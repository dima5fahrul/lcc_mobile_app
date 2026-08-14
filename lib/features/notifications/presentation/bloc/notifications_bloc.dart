/// `NotificationsBloc` — the shell bell's state. Two independent reads, no
/// timer.
///
/// Ports the two `useQuery` calls and the two handlers inside
/// `Layout.tsx`'s `NotificationMenu` (`:96-296`).
///
/// ## THE BELL DOES NOT POLL, AND THAT IS THE REQUIREMENT
///
/// `Layout.tsx:114-116` runs `me.unreadCount` with dependency list
/// `[isAuthenticated]`, and `hooks.ts:57-88`'s `useQuery` effect installs **no
/// interval, no focus listener and no window revalidation** — it re-runs only
/// when a dep or the `refetch` nonce changes. So the badge is refreshed exactly
/// twice in the app's life: on sign-in, and explicitly after `openNotification`
/// (`:135`) or `markAllRead` (`:141`). **Between those it is stale, and the
/// port is stale with it.**
///
/// A 30-second refresh here would make the app *better* than its source and
/// would diverge in a way no fidelity tier can see — the R-25 class
/// (`roadmap.md` § B8). Changing it is a user decision plus an ADR, never an
/// implementer's (specs.md § 6.2, § 8.3). There is deliberately no `dart:async`
/// import in this file: `grep -rn "Timer" lib/features/notifications` must find
/// nothing, and B9-AC-18 asserts the count use case is invoked **exactly once**
/// across ten minutes of fake clock.
///
/// Chat polls every 4,000 ms. That is B9b, a different feature, and the two
/// postures are different on purpose.
///
/// ## The generation guard is a port, not an embellishment
///
/// `hooks.ts:60,73,79,84` stamps every in-flight request with
/// `const mine = ++generation.current` and drops the response when
/// `mine !== generation.current` — *"a newer request won"*. Reproduced here as
/// [_countGeneration] / [_listGeneration], and it is load-bearing rather than
/// decorative: `bloc` 9.2.1's default event transformer is **concurrent**, so
/// two taps on the bell start two list fetches, and without the stamp the
/// slower one would overwrite the fresher one on arrival. Four B2 BLoCs
/// `emit(… await …)` with no such re-check; this one does not.
///
/// ## Where the session comes from
///
/// It does not come from here. `isAuthenticated` arrives as
/// [NotificationsAuthChanged], dispatched by `NotificationBell` from the
/// app-wide `SessionBloc` — the same shape the React component uses, where
/// `isAuthenticated` is a prop `Layout` was handed. That keeps this BLoC
/// testable with no session in the tree and keeps the shell session-agnostic
/// (`app_shell.dart`'s own note).
library;

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/notification_entities.dart';
import '../../domain/usecases/notification_usecases.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';
part 'notifications_bloc.freezed.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({
    required this.getNotifications,
    required this.getUnreadCount,
    required this.markNotificationRead,
    required this.markAllNotificationsRead,
  }) : super(const NotificationsState()) {
    on<NotificationsAuthChanged>(_onAuthChanged);
    on<NotificationsMenuToggled>(_onMenuToggled);
    on<NotificationsMenuDismissed>(_onMenuDismissed);
    on<NotificationsListRetried>(_onListRetried);
    on<NotificationOpened>(_onNotificationOpened);
    on<NotificationsMarkAllRead>(_onMarkAllRead);
  }

  final GetNotifications getNotifications;
  final GetUnreadCount getUnreadCount;
  final MarkNotificationRead markNotificationRead;
  final MarkAllNotificationsRead markAllNotificationsRead;

  /// `hooks.ts:55` — `const generation = useRef(0)`, one per query.
  int _countGeneration = 0;
  int _listGeneration = 0;

  // ── The unread-count query: deps `[isAuthenticated]`, enabled when signed in
  // ───────────────────────────────────────────────────────────────────────────

  /// `useQuery(me.unreadCount, [isAuthenticated], {enabled: isAuthenticated})`
  /// — `Layout.tsx:114-116`.
  ///
  /// **A dep change while disabled does not clear the last value.**
  /// `hooks.ts:58-61` returns early on `!enabled` without touching `data`, so
  /// after a sign-out the count keeps whatever it last read. That is invisible
  /// in the source because a signed-out bell shows the dot unconditionally
  /// (`:172`), but it is the measured behaviour and reproducing it costs
  /// nothing.
  Future<void> _onAuthChanged(
    NotificationsAuthChanged event,
    Emitter<NotificationsState> emit,
  ) async {
    if (event.isAuthenticated == state.isAuthenticated) return;

    emit(state.copyWith(isAuthenticated: event.isAuthenticated));

    // Signing out also closes an open menu: `enabled` goes false for the inbox
    // query too, and `Layout.tsx:208` swaps the whole body for the sign-in
    // prompt. Leaving `open` true would render that prompt inside a dropdown
    // nobody asked to reopen.
    if (!event.isAuthenticated) {
      emit(state.copyWith(open: false));
      return;
    }

    await _loadCount(emit);
  }

  Future<void> _loadCount(Emitter<NotificationsState> emit) async {
    final int mine = ++_countGeneration;
    final Either<Failure, int> result = await getUnreadCount(NoParams());
    // "a newer request won" — `hooks.ts:73`.
    if (mine != _countGeneration || emit.isDone) return;

    // `counter.data?.unread ?? 0`: a failed count leaves the previous number
    // standing rather than blanking the badge, because `useQuery` only calls
    // `setData` on success.
    result.fold(
      (Failure _) {},
      (int unread) => emit(state.copyWith(unreadCount: unread)),
    );
  }

  // ── The inbox query: deps `[isAuthenticated, open]`, enabled when both ──────

  /// `setOpen((v) => !v)` — `Layout.tsx:165`.
  ///
  /// The list query's deps include `open`, so **every** opening refetches. The
  /// menu is not a cache.
  Future<void> _onMenuToggled(
    NotificationsMenuToggled event,
    Emitter<NotificationsState> emit,
  ) async {
    final bool next = !state.open;
    emit(state.copyWith(open: next));
    if (!next || !state.isAuthenticated) return;
    await _loadList(emit);
  }

  Future<void> _onMenuDismissed(
    NotificationsMenuDismissed event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(open: false));
  }

  /// `inbox.refetch()` — the error branch's button (`Layout.tsx:234`).
  Future<void> _onListRetried(
    NotificationsListRetried event,
    Emitter<NotificationsState> emit,
  ) =>
      _loadList(emit);

  Future<void> _loadList(Emitter<NotificationsState> emit) async {
    final int mine = ++_listGeneration;

    // `if (hasData) setRefreshing(true); else setLoading(true);` —
    // `hooks.ts:67-68`. A reopen with rows already in hand keeps showing them
    // instead of flashing the spinner, and only the *first* open renders the
    // loading state. Collapsing the two would make the menu blink on every
    // open, which the source does not do.
    emit(state.listLoaded
        ? state.copyWith(listRefreshing: true)
        : state.copyWith(listStatus: RegionStatus.loading));

    final Either<Failure, List<CitizenNotification>> result =
        await getNotifications(NoParams());
    if (mine != _listGeneration || emit.isDone) return;

    emit(state.withList(result));
  }

  // ── Opening one notice ─────────────────────────────────────────────────────

  /// `openNotification(item)` — `Layout.tsx:129-137`.
  ///
  /// The order is the source's and it is observable: the menu closes and the
  /// tab changes **first**, synchronously, and only then is the mark-read
  /// issued. Navigation is the widget's — it needs a `BuildContext` — and it
  /// happens before this event is even dispatched, which is the same ordering.
  ///
  /// **`counter.refetch()` runs whether or not the POST succeeded**, because
  /// `.catch(() => undefined)` swallows the rejection and execution continues
  /// to `:135`. Reproduced literally: the `Either` is discarded, not branched
  /// on.
  Future<void> _onNotificationOpened(
    NotificationOpened event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(open: false));

    // `if (!item.read_at)` — an already-read notice issues no POST and does not
    // refetch the count. Asserted by invocation count (B9-AC-19).
    if (!event.item.isUnread) return;

    await markNotificationRead(MarkNotificationReadParams(event.item.id));
    if (emit.isDone) return;
    await _loadCount(emit);
  }

  /// `markAllRead()` — `Layout.tsx:139-143`. Both queries are refetched, and
  /// the menu **stays open**: the source calls neither `setOpen(false)` nor a
  /// navigation here.
  Future<void> _onMarkAllRead(
    NotificationsMarkAllRead event,
    Emitter<NotificationsState> emit,
  ) async {
    await markAllNotificationsRead(NoParams());
    if (emit.isDone) return;
    await _loadCount(emit);
    if (emit.isDone) return;
    await _loadList(emit);
  }
}

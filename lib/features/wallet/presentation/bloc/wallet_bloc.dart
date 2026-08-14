/// `WalletBloc` — the wallet page's whole read surface, and its one write.
///
/// One screen-level BLoC (SSD § 7.2), holding the four `useQuery` calls of
/// `WalletPage.tsx:101-120` plus the top-up sheet's catalogue query (`:726`)
/// and its mutation (`:733`).
///
/// ## Events and state live in this file, not in `part` siblings
///
/// `notifications_bloc.dart` and `news_bloc.dart` split into
/// `*_event.dart` / `*_state.dart` parts. This one does not, and the reason is
/// scope rather than taste: specs.md § 3.1's B6a table admits
/// `presentation/bloc/wallet_bloc.dart (+ .freezed.dart)` and no sibling, and
/// an unlisted file is an automatic FAIL of the batch. Nothing else about the
/// pattern changes.
///
/// ## Four queries, four different enablement conditions (§ 6.8(1))
///
/// | Query | Endpoint | `enabled` | Source |
/// |---|---|---|---|
/// | overview | `/me/wallet` | `isAuthenticated` | `:101` |
/// | receipts | `/me/transactions?page=1&per_page=10` | `isAuthenticated` | `:110-114` |
/// | ledger | `/me/wallet/entries?page=N&per_page=10` | `isAuthenticated && showLedger` | `:116-120` |
/// | methods | `/payment-methods` | **sheet mounted** — not a page query | `:726` |
///
/// Not one composite fetch. `B6-AC-23` asserts, per condition, which endpoints
/// were and were not hit, and `B6-AC-25` asserts a page load issues **zero**
/// `/payment-methods` requests.
///
/// **Bills (`GET /applications/`) is deliberately absent.** It is B6b's, it
/// belongs to `features/application`, and `B6-AC-45` proves B6a contains no
/// reference to it. [kBillsDueB6b] is the named empty constant that row asks
/// for.
///
/// ## Nothing here refreshes on a timer, on resume, or on focus (`B6-DIV-4`)
///
/// `WalletPage.tsx:132-137`'s `refreshMoney` is called from exactly two places:
/// after a successful top-up (`:559-562`) and after a successful pay (B6b,
/// `:544`). `hooks.ts`'s `useQuery` installs no interval, no focus listener and
/// no window revalidation. So the wallet is stale between actions and **the
/// port is stale with it**. There is deliberately no `dart:async` import in
/// this file: `B6-AC-26` greps `lib/features/wallet` and
/// `lib/presentation/payment` for `Timer|periodic|WidgetsBindingObserver|
/// RefreshIndicator` and requires zero. Adding a pull-to-refresh would make the
/// app *better* than its source, which is a divergence no fidelity tier can
/// see — the same class of change B9 refused for the bell.
///
/// ## The generation guard is a port, not an embellishment
///
/// `hooks.ts:55-83` stamps every in-flight request with
/// `const mine = ++generation.current` and drops the response when
/// `mine !== generation.current` — *"a newer request won"*. Reproduced here as
/// five counters, one per query, and load-bearing rather than decorative:
/// `bloc` 9.2.1's default event transformer is **concurrent**, so two taps on
/// the ledger pager start two fetches and without the stamp the slower one
/// overwrites the fresher one on arrival. Four B2 BLoCs `emit(… await …)` with
/// no such re-check; B9 ported it; this one does too.
///
/// ## What this BLoC does NOT hold
///
/// The **balance eye toggle**. `WalletPage.tsx:95` is a plain `useState`, and
/// SSD § 7.2's *"`setState` is permitted only for ephemeral local UI"* is
/// exactly this case: nothing fetches on it, nothing else reads it, and putting
/// it here would make hiding a balance a state transition every `bloc_test` in
/// this feature has to spell. `wallet_page.dart` owns it (§ 6.8(6)).
library;

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/paged.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/wallet_entry.dart';
import '../../domain/entities/wallet_overview.dart';
import '../../domain/usecases/wallet_usecases.dart';

part 'wallet_bloc.freezed.dart';

/// **The empty bills list, named** (`B6-AC-45`).
///
/// `WalletPage.tsx:123-125` filters `billsQuery.data` down to the pending,
/// non-zero-fee cases. B6a has no `billsQuery` — `GET /applications/` is B7a's
/// endpoint and B6b's consumer — so the section renders its empty branch from
/// this constant. An inline `[]` at the widget would be indistinguishable from
/// "the citizen has no bills", which is the state it happens to produce today
/// and is **not** what it means.
///
/// TODO(B6b): replace with the filtered `List<ApplicationRow>` from
/// `ListPendingBills`, reached through a DI closure over `applicationInjection`
/// against B7a's domain interface (specs.md § 2.3).
const List<Object> kBillsDueB6b = <Object>[];

// ─────────────────────────────────────────────────────────────────────────────
// Events
// ─────────────────────────────────────────────────────────────────────────────

sealed class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The mount event, dispatched by the `/wallet` route builder (`B6-AC-12`).
///
/// **It fetches nothing, and that is the port.** All four page queries are
/// `enabled: isAuthenticated` (`WalletPage.tsx:101,105,113,119`), and this BLoC
/// does not read `SessionBloc` — the flag arrives as [WalletAuthChanged] from
/// the page's listener, exactly as `isAuthenticated` arrives at the React
/// component as a prop. So there is nothing to fetch until the session
/// resolves. The same asymmetry `NotificationsBloc` documents: `/` and
/// `/service` dispatch a mount fetch because they have public reads; the bell,
/// the chat and the wallet do not because they have none.
///
/// It is kept rather than dropped because the *provider* must be created at
/// mount either way, and a builder that creates a BLoC and dispatches nothing
/// reads as an oversight. `B6-AC-25` asserts a mount issues zero requests.
final class WalletStarted extends WalletEvent {
  const WalletStarted();
}

/// `isAuthenticated` changed, from the page's `BlocListener<SessionBloc>`.
final class WalletAuthChanged extends WalletEvent {
  const WalletAuthChanged({required this.isAuthenticated});

  final bool isAuthenticated;

  @override
  List<Object?> get props => <Object?>[isAuthenticated];
}

/// The balance card's "Try again" pill — `WalletPage.tsx:194`.
final class WalletOverviewRetried extends WalletEvent {
  const WalletOverviewRetried();
}

/// The receipts card's retry — `:441`.
final class WalletReceiptsRetried extends WalletEvent {
  const WalletReceiptsRetried();
}

/// The ledger card's retry — `:609`.
final class WalletLedgerRetried extends WalletEvent {
  const WalletLedgerRetried();
}

/// The toggle above the list — `:394-404`.
///
/// Resets paging to 1 **in both directions** and the label names the
/// destination, not the current view (`B6-DIV-5`, `B6-AC-28`).
final class WalletLedgerToggled extends WalletEvent {
  const WalletLedgerToggled();
}

/// The ledger pager — `:686-700`.
final class WalletLedgerPageChanged extends WalletEvent {
  const WalletLedgerPageChanged(this.page);

  final int page;

  @override
  List<Object?> get props => <Object?>[page];
}

/// The top-up sheet mounted — `:726`, `useQuery(payments.methods, [])`.
///
/// This is where `/payment-methods` is fetched, and nowhere else in B6a
/// (`B6-AC-25`). Refetched on every mount, because the source's query has an
/// empty dependency list inside a component that is unmounted when the sheet
/// closes.
final class WalletTopUpSheetOpened extends WalletEvent {
  const WalletTopUpSheetOpened();
}

/// The sheet closed — clears the mutation's error so reopening does not show
/// the last attempt's message. `:812`'s error branch belongs to the query;
/// `:876`'s belongs to the mutation, and a `useMutation` is recreated with the
/// component.
final class WalletTopUpSheetClosed extends WalletEvent {
  const WalletTopUpSheetClosed();
}

/// The sheet's "Try again" — `:815`.
final class WalletPaymentMethodsRetried extends WalletEvent {
  const WalletPaymentMethodsRetried();
}

/// `submit()` — `WalletPage.tsx:741-749`.
///
/// **This event moves real money.** specs.md § 4.4 forbids executing the
/// underlying `POST /me/wallet/topup` against any host; every test of this path
/// runs against a mock transport.
///
/// [amountLak] is already an `int` here: the parse
/// (`parseTopUpAmount`, `B6-AC-34`) and the min/max guard (`B6-AC-35`,
/// security-review item 9) both run **before** the event is constructed, so no
/// unparsed value can reach the request body.
final class WalletTopUpSubmitted extends WalletEvent {
  const WalletTopUpSubmitted({required this.amountLak, required this.methodCode});

  final int amountLak;
  final String methodCode;

  @override
  List<Object?> get props => <Object?>[amountLak, methodCode];
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

/// One region's async status, ported from `useQuery`'s `{data, loading, error}`.
///
/// `error` is a `String?` and not a [Failure] because the four error branches
/// **render it** (`WalletPage.tsx:439,607,812,876`), so what the state needs is
/// the message; keeping the `Failure` would push `.message` into four widgets.
@freezed
abstract class WalletState with _$WalletState {
  const factory WalletState({
    @Default(false) bool isAuthenticated,

    // ── overview: `/me/wallet` ───────────────────────────────────────────────
    WalletOverview? overview,
    @Default(false) bool overviewLoading,
    String? overviewError,

    // ── receipts: `/me/transactions` ─────────────────────────────────────────
    @Default(<Transaction>[]) List<Transaction> receipts,
    @Default(false) bool receiptsLoading,
    String? receiptsError,

    // ── ledger: `/me/wallet/entries`, enabled only while [showLedger] ────────
    /// `null` until the first page has arrived. Distinguished from an empty
    /// page because the *first frame* of the ledger deliberately renders
    /// `overview.recentEntries` instead (§ 6.8(3)) — a distinction an empty
    /// `PagedRows` could not carry.
    PagedRows<WalletEntry>? ledger,
    @Default(false) bool ledgerLoading,
    String? ledgerError,
    @Default(false) bool showLedger,
    @Default(1) int ledgerPage,

    // ── methods: `/payment-methods`, fetched by the sheet ────────────────────
    @Default(<PaymentMethod>[]) List<PaymentMethod> methods,
    @Default(false) bool methodsLoading,
    String? methodsError,

    // ── the top-up mutation ──────────────────────────────────────────────────
    @Default(false) bool topUpPending,
    String? topUpError,
    /// Raised for one state emission after a successful credit, so the page can
    /// close the sheet. `onDone` (`:559-562`) is a callback on the web; a BLoC
    /// has no callbacks, so it is a flag the listener consumes.
    @Default(false) bool topUpSucceeded,
  }) = _WalletState;

  const WalletState._();

  /// `overview?.wallet.balance_lak ?? 0` — `WalletPage.tsx:122`.
  int get balanceLak => overview?.wallet.balanceLak ?? 0;

  /// `walletQuery.loading && !overview` — `:184`.
  ///
  /// The ellipsis shows **only** before the first overview arrives. A refetch
  /// with an overview in hand shows the *old* balance (§ 6.8(7), `B6-AC-29`).
  bool get balanceIsPlaceholder => overviewLoading && overview == null;

  /// `ledgerQuery.data?.data ?? overview?.recent_entries ?? []` — `:130`.
  ///
  /// The ledger's first frame is deliberately **stale** (`B6-DIV-5`).
  List<WalletEntry> get ledgerEntries =>
      ledger?.rows ?? overview?.recentEntries ?? const <WalletEntry>[];

  /// `ledgerQuery.loading && entries.length === 0` — `:418`.
  ///
  /// The skeleton is **suppressed** whenever the stale first frame has
  /// something to draw (`B6-AC-27`).
  bool get ledgerSkeleton => ledgerLoading && ledgerEntries.isEmpty;

  /// `txQuery.loading && receipts.length === 0` — `:428`.
  bool get receiptsSkeleton => receiptsLoading && receipts.isEmpty;

  /// `ledgerQuery.data?.meta.page ?? ledgerPage` — `:421`.
  int get ledgerPageShown => ledger?.page ?? ledgerPage;

  /// `ledgerQuery.data?.meta.total_pages ?? 1` — `:422`.
  int get ledgerTotalPages => ledger?.totalPages ?? 1;

  /// `(methods.data ?? []).filter(m => m.enabled && m.code !== "wallet")`
  /// — `WalletPage.tsx:728`.
  ///
  /// **The wallet cannot top itself up.** Live `PaymentSection` filters on
  /// `m.enabled` alone (`PaymentSection.tsx:211`) and therefore keeps it — two
  /// different filters over one API, and `B6-AC-53` asserts 6 rows here and 7
  /// there against the same recorded fixture.
  List<PaymentMethod> get topUpOptions => methods
      .where((PaymentMethod m) => m.enabled && m.code != 'wallet')
      .toList(growable: false);
}

// ─────────────────────────────────────────────────────────────────────────────
// Bloc
// ─────────────────────────────────────────────────────────────────────────────

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  WalletBloc({
    required this.getWalletOverview,
    required this.getWalletEntries,
    required this.getTransactions,
    required this.getPaymentMethods,
    required this.topUpWallet,
  }) : super(const WalletState()) {
    on<WalletStarted>(_onStarted);
    on<WalletAuthChanged>(_onAuthChanged);
    on<WalletOverviewRetried>(_onOverviewRetried);
    on<WalletReceiptsRetried>(_onReceiptsRetried);
    on<WalletLedgerRetried>(_onLedgerRetried);
    on<WalletLedgerToggled>(_onLedgerToggled);
    on<WalletLedgerPageChanged>(_onLedgerPageChanged);
    on<WalletTopUpSheetOpened>(_onSheetOpened);
    on<WalletTopUpSheetClosed>(_onSheetClosed);
    on<WalletPaymentMethodsRetried>(_onMethodsRetried);
    on<WalletTopUpSubmitted>(_onTopUpSubmitted);
  }

  final GetWalletOverview getWalletOverview;
  final GetWalletEntries getWalletEntries;
  final GetTransactions getTransactions;
  final GetPaymentMethods getPaymentMethods;
  final TopUpWallet topUpWallet;

  /// `hooks.ts:55` — `const generation = useRef(0)`, **one per query**.
  int _overviewGeneration = 0;
  int _receiptsGeneration = 0;
  int _ledgerGeneration = 0;
  int _methodsGeneration = 0;

  // ── Mount and session ──────────────────────────────────────────────────────

  /// Deliberately empty. See [WalletStarted].
  void _onStarted(WalletStarted event, Emitter<WalletState> emit) {}

  Future<void> _onAuthChanged(
    WalletAuthChanged event,
    Emitter<WalletState> emit,
  ) async {
    if (event.isAuthenticated == state.isAuthenticated) return;
    emit(state.copyWith(isAuthenticated: event.isAuthenticated));

    if (!event.isAuthenticated) {
      // `hooks.ts:58-61` returns early on `!enabled` **without touching
      // `data`**, so the web keeps the last-read rows in memory after a sign
      // out — they are simply never rendered, because every consuming branch is
      // itself behind `isAuthenticated` (`:409`). Holding a balance and an
      // account number in memory for the next citizen on the device is not a
      // behaviour worth being faithful about: SSD § 12 forbids persisting them
      // and this is the same hazard one layer up. Cleared, and recorded as the
      // one place this BLoC is deliberately stricter than `useQuery` — it is
      // unobservable on every fidelity tier because no signed-out surface reads
      // these fields.
      emit(state.copyWith(
        overview: null,
        receipts: const <Transaction>[],
        ledger: null,
        showLedger: false,
        ledgerPage: 1,
        overviewError: null,
        receiptsError: null,
        ledgerError: null,
      ));
      return;
    }

    await Future.wait(<Future<void>>[
      _loadOverview(emit),
      _loadReceipts(emit),
    ]);
  }

  // ── overview ───────────────────────────────────────────────────────────────

  Future<void> _onOverviewRetried(
    WalletOverviewRetried event,
    Emitter<WalletState> emit,
  ) async {
    if (!state.isAuthenticated) return;
    await _loadOverview(emit);
  }

  Future<void> _loadOverview(Emitter<WalletState> emit) async {
    final int mine = ++_overviewGeneration;
    emit(state.copyWith(overviewLoading: true, overviewError: null));

    final Either<Failure, WalletOverview> result =
        await getWalletOverview(NoParams());

    // "a newer request won" — `hooks.ts:73`.
    if (mine != _overviewGeneration || emit.isDone) return;

    emit(
      result.fold(
        (Failure f) => state.copyWith(
          overviewLoading: false,
          overviewError: f.message,
        ),
        // `setData` on success only: a failed refetch leaves the previous
        // overview standing rather than blanking the card.
        (WalletOverview o) => state.copyWith(
          overviewLoading: false,
          overview: o,
          overviewError: null,
        ),
      ),
    );
  }

  // ── receipts ───────────────────────────────────────────────────────────────

  Future<void> _onReceiptsRetried(
    WalletReceiptsRetried event,
    Emitter<WalletState> emit,
  ) async {
    if (!state.isAuthenticated) return;
    await _loadReceipts(emit);
  }

  Future<void> _loadReceipts(Emitter<WalletState> emit) async {
    final int mine = ++_receiptsGeneration;
    emit(state.copyWith(receiptsLoading: true, receiptsError: null));

    // `{page: 1, per_page: 10}` — `WalletPage.tsx:111`. Page 1 is a literal on
    // the web: the receipts list has no pager, only the ledger does.
    final Either<Failure, PagedRows<Transaction>> result =
        await getTransactions(const WalletPageParams(page: 1));

    if (mine != _receiptsGeneration || emit.isDone) return;

    emit(
      result.fold(
        (Failure f) => state.copyWith(
          receiptsLoading: false,
          receiptsError: f.message,
        ),
        (PagedRows<Transaction> p) => state.copyWith(
          receiptsLoading: false,
          receipts: p.rows,
          receiptsError: null,
        ),
      ),
    );
  }

  // ── ledger ─────────────────────────────────────────────────────────────────

  /// `setLedgerPage(1); setShowLedger(s => !s)` — `WalletPage.tsx:399-400`.
  ///
  /// **Both directions reset the page** (`B6-DIV-5`, `B6-AC-28`), and closing
  /// the ledger drops its rows: the query's `enabled` goes false, and reopening
  /// re-runs it from page 1.
  Future<void> _onLedgerToggled(
    WalletLedgerToggled event,
    Emitter<WalletState> emit,
  ) async {
    if (!state.isAuthenticated) return;

    final bool opening = !state.showLedger;
    emit(state.copyWith(
      showLedger: opening,
      ledgerPage: 1,
      ledger: null,
      ledgerError: null,
    ));

    if (opening) await _loadLedger(emit, 1);
  }

  Future<void> _onLedgerPageChanged(
    WalletLedgerPageChanged event,
    Emitter<WalletState> emit,
  ) async {
    if (!state.isAuthenticated || !state.showLedger) return;
    if (event.page == state.ledgerPage) return;

    emit(state.copyWith(ledgerPage: event.page));
    await _loadLedger(emit, event.page);
  }

  Future<void> _onLedgerRetried(
    WalletLedgerRetried event,
    Emitter<WalletState> emit,
  ) async {
    if (!state.isAuthenticated || !state.showLedger) return;
    await _loadLedger(emit, state.ledgerPage);
  }

  Future<void> _loadLedger(Emitter<WalletState> emit, int page) async {
    final int mine = ++_ledgerGeneration;
    emit(state.copyWith(ledgerLoading: true, ledgerError: null));

    final Either<Failure, PagedRows<WalletEntry>> result =
        await getWalletEntries(WalletPageParams(page: page));

    // The pager is the reason this stamp is not decorative: two taps on "next"
    // start two fetches, and `bloc`'s default transformer is concurrent.
    if (mine != _ledgerGeneration || emit.isDone) return;

    emit(
      result.fold(
        (Failure f) => state.copyWith(
          ledgerLoading: false,
          ledgerError: f.message,
        ),
        (PagedRows<WalletEntry> p) => state.copyWith(
          ledgerLoading: false,
          ledger: p,
          ledgerError: null,
        ),
      ),
    );
  }

  // ── /payment-methods, the sheet's own query ────────────────────────────────

  Future<void> _onSheetOpened(
    WalletTopUpSheetOpened event,
    Emitter<WalletState> emit,
  ) async {
    // The mutation is recreated with the component on the web (`:733`), so its
    // error does not survive a close/reopen.
    emit(state.copyWith(topUpError: null, topUpSucceeded: false));
    await _loadMethods(emit);
  }

  void _onSheetClosed(
    WalletTopUpSheetClosed event,
    Emitter<WalletState> emit,
  ) {
    emit(state.copyWith(topUpError: null, topUpSucceeded: false));
  }

  Future<void> _onMethodsRetried(
    WalletPaymentMethodsRetried event,
    Emitter<WalletState> emit,
  ) =>
      _loadMethods(emit);

  Future<void> _loadMethods(Emitter<WalletState> emit) async {
    final int mine = ++_methodsGeneration;
    emit(state.copyWith(methodsLoading: true, methodsError: null));

    final Either<Failure, List<PaymentMethod>> result =
        await getPaymentMethods(NoParams());

    if (mine != _methodsGeneration || emit.isDone) return;

    emit(
      result.fold(
        (Failure f) => state.copyWith(
          methodsLoading: false,
          methodsError: f.message,
        ),
        (List<PaymentMethod> rows) => state.copyWith(
          methodsLoading: false,
          methods: rows,
          methodsError: null,
        ),
      ),
    );
  }

  // ── the one write ──────────────────────────────────────────────────────────

  /// `submit()` — `WalletPage.tsx:741-749`, then `onDone` → `refreshMoney()`.
  ///
  /// **`refreshMoney` refetches the ledger only when the ledger is open**
  /// (`:136`, `B6-AC-26`) — and `/applications/` is B6b's, so two of the
  /// source's four refetches are what this reproduces.
  Future<void> _onTopUpSubmitted(
    WalletTopUpSubmitted event,
    Emitter<WalletState> emit,
  ) async {
    if (state.topUpPending) return; // `!topUp.pending` — `:740`.

    emit(state.copyWith(
      topUpPending: true,
      topUpError: null,
      topUpSucceeded: false,
    ));

    final Either<Failure, Wallet> result = await topUpWallet(
      TopUpParams(amountLak: event.amountLak, methodCode: event.methodCode),
    );

    if (emit.isDone) return;

    final bool ok = result.isRight();
    emit(
      result.fold(
        (Failure f) => state.copyWith(topUpPending: false, topUpError: f.message),
        // The returned `Wallet` is **discarded**, exactly as the source
        // discards the mutation's result: `onDone` closes the sheet and
        // re-reads `/me/wallet`. Rendering the returned balance instead would
        // be a narrowing the web does not perform.
        (Wallet _) => state.copyWith(topUpPending: false, topUpSucceeded: true),
      ),
    );

    if (!ok) return;

    await _refreshMoney(emit);
  }

  /// `refreshMoney` — `WalletPage.tsx:132-137`.
  Future<void> _refreshMoney(Emitter<WalletState> emit) async {
    await Future.wait(<Future<void>>[
      _loadOverview(emit),
      _loadReceipts(emit),
      if (state.showLedger) _loadLedger(emit, state.ledgerPage),
    ]);
  }
}

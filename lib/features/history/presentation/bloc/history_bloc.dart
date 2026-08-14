/// `HistoryBloc` — `/history`'s state: one list query, four count queries and
/// the status pipeline.
///
/// Ports `HistoryPage.tsx`'s four `useState`s (`filter`, `query`, `page`,
/// `selectedId`), its `useDebounced`, its two `useQuery` calls and
/// `usePipeline()`. `selectedId` is **not** here — the detail is B7b's, and
/// § 6.6 rules it in-page state; B7a exposes [HistoryReturnedFromDetail] so
/// B7b can wire `onBack` without reopening this file.
///
/// ## Three query lifetimes, deliberately different (§ 6.8, Finding J)
///
/// | Query | Deps | Refetches on |
/// |---|---|---|
/// | list | `[page, filter, search]` | every control, and retry |
/// | counts | `[]` | mount, and **return from the detail** only |
/// | pipeline | once per app run | nothing |
///
/// The tiles **do not follow the filter chips**. That is inefficient — a cold
/// authenticated load issues five `/applications` requests (`B7-AC-38`) where
/// one could serve — and it is what the web does. Collapsing them, or making
/// the tiles track the filter, would be the port being better than its source
/// and would be invisible to all four fidelity tiers.
///
/// ## The generation guard is a port, not an embellishment
///
/// `hooks.ts:55,65,73` stamps every in-flight request with
/// `const mine = ++generation.current` and drops the answer when
/// `mine !== generation.current` — *"a newer request won"*. Reproduced as
/// [_listGeneration] / [_countsGeneration]. It is load-bearing rather than
/// decorative: `bloc` 9's default event transformer is **concurrent**, so a
/// fast page-2 can resolve before a slow page-1 and, without the stamp, the
/// stale answer would overwrite the fresh one (`B7-AC-21`). Four B2 BLoCs
/// dropped this; B9's `NotificationsBloc` ported it, and so does this.
///
/// ## No `enabled` flag (§ 6.5)
///
/// `HistoryPage.tsx:95` and `:113` gate both queries on `isAuthenticated`. In
/// the port `/history` is in `AppRoutes._protectedPaths`, so the page cannot
/// mount unauthenticated — the gate is structural and a second in-page check
/// would be dead code that could drift from the real one. The signed-out
/// branch at `:223-234` is therefore not ported either; it is a redirect here,
/// recorded as a deliberate divergence.
library;

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../application/domain/entities/application_page.dart';
import '../../../application/domain/entities/application_row.dart';
import '../../../application/domain/entities/status_pipeline.dart';
import '../../../application/domain/usecases/application_usecases.dart';

part 'history_event.dart';
part 'history_state.dart';
part 'history_bloc.freezed.dart';

/// `useDebounced(query.trim(), 350)` — `HistoryPage.tsx:76`.
///
/// 350 ms, not `ServiceBloc`'s 300: the two surfaces debounce different boxes
/// and the source uses different numbers (`ServicePage.tsx` 300,
/// `HistoryPage.tsx:76` 350). Sharing one constant would silently pick one.
const Duration kHistorySearchDebounce = Duration(milliseconds: 350);

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc({
    required this.listApplications,
    required this.getStatusPipeline,
  }) : super(const HistoryState()) {
    on<HistoryStarted>(_onStarted);
    on<HistoryListRetried>(_onListRetried);
    on<HistoryFilterPicked>(_onFilterPicked);
    on<HistorySearchChanged>(_onSearchChanged);
    on<HistorySearchDebounced>(_onSearchDebounced);
    on<HistoryPreviousPage>(_onPreviousPage);
    on<HistoryNextPage>(_onNextPage);
    on<HistoryReturnedFromDetail>(_onReturnedFromDetail);
  }

  final ListApplications listApplications;
  final GetStatusPipeline getStatusPipeline;

  /// `hooks.ts:55` — `const generation = useRef(0)`, one per query.
  int _listGeneration = 0;
  int _countsGeneration = 0;

  Timer? _debounce;

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  // ── Mount ──────────────────────────────────────────────────────────────────

  /// The render-time work of `HistoryPage.tsx:68` (`usePipeline`), `:83`
  /// (the list) and `:99` (the counts). All three start in the same tick, as
  /// the three hooks do.
  Future<void> _onStarted(HistoryStarted event, Emitter<HistoryState> emit) async {
    emit(state.copyWith(
      listStatus: RegionStatus.loading,
      countsStatus: RegionStatus.loading,
    ));

    await Future.wait(<Future<void>>[
      _loadPipeline(emit),
      _loadList(emit),
      _loadCounts(emit),
    ]);
  }

  // ── The pipeline: fetched once, and its failure is swallowed ───────────────

  /// `statusCatalogue.ts:56-69`.
  ///
  /// Three behaviours, all the source's, and two of them live in
  /// `StatusPipeline.fromOrder` so a second caller cannot get them wrong:
  /// `draft` is stripped, an empty answer keeps the seed, and **a failed fetch
  /// is swallowed** — *"Offline or the API is down — the seeded order above is
  /// the fallback"* (`:67-69`). The page still renders (`B7-AC-27`).
  Future<void> _loadPipeline(Emitter<HistoryState> emit) async {
    final Either<Failure, StatusPipeline> result =
        await getStatusPipeline(NoParams());
    if (emit.isDone) return;
    result.fold(
      // Deliberately empty: the seed in `HistoryState.pipeline` stands, and
      // no error surface exists for the catalogue anywhere in the source.
      (Failure _) {},
      (StatusPipeline pipeline) => emit(state.copyWith(pipeline: pipeline)),
    );
  }

  // ── The list query: page, filter and search are its three inputs ───────────

  /// `list.refetch` — the error panel's Try-again (`HistoryPage.tsx:141-146`).
  Future<void> _onListRetried(
    HistoryListRetried event,
    Emitter<HistoryState> emit,
  ) =>
      _loadList(emit);

  /// `setFilter(f.id)` — `HistoryPage.tsx:196`, and the
  /// `useEffect(() => setPage(1), [filter, search])` at `:79-81` that follows
  /// it. **The page resets** (`B7-AC-20`); keeping it would ask for page 3 of a
  /// filter that has one and render an empty list that is not empty.
  ///
  /// The counts are untouched: their deps are `[]` (`B7-AC-37`).
  Future<void> _onFilterPicked(
    HistoryFilterPicked event,
    Emitter<HistoryState> emit,
  ) async {
    if (event.filter == state.filter) return;
    // The chip must look selected while its list is still in flight, which is
    // what `setFilter` before the query re-runs does on the web.
    emit(state.copyWith(filter: event.filter, page: 1));
    await _loadList(emit);
  }

  /// Every keystroke. Emits immediately so the field is not laggy, then arms
  /// the 350 ms debounce; the fetch happens in [_onSearchDebounced].
  ///
  /// **Clearing the box is still a search** — unlike `ServiceBloc`, which
  /// short-circuits an empty field because clearing it flips `ServicePage`
  /// back to a view that issues no request at all. `/history` has no such
  /// view: an empty box is the unfiltered list, which is a real query, so it
  /// waits out the same 350 ms the source makes it wait (`useDebounced` has no
  /// empty-value fast path, `hooks.ts:126-134`).
  void _onSearchChanged(
    HistorySearchChanged event,
    Emitter<HistoryState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));

    _debounce?.cancel();
    _debounce = Timer(
      kHistorySearchDebounce,
      () => add(HistorySearchDebounced(event.query.trim())),
    );
  }

  /// The debounce fired. `search` is the trimmed term
  /// (`useDebounced(query.trim(), 350)`).
  Future<void> _onSearchDebounced(
    HistorySearchDebounced event,
    Emitter<HistoryState> emit,
  ) async {
    // A timer that fired after the citizen typed again. `cancel()` makes this
    // rare rather than impossible — the event can already be queued when the
    // next keystroke lands — so this guard, not the cancel, is the correctness
    // boundary (`ServiceBloc`'s note, measured there).
    if (event.term != state.searchQuery.trim()) return;
    // `useDebounced` settling to the value it already held re-runs no effect:
    // `deps` are compared by identity and the string has not changed.
    if (event.term == state.search) return;

    emit(state.copyWith(search: event.term, page: 1));
    await _loadList(emit);
  }

  /// `setPage((p) => Math.max(1, p - 1))` — `HistoryPage.tsx:409`.
  Future<void> _onPreviousPage(
    HistoryPreviousPage event,
    Emitter<HistoryState> emit,
  ) async {
    final int next = state.page - 1 < 1 ? 1 : state.page - 1;
    if (next == state.page) return;
    emit(state.copyWith(page: next));
    await _loadList(emit);
  }

  /// `setPage((p) => p + 1)` — `HistoryPage.tsx:420`.
  Future<void> _onNextPage(
    HistoryNextPage event,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(page: state.page + 1));
    await _loadList(emit);
  }

  /// `onBack` — `HistoryPage.tsx:120-124`: `setSelectedId(null)`, then
  /// **`list.refetch()` AND `counts.refetch()`**. Both fire (`B7-AC-37`,
  /// `B7-AC-76`). This is the only thing that ever refetches the tiles after
  /// mount.
  ///
  /// Declared by B7a and dispatched by B7b's detail seam. Unlike a speculative
  /// port, it has a consumer inside B7a's own tests: `B7-AC-37` counts the
  /// requests it issues.
  Future<void> _onReturnedFromDetail(
    HistoryReturnedFromDetail event,
    Emitter<HistoryState> emit,
  ) async {
    await Future.wait(<Future<void>>[
      _loadList(emit),
      _loadCounts(emit),
    ]);
  }

  Future<void> _loadList(Emitter<HistoryState> emit) async {
    final int mine = ++_listGeneration;
    if (!emit.isDone) emit(state.copyWith(listStatus: RegionStatus.loading));

    final Either<Failure, ApplicationPage> result = await listApplications(
      ListApplicationsParams(
        page: state.page,
        filter: state.filter,
        search: state.search,
      ),
    );

    // "a newer request won" — `hooks.ts:73`. A slow page-1 resolving after a
    // fast page-2 must not overwrite page 2 (`B7-AC-21`).
    if (mine != _listGeneration || emit.isDone) return;
    emit(state.withList(result));
  }

  /// The four count queries — `HistoryPage.tsx:99-110`.
  ///
  /// `Promise.all` of four `applications.list({page: 1, per_page: 1, status})`
  /// calls, each reading `p.meta.total`. **Four requests, in parallel, each
  /// asking for one row**, and the number on the tile is the pagination
  /// block's `total` and never the row count (`B7-AC-24`).
  ///
  /// `Promise.all` rejects on the first failure, so one failed count blanks all
  /// four — reproduced by folding the four `Either`s into one status rather
  /// than four.
  Future<void> _loadCounts(Emitter<HistoryState> emit) async {
    final int mine = ++_countsGeneration;
    if (!emit.isDone) emit(state.copyWith(countsStatus: RegionStatus.loading));

    final List<Either<Failure, ApplicationPage>> answers = await Future.wait(
      <String>[kFilterAll, kFilterApproved, kFilterPending, kFilterRejected]
          .map((String filter) => listApplications(
                ListApplicationsParams(
                  page: 1,
                  perPage: kApplicationsCountPerPage,
                  filter: filter,
                ),
              ))
          .toList(growable: false),
    );

    if (mine != _countsGeneration || emit.isDone) return;

    if (answers.any((Either<Failure, ApplicationPage> a) => a.isLeft())) {
      emit(state.copyWith(countsStatus: RegionStatus.failure));
      return;
    }

    final List<int> totals = answers
        .map((Either<Failure, ApplicationPage> a) =>
            a.getOrElse(() => ApplicationPage.empty).total)
        .toList(growable: false);

    emit(state.copyWith(
      countsStatus: RegionStatus.success,
      counts: HistoryCounts(
        total: totals[0],
        approved: totals[1],
        pending: totals[2],
        rejected: totals[3],
      ),
    ));
  }
}

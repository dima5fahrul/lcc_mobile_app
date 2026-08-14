part of 'history_bloc.dart';

/// One region's position in the four-state contract.
///
/// `initial` is distinct from `loading` for the reason `NewsState`'s
/// `RegionStatus` gives: "nothing has been asked for" and "we asked and are
/// waiting" are different screens, and conflating them makes a
/// never-dispatched region render a spinner forever.
enum RegionStatus { initial, loading, success, failure }

/// The four stat tiles' numbers — `HistoryPage.tsx:99-110`'s
/// `{total, approved, pending, rejected}`.
///
/// A record of four `meta.total`s, never a count of rows. [zero] is the
/// source's `counts.data ?? {total: 0, …}` fallback (`:131`), which is only
/// ever read after `counts.loading` has been checked — while loading, the
/// tiles print `"—"` and not `0` (`:186`, `B7-AC-36`).
class HistoryCounts extends Equatable {
  const HistoryCounts({
    required this.total,
    required this.approved,
    required this.pending,
    required this.rejected,
  });

  static const HistoryCounts zero =
      HistoryCounts(total: 0, approved: 0, pending: 0, rejected: 0);

  final int total;
  final int approved;
  final int pending;
  final int rejected;

  @override
  List<Object?> get props => <Object?>[total, approved, pending, rejected];
}

@freezed
abstract class HistoryState with _$HistoryState {
  const factory HistoryState({
    // ── The list ─────────────────────────────────────────────────────────────
    @Default(RegionStatus.initial) RegionStatus listStatus,
    @Default(ApplicationPage.empty) ApplicationPage result,

    // ── The four tiles ───────────────────────────────────────────────────────
    @Default(RegionStatus.initial) RegionStatus countsStatus,
    @Default(HistoryCounts.zero) HistoryCounts counts,

    // ── The pipeline ─────────────────────────────────────────────────────────
    //
    // Seeded, not empty. `statusCatalogue.ts:27-33` exports `PIPELINE`
    // pre-populated so a progress bar never renders blank and so an offline
    // start still counts "Step 1 of 5" against something.
    @Default(StatusPipeline.seeded) StatusPipeline pipeline,

    /// The selected chip — a key of `kFilterStatuses`.
    @Default(kFilterAll) String filter,

    /// What is in the box right now. Moves on every keystroke so the field is
    /// not laggy.
    @Default('') String searchQuery,

    /// The debounced, trimmed term that is actually on the wire —
    /// `useDebounced(query.trim(), 350)`.
    @Default('') String search,

    /// The requested page. Moves on tap, ahead of the response, so the pager
    /// does not lag its own controls.
    @Default(1) int page,

    /// The failed list response's own message — `list.error.message`,
    /// `HistoryPage.tsx:254`.
    ///
    /// The web prints the **API's** sentence here, not one of its own, so the
    /// port carries it rather than dropping it on the fold. An earlier cut of
    /// this file discarded the `Failure` and rendered a fixed
    /// `history.listError` string; that reads better and is a divergence
    /// (`B7-AC-35`, ADR-0001 — the shipped web is the source of truth, and
    /// "mirror the web exactly" beats cleverness).
    @Default('') String listError,
  }) = _HistoryState;

  const HistoryState._();

  /// `list.loading` — `HistoryPage.tsx:235`.
  ///
  /// `initial` counts as loading: the route builder dispatches
  /// [HistoryStarted] in the same frame it creates the BLoC, so the one frame
  /// before the handler runs must render the skeleton and not the empty state.
  bool get listLoading =>
      listStatus == RegionStatus.loading || listStatus == RegionStatus.initial;

  /// `list.error` — `HistoryPage.tsx:250`.
  bool get listFailed => listStatus == RegionStatus.failure;

  /// `list.loading && rows.length === 0` — `HistoryPage.tsx:235`.
  ///
  /// **Both halves.** A refetch with rows already on screen keeps the rows
  /// rather than flashing three skeletons, which is what the source's `&&`
  /// buys and what `B7-AC-34` asserts.
  bool get showSkeleton => listLoading && rows.isEmpty;

  /// `rows.length === 0` — `HistoryPage.tsx:266`, evaluated only after the
  /// loading and error branches above.
  bool get listEmpty => !listLoading && !listFailed && rows.isEmpty;

  List<ApplicationRow> get rows => result.rows;

  /// `search || filter !== "all"` — `HistoryPage.tsx:274`. Picks which of the
  /// two empty-state subtitles renders (`B7-AC-33`).
  bool get isFiltered => search.isNotEmpty || filter != kFilterAll;

  /// `counts.loading` — `HistoryPage.tsx:186`. `initial` counts as loading for
  /// the same one-frame reason [listLoading] does; the tiles print `"—"`.
  bool get countsLoading =>
      countsStatus == RegionStatus.loading ||
      countsStatus == RegionStatus.initial;

  /// `meta && meta.total_pages > 1` — `HistoryPage.tsx:407`.
  ///
  /// **Only that.** Unlike `/news` (`NewsPage.tsx:205`, four conditions), the
  /// history pager is *not* additionally gated on `!loading || !error`; it
  /// stays mounted across a refetch with its buttons disabled (`:411`, `:422`).
  /// Porting news' extra two conditions would make it disappear and reappear
  /// on every page turn.
  bool get showPager => result.showPager;

  /// `disabled={!meta.has_prev || list.loading}` — `HistoryPage.tsx:411`.
  bool get canGoPrev => result.hasPrev && !listLoading;

  /// `disabled={!meta.has_next || list.loading}` — `HistoryPage.tsx:422`.
  bool get canGoNext => result.hasNext && !listLoading;

  /// Folds a list response into the state.
  HistoryState withList(Either<Failure, ApplicationPage> response) =>
      response.fold(
        (Failure failure) => copyWith(
          listStatus: RegionStatus.failure,
          listError: failure.message,
        ),
        (ApplicationPage page) => copyWith(
          listStatus: RegionStatus.success,
          listError: '',
          result: page,
          // The server is the authority on which page it actually served — a
          // `page` the client incremented past the end comes back clamped, and
          // taking the response's number keeps the `3 / 3` readout honest.
          page: page.page,
        ),
      );
}

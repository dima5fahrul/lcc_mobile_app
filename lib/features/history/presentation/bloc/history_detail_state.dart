part of 'history_detail_bloc.dart';

@freezed
abstract class HistoryDetailState with _$HistoryDetailState {
  const factory HistoryDetailState({
    /// Which case is open. Empty before [HistoryDetailStarted].
    @Default('') String applicationId,

    // ── The detail query ─────────────────────────────────────────────────────
    @Default(RegionStatus.initial) RegionStatus detailStatus,
    ApplicationDetail? detail,

    /// `detailQuery.error?.message` — **the backend's own sentence**
    /// (`HistoryDetailPage.tsx:205`), not a fixed string of the app's.
    ///
    /// B7a's list state carries the same field for the same reason and records
    /// the mistake that made it necessary: an earlier cut rendered a fixed
    /// `history.listError` and discarded the `Failure` entirely. `B7-AC-35`
    /// pinned that; this is the same shape one page over, so it is written
    /// carrying the message from the first line rather than fixed later.
    @Default('') String detailError,

    /// `detailQuery.error?.isNotFound` — `:201`. **A separate field, not a
    /// substring test on [detailError]**: the two branches print different copy
    /// and telling them apart by matching the message text works right up until
    /// the backend rewords a sentence (`B7-AC-54`).
    @Default(false) bool detailNotFound,

    /// `detailQuery.refreshing` — `:414` spins the glyph on this and nothing
    /// else. True only while a reload runs with a case already on screen.
    @Default(false) bool refreshing,

    // ── The timeline query ───────────────────────────────────────────────────
    @Default(RegionStatus.initial) RegionStatus timelineStatus,

    /// **Null until the query succeeds**, and that nullability is the first
    /// link of `:249`'s fallback chain — see [events].
    CaseTimeline? timeline,
    @Default('') String timelineError,
  }) = _HistoryDetailState;

  const HistoryDetailState._();

  bool get hasDetail => detail != null;

  /// `detailQuery.loading && !detail` — `:170`.
  ///
  /// **Both halves.** A refresh with the case on screen must not replace it
  /// with three skeleton cards; that is what `refreshing` is for.
  /// `initial` counts as loading for `HistoryState.listLoading`'s reason: the
  /// page dispatches `Started` in the frame it builds the BLoC, and the frame
  /// before the handler runs must render the skeleton rather than the
  /// not-found card.
  bool get showSkeleton =>
      !hasDetail &&
      (detailStatus == RegionStatus.loading ||
          detailStatus == RegionStatus.initial);

  /// `if (!detail)` — `:200`, evaluated **after** the loading branch. Reaching
  /// it means the case is absent and nothing is in flight.
  bool get showDetailError => !hasDetail && !showSkeleton;

  /// `timelineQuery.data?.events ?? detail.timeline ?? []` — `:249`.
  ///
  /// The chain has three distinguishable arrangements and `B7-AC-62` asserts
  /// all three:
  ///
  /// 1. the timeline query answered → **its** events, even when empty (an empty
  ///    `events: []` is an answer, not an absence, and does not fall through);
  /// 2. it has not answered, or failed → the detail payload's inlined
  ///    `timeline`, which is why [CaseTimeline] is null rather than
  ///    `CaseTimeline.empty` until success;
  /// 3. neither → the empty list, and the timeline card's empty state.
  List<CaseEvent> get events =>
      timeline?.events ?? detail?.timeline ?? const <CaseEvent>[];

  /// `timelineQuery.loading && events.length === 0` — `:510`.
  bool get timelineLoading =>
      (timelineStatus == RegionStatus.loading ||
          timelineStatus == RegionStatus.initial) &&
      events.isEmpty;

  /// `timelineQuery.error && events.length === 0` — `:522`.
  ///
  /// **Both halves again**: a failed refetch that still has the detail's
  /// inlined trail keeps rendering the trail rather than replacing it with a
  /// retry panel.
  bool get timelineFailed =>
      timelineStatus == RegionStatus.failure && events.isEmpty;

  /// `events.length === 0` — `:534`, reached only after the two above.
  bool get timelineEmpty =>
      !timelineLoading && !timelineFailed && events.isEmpty;

  /// Folds a detail response into the state.
  HistoryDetailState withDetail(Either<Failure, ApplicationDetail> response) =>
      response.fold(
        (Failure failure) => copyWith(
          detailStatus: RegionStatus.failure,
          refreshing: false,
          detailError: failure.message,
          detailNotFound: failure is NotFoundFailure,
        ),
        (ApplicationDetail detail) => copyWith(
          detailStatus: RegionStatus.success,
          refreshing: false,
          detailError: '',
          detailNotFound: false,
          detail: detail,
        ),
      );

  /// Folds a timeline response into the state.
  ///
  /// A failure leaves [timeline] **as it was** rather than nulling it: a failed
  /// refetch must not throw away the events already on screen, which is what
  /// `events.length === 0` in the source's error guard depends on.
  HistoryDetailState withTimeline(Either<Failure, CaseTimeline> response) =>
      response.fold(
        (Failure failure) => copyWith(
          timelineStatus: RegionStatus.failure,
          timelineError: failure.message,
        ),
        (CaseTimeline loaded) => copyWith(
          timelineStatus: RegionStatus.success,
          timelineError: '',
          timeline: loaded,
        ),
      );
}

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

    // ── The certificate query (B5, specs.md § 6.6) ───────────────────────────

    /// The **list** query's region status — `certListQuery` (`:149`). The
    /// single fetch at `:157` deliberately does **not** move it: the source's
    /// `:486` gate reads `certListQuery.loading` and nothing else, so folding
    /// the two would make the note disappear during a fetch the source does
    /// not wait for (`B5-AC-44`).
    @Default(RegionStatus.initial) RegionStatus certificateStatus,

    /// `certFromList ?? certOneQuery.data` — `:160`. Null until one of the two
    /// resolves, and permanently null when neither has a match.
    IssuedCertificate? certificate,

    /// **Every** certificate of this application, in the server's list order —
    /// review I-2, 2026-10-22, and the spec's implementation checklist
    /// (*"grouped by `application_id`; label by `document_type` and `copy`"*).
    ///
    /// A divorce issues three rows for one application (joint card, booklet A,
    /// booklet B) and [certificate] can only ever name one of them, so the
    /// document actions read this list instead. Empty until the list query
    /// answers; a single-document application holds exactly one entry and the
    /// surface renders what it always did.
    ///
    /// Carried **beside** [certificate] rather than replacing it: `:160`'s
    /// `certFromList ?? certOneQuery.data` precedence, the single-fetch skip
    /// (`B5-AC-41`) and `showsCertificatePanel` are all about the one row the
    /// source picks, and none of them changes.
    @Default(<IssuedCertificate>[]) List<IssuedCertificate> certificates,

    /// The backend's own sentence when the certificate slice fails. Carried on
    /// its **own** field so a certificate outage cannot be mistaken for a case
    /// outage: the source runs three independent `useQuery`s and the detail and
    /// the timeline keep their data (`B5-AC-31`).
    @Default('') String certificateError,
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

  /// `certListQuery.loading` — `:485`. **True only while the LIST is in
  /// flight** (`B5-AC-44`).
  ///
  /// Unlike [showSkeleton], `initial` does **not** count as loading here, and
  /// that is the source's own shape rather than an oversight: `useQuery`
  /// initialises `loading` to `useState(enabled)` (`hooks.ts:46`), and on the
  /// render where the detail first arrives `enabled` was still false when the
  /// hook last ran — so the source also passes through one commit with
  /// `isIssued == true` and `loading == false`. Counting `initial` as loading
  /// would suppress a state the web has.
  bool get certificateLoading => certificateStatus == RegionStatus.loading;

  /// `isIssued && (certificate || detail.certificate_no)` — `:456`, **both
  /// disjuncts**.
  ///
  /// B7b's own library doc (`history_detail_page.dart:24-32`) records that it
  /// rendered neither half and handed the whole gate to B5: *"half of a card
  /// whose other three rows need B5's payload is worse than the slot B5 fills
  /// whole."* So this getter is the gate, and `history_detail_page.dart` reads
  /// it instead of re-deriving `isIssued` alone.
  ///
  /// **This is a deviation from specs.md § 6.7's literal call-site wording**,
  /// which keeps the gate at `detail.isIssued && certificatePanel != null`.
  /// With the seam retyped to a builder, `certificatePanel != null` is true
  /// from the moment `app_routes.dart` supplies one, so that form would render
  /// an empty white card for an issued case that has neither a certificate nor
  /// a `certificate_no` — a surface the source never draws, which L-10
  /// corollary (b) makes a MAJOR defect. Reported against `B5-AC-47` rather
  /// than absorbed.
  ///
  /// The second disjunct is JavaScript truthiness, so `certificate_no: ""`
  /// does not open the card.
  bool get showsCertificatePanel {
    final ApplicationDetail? d = detail;
    if (d == null || !d.isIssued) return false;
    final String? no = d.row.certificateNo;
    return certificate != null || (no != null && no.isNotEmpty);
  }

  /// Folds the **list** response, plus whatever [matchIssuedCertificate] found
  /// in it.
  ///
  /// A failure leaves [certificate] as it was rather than nulling it, for
  /// `withTimeline`'s reason: a failed refetch must not throw away what is
  /// already on screen.
  HistoryDetailState withCertificateList(
    Either<Failure, List<IssuedCertificate>> response,
    IssuedCertificate? matched,
    List<IssuedCertificate> allMatched,
  ) =>
      response.fold(
        (Failure failure) => copyWith(
          certificateStatus: RegionStatus.failure,
          certificateError: failure.message,
        ),
        (List<IssuedCertificate> _) => copyWith(
          certificateStatus: RegionStatus.success,
          certificateError: '',
          // `certFromList ?? certOneQuery.data` — precedence. A null here is
          // *not* an erasure: the single fetch may still answer below, and if
          // it does not, null is the correct rendered state.
          certificate: matched ?? certificate,
          // Same disposition one list up: an answer with no match does not
          // throw away rows a previous answer found.
          certificates: allMatched.isEmpty ? certificates : allMatched,
        ),
      );

  /// Folds the **single** fetch — `certOneQuery` (`:157`).
  ///
  /// It does not touch [certificateStatus]: that field is the list's, and the
  /// note at `:486` gates on the list alone.
  HistoryDetailState withCertificate(
    Either<Failure, IssuedCertificate> response,
  ) =>
      response.fold(
        (Failure failure) => copyWith(certificateError: failure.message),
        (IssuedCertificate loaded) => copyWith(
          certificateError: '',
          certificate: loaded,
          // This branch is reached only when the list found nothing
          // (`B5-AC-41`), so the one row it answered IS the whole set — the
          // actions row would otherwise render no file for a case whose
          // certificate arrived by the single fetch.
          certificates: <IssuedCertificate>[loaded],
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

part of 'help_bloc.dart';

/// One region's position in the four-state contract (§ 6.6). `initial` is
/// distinct from `loading` for the reason B2b's `RegionStatus` records:
/// "nothing has been asked for" and "we asked and are waiting" are different
/// screens.
enum RegionStatus { initial, loading, success, failure }

@freezed
abstract class HelpState with _$HelpState {
  const factory HelpState({
    // ── Topic chips ──────────────────────────────────────────────────────────
    @Default(RegionStatus.initial) RegionStatus categoriesStatus,
    @Default(<FaqCategory>[]) List<FaqCategory> categories,

    // ── Questions ────────────────────────────────────────────────────────────
    @Default(RegionStatus.initial) RegionStatus faqStatus,
    @Default(HelpFaqPage.empty) HelpFaqPage faqs,

    /// The selected chip — a `FaqCategory.code`, or [kHelpAllTopics].
    @Default(kHelpAllTopics) String topic,

    /// What is in the field **right now**. Moves on every keystroke.
    @Default('') String query,

    /// What the last request was made with. Trails [query] by
    /// [kHelpSearchDebounce] — `useDebounced(query.trim(), 350)`.
    @Default('') String debouncedQuery,

    @Default(1) int page,

    /// The one expanded question's id, or null — `:98`, `setOpen`.
    String? openFaqId,

    // ── Guides ───────────────────────────────────────────────────────────────
    @Default(RegionStatus.initial) RegionStatus guidesStatus,
    @Default(<HelpArticle>[]) List<HelpArticle> guides,

    /// The one expanded guide's slug, or null — `:99`, `setOpenGuide`.
    String? openGuideSlug,

    /// The lazily-fetched body — `enabled: Boolean(openGuide)`.
    @Default(RegionStatus.initial) RegionStatus guideStatus,
    HelpArticle? guideBody,

    // ── Support channels ─────────────────────────────────────────────────────
    @Default(RegionStatus.initial) RegionStatus channelsStatus,
    @Default(<SupportChannel>[]) List<SupportChannel> channels,

    // ── Feedback ─────────────────────────────────────────────────────────────
    /// `voted` — `:100`. Question id → the vote cast this visit. Absent means
    /// "not voted", which is what shows the two thumb controls.
    @Default(<String, bool>{}) Map<String, bool> votes,
  }) = _HelpState;

  const HelpState._();

  // ── Topics ─────────────────────────────────────────────────────────────────

  bool get categoriesLoading =>
      categoriesStatus == RegionStatus.loading ||
      categoriesStatus == RegionStatus.initial;

  bool get categoriesFailed => categoriesStatus == RegionStatus.failure;

  // ── Questions ──────────────────────────────────────────────────────────────

  /// `faqs.loading` — `:259`. `initial` counts, so the frame between `create:`
  /// and the handler running shows the skeleton and not "no results".
  bool get faqsLoading =>
      faqStatus == RegionStatus.loading || faqStatus == RegionStatus.initial;

  bool get faqsFailed => faqStatus == RegionStatus.failure;

  /// `items.length === 0` — `:270`, reached only after loading and error.
  bool get faqsEmpty =>
      faqStatus == RegionStatus.success && faqs.items.isEmpty;

  /// `searching` — `:129`, `query.trim().length > 0`. Reads the **live** query,
  /// not the debounced one: the "Popular right now" pill disappears as soon as
  /// the citizen starts typing, before the request lands.
  bool get searching => query.trim().isNotEmpty;

  /// `!faqs.loading && !faqs.error` — `:252`, the result-count line's guard.
  bool get showResultCount => !faqsLoading && !faqsFailed;

  /// `meta && meta.total_pages > 1 && !faqs.loading && !faqs.error` — `:367`.
  bool get showPager => faqs.showPager && !faqsLoading && !faqsFailed;

  // ── Guides ─────────────────────────────────────────────────────────────────

  bool get guidesLoading =>
      guidesStatus == RegionStatus.loading ||
      guidesStatus == RegionStatus.initial;

  bool get guidesFailed => guidesStatus == RegionStatus.failure;

  bool get guidesEmpty =>
      guidesStatus == RegionStatus.success && guides.isEmpty;

  /// `guide.error` — `:440`, inside the expanded panel.
  bool get guideBodyFailed => guideStatus == RegionStatus.failure;

  /// `guide.data?.slug === g.slug` — `:442`. The body belongs to the guide that
  /// is open, rather than to whichever request finished last.
  bool bodyIsFor(String slug) =>
      guideStatus == RegionStatus.success && guideBody?.slug == slug;

  // ── Channels ───────────────────────────────────────────────────────────────

  bool get channelsLoading =>
      channelsStatus == RegionStatus.loading ||
      channelsStatus == RegionStatus.initial;

  bool get channelsFailed => channelsStatus == RegionStatus.failure;

  /// `(channels.data ?? []).length === 0` — `:478`. The empty branch is **not**
  /// a message: it is the "Contact support" link to `/account` (`:479-486`).
  bool get channelsEmpty =>
      channelsStatus == RegionStatus.success && channels.isEmpty;

  // ── Folding ────────────────────────────────────────────────────────────────

  /// Folds a question-list response in, leaving every other region untouched.
  HelpState withFaqs(Either<Failure, HelpFaqPage> response) => response.fold(
        (Failure _) => copyWith(faqStatus: RegionStatus.failure),
        (HelpFaqPage result) => copyWith(
          faqStatus: RegionStatus.success,
          faqs: result,
          // The server is the authority on which page it served; a client-side
          // increment past the end comes back clamped, and taking the
          // response's number keeps the `2 / 2` readout honest.
          page: result.page,
        ),
      );
}

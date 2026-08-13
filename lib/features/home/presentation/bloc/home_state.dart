part of 'home_bloc.dart';

/// One region's lifecycle.
///
/// **Five regions, five statuses — deliberately not one.** `ServiceBloc` folds
/// its two catalogue queries into a single status because the source renders
/// them as one skeleton and retries them together. Home is the opposite case:
/// `HomePage.tsx` gives the summary, the service grid, the news slider and the
/// FAQ list **their own** `loading` / `error` / `refetch` branches, stacked
/// down the page, and a citizen whose news request fails still sees their
/// applications. Collapsing them would turn four independent failures into one
/// page-wide error — which is a strictly worse screen and a Tier 1 failure
/// besides, because the source presents four different error sentences.
enum RegionStatus {
  /// Not requested. For [HomeState.summaryStatus] and
  /// [HomeState.digitalIdStatus] this is also the **signed-out** state, and it
  /// is why those two regions render as *absent* rather than as a spinner:
  /// `enabled: Boolean(isAuthenticated)` means the request was never made
  /// (§ 6.6, manifest F-4).
  initial,
  loading,
  success,
  failure,
}

/// Which grid the services section is showing.
enum ServiceGridMode {
  /// `displayedServices = homeServices` — the quick actions plus the "More"
  /// tile (`HomePage.tsx:272`).
  quickActions,

  /// `searchQuery.trim()` is non-empty: up to seven matches, no "More" tile
  /// (`HomePage.tsx:264-272`, `:495`).
  search,
}

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState({
    /// Mirrors the `isAuthenticated` prop. The two `me.*` queries are enabled
    /// by it and the hero card switches between the specimen and the citizen's
    /// own record on it.
    @Default(false) bool isAuthenticated,

    // ── /me/home-summary ────────────────────────────────────────────────────
    @Default(RegionStatus.initial) RegionStatus summaryStatus,
    HomeSummary? summary,

    // ── /me/digital-id ──────────────────────────────────────────────────────
    @Default(RegionStatus.initial) RegionStatus digitalIdStatus,
    DigitalIdCard? digitalId,

    // ── /services?phase1=true ───────────────────────────────────────────────
    @Default(RegionStatus.initial) RegionStatus servicesStatus,
    @Default(<Service>[]) List<Service> quickActions,

    // ── /services?search= ───────────────────────────────────────────────────
    @Default(RegionStatus.initial) RegionStatus searchStatus,
    @Default(<Service>[]) List<Service> searchResults,

    /// Exactly what is in the search field, untrimmed — the field shows what
    /// was typed.
    @Default('') String searchQuery,

    /// The trimmed query the last request used. Lags [searchQuery] by up to
    /// [kHomeSearchDebounce].
    @Default('') String debouncedQuery,

    // ── /news?per_page=3&featured=true ──────────────────────────────────────
    @Default(RegionStatus.initial) RegionStatus newsStatus,
    @Default(<HomeNewsItem>[]) List<HomeNewsItem> news,

    // ── /help/faqs?per_page=5 ───────────────────────────────────────────────
    @Default(RegionStatus.initial) RegionStatus faqStatus,
    @Default(<HomeFaqItem>[]) List<HomeFaqItem> faqs,

    /// `useState<number | null>(0)` — `HomePage.tsx:207`. The **first question
    /// is open on arrival**; tapping it closes it and tapping another moves the
    /// open one. Null means all closed.
    @Default(0) int? openFaqIndex,

    /// `showBanner` — `HomePage.tsx:148`. False once the citizen confirms the
    /// dismissal. Per-visit, like the source's `useState`: the web does not
    /// persist it either, so a reload brings the banner back.
    @Default(true) bool bannerVisible,
  }) = _HomeState;

  const HomeState._();

  /// `searchQuery.trim()` — the value every branch below tests, computed once.
  String get query => searchQuery.trim();

  /// `searchQuery.trim()` non-empty — `HomePage.tsx:264`.
  ServiceGridMode get gridMode =>
      query.isEmpty ? ServiceGridMode.quickActions : ServiceGridMode.search;

  /// True inside the debounce window — the same `typing` term
  /// `ServiceBloc` derives, for the same reason: without it the grid shows the
  /// *previous* query's matches while the next request is still in flight, and
  /// a citizen watching rows they did not ask for is worse than a skeleton.
  bool get typing => query != debouncedQuery;

  /// The rows the grid draws.
  List<Service> get displayedServices =>
      gridMode == ServiceGridMode.search ? searchResults : quickActions;

  /// Whether the grid is in its loading state, per mode.
  ///
  /// `initial` counts as loading in search mode for `ServiceState.listLoading`'s
  /// reason: the search grid is only reachable by typing, which always
  /// dispatches a fetch, so an `initial` search status while the search grid is
  /// visible is a frame in flight — and rendering "No services found" for it
  /// would be § 6.6's exact failure mode of showing an empty result where a
  /// spinner belongs.
  bool get servicesLoading => switch (gridMode) {
        ServiceGridMode.quickActions =>
          servicesStatus == RegionStatus.loading ||
              servicesStatus == RegionStatus.initial,
        ServiceGridMode.search => typing ||
            searchStatus == RegionStatus.loading ||
            searchStatus == RegionStatus.initial,
      };

  /// Whether the grid is in its error state, per mode.
  bool get servicesFailed => switch (gridMode) {
        ServiceGridMode.quickActions => servicesStatus == RegionStatus.failure,
        ServiceGridMode.search => searchStatus == RegionStatus.failure,
      };

  /// The four summary tiles are drawn only when the request **succeeded**.
  /// `isAuthenticated && summary.data` — `HomePage.tsx:337`.
  bool get showSummaryTiles =>
      isAuthenticated && summaryStatus == RegionStatus.success;

  /// `isAuthenticated && showBanner && summary.data?.next_action`
  /// — `HomePage.tsx:393`.
  bool get showActionBanner =>
      isAuthenticated && bannerVisible && summary?.nextAction != null;
}

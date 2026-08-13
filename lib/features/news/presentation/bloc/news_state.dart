part of 'news_bloc.dart';

/// One region's position in the four-state contract (§ 6.6).
///
/// `initial` is distinct from `loading` for the reason B2b's `RegionStatus`
/// gives: "nothing has been asked for" and "we asked and are waiting" are
/// different screens, and conflating them makes a never-dispatched region
/// render a spinner forever.
enum RegionStatus { initial, loading, success, failure }

@freezed
abstract class NewsState with _$NewsState {
  const factory NewsState({
    // ── Category chips ───────────────────────────────────────────────────────
    @Default(RegionStatus.initial) RegionStatus categoriesStatus,
    @Default(<NewsCategory>[]) List<NewsCategory> categories,

    // ── The list ─────────────────────────────────────────────────────────────
    @Default(RegionStatus.initial) RegionStatus listStatus,
    @Default(NewsPageResult.empty) NewsPageResult result,

    /// The selected chip — a `NewsCategory.code`, or [kNewsAllCategories].
    @Default(kNewsAllCategories) String filter,

    /// The requested page. Moves on tap, ahead of the response, so the pager
    /// and the chips do not lag their own controls.
    @Default(1) int page,
  }) = _NewsState;

  const NewsState._();

  /// `list.loading` — `NewsPage.tsx:125`.
  ///
  /// `initial` counts as loading: the route builder dispatches [NewsStarted] in
  /// the same frame it creates the BLoC, so the one frame before the handler
  /// runs must render the skeleton and not the empty state.
  bool get listLoading =>
      listStatus == RegionStatus.loading || listStatus == RegionStatus.initial;

  /// `list.error` — `NewsPage.tsx:139`.
  bool get listFailed => listStatus == RegionStatus.failure;

  /// `items.length === 0` — `NewsPage.tsx:150`, evaluated only after the two
  /// branches above.
  bool get listEmpty =>
      listStatus == RegionStatus.success && result.articles.isEmpty;

  List<NewsArticle> get articles => result.articles;

  /// `categories.data ?? []` renders the chips; a failure shows the retry.
  bool get categoriesLoading =>
      categoriesStatus == RegionStatus.loading ||
      categoriesStatus == RegionStatus.initial;

  bool get categoriesFailed => categoriesStatus == RegionStatus.failure;

  /// `meta && meta.total_pages > 1 && !list.loading && !list.error` —
  /// `NewsPage.tsx:205`. All four conditions, in one place, because the pager
  /// appearing over a skeleton is exactly the glitch the source's `&&` chain
  /// prevents.
  bool get showPager => result.showPager && !listLoading && !listFailed;

  /// Folds a list response into the state, leaving the chips untouched.
  NewsState withList(Either<Failure, NewsPageResult> response) =>
      response.fold(
        (Failure _) => copyWith(listStatus: RegionStatus.failure),
        (NewsPageResult page) => copyWith(
          listStatus: RegionStatus.success,
          result: page,
          // The server is the authority on which page it actually served — a
          // `page` the client incremented past the end comes back clamped, and
          // taking the response's number keeps the `3 / 3` readout honest.
          page: page.page,
        ),
      );
}

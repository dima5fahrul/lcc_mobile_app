part of 'news_detail_bloc.dart';

@freezed
abstract class NewsDetailState with _$NewsDetailState {
  const factory NewsDetailState({
    /// The route parameter this state is about. Held so a widget test can
    /// assert the page asked for what the router gave it.
    @Default('') String slug,

    // ── The article ──────────────────────────────────────────────────────────
    @Default(RegionStatus.initial) RegionStatus status,
    NewsArticle? article,

    /// True when the failure was a 404 — the **empty** branch
    /// (`NewsDetailPage.tsx:141`), not the error one.
    @Default(false) bool notFound,

    // ── "More news" ──────────────────────────────────────────────────────────
    @Default(RegionStatus.initial) RegionStatus moreStatus,
    @Default(<NewsArticle>[]) List<NewsArticle> more,
  }) = _NewsDetailState;

  const NewsDetailState._();

  /// `resolving` — `NewsDetailPage.tsx:85`, restricted to the article (the
  /// catalogue no longer gates identity; see the BLoC's doc).
  ///
  /// `initial` counts, so the frame between `create:` and the handler running
  /// renders the skeleton rather than the not-found copy.
  bool get loading =>
      status == RegionStatus.loading || status == RegionStatus.initial;

  /// `loadError && !loadError.isNotFound` — `:117`. Error-with-retry.
  bool get failed => status == RegionStatus.failure && !notFound;

  /// `!article` after the two branches above — `:141`. Empty, with a way back
  /// and **no retry**: re-requesting a 404 cannot succeed.
  bool get missing =>
      !loading && !failed && article == null;

  /// `more.length > 0` — `:254`. A failed catalogue renders no strip, which is
  /// what `catalogue.data ?? []` does on the web.
  bool get showMore =>
      moreStatus == RegionStatus.success && more.isNotEmpty;
}

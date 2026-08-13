/// One page of `GET /news` — the rows plus the pager the list actually draws.
///
/// The web reads `list.data.meta` directly (`NewsPage.tsx:54`) and the pager at
/// `:205-227` consults four of its six fields: `total_pages`, `page`,
/// `has_prev`, `has_next`. `core/network/envelope.dart`'s `Paged<T>` already
/// carries exactly that, but it is a **data-layer** type parameterised over the
/// wire row, and `domain/` may not depend on `data/` (G-L2).
///
/// So this is the domain-side pair: entities plus the same four numbers,
/// nothing else. `total` and `per_page` are deliberately absent — the news
/// pager never prints a count, unlike Help's `resultsMany` (which is why
/// `HelpFaqPage` carries `total` and this does not).
library;

import 'package:equatable/equatable.dart';

import '../entities/news_article.dart';

/// Value equality via [Equatable], not identity. `NewsState` is a `@freezed`
/// class, so its generated `==` compares fields — and a plain class here would
/// make every state carrying a freshly-parsed page compare unequal to an
/// identical one, which turns `bloc_test`'s `expect:` into an identity check
/// nobody can satisfy.
class NewsPageResult extends Equatable {
  const NewsPageResult({
    required this.articles,
    required this.page,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  /// An empty first page — the shape the **empty** state renders from
  /// (`NewsPage.tsx:150`, `items.length === 0`).
  static const NewsPageResult empty = NewsPageResult(
    articles: <NewsArticle>[],
    page: 1,
    totalPages: 1,
    hasNext: false,
    hasPrev: false,
  );

  final List<NewsArticle> articles;

  final int page;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  /// `meta && meta.total_pages > 1` — `NewsPage.tsx:205`. The pager is hidden
  /// entirely on a single-page result, which is the state staging is in today
  /// (6 articles, `per_page` 6).
  bool get showPager => totalPages > 1;

  @override
  List<Object?> get props =>
      <Object?>[articles, page, totalPages, hasNext, hasPrev];
}

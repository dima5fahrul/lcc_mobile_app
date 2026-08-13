part of 'news_bloc.dart';

/// The list page's events — one per control the citizen can operate, plus the
/// mount fetch and the two retries § 6.6 requires.
sealed class NewsEvent {
  const NewsEvent();
}

/// The mount fetch, dispatched by the `/news` route builder.
final class NewsStarted extends NewsEvent {
  const NewsStarted();
}

/// `Try again` under a failed chip row.
///
/// The source has no such control — a failed `content.newsCategories` renders
/// `[]` silently (`NewsPage.tsx:103`). § 6.6 and B2-AC-16 make
/// error-with-retry mandatory per network-backed surface, so this is an
/// **addition**, recorded in the Tier 1 oracle as one rather than smuggled in.
final class NewsCategoriesRetried extends NewsEvent {
  const NewsCategoriesRetried();
}

/// `list.refetch` — `NewsPage.tsx:143`.
final class NewsListRetried extends NewsEvent {
  const NewsListRetried();
}

/// `pick(code)` — `NewsPage.tsx:56`. [category] is a `NewsCategory.code`, or
/// [kNewsAllCategories].
final class NewsCategoryPicked extends NewsEvent {
  const NewsCategoryPicked(this.category);

  final String category;
}

/// The pager's left control — `NewsPage.tsx:208`.
final class NewsPreviousPage extends NewsEvent {
  const NewsPreviousPage();
}

/// The pager's right control — `NewsPage.tsx:219`.
final class NewsNextPage extends NewsEvent {
  const NewsNextPage();
}

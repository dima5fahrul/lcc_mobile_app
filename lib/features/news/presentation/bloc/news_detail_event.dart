part of 'news_detail_bloc.dart';

sealed class NewsDetailEvent {
  const NewsDetailEvent();
}

/// The mount fetch, dispatched by the `/news/:slug` route builder.
final class NewsDetailStarted extends NewsDetailEvent {
  const NewsDetailStarted();
}

/// The error state's `Try again` — `NewsDetailPage.tsx:122`.
final class NewsDetailRetried extends NewsDetailEvent {
  const NewsDetailRetried();
}

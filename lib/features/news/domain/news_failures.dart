/// The one failure the news pages must tell apart from every other.
///
/// `NewsDetailPage.tsx:117` branches on it explicitly:
///
/// ```tsx
/// if (loadError && !loadError.isNotFound) { …error panel with Try again… }
/// if (!article)                           { …t("empty") + Back to news… }
/// ```
///
/// So a **404 is not an error state** on that page — it is the "unknown /
/// missing article" state, which renders the empty copy and a way back, with no
/// retry button (retrying a 404 cannot succeed). Every other failure — offline,
/// 500, a malformed row — is the error-with-retry state.
///
/// Collapsing the two would break § 6.6 in the direction that matters: an
/// article that does not exist would offer a Try-again button that can only
/// ever fail again.
///
/// This subclasses [Failure] rather than adding a field to it because
/// `lib/core/error/**` is outside B2c's § 3.1 scope, and because a subtype is
/// what lets `is NewsArticleNotFound` be the whole test at the call site.
library;

import '../../../core/error/failure.dart';

/// `GET /news/<slug>` answered 404 — `ApiException.isNotFound`.
class NewsArticleNotFound extends Failure {
  const NewsArticleNotFound(super.message);
}

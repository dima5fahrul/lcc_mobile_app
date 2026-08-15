/// The one failure distinction the application feature's read slice makes.
///
/// ## Why this file exists at all
///
/// `application_repository_impl.dart:8-10` — written by B7a — says it plainly:
///
/// > *"B7b's detail page **does** distinguish not-found (`:200-238`,
/// > `B7-AC-54`) and adds its own failure type additively when it lands; adding
/// > it here speculatively would be a branch with no reader."*
///
/// This is that type, and B7b is the reader. `HistoryDetailPage.tsx:201`
/// branches on `detailQuery.error?.isNotFound` — a 404 gets *"This application
/// could not be found."* and everything else gets the API's own sentence or a
/// generic fallback. Without a distinguishable failure the two branches would
/// have to be told apart by string-matching an error message, which is the
/// shape of thing that works until the backend rewords a sentence.
///
/// ## A recorded scope deviation — § 3.1's B7b table does not name this file
///
/// The B7b row grants `lib/features/application/domain/**` as *"modify —
/// **additive**: `ApplicationDetail`, `CaseEvent`, `Attachment`, `CaseTimeline`,
/// and their two usecases"*. The **path** covers this file; the enumeration
/// does not name it. The alternatives are worse and are all out of scope or
/// forbidden:
///
/// * putting the flag on `lib/core/error/failure.dart` — `lib/core/**` is
///   granted to B7b for `api_endpoint.dart` only, and every feature in the tree
///   would inherit a field one page reads;
/// * having `HistoryDetailBloc` string-match the message — see above;
/// * dropping the distinction — `B7-AC-54` is then unmeetable, and the citizen
///   sees *"could not be loaded"* for a case that does not exist.
///
/// Recorded in the batch hand-back rather than slipped in, exactly as B7a
/// recorded `lib/features/history/di/` and `application_formatting.dart`.
///
/// ## It carries the API's message too
///
/// `ApiException.toString()` is `ApiException(404, NOT_FOUND, …)` — a Dart type
/// dump. `HistoryDetailPage.tsx:205` renders `detailQuery.error?.message`, the
/// backend's **sentence**, so the detail's mapping keeps [Failure.message] as
/// the bare message. B7a's list path folds `e.toString()` instead; that
/// difference is measured, is B7a's to resolve, and is recorded in B7b's
/// hand-back rather than changed here — editing it would rewrite the string
/// `B7-AC-35` pins, in a file whose behaviour B7b was not asked to change.
library;

import '../../../core/error/failure.dart';
import '../../../core/network/api_exception.dart';

/// A read that answered **404**.
///
/// `ApiError.isNotFound` — `client.ts:92-94`, `status === 404` — ported as a
/// type rather than a bool because `Failure` is what crosses the repository
/// boundary and it has no status field to inspect.
///
/// Equality includes the runtime type (Equatable compares `runtimeType` before
/// `props`), so a `NotFoundFailure('x')` and a plain `Failure('x')` are **not**
/// equal — which is what makes a bloc test able to tell the two branches apart
/// on state alone.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// A **write** that failed, with the exception kept.
///
/// ## Why the write half needs this and the read half does not
///
/// `ResidentCertificatePage.tsx:573` asks the caught error two questions —
/// `err.isValidation` and `err.fields.length` — and then calls `err.fieldMap()`
/// (`:574`) to build the per-field error map the wizard renders and routes on
/// (`F1-AC-63`). A `Failure` carrying only a `String` has thrown all three away.
///
/// The read half never asks: `HistoryPage.tsx:250-264` is one error panel
/// whatever the status, and `HistoryDetailPage.tsx:201` needs one bit, which
/// [NotFoundFailure] already carries. So this is added rather than
/// `Failure.message` being widened, and rather than `_guard` being rewritten —
/// `B7-AC-35` pins the string the list's error panel renders and F1 has no
/// business changing it (`specs.md` § 6.3's "merge, not rewrite").
///
/// [Failure.message] is the API's own **sentence**, matching [NotFoundFailure]
/// and matching what `:711` renders — `submitError.message`, not a type dump.
class ApiFailure extends Failure {
  const ApiFailure(this.exception, super.message);

  final ApiException exception;

  /// `err instanceof ApiError && err.isValidation && err.fields.length` —
  /// `:573`, as one question.
  bool get isValidation => exception.isValidation && exception.fields.isNotEmpty;

  @override
  List<Object?> get props => <Object?>[message, exception];
}

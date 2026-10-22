/// The verify slice's `Failure` leaves — the `application_failures.dart`
/// pattern: a typed leaf of [Failure] so a consumer can branch on the Left's
/// **type** without the repository growing a status field or the bloc parsing
/// message strings.
///
/// ## Why 429 gets a leaf and nothing else does
///
/// The guide gives exactly one status a distinct SCREEN: `429
/// TOO_MANY_REQUESTS` → "Please wait a minute; never retry in a loop" (§
/// Errors). Everything else that folds left — a 5xx, a network failure, a
/// malformed body — renders the same failure sentence, so a leaf per status
/// would be types nothing can render. `not-found` needs none either: it is a
/// 200 and a Right (§ Errors), never a Failure at all.
///
/// Equality includes the runtime type (Equatable compares `runtimeType`
/// before `props`), so `TooManyRequestsFailure('x')` and a plain
/// `Failure('x')` are **not** equal — which is what lets the bloc and its
/// tests tell the two branches apart on state alone.
library;

import '../../../core/error/failure.dart';

/// A read that answered **429 TOO_MANY_REQUESTS** — 30 checks per minute per
/// IP on `/verify` (§ Errors).
class TooManyRequestsFailure extends Failure {
  const TooManyRequestsFailure(super.message);
}

part of 'verify_bloc.dart';

/// `VerifyState` — the five-state contract the brief fixes:
/// `initial | loading | result(VerificationResult) | tooManyRequests |
/// failure(String)`.
///
/// Free **union shape, not a status enum over shared fields**, for the same
/// reason `HelpState`'s per-region enums exist: the four non-initial states
/// are four different SCREENS, and a status + three nullable fields would let
/// a fourth combination (`result` AND `failure`) exist in the type but not in
/// the contract. The union makes the impossible states unrepresentable.
///
/// `not-found` is deliberately NOT here: it arrives as a `result` with
/// `status: "not-found"` (200, § Errors — "an unknown code or hash is not an
/// HTTP error"), and its screen is one of the five result screens.
@freezed
sealed class VerifyState with _$VerifyState {
  const VerifyState._();

  /// Nothing has been asked for. Distinct from `loading` for the standing
  /// reason: "no request in flight" and "a request is in flight" are
  /// different screens.
  const factory VerifyState.initial() = VerifyInitial;

  /// A request is in flight.
  const factory VerifyState.loading() = VerifyLoading;

  /// An answer — including `status: "not-found"`, which is a normal 200.
  const factory VerifyState.result(VerificationResult result) = VerifyResult;

  /// `429 TOO_MANY_REQUESTS` (30 per minute per IP, § Errors). A distinct
  /// state so the page renders "please wait a minute" and offers **no retry
  /// button** — "never retry in a loop" is the guide's own sentence, and a
  /// state that carries no message cannot be worded into one.
  const factory VerifyState.tooManyRequests() = VerifyTooManyRequests;

  /// Anything else that failed: the server's sentence as Task 3's `_guard`
  /// folded it (`ApiException.message`, or the transport error's `toString()`
  /// where no sentence exists). Rendered verbatim — the same fidelity the
  /// `error_fold_shape_test.dart` guard exists to keep.
  const factory VerifyState.failure(String message) = VerifyFailure;

  // ── The union's shared readers ────────────────────────────────────────────
  // Four one-line getters so a test (and the page) can ask a question of ANY
  // state without a `map` — the same shape `NotificationsState.showsDot` is.
  // Each answers null/false off its own branch; a `result` AND a `failure`
  // can never both be non-null because they live on different union members.

  /// The answer, when this is [VerifyResult] — null on every other member.
  VerificationResult? get result =>
      switch (this) { VerifyResult(:final result) => result, _ => null };

  /// True on [VerifyLoading] and on nothing else.
  bool get isLoading => this is VerifyLoading;

  /// True on [VerifyTooManyRequests] and on nothing else.
  bool get isTooManyRequests => this is VerifyTooManyRequests;

  /// The server's sentence, when this is [VerifyFailure] — null elsewhere.
  String? get failure =>
      switch (this) { VerifyFailure(:final message) => message, _ => null };
}

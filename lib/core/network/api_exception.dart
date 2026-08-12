/// `ApiException` — the machine-readable error thrown by [ApiClient] when the
/// server returns a non-success envelope or a transport failure occurs.
///
/// Ported from `lcc-app/src/app/api/client.ts` `ApiError`:
/// - `status`  : HTTP status code (0 for transport failures).
/// - `code`    : machine-readable error code from the envelope, or a
///               [ApiCode] constant. See [ApiCode].
/// - `message` : human-readable message (safe to surface to the user).
/// - `fields`  : per-field validation errors; empty list when not a validation
///               error. Use [fieldMap] to look up by field name when rendering
///               a form.
/// - `requestId`: the server's request-id, if present — useful for support.
library;

import 'package:equatable/equatable.dart';

import 'envelope.dart';

/// Machine-readable error codes the backend may send in `envelope.code`.
///
/// Ported verbatim from the TS `ApiCode` union. Keep in sync with the server's
/// `ApiCode` set — these are the codes the citizen portal is expected to
/// branch on.
class ApiCode {
  ApiCode._();

  static const String badRequest = 'BAD_REQUEST';
  static const String validationError = 'VALIDATION_ERROR';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String forbidden = 'FORBIDDEN';
  static const String notFound = 'NOT_FOUND';
  static const String conflict = 'CONFLICT';
  static const String unprocessable = 'UNPROCESSABLE';
  static const String tooManyRequests = 'TOO_MANY_REQUESTS';
  static const String internalError = 'INTERNAL_ERROR';
  static const String serviceUnavailable = 'SERVICE_UNAVAILABLE';
  static const String invalidStateTransition = 'INVALID_STATE_TRANSITION';
  static const String paymentRequired = 'PAYMENT_REQUIRED';
  static const String insufficientFunds = 'INSUFFICIENT_FUNDS';
  static const String networkError = 'NETWORK_ERROR';
}

/// Error thrown by [ApiClient] when the server returns a non-success envelope
/// or when the network call itself fails.
///
/// Implements [Equatable] so it compares by content — useful in bloc tests
/// that assert `emitEquals([ApiException(...)])`.
class ApiException extends Equatable implements Exception {
  const ApiException({
    required this.status,
    required this.code,
    required this.message,
    this.fields = const <FieldError>[],
    this.requestId,
  });

  /// HTTP status code. `0` when the request never reached the server.
  final int status;

  /// Machine-readable code — one of [ApiCode] or a server-defined string.
  final String code;

  /// Human-readable message. Safe to surface to the user.
  final String message;

  /// Per-field validation errors. Empty when not a validation error.
  final List<FieldError> fields;

  /// The server's request-id, if present.
  final String? requestId;

  /// Field errors keyed by field name — a form looks up its fields as it
  /// renders. Ported from `ApiError.fieldMap()`.
  Map<String, String> fieldMap() {
    final out = <String, String>{};
    for (final f in fields) {
      out[f.field] = f.message;
    }
    return out;
  }

  /// True when the error is a validation failure — either the code is
  /// `VALIDATION_ERROR` or the HTTP status is 422.
  bool get isValidation => code == ApiCode.validationError || status == 422;

  /// True when the HTTP status is 401.
  bool get isUnauthorized => status == 401;

  /// True when the HTTP status is 403.
  bool get isForbidden => status == 403;

  /// True when the HTTP status is 404.
  bool get isNotFound => status == 404;

  @override
  List<Object?> get props => [status, code, message, fields, requestId];

  @override
  String toString() =>
      'ApiException($status, $code, $message${requestId == null ? '' : ', requestId: $requestId'}${fields.isEmpty ? '' : ', ${fields.length} field(s)'})';
}

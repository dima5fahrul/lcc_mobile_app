/// Exception hierarchy used by the data/domain layers.
///
/// Extends the flutter-boilerplate set (`ServerException`, `ClientException`,
/// `CacheException`) with two LCC-specific additions:
/// - [ValidationException] — a form-validation failure carrying the per-field
///   errors (mirrors the TS `ApiError` with `code === VALIDATION_ERROR`).
/// - [AuthException] — an auth/session failure (401 after refresh-exhausted,
///   or a logout).
class ServerException implements Exception {}

class ClientException implements Exception {
  const ClientException(this.message);
  final String message;
}

class CacheException implements Exception {}

/// A form-validation failure from the server.
///
/// `fields` mirrors the `FieldError` list in the envelope; callers that want
/// a plain `Map<String,String>` should use [ApiException.fieldMap] instead —
/// this class is for the domain layer that does not depend on `envelope.dart`.
class ValidationException implements Exception {
  const ValidationException(this.message, [this.fields = const <String, String>{}]);
  final String message;
  final Map<String, String> fields;
}

/// An auth/session failure — expired credentials, refresh failed, or the
/// server rejected the token.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

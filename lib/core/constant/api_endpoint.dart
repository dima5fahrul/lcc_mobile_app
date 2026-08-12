/// API endpoint path constants.
///
/// The base URL is resolved at compile time via `--dart-define=LCC_API_URL`
/// (falling back to the local dev server) — see [ApiEndpoint.baseUrl].
///
/// Every path constant below is a *relative* segment (no host); the Dio
/// `BaseOptions.baseUrl` supplies the host prefix so the path strings stay
/// environment-agnostic.
///
/// Paths are ported verbatim from the web client `lcc-app/src/app/api/endpoints.ts`
/// so a change to the API surface shows up here as a compile error rather than
/// a 404 at runtime.
class ApiEndpoint {
  ApiEndpoint._();

  /// Resolved from `--dart-define=LCC_API_URL` (trimmed, trailing `/` stripped),
  /// falling back to `http://localhost:8080/api/v1` when the define is absent or
  /// empty — mirrors `API_BASE_URL` in `client.ts`.
  static const String _rawBase = String.fromEnvironment(
    'LCC_API_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  static final String baseUrl = _rawBase.trim().replaceAll(RegExp(r'/+$'), '');

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String authRegister = '/auth/citizen/register';
  static const String authRequestOtp = '/auth/citizen/request-otp';
  static const String authVerifyOtp = '/auth/citizen/verify-otp';
  static const String authLogin = '/auth/citizen/login';
  static const String authLoginEid = '/auth/citizen/login/eid';
  static const String authForgotPassword = '/auth/citizen/forgot-password';
  static const String authResetPassword = '/auth/citizen/reset-password';
  static const String authMe = '/auth/me';
  static const String authLogout = '/auth/logout';
  static const String authChangePassword = '/auth/change-password';
  static const String authRefresh = '/auth/refresh';

  // ── The signed-in citizen ──────────────────────────────────────────────────
  static const String meProfile = '/me/profile';
}

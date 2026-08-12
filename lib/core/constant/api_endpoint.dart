/// API endpoint path constants.
///
/// The base URL is resolved at compile time via `--dart-define=LCC_API_URL`
/// (falling back to the staging HTTPS backend) — see [ApiEndpoint.baseUrl].
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
  /// falling back to `https://api.staging.linkit360.la/api/v1` when the define
  /// is absent or empty. The default is HTTPS-only (V-6): a cleartext
  /// `http://` default would ship an insecure backend to release builds.
  static const String _rawBase = String.fromEnvironment(
    'LCC_API_URL',
    defaultValue: 'https://api.staging.linkit360.la/api/v1',
  );

  // V-6 enforcement: release builds must talk to an HTTPS backend. If a release
  // build is compiled with `--dart-define=LCC_API_URL=http://...` the app must
  // fail loudly at startup rather than silently ship cleartext traffic. `assert`
  // alone is stripped in release, so this release-only `StateError` is the real
  // gate. The guard runs on first access of [baseUrl] — i.e. when the Dio client
  // reads `BaseOptions.baseUrl` at app bootstrap.
  static final String baseUrl = (() {
    final String trimmed = _rawBase.trim().replaceAll(RegExp(r'/+$'), '');
    final bool isRelease = const bool.fromEnvironment('dart.vm.product');
    if (isRelease && !trimmed.startsWith('https://')) {
      throw StateError(
        'ApiEndpoint.baseUrl must be HTTPS in release builds, got: "$trimmed". '
        'Compile with --dart-define=LCC_API_URL=https://... or omit the define '
        'to use the HTTPS staging default.',
      );
    }
    return trimmed;
  })();

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

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

  // `endpoints.ts:113,120`'s `me.digitalID` / `me.homeSummary`. Both are
  // authenticated — neither is `anonymous: true` in the source — and both are
  // fired by `HomePage.tsx` with `enabled: Boolean(isAuthenticated)`, so a
  // signed-out citizen never requests them (§ 6.6, manifest F-4). Additive
  // only (SSD § 6.5) — nothing above changed.
  static const String meHomeSummary = '/me/home-summary';
  static const String meDigitalId = '/me/digital-id';

  // ── Service catalogue (public, anonymous) ─────────────────────────────────
  // `endpoints.ts:167-171`'s `catalog.categories` / `catalog.services`. Both
  // are `anonymous: true` in the source and stay so here: the catalogue is
  // readable signed-out, which is what makes a signed-out citizen able to
  // browse all 43 services. Additive only (SSD § 6.5) — nothing above changed.
  static const String serviceCategories = '/service-categories';
  static const String services = '/services';

  // ── Content (public, anonymous, paged) ─────────────────────────────────────
  // `endpoints.ts:368,374`'s `content.news` / `content.faqs`. Both are
  // `anonymous: true` and both are **paged** — the envelope carries `meta`
  // beside the rows, so callers go through `ApiClient.requestPaged`.
  //
  // These two are shared between B2b and B2c: § 2.2 Finding B's table records
  // `/news` as `NewsPage.tsx:45` + `HomePage.tsx:173` and `/help/faqs` as
  // `HelpCenterPage.tsx:109` + `HomePage.tsx:178`. § 3.1's B2b column names
  // only the two `/me/*` paths and its B2c column claims all seven content
  // paths, which leaves the two Home also calls unattributed to the batch that
  // needs them first. Landed here by B2b because B2b cannot render without
  // them; B2c's remaining five paths (`/news/categories`, `/news/:slug`,
  // `/help/categories`, `/help/articles`, `/help/articles/:slug`, and the FAQ
  // feedback POST) are still its own to append. Recorded as a spec gap, not
  // resolved unilaterally.
  static const String news = '/news';
  static const String helpFaqs = '/help/faqs';
}

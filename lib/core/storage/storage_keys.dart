/// String keys used by [StorageService] to persist session, language, and
/// Hive box names in [FlutterSecureStorage].
///
/// Extends the flutter-boilerplate `StorageKeys`:
/// - keeps `token` + `movieBox` for compat (boilerplate used `token`).
/// - adds the LCC token pair (`lcc.access_token`, `lcc.refresh_token`),
///   the language preference, and the Hive session box name.
class StorageKeys {
  StorageKeys._();

  // ── Boilerplate compat (kept so existing boilerplate code still compiles) ──
  /// Legacy single-token key. Prefer [accessToken] / [refreshToken].
  static const String token = 'auth_token';

  /// Legacy Hive box name. Kept for boilerplate compat; LCC uses [sessionBox].
  static const String movieBox = 'movie_box';

  // ── LCC session ───────────────────────────────────────────────────────────
  static const String accessToken = 'lcc.access_token';
  static const String refreshToken = 'lcc.refresh_token';

  // ── LCC preferences ───────────────────────────────────────────────────────
  static const String lang = 'lcc.lang';

  // ── Hive box names ────────────────────────────────────────────────────────
  static const String sessionBox = 'session_box';
}

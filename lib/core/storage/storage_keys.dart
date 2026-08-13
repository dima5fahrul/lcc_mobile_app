/// String keys used by [StorageService] to persist session, language, and
/// Hive box names in [FlutterSecureStorage].
///
/// Holds the LCC token pair (`lcc.access_token`, `lcc.refresh_token`), the
/// language preference, and the Hive session box name.
///
/// **CR-2 (SSD § 6.7)** removed the boilerplate leftovers `token`
/// (`'auth_token'`) and `movieBox` (`'movie_box'`) along with the three
/// `StorageService` methods that used them. Nothing in `lib/` read either key,
/// so no shipped install loses data — and keeping a second token slot alive
/// next to [accessToken] was an invitation to write to the wrong one.
class StorageKeys {
  StorageKeys._();

  // ── LCC session ───────────────────────────────────────────────────────────
  static const String accessToken = 'lcc.access_token';
  static const String refreshToken = 'lcc.refresh_token';

  // ── LCC preferences ───────────────────────────────────────────────────────
  static const String lang = 'lcc.lang';

  // ── Hive box names ────────────────────────────────────────────────────────
  static const String sessionBox = 'session_box';
}

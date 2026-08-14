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

  /// First-run splash gate — `SplashScreens.tsx:31`'s `lcc_onboarding_seen`.
  ///
  /// **Dot-namespaced, not the web's underscore spelling** (B10 § 6.11).
  /// Different store, no interop with `localStorage`, and matching [lang]'s
  /// convention beats matching a key nothing on this side reads.
  static const String onboardingSeen = 'lcc.onboarding_seen';

  /// Home tutorial gate — `HomePage.tsx:212`'s `lcc_tutorial_seen`.
  ///
  /// **Independent of [onboardingSeen].** `manifest.md`:190-191 claimed
  /// dismissing the splash sets both; `:262-264` measured that it does not.
  /// Two keys, two writers: `finish()` (`SplashScreens.tsx:216`) sets only the
  /// former, `handleTutorialDone` (`HomePage.tsx:229`) only the latter.
  static const String tutorialSeen = 'lcc.tutorial_seen';

  // ── Hive box names ────────────────────────────────────────────────────────
  static const String sessionBox = 'session_box';
}

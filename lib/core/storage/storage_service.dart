/// Persistent storage wrapper backed by [FlutterSecureStorage].
///
/// Replaces the flutter-boilerplate `StorageService` (which only knew how to
/// save/read/delete a single token) with the LCC token *pair*, the language
/// preference, and an observable auth-state flag.
///
/// **CR-2 (SSD § 6.7).** The boilerplate's `saveToken` / `getToken` /
/// `deleteToken` are gone, together with `StorageKeys.token` and
/// `StorageKeys.movieBox`. They had zero production call sites — the only code
/// exercising them was the test that asserted they existed — so they were a
/// second, parallel token slot that a future contributor could reach for and
/// silently desynchronise from the pair the interceptors actually read.
///
/// Ported from `lcc-app/src/app/api/client.ts` `tokens` object:
/// - `saveTokens(access, refresh?)`   ← `tokens.set`
/// - `getAccessToken()` / `getRefreshToken()`   ← `tokens.access` / `tokens.refresh`
/// - `clearTokens()`                  ← `tokens.clear`
/// - `isAuthenticated()`              ← `tokens.isAuthenticated()`
/// - `authStateNotifier`              ← the `listeners` Set (ValueNotifier form)
/// - `saveLang` / `getLang`            ← Lao/EN preference, default `"lo"`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'storage_keys.dart';

class StorageService {
  StorageService(this._storage);

  final FlutterSecureStorage _storage;

  /// Notifies `true` when a session is established, `false` when cleared.
  /// Mirrors the `subscribe` Set in the TS `tokens` object.
  final ValueNotifier<bool> authStateNotifier = ValueNotifier<bool>(false);

  // ── LCC token pair ─────────────────────────────────────────────────────────
  /// Persists the access token and (optionally) the refresh token, then fires
  /// [authStateNotifier]. Mirrors `tokens.set(access, refresh?)`.
  Future<void> saveTokens(String access, [String? refresh]) async {
    await _storage.write(key: StorageKeys.accessToken, value: access);
    if (refresh != null) {
      await _storage.write(key: StorageKeys.refreshToken, value: refresh);
    }
    authStateNotifier.value = true;
  }

  Future<String?> getAccessToken() =>
      _storage.read(key: StorageKeys.accessToken);

  Future<String?> getRefreshToken() =>
      _storage.read(key: StorageKeys.refreshToken);

  /// Clears both tokens and fires [authStateNotifier] with `false`.
  /// Mirrors `tokens.clear()`.
  Future<void> clearTokens() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    authStateNotifier.value = false;
  }

  /// True when an access token is present.
  /// Mirrors `tokens.isAuthenticated()`.
  Future<bool> isAuthenticated() async => (await getAccessToken()) != null;

  // ── Language preference ───────────────────────────────────────────────────
  /// Persists the UI language code (`"lo"`, `"en"`, ...).
  Future<void> saveLang(String lang) =>
      _storage.write(key: StorageKeys.lang, value: lang);

  /// Reads the UI language code. Defaults to `"lo"` when unset.
  Future<String> getLang() async =>
      (await _storage.read(key: StorageKeys.lang)) ?? 'lo';

  // ── First-run gates (B10 § 6.11) ──────────────────────────────────────────
  //
  // Two booleans, `"1"` or absent, mirroring the web's `localStorage` values.
  //
  // **The failure mode is ported, not just the happy path.**
  // `SplashScreens.tsx:35-41` wraps its read in `try/catch` and returns
  // `false` on any throw — *"private mode / storage blocked — show it, it's
  // harmless"* — and `:43-49` swallows the write error entirely. Both are
  // reproduced below, because this is precisely the branch that ships untested
  // and turns a keychain hiccup into an onboarding loop that a citizen cannot
  // get out of. `FlutterSecureStorage` throws on a locked or unavailable
  // keychain, which is the same class of condition as a blocked
  // `localStorage`.
  //
  // A read failure means **not seen** (show the surface — showing it twice is
  // harmless, hiding it forever is not). A write failure is ignored: the only
  // consequence is that the surface shows again next launch.

  /// `hasSeenOnboarding()` — `SplashScreens.tsx:35-41`. False on any read
  /// failure.
  Future<bool> hasSeenOnboarding() => _readFlag(StorageKeys.onboardingSeen);

  /// `markOnboardingSeen()` — `SplashScreens.tsx:43-49`. Never throws.
  Future<void> markOnboardingSeen() => _writeFlag(StorageKeys.onboardingSeen);

  /// `localStorage.getItem("lcc_tutorial_seen")` — `HomePage.tsx:212`.
  Future<bool> hasSeenTutorial() => _readFlag(StorageKeys.tutorialSeen);

  /// `localStorage.setItem("lcc_tutorial_seen", "1")` — `HomePage.tsx:229`.
  Future<void> markTutorialSeen() => _writeFlag(StorageKeys.tutorialSeen);

  Future<bool> _readFlag(String key) async {
    try {
      return (await _storage.read(key: key)) == '1';
    } catch (_) {
      return false;
    }
  }

  Future<void> _writeFlag(String key) async {
    try {
      await _storage.write(key: key, value: '1');
    } catch (_) {
      /* ignore — see the note above */
    }
  }
}

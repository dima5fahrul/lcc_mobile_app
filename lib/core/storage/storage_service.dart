/// Persistent storage wrapper backed by [FlutterSecureStorage].
///
/// Extends the flutter-boilerplate `StorageService` (which only knew how to
/// save/read/delete a single token) to handle the LCC token *pair*, the
/// language preference, and an observable auth-state flag.
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

  // ── Legacy single-token API (boilerplate compat) ──────────────────────────
  Future<void> saveToken(String token) =>
      _storage.write(key: StorageKeys.token, value: token);

  Future<String?> getToken() => _storage.read(key: StorageKeys.token);

  Future<void> deleteToken() => _storage.delete(key: StorageKeys.token);

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
}

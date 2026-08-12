/// `StorageService` — token pair, auth-state notifier, language preference.
///
/// GOR-245 § 4.2 freezes the four key strings (`lcc.access_token`,
/// `lcc.refresh_token`, `lcc.lang`, `session_box`): renaming any of them signs
/// out every existing install. Several tests below therefore assert on the
/// literal key that reached storage, not just on the round trip — a round trip
/// alone would still pass after a rename.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';

import '../../helpers/core_test_helper.dart';

void main() {
  late Map<String, String> store;
  late StorageService storage;

  setUp(() {
    store = <String, String>{};
    storage = inMemoryStorageService(store);
  });

  group('token pair', () {
    test('saveTokens writes both tokens under the frozen keys', () async {
      await storage.saveTokens('access-1', 'refresh-1');

      expect(store, <String, String>{
        'lcc.access_token': 'access-1',
        'lcc.refresh_token': 'refresh-1',
      });
    });

    test('saveTokens without a refresh token leaves the stored one alone',
        () async {
      await storage.saveTokens('access-1', 'refresh-1');
      await storage.saveTokens('access-2');

      expect(store[StorageKeys.accessToken], 'access-2');
      expect(store[StorageKeys.refreshToken], 'refresh-1');
    });

    test('getAccessToken / getRefreshToken read them back', () async {
      await storage.saveTokens('access-1', 'refresh-1');

      expect(await storage.getAccessToken(), 'access-1');
      expect(await storage.getRefreshToken(), 'refresh-1');
    });

    test('reads null when nothing is stored', () async {
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });

    test('clearTokens removes both', () async {
      await storage.saveTokens('access-1', 'refresh-1');

      await storage.clearTokens();

      expect(store, isEmpty);
      expect(await storage.getAccessToken(), isNull);
    });
  });

  group('isAuthenticated', () {
    test('is false with no access token', () async {
      expect(await storage.isAuthenticated(), isFalse);
    });

    test('is true once an access token is stored', () async {
      await storage.saveTokens('access-1');
      expect(await storage.isAuthenticated(), isTrue);
    });

    test('is false again after clearTokens', () async {
      await storage.saveTokens('access-1');
      await storage.clearTokens();
      expect(await storage.isAuthenticated(), isFalse);
    });
  });

  group('authStateNotifier', () {
    test('starts false', () {
      expect(storage.authStateNotifier.value, isFalse);
    });

    test('fires true on saveTokens and false on clearTokens', () async {
      final List<bool> seen = <bool>[];
      storage.authStateNotifier
          .addListener(() => seen.add(storage.authStateNotifier.value));

      await storage.saveTokens('access-1');
      await storage.clearTokens();

      expect(seen, <bool>[true, false]);
    });
  });

  group('language preference', () {
    test('defaults to lo when unset', () async {
      expect(await storage.getLang(), 'lo');
    });

    test('round-trips the saved code under the frozen key', () async {
      await storage.saveLang('en');

      expect(store[StorageKeys.lang], 'en');
      expect(await storage.getLang(), 'en');
    });
  });

  group('legacy single-token API (boilerplate compatibility)', () {
    test('saves, reads and deletes under the legacy key', () async {
      await storage.saveToken('legacy-1');
      expect(store[StorageKeys.token], 'legacy-1');
      expect(await storage.getToken(), 'legacy-1');

      await storage.deleteToken();
      expect(await storage.getToken(), isNull);
    });

    test('is a separate slot from the LCC access token', () async {
      await storage.saveToken('legacy-1');
      await storage.saveTokens('access-1');

      expect(await storage.getToken(), 'legacy-1');
      expect(await storage.getAccessToken(), 'access-1');
    });
  });

  group('frozen key strings (GOR-245 § 4.2)', () {
    test('are exactly the values every shipped install already holds', () {
      expect(StorageKeys.accessToken, 'lcc.access_token');
      expect(StorageKeys.refreshToken, 'lcc.refresh_token');
      expect(StorageKeys.lang, 'lcc.lang');
      expect(StorageKeys.sessionBox, 'session_box');
      // Legacy boilerplate leftovers — § 5 permits removal only once grep
      // proves zero references, so their values stay pinned meanwhile.
      expect(StorageKeys.token, 'auth_token');
      expect(StorageKeys.movieBox, 'movie_box');
    });
  });
}

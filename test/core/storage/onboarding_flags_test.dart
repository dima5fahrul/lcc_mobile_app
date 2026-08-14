/// The two first-run flags — B10 § 6.11, `B10-AC-35` (storage half) and
/// `B10-AC-46`.
///
/// ## Why the failure path gets more tests than the happy path
///
/// § 6.11 ports the source's error handling verbatim: `hasSeenOnboarding()`
/// (`SplashScreens.tsx`:35-41) catches and returns `false` — *"private mode /
/// storage blocked — show it, it's harmless"* — and `markOnboardingSeen`
/// (`:43-49`) swallows its write error.
///
/// That branch is exactly the kind that ships untested and turns a keychain
/// hiccup into an **onboarding loop**: every launch shows the splash, the
/// write to suppress it throws, and the citizen can never get past it. A test
/// that only exercised the happy path would be green against an implementation
/// that let the exception escape.
///
/// The asymmetry is deliberate and is the source's: a read failure means
/// **not seen** (showing the splash twice is harmless; hiding it forever is
/// not), and a write failure is ignored (the only cost is that it shows again
/// next launch).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/core_test_helper.dart';

/// The condition the source calls "private mode / storage blocked".
/// `FlutterSecureStorage` throws on a locked or unavailable keychain.
class _KeychainUnavailable implements Exception {
  const _KeychainUnavailable();
  @override
  String toString() => 'PlatformException(keychain unavailable)';
}

StorageService _throwingOnRead() {
  final MockSecureStorage mock = MockSecureStorage();
  when(() => mock.read(key: any(named: 'key')))
      .thenThrow(const _KeychainUnavailable());
  when(() => mock.write(key: any(named: 'key'), value: any(named: 'value')))
      .thenAnswer((_) async {});
  return StorageService(mock);
}

StorageService _throwingOnWrite() {
  final MockSecureStorage mock = MockSecureStorage();
  when(() => mock.read(key: any(named: 'key'))).thenAnswer((_) async => null);
  when(() => mock.write(key: any(named: 'key'), value: any(named: 'value')))
      .thenThrow(const _KeychainUnavailable());
  return StorageService(mock);
}

void main() {
  group('the keys are the dot-namespaced ones, not the web\'s underscores', () {
    test('§ 6.11 — `lcc.onboarding_seen` / `lcc.tutorial_seen`', () {
      // Different store, no interop with `localStorage`, so matching the
      // neighbouring `lcc.lang` beats matching a web key nothing reads.
      expect(StorageKeys.onboardingSeen, 'lcc.onboarding_seen');
      expect(StorageKeys.tutorialSeen, 'lcc.tutorial_seen');
    });

    test('the literal key is what reaches storage', () async {
      // A round trip alone would still pass after a rename; this asserts the
      // string that landed, the same way `storage_service_test.dart` does for
      // the frozen token keys.
      final Map<String, String> store = <String, String>{};
      final StorageService storage = inMemoryStorageService(store);

      await storage.markOnboardingSeen();
      await storage.markTutorialSeen();

      expect(store, <String, String>{
        'lcc.onboarding_seen': '1',
        'lcc.tutorial_seen': '1',
      });
    });
  });

  group('B10-AC-35 — the two flags are INDEPENDENT, in both directions', () {
    test('setting only onboarding leaves the tutorial unseen', () async {
      final Map<String, String> store = <String, String>{};
      final StorageService storage = inMemoryStorageService(store);

      await storage.markOnboardingSeen();

      expect(await storage.hasSeenOnboarding(), isTrue);
      expect(
        await storage.hasSeenTutorial(),
        isFalse,
        reason: '`manifest.md`:190-191 claimed dismissing the splash sets '
            'both; :262-264 corrects it — measured, it does not. A fresh '
            'install sees splash → Home → tutorial.',
      );
    });

    test('setting only the tutorial leaves onboarding unseen', () async {
      final Map<String, String> store = <String, String>{};
      final StorageService storage = inMemoryStorageService(store);

      await storage.markTutorialSeen();

      expect(await storage.hasSeenTutorial(), isTrue);
      expect(await storage.hasSeenOnboarding(), isFalse);
    });

    test('neither set: both false', () async {
      final StorageService storage = inMemoryStorageService(<String, String>{});
      expect(await storage.hasSeenOnboarding(), isFalse);
      expect(await storage.hasSeenTutorial(), isFalse);
    });

    test('a value that is not "1" does not count as seen', () async {
      // `_readFlag` compares to '1'. A stray empty string or "false" left by a
      // migration must not suppress the surface.
      final StorageService storage = inMemoryStorageService(<String, String>{
        StorageKeys.onboardingSeen: '',
        StorageKeys.tutorialSeen: 'false',
      });
      expect(await storage.hasSeenOnboarding(), isFalse);
      expect(await storage.hasSeenTutorial(), isFalse);
    });
  });

  group('B10-AC-46 — storage failure is survivable', () {
    test('a READ that throws means "not seen" — the splash shows', () async {
      final StorageService storage = _throwingOnRead();

      // The assertion is that this RETURNS, and returns false. If the
      // exception escaped, `main.dart`'s boot would crash before the first
      // frame — on a device whose keychain happens to be locked at launch.
      expect(
        await storage.hasSeenOnboarding(),
        isFalse,
        reason: 'SplashScreens.tsx:35-41 — "private mode / storage blocked: '
            'show it, it\'s harmless"',
      );
      expect(await storage.hasSeenTutorial(), isFalse);
    });

    test('a WRITE that throws does not propagate', () async {
      final StorageService storage = _throwingOnWrite();

      // `expect(..., completes)` rather than a bare await: an await that threw
      // would fail the test with the raw PlatformException and read as an
      // infrastructure problem rather than as this AC failing.
      await expectLater(storage.markOnboardingSeen(), completes);
      await expectLater(storage.markTutorialSeen(), completes);
    });

    test('the throwing double really does throw — negative control', () async {
      // Without this, every assertion above would also pass against a mock
      // that had been misconfigured to return null, and `B10-AC-46` would be
      // green while testing nothing.
      final MockSecureStorage mock = MockSecureStorage();
      when(() => mock.read(key: any(named: 'key')))
          .thenThrow(const _KeychainUnavailable());
      await expectLater(
        () => mock.read(key: 'anything'),
        throwsA(isA<_KeychainUnavailable>()),
      );
    });
  });
}

/// **R-25 — the language mirror. B8-AC-16, B8-AC-19, B8-AC-20, B8-AC-21.**
///
/// `SessionMirrorLanguage`'s three ported properties
/// (`LanguageToggle.tsx:69-72`), each asserted by the thing that would break if
/// it were absent rather than by the thing that would be present if it worked:
///
/// | Property | Assertion |
/// |---|---|
/// | authenticated only | a **zero** invocation count on the use-case spy |
/// | failure is silent | no emitted state, no rethrow, with a **throwing** use case |
/// | the body | one key, `preferred_lang` |
///
/// The local-first half (B8-AC-19) is the toggle widget's, not this BLoC's, and
/// lives in `test/presentation/shell/language_toggle_r25_test.dart`.
///
/// ## A separate file from `session_bloc_test.dart`
///
/// That file's `build()` hands the BLoC an **unstubbed** `MockUpdateProfile` on
/// purpose, so any of its tests that reached the mirror would fail loudly. This
/// one stubs it, and keeping the two apart is what makes that guarantee
/// readable. Its scope note: specs.md § 3.1's test row names
/// `test/features/account/**`, `test/fidelity/**` and one shell test; a test
/// for the `core/session/bloc/` change § 3.1 *does* authorise has to live
/// somewhere, and beside the file it tests is the least surprising place.
/// Recorded in the hand-back.
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/core/session/bloc/session_bloc.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/core/usecase/usecase.dart';
import 'package:lcc_mobile_app/features/session/data/models/profile_update_body.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/citizen_profile.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/profile_update.dart';
import 'package:lcc_mobile_app/features/session/domain/usecases/update_profile.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/core_test_helper.dart';
import '../../../helpers/session_test_helper.dart';

void main() {
  late Map<String, String> store;
  late StorageService storage;
  late MockGetProfile getProfile;
  late MockSessionRepository repository;
  late MockUpdateProfile updateProfile;

  setUpAll(() {
    registerFallbackValue(NoParams());
    registerFallbackValue(const UpdateProfileParams(ProfileUpdate()));
  });

  setUp(() {
    store = <String, String>{};
    storage = inMemoryStorageService(store);
    getProfile = MockGetProfile();
    repository = MockSessionRepository();
    updateProfile = MockUpdateProfile();
  });

  SessionBloc build() => SessionBloc(
        storage: storage,
        getProfile: getProfile,
        repository: repository,
        updateProfile: updateProfile,
      );

  /// Puts the BLoC in `authenticated` the way the app does — a stored token
  /// plus a successful `GET /me/profile` — rather than by reaching into state.
  Future<void> authenticate(SessionBloc bloc) async {
    store[StorageKeys.accessToken] = 'synthetic-access-token';
    store[StorageKeys.refreshToken] = 'synthetic-refresh-token';
    when(() => getProfile(any())).thenAnswer(
      (_) async => Right<Failure, CitizenProfile>(tCitizenProfile()),
    );
    bloc.add(const SessionEvent.started());
    await bloc.stream.firstWhere(
      (SessionState s) => s.status == SessionStatus.authenticated,
    );
  }

  // ── B8-AC-20 — unauthenticated issues NO request ──────────────────────────

  group('B8-AC-20 — the mirror is gated on `isAuthenticated`', () {
    test('a signed-out citizen produces ZERO calls', () async {
      final SessionBloc bloc = build();
      addTearDown(bloc.close);

      // Boot with no token: `SessionStarted` resolves to `unauthenticated`.
      bloc.add(const SessionEvent.started());
      await bloc.stream.firstWhere(
        (SessionState s) => s.status == SessionStatus.unauthenticated,
      );

      bloc.add(const SessionEvent.mirrorLanguage('en'));
      // Let the handler run to completion before counting.
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => updateProfile(any()));
      // The spy is the assertion. A test that only checked "no error was
      // surfaced" would pass with the request being sent, which is the
      // behaviour `if (isAuthenticated)` exists to prevent —
      // `LanguageToggle.tsx:71`.
    });

    test('the boot hold (`initial`) also produces zero calls', () async {
      final SessionBloc bloc = build();
      addTearDown(bloc.close);

      expect(bloc.state.status, SessionStatus.initial);
      bloc.add(const SessionEvent.mirrorLanguage('lo'));
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => updateProfile(any()));
    });
  });

  // ── B8-AC-16 — the body ───────────────────────────────────────────────────

  test('B8-AC-16 — an authenticated toggle sends exactly '
      '{"preferred_lang": "<next>"}', () async {
    final SessionBloc bloc = build();
    addTearDown(bloc.close);
    await authenticate(bloc);

    when(() => updateProfile(any())).thenAnswer(
      (_) async => Right<Failure, CitizenProfile>(tCitizenProfile()),
    );

    bloc.add(const SessionEvent.mirrorLanguage('en'));
    await Future<void>.delayed(Duration.zero);

    final UpdateProfileParams captured =
        verify(() => updateProfile(captureAny())).captured.single
            as UpdateProfileParams;

    expect(captured.update.preferredLang, 'en');
    expect(captured.update.name, isNull);
    expect(captured.update.email, isNull);
    expect(captured.update.address, isNull);
    // The wire form, not just the entity: one key, and it is the snake_case
    // one. Tier 0 asserts the encoded string; this asserts the value that
    // reaches it from the real dispatch path.
    expect(
      profileUpdateBody(captured.update),
      <String, dynamic>{'preferred_lang': 'en'},
    );
  });

  // ── B8-AC-21 — failure is silent ──────────────────────────────────────────

  group('B8-AC-21 — a rejected mirror is swallowed whole', () {
    test('a Left produces no state change and no throw', () async {
      final SessionBloc bloc = build();
      addTearDown(bloc.close);
      await authenticate(bloc);

      when(() => updateProfile(any())).thenAnswer(
        (_) async => const Left<Failure, CitizenProfile>(
          Failure('the server said no'),
        ),
      );

      final SessionState before = bloc.state;
      final List<SessionState> emitted = <SessionState>[];
      final sub = bloc.stream.listen(emitted.add);
      addTearDown(sub.cancel);

      bloc.add(const SessionEvent.mirrorLanguage('lo'));
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty,
          reason: '`.catch(() => undefined)` — no toast, no error state, no '
              'retry. An emitted state is how an error surface starts.');
      expect(bloc.state, before);
      expect(bloc.state.errorMessage, isNull);
      expect(bloc.state.status, SessionStatus.authenticated);
    });

    test('a THROWN ApiException — including a 401 — does not sign the citizen '
        'out mid-toggle', () async {
      final SessionBloc bloc = build();
      addTearDown(bloc.close);
      await authenticate(bloc);

      // `SessionRepositoryImpl.updateProfile` rethrows `ApiException` for the
      // benefit of the OTHER caller (`AccountProfileBloc`). The mirror must
      // catch it anyway: a 401 here signing the citizen out would make
      // changing language a logout hazard.
      when(() => updateProfile(any())).thenThrow(
        const ApiException(
          status: 401,
          code: 'UNAUTHORIZED',
          message: 'a bearer token is required',
        ),
      );

      final List<SessionState> emitted = <SessionState>[];
      final sub = bloc.stream.listen(emitted.add);
      addTearDown(sub.cancel);

      bloc.add(const SessionEvent.mirrorLanguage('en'));
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      expect(bloc.state.status, SessionStatus.authenticated);
      expect(store[StorageKeys.accessToken], isNotNull,
          reason: 'the tokens must still be there — a swallowed mirror '
              'failure clears nothing');
    });
  });

  // ── The BLoC is otherwise untouched by this event ─────────────────────────

  blocTest<SessionBloc, SessionState>(
    'the mirror emits nothing at all on success either — it is a write, not a '
    'state transition',
    build: () {
      store[StorageKeys.accessToken] = 'synthetic-access-token';
      store[StorageKeys.refreshToken] = 'synthetic-refresh-token';
      when(() => getProfile(any())).thenAnswer(
        (_) async => Right<Failure, CitizenProfile>(tCitizenProfile()),
      );
      when(() => updateProfile(any())).thenAnswer(
        (_) async => Right<Failure, CitizenProfile>(tCitizenProfile()),
      );
      return build();
    },
    act: (SessionBloc bloc) async {
      bloc.add(const SessionEvent.started());
      await bloc.stream.firstWhere(
        (SessionState s) => s.status == SessionStatus.authenticated,
      );
      bloc.add(const SessionEvent.mirrorLanguage('en'));
    },
    // Only the two states `SessionStarted` produces. **Nothing after them.**
    // The web's toggle does not refetch the profile after the mirror
    // (`LanguageToggle.tsx:71` has no `.then`), so neither does this.
    expect: () => <Matcher>[
      isA<SessionState>()
          .having((SessionState s) => s.status, 'status',
              SessionStatus.loading),
      isA<SessionState>()
          .having((SessionState s) => s.status, 'status',
              SessionStatus.authenticated),
    ],
  );
}

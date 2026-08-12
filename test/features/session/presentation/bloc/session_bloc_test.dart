/// `SessionBloc` — boot, sign-in, sign-out, profile refresh.
///
/// Named by plan § Testing ("boot authenticated/unauthenticated, signIn,
/// signOut") and GOR-245 § 3.1.
///
/// `StorageService` is real (over an in-memory secure store) rather than
/// mocked: the bloc's contract includes *what ends up persisted* — a sign-in
/// that emits `authenticated` without writing the token pair is a bug that a
/// mocked storage would happily verify away.
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/core/usecase/usecase.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/citizen_profile.dart';
import 'package:lcc_mobile_app/features/session/presentation/bloc/session_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/core_test_helper.dart';
import '../../../../helpers/session_test_helper.dart';

void main() {
  late Map<String, String> store;
  late StorageService storage;
  late MockGetProfile getProfile;
  late MockSessionRepository repository;

  setUpAll(() {
    registerFallbackValue(NoParams());
  });

  setUp(() {
    store = <String, String>{};
    storage = inMemoryStorageService(store);
    getProfile = MockGetProfile();
    repository = MockSessionRepository();
  });

  SessionBloc build() => SessionBloc(
        storage: storage,
        getProfile: getProfile,
        repository: repository,
      );

  /// The intermediate `loading` emission every profile-loading path produces.
  ///
  /// Spelled out in each `expect` list rather than skipped with `bloc_test`'s
  /// `skip:` parameter. `skip:` here means "ignore the first N emitted states",
  /// not "skip this test" — but GOR-245 § 11 asks the reviewer to confirm that
  /// nothing was made green by re-adding a skip, and a file full of `skip: 1`
  /// makes that check needlessly ambiguous. Asserting the state is also
  /// strictly stronger: a handler that stopped emitting `loading` would now
  /// fail rather than pass unnoticed.
  final Matcher isLoading = isA<SessionState>()
      .having((SessionState s) => s.status, 'status', SessionStatus.loading);

  void stubProfileSuccess({String name = 'Test Citizen', String? avatarUrl}) {
    when(() => getProfile(any())).thenAnswer(
      (_) async => Right<Failure, CitizenProfile>(
        tCitizenProfile(name: name, avatarUrl: avatarUrl),
      ),
    );
  }

  test('starts in the initial status with no profile', () {
    final SessionBloc bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.status, SessionStatus.initial);
    expect(bloc.state.profile, isNull);
    expect(bloc.state.errorMessage, isNull);
  });

  test('exposes the storage auth-state notifier verbatim', () {
    final SessionBloc bloc = build();
    addTearDown(bloc.close);

    expect(bloc.authStateNotifier, same(storage.authStateNotifier));
  });

  group('SessionStarted (boot)', () {
    blocTest<SessionBloc, SessionState>(
      'goes straight to unauthenticated when no token is stored',
      build: build,
      act: (SessionBloc bloc) => bloc.add(const SessionEvent.started()),
      expect: () => <Matcher>[
        isA<SessionState>().having(
            (SessionState s) => s.status, 'status', SessionStatus.unauthenticated),
      ],
      verify: (_) => verifyNever(() => getProfile(any())),
    );

    blocTest<SessionBloc, SessionState>(
      'with a stored token loads the profile and ends authenticated',
      setUp: () {
        store[StorageKeys.accessToken] = 'access-abc';
        stubProfileSuccess(name: 'Somsak', avatarUrl: 'https://x/y.png');
      },
      build: build,
      act: (SessionBloc bloc) => bloc.add(const SessionEvent.started()),
      expect: () => <Matcher>[
        isA<SessionState>()
            .having((SessionState s) => s.status, 'status', SessionStatus.loading),
        isA<SessionState>()
            .having((SessionState s) => s.status, 'status',
                SessionStatus.authenticated)
            .having((SessionState s) => s.profile?.name, 'name', 'Somsak')
            .having((SessionState s) => s.profile?.avatarUrl, 'avatarUrl',
                'https://x/y.png'),
      ],
    );

    blocTest<SessionBloc, SessionState>(
      'projects a missing avatar as an empty string, not null',
      setUp: () {
        store[StorageKeys.accessToken] = 'access-abc';
        stubProfileSuccess();
      },
      build: build,
      act: (SessionBloc bloc) => bloc.add(const SessionEvent.started()),
      expect: () => <Matcher>[
        isLoading,
        isA<SessionState>()
            .having((SessionState s) => s.profile?.avatarUrl, 'avatarUrl', ''),
      ],
    );

    blocTest<SessionBloc, SessionState>(
      'a 401 from the profile call clears the token and signs the citizen out',
      setUp: () {
        store[StorageKeys.accessToken] = 'access-abc';
        store[StorageKeys.refreshToken] = 'refresh-abc';
        when(() => getProfile(any())).thenThrow(
          const ApiException(
              status: 401, code: 'UNAUTHORIZED', message: 'expired'),
        );
      },
      build: build,
      act: (SessionBloc bloc) => bloc.add(const SessionEvent.started()),
      expect: () => <Matcher>[
        isLoading,
        isA<SessionState>()
            .having((SessionState s) => s.status, 'status',
                SessionStatus.unauthenticated)
            .having((SessionState s) => s.profile, 'profile', isNull)
            .having((SessionState s) => s.errorMessage, 'errorMessage', isNull),
      ],
      verify: (_) {
        expect(store.containsKey(StorageKeys.accessToken), isFalse);
        expect(store.containsKey(StorageKeys.refreshToken), isFalse);
      },
    );

    blocTest<SessionBloc, SessionState>(
      'a 403 also clears the token — a token with no account is worse than none',
      setUp: () {
        store[StorageKeys.accessToken] = 'access-abc';
        when(() => getProfile(any())).thenThrow(
          const ApiException(status: 403, code: 'FORBIDDEN', message: 'no'),
        );
      },
      build: build,
      act: (SessionBloc bloc) => bloc.add(const SessionEvent.started()),
      expect: () => <Matcher>[
        isLoading,
        isA<SessionState>().having(
            (SessionState s) => s.status, 'status', SessionStatus.unauthenticated),
      ],
      verify: (_) => expect(store.containsKey(StorageKeys.accessToken), isFalse),
    );

    blocTest<SessionBloc, SessionState>(
      'a non-auth ApiException keeps the session and surfaces the message',
      setUp: () {
        store[StorageKeys.accessToken] = 'access-abc';
        when(() => getProfile(any())).thenThrow(
          const ApiException(
              status: 500, code: 'INTERNAL_ERROR', message: 'server exploded'),
        );
      },
      build: build,
      act: (SessionBloc bloc) => bloc.add(const SessionEvent.started()),
      expect: () => <Matcher>[
        isLoading,
        isA<SessionState>()
            .having((SessionState s) => s.status, 'status',
                SessionStatus.authenticated)
            .having((SessionState s) => s.errorMessage, 'errorMessage',
                'server exploded'),
      ],
      verify: (_) => expect(store[StorageKeys.accessToken], 'access-abc'),
    );

    blocTest<SessionBloc, SessionState>(
      'a Left(Failure) keeps the session and surfaces the failure message',
      setUp: () {
        store[StorageKeys.accessToken] = 'access-abc';
        when(() => getProfile(any())).thenAnswer(
          (_) async => const Left<Failure, CitizenProfile>(Failure('offline')),
        );
      },
      build: build,
      act: (SessionBloc bloc) => bloc.add(const SessionEvent.started()),
      expect: () => <Matcher>[
        isLoading,
        isA<SessionState>()
            .having((SessionState s) => s.status, 'status',
                SessionStatus.authenticated)
            .having((SessionState s) => s.errorMessage, 'errorMessage', 'offline'),
      ],
    );

    blocTest<SessionBloc, SessionState>(
      'a non-Api exception is caught and reported, never rethrown',
      setUp: () {
        store[StorageKeys.accessToken] = 'access-abc';
        when(() => getProfile(any())).thenThrow(StateError('boom'));
      },
      build: build,
      act: (SessionBloc bloc) => bloc.add(const SessionEvent.started()),
      expect: () => <Matcher>[
        isLoading,
        isA<SessionState>()
            .having((SessionState s) => s.status, 'status',
                SessionStatus.authenticated)
            .having((SessionState s) => s.errorMessage, 'errorMessage',
                contains('boom')),
      ],
    );
  });

  group('SessionSignIn', () {
    blocTest<SessionBloc, SessionState>(
      'persists the token pair, then loads the profile',
      setUp: stubProfileSuccess,
      build: build,
      act: (SessionBloc bloc) =>
          bloc.add(SessionEvent.signIn(tCitizenSession())),
      expect: () => <Matcher>[
        isA<SessionState>()
            .having((SessionState s) => s.status, 'status', SessionStatus.loading),
        isA<SessionState>().having(
            (SessionState s) => s.status, 'status', SessionStatus.authenticated),
      ],
      verify: (_) {
        expect(store[StorageKeys.accessToken], 'access-abc');
        expect(store[StorageKeys.refreshToken], 'refresh-abc');
      },
    );

    blocTest<SessionBloc, SessionState>(
      'a 401 immediately after sign-in clears the token it just wrote',
      setUp: () {
        when(() => getProfile(any())).thenThrow(
          const ApiException(status: 401, code: 'UNAUTHORIZED', message: 'no'),
        );
      },
      build: build,
      act: (SessionBloc bloc) =>
          bloc.add(SessionEvent.signIn(tCitizenSession())),
      expect: () => <Matcher>[
        isLoading,
        isA<SessionState>().having(
            (SessionState s) => s.status, 'status', SessionStatus.unauthenticated),
      ],
      verify: (_) => expect(store, isEmpty),
    );
  });

  group('SessionSignOut', () {
    blocTest<SessionBloc, SessionState>(
      'revokes the refresh token, clears storage and goes unauthenticated',
      setUp: () {
        store[StorageKeys.accessToken] = 'access-abc';
        store[StorageKeys.refreshToken] = 'refresh-abc';
        when(() => repository.logout(any()))
            .thenAnswer((_) async => const Right<Failure, void>(null));
      },
      build: build,
      act: (SessionBloc bloc) => bloc.add(const SessionEvent.signOut()),
      expect: () => <Matcher>[
        isA<SessionState>()
            .having((SessionState s) => s.status, 'status',
                SessionStatus.unauthenticated)
            .having((SessionState s) => s.profile, 'profile', isNull),
      ],
      verify: (_) {
        verify(() => repository.logout('refresh-abc')).called(1);
        expect(store, isEmpty);
      },
    );

    blocTest<SessionBloc, SessionState>(
      'still signs out when the server-side revoke fails',
      setUp: () {
        store[StorageKeys.accessToken] = 'access-abc';
        store[StorageKeys.refreshToken] = 'refresh-abc';
        when(() => repository.logout(any())).thenAnswer(
          (_) async => const Left<Failure, void>(Failure('revoke failed')),
        );
      },
      build: build,
      act: (SessionBloc bloc) => bloc.add(const SessionEvent.signOut()),
      expect: () => <Matcher>[
        isA<SessionState>().having(
            (SessionState s) => s.status, 'status', SessionStatus.unauthenticated),
      ],
      verify: (_) => expect(store, isEmpty),
    );

    blocTest<SessionBloc, SessionState>(
      'skips the revoke call when there is no refresh token to revoke',
      setUp: () => store[StorageKeys.accessToken] = 'access-abc',
      build: build,
      act: (SessionBloc bloc) => bloc.add(const SessionEvent.signOut()),
      expect: () => <Matcher>[
        isA<SessionState>().having(
            (SessionState s) => s.status, 'status', SessionStatus.unauthenticated),
      ],
      verify: (_) {
        verifyNever(() => repository.logout(any()));
        expect(store, isEmpty);
      },
    );
  });

  group('SessionRefreshProfile', () {
    blocTest<SessionBloc, SessionState>(
      're-reads the profile while a token is held',
      setUp: () {
        store[StorageKeys.accessToken] = 'access-abc';
        stubProfileSuccess(name: 'Renamed Citizen');
      },
      build: build,
      act: (SessionBloc bloc) => bloc.add(const SessionEvent.refreshProfile()),
      expect: () => <Matcher>[
        isA<SessionState>()
            .having((SessionState s) => s.status, 'status', SessionStatus.loading),
        isA<SessionState>()
            .having((SessionState s) => s.status, 'status',
                SessionStatus.authenticated)
            .having((SessionState s) => s.profile?.name, 'name', 'Renamed Citizen'),
      ],
    );

    blocTest<SessionBloc, SessionState>(
      'drops to unauthenticated with no profile when the token has gone',
      build: build,
      act: (SessionBloc bloc) => bloc.add(const SessionEvent.refreshProfile()),
      expect: () => <Matcher>[
        isA<SessionState>()
            .having((SessionState s) => s.status, 'status',
                SessionStatus.unauthenticated)
            .having((SessionState s) => s.profile, 'profile', isNull),
      ],
      verify: (_) => verifyNever(() => getProfile(any())),
    );
  });
}

/// What a citizen's screen ends up showing when the server says no.
///
/// AC-17 and AC-19 are both stated at BLoC level — "leaves `SessionBloc` at
/// `unauthenticated`, never `loading`", "reaches `AuthState.fieldErrors`
/// non-empty" — and neither can be proved by a test of one layer. The failure
/// they describe has to cross the whole chain:
///
///   transport → RefreshInterceptor → ApiClient → datasource → repository
///             → usecase → BLoC
///
/// So every object in that chain is the production one here, with exactly two
/// substitutions: the HTTP transport (`RecordingHttpAdapter`) and the
/// secure-storage platform channel (an in-memory map). Nothing is mocked at a
/// seam the defects lived in.
///
/// **Deliberately not a `testWidgets` test, and not `app_test_harness.dart`.**
/// The widget layer contributes nothing to either criterion, and `testWidgets`
/// would put every assertion inside a `FakeAsync` zone — where a real hang
/// presents as a `pumpAndSettle` timeout rather than as the thing under test,
/// and where a wall-clock deadline means nothing. These are plain `test()`
/// bodies on the real event loop, so [within] measures real time and a stall is
/// a stall. It also sidesteps the two hazards recorded in `app_test_harness.dart`
/// (a BLoC built outside the fake zone never handling its events; a router
/// disposed while mounted hanging to timeout) by not standing a widget tree up
/// at all.
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:lcc_mobile_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lcc_mobile_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/forgot_password.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/login.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/register.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/request_otp.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/reset_password.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/verify_otp.dart';
import 'package:lcc_mobile_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lcc_mobile_app/features/session/data/datasources/session_remote_datasource.dart';
import 'package:lcc_mobile_app/features/session/data/repositories/session_repository_impl.dart';
import 'package:lcc_mobile_app/features/session/domain/repositories/session_repository.dart';
import 'package:lcc_mobile_app/features/session/domain/usecases/get_profile.dart';
import 'package:lcc_mobile_app/features/session/domain/usecases/update_profile.dart';
import 'package:lcc_mobile_app/core/session/bloc/session_bloc.dart';

import '../helpers/core_test_helper.dart';
import '../helpers/session_test_helper.dart';

/// The `POST /auth/refresh` success envelope.
Map<String, dynamic> refreshEnvelope({String access = 'access-new'}) {
  return okEnvelope(<String, dynamic>{
    'tokens': <String, dynamic>{
      'access_token': access,
      'refresh_token': 'refresh-new',
    },
  });
}

void main() {
  late Map<String, String> store;
  late StorageService storage;

  setUp(() {
    store = <String, String>{
      StorageKeys.accessToken: 'access-old',
      StorageKeys.refreshToken: 'refresh-old',
    };
    storage = inMemoryStorageService(store);
  });

  /// Wall-clock budget. A breach fails the test — never an outcome a matcher
  /// can be satisfied by. See AC-17: "no test may assert a timeout as success."
  const Duration settleDeadline = Duration(seconds: 5);

  Future<T> within<T>(Future<T> call) => call.timeout(
        settleDeadline,
        onTimeout: () => fail(
          'the flow was still pending after ${settleDeadline.inSeconds}s. '
          'A session that never resolves is the D-2 symptom the citizen '
          'actually sees, and a hang is a failure, never a pass.',
        ),
      );

  /// The full production graph below `ApiClient`, over [responder].
  ({
    ApiClient client,
    RecordingHttpAdapter adapter,
  }) wireClient(ScriptedResponder responder) {
    final RecordingHttpAdapter adapter = RecordingHttpAdapter(responder);
    // Real interceptor chain: `AuthInterceptor` attaches the token,
    // `RefreshInterceptor` owns the 401.
    final Dio dio = buildTestDio(storage: storage, adapter: adapter);
    return (client: ApiClient(dio: dio, storage: storage), adapter: adapter);
  }

  SessionBloc sessionBlocOver(ApiClient client) {
    final SessionRepository repository = SessionRepositoryImpl(
      remote: SessionRemoteDatasourceImpl(apiClient: client),
    );
    return SessionBloc(
      storage: storage,
      getProfile: GetProfile(repository: repository),
      repository: repository,
      // B8a — R-25's mirror, over the same repository this bloc already holds.
      updateProfile: UpdateProfile(repository: repository),
    );
  }

  AuthBloc authBlocOver(ApiClient client) {
    final AuthRepository repository = AuthRepositoryImpl(
      remote: AuthRemoteDatasourceImpl(apiClient: client),
    );
    return AuthBloc(
      register: Register(repository: repository),
      requestOtp: RequestOtp(repository: repository),
      verifyOtp: VerifyOtp(repository: repository),
      login: Login(repository: repository),
      forgotPassword: ForgotPassword(repository: repository),
      resetPassword: ResetPassword(repository: repository),
    );
  }

  List<String> pathsOf(RecordingHttpAdapter adapter) =>
      adapter.requests.map((RequestOptions r) => r.path).toList();

  TypeMatcher<SessionState> sessionAt(SessionStatus status) =>
      isA<SessionState>().having(
          (SessionState s) => s.status, 'status', status);

  // ── AC-17, at the layer the criterion is written about ─────────────────────
  //
  // The interceptor-level proof is in `refresh_interceptor_test.dart`. This is
  // the consequence the architecture review actually cares about: under D-2 the
  // 401 never came back, so `SessionBloc._loadProfile` awaited `getProfile()`
  // forever, the session never left `SessionStatus.loading`, and
  // `AppRoutes._redirect`'s boot-hold branch kept returning `null` — the
  // citizen held on an unresolving screen rather than being signed out. The
  // criterion names `loading` explicitly, so the emission ORDER is asserted,
  // not just the final state: reaching `unauthenticated` eventually would not
  // distinguish the fixed code from a lucky race.
  group('AC-17 — an expired session resolves to signed-out, not to a stall',
      () {
    test('a 401 whose refresh also 401s ends at unauthenticated with the '
        'tokens cleared', () async {
      final ({ApiClient client, RecordingHttpAdapter adapter}) w = wireClient(
        (RequestOptions _, int __) => jsonResponse(
          failEnvelope(code: ApiCode.unauthorized, message: 'Token expired'),
          statusCode: 401,
        ),
      );
      final SessionBloc bloc = sessionBlocOver(w.client);
      addTearDown(bloc.close);

      final Future<void> settled = expectLater(
        bloc.stream,
        emitsInOrder(<Matcher>[
          sessionAt(SessionStatus.loading),
          sessionAt(SessionStatus.unauthenticated),
        ]),
      );
      bloc.add(const SessionEvent.started());
      await within(settled);

      expect(bloc.state.status, SessionStatus.unauthenticated);
      expect(bloc.state.profile, isNull);
      expect(bloc.state.errorMessage, isNull,
          reason: 'an expired session is a sign-out, not an error to show');
      // Two clears happen on this path and both matter: `RefreshInterceptor`
      // clears when the refresh fails, and `SessionBloc` clears again on the
      // 401 it then receives. Belt and braces, and under D-2 neither ran.
      expect(store.containsKey(StorageKeys.accessToken), isFalse);
      expect(store.containsKey(StorageKeys.refreshToken), isFalse);
      expect(storage.authStateNotifier.value, isFalse,
          reason: 'the shell auth badge reads this notifier directly');
      expect(
        pathsOf(w.adapter),
        <String>[ApiEndpoint.meProfile, ApiEndpoint.authRefresh],
        reason: 'one refresh attempt, no replay after it failed',
      );
    });

    test('the 401 arrives as a real ApiException, which is what routes it to '
        'the sign-out branch', () async {
      // `SessionBloc._loadProfile` only clears tokens when it catches an
      // `ApiException` whose `isUnauthorized` is true. Under D-1 the exception
      // that reached it would have been a status-0 NETWORK_ERROR, which takes
      // the *other* branch — status stays `authenticated` with an error
      // message, leaving the UI signed in with nothing behind it. So the two
      // fixes are load-bearing for each other here, and this pins the join.
      final ({ApiClient client, RecordingHttpAdapter adapter}) w = wireClient(
        (RequestOptions _, int __) => jsonResponse(
          failEnvelope(code: ApiCode.unauthorized, message: 'Token expired'),
          statusCode: 401,
        ),
      );
      final SessionRepository repository = SessionRepositoryImpl(
        remote: SessionRemoteDatasourceImpl(apiClient: w.client),
      );

      await expectLater(
        within(repository.getProfile()),
        throwsA(isA<ApiException>()
            .having((ApiException e) => e.status, 'status', 401)
            .having((ApiException e) => e.code, 'code', ApiCode.unauthorized)
            .having((ApiException e) => e.isUnauthorized, 'isUnauthorized',
                isTrue)),
      );
    });

    test('a 401 whose refresh succeeds reaches authenticated with the profile',
        () async {
      // The other side of AC-17, and plan verification item 9 at flow level:
      // the path that was already green must stay green now that the unhappy
      // ones are too.
      final ({ApiClient client, RecordingHttpAdapter adapter}) w = wireClient(
        (RequestOptions options, int __) {
          if (options.path == ApiEndpoint.authRefresh) {
            return jsonResponse(refreshEnvelope());
          }
          return options.headers['Authorization'] == 'Bearer access-old'
              ? jsonResponse(failEnvelope(code: ApiCode.unauthorized),
                  statusCode: 401)
              : jsonResponse(okEnvelope(tCitizenProfileJson()));
        },
      );
      final SessionBloc bloc = sessionBlocOver(w.client);
      addTearDown(bloc.close);

      final Future<void> settled = expectLater(
        bloc.stream,
        emitsInOrder(<Matcher>[
          sessionAt(SessionStatus.loading),
          sessionAt(SessionStatus.authenticated),
        ]),
      );
      bloc.add(const SessionEvent.started());
      await within(settled);

      expect(bloc.state.profile?.name, 'Test Citizen');
      expect(store[StorageKeys.accessToken], 'access-new');
      expect(
        pathsOf(w.adapter),
        <String>[
          ApiEndpoint.meProfile,
          ApiEndpoint.authRefresh,
          ApiEndpoint.meProfile,
        ],
      );
    });
  });

  // ── AC-19, at the layer the criterion is written about ─────────────────────
  //
  // "reaches `AuthState.fieldErrors` non-empty at BLoC level". The register
  // form highlights every offending field where the citizen typed, and it can
  // only do that if the server's `errors[]` survives four layers of unwrapping.
  // Under D-1 it did not survive the first: `ApiClient` replaced the whole
  // envelope with a generic NETWORK_ERROR, so `fieldMap()` was empty by the
  // time `AuthBloc` read it and the form had nothing to highlight.
  group('AC-19 — a 422 reaches the form with every offending field', () {
    test('AuthBloc surfaces the server message and one entry per bad field',
        () async {
      final ({ApiClient client, RecordingHttpAdapter adapter}) w = wireClient(
        (RequestOptions _, int __) => jsonResponse(
          failEnvelope(
            code: ApiCode.validationError,
            message: 'The given data was invalid.',
            errors: <Map<String, dynamic>>[
              <String, dynamic>{'field': 'phone', 'message': 'already taken'},
              <String, dynamic>{
                'field': 'password',
                'message': 'is too short',
              },
            ],
          ),
          statusCode: 422,
        ),
      );
      final AuthBloc bloc = authBlocOver(w.client);
      addTearDown(bloc.close);

      final Future<void> settled = expectLater(
        bloc.stream,
        emitsInOrder(<Matcher>[
          isA<AuthState>()
              .having((AuthState s) => s.status, 'status', AuthStatus.loading),
          isA<AuthState>()
              .having((AuthState s) => s.status, 'status', AuthStatus.failure)
              .having((AuthState s) => s.errorMessage, 'errorMessage',
                  'The given data was invalid.')
              .having((AuthState s) => s.fieldErrors, 'fieldErrors',
                  <String, String>{
                    'phone': 'already taken',
                    'password': 'is too short',
                  }),
        ]),
      );
      bloc.add(const AuthEvent.registerStarted(
        phone: '+8562012345',
        name: 'Test Citizen',
        password: 'short',
      ));
      await within(settled);

      expect(bloc.state.fieldErrors, isNotEmpty);
    });

    test('a request that never reached the server still fails with the generic '
        'network message and no field errors', () async {
      // The non-regression half, at the same layer. A form must not invent
      // per-field complaints out of a dropped connection, and the citizen must
      // be told to check their connection rather than shown a server message
      // no server sent.
      final ({ApiClient client, RecordingHttpAdapter adapter}) w = wireClient(
        (RequestOptions options, int __) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
      final AuthBloc bloc = authBlocOver(w.client);
      addTearDown(bloc.close);

      final Future<void> settled = expectLater(
        bloc.stream,
        emitsInOrder(<Matcher>[
          isA<AuthState>()
              .having((AuthState s) => s.status, 'status', AuthStatus.loading),
          isA<AuthState>()
              .having((AuthState s) => s.status, 'status', AuthStatus.failure)
              .having((AuthState s) => s.errorMessage, 'errorMessage',
                  'Cannot reach the server. Check your connection and try again.')
              .having((AuthState s) => s.fieldErrors, 'fieldErrors', isEmpty),
        ]),
      );
      bloc.add(const AuthEvent.registerStarted(
        phone: '+8562012345',
        name: 'Test Citizen',
        password: 'short',
      ));
      await within(settled);
    });
  });
}

/// `RefreshInterceptor` — the gated single-retry 401 refresh.
///
/// Beyond the GOR-245 § 3.1 file list, and deliberately so: the plan's own
/// `api_client_test.dart` line asks for "401 retry", but that behaviour lives
/// in this class, not in `ApiClient`. Testing it here keeps each file about the
/// unit it names, and gives the 401 path — the single most consequential piece
/// of untested logic in `core/network` — its own coverage.
///
/// Every case drives a real `Dio` with the real interceptor chain and a
/// scripted transport, so the assertions are about what the server would see:
/// how many calls, in what order, with which `Authorization` header.
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';

import '../../helpers/core_test_helper.dart';

/// The `POST /auth/refresh` success envelope: `data.tokens.{access,refresh}`.
Map<String, dynamic> refreshEnvelope({
  String access = 'access-new',
  String? refresh = 'refresh-new',
}) {
  return okEnvelope(<String, dynamic>{
    'tokens': <String, dynamic>{
      'access_token': access,
      if (refresh != null) 'refresh_token': refresh,
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

  ({Dio dio, RecordingHttpAdapter adapter}) wire(ScriptedResponder responder) {
    final RecordingHttpAdapter adapter = RecordingHttpAdapter(responder);
    return (dio: buildTestDio(storage: storage, adapter: adapter), adapter: adapter);
  }

  test('refreshes once on a 401 and replays the original request with the '
      'new token', () async {
    final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(
      (RequestOptions options, int _) {
        if (options.path == ApiEndpoint.authRefresh) {
          return jsonResponse(refreshEnvelope());
        }
        // The protected call fails only while the old token is attached.
        if (options.headers['Authorization'] == 'Bearer access-old') {
          return jsonResponse(
            failEnvelope(code: 'UNAUTHORIZED', message: 'expired'),
            statusCode: 401,
          );
        }
        return jsonResponse(okEnvelope(<String, dynamic>{'id': 'me'}));
      },
    );

    final Response<dynamic> response = await w.dio.get<dynamic>('/me/profile');

    expect(response.statusCode, 200);
    expect(
      w.adapter.requests.map((RequestOptions r) => r.path).toList(),
      <String>['/me/profile', ApiEndpoint.authRefresh, '/me/profile'],
      reason: 'exactly one refresh, then exactly one replay',
    );
    expect(w.adapter.requests.last.headers['Authorization'], 'Bearer access-new');
    expect(w.adapter.requests.last.extra['retryAttempt'], 1);
    expect(store[StorageKeys.accessToken], 'access-new');
    expect(store[StorageKeys.refreshToken], 'refresh-new');
  });

  test('sends the refresh call anonymously, so it cannot recurse', () async {
    final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(
      (RequestOptions options, int _) {
        if (options.path == ApiEndpoint.authRefresh) {
          return jsonResponse(refreshEnvelope());
        }
        return options.headers.containsKey('Authorization') &&
                options.headers['Authorization'] == 'Bearer access-old'
            ? jsonResponse(failEnvelope(), statusCode: 401)
            : jsonResponse(okEnvelope(null));
      },
    );

    await w.dio.get<dynamic>('/me/profile');

    final RequestOptions refreshCall = w.adapter.requests
        .firstWhere((RequestOptions r) => r.path == ApiEndpoint.authRefresh);
    expect(refreshCall.extra['anonymous'], isTrue);
    expect(refreshCall.headers.containsKey('Authorization'), isFalse);
  });

  test('keeps the existing refresh token when the server returns only a new '
      'access token', () async {
    final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(
      (RequestOptions options, int _) {
        if (options.path == ApiEndpoint.authRefresh) {
          return jsonResponse(refreshEnvelope(refresh: null));
        }
        return options.headers['Authorization'] == 'Bearer access-old'
            ? jsonResponse(failEnvelope(), statusCode: 401)
            : jsonResponse(okEnvelope(null));
      },
    );

    await w.dio.get<dynamic>('/me/profile');

    expect(store[StorageKeys.accessToken], 'access-new');
    expect(store[StorageKeys.refreshToken], 'refresh-old');
  });

  test('treats a success:false refresh envelope as a failed refresh', () async {
    final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(
      (RequestOptions options, int _) => options.path == ApiEndpoint.authRefresh
          ? jsonResponse(failEnvelope(message: 'refresh rejected'))
          : jsonResponse(failEnvelope(), statusCode: 401),
    );

    await expectLater(w.dio.get<dynamic>('/me/profile'), throwsA(isA<DioException>()));
    expect(store.containsKey(StorageKeys.accessToken), isFalse);
  });

  test('treats a refresh envelope with no tokens block as a failed refresh',
      () async {
    final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(
      (RequestOptions options, int _) => options.path == ApiEndpoint.authRefresh
          ? jsonResponse(okEnvelope(<String, dynamic>{'no': 'tokens'}))
          : jsonResponse(failEnvelope(), statusCode: 401),
    );

    await expectLater(w.dio.get<dynamic>('/me/profile'), throwsA(isA<DioException>()));
    expect(store.containsKey(StorageKeys.accessToken), isFalse);
  });

  test('treats a non-map refresh data block as a failed refresh', () async {
    final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(
      (RequestOptions options, int _) => options.path == ApiEndpoint.authRefresh
          ? jsonResponse(okEnvelope('not-a-map'))
          : jsonResponse(failEnvelope(), statusCode: 401),
    );

    await expectLater(w.dio.get<dynamic>('/me/profile'), throwsA(isA<DioException>()));
  });

  test('treats an empty access token in the refresh response as a failure',
      () async {
    final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(
      (RequestOptions options, int _) => options.path == ApiEndpoint.authRefresh
          ? jsonResponse(refreshEnvelope(access: ''))
          : jsonResponse(failEnvelope(), statusCode: 401),
    );

    await expectLater(w.dio.get<dynamic>('/me/profile'), throwsA(isA<DioException>()));
  });

  test('does not attempt a refresh when no refresh token is held', () async {
    store.remove(StorageKeys.refreshToken);
    final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(
      (RequestOptions options, int _) =>
          jsonResponse(failEnvelope(), statusCode: 401),
    );

    await expectLater(w.dio.get<dynamic>('/me/profile'), throwsA(isA<DioException>()));

    expect(
      w.adapter.requests.map((RequestOptions r) => r.path).toList(),
      <String>['/me/profile'],
    );
  });

  test('does not refresh when a refresh call is itself the thing that 401s',
      () async {
    final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(
      (RequestOptions options, int _) =>
          jsonResponse(failEnvelope(), statusCode: 401),
    );

    await expectLater(
      w.dio.post<dynamic>(
        ApiEndpoint.authRefresh,
        data: <String, dynamic>{'refresh_token': 'refresh-old'},
      ),
      throwsA(isA<DioException>()),
    );

    expect(w.adapter.callCount, 1, reason: 'no recursion into the refresh gate');
  });

  test('does not refresh an anonymous request that 401s', () async {
    final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(
      (RequestOptions options, int _) =>
          jsonResponse(failEnvelope(), statusCode: 401),
    );

    await expectLater(
      w.dio.post<dynamic>(
        ApiEndpoint.authLogin,
        options: Options(extra: <String, dynamic>{'anonymous': true}),
      ),
      throwsA(isA<DioException>()),
    );

    expect(w.adapter.callCount, 1);
    expect(store[StorageKeys.accessToken], 'access-old',
        reason: 'an anonymous 401 must not sign the citizen out');
  });

  test('passes a non-401 error straight through', () async {
    final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(
      (RequestOptions options, int _) =>
          jsonResponse(failEnvelope(code: 'FORBIDDEN'), statusCode: 403),
    );

    await expectLater(
      w.dio.get<dynamic>('/me/profile'),
      throwsA(isA<DioException>().having(
          (DioException e) => e.response?.statusCode, 'status', 403)),
    );

    expect(w.adapter.callCount, 1);
    expect(store[StorageKeys.accessToken], 'access-old');
  });

  test('two sequential 401s each get their own refresh', () async {
    // `RefreshInterceptor` is a `QueuedInterceptor`, so 401s are handled one at
    // a time. This pins that a *second*, later 401 is still refreshed — i.e.
    // the `_refreshCompleter` gate is released after each pass. See defect D-3
    // in qa-report.md for the concurrent case, which this design never reaches.
    int refreshes = 0;
    final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(
      (RequestOptions options, int _) {
        if (options.path == ApiEndpoint.authRefresh) {
          refreshes++;
          return jsonResponse(refreshEnvelope(access: 'access-$refreshes'));
        }
        return options.headers['Authorization'] == 'Bearer access-$refreshes'
            ? jsonResponse(okEnvelope(null))
            : jsonResponse(failEnvelope(), statusCode: 401);
      },
    );

    await w.dio.get<dynamic>('/one');
    store[StorageKeys.accessToken] = 'stale-again';
    await w.dio.get<dynamic>('/two');

    expect(refreshes, 2);
  });

  // ── DEFECT D-2 — nested-call deadlock ──────────────────────────────────────
  //
  // `RefreshInterceptor extends QueuedInterceptor` and makes nested calls on
  // the SAME `Dio` from inside `onError` — `_dio.post(authRefresh)` and, on
  // success, `_dio.fetch(options)`. dio keeps one queue per phase, and the
  // outer `onError` occupies the *error* queue for as long as it is awaiting.
  // The nested call's own error is therefore enqueued behind an entry that can
  // only be released by that same nested call returning. Neither ever
  // completes: the original request's `Future` stays pending forever.
  //
  // The request queue is separate, which is why the all-green path (refresh
  // 200 → replay 200) works and why this went unnoticed. Every *unhappy*
  // branch below hangs, including the single most ordinary one: an expired
  // refresh token.
  //
  // Consequence in the assembled app: `SessionBloc._loadProfile` awaits
  // `getProfile()` forever, the session never leaves `SessionStatus.loading`,
  // and `AppRoutes._redirect`'s boot-hold branch keeps returning `null`. The
  // citizen is held on an unresolving screen instead of being signed out.
  // No timeout rescues it — the socket already answered; the stall is in the
  // interceptor queue.
  //
  // These tests pin the *observed* behaviour, deliberately, because
  // `core/network` is frozen (GOR-245 § 4.1) and a test written against the
  // intended behaviour would simply fail. They are written to break loudly the
  // moment the defect is fixed, which is when they should be rewritten to
  // assert the real contract (tokens cleared, 401 surfaced, at most one
  // replay). Reported in qa-report.md, routed to mobile-frontend-developer-lead.

  /// Runs [call] against a short real-time deadline. Returns `'DEADLOCK'` when
  /// the future is still pending, so a hang is asserted without hanging the
  /// suite.
  Future<String> outcomeOf(Future<Object?> call) {
    return Future.any<String>(<Future<String>>[
      call.then<String>((Object? _) => 'completed').catchError(
            (Object e) => 'threw ${e.runtimeType}',
          ),
      Future<String>.delayed(const Duration(milliseconds: 400), () => 'DEADLOCK'),
    ]);
  }

  test('DEFECT D-2: a refresh call that itself 401s deadlocks the request',
      () async {
    final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(
      (RequestOptions options, int _) => jsonResponse(
        failEnvelope(code: 'UNAUTHORIZED'),
        statusCode: 401,
      ),
    );

    expect(
      await outcomeOf(w.dio.get<dynamic>('/me/profile')),
      'DEADLOCK',
      reason: 'expected the 401 to surface and the tokens to be cleared',
    );
    // `clearTokens()` sits after `await _refreshSession()`, so it never runs:
    // the citizen keeps a dead token AND gets no error.
    expect(store[StorageKeys.accessToken], 'access-old');
    expect(
      w.adapter.requests.map((RequestOptions r) => r.path).toList(),
      <String>['/me/profile', ApiEndpoint.authRefresh],
    );
  });

  test('DEFECT D-2: a transport failure on the refresh call deadlocks too',
      () async {
    final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(
      (RequestOptions options, int _) {
        if (options.path == ApiEndpoint.authRefresh) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        return jsonResponse(failEnvelope(), statusCode: 401);
      },
    );

    expect(await outcomeOf(w.dio.get<dynamic>('/me/profile')), 'DEADLOCK');
    expect(store[StorageKeys.accessToken], 'access-old');
  });

  test('DEFECT D-2: a replay that 401s again deadlocks instead of surfacing',
      () async {
    final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(
      (RequestOptions options, int _) => options.path == ApiEndpoint.authRefresh
          ? jsonResponse(refreshEnvelope())
          : jsonResponse(failEnvelope(), statusCode: 401),
    );

    expect(await outcomeOf(w.dio.get<dynamic>('/me/profile')), 'DEADLOCK');
    // The refresh itself did succeed and was persisted before the stall.
    expect(store[StorageKeys.accessToken], 'access-new');
    expect(
      w.adapter.requests.map((RequestOptions r) => r.path).toList(),
      <String>['/me/profile', ApiEndpoint.authRefresh, '/me/profile'],
      reason: 'the retryAttempt guard does stop a second refresh; the request '
          'still never completes',
    );
  });

  test('DEFECT D-2: a transport failure during the replay deadlocks', () async {
    final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(
      (RequestOptions options, int callIndex) {
        if (options.path == ApiEndpoint.authRefresh) {
          return jsonResponse(refreshEnvelope());
        }
        if (callIndex == 0) {
          return jsonResponse(failEnvelope(), statusCode: 401);
        }
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      },
    );

    expect(await outcomeOf(w.dio.get<dynamic>('/me/profile')), 'DEADLOCK');
  });
}

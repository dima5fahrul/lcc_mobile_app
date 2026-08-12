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

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
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
            failEnvelope(code: ApiCode.unauthorized, message: 'expired'),
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
    // Pins that a *second*, later 401 is still refreshed: the
    // `_refreshCompleter` gate is cleared after each pass rather than left
    // latched. This is the sequential half of that guarantee; the concurrent
    // half — N simultaneous 401s must SHARE one refresh instead of each opening
    // their own — is the AC-18 group below. Both are needed, because a gate
    // that never opens again and a gate that never closes are different defects
    // presenting the same way from a single-caller test.
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

  // ── Bounded-deadline plumbing ──────────────────────────────────────────────
  //
  // These are plain `test()` bodies, so the event loop is the real one and a
  // genuine hang would stall the suite rather than fail it. Every case below
  // therefore runs under a wall-clock deadline — and the deadline is a FAILURE
  // condition, never an outcome. That inversion is the substance of AC-17: the
  // four cases in the next group used to *assert* the hang, so the helper they
  // shared reported a still-pending future as an ordinary value ('DEADLOCK')
  // that an `expect` could happily match. Nothing here can do that.

  /// Wall-clock budget for a 401 path to settle. Every path below needs a
  /// handful of microtasks over a synchronous transport, so this is ~2 orders
  /// of magnitude of slack for a loaded machine, not a threshold being raced.
  const Duration settleDeadline = Duration(seconds: 5);

  /// Awaits [call], expecting it to SUCCEED inside [settleDeadline].
  Future<T> within<T>(Future<T> call) => call.timeout(
        settleDeadline,
        onTimeout: () => fail(
          'still pending after ${settleDeadline.inSeconds}s. A hang is a '
          'failure, never a pass (AC-17).',
        ),
      );

  /// Awaits [call], expecting it to FAIL inside [settleDeadline], and returns
  /// the error it failed with.
  ///
  /// There is no return path out of this function that a still-pending future
  /// can reach: a breached deadline calls [fail] directly, and so does a call
  /// that unexpectedly succeeds.
  Future<Object> errorFrom(Future<Object?> call) async {
    Object? value;
    try {
      value = await call.timeout(settleDeadline);
    } on TimeoutException {
      fail(
        'the request was still pending after ${settleDeadline.inSeconds}s — '
        'that is the D-2 deadlock, and a hang is a failure, never a pass '
        '(AC-17).',
      );
    } on Object catch (error) {
      return error;
    }
    fail('expected the call to fail; it completed with $value');
  }

  /// [errorFrom], narrowed to the `DioException` a Dio-level caller sees.
  Future<DioException> dioErrorFrom(Future<Object?> call) async {
    final Object error = await errorFrom(call);
    expect(error, isA<DioException>());
    return error as DioException;
  }

  List<String> pathsOf(RecordingHttpAdapter adapter) =>
      adapter.requests.map((RequestOptions r) => r.path).toList();

  // ── AC-17 — the unhappy 401 paths settle, and settle correctly ─────────────
  //
  // These four were the `DEFECT D-2` reproductions. `RefreshInterceptor` was a
  // `QueuedInterceptor` making nested calls on the very queue its `onError` was
  // occupying, so every unhappy 401 path waited on itself: a permanent stall on
  // the most ordinary path there is, an expired refresh token. In the assembled
  // app that left `SessionBloc` on `SessionStatus.loading` forever and held the
  // citizen on an unresolving screen instead of signing them out.
  //
  // GOR-246 made the class a plain `Interceptor` and moved the refresh POST off
  // the shared client. The four cases are kept verbatim — same transports, same
  // scripts, so they are still the same four situations — and inverted to
  // assert the contract: a real error reaches the caller, the token store is
  // left in the right state, and no path fires a second refresh. The
  // `SessionBloc` half of AC-17 is proved end to end in
  // `test/app/server_error_flow_test.dart`.
  group('AC-17 — every unhappy 401 path settles with a real error', () {
    test('a refresh call that itself 401s surfaces the original 401 and clears '
        'the tokens', () async {
      final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(
        (RequestOptions options, int _) => jsonResponse(
          failEnvelope(code: ApiCode.unauthorized, message: 'expired'),
          statusCode: 401,
        ),
      );

      final DioException error =
          await dioErrorFrom(w.dio.get<dynamic>('/me/profile'));

      expect(error.response?.statusCode, 401,
          reason: 'the original 401 is what the caller must see');
      expect(
        (error.response?.data as Map<String, dynamic>)['code'],
        ApiCode.unauthorized,
        reason: 'the envelope rides along, so ApiClient can unwrap it',
      );
      // `clearTokens()` sits after `await _refreshSession()`. Under the deadlock
      // it never ran and the citizen kept a dead token with no error; it now
      // runs on every failed refresh.
      expect(store.containsKey(StorageKeys.accessToken), isFalse);
      expect(store.containsKey(StorageKeys.refreshToken), isFalse);
      expect(
        pathsOf(w.adapter),
        <String>['/me/profile', ApiEndpoint.authRefresh],
        reason: 'one refresh attempt, and no replay after it failed',
      );
    });

    test('a transport failure on the refresh call surfaces the original 401 '
        'and clears the tokens', () async {
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

      final DioException error =
          await dioErrorFrom(w.dio.get<dynamic>('/me/profile'));

      expect(error.response?.statusCode, 401,
          reason: 'the caller is told their request was rejected, not that the '
              'refresh could not be reached — the refresh is an implementation '
              'detail of this interceptor');
      expect(store.containsKey(StorageKeys.accessToken), isFalse);
      expect(pathsOf(w.adapter),
          <String>['/me/profile', ApiEndpoint.authRefresh]);
    });

    test('a replay that 401s again surfaces that second 401 without refreshing '
        'twice', () async {
      final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(
        (RequestOptions options, int _) =>
            options.path == ApiEndpoint.authRefresh
                ? jsonResponse(refreshEnvelope())
                : jsonResponse(failEnvelope(), statusCode: 401),
      );

      final DioException error =
          await dioErrorFrom(w.dio.get<dynamic>('/me/profile'));

      expect(error.response?.statusCode, 401);
      expect(error.requestOptions.extra['retryAttempt'], 1,
          reason: 'the surfaced error is the replay, not the first attempt');
      // The refresh itself succeeded, so the new pair is legitimately held —
      // this path must NOT clear tokens.
      expect(store[StorageKeys.accessToken], 'access-new');
      expect(store[StorageKeys.refreshToken], 'refresh-new');
      expect(
        pathsOf(w.adapter),
        <String>['/me/profile', ApiEndpoint.authRefresh, '/me/profile'],
        reason: 'the retryAttempt guard stops the replay re-entering the gate',
      );
    });

    test('a transport failure during the replay surfaces as a transport error',
        () async {
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

      final DioException error =
          await dioErrorFrom(w.dio.get<dynamic>('/me/profile'));

      expect(error.type, DioExceptionType.connectionError);
      expect(error.response, isNull,
          reason: 'no answer came back, so ApiClient must still call this a '
              'NETWORK_ERROR rather than inventing an envelope');
      expect(store[StorageKeys.accessToken], 'access-new');
    });
  });

  // ── AC-18 — one refresh per burst, and the gate opens on every exit ────────
  //
  // Defect D-4: `_refreshCompleter` was created, stored, and never completed.
  // Nothing hit it while the class was a `QueuedInterceptor`, because dio
  // serialised the 401s — it was latent. Removing that queue for D-2 removes
  // the serialisation, which is exactly what makes these tests both possible
  // and mandatory: N 401s now genuinely land in `onError` together, and a gate
  // that is opened but never settled hangs every caller that shares it.
  //
  // Each case here is genuinely simultaneous and does not rely on luck for it.
  // [burstOf] refuses to answer ANY protected request until all N have reached
  // the transport, so the N 401s are released as one batch; the refresh answer
  // is then held for [refreshHold] on top of that, which is orders of magnitude
  // longer than the few microtasks the remaining callers need to reach the
  // gate. The recorded trace proves the simultaneity rather than assuming it:
  // all N protected calls appear before the first refresh, which a sequential
  // run cannot produce.
  group('AC-18 — N concurrent 401s share exactly one refresh', () {
    /// How long the refresh answer is held open. Long enough that every caller
    /// in the burst is provably parked on the gate before it settles.
    const Duration refreshHold = Duration(milliseconds: 50);

    /// A responder that answers protected requests only once all [n] of them
    /// have reached the transport, so the N 401s are released as one batch.
    ScriptedResponder burstOf(
      int n, {
      required FutureOr<ResponseBody> Function(RequestOptions options) onRefresh,
      required FutureOr<ResponseBody> Function(RequestOptions options)
          onProtected,
    }) {
      final Completer<void> allArrived = Completer<void>();
      int arrived = 0;
      return (RequestOptions options, int _) async {
        if (options.path == ApiEndpoint.authRefresh) return onRefresh(options);
        arrived++;
        if (arrived >= n && !allArrived.isCompleted) allArrived.complete();
        await allArrived.future;
        return onProtected(options);
      };
    }

    ResponseBody unauthorized(RequestOptions _) =>
        jsonResponse(failEnvelope(code: ApiCode.unauthorized), statusCode: 401);

    test('the success exit: one refresh, N replays, every caller resolves',
        () async {
      const int n = 4;
      int refreshCalls = 0;

      final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(burstOf(
        n,
        onRefresh: (RequestOptions _) async {
          refreshCalls++;
          await Future<void>.delayed(refreshHold);
          return jsonResponse(refreshEnvelope());
        },
        onProtected: (RequestOptions options) =>
            options.headers['Authorization'] == 'Bearer access-old'
                ? jsonResponse(failEnvelope(code: ApiCode.unauthorized),
                    statusCode: 401)
                : jsonResponse(
                    okEnvelope(<String, dynamic>{'path': options.path})),
      ));

      final List<Response<dynamic>> responses =
          await within(Future.wait(<Future<Response<dynamic>>>[
        for (int i = 0; i < n; i++) w.dio.get<dynamic>('/protected/$i'),
      ]));

      expect(refreshCalls, 1,
          reason: 'N simultaneous 401s must share ONE refresh; N refreshes '
              'would each invalidate the previous rotated refresh token');
      expect(responses.map((Response<dynamic> r) => r.statusCode).toList(),
          List<int>.filled(n, 200),
          reason: 'every caller in the burst resolves — none is left on the '
              'gate');
      expect(
        responses
            .map((Response<dynamic> r) =>
                ((r.data as Map<String, dynamic>)['data']
                    as Map<String, dynamic>)['path'])
            .toSet(),
        <String>{for (int i = 0; i < n; i++) '/protected/$i'},
        reason: 'each caller got its OWN answer back, not another one\'s',
      );

      final List<String> paths = pathsOf(w.adapter);
      expect(
        paths.take(n).toSet(),
        <String>{for (int i = 0; i < n; i++) '/protected/$i'},
        reason: 'all N were in flight before the refresh went out — this is '
            'what makes the burst concurrent rather than sequential, and a '
            'sequential run cannot produce this trace',
      );
      expect(paths.where((String p) => p == ApiEndpoint.authRefresh), hasLength(1));
      expect(paths, hasLength(n * 2 + 1),
          reason: 'N originals, one refresh, N replays');
      expect(
        w.adapter.requests
            .skip(n + 1)
            .map((RequestOptions r) => r.headers['Authorization'])
            .toSet(),
        <String>{'Bearer access-new'},
        reason: 'every replay carried the refreshed token',
      );
    });

    test('the pre-POST early return: no refresh token held still resolves '
        'every caller', () async {
      // `_performRefresh` returns false before sending anything. Under D-4 that
      // exit left the completer unsettled, so caller 1 hung on its own future
      // and callers 2..N hung on the gate. `slowReadStorageService` holds the
      // token read open so the gate really is contended — without it this exit
      // is over in two microtasks and the sharing might never happen.
      store.remove(StorageKeys.refreshToken);
      final List<String> reads = <String>[];
      storage = slowReadStorageService(store, refreshHold, readLog: reads);
      const int n = 3;
      int refreshCalls = 0;

      final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(burstOf(
        n,
        onRefresh: (RequestOptions _) {
          refreshCalls++;
          return jsonResponse(refreshEnvelope());
        },
        onProtected: unauthorized,
      ));

      final List<Object> errors = await Future.wait(<Future<Object>>[
        for (int i = 0; i < n; i++) errorFrom(w.dio.get<dynamic>('/p$i')),
      ]);

      expect(refreshCalls, 0,
          reason: 'with no refresh token there is nothing to send');
      expect(errors, everyElement(isA<DioException>()));
      expect(errors, hasLength(n));
      expect(store.containsKey(StorageKeys.accessToken), isFalse);
      expect(pathsOf(w.adapter), hasLength(n),
          reason: 'N originals and nothing else');
      // This exit sends no HTTP call, so the request trace cannot show whether
      // the burst shared one refresh. The token read can: `_performRefresh`
      // reads the refresh-token key once per refresh it opens.
      expect(
        reads.where((String k) => k == StorageKeys.refreshToken), hasLength(1),
        reason: 'the other N-1 callers went through the shared gate, so this '
            'exit really is settling a contended completer and not just its '
            'own',
      );
    });

    test('the exception exit: a refresh POST that 401s still resolves every '
        'caller', () async {
      const int n = 3;
      int refreshCalls = 0;

      final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(burstOf(
        n,
        onRefresh: (RequestOptions _) async {
          refreshCalls++;
          await Future<void>.delayed(refreshHold);
          return jsonResponse(failEnvelope(code: ApiCode.unauthorized),
              statusCode: 401);
        },
        onProtected: unauthorized,
      ));

      final List<Object> errors = await Future.wait(<Future<Object>>[
        for (int i = 0; i < n; i++) errorFrom(w.dio.get<dynamic>('/p$i')),
      ]);

      expect(refreshCalls, 1,
          reason: 'the gate was shared — proof the other N-1 callers reached a '
              'completer that the exception arm then had to settle');
      expect(
        errors
            .cast<DioException>()
            .map((DioException e) => e.response?.statusCode)
            .toSet(),
        <int>{401},
      );
      expect(store.containsKey(StorageKeys.accessToken), isFalse,
          reason: 'a failed refresh signs the citizen out, once per caller and '
              'idempotently');
      expect(pathsOf(w.adapter), hasLength(n + 1),
          reason: 'N originals plus the single refresh; no replays');
    });

    test('the post-POST early return: a success:false refresh envelope still '
        'resolves every caller', () async {
      const int n = 3;
      int refreshCalls = 0;

      final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(burstOf(
        n,
        onRefresh: (RequestOptions _) async {
          refreshCalls++;
          await Future<void>.delayed(refreshHold);
          // 200, so nothing throws: `_performRefresh` reads the envelope and
          // takes its `if (!success) return false` exit. A distinct exit from
          // the exception arm above, and one the `finally` also has to cover.
          return jsonResponse(failEnvelope(message: 'refresh rejected'));
        },
        onProtected: unauthorized,
      ));

      final List<Object> errors = await Future.wait(<Future<Object>>[
        for (int i = 0; i < n; i++) errorFrom(w.dio.get<dynamic>('/p$i')),
      ]);

      expect(refreshCalls, 1);
      expect(errors, everyElement(isA<DioException>()));
      expect(store.containsKey(StorageKeys.accessToken), isFalse);
      expect(pathsOf(w.adapter), hasLength(n + 1));
    });
  });

  // ── AC-20 — the D-1 fix did not silently disable refresh ───────────────────
  //
  // architecture-review.md § 1.3 names the trap: the obvious way to make
  // `_unwrap`'s non-2xx branch live is a permissive `validateStatus`, and that
  // would stop non-2xx raising a `DioException` at all. `onError` is the ONLY
  // door a 401 can reach this interceptor through, so refresh would die
  // outright — and the AC-17 group above would go green *because no refresh
  // happens*, which reads exactly like success.
  //
  // This drives the real `ApiClient` over the real interceptor chain, so both
  // halves of the fix are in the same frame. The companion structural check —
  // that `buildDio` itself still rejects non-2xx — is in
  // `dio_network_client_test.dart`.
  group('AC-20 — 401 → refresh → replay still fires through ApiClient', () {
    test('the caller gets its data, and the replay carried the refreshed token',
        () async {
      final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(
        (RequestOptions options, int _) {
          if (options.path == ApiEndpoint.authRefresh) {
            return jsonResponse(refreshEnvelope());
          }
          return options.headers['Authorization'] == 'Bearer access-old'
              ? jsonResponse(
                  failEnvelope(code: ApiCode.unauthorized, message: 'expired'),
                  statusCode: 401)
              : jsonResponse(okEnvelope(<String, dynamic>{'id': 'me'}));
        },
      );
      final ApiClient client = ApiClient(dio: w.dio, storage: storage);

      // Assertion 1 — the citizen's data actually came back. If non-2xx stopped
      // raising, `_unwrap` would see the 401 itself and throw
      // ApiException(401, UNAUTHORIZED) here instead, and this line would fail
      // before any of the others were reached.
      final Map<String, dynamic> profile = await within(
        client.get<Map<String, dynamic>>(ApiEndpoint.meProfile),
      );
      expect(profile, <String, dynamic>{'id': 'me'});

      // Assertion 2 — the refresh POST and the replay are both on the wire. A
      // disabled refresh leaves a single entry here.
      expect(
        pathsOf(w.adapter),
        <String>[
          ApiEndpoint.meProfile,
          ApiEndpoint.authRefresh,
          ApiEndpoint.meProfile,
        ],
      );

      // Assertion 3 — the strong one. The replay is not merely a second
      // request; it carried the token the refresh minted. A replay still
      // holding `access-old` would mean the refresh ran but its result never
      // reached the retry, which no count-based assertion would notice.
      expect(w.adapter.requests.last.headers['Authorization'],
          'Bearer access-new');
      expect(w.adapter.requests.last.extra['retryAttempt'], 1);
      expect(store[StorageKeys.accessToken], 'access-new');
    });

    test('a 422 unwraps its envelope on the same client that refreshes 401s',
        () async {
      // The other side of the same interaction: the D-1 behaviour has to hold
      // *with* `RefreshInterceptor` installed, not just on the bare client the
      // `api_client_test.dart` cases use. A 422 is not a 401, so it must pass
      // straight through the interceptor and still arrive as a real envelope.
      final ({Dio dio, RecordingHttpAdapter adapter}) w = wire(
        (RequestOptions options, int _) => jsonResponse(
          failEnvelope(
            code: ApiCode.validationError,
            message: 'The given data was invalid.',
            errors: <Map<String, dynamic>>[
              <String, dynamic>{'field': 'phone', 'message': 'already taken'},
            ],
          ),
          statusCode: 422,
        ),
      );
      final ApiClient client = ApiClient(dio: w.dio, storage: storage);

      final Object error = await errorFrom(
        client.post<Map<String, dynamic>>(ApiEndpoint.authRegister),
      );

      expect(
        error,
        isA<ApiException>()
            .having((ApiException e) => e.code, 'code', ApiCode.validationError)
            .having((ApiException e) => e.fieldMap(), 'fieldMap',
                <String, String>{'phone': 'already taken'}),
      );
      expect(pathsOf(w.adapter), <String>[ApiEndpoint.authRegister],
          reason: 'a 422 must not trigger a refresh');
      expect(store[StorageKeys.accessToken], 'access-old',
          reason: 'and must not sign the citizen out');
    });
  });
}

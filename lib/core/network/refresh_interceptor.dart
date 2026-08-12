/// RefreshInterceptor — on a 401, refresh the access token once and replay
/// the request exactly once; concurrent 401s share the same refresh via a
/// [Completer] gate.
///
/// Ported from `lcc-app/src/app/api/client.ts` `refreshSession` + the 401
/// retry branch in `send()`:
///
/// - If the request is to `/auth/refresh` or marked `anonymous`, the
///   interceptor is skipped (a refresh failing with 401 must not recurse).
/// - A 401 triggers a single `_refreshCompleter`-gated refresh. Ten
///   concurrent 401s share the same refresh so they do not invalidate each
///   other's token.
/// - If the refresh succeeds, the original request is replayed once with the
///   new Authorization header. If it fails, the stored tokens are cleared.
///
/// ## Two structural rules, and why breaking either re-opens a critical defect
///
/// **1. Plain [Interceptor], never [QueuedInterceptor] (defect D-2).** dio
/// keeps one task queue per phase per queued interceptor, and an `onError`
/// task holds the error queue for as long as it is awaiting. A queued
/// `onError` that awaits a nested call whose own failure has to travel back
/// through that same queue therefore waits on itself: permanent deadlock, on
/// the ordinary expired-refresh-token path, with no timeout to rescue it.
/// Both nested calls below (the refresh POST and the replay) are exactly that
/// shape, so this class must not be queued.
///
/// **2. The [Completer] gate has to genuinely work (defect D-4).** Rule 1
/// removes dio's serialisation, so N simultaneous 401s really do arrive in
/// [onError] at once. Without a working gate they would fire N refreshes, each
/// invalidating the previous one's rotated refresh token — a worse,
/// load-dependent version of the bug rule 1 fixes. The gate is what makes the
/// "concurrent 401s share the same refresh" sentence at the top of this doc
/// true rather than aspirational: it was false before GOR-246, because the
/// completer was created and discarded but never completed, so any caller that
/// reached it awaited forever.
library;

import 'dart:async';

import 'package:dio/dio.dart';

import '../constant/api_endpoint.dart';
import '../storage/storage_service.dart';

class RefreshInterceptor extends Interceptor {
  /// [_dio] is the client this interceptor is installed on: `buildDio` passes
  /// the very instance it is adding the interceptor to, and both test
  /// harnesses do the same.
  ///
  /// That wiring is the composition-root half of D-2 (code review CR-11), so
  /// rather than *documenting* a "do not hand me my own Dio" precondition that
  /// every existing call site already violates, this class removes the need
  /// for one: the refresh POST never goes out on [_dio] at all. It is sent on
  /// a private, interceptor-free client ([_isolatedRefreshClient]), so it
  /// cannot re-enter the chain this interceptor belongs to no matter what a
  /// caller passes in — including the self-same instance.
  ///
  /// The replay deliberately does stay on [_dio], because a replayed request
  /// must traverse the full chain (Authorization header, debug logging) to be
  /// the same request. That is safe under rule 1: there is no queue to
  /// deadlock against, and the `retryAttempt` marker stops it recursing.
  RefreshInterceptor(this._dio, this._storage);

  /// The client this interceptor is installed on. Used to replay the original
  /// request, and as the template for [_isolatedRefreshClient] — never to send
  /// the refresh POST itself.
  final Dio _dio;
  final StorageService _storage;

  /// Guards a single in-flight refresh so concurrent 401s share it. Non-null
  /// exactly while a refresh is running; [_runRefresh] settles and clears it on
  /// every exit path.
  Completer<bool>? _refreshCompleter;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final options = err.requestOptions;

    final isRefreshCall = options.path == ApiEndpoint.authRefresh;
    final isAnonymous = (options.extra['anonymous'] as bool?) ?? false;
    final alreadyRetried = (options.extra['retryAttempt'] as int?) ?? 0;

    // Only handle 401 on a non-anonymous, non-refresh call that has not
    // already been retried.
    if (status != 401 || isRefreshCall || isAnonymous || alreadyRetried >= 1) {
      handler.next(err);
      return;
    }

    final refreshed = await _refreshSession();
    if (!refreshed) {
      await _storage.clearTokens();
      handler.next(err);
      return;
    }

    // Replay the original request once with the fresh token.
    try {
      final newToken = await _storage.getAccessToken();
      options.headers['Authorization'] = 'Bearer $newToken';
      options.extra['retryAttempt'] = 1;

      final response = await _dio.fetch(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Refresh the access token once; concurrent callers share the same future.
  /// Returns `true` on success, `false` on any failure.
  ///
  /// Mirrors the `refreshing` Promise gate in `refreshSession()`. The check and
  /// the claim below are deliberately in a synchronous prologue — there is no
  /// `await` between reading [_refreshCompleter] and assigning it, so two 401s
  /// arriving in the same event-loop turn cannot both open a refresh.
  Future<bool> _refreshSession() {
    final inFlight = _refreshCompleter;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<bool>();
    _refreshCompleter = completer;
    unawaited(_runRefresh(completer));
    return completer.future;
  }

  /// Drives one refresh to completion and settles [completer] on **every** exit
  /// path: success, each early `return false` in [_performRefresh], and both
  /// the DioException and the catch-all arms.
  ///
  /// Defect D-4 was the absence of exactly this: the old code created the
  /// completer, cleared the field in a `finally`, and never called `.complete`
  /// anywhere in the file, so every caller that reached the gate hung.
  /// Completing from a `finally` makes that a structural property rather than a
  /// promise — a future early return cannot slip past it.
  Future<void> _runRefresh(Completer<bool> completer) async {
    var refreshed = false;
    try {
      refreshed = await _performRefresh();
    } catch (_) {
      // A non-2xx refresh raises DioException; a malformed body can raise a
      // cast error. Neither is recoverable, and both mean "not refreshed".
      refreshed = false;
    } finally {
      // Clear the gate *before* completing it, so a caller woken by this
      // completion opens a fresh refresh instead of re-awaiting a settled one.
      _refreshCompleter = null;
      completer.complete(refreshed);
    }
  }

  /// The refresh call itself. Returns `true` only when a usable access token
  /// came back and was persisted; every other outcome returns `false` or
  /// throws, and [_runRefresh] treats both the same way.
  Future<bool> _performRefresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    final response = await _isolatedRefreshClient().post<Map<String, dynamic>>(
      ApiEndpoint.authRefresh,
      data: <String, dynamic>{'refresh_token': refreshToken},
      options: Options(
        // The refresh call itself must be anonymous (no Authorization header)
        // and must not recurse through the interceptor.
        extra: <String, dynamic>{'anonymous': true},
        headers: <String, dynamic>{'Accept': 'application/json'},
      ),
    );

    final body = response.data;
    if (body == null) return false;

    final success = body['success'] as bool? ?? false;
    if (!success) return false;

    final data = body['data'];
    if (data is! Map<String, dynamic>) return false;

    final tokens = data['tokens'];
    if (tokens is! Map<String, dynamic>) return false;

    final access = tokens['access_token'] as String?;
    if (access == null || access.isEmpty) return false;

    final refresh = tokens['refresh_token'] as String?;
    await _storage.saveTokens(access, refresh);
    return true;
  }

  /// A private, interceptor-free [Dio] that carries the refresh POST.
  ///
  /// It borrows the host's [BaseOptions] and transport, so it reaches the same
  /// server, through the same adapter, with the same timeouts — but it holds no
  /// interceptors, which is the point: the refresh POST cannot re-enter
  /// [RefreshInterceptor], so it can neither recurse nor (under a future queued
  /// interceptor) deadlock against the request it is trying to rescue.
  ///
  /// Built per refresh rather than cached because a `Dio`'s adapter is
  /// routinely installed *after* its interceptors are — `buildTestDio`,
  /// `bootHarness` and `DioAdapter` all do that — so a client captured at
  /// construction time would hold the wrong transport.
  Dio _isolatedRefreshClient() {
    final client = Dio(_dio.options.copyWith());
    client.httpClientAdapter = _dio.httpClientAdapter;
    client.transformer = _dio.transformer;
    return client;
  }
}

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
library;

import 'dart:async';

import 'package:dio/dio.dart';

import '../constant/api_endpoint.dart';
import '../storage/storage_service.dart';

class RefreshInterceptor extends QueuedInterceptor {
  RefreshInterceptor(this._dio, this._storage);

  final Dio _dio;
  final StorageService _storage;

  /// Guards a single in-flight refresh so concurrent 401s share it.
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
  /// Mirrors the `refreshing` Promise gate in `refreshSession()`.
  Future<bool> _refreshSession() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final response = await _dio.post<Map<String, dynamic>>(
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
    } on DioException {
      return false;
    } catch (_) {
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }
}

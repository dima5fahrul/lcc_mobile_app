/// AuthInterceptor — adds `Authorization: Bearer <token>` and `Accept:
/// application/json` to every request that is not marked `anonymous`.
///
/// Adapts the flutter-boilerplate `AuthInterceptor`:
/// - The boilerplate read a `const` TMDB access token. Here the token is read
///   at runtime from [StorageService] because it rotates (login/refresh/logout).
/// - `anonymous` requests skip the Authorization header. The flag is passed
///   through `RequestOptions.extra['anonymous'] = true` by [ApiClient].
library;

import 'package:dio/dio.dart';

import '../storage/storage_service.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final StorageService _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isAnonymous = (options.extra['anonymous'] as bool?) ?? false;

    options.headers['Accept'] = 'application/json';

    if (!isAnonymous) {
      final token = await _storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }
}

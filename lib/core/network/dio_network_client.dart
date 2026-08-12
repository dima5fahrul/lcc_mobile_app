/// Dio setup — the top-level [buildDio] function.
///
/// Extends the flutter-boilerplate `buildDio`:
/// - base URL comes from [ApiEndpoint.baseUrl] (dart-define-driven, no TMDB).
/// - adds [AuthInterceptor] and [RefreshInterceptor] (the boilerplate only had
///   a const-token AuthInterceptor; LCC needs runtime token reads + 401 retry).
/// - `extraInterceptors` lets debug builds attach `ChuckerDioInterceptor`.
library;

import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constant/api_endpoint.dart';
import '../storage/storage_service.dart';
import 'auth_interceptor.dart';
import 'refresh_interceptor.dart';

/// Build a configured [Dio] instance for the LCC API.
///
/// Always installs [AuthInterceptor] + [RefreshInterceptor]; `extraInterceptors`
/// is for debug-only tools (e.g. `ChuckerDioInterceptor`) so they do not
/// pollute release builds.
Dio buildDio({
  required StorageService storage,
  List<Interceptor> extraInterceptors = const <Interceptor>[],
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoint.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      // Default to JSON; multipart uploads override per-request.
      contentType: 'application/json',
    ),
  );

  dio.interceptors.add(AuthInterceptor(storage));
  dio.interceptors.add(RefreshInterceptor(dio, storage));
  dio.interceptors.addAll(extraInterceptors);

  return dio;
}

/// Debug-mode extra interceptors. Kept as a function so the call site in
/// [DependencyInjection] reads `buildDio(extraInterceptors: debugInterceptors())`.
List<Interceptor> debugInterceptors() {
  if (!kDebugMode) return const <Interceptor>[];
  return <Interceptor>[ChuckerDioInterceptor()];
}

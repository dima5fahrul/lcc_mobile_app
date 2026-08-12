/// Shared doubles for the **core** layer (`core/network`, `core/storage`).
///
/// Split from `auth_test_helper.dart` rather than bolted onto it: that file is
/// a flat bag of `Mock*` classes for the auth feature's collaborators, and the
/// core layer needs a different *kind* of double — a real `Dio` driven by a
/// stub transport, so the interceptors under test actually run. Mixing the two
/// would make every auth test pull in `dio` and every network test pull in six
/// auth usecases.
///
/// ## Which faking tool, and why
///
/// - **`mocktail`** at architectural seams — `FlutterSecureStorage`
///   (a platform channel, unusable headless) and, elsewhere, repository ↔
///   datasource ↔ usecase boundaries.
/// - **A hand-written [RecordingHttpAdapter]** for `core/network`. The tests
///   there assert on *what left the client* (`Authorization` header present or
///   absent, `retryAttempt` marker, call ordering) and need a 401 to be
///   followed by a 200 on the same route. `http_mock_adapter` keys a single
///   canned response per route, so a 401-then-200 sequence is not expressible
///   in it; this adapter takes `(options, callIndex)` and can.
/// - **`http_mock_adapter`** is used where a plain canned route reply is the
///   whole requirement — see `test/helpers/app_test_harness.dart`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lcc_mobile_app/core/network/auth_interceptor.dart';
import 'package:lcc_mobile_app/core/network/refresh_interceptor.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:mocktail/mocktail.dart';

/// Base URL every test `Dio` is pointed at. Deliberately not
/// `ApiEndpoint.baseUrl`: that constant is `--dart-define`-driven, so a test
/// asserting on a full URI would pass or fail depending on how the suite was
/// invoked.
const String kTestBaseUrl = 'https://api.test.invalid/api/v1';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

/// A [FlutterSecureStorage] backed by the plain map [store], which the caller
/// keeps a handle on so it can assert what was persisted (and seed a "warm
/// boot with a stored token" case).
FlutterSecureStorage inMemorySecureStorage(Map<String, String> store) {
  final MockSecureStorage mock = MockSecureStorage();

  when(() => mock.read(key: any(named: 'key'))).thenAnswer(
    (Invocation i) async => store[i.namedArguments[#key] as String],
  );

  when(() => mock.write(key: any(named: 'key'), value: any(named: 'value')))
      .thenAnswer((Invocation i) async {
    final String key = i.namedArguments[#key] as String;
    final String? value = i.namedArguments[#value] as String?;
    if (value == null) {
      store.remove(key);
    } else {
      store[key] = value;
    }
  });

  when(() => mock.delete(key: any(named: 'key')))
      .thenAnswer((Invocation i) async {
    store.remove(i.namedArguments[#key] as String);
  });

  return mock;
}

/// A real [StorageService] over [inMemorySecureStorage].
StorageService inMemoryStorageService(Map<String, String> store) =>
    StorageService(inMemorySecureStorage(store));

// ── Envelope builders ───────────────────────────────────────────────────────

/// A success envelope: `{success: true, message, data, ...}`.
Map<String, dynamic> okEnvelope(
  Object? data, {
  String message = 'OK',
  Map<String, dynamic>? meta,
  String? requestId,
}) {
  return <String, dynamic>{
    'success': true,
    'message': message,
    'data': data,
    if (meta != null) 'meta': meta,
    if (requestId != null) 'request_id': requestId,
  };
}

/// A failure envelope: `{success: false, code, message, errors, request_id}`.
Map<String, dynamic> failEnvelope({
  String code = 'BAD_REQUEST',
  String message = 'Something went wrong.',
  List<Map<String, dynamic>>? errors,
  String? requestId,
}) {
  return <String, dynamic>{
    'success': false,
    'message': message,
    'code': code,
    'data': null,
    if (errors != null) 'errors': errors,
    if (requestId != null) 'request_id': requestId,
  };
}

/// The `meta` block shape `PageMeta.fromJson` expects.
Map<String, dynamic> pageMetaJson({
  int page = 1,
  int perPage = 20,
  int total = 40,
  int totalPages = 2,
  bool hasNext = true,
  bool hasPrev = false,
}) {
  return <String, dynamic>{
    'page': page,
    'per_page': perPage,
    'total': total,
    'total_pages': totalPages,
    'has_next': hasNext,
    'has_prev': hasPrev,
  };
}

// ── Transport double ────────────────────────────────────────────────────────

/// Produces the transport-level answer for call number [callIndex] (0-based)
/// on this adapter. Throw a [DioException] to simulate a transport failure.
typedef ScriptedResponder = FutureOr<ResponseBody> Function(
  RequestOptions options,
  int callIndex,
);

/// A [HttpClientAdapter] that records every request and answers from a
/// caller-supplied script.
///
/// Sits *below* the interceptor chain, so `AuthInterceptor` and
/// `RefreshInterceptor` run for real and [requests] shows exactly the headers
/// and `extra` markers they produced.
class RecordingHttpAdapter implements HttpClientAdapter {
  RecordingHttpAdapter(this.responder);

  /// Always answers [body] with [statusCode], whatever is asked.
  factory RecordingHttpAdapter.always(Object? body, {int statusCode = 200}) {
    return RecordingHttpAdapter(
      (RequestOptions _, int __) => jsonResponse(body, statusCode: statusCode),
    );
  }

  final ScriptedResponder responder;

  /// Every request that reached the transport, in order.
  final List<RequestOptions> requests = <RequestOptions>[];

  int get callCount => requests.length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final int index = requests.length;
    requests.add(options);
    return responder(options, index);
  }

  @override
  void close({bool force = false}) {}
}

/// A JSON [ResponseBody] carrying [body] encoded, with a JSON content type so
/// Dio's transformer decodes it into a `Map`.
ResponseBody jsonResponse(Object? body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

/// A plain-text [ResponseBody] — used by the `raw: true` (CSV export) path.
ResponseBody textResponse(String body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    body,
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>['text/plain'],
    },
  );
}

/// A `Dio` configured the way `buildDio` configures the real one — same two
/// interceptors, same base options — but pointed at [adapter] instead of a
/// socket, and without the debug-only Chucker interceptor (which needs
/// `SharedPreferences` and has no place in a headless run).
///
/// [withInterceptors] false yields a bare client, for the tests that want to
/// exercise `ApiClient`'s envelope handling with nothing in the way.
Dio buildTestDio({
  required StorageService storage,
  required HttpClientAdapter adapter,
  bool withInterceptors = true,
}) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: kTestBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ),
  );

  if (withInterceptors) {
    dio.interceptors.add(AuthInterceptor(storage));
    dio.interceptors.add(RefreshInterceptor(dio, storage));
  }

  dio.httpClientAdapter = adapter;
  return dio;
}

/// `ApiClient` — envelope unwrap, error mapping, paged reads, verb surface.
///
/// Plan § Testing names this file ("envelope unwrap, 401 retry, ApiException
/// fields, paged"); GOR-245 § 3.1 repeats it. The 401-retry half lives in
/// `refresh_interceptor_test.dart`, because that behaviour belongs to
/// `RefreshInterceptor` and testing it here would assert on a collaborator.
///
/// Driven through a real `Dio` on a stub transport rather than a mocked `Dio`:
/// the thing under test is the *seam between* Dio and the envelope, and a
/// mocked Dio would let a wrong `ResponseType` or a wrong cast pass unnoticed.
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/core/network/envelope.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';

import '../../helpers/core_test_helper.dart';

void main() {
  late Map<String, String> store;
  late StorageService storage;

  setUp(() {
    store = <String, String>{};
    storage = inMemoryStorageService(store);
  });

  /// A client whose transport answers from [responder].
  ///
  /// The `Dio` is configured exactly as `buildDio` configures the shipped one,
  /// `validateStatus` included — so every case in this file, the non-2xx ones
  /// especially, runs the code path the app runs. That was not true before
  /// GOR-246: the non-2xx cases needed a test-only permissive `validateStatus`
  /// to reach `_unwrap`'s failure branch at all, which is precisely what defect
  /// D-1 was. The knob is gone rather than left unused, because a test-only
  /// configuration that mirrors nothing in production is a place for a wrong
  /// answer to hide.
  ({ApiClient client, RecordingHttpAdapter adapter}) clientWith(
    ScriptedResponder responder,
  ) {
    final RecordingHttpAdapter adapter = RecordingHttpAdapter(responder);
    final Dio dio = buildTestDio(
      storage: storage,
      adapter: adapter,
      withInterceptors: false,
    );
    return (client: ApiClient(dio: dio, storage: storage), adapter: adapter);
  }

  ApiClient clientReplying(Object? body, {int statusCode = 200}) {
    return clientWith(
      (RequestOptions _, int __) => jsonResponse(body, statusCode: statusCode),
    ).client;
  }

  group('construction', () {
    test('exposes the injected StorageService', () {
      final ApiClient client = clientReplying(okEnvelope(null));
      expect(client.storage, same(storage));
    });
  });

  group('request — envelope unwrap', () {
    test('returns the envelope data on success', () async {
      final ApiClient client =
          clientReplying(okEnvelope(<String, dynamic>{'id': 'abc'}));

      final Map<String, dynamic> data =
          await client.get<Map<String, dynamic>>('/thing');

      expect(data, <String, dynamic>{'id': 'abc'});
    });

    test('returns null data as null', () async {
      final ApiClient client = clientReplying(okEnvelope(null));

      final dynamic data = await client.get<dynamic>('/thing');

      expect(data, isNull);
    });

    test('throws ApiException carrying code, message, requestId and fields '
        'when the envelope says success:false on a 200', () async {
      final ApiClient client = clientReplying(
        failEnvelope(
          code: ApiCode.validationError,
          message: 'Validation failed',
          requestId: 'req-77',
          errors: <Map<String, dynamic>>[
            <String, dynamic>{
              'field': 'phone',
              'rule': 'format',
              'message': 'phone is invalid',
            },
            <String, dynamic>{'field': 'name', 'message': 'name is required'},
          ],
        ),
      );

      await expectLater(
        client.get<dynamic>('/thing'),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.status, 'status', 200)
              .having((ApiException e) => e.code, 'code', ApiCode.validationError)
              .having((ApiException e) => e.message, 'message', 'Validation failed')
              .having((ApiException e) => e.requestId, 'requestId', 'req-77')
              .having(
                (ApiException e) => e.fieldMap(),
                'fieldMap',
                <String, String>{
                  'phone': 'phone is invalid',
                  'name': 'name is required',
                },
              ),
        ),
      );
    });

    test('falls back to INTERNAL_ERROR and a generic message when the failing '
        'envelope omits code and message', () async {
      final ApiClient client =
          clientReplying(<String, dynamic>{'success': false});

      await expectLater(
        client.get<dynamic>('/thing'),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.code, 'code', ApiCode.internalError)
              .having((ApiException e) => e.message, 'message',
                  'Something went wrong.')
              .having((ApiException e) => e.fields, 'fields', isEmpty),
        ),
      );
    });

    test('ignores a non-list errors block rather than throwing', () async {
      final ApiClient client = clientReplying(<String, dynamic>{
        'success': false,
        'message': 'nope',
        'code': ApiCode.badRequest,
        'errors': 'not-a-list',
      });

      await expectLater(
        client.get<dynamic>('/thing'),
        throwsA(isA<ApiException>()
            .having((ApiException e) => e.fields, 'fields', isEmpty)),
      );
    });

    test('throws INTERNAL_ERROR when a 200 body is not an envelope map',
        () async {
      final ApiClient client = clientReplying(<dynamic>['not', 'an', 'envelope']);

      await expectLater(
        client.get<dynamic>('/thing'),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.status, 'status', 200)
              .having((ApiException e) => e.code, 'code', ApiCode.internalError)
              .having((ApiException e) => e.message, 'message',
                  'The server sent a malformed response.'),
        ),
      );
    });
  });

  group('request — raw responses', () {
    test('returns the body verbatim when raw is true', () async {
      final RecordingHttpAdapter adapter = RecordingHttpAdapter(
        (RequestOptions _, int __) => textResponse('a,b,c\n1,2,3'),
      );
      final ApiClient client = ApiClient(
        dio: buildTestDio(
          storage: storage,
          adapter: adapter,
          withInterceptors: false,
        ),
        storage: storage,
      );

      final String csv = await client.request<String>(
        HttpMethod.get,
        '/export',
        options: const ApiRequestOptions(raw: true),
      );

      expect(csv, 'a,b,c\n1,2,3');
      expect(adapter.requests.single.responseType, ResponseType.plain);
    });
  });

  // AC-19 non-regression. The D-1 fix hands any `DioException` that carries a
  // response back to `_unwrap`, so the envelope survives; a request that never
  // got an answer has no envelope to survive, and those — and only those — must
  // still flatten to `NETWORK_ERROR`. The architecture review is explicit that
  // one wrong answer must not be traded for another, so each response-less
  // failure the fix enumerates is checked rather than assumed to follow from
  // the first one.
  group('request — transport failures', () {
    test('maps a connection error to NETWORK_ERROR with status 0', () async {
      final ApiClient client = clientWith(
        (RequestOptions options, int __) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      ).client;

      await expectLater(
        client.get<dynamic>('/thing'),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.status, 'status', 0)
              .having((ApiException e) => e.code, 'code', ApiCode.networkError)
              .having((ApiException e) => e.message, 'message',
                  'Cannot reach the server. Check your connection and try again.'),
        ),
      );
    });

    // The remaining response-less shapes. `connectionError` above covers
    // "connection refused"; these are the DNS, TLS and three timeout cases the
    // fix's own comment names. Driven from a table because the assertion is
    // identical for all of them and the point is the coverage of the set.
    for (final (DioExceptionType type, String label) shape
        in <(DioExceptionType, String)>[
      (DioExceptionType.unknown, 'a DNS failure'),
      (DioExceptionType.badCertificate, 'a TLS failure'),
      (DioExceptionType.connectionTimeout, 'a connect timeout'),
      (DioExceptionType.sendTimeout, 'a send timeout'),
      (DioExceptionType.receiveTimeout, 'a receive timeout'),
    ]) {
      test('${shape.$2} still maps to NETWORK_ERROR with status 0', () async {
        final ApiClient client = clientWith(
          (RequestOptions options, int __) => throw DioException(
            requestOptions: options,
            type: shape.$1,
          ),
        ).client;

        await expectLater(
          client.get<dynamic>('/thing'),
          throwsA(
            isA<ApiException>()
                .having((ApiException e) => e.status, 'status', 0)
                .having(
                    (ApiException e) => e.code, 'code', ApiCode.networkError)
                .having((ApiException e) => e.message, 'message',
                    'Cannot reach the server. Check your connection and try again.')
                .having((ApiException e) => e.fields, 'fields', isEmpty),
          ),
        );
      });
    }

    test('maps a cancellation to its own NETWORK_ERROR message', () async {
      final ApiClient client = clientWith(
        (RequestOptions options, int __) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
        ),
      ).client;

      await expectLater(
        client.get<dynamic>('/thing'),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.status, 'status', 0)
              .having((ApiException e) => e.code, 'code', ApiCode.networkError)
              .having((ApiException e) => e.message, 'message',
                  'Request cancelled.'),
        ),
      );
    });
  });

  group('request — verb surface and options', () {
    late RecordingHttpAdapter adapter;
    late ApiClient client;

    setUp(() {
      final ({ApiClient client, RecordingHttpAdapter adapter}) built =
          clientWith(
        (RequestOptions _, int __) => jsonResponse(okEnvelope(<String, dynamic>{
          'ok': true,
        })),
      );
      adapter = built.adapter;
      client = built.client;
    });

    test('get / post / put / patch / delete each use their own HTTP method',
        () async {
      await client.get<Map<String, dynamic>>('/a');
      await client.post<Map<String, dynamic>>('/b', body: <String, int>{'x': 1});
      await client.put<Map<String, dynamic>>('/c', body: <String, int>{'x': 2});
      await client.patch<Map<String, dynamic>>('/d', body: <String, int>{'x': 3});
      await client.delete<Map<String, dynamic>>('/e');

      expect(
        adapter.requests.map((RequestOptions r) => r.method).toList(),
        <String>['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
      );
      expect(
        adapter.requests.map((RequestOptions r) => r.path).toList(),
        <String>['/a', '/b', '/c', '/d', '/e'],
      );
    });

    test('marks the request anonymous in extra when asked', () async {
      await client.get<Map<String, dynamic>>('/a');
      await client.get<Map<String, dynamic>>('/b', anonymous: true);
      await client.post<Map<String, dynamic>>('/c', anonymous: true);

      expect(
        adapter.requests
            .map((RequestOptions r) => r.extra['anonymous'])
            .toList(),
        <bool>[false, true, true],
      );
    });

    test('drops null and empty-string query params, keeps list values',
        () async {
      await client.get<Map<String, dynamic>>(
        '/search',
        query: <String, dynamic>{
          'q': 'lao',
          'blank': '',
          'missing': null,
          'status': <String>['open', 'closed'],
          'page': 2,
        },
      );

      expect(
        adapter.requests.single.queryParameters,
        <String, dynamic>{
          'q': 'lao',
          'status': <String>['open', 'closed'],
          'page': 2,
        },
      );
    });

    test('sends an empty query map when none is supplied', () async {
      await client.get<Map<String, dynamic>>('/a');
      expect(adapter.requests.single.queryParameters, isEmpty);
    });

    test('sets a JSON content type for a body request', () async {
      await client.post<Map<String, dynamic>>('/b', body: <String, int>{'x': 1});
      expect(adapter.requests.single.contentType, contains('application/json'));
    });

    test('upload sends the FormData and lets Dio own the content type',
        () async {
      final FormData form = FormData.fromMap(<String, dynamic>{'field': 'value'});

      await client.upload<Map<String, dynamic>>('/files', form);

      final RequestOptions sent = adapter.requests.single;
      expect(sent.method, 'POST');
      expect(sent.data, same(form));
      // multipart/form-data with a Dio-generated boundary, never a hand-set
      // application/json.
      expect(sent.contentType, contains('multipart/form-data'));
    });
  });

  group('requestPaged', () {
    test('returns rows and the server meta block', () async {
      final ApiClient client = clientReplying(
        okEnvelope(
          <Map<String, dynamic>>[
            <String, dynamic>{'id': '1'},
            <String, dynamic>{'id': '2'},
          ],
          meta: pageMetaJson(page: 3, perPage: 2, total: 10, totalPages: 5),
        ),
      );

      final Paged<Map<String, dynamic>> paged =
          await client.requestPaged<Map<String, dynamic>>('/rows');

      expect(paged.data.length, 2);
      expect(paged.data.first['id'], '1');
      expect(paged.meta.page, 3);
      expect(paged.meta.perPage, 2);
      expect(paged.meta.total, 10);
      expect(paged.meta.totalPages, 5);
      expect(paged.meta.hasNext, isTrue);
      expect(paged.meta.hasPrev, isFalse);
    });

    test('synthesizes meta from the row count when the server omits it',
        () async {
      final ApiClient client = clientReplying(
        okEnvelope(<Map<String, dynamic>>[
          <String, dynamic>{'id': '1'},
          <String, dynamic>{'id': '2'},
          <String, dynamic>{'id': '3'},
        ]),
      );

      final Paged<Map<String, dynamic>> paged =
          await client.requestPaged<Map<String, dynamic>>('/rows');

      expect(paged.meta.page, 1);
      expect(paged.meta.perPage, 3);
      expect(paged.meta.total, 3);
      expect(paged.meta.totalPages, 1);
      expect(paged.meta.hasNext, isFalse);
      expect(paged.meta.hasPrev, isFalse);
    });

    test('yields an empty list when data is not a list', () async {
      final ApiClient client =
          clientReplying(okEnvelope(<String, dynamic>{'not': 'a list'}));

      final Paged<dynamic> paged = await client.requestPaged<dynamic>('/rows');

      expect(paged.data, isEmpty);
      expect(paged.meta.perPage, 0);
    });

    test('throws ApiException with the envelope code on success:false',
        () async {
      final ApiClient client = clientReplying(
        failEnvelope(
          code: ApiCode.forbidden,
          message: 'Not allowed',
          requestId: 'req-9',
          errors: <Map<String, dynamic>>[
            <String, dynamic>{'field': 'scope', 'message': 'missing'},
          ],
        ),
      );

      await expectLater(
        client.requestPaged<dynamic>('/rows'),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.code, 'code', ApiCode.forbidden)
              .having((ApiException e) => e.message, 'message', 'Not allowed')
              .having((ApiException e) => e.requestId, 'requestId', 'req-9')
              .having((ApiException e) => e.fieldMap(), 'fieldMap',
                  <String, String>{'scope': 'missing'}),
        ),
      );
    });

    test('forwards query parameters', () async {
      final ({ApiClient client, RecordingHttpAdapter adapter}) built =
          clientWith(
        (RequestOptions _, int __) =>
            jsonResponse(okEnvelope(<Map<String, dynamic>>[])),
      );

      await built.client.requestPaged<Map<String, dynamic>>(
        '/rows',
        query: <String, dynamic>{'page': 2, 'empty': ''},
      );

      expect(built.adapter.requests.single.queryParameters,
          <String, dynamic>{'page': 2});
    });

    test('maps a transport failure to NETWORK_ERROR', () async {
      final ApiClient client = clientWith(
        (RequestOptions options, int __) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        ),
      ).client;

      await expectLater(
        client.requestPaged<dynamic>('/rows'),
        throwsA(isA<ApiException>()
            .having((ApiException e) => e.code, 'code', ApiCode.networkError)),
      );
    });

    test('a non-2xx page still surfaces the envelope code, message and fields',
        () async {
      // `requestPaged` carries its own copy of the D-1 fix, in a second
      // `on DioException` arm. A list endpoint rejecting a bad filter is the
      // ordinary case for it, and it was flattened to NETWORK_ERROR too.
      final ApiClient client = clientWith(
        (RequestOptions _, int __) => jsonResponse(
          failEnvelope(
            code: ApiCode.unprocessable,
            message: 'Unknown filter value.',
            errors: <Map<String, dynamic>>[
              <String, dynamic>{'field': 'status', 'message': 'unknown value'},
            ],
            requestId: 'req-paged',
          ),
          statusCode: 422,
        ),
      ).client;

      await expectLater(
        client.requestPaged<dynamic>('/rows'),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.status, 'status', 422)
              .having((ApiException e) => e.code, 'code', ApiCode.unprocessable)
              .having((ApiException e) => e.message, 'message',
                  'Unknown filter value.')
              .having((ApiException e) => e.requestId, 'requestId', 'req-paged')
              .having((ApiException e) => e.fieldMap(), 'fieldMap',
                  <String, String>{'status': 'unknown value'}),
        ),
      );
    });

    test('rejects a plain-text body as a malformed paged response', () async {
      final RecordingHttpAdapter adapter = RecordingHttpAdapter(
        (RequestOptions _, int __) => textResponse('id,name\n1,a'),
      );
      final Dio dio = buildTestDio(
        storage: storage,
        adapter: adapter,
        withInterceptors: false,
      );
      // A paged read never asks for ResponseType.plain, so force the only
      // shape that reaches the `raw is String` guard.
      dio.options.responseType = ResponseType.plain;

      await expectLater(
        ApiClient(dio: dio, storage: storage).requestPaged<dynamic>('/rows'),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.code, 'code', ApiCode.internalError)
              .having((ApiException e) => e.message, 'message',
                  'Malformed paged response.'),
        ),
      );
    });
  });

  // ── AC-19 — the server's own error survives the trip to the caller ─────────
  //
  // This was defect D-1. `_unwrap`'s non-2xx branch was correct but
  // unreachable: dio's 2xx-only `validateStatus` raised a `DioException` before
  // `_unwrap` could run, and `request()`'s `on DioException` arm rewrote every
  // one of them as `ApiCode.networkError` with a generic "cannot reach the
  // server" message — discarding the envelope's `code`, `message` and per-field
  // `errors[]`. A 422 could never tell a form which field it was complaining
  // about, because the answer was thrown away one layer below the form.
  //
  // GOR-246 left `validateStatus` alone (deliberately — see AC-20) and instead
  // hands a present `e.response` back to `_unwrap`. So these cases now run
  // through the shipped configuration, with no test-only knob in the way. The
  // group that used to need one is folded in here; the two that documented the
  // flattened answer are inverted.
  group('non-2xx handling — the envelope survives, on the shipped Dio', () {
    test('a 422 surfaces the real code, message, fields and request id',
        () async {
      final ApiClient client = clientWith(
        (RequestOptions _, int __) => jsonResponse(
          failEnvelope(
            code: ApiCode.validationError,
            message: 'The given data was invalid.',
            errors: <Map<String, dynamic>>[
              <String, dynamic>{'field': 'phone', 'message': 'already taken'},
              <String, dynamic>{'field': 'email', 'message': 'is invalid'},
            ],
            requestId: 'req-422',
          ),
          statusCode: 422,
        ),
      ).client;

      await expectLater(
        client.post<dynamic>('/auth/citizen/register'),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.status, 'status', 422)
              .having((ApiException e) => e.code, 'code', ApiCode.validationError)
              .having((ApiException e) => e.message, 'message',
                  'The given data was invalid.')
              .having((ApiException e) => e.isValidation, 'isValidation', isTrue)
              .having((ApiException e) => e.requestId, 'requestId', 'req-422')
              // The whole point of the fix: every offending field arrives, so a
              // form can highlight all of them at once rather than one per
              // round trip.
              .having((ApiException e) => e.fieldMap(), 'fieldMap',
                  <String, String>{
                    'phone': 'already taken',
                    'email': 'is invalid',
                  }),
        ),
      );
    });

    test('a 422 on a typed request<Map<String, dynamic>> unwraps without a '
        'cast failure', () async {
      // `request`'s DioException arm calls `_unwrap<dynamic>`, not `_unwrap<T>`,
      // because dio hands back a `Response<dynamic>` whatever `T` the call
      // asked for. Every datasource in the app calls
      // `apiClient.get/post<Map<String, dynamic>>`, so a regression to
      // `_unwrap<T>` would still compile and would break all of them at
      // runtime, on the error path only. Pinned with the real call shape.
      final ApiClient client = clientWith(
        (RequestOptions _, int __) => jsonResponse(
          failEnvelope(code: ApiCode.validationError, message: 'nope'),
          statusCode: 422,
        ),
      ).client;

      await expectLater(
        client.post<Map<String, dynamic>>('/auth/citizen/register'),
        throwsA(isA<ApiException>()
            .having((ApiException e) => e.code, 'code', ApiCode.validationError)
            .having((ApiException e) => e.message, 'message', 'nope')),
      );
    });

    test('a 401 surfaces its code and message, not just its status', () async {
      final ApiClient client = clientWith(
        (RequestOptions _, int __) => jsonResponse(
          failEnvelope(code: ApiCode.unauthorized, message: 'Token expired'),
          statusCode: 401,
        ),
      ).client;

      await expectLater(
        client.get<dynamic>('/me/profile'),
        throwsA(isA<ApiException>()
            .having((ApiException e) => e.status, 'status', 401)
            .having((ApiException e) => e.code, 'code', ApiCode.unauthorized)
            .having((ApiException e) => e.message, 'message', 'Token expired')
            .having(
                (ApiException e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
      );
    });

    test('a 500 surfaces the server code rather than a network error',
        () async {
      final ApiClient client = clientWith(
        (RequestOptions _, int __) => jsonResponse(
          failEnvelope(
            code: ApiCode.serviceUnavailable,
            message: 'Registry is down for maintenance.',
          ),
          statusCode: 503,
        ),
      ).client;

      await expectLater(
        client.get<dynamic>('/thing'),
        throwsA(isA<ApiException>()
            .having((ApiException e) => e.status, 'status', 503)
            .having(
                (ApiException e) => e.code, 'code', ApiCode.serviceUnavailable)
            .having((ApiException e) => e.message, 'message',
                'Registry is down for maintenance.')),
      );
    });

    test('reports a null body on a non-2xx as a malformed response', () async {
      final ApiClient client = clientWith(
        (RequestOptions _, int __) => jsonResponse(null, statusCode: 500),
      ).client;

      await expectLater(
        client.get<dynamic>('/thing'),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.status, 'status', 500)
              .having((ApiException e) => e.code, 'code', ApiCode.internalError)
              .having((ApiException e) => e.message, 'message',
                  'The server sent a malformed response.'),
        ),
      );
    });

    test('reports a non-2xx whose body is JSON but not an envelope object',
        () async {
      // A JSON array where an envelope was expected — the shape a misbehaving
      // gateway or an error page rendered by the wrong middleware produces.
      // `_unwrap` has nothing to read a `code` out of, so it must say the
      // status rather than guess. Previously recorded in qa-report.md § 2.3 as
      // an unreachable line; it is reachable, and this is the case that reaches
      // it, so the "unreachable" note was wrong rather than the code being dead.
      final ApiClient client = clientWith(
        (RequestOptions _, int __) =>
            jsonResponse(<int>[1, 2, 3], statusCode: 502),
      ).client;

      await expectLater(
        client.get<dynamic>('/thing'),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.status, 'status', 502)
              .having((ApiException e) => e.code, 'code', ApiCode.internalError)
              .having((ApiException e) => e.message, 'message',
                  'Request failed with status 502.'),
        ),
      );
    });

    test('surfaces the body text on a non-2xx raw response', () async {
      final ApiClient client = clientWith(
        (RequestOptions _, int __) =>
            textResponse('gateway down', statusCode: 502),
      ).client;

      await expectLater(
        client.request<String>(
          HttpMethod.get,
          '/export',
          options: const ApiRequestOptions(raw: true),
        ),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.status, 'status', 502)
              .having((ApiException e) => e.code, 'code', ApiCode.badRequest)
              .having((ApiException e) => e.message, 'message', 'gateway down'),
        ),
      );
    });

    test('truncates a long non-2xx raw body to 200 characters', () async {
      final ApiClient client = clientWith(
        (RequestOptions _, int __) => textResponse('x' * 500, statusCode: 500),
      ).client;

      await expectLater(
        client.request<String>(
          HttpMethod.get,
          '/export',
          options: const ApiRequestOptions(raw: true),
        ),
        throwsA(isA<ApiException>()
            .having((ApiException e) => e.message.length, 'message length', 200)),
      );
    });

    test('falls back to a status message when a non-2xx raw body is empty',
        () async {
      final ApiClient client = clientWith(
        (RequestOptions _, int __) => textResponse('', statusCode: 503),
      ).client;

      await expectLater(
        client.request<String>(
          HttpMethod.get,
          '/export',
          options: const ApiRequestOptions(raw: true),
        ),
        throwsA(isA<ApiException>()
            .having((ApiException e) => e.message, 'message', 'Request failed.')),
      );
    });
  });
}

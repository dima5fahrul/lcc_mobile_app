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
  ({ApiClient client, RecordingHttpAdapter adapter}) clientWith(
    ScriptedResponder responder, {
    bool permissiveStatus = false,
  }) {
    final RecordingHttpAdapter adapter = RecordingHttpAdapter(responder);
    final Dio dio = buildTestDio(
      storage: storage,
      adapter: adapter,
      withInterceptors: false,
    );
    if (permissiveStatus) {
      // Deliberately NOT how `buildDio` configures the real client — see the
      // "unreachable in production" group at the bottom of this file.
      dio.options.validateStatus = (int? _) => true;
    }
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

  // ── Defect D-1 ─────────────────────────────────────────────────────────────
  //
  // `_unwrap`'s non-2xx branch is CORRECT but UNREACHABLE through `buildDio`.
  // Dio's default `validateStatus` (2xx only) raises a `DioException` before
  // `_unwrap` ever runs, and `request()`'s `on DioException` arm rewrites every
  // one of them as `ApiCode.networkError` with the generic "Cannot reach the
  // server" text — discarding the envelope's `code`, `message` and per-field
  // `errors`.
  //
  // These two groups pin both halves so the defect cannot be argued about:
  // the first shows what the code *does* when reached, the second shows what
  // the app actually observes today. Reported, not patched — `core/network` is
  // frozen by GOR-245 § 4.1, which requires escalation rather than a silent
  // fix or a weakened test.
  group('non-2xx handling — reached only with a permissive validateStatus', () {
    test('maps the envelope code, message and fields off a 422', () async {
      final ApiClient client = clientWith(
        (RequestOptions _, int __) => jsonResponse(
          failEnvelope(
            code: ApiCode.validationError,
            message: 'The given data was invalid.',
            errors: <Map<String, dynamic>>[
              <String, dynamic>{'field': 'phone', 'message': 'already taken'},
            ],
          ),
          statusCode: 422,
        ),
        permissiveStatus: true,
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
              .having((ApiException e) => e.fieldMap(), 'fieldMap',
                  <String, String>{'phone': 'already taken'}),
        ),
      );
    });

    test('reports a null body on a non-2xx as a malformed response', () async {
      final ApiClient client = clientWith(
        (RequestOptions _, int __) => jsonResponse(null, statusCode: 500),
        permissiveStatus: true,
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

    test('surfaces the body text on a non-2xx raw response', () async {
      final RecordingHttpAdapter adapter = RecordingHttpAdapter(
        (RequestOptions _, int __) => textResponse('gateway down', statusCode: 502),
      );
      final Dio dio = buildTestDio(
        storage: storage,
        adapter: adapter,
        withInterceptors: false,
      );
      dio.options.validateStatus = (int? _) => true;

      await expectLater(
        ApiClient(dio: dio, storage: storage).request<String>(
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
      final RecordingHttpAdapter adapter = RecordingHttpAdapter(
        (RequestOptions _, int __) =>
            textResponse('x' * 500, statusCode: 500),
      );
      final Dio dio = buildTestDio(
        storage: storage,
        adapter: adapter,
        withInterceptors: false,
      );
      dio.options.validateStatus = (int? _) => true;

      await expectLater(
        ApiClient(dio: dio, storage: storage).request<String>(
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
      final RecordingHttpAdapter adapter = RecordingHttpAdapter(
        (RequestOptions _, int __) => textResponse('', statusCode: 503),
      );
      final Dio dio = buildTestDio(
        storage: storage,
        adapter: adapter,
        withInterceptors: false,
      );
      dio.options.validateStatus = (int? _) => true;

      await expectLater(
        ApiClient(dio: dio, storage: storage).request<String>(
          HttpMethod.get,
          '/export',
          options: const ApiRequestOptions(raw: true),
        ),
        throwsA(isA<ApiException>()
            .having((ApiException e) => e.message, 'message', 'Request failed.')),
      );
    });
  });

  group('DEFECT D-1 — what the app actually sees today', () {
    test('a 422 validation envelope reaches the caller as NETWORK_ERROR with '
        'no field errors, because Dio rejects the status before _unwrap runs',
        () async {
      // Same server response as the permissive-validateStatus test above, but
      // through a Dio configured exactly as `buildDio` configures it.
      final ApiClient client = clientWith(
        (RequestOptions _, int __) => jsonResponse(
          failEnvelope(
            code: ApiCode.validationError,
            message: 'The given data was invalid.',
            errors: <Map<String, dynamic>>[
              <String, dynamic>{'field': 'phone', 'message': 'already taken'},
            ],
          ),
          statusCode: 422,
        ),
      ).client;

      await expectLater(
        client.post<dynamic>('/auth/citizen/register'),
        throwsA(
          isA<ApiException>()
              // The status survives, so `isValidation` still answers true …
              .having((ApiException e) => e.status, 'status', 422)
              .having((ApiException e) => e.isValidation, 'isValidation', isTrue)
              // … but the machine-readable code, the server's message and every
              // per-field error are gone. The register/login forms therefore
              // cannot highlight the offending field, which is what the plan's
              // manual-verification item 8 expects them to do.
              .having((ApiException e) => e.code, 'code', ApiCode.networkError)
              .having((ApiException e) => e.message, 'message',
                  'Cannot reach the server. Check your connection and try again.')
              .having((ApiException e) => e.fields, 'fields', isEmpty),
        ),
      );
    });

    test('a 401 still answers isUnauthorized, so the session guard survives',
        () async {
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
            .having((ApiException e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
      );
    });
  });
}

/// `AuthInterceptor` — token injection and the `anonymous` skip.
///
/// Named by plan § Testing and GOR-245 § 3.1. Asserted at the transport, not
/// by calling `onRequest` by hand: the contract is "what leaves the client",
/// and hand-invoking the interceptor would not prove it is actually installed
/// in the chain the way `buildDio` installs it.
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';

import '../../helpers/core_test_helper.dart';

void main() {
  late Map<String, String> store;
  late StorageService storage;
  late RecordingHttpAdapter adapter;
  late Dio dio;

  setUp(() {
    store = <String, String>{};
    storage = inMemoryStorageService(store);
    adapter = RecordingHttpAdapter.always(okEnvelope(null));
    dio = buildTestDio(storage: storage, adapter: adapter);
  });

  Map<String, dynamic> sentHeaders() => adapter.requests.single.headers;

  test('always sets Accept: application/json', () async {
    await dio.get<dynamic>('/thing');

    expect(sentHeaders()['Accept'], 'application/json');
  });

  test('adds a bearer token when one is stored', () async {
    await storage.saveTokens('tok-123', 'refresh-123');

    await dio.get<dynamic>('/thing');

    expect(sentHeaders()['Authorization'], 'Bearer tok-123');
  });

  test('sends no Authorization header when no token is stored', () async {
    await dio.get<dynamic>('/thing');

    expect(sentHeaders().containsKey('Authorization'), isFalse);
  });

  test('sends no Authorization header when the stored token is empty', () async {
    store[StorageKeys.accessToken] = '';

    await dio.get<dynamic>('/thing');

    expect(sentHeaders().containsKey('Authorization'), isFalse);
  });

  test('skips the Authorization header on an anonymous request even when a '
      'token is held', () async {
    await storage.saveTokens('tok-123');

    await dio.get<dynamic>(
      '/auth/citizen/login',
      options: Options(extra: <String, dynamic>{'anonymous': true}),
    );

    expect(sentHeaders().containsKey('Authorization'), isFalse);
    // Accept is still set — `anonymous` is about credentials, not content
    // negotiation.
    expect(sentHeaders()['Accept'], 'application/json');
  });

  test('reads the token fresh on every request, so a rotation is picked up',
      () async {
    await storage.saveTokens('first');
    await dio.get<dynamic>('/one');

    await storage.saveTokens('second');
    await dio.get<dynamic>('/two');

    expect(
      adapter.requests
          .map((RequestOptions r) => r.headers['Authorization'])
          .toList(),
      <String>['Bearer first', 'Bearer second'],
    );
  });
}

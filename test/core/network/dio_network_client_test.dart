/// `buildDio` / `debugInterceptors` — the Dio the app actually ships.
///
/// AC-10 hotspot 2 asks whether `ChuckerDioInterceptor` (which captures the
/// full request, `Authorization: Bearer …` header included) can reach a release
/// build. `debugInterceptors()` is the gate, so it is asserted here as well as
/// reviewed: under `kDebugMode` it must yield the interceptor, and its release
/// branch must yield nothing. A test binary always runs in debug, so only the
/// debug branch is executable here — the release branch is a `kDebugMode`
/// constant-folded `return const []`, and that limitation is recorded rather
/// than papered over.
library;

import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/network/auth_interceptor.dart';
import 'package:lcc_mobile_app/core/network/dio_network_client.dart';
import 'package:lcc_mobile_app/core/network/refresh_interceptor.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';

import '../../helpers/core_test_helper.dart';

void main() {
  late StorageService storage;

  setUp(() {
    storage = inMemoryStorageService(<String, String>{});
  });

  test('points at ApiEndpoint.baseUrl with JSON defaults and 10s timeouts', () {
    final Dio dio = buildDio(storage: storage);

    expect(dio.options.baseUrl, ApiEndpoint.baseUrl);
    expect(dio.options.contentType, 'application/json');
    expect(dio.options.connectTimeout, const Duration(seconds: 10));
    expect(dio.options.receiveTimeout, const Duration(seconds: 10));
  });

  // AC-20, structural half — architecture-review.md § 1.3 names this as the
  // trap the D-1 fix must not walk into. The tempting fix was a permissive
  // `validateStatus` here, which would make `_unwrap`'s non-2xx branch live by
  // stopping non-2xx from raising a `DioException` at all. `onError` is the
  // only door a 401 can reach `RefreshInterceptor` through, so that would kill
  // refresh outright — and the refresh tests would go green *because no refresh
  // happens*, which reads exactly like success. The behavioural half (a 401
  // really does still refresh and replay) is in `refresh_interceptor_test.dart`;
  // this pins the invariant at its source, in the composition root, where the
  // regression would actually be introduced.
  test('leaves validateStatus rejecting non-2xx, so a 401 still raises and '
      'still reaches RefreshInterceptor.onError', () {
    final Dio dio = buildDio(storage: storage);
    final bool Function(int?) accepts = dio.options.validateStatus;

    expect(accepts(200), isTrue);
    expect(accepts(299), isTrue);
    expect(accepts(401), isFalse,
        reason: 'a 401 that does not raise never reaches onError, and the '
            'whole 401 → refresh → replay path dies silently');
    expect(accepts(422), isFalse);
    expect(accepts(500), isFalse);
  });

  test('installs AuthInterceptor before RefreshInterceptor', () {
    final Dio dio = buildDio(storage: storage);

    expect(dio.interceptors.whereType<AuthInterceptor>(), hasLength(1));
    expect(dio.interceptors.whereType<RefreshInterceptor>(), hasLength(1));
    expect(
      dio.interceptors.indexOf(dio.interceptors.whereType<AuthInterceptor>().first),
      lessThan(dio.interceptors
          .indexOf(dio.interceptors.whereType<RefreshInterceptor>().first)),
      reason: 'the token must be attached before the 401 gate can replay it',
    );
  });

  test('appends extraInterceptors after the two built-ins', () {
    final Interceptor extra = InterceptorsWrapper();

    final Dio dio = buildDio(
      storage: storage,
      extraInterceptors: <Interceptor>[extra],
    );

    expect(dio.interceptors.last, same(extra));
  });

  test('installs no extra interceptors by default', () {
    final Dio dio = buildDio(storage: storage);

    // Dio ships one built-in (ImplyContentTypeInterceptor) ahead of ours.
    expect(dio.interceptors.whereType<ChuckerDioInterceptor>(), isEmpty);
  });

  test('debugInterceptors yields Chucker in a debug build only', () {
    final List<Interceptor> interceptors = debugInterceptors();

    if (kDebugMode) {
      expect(interceptors.whereType<ChuckerDioInterceptor>(), hasLength(1));
    } else {
      expect(interceptors, isEmpty);
    }
  });
}

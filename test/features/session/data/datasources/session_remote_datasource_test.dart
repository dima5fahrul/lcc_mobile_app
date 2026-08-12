/// `SessionRemoteDatasourceImpl` — the session feature's HTTP boundary.
///
/// Named by plan § Testing and GOR-245 § 3.1. `ApiClient` is mocked here (not
/// stubbed at the transport): the datasource's job is *which endpoint, which
/// body, which anonymity flag, which model*, and a mock is the only double
/// that can assert the anonymity flag was passed rather than defaulted.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/features/session/data/datasources/session_remote_datasource.dart';
import 'package:lcc_mobile_app/features/session/data/models/auth_tokens_model.dart';
import 'package:lcc_mobile_app/features/session/data/models/citizen_profile_model.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/auth_mock_data.dart';
import '../../../../helpers/auth_test_helper.dart';
import '../../../../helpers/session_test_helper.dart';

void main() {
  late MockApiClient apiClient;
  late SessionRemoteDatasourceImpl datasource;

  setUp(() {
    apiClient = MockApiClient();
    datasource = SessionRemoteDatasourceImpl(apiClient: apiClient);
  });

  group('getProfile', () {
    test('GETs /me/profile and parses the profile model', () async {
      when(() => apiClient.get<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => tCitizenProfileJson());

      final CitizenProfileModel model = await datasource.getProfile();

      verify(() => apiClient.get<Map<String, dynamic>>(ApiEndpoint.meProfile))
          .called(1);
      expect(model.account.id, 'citizen-123');
      expect(model.householdNo, 'H001');
      expect(model.place?.province?.lo, 'ວຽງຈັນ');
      expect(model.registry, <String, dynamic>{'status': 'active'});
    });

    test('parses a profile with no place block', () async {
      when(() => apiClient.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => tCitizenProfileJson(withPlace: false),
      );

      final CitizenProfileModel model = await datasource.getProfile();

      expect(model.place, isNull);
    });

    test('propagates ApiException from the client', () async {
      when(() => apiClient.get<Map<String, dynamic>>(any())).thenThrow(
        const ApiException(status: 401, code: 'UNAUTHORIZED', message: 'nope'),
      );

      await expectLater(datasource.getProfile(), throwsA(isA<ApiException>()));
    });
  });

  group('logout', () {
    test('POSTs the refresh token to /auth/logout as an authenticated call',
        () async {
      when(() => apiClient.post<void>(any(), body: any(named: 'body')))
          .thenAnswer((_) async {});

      await datasource.logout('refresh-abc');

      verify(
        () => apiClient.post<void>(
          ApiEndpoint.authLogout,
          body: <String, dynamic>{'refresh_token': 'refresh-abc'},
        ),
      ).called(1);
    });

    test('propagates a failure from the client', () async {
      when(() => apiClient.post<void>(any(), body: any(named: 'body')))
          .thenThrow(
        const ApiException(status: 500, code: 'INTERNAL_ERROR', message: 'x'),
      );

      await expectLater(
        datasource.logout('refresh-abc'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('refreshTokens', () {
    test('POSTs anonymously to /auth/refresh and parses the token pair',
        () async {
      when(
        () => apiClient.post<Map<String, dynamic>>(
          any(),
          body: any(named: 'body'),
          anonymous: any(named: 'anonymous'),
        ),
      ).thenAnswer((_) async => tAuthTokensJson);

      final AuthTokensModel tokens =
          await datasource.refreshTokens('refresh-abc');

      verify(
        () => apiClient.post<Map<String, dynamic>>(
          ApiEndpoint.authRefresh,
          body: <String, dynamic>{'refresh_token': 'refresh-abc'},
          anonymous: true,
        ),
      ).called(1);
      expect(tokens.accessToken, 'access-abc');
      expect(tokens.refreshToken, 'refresh-abc');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/auth_mock_data.dart';
import '../../../../helpers/auth_test_helper.dart';

void main() {
  late AuthRemoteDatasourceImpl datasource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    datasource = AuthRemoteDatasourceImpl(apiClient: mockApiClient);
  });

  void stubPost(Map<String, dynamic> response) {
    when(() => mockApiClient.post<Map<String, dynamic>>(
          any(),
          body: any(named: 'body'),
          anonymous: any(named: 'anonymous'),
        )).thenAnswer((_) async => response);
  }

  group('register', () {
    test('returns RegisterResultModel on success', () async {
      stubPost(tRegisterResultJson());

      final result = await datasource.register(
        phone: '+8562012345',
        name: 'Test Citizen',
        password: 'password123',
        email: 'test@example.com',
      );

      expect(result.citizenId, 'citizen-123');
      expect(result.challenge.phone, '+8562012345');
      expect(result.challenge.purpose, 'register');
      expect(result.challenge.devCode, '123456');
    });

    test('propagates ApiException from ApiClient', () async {
      final exception = ApiException(
        status: 422,
        code: 'VALIDATION_ERROR',
        message: 'Phone already registered',
      );
      when(() => mockApiClient.post<Map<String, dynamic>>(
            any(),
            body: any(named: 'body'),
            anonymous: any(named: 'anonymous'),
          )).thenThrow(exception);

      expect(
        () => datasource.register(
          phone: '+8562012345',
          name: 'Test',
          password: 'password123',
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('hits authRegister endpoint with anonymous:true', () async {
      String? capturedPath;
      bool? capturedAnonymous;

      when(() => mockApiClient.post<Map<String, dynamic>>(
            any(),
            body: any(named: 'body'),
            anonymous: any(named: 'anonymous'),
          )).thenAnswer((invocation) async {
        capturedPath = invocation.positionalArguments.first as String;
        capturedAnonymous =
            invocation.namedArguments[#anonymous] as bool;
        return tRegisterResultJson();
      });

      await datasource.register(
        phone: '+8562012345',
        name: 'Test',
        password: 'password123',
      );

      expect(capturedPath, ApiEndpoint.authRegister);
      expect(capturedAnonymous, true);
    });
  });

  group('requestOtp', () {
    test('returns OtpChallengeModel on success', () async {
      stubPost(tOtpChallengeJson(purpose: 'login'));

      final result = await datasource.requestOtp(
        phone: '+8562012345',
        purpose: 'login',
      );

      expect(result.phone, '+8562012345');
      expect(result.purpose, 'login');
      expect(result.expiresIn, 300);
    });
  });

  group('verifyOtp', () {
    test('returns CitizenSessionModel on success', () async {
      stubPost(tCitizenSessionJson());

      final result = await datasource.verifyOtp(
        phone: '+8562012345',
        code: '123456',
        purpose: 'login',
      );

      expect(result.actor, 'citizen');
      expect(result.citizen.phone, '+8562012345');
      expect(result.tokens.accessToken, 'access-abc');
    });
  });

  group('login', () {
    test('returns CitizenSessionModel on success', () async {
      stubPost(tCitizenSessionJson());

      final result = await datasource.login(
        phone: '+8562012345',
        password: 'password123',
      );

      expect(result.actor, 'citizen');
      expect(result.citizen.id, 'citizen-123');
      expect(result.tokens.accessToken, 'access-abc');
    });
  });

  group('forgotPassword', () {
    test('returns OtpChallengeModel on success', () async {
      stubPost(tOtpChallengeJson(purpose: 'forgot'));

      final result = await datasource.forgotPassword(phone: '+8562012345');

      expect(result.phone, '+8562012345');
      expect(result.purpose, 'forgot');
    });
  });

  group('resetPassword', () {
    test('returns true when server answers {reset: true}', () async {
      stubPost({'reset': true});

      final result = await datasource.resetPassword(
        phone: '+8562012345',
        code: '123456',
        newPassword: 'newpass123',
      );

      expect(result, true);
    });

    test('defaults to true when reset field is absent', () async {
      stubPost({});

      final result = await datasource.resetPassword(
        phone: '+8562012345',
        code: '123456',
        newPassword: 'newpass123',
      );

      expect(result, true);
    });

    test('returns false when server answers {reset: false}', () async {
      stubPost({'reset': false});

      final result = await datasource.resetPassword(
        phone: '+8562012345',
        code: '123456',
        newPassword: 'newpass123',
      );

      expect(result, false);
    });
  });
}

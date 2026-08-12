import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/features/auth/data/models/citizen_session_model.dart';
import 'package:lcc_mobile_app/features/auth/data/models/otp_challenge_model.dart';
import 'package:lcc_mobile_app/features/auth/data/models/register_result_model.dart';
import 'package:lcc_mobile_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lcc_mobile_app/features/auth/domain/entities/register_result.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/citizen_session.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/otp_challenge.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/auth_mock_data.dart';
import '../../../../helpers/auth_test_helper.dart';

void main() {
  late MockAuthRemoteDatasource mockRemote;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockRemote = MockAuthRemoteDatasource();
    repository = AuthRepositoryImpl(remote: mockRemote);
  });

  group('register', () {
    test('returns Right(RegisterResult) on success', () async {
      final model = RegisterResultModel.fromJson(tRegisterResultJson());
      when(() => mockRemote.register(
            phone: any(named: 'phone'),
            name: any(named: 'name'),
            password: any(named: 'password'),
            email: any(named: 'email'),
          )).thenAnswer((_) async => model);

      final result = await repository.register(
        phone: '+8562012345',
        name: 'Test',
        password: 'password123',
      );

      expect(result, isA<Right<Failure, RegisterResult>>());
      result.fold((l) => fail('should be Right'), (r) {
        expect(r.citizenId, 'citizen-123');
        expect(r.challenge.phone, '+8562012345');
      });
    });

    test('rethrows ApiException (preserves per-field map)', () async {
      final exception = fakeValidationApiException();
      when(() => mockRemote.register(
            phone: any(named: 'phone'),
            name: any(named: 'name'),
            password: any(named: 'password'),
            email: any(named: 'email'),
          )).thenThrow(exception);

      expect(
        () => repository.register(
          phone: '+8562012345',
          name: 'Test',
          password: 'password123',
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('returns Left(Failure) on generic exception', () async {
      when(() => mockRemote.register(
            phone: any(named: 'phone'),
            name: any(named: 'name'),
            password: any(named: 'password'),
            email: any(named: 'email'),
          )).thenThrow(Exception('boom'));

      final result = await repository.register(
        phone: '+8562012345',
        name: 'Test',
        password: 'password123',
      );

      expect(result, isA<Left<Failure, RegisterResult>>());
      result.fold((l) => expect(l, isA<Failure>()), (_) => fail('should be Left'));
    });
  });

  group('requestOtp', () {
    test('returns Right(OTPChallenge) on success', () async {
      final model = OtpChallengeModel.fromJson(tOtpChallengeJson());
      when(() => mockRemote.requestOtp(
            phone: any(named: 'phone'),
            purpose: any(named: 'purpose'),
          )).thenAnswer((_) async => model);

      final result = await repository.requestOtp(
        phone: '+8562012345',
        purpose: 'login',
      );

      expect(result, isA<Right<Failure, OTPChallenge>>());
      result.fold((l) => fail('should be Right'), (r) {
        expect(r.phone, '+8562012345');
        expect(r.purpose, 'login');
      });
    });
  });

  group('verifyOtp', () {
    test('returns Right(CitizenSession) on success', () async {
      final model = CitizenSessionModel.fromJson(tCitizenSessionJson());
      when(() => mockRemote.verifyOtp(
            phone: any(named: 'phone'),
            code: any(named: 'code'),
            purpose: any(named: 'purpose'),
          )).thenAnswer((_) async => model);

      final result = await repository.verifyOtp(
        phone: '+8562012345',
        code: '123456',
        purpose: 'login',
      );

      expect(result, isA<Right<Failure, CitizenSession>>());
      result.fold((l) => fail('should be Right'), (r) {
        expect(r.actor, 'citizen');
        expect(r.citizen.id, 'citizen-123');
      });
    });
  });

  group('login', () {
    test('returns Right(CitizenSession) on success', () async {
      final model = CitizenSessionModel.fromJson(tCitizenSessionJson());
      when(() => mockRemote.login(
            phone: any(named: 'phone'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => model);

      final result = await repository.login(
        phone: '+8562012345',
        password: 'password123',
      );

      expect(result, isA<Right<Failure, CitizenSession>>());
      result.fold((l) => fail('should be Right'), (r) {
        expect(r.citizen.id, 'citizen-123');
      });
    });
  });

  group('forgotPassword', () {
    test('returns Right(OTPChallenge) on success', () async {
      final model = OtpChallengeModel.fromJson(tOtpChallengeJson(purpose: 'forgot'));
      when(() => mockRemote.forgotPassword(phone: any(named: 'phone')))
          .thenAnswer((_) async => model);

      final result = await repository.forgotPassword(phone: '+8562012345');

      expect(result, isA<Right<Failure, OTPChallenge>>());
      result.fold((l) => fail('should be Right'), (r) {
        expect(r.purpose, 'forgot');
      });
    });
  });

  group('resetPassword', () {
    test('returns Right(true) on success', () async {
      when(() => mockRemote.resetPassword(
            phone: any(named: 'phone'),
            code: any(named: 'code'),
            newPassword: any(named: 'newPassword'),
          )).thenAnswer((_) async => true);

      final result = await repository.resetPassword(
        phone: '+8562012345',
        code: '123456',
        newPassword: 'newpass123',
      );

      expect(result, const Right<Failure, bool>(true));
    });

    test('returns Right(false) when server says no', () async {
      when(() => mockRemote.resetPassword(
            phone: any(named: 'phone'),
            code: any(named: 'code'),
            newPassword: any(named: 'newPassword'),
          )).thenAnswer((_) async => false);

      final result = await repository.resetPassword(
        phone: '+8562012345',
        code: '123456',
        newPassword: 'newpass123',
      );

      expect(result, const Right<Failure, bool>(false));
    });
  });

  // ── GOR-245 additions ─────────────────────────────────────────────────────
  //
  // Only `register` had its error branches covered. The rethrow-vs-wrap split
  // is a per-method contract, not a class-wide one — `ApiException` is
  // rethrown so `AuthBloc` can read `fieldMap()` and highlight the offending
  // field, everything else becomes `Left(Failure)`. Five methods were taking
  // that contract on trust.

  group('error contract — ApiException is rethrown, anything else is wrapped',
      () {
    final exception = fakeValidationApiException();

    test('requestOtp rethrows ApiException', () async {
      when(() => mockRemote.requestOtp(
            phone: any(named: 'phone'),
            purpose: any(named: 'purpose'),
          )).thenThrow(exception);

      expect(
        () => repository.requestOtp(phone: '+8562012345', purpose: 'login'),
        throwsA(isA<ApiException>()),
      );
    });

    test('requestOtp wraps any other exception', () async {
      when(() => mockRemote.requestOtp(
            phone: any(named: 'phone'),
            purpose: any(named: 'purpose'),
          )).thenThrow(const FormatException('bad json'));

      final result =
          await repository.requestOtp(phone: '+8562012345', purpose: 'login');

      expect(result.isLeft(), isTrue);
    });

    test('verifyOtp rethrows ApiException', () async {
      when(() => mockRemote.verifyOtp(
            phone: any(named: 'phone'),
            code: any(named: 'code'),
            purpose: any(named: 'purpose'),
          )).thenThrow(exception);

      expect(
        () => repository.verifyOtp(
          phone: '+8562012345',
          code: '123456',
          purpose: 'login',
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('verifyOtp wraps any other exception', () async {
      when(() => mockRemote.verifyOtp(
            phone: any(named: 'phone'),
            code: any(named: 'code'),
            purpose: any(named: 'purpose'),
          )).thenThrow(const FormatException('bad json'));

      final result = await repository.verifyOtp(
        phone: '+8562012345',
        code: '123456',
        purpose: 'login',
      );

      expect(result.isLeft(), isTrue);
    });

    test('login rethrows ApiException', () async {
      when(() => mockRemote.login(
            phone: any(named: 'phone'),
            password: any(named: 'password'),
          )).thenThrow(exception);

      expect(
        () => repository.login(phone: '+8562012345', password: 'x'),
        throwsA(isA<ApiException>()),
      );
    });

    test('login wraps any other exception', () async {
      when(() => mockRemote.login(
            phone: any(named: 'phone'),
            password: any(named: 'password'),
          )).thenThrow(const FormatException('bad json'));

      final result =
          await repository.login(phone: '+8562012345', password: 'x');

      expect(result.isLeft(), isTrue);
    });

    test('forgotPassword rethrows ApiException', () async {
      when(() => mockRemote.forgotPassword(phone: any(named: 'phone')))
          .thenThrow(exception);

      expect(
        () => repository.forgotPassword(phone: '+8562012345'),
        throwsA(isA<ApiException>()),
      );
    });

    test('forgotPassword wraps any other exception', () async {
      when(() => mockRemote.forgotPassword(phone: any(named: 'phone')))
          .thenThrow(const FormatException('bad json'));

      final result = await repository.forgotPassword(phone: '+8562012345');

      expect(result.isLeft(), isTrue);
    });

    test('resetPassword rethrows ApiException', () async {
      when(() => mockRemote.resetPassword(
            phone: any(named: 'phone'),
            code: any(named: 'code'),
            newPassword: any(named: 'newPassword'),
          )).thenThrow(exception);

      expect(
        () => repository.resetPassword(
          phone: '+8562012345',
          code: '123456',
          newPassword: 'newpass123',
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('resetPassword wraps any other exception', () async {
      when(() => mockRemote.resetPassword(
            phone: any(named: 'phone'),
            code: any(named: 'code'),
            newPassword: any(named: 'newPassword'),
          )).thenThrow(const FormatException('bad json'));

      final result = await repository.resetPassword(
        phone: '+8562012345',
        code: '123456',
        newPassword: 'newpass123',
      );

      expect(result.isLeft(), isTrue);
    });

    test('register passes the optional email straight through', () async {
      final model = RegisterResultModel.fromJson(tRegisterResultJson());
      when(() => mockRemote.register(
            phone: any(named: 'phone'),
            name: any(named: 'name'),
            password: any(named: 'password'),
            email: any(named: 'email'),
          )).thenAnswer((_) async => model);

      await repository.register(
        phone: '+8562012345',
        name: 'Test',
        password: 'password123',
        email: 'test@example.com',
      );

      verify(() => mockRemote.register(
            phone: '+8562012345',
            name: 'Test',
            password: 'password123',
            email: 'test@example.com',
          )).called(1);
    });
  });
}

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/auth/data/models/citizen_session_model.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/verify_otp.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/citizen_session.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/auth_mock_data.dart';
import '../../../../helpers/auth_test_helper.dart';

void main() {
  late MockAuthRepository mockRepository;
  late VerifyOtp usecase;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = VerifyOtp(repository: mockRepository);
  });

  test('calls repository.verifyOtp and returns Right on success', () async {
    final session = CitizenSessionModel.fromJson(tCitizenSessionJson()).toEntity();
    when(() => mockRepository.verifyOtp(
          phone: any(named: 'phone'),
          code: any(named: 'code'),
          purpose: any(named: 'purpose'),
        )).thenAnswer((_) async => Right(session));

    final result = await usecase(
      const VerifyOtpParams(phone: '+8562012345', code: '123456', purpose: 'login'),
    );

    expect(result, isA<Right<Failure, CitizenSession>>());
    result.fold((l) => fail('should be Right'), (r) {
      expect(r.citizen.id, 'citizen-123');
    });
    verify(() => mockRepository.verifyOtp(
          phone: '+8562012345',
          code: '123456',
          purpose: 'login',
        )).called(1);
  });

  test('returns Left(Failure) when repository fails', () async {
    when(() => mockRepository.verifyOtp(
          phone: any(named: 'phone'),
          code: any(named: 'code'),
          purpose: any(named: 'purpose'),
        )).thenAnswer((_) async => Left(Failure('invalid code')));

    final result = await usecase(
      const VerifyOtpParams(phone: '+8562012345', code: '000000', purpose: 'login'),
    );

    expect(result, isA<Left<Failure, CitizenSession>>());
    result.fold((l) => expect(l.message, 'invalid code'), (_) => fail('should be Left'));
  });
}

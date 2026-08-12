import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/auth/data/models/otp_challenge_model.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/request_otp.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/otp_challenge.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/auth_mock_data.dart';
import '../../../../helpers/auth_test_helper.dart';

void main() {
  late MockAuthRepository mockRepository;
  late RequestOtp usecase;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = RequestOtp(repository: mockRepository);
  });

  test('calls repository.requestOtp and returns Right on success', () async {
    final challenge = OtpChallengeModel.fromJson(tOtpChallengeJson()).toEntity();
    when(() => mockRepository.requestOtp(
          phone: any(named: 'phone'),
          purpose: any(named: 'purpose'),
        )).thenAnswer((_) async => Right(challenge));

    final result = await usecase(
      const RequestOtpParams(phone: '+8562012345', purpose: 'login'),
    );

    expect(result, isA<Right<Failure, OTPChallenge>>());
    result.fold((l) => fail('should be Right'), (r) {
      expect(r.phone, '+8562012345');
    });
    verify(() => mockRepository.requestOtp(
          phone: '+8562012345',
          purpose: 'login',
        )).called(1);
  });

  test('returns Left(Failure) when repository fails', () async {
    when(() => mockRepository.requestOtp(
          phone: any(named: 'phone'),
          purpose: any(named: 'purpose'),
        )).thenAnswer((_) async => Left(Failure('rate limited')));

    final result = await usecase(
      const RequestOtpParams(phone: '+8562012345', purpose: 'login'),
    );

    expect(result, isA<Left<Failure, OTPChallenge>>());
    result.fold((l) => expect(l.message, 'rate limited'), (_) => fail('should be Left'));
  });
}

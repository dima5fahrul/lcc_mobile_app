import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/auth/data/models/otp_challenge_model.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/forgot_password.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/otp_challenge.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/auth_mock_data.dart';
import '../../../../helpers/auth_test_helper.dart';

void main() {
  late MockAuthRepository mockRepository;
  late ForgotPassword usecase;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = ForgotPassword(repository: mockRepository);
  });

  test('calls repository.forgotPassword and returns Right on success', () async {
    final challenge = OtpChallengeModel.fromJson(tOtpChallengeJson(purpose: 'forgot')).toEntity();
    when(() => mockRepository.forgotPassword(phone: any(named: 'phone')))
        .thenAnswer((_) async => Right(challenge));

    final result = await usecase(
      const ForgotPasswordParams(phone: '+8562012345'),
    );

    expect(result, isA<Right<Failure, OTPChallenge>>());
    result.fold((l) => fail('should be Right'), (r) {
      expect(r.purpose, 'forgot');
    });
    verify(() => mockRepository.forgotPassword(phone: '+8562012345')).called(1);
  });

  test('returns Left(Failure) when repository fails', () async {
    when(() => mockRepository.forgotPassword(phone: any(named: 'phone')))
        .thenAnswer((_) async => Left(Failure('not found')));

    final result = await usecase(
      const ForgotPasswordParams(phone: '+8562012345'),
    );

    expect(result, isA<Left<Failure, OTPChallenge>>());
    result.fold((l) => expect(l.message, 'not found'), (_) => fail('should be Left'));
  });
}

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/reset_password.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/auth_test_helper.dart';

void main() {
  late MockAuthRepository mockRepository;
  late ResetPassword usecase;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = ResetPassword(repository: mockRepository);
  });

  test('calls repository.resetPassword and returns Right(true) on success', () async {
    when(() => mockRepository.resetPassword(
          phone: any(named: 'phone'),
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer((_) async => const Right(true));

    final result = await usecase(
      const ResetPasswordParams(
        phone: '+8562012345',
        code: '123456',
        newPassword: 'newpass123',
      ),
    );

    expect(result, const Right<Failure, bool>(true));
    verify(() => mockRepository.resetPassword(
          phone: '+8562012345',
          code: '123456',
          newPassword: 'newpass123',
        )).called(1);
  });

  test('returns Left(Failure) when repository fails', () async {
    when(() => mockRepository.resetPassword(
          phone: any(named: 'phone'),
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer((_) async => Left(Failure('expired')));

    final result = await usecase(
      const ResetPasswordParams(
        phone: '+8562012345',
        code: '000000',
        newPassword: 'newpass123',
      ),
    );

    expect(result, isA<Left<Failure, bool>>());
    result.fold((l) => expect(l.message, 'expired'), (_) => fail('should be Left'));
  });
}

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/auth/data/models/register_result_model.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/register.dart';
import 'package:lcc_mobile_app/features/auth/domain/entities/register_result.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/auth_mock_data.dart';
import '../../../../helpers/auth_test_helper.dart';

void main() {
  late MockAuthRepository mockRepository;
  late Register usecase;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = Register(repository: mockRepository);
  });

  test('calls repository.register and returns Right on success', () async {
    final registerResult = RegisterResultModel.fromJson(tRegisterResultJson()).toEntity();
    when(() => mockRepository.register(
          phone: any(named: 'phone'),
          name: any(named: 'name'),
          password: any(named: 'password'),
          email: any(named: 'email'),
        )).thenAnswer((_) async => Right(registerResult));

    final result = await usecase(
      const RegisterParams(
        phone: '+8562012345',
        name: 'Test',
        password: 'password123',
      ),
    );

    expect(result, isA<Right<Failure, RegisterResult>>());
    result.fold((l) => fail('should be Right'), (r) {
      expect(r.citizenId, 'citizen-123');
    });
    verify(() => mockRepository.register(
          phone: '+8562012345',
          name: 'Test',
          password: 'password123',
        )).called(1);
  });

  test('passes optional email when provided', () async {
    final registerResult = RegisterResultModel.fromJson(tRegisterResultJson()).toEntity();
    when(() => mockRepository.register(
          phone: any(named: 'phone'),
          name: any(named: 'name'),
          password: any(named: 'password'),
          email: any(named: 'email'),
        )).thenAnswer((_) async => Right(registerResult));

    await usecase(
      const RegisterParams(
        phone: '+8562012345',
        name: 'Test',
        password: 'password123',
        email: 'test@example.com',
      ),
    );

    verify(() => mockRepository.register(
          phone: '+8562012345',
          name: 'Test',
          password: 'password123',
          email: 'test@example.com',
        )).called(1);
  });

  test('returns Left(Failure) when repository fails', () async {
    when(() => mockRepository.register(
          phone: any(named: 'phone'),
          name: any(named: 'name'),
          password: any(named: 'password'),
          email: any(named: 'email'),
        )).thenAnswer((_) async => Left(Failure('exists')));

    final result = await usecase(
      const RegisterParams(
        phone: '+8562012345',
        name: 'Test',
        password: 'password123',
      ),
    );

    expect(result, isA<Left<Failure, RegisterResult>>());
    result.fold((l) => expect(l.message, 'exists'), (_) => fail('should be Left'));
  });
}

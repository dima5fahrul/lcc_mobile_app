import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/auth/data/models/citizen_session_model.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/login.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/citizen_session.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/auth_mock_data.dart';
import '../../../../helpers/auth_test_helper.dart';

void main() {
  late MockAuthRepository mockRepository;
  late Login usecase;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = Login(repository: mockRepository);
  });

  test('calls repository.login and returns Right on success', () async {
    final session = CitizenSessionModel.fromJson(tCitizenSessionJson()).toEntity();
    when(() => mockRepository.login(
          phone: any(named: 'phone'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => Right(session));

    final result = await usecase(
      const LoginParams(phone: '+8562012345', password: 'password123'),
    );

    expect(result, isA<Right<Failure, CitizenSession>>());
    result.fold((l) => fail('should be Right'), (r) {
      expect(r.citizen.id, 'citizen-123');
    });
    verify(() => mockRepository.login(
          phone: '+8562012345',
          password: 'password123',
        )).called(1);
  });

  test('returns Left(Failure) when repository fails', () async {
    when(() => mockRepository.login(
          phone: any(named: 'phone'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => Left(Failure('network error')));

    final result = await usecase(
      const LoginParams(phone: '+8562012345', password: 'password123'),
    );

    expect(result, isA<Left<Failure, CitizenSession>>());
    result.fold((l) => expect(l.message, 'network error'), (_) => fail('should be Left'));
  });
}

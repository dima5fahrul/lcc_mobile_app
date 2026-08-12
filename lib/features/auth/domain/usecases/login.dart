/// `Login` usecase — thin wrapper over [AuthRepository.login].
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../session/domain/entities/citizen_session.dart';
import '../repositories/auth_repository.dart';

class LoginParams extends Equatable {
  const LoginParams({required this.phone, required this.password});

  final String phone;
  final String password;

  @override
  List<Object?> get props => [phone, password];
}

class Login implements UseCase<CitizenSession, LoginParams> {
  const Login({required this.repository});

  final AuthRepository repository;

  @override
  Future<Either<Failure, CitizenSession>> call(LoginParams params) =>
      repository.login(phone: params.phone, password: params.password);
}

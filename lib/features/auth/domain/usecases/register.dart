/// `Register` usecase — thin wrapper over [AuthRepository.register].
///
/// Follows the flutter-boilerplate `GetPopularMovies` pattern: a const
/// constructor that takes the repository, a single `call(Params)` method that
/// delegates straight to the repo. The [RegisterParams] carry the form's
/// validated fields so the BLoC does not construct a map.
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/register_result.dart';
import '../repositories/auth_repository.dart';

class RegisterParams extends Equatable {
  const RegisterParams({
    required this.phone,
    required this.name,
    required this.password,
    this.email,
  });

  final String phone;
  final String name;
  final String password;
  final String? email;

  @override
  List<Object?> get props => [phone, name, password, email];
}

class Register implements UseCase<RegisterResult, RegisterParams> {
  const Register({required this.repository});

  final AuthRepository repository;

  @override
  Future<Either<Failure, RegisterResult>> call(RegisterParams params) =>
      repository.register(
        phone: params.phone,
        name: params.name,
        password: params.password,
        email: params.email,
      );
}

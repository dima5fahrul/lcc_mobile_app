/// `ResetPassword` usecase — thin wrapper over [AuthRepository.resetPassword].
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordParams extends Equatable {
  const ResetPasswordParams({
    required this.phone,
    required this.code,
    required this.newPassword,
  });

  final String phone;
  final String code;
  final String newPassword;

  @override
  List<Object?> get props => [phone, code, newPassword];
}

class ResetPassword implements UseCase<bool, ResetPasswordParams> {
  const ResetPassword({required this.repository});

  final AuthRepository repository;

  @override
  Future<Either<Failure, bool>> call(ResetPasswordParams params) =>
      repository.resetPassword(
        phone: params.phone,
        code: params.code,
        newPassword: params.newPassword,
      );
}

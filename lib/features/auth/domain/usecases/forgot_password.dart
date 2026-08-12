/// `ForgotPassword` usecase — thin wrapper over [AuthRepository.forgotPassword].
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../session/domain/entities/otp_challenge.dart';
import '../repositories/auth_repository.dart';

class ForgotPasswordParams extends Equatable {
  const ForgotPasswordParams({required this.phone});

  final String phone;

  @override
  List<Object?> get props => [phone];
}

class ForgotPassword implements UseCase<OTPChallenge, ForgotPasswordParams> {
  const ForgotPassword({required this.repository});

  final AuthRepository repository;

  @override
  Future<Either<Failure, OTPChallenge>> call(ForgotPasswordParams params) =>
      repository.forgotPassword(phone: params.phone);
}

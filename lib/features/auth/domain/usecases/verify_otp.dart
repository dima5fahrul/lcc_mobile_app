/// `VerifyOtp` usecase — thin wrapper over [AuthRepository.verifyOtp].
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../session/domain/entities/citizen_session.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpParams extends Equatable {
  const VerifyOtpParams({
    required this.phone,
    required this.code,
    required this.purpose,
  });

  final String phone;
  final String code;
  final String purpose;

  @override
  List<Object?> get props => [phone, code, purpose];
}

class VerifyOtp implements UseCase<CitizenSession, VerifyOtpParams> {
  const VerifyOtp({required this.repository});

  final AuthRepository repository;

  @override
  Future<Either<Failure, CitizenSession>> call(VerifyOtpParams params) =>
      repository.verifyOtp(
        phone: params.phone,
        code: params.code,
        purpose: params.purpose,
      );
}

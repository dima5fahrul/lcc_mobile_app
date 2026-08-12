/// `RequestOtp` usecase — thin wrapper over [AuthRepository.requestOtp].
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../session/domain/entities/otp_challenge.dart';
import '../repositories/auth_repository.dart';

class RequestOtpParams extends Equatable {
  const RequestOtpParams({required this.phone, required this.purpose});

  final String phone;
  final String purpose;

  @override
  List<Object?> get props => [phone, purpose];
}

class RequestOtp implements UseCase<OTPChallenge, RequestOtpParams> {
  const RequestOtp({required this.repository});

  final AuthRepository repository;

  @override
  Future<Either<Failure, OTPChallenge>> call(RequestOtpParams params) =>
      repository.requestOtp(phone: params.phone, purpose: params.purpose);
}

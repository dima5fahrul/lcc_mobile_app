/// `AuthRepository` — the auth feature's domain contract.
///
/// Ported from `lcc-app/src/app/api/endpoints.ts` (`auth` object). The UI/BLoC
/// depends on this abstract; the data layer's [AuthRepositoryImpl] is the
/// only concrete implementation.
///
/// Every method returns `Future<Either<Failure, T>>` so the BLoC can fold over
/// the result and surface a typed error to the form. The six methods mirror
/// the six anonymous auth endpoints the citizen portal exposes.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../session/domain/entities/citizen_session.dart';
import '../../../session/domain/entities/otp_challenge.dart';
import '../entities/register_result.dart';

abstract class AuthRepository {
  /// `POST /auth/citizen/register` — create an account and issue a verify OTP.
  Future<Either<Failure, RegisterResult>> register({
    required String phone,
    required String name,
    required String password,
    String? email,
  });

  /// `POST /auth/citizen/request-otp` — request an OTP for a phone/purpose.
  Future<Either<Failure, OTPChallenge>> requestOtp({
    required String phone,
    required String purpose,
  });

  /// `POST /auth/citizen/verify-otp` — verify an OTP, returning a session.
  Future<Either<Failure, CitizenSession>> verifyOtp({
    required String phone,
    required String code,
    required String purpose,
  });

  /// `POST /auth/citizen/login` — phone + password login, returning a session.
  Future<Either<Failure, CitizenSession>> login({
    required String phone,
    required String password,
  });

  /// `POST /auth/citizen/forgot-password` — issue a reset OTP.
  Future<Either<Failure, OTPChallenge>> forgotPassword({required String phone});

  /// `POST /auth/citizen/reset-password` — spend a reset OTP on a new password.
  Future<Either<Failure, bool>> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  });
}

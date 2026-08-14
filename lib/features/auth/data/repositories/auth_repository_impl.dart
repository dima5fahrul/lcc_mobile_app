/// `AuthRepositoryImpl` — the auth feature's only repository impl.
///
/// Follows the flutter-boilerplate `MovieRepositoryImpl` pattern (try the
/// remote datasource, on exception return `Left(Failure(e.toString()))`,
/// on success return `Right(entity)`). `ApiException` is caught and wrapped
/// into `Left(Failure(...))` — unlike the session feature, the auth BLoC
/// reads `ApiException.fieldMap()` from the caught exception directly via
/// the datasource's rethrown `ApiException`, so the repository rethrows it
/// to preserve the per-field validation signal the register form needs.
///
/// Rationale: register's 422 response names every offending field, and the
/// form highlights them where the citizen typed. Wrapping `ApiException`
/// into a plain `Failure(message)` would lose that per-field map. The BLoC
/// catches `ApiException` and reads `fieldMap()`; other exceptions are
/// wrapped as `Failure` per the boilerplate pattern.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/register_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../session/domain/entities/citizen_session.dart';
import '../../../session/domain/entities/otp_challenge.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/citizen_session_model.dart';
import '../models/otp_challenge_model.dart';
import '../models/register_result_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required this.remote});

  final AuthRemoteDatasource remote;

  @override
  Future<Either<Failure, RegisterResult>> register({
    required String phone,
    required String name,
    required String password,
    String? email,
  }) async {
    try {
      final model = await remote.register(
        phone: phone,
        name: name,
        password: password,
        email: email,
      );
      return Right(model.toEntity());
    } on ApiException {
      rethrow;
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OTPChallenge>> requestOtp({
    required String phone,
    required String purpose,
  }) async {
    try {
      final model = await remote.requestOtp(phone: phone, purpose: purpose);
      return Right(model.toEntity());
    } on ApiException {
      rethrow;
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CitizenSession>> verifyOtp({
    required String phone,
    required String code,
    required String purpose,
  }) async {
    try {
      final model = await remote.verifyOtp(
        phone: phone,
        code: code,
        purpose: purpose,
      );
      return Right(model.toEntity());
    } on ApiException {
      rethrow;
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CitizenSession>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final model = await remote.login(phone: phone, password: password);
      return Right(model.toEntity());
    } on ApiException {
      rethrow;
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OTPChallenge>> forgotPassword({
    required String phone,
  }) async {
    try {
      final model = await remote.forgotPassword(phone: phone);
      return Right(model.toEntity());
    } on ApiException {
      rethrow;
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    try {
      final ok = await remote.resetPassword(
        phone: phone,
        code: code,
        newPassword: newPassword,
      );
      return Right(ok);
    } on ApiException {
      rethrow;
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await remote.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      // **No `on ApiException { rethrow; }` here, unlike every other method on
      // this repository, and the asymmetry is a port decision.**
      //
      // The rethrow exists so the register/login forms can read
      // `ApiException.fieldMap()` for a 422. `handleChangePassword`
      // (`AccountPage.tsx:283-285`) does no such thing: it catches everything
      // and renders `(err as Error).message` into one `pwError` slot. There is
      // no per-field surface on this form to feed, so a typed rethrow would
      // hand `AccountProfileBloc` a signal it must then discard — and force
      // `features/account/presentation/` to catch `ApiException`, which is
      // `core/network/`'s type and not part of the contract account consumes.
      //
      // `Failure.message` therefore carries the server's own text, which is
      // exactly what the source renders. See specs.md § 6.8 item 3: that the
      // raw server message reaches the UI on a credential endpoint is a
      // measured property of the oracle, recorded on the security review's
      // agenda (B8-AC-59 item 2) rather than silently improved here.
      return Left<Failure, Unit>(Failure(e.toString()));
    }
  }
}

/// `SessionRepositoryImpl` — the session feature's only repository impl.
///
/// Follows the flutter-boilerplate `MovieRepositoryImpl` pattern (try the
/// remote datasource, on exception return `Left(Failure(e.toString()))`),
/// with ONE documented deviation: `ApiException` is rethrown, not wrapped.
///
/// Rationale: the session BLoC needs to branch on 401/403 to clear tokens
/// (the TS `loadProfile` guard:
///   `if (err instanceof ApiError && (err.isUnauthorized || err.isForbidden)) tokens.clear();`
/// ). Wrapping `ApiException` into a plain `Failure(message)` would lose the
/// `isUnauthorized`/`isForbidden` signal that the boot/sign-in flow depends
/// on. Other exception types are still wrapped as `Failure` per the
/// boilerplate pattern.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/citizen_profile.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/session_remote_datasource.dart';
import '../models/auth_tokens_model.dart';
import '../models/citizen_profile_model.dart';

class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl({required this.remote});

  final SessionRemoteDatasource remote;

  @override
  Future<Either<Failure, CitizenProfile>> getProfile() async {
    try {
      final model = await remote.getProfile();
      return Right(model.toEntity());
    } on ApiException {
      // Rethrown so SessionBloc can check isUnauthorized/isForbidden and
      // clear tokens — the one typed-error branch the session feature needs.
      rethrow;
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout(String refreshToken) async {
    try {
      await remote.logout(refreshToken);
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthTokens>> refreshTokens(
      String refreshToken) async {
    try {
      final model = await remote.refreshTokens(refreshToken);
      return Right(model.toEntity());
    } on ApiException {
      rethrow;
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}

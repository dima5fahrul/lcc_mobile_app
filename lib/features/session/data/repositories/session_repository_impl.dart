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
import '../../domain/entities/profile_update.dart';
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
  Future<Either<Failure, CitizenProfile>> updateProfile(
      ProfileUpdate update) async {
    try {
      final model = await remote.updateProfile(update);
      return Right(model.toEntity());
    } on ApiException {
      // Rethrown for the same reason `getProfile` rethrows: a 401/403 on a
      // `/me/*` write means the token no longer resolves to an account, and
      // `SessionBloc` is the thing that has to clear it. Wrapping would lose
      // `isUnauthorized`/`isForbidden`.
      //
      // The two B8 callers dispose of it differently and both are ports:
      // `AccountProfileBloc` catches and surfaces the message
      // (`AccountPage.tsx:544-546`), while `SessionBloc`'s R-25 mirror swallows
      // it outright (`.catch(() => undefined)`, `LanguageToggle.tsx:71`).
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

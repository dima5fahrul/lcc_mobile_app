/// `SessionRepository` — the session feature's domain contract.
///
/// Ported from `lcc-app/src/app/api/endpoints.ts` (`me.profile`, `auth.logout`,
/// `auth.refresh`). The UI/BLoC depends on this abstract; the data layer's
/// [SessionRepositoryImpl] is the only concrete implementation.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/auth_tokens.dart';
import '../entities/citizen_profile.dart';

abstract class SessionRepository {
  /// `GET /me/profile` — the signed-in citizen's full profile.
  Future<Either<Failure, CitizenProfile>> getProfile();

  /// `POST /auth/logout` — revoke the refresh token server-side.
  Future<Either<Failure, void>> logout(String refreshToken);

  /// `POST /auth/refresh` — exchange a refresh token for a new token pair.
  Future<Either<Failure, AuthTokens>> refreshTokens(String refreshToken);
}

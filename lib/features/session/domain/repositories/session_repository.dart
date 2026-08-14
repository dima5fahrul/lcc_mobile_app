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
import '../entities/profile_update.dart';

abstract class SessionRepository {
  /// `GET /me/profile` — the signed-in citizen's full profile.
  Future<Either<Failure, CitizenProfile>> getProfile();

  /// `PATCH /me/profile` — the dirty-field diff (`endpoints.ts:96-105`).
  ///
  /// **This lives on the session repository, not on account's** (specs.md
  /// § 6.3): `features/session/` already owns the `GET` for this path, and two
  /// features writing one endpoint would mean two independent copies of its
  /// wire format. CFI's accepted-cost clause covers duplicated *parsing*, not
  /// duplicated ownership of a *mutation*.
  ///
  /// Answers the refreshed [CitizenProfile] the API echoes back
  /// (`api.patch<CitizenProfile>`). Two call sites, both in B8:
  /// `AccountProfileBloc`'s save (`AccountPage.tsx:222`) and `SessionBloc`'s
  /// R-25 language mirror (`LanguageToggle.tsx:71`).
  Future<Either<Failure, CitizenProfile>> updateProfile(ProfileUpdate update);

  /// `POST /auth/logout` — revoke the refresh token server-side.
  Future<Either<Failure, void>> logout(String refreshToken);

  /// `POST /auth/refresh` — exchange a refresh token for a new token pair.
  Future<Either<Failure, AuthTokens>> refreshTokens(String refreshToken);
}

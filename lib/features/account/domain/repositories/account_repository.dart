/// The account surface's repository contract — three calls.
///
/// | Source | Method | Endpoint | Envelope |
/// |---|---|---|---|
/// | `AccountPage.tsx:191` | [getPreferences] | `GET /me/preferences` | object |
/// | `:258` | [savePreferences] | **`PUT`** `/me/preferences` | object |
/// | `:190` | [getDocuments] | `GET /me/documents` | **plain array** |
///
/// `PATCH /me/profile` and `POST /auth/change-password` are **deliberately
/// absent**: specs.md § 6.3 puts them on `features/session/` and
/// `features/auth/` respectively, and `features/account/` consumes them through
/// those features' `domain/**`. Putting a fourth and fifth method here would
/// be two features owning one mutation each — the thing CFI's accepted-cost
/// clause does *not* cover.
///
/// `DELETE /me/account` is absent because the feature does not exist in the
/// oracle (specs.md § 6.1, FU-4). See `api_endpoint.dart`'s B8a block.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/citizen_document.dart';
import '../entities/citizen_preferences.dart';

abstract class AccountRepository {
  /// `GET /me/preferences` — `endpoints.ts:122`.
  Future<Either<Failure, CitizenPreferences>> getPreferences();

  /// `PUT /me/preferences` — `endpoints.ts:123`.
  ///
  /// **`PUT`, not `PATCH`, and the body is the whole object.** The caller is
  /// responsible for having merged it (`CitizenPreferences.merge`); this
  /// method sends what it is given. That split is deliberate: the merge is the
  /// ported transform and belongs somewhere a Tier 0 test can reach without a
  /// network double.
  Future<Either<Failure, CitizenPreferences>> savePreferences(
    CitizenPreferences preferences,
  );

  /// `GET /me/documents` — `endpoints.ts:115`.
  ///
  /// **Never measured for the live test citizen** (specs.md § 6.5, GG-2). The
  /// four list states are gated against fixtures; the *populated* state's live
  /// behaviour is NOT EVALUATED with that reason recorded, not asserted from an
  /// assumption that the list is empty.
  Future<Either<Failure, List<CitizenDocument>>> getDocuments();
}

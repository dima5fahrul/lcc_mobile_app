/// The public verification repository — the two anonymous reads of
/// MOBILE-API-E-CERTIFICATES.md (2026-10) § Public verification endpoints.
///
/// Both methods return the SAME `VerificationResult`; the two endpoints
/// differ only in the lookup key (code vs document hash). There is **no
/// write path**: `document-hash` is a POST whose body is a fingerprint, and
/// it creates nothing — § Checking a PDF on the device calls it a *check*.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/verification_result.dart';

abstract class VerifyRepository {
  /// `GET /verify/{code}` — by the code a QR carried or the citizen typed,
  /// as extracted by `certificateCodeFromScanned` (nothing else may call
  /// this with unvalidated text — rule 3 of § QR codes and deep links: a
  /// scanned password or personal data never reaches server logs).
  ///
  /// An unknown code is a **Right** carrying `status: "not-found"`,
  /// `valid: false` — not a Failure (§ Errors).
  Future<Either<Failure, VerificationResult>> verifyByCode(String code);

  /// `POST /verify/document-hash` — by the device-computed SHA-256 of the
  /// user's PDF, 64 lower-case hex characters. Same not-found-is-a-Right
  /// contract as [verifyByCode].
  Future<Either<Failure, VerificationResult>> verifyDocumentHash(String hash);
}

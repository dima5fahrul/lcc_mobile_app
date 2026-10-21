/// `VerificationResult` — the one object BOTH public verification endpoints
/// answer, `GET /verify/{code}` and `POST /verify/document-hash`
/// (MOBILE-API-E-CERTIFICATES.md, 2026-10, § Public verification endpoints).
///
/// Every key the guide's example body sends is a field here, per
/// `application_row.dart`'s standing rule that every wire key is parsed,
/// rendered or not — including `copy`, `revoked_at`, `revoke_reason` and
/// `replaced_by_certificate_no`, which Task 4's five status screens consume.
///
/// ## `status` and every `checks.*.status` are plain Strings — open sets
///
/// The same argument `issued_certificate.dart` makes: `status` moves through
/// `issued | expired | revoked | superseded | not-found` today and an enum
/// would add a failure mode the wire does not have — a new status must render
/// as its word, not crash and not collapse into `unknown`. The check
/// statuses are the guide's honest-wording table, verbatim open sets:
/// `signature.status` is `recorded | missing` (never "verified"),
/// `record_hash.status` is `match | mismatch | missing`,
/// `revocation.status` is `not-revoked | revoked | superseded | not-found`.
///
/// ## Holder names are masked server-side, and nothing here unmasks them
///
/// The guide: "holder names are always masked here … The response never
/// contains the holder's UIN, birth date, address or the issuing village; do
/// not try to show more." [holderName] and [holders] are read as plain
/// strings and stay exactly as the server sent them.
///
/// ## Declared locally per G-L3, like `certificate_wire.dart`'s readers
///
/// `features/documents/**` holds near-identical lenient readers. The domain
/// edge (`features/session/domain/entities/bilingual.dart`) is shared
/// currency; the data edge (`application_wire.dart`) is not — `ssd.md` § 4.3
/// — so the readers live in `verification_wire.dart` in this feature, copied
/// not imported.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/bilingual.dart';

part 'verification_result.freezed.dart';

/// `issuer_contact` — `{phone, email, address}`, all three possibly `""`
/// (the guide's own example sends empty strings).
@freezed
abstract class IssuerContact with _$IssuerContact {
  const factory IssuerContact({
    required String phone,
    required String email,
    required String address,
  }) = _IssuerContact;
}

/// `checks.signature` — an officer's signature on file. `ca`, `format` and
/// `timestamp` "stay empty until the national CA is connected; show them only
/// when non-empty" (guide, § Public verification endpoints) — parsed, kept,
/// rendered-or-not is Task 4's decision.
@freezed
abstract class SignatureCheck with _$SignatureCheck {
  const factory SignatureCheck({
    /// `recorded` (an officer's signature is on file) or `missing`. A plain
    /// String — never worded as "verified" anywhere downstream.
    required String status,
    required String provider,
    required String method,
    required String signerName,
    Bilingual? signerTitle,
    required String signedAt,
    required String ca,
    required String format,
    required String timestamp,
  }) = _SignatureCheck;
}

/// `checks.record_hash` — the SERVER's stored file fingerprint, and nothing
/// about the user's own file (only the PDF check says that). `mismatch`
/// "warn, and offer the PDF check"; `missing` hides the check (Task 7).
@freezed
abstract class RecordHashCheck with _$RecordHashCheck {
  const factory RecordHashCheck({
    /// `match | mismatch | missing` — plain String, open set.
    required String status,
    required String algorithm,
  }) = _RecordHashCheck;
}

/// `checks.revocation` — `not-revoked | revoked | superseded`, and
/// `not-found` on a not-found answer.
@freezed
abstract class RevocationCheck with _$RevocationCheck {
  const factory RevocationCheck({
    required String status,
    required String checkedAt,
  }) = _RevocationCheck;
}

/// The three sub-objects, held together so a consumer reads
/// `result.checks.recordHash.status` and not three nullable fields.
@freezed
abstract class VerificationChecks with _$VerificationChecks {
  const factory VerificationChecks({
    required SignatureCheck signature,
    required RecordHashCheck recordHash,
    required RevocationCheck revocation,
  }) = _VerificationChecks;
}

@freezed
abstract class VerificationResult with _$VerificationResult {
  const factory VerificationResult({
    /// `true` only for `issued` — but read as `bool?`: a non-bool wire value
    /// is *unknown*, which `false` would misreport
    /// (`certificate_wire.dart`'s `_nullableBoolAt` disposition).
    bool? valid,

    /// `issued | expired | revoked | superseded | not-found` — plain String,
    /// open set, the five-screen router Task 4 builds.
    required String status,
    required String certificateNo,
    required String documentType,

    /// `""` joint card, `A` husband's booklet, `B` wife's booklet (§ Divorce).
    required String copy,
    required String layout,
    Bilingual? service,
    required String serviceCode,

    /// Masked server-side (`P****** S********`). Never unmasked here.
    required String holderName,
    @Default(<String>[]) List<String> holders,
    required String issuedAt,

    /// The one optional whose `''` IS absence, per `certificate_wire.dart`'s
    /// `_nullableDateAt` — EXPIRED needs a real date or nothing.
    String? validUntil,
    Bilingual? issuingOffice,
    IssuerContact? issuerContact,
    required String verifyCode,
    String? documentHash,
    required String language,
    required String revokedAt,
    required String revokeReason,
    required String replacedByCertificateNo,
    required VerificationChecks checks,
    required String checkedAt,
  }) = _VerificationResult;
}

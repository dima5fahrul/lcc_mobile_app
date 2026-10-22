/// Synthetic `VerificationResult` fixtures for the verify presentation tests.
///
/// **SYNTHETIC, and named for it** — the `notification_test_helper.dart`
/// convention: these are not recorded staging payloads, they are constructed
/// from the guide's own § Public verification endpoints example body, key for
/// key, by hand. The transport suite
/// (`test/features/verify/data/verify_transport_test.dart`) is where the real
/// wire shapes are driven through real Dio; these builders serve the bloc and
/// the widget, which consume the *entity*.
///
/// Each builder overrides only what its screen claim needs and carries the
/// guide's defaults for everything else, so a test reads as "an issued answer
/// whose record_hash mismatched" rather than as a wall of field literals.
library;

import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';
import 'package:lcc_mobile_app/features/verify/domain/entities/verification_result.dart';

/// `checks` from the guide's example, adjustable per check.
VerificationResult verificationResult({
  bool? valid,
  String status = 'issued',
  String certificateNo = 'LA-RES-2026-000123',
  String holderName = 'P****** S********',
  List<String> holders = const <String>['P****** S********'],
  String issuedAt = '2026-09-30',
  String? validUntil = '2026-12-29',
  Bilingual? issuingOffice = const Bilingual(
    en: 'District Office of Public Security, Chanthabuly',
    lo: '…',
  ),
  IssuerContact? issuerContact = const IssuerContact(
    phone: '',
    email: '',
    address: '',
  ),
  String verifyCode = 'RES-7Q4K-19XD',
  String revokedAt = '',
  String revokeReason = '',
  String replacedByCertificateNo = '',
  String signatureStatus = 'recorded',
  String signatureSignerName = 'Vongdeuane XAYASONE',
  String signatureCa = '',
  String signatureFormat = '',
  String signatureTimestamp = '',
  String recordHashStatus = 'match',
  String revocationStatus = 'not-revoked',
  String checkedAt = '2026-10-21T11:24:03+07:00',
  String? documentHash = '3f9a…c21b',
}) {
  return VerificationResult(
    valid: valid,
    status: status,
    certificateNo: certificateNo,
    documentType: 'RES',
    copy: '',
    layout: 'card',
    service: const Bilingual(en: 'Residence Certificate', lo: '…'),
    serviceCode: 'resident',
    holderName: holderName,
    holders: holders,
    issuedAt: issuedAt,
    validUntil: validUntil,
    issuingOffice: issuingOffice,
    issuerContact: issuerContact,
    verifyCode: verifyCode,
    documentHash: documentHash,
    language: 'lo',
    revokedAt: revokedAt,
    revokeReason: revokeReason,
    replacedByCertificateNo: replacedByCertificateNo,
    checks: VerificationChecks(
      signature: SignatureCheck(
        status: signatureStatus,
        provider: 'visual',
        method: 'officer-otp',
        signerName: signatureSignerName,
        signerTitle: const Bilingual(en: 'District Officer', lo: '…'),
        signedAt: '2026-09-30T10:42:18+07:00',
        ca: signatureCa,
        format: signatureFormat,
        timestamp: signatureTimestamp,
      ),
      recordHash: RecordHashCheck(
        status: recordHashStatus,
        algorithm: 'SHA-256',
      ),
      revocation: RevocationCheck(
        status: revocationStatus,
        checkedAt: checkedAt,
      ),
    ),
    checkedAt: checkedAt,
  );
}

/// The guide's own example answer — `issued`, everything green.
VerificationResult issuedResult() => verificationResult();

/// The issued answer with the three CA fields non-empty — the national CA
/// connected, which the guide says is why they are usually `""`.
VerificationResult issuedResultWithCa() => verificationResult(
      signatureCa: 'National Digital CA',
      signatureFormat: 'PAdES-B-LT',
      signatureTimestamp: '2026-09-30T10:42:18+07:00',
    );

/// The guide's not-found answer: 200, `valid: false`, `status: "not-found"`,
/// revocation `not-found`.
VerificationResult notFoundResult() => verificationResult(
      valid: false,
      status: 'not-found',
      certificateNo: '',
      holderName: '',
      holders: <String>[],
      issuedAt: '',
      validUntil: null,
      issuingOffice: null,
      issuerContact: null,
      verifyCode: 'RES-0000-0000',
      revocationStatus: 'not-found',
      documentHash: null,
    );

/// A residence certificate past `valid_until`.
VerificationResult expiredResult() => verificationResult(
      valid: false,
      status: 'expired',
      revokedAt: '',
    );

/// A revoked certificate — REVOKED — do not accept.
VerificationResult revokedResult() => verificationResult(
      valid: false,
      status: 'revoked',
      validUntil: null,
      revokedAt: '2026-10-15T09:00:00+07:00',
      revokeReason: 'Reported lost by the holder',
      revocationStatus: 'revoked',
    );

/// A reissued certificate whose old row answers `superseded`.
VerificationResult supersededResult() => verificationResult(
      valid: false,
      status: 'superseded',
      validUntil: null,
      replacedByCertificateNo: 'LA-RES-2026-000456',
      revocationStatus: 'superseded',
    );

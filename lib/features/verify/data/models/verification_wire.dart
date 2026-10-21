/// The public verification endpoints' wire mapper — `VerificationResult` ←
/// the body `GET /verify/{code}` and `POST /verify/document-hash` both
/// answer (MOBILE-API-E-CERTIFICATES.md, 2026-10, § Public verification
/// endpoints).
///
/// ## The readers are local, and that is CFI, not duplication-by-accident
///
/// `features/documents/data/models/certificate_wire.dart` holds the same
/// eight lines of null-shape defence. **G-L3 forbids
/// `features/verify/** → features/documents/**`** — the domain edge is the
/// shared currency, the data edge is not (`ssd.md` § 4.3) — so the readers
/// are declared here, in the verify feature, with the dispositions copied.
///
/// ## The not-found answer is a normal parse
///
/// An unknown code answers **200** `{"valid": false, "status": "not-found"}`
/// (§ Errors: "not an HTTP error") — it rides this mapper into a
/// [VerificationResult] and reaches the caller as a Right. Only a genuinely
/// failed request (429, network, non-2xx) becomes a Failure.
library;

import '../../../session/domain/entities/bilingual.dart';
import '../../domain/entities/verification_result.dart';

/// A required string: anything that is not a `String` reads as `''`, which
/// the entity's `required String` fields then carry without a crash.
String _stringAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  return raw is String ? raw : '';
}

/// An optional string. `''` is kept as `''` except where a key's `''` IS an
/// absence marker — see [_nullableDateAt].
String? _nullableStringAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  return raw is String ? raw : null;
}

/// `valid_until` — the EXPIRED screen's date. The guide's own examples send
/// `"valid_until": ""` when there is no horizon, so `''` collapses to null
/// exactly as `certificate_wire.dart` rules for this key.
String? _nullableDateAt(Map<String, dynamic> json, String key) {
  final String? raw = _nullableStringAt(json, key);
  return raw == null || raw.isEmpty ? null : raw;
}

/// An optional bool: `true`/`false` read verbatim, everything else reads as
/// *unknown* rather than as a verdict — `valid: false` and "never answered"
/// are different facts (the not-found body sends `valid: false` and it must
/// survive as false, not be confused with a malformed answer).
bool? _nullableBoolAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  return raw is bool ? raw : null;
}

/// `{en, lo}` — and a plain string lands on **both** sides, the disposition
/// `certificate_wire.dart`'s `_nullableBilingualAt` measures from
/// `text(value, lang)`'s `wanted || en || lo || ""` fallback.
Bilingual? _nullableBilingualAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is String) return raw.isEmpty ? null : Bilingual(en: raw, lo: raw);
  if (raw is Map<String, dynamic>) {
    return Bilingual(
      en: raw['en'] is String ? raw['en'] as String : '',
      lo: raw['lo'] is String ? raw['lo'] as String : '',
    );
  }
  return null;
}

/// `holders[]` — non-strings dropped one element at a time, the
/// `_stringsAt` disposition: a row that names two people and one stray `42`
/// still parses its two names.
List<String> _stringsAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is! List<dynamic>) return const <String>[];
  return <String>[
    for (final Object? entry in raw)
      if (entry is String) entry,
  ];
}

/// A sub-object of `checks` that is not a map — the whole check reads as its
/// empty default, not a crash.
Map<String, dynamic> _mapAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  return raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
}

/// One public verification answer.
VerificationResult verificationResultFrom(Map<String, dynamic> json) {
  final Map<String, dynamic> checksMap = json['checks'] is Map<String, dynamic>
      ? json['checks'] as Map<String, dynamic>
      : const <String, dynamic>{};
  final Map<String, dynamic> signature = _mapAt(checksMap, 'signature');
  final Map<String, dynamic> recordHash = _mapAt(checksMap, 'record_hash');
  final Map<String, dynamic> revocation = _mapAt(checksMap, 'revocation');
  final Map<String, dynamic> issuerContact = _mapAt(json, 'issuer_contact');

  return VerificationResult(
    valid: _nullableBoolAt(json, 'valid'),
    status: _stringAt(json, 'status'),
    certificateNo: _stringAt(json, 'certificate_no'),
    documentType: _stringAt(json, 'document_type'),
    copy: _stringAt(json, 'copy'),
    layout: _stringAt(json, 'layout'),
    service: _nullableBilingualAt(json, 'service'),
    serviceCode: _stringAt(json, 'service_code'),
    holderName: _stringAt(json, 'holder_name'),
    holders: _stringsAt(json, 'holders'),
    issuedAt: _stringAt(json, 'issued_at'),
    validUntil: _nullableDateAt(json, 'valid_until'),
    issuingOffice: _nullableBilingualAt(json, 'issuing_office'),
    issuerContact: IssuerContact(
      phone: _stringAt(issuerContact, 'phone'),
      email: _stringAt(issuerContact, 'email'),
      address: _stringAt(issuerContact, 'address'),
    ),
    verifyCode: _stringAt(json, 'verify_code'),
    documentHash: _nullableStringAt(json, 'document_hash'),
    language: _stringAt(json, 'language'),
    revokedAt: _stringAt(json, 'revoked_at'),
    revokeReason: _stringAt(json, 'revoke_reason'),
    replacedByCertificateNo: _stringAt(json, 'replaced_by_certificate_no'),
    checks: VerificationChecks(
      signature: SignatureCheck(
        status: _stringAt(signature, 'status'),
        provider: _stringAt(signature, 'provider'),
        method: _stringAt(signature, 'method'),
        signerName: _stringAt(signature, 'signer_name'),
        signerTitle: _nullableBilingualAt(signature, 'signer_title'),
        signedAt: _stringAt(signature, 'signed_at'),
        ca: _stringAt(signature, 'ca'),
        format: _stringAt(signature, 'format'),
        timestamp: _stringAt(signature, 'timestamp'),
      ),
      recordHash: RecordHashCheck(
        status: _stringAt(recordHash, 'status'),
        algorithm: _stringAt(recordHash, 'algorithm'),
      ),
      revocation: RevocationCheck(
        status: _stringAt(revocation, 'status'),
        checkedAt: _stringAt(revocation, 'checked_at'),
      ),
    ),
    checkedAt: _stringAt(json, 'checked_at'),
  );
}

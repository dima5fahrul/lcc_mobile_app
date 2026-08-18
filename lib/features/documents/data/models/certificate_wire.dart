/// `Certificate` → [IssuedCertificate] — `lcc-app/src/app/api/types.ts:625-641`.
///
/// **All 15 wire fields** (`B5-AC-27`), including the four this surface parses
/// and never renders. `application_row.dart`'s standing rule is that every key
/// the wire sends is parsed; the entity's doc records which four are silent and
/// why.
///
/// ## The readers are local, and that is CFI, not duplication-by-accident
///
/// `features/application/data/models/application_wire.dart` already holds
/// `stringAt` / `nullableStringAt` / `nullableBilingualAt`. **G-L3 forbids
/// `features/documents/** → features/application/data/**`** — the domain edge
/// is the shared currency, the data edge is not (`ssd.md` § 4.3) — so the three
/// readers below are declared here. They are eight lines of null-shape defence,
/// not a transform with behaviour that can drift; the thing that *would* drift
/// (the date table) is imported instead, per Finding Q.
library;

import '../../../session/domain/entities/bilingual.dart';
import '../../domain/entities/issued_certificate.dart';

/// A required string: anything that is not a `String` reads as `''`, which the
/// mappers' `||` fallbacks then treat exactly as the source's falsy branch.
String _stringAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  return raw is String ? raw : '';
}

/// An optional string. `''` is kept as `''` rather than collapsed to null: the
/// source distinguishes them nowhere on this surface, and collapsing would make
/// `certificate_no: ""` and an absent key indistinguishable to a wire test.
String? _nullableStringAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  return raw is String ? raw : null;
}

/// `service_name?: Bilingual` — `types.ts:630`.
///
/// Accepts the two shapes this API sends (`application_wire.dart:15` measured
/// both): `{en, lo}`, and a plain string which lands on **both** sides —
/// faithful, because `text(value, lang)` (`types.ts:17-22`) falls back
/// `wanted || en || lo || ""` and so already renders one language in either
/// locale on the web.
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

/// One `Certificate` object.
IssuedCertificate issuedCertificateFrom(Map<String, dynamic> json) =>
    IssuedCertificate(
      id: _stringAt(json, 'id'),
      certificateNo: _stringAt(json, 'certificate_no'),
      applicationId: _nullableStringAt(json, 'application_id'),
      referenceNo: _nullableStringAt(json, 'reference_no'),
      serviceCode: _stringAt(json, 'service_code'),
      serviceName: _nullableBilingualAt(json, 'service_name'),
      holderName: _stringAt(json, 'holder_name'),
      uin: _nullableStringAt(json, 'uin'),
      issuedAt: _stringAt(json, 'issued_at'),
      issuedByName: _nullableStringAt(json, 'issued_by_name'),
      // A plain string, never an enum — specs.md § 5 and `B5-AC-28`.
      status: _stringAt(json, 'status'),
      verifyCode: _stringAt(json, 'verify_code'),
      verifyUrl: _nullableStringAt(json, 'verify_url'),
      qrPayload: _nullableStringAt(json, 'qr_payload'),
      fileUrl: _nullableStringAt(json, 'file_url'),
      documentHash: _nullableStringAt(json, 'document_hash'),
    );

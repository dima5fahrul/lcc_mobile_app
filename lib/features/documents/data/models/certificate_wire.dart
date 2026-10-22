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
import '../../domain/entities/certificate_file.dart';
import '../../domain/entities/certificate_qr.dart';
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

/// `valid_until` — the one v2 optional whose `''` **is** collapsed to null.
///
/// The spec's own list item sends `"valid_until": ""` for a row without a
/// horizon, i.e. the wire uses `''` as an absence marker on this key, so
/// keeping it verbatim would hand callers two absences (null and `''`) where
/// the spec means one.
String? _nullableDateAt(Map<String, dynamic> json, String key) {
  final String? raw = _nullableStringAt(json, key);
  return raw == null || raw.isEmpty ? null : raw;
}

/// An optional bool: `true`/`false` read verbatim, everything else (absent,
/// null, a string the server should not have sent) reads as *unknown* rather
/// than as a verdict — `valid: false` and "never answered" are different
/// facts about a certificate.
bool? _nullableBoolAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  return raw is bool ? raw : null;
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

/// `files[]` — one `CertificateFile` per layout (`§ Certificate model`).
///
/// A body that is not a list, or an entry that is not a map, contributes
/// nothing rather than a crash: a list endpoint returns many rows, and one
/// malformed row must not blank the card (the same disposition
/// `getCertificates` takes via `whereType`). Per-field reads go through the
/// same `_stringAt` leniency, so a map with wrong-typed fields is skipped
/// whole — a partial file with no URL is worse than none.
List<CertificateFile> _filesAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is! List<dynamic>) return const <CertificateFile>[];
  return <CertificateFile>[
    for (final Object? entry in raw)
      if (entry is Map<String, dynamic> &&
          _stringAt(entry, 'layout').isNotEmpty &&
          _stringAt(entry, 'url').isNotEmpty)
        CertificateFile(
          layout: _stringAt(entry, 'layout'),
          url: _stringAt(entry, 'url'),
          sha256: _stringAt(entry, 'sha256'),
        ),
  ];
}

/// A list-of-strings wire key (`layouts`, `holders`): non-strings are dropped
/// one element at a time — a row that names three people and one stray `42`
/// still parses its three names.
List<String> _stringsAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is! List<dynamic>) return const <String>[];
  return <String>[
    for (final Object? entry in raw)
      if (entry is String) entry,
  ];
}

/// The certificate object inside a detail body, wherever the endpoint put it.
///
/// `GET /me/certificates/{id}` on the v2 API answers
/// `data = {certificate: …, issuing_office: …, holder: …}` — the item nested
/// under `certificate` — while the shipped v1 body was the item itself, flat.
/// Both shapes land here; `certificate` wins only when it is a map, so a
/// server that sends `"certificate": null` among the detail siblings still
/// falls through to the flat read instead of blanking.
Map<String, dynamic> _certificateBody(dynamic data) {
  if (data is Map<String, dynamic> &&
      data['certificate'] is Map<String, dynamic>) {
    return data['certificate'] as Map<String, dynamic>;
  }
  return data is Map<String, dynamic> ? data : const <String, dynamic>{};
}

/// One `Certificate` object.
///
/// Accepts both body shapes the endpoints produce: a bare list item (no
/// `certificate` key, so [_certificateBody] returns it unchanged) and the
/// detail body, which may nest the item under `certificate` (v2) or be the
/// item itself (v1) — the datasource forwards either whole.
IssuedCertificate issuedCertificateFrom(Map<String, dynamic> json) {
  final Map<String, dynamic> body = _certificateBody(json);
  return IssuedCertificate(
    id: _stringAt(body, 'id'),
    certificateNo: _stringAt(body, 'certificate_no'),
    applicationId: _nullableStringAt(body, 'application_id'),
    referenceNo: _nullableStringAt(body, 'reference_no'),
    serviceCode: _stringAt(body, 'service_code'),
    // New-first: the v2 bilingual `service` object is the current shape and
    // shadows the legacy string; a v1 row sends no `service` and falls
    // through to `service_name`.
    serviceName:
        _nullableBilingualAt(body, 'service') ??
        _nullableBilingualAt(body, 'service_name'),
    holderName: _stringAt(body, 'holder_name'),
    uin: _nullableStringAt(body, 'uin'),
    issuedAt: _stringAt(body, 'issued_at'),
    issuedByName: _nullableStringAt(body, 'issued_by_name'),
    // A plain string, never an enum — specs.md § 5 and `B5-AC-28`.
    status: _stringAt(body, 'status'),
    verifyCode: _stringAt(body, 'verify_code'),
    verifyUrl: _nullableStringAt(body, 'verify_url'),
    qrPayload: _nullableStringAt(body, 'qr_payload'),
    fileUrl: _nullableStringAt(body, 'file_url'),
    documentHash: _nullableStringAt(body, 'document_hash'),
    // The v2 keys, each defaulted by the entity when the key is absent.
    //
    // `document_type` (review I-2, 2026-10-22): the spec's list item carries
    // it beside `copy` and the implementation checklist labels a row by the
    // pair. Legacy rows send neither and both default to `''`.
    documentType: _stringAt(body, 'document_type'),
    copy: _stringAt(body, 'copy'),
    layouts: _stringsAt(body, 'layouts'),
    files: _filesAt(body, 'files'),
    holders: _stringsAt(body, 'holders'),
    validUntil: _nullableDateAt(body, 'valid_until'),
    valid: _nullableBoolAt(body, 'valid'),
    language: _nullableStringAt(body, 'language'),
    reissuedFrom: _nullableStringAt(body, 'reissued_from'),
  );
}

/// One QR endpoint answer — `GET /me/certificates/{id}/qr` (the 2026-10
/// guide's § Citizen endpoints, QR paragraph). Same lenient readers as
/// [issuedCertificateFrom]: `status` stays a plain string (open set), `valid`
/// reads through [_nullableBoolAt] (non-bool = unknown, not false), and the
/// optional strings read through [_nullableStringAt] so an absent or
/// wrong-typed `payload` is "draw nothing", not a crash.
CertificateQr certificateQrFrom(Map<String, dynamic> json) {
  return CertificateQr(
    certificateId: _stringAt(json, 'certificate_id'),
    certificateNo: _stringAt(json, 'certificate_no'),
    verifyCode: _stringAt(json, 'verify_code'),
    verifyUrl: _nullableStringAt(json, 'verify_url'),
    payload: _nullableStringAt(json, 'payload'),
    documentHash: _nullableStringAt(json, 'document_hash'),
    status: _stringAt(json, 'status'),
    valid: _nullableBoolAt(json, 'valid'),
    issuedAt: _stringAt(json, 'issued_at'),
  );
}

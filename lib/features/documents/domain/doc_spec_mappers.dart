/// The two live mappers of `lcc-app/src/app/data/documents.ts`, ported clause
/// for clause.
///
/// ## Two of the source's three, and the third is dead
///
/// `docSpecFromDocument` (`:79-115`) is **not** ported. Its only consumer is
/// `DocumentViewer`'s `documentId` branch, and neither of the component's two
/// mount sites passes `documentId` (specs.md Finding D), so the branch, the
/// single-document query behind it (`endpoints.ts:116`) and the
/// `DocumentPayload` type are all unreachable in the shipped web app. Porting
/// it would be the first half of porting a behaviour the source does not have.
///
/// ## `day()` is IMPORTED, not re-implemented (specs.md Finding Q)
///
/// `data/documents.ts:52-61`'s `day()` is byte-identical in behaviour to
/// `HistoryDetailPage.tsx:85-94`'s `formatDate` — same `en-GB`/`lo-LA`
/// short-month tables, same `2-digit` day, same `"—"` absent sentinel, same
/// return-the-input-verbatim fallback. The Flutter port of that transform is
/// [formatApplicationDate], whose own library doc records it as the **fourth**
/// copy in this tree. A fifth is the one that drifts
/// (`wallet_formatting.dart:29`'s ruling, applied), and CFI/G-L3 permit
/// `features/documents/domain → features/application/domain`
/// (`ssd.md` § 4.3, § 4.4.1 RULING 13). `B5-AC-26`.
///
/// ## Locale in, locale out
///
/// Both mappers take a [Lang] because both source functions take `lang` and
/// localise six field labels and the date table with it. That is the half of
/// the port that **must** vary by locale (`B5-AC-64`) — the complement of
/// `B5-AC-87`, which requires the painter's chrome not to.
library;

import '../../../i18n/i18n.dart';
import '../../application/domain/application_formatting.dart';
import '../../application/domain/entities/application_detail.dart';
import 'entities/doc_spec.dart';
import 'entities/issued_certificate.dart';

/// `const L = (lang, en, lo) => (lang === "lo" ? lo : en)` —
/// `data/documents.ts:49`.
String _l(Lang lang, String en, String lo) => lang == Lang.lo ? lo : en;

/// The `office` fallback both mappers share — `:108`, `:135`, `:171`. An
/// English literal in the source, and **not** localised: `data/documents.ts`
/// writes it as a bare string on all three sites even though `lang` is in
/// scope. Mirrored, not improved (`ssd.md` § 11.2 L-10 corollary (b)).
const String kDocumentOfficeFallback = 'Lao Citizen Center';

/// The `"—"` the mappers substitute for an absent holder or reference.
/// Identical in value to [kAbsentDate] and declared separately because the
/// source writes two different literals that happen to agree; collapsing them
/// would hide a future divergence.
const String kDocumentAbsent = '—';

/// `titleCase(slug)` — `data/documents.ts:63-69`.
///
/// ```ts
/// slug.split(/[-_]/).filter(Boolean)
///     .map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join(" ")
/// ```
///
/// **Only the first character is upper-cased; the rest of the word is left
/// exactly as it arrived** (`B5-AC-62`). So `"under-review"` becomes
/// `"Under Review"` and `"UNDER_REVIEW"` becomes `"UNDER REVIEW"` — not
/// `"Under Review"`. A `toLowerCase()` on the tail would be an improvement the
/// source does not make.
String titleCase(String slug) => slug
    .split(RegExp(r'[-_]'))
    .where((String w) => w.isNotEmpty)
    .map((String w) => '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

/// The `push` guard both mappers use — `:120-122`, `:154-156`. A field with an
/// empty or absent value is **skipped entirely**, not rendered blank.
void _push(List<DocField> into, String label, String? value) {
  if (value != null && value.isNotEmpty) {
    into.add(DocField(label: label, value: value));
  }
}

/// `docSpecFromCertificate(cert, lang)` — `data/documents.ts:118-140`.
///
/// Six fields in the source's order (`:123-128`), empties skipped
/// (`B5-AC-61`).
DocSpec docSpecFromCertificate(IssuedCertificate cert, Lang lang) {
  final String languageCode = lang == Lang.lo ? kLaoCode : 'en';
  final List<DocField> fields = <DocField>[];

  _push(fields, _l(lang, 'Certificate no.', 'ເລກໃບຢັ້ງຢືນ'), cert.certificateNo);
  _push(fields, _l(lang, 'Reference', 'ເລກອ້າງອີງ'), cert.referenceNo);
  _push(fields, _l(lang, 'UIN', 'ລະຫັດປະຈຳຕົວ'), cert.uin);
  _push(
    fields,
    _l(lang, 'Status', 'ສະຖານະ'),
    // `cert.status ? titleCase(cert.status) : undefined` — `:126`. The ternary
    // is on the RAW value, so an empty status skips the row rather than
    // pushing an empty `titleCase("")`.
    cert.status.isEmpty ? null : titleCase(cert.status),
  );
  _push(fields, _l(lang, 'Issued by', 'ອອກໂດຍ'), cert.issuedByName);
  _push(fields, _l(lang, 'Verify code', 'ລະຫັດກວດສອບ'), cert.verifyCode);

  return DocSpec(
    // `text(cert.service_name, lang) || L(…)` — `:131`.
    title: _orElse(
      text(cert.serviceName, lang),
      _l(lang, 'Official Certificate', 'ໃບຢັ້ງຢືນທາງການ'),
    ),
    kicker: _l(lang, 'Civil Registration', 'ທະບຽນພົນລະເມືອງ'),
    // `cert.certificate_no || cert.reference_no || "—"` — `:133`.
    refNo: _orElse(
      cert.certificateNo,
      _orElse(cert.referenceNo ?? '', kDocumentAbsent),
    ),
    holderName: _orElse(cert.holderName, kDocumentAbsent),
    office: _orElse(cert.issuedByName ?? '', kDocumentOfficeFallback),
    fields: fields,
    issued: formatApplicationDate(cert.issuedAt, languageCode),
    // `cert.verify_code || cert.certificate_no || "—"` — `:138`.
    verifyCode: _orElse(
      cert.verifyCode,
      _orElse(cert.certificateNo, kDocumentAbsent),
    ),
  );
}

/// `docSpecFromApplication(app, cert, lang)` — `data/documents.ts:146-176`.
///
/// **The certificate wins outright**: `if (cert) return docSpecFromCertificate(…)`
/// (`:151`) is an early return, not a merge (`B5-AC-57`). The six-field
/// fallback below is only reached when no certificate resolved.
DocSpec docSpecFromApplication(
  ApplicationDetail app,
  IssuedCertificate? cert,
  Lang lang,
) {
  if (cert != null) return docSpecFromCertificate(cert, lang);

  final String languageCode = lang == Lang.lo ? kLaoCode : 'en';
  final List<DocField> fields = <DocField>[];

  // `:157-162`, in the source's order (`B5-AC-58`).
  _push(fields, _l(lang, 'Reference', 'ເລກອ້າງອີງ'), app.row.referenceNo);
  _push(fields, _l(lang, 'Certificate no.', 'ເລກໃບຢັ້ງຢືນ'), app.row.certificateNo);
  _push(fields, _l(lang, 'Status', 'ສະຖານະ'), text(app.row.statusLabel, lang));
  _push(fields, _l(lang, 'Province', 'ແຂວງ'), app.row.jurisdiction.provinceName);
  _push(fields, _l(lang, 'District', 'ເມືອງ'), app.row.jurisdiction.districtName);
  _push(fields, _l(lang, 'Village', 'ບ້ານ'), app.row.jurisdiction.villageName);

  final String? district = app.row.jurisdiction.districtName;
  final String? province = app.row.jurisdiction.provinceName;

  return DocSpec(
    title: text(app.row.serviceName, lang),
    kicker: _l(lang, 'Civil Registration', 'ທະບຽນພົນລະເມືອງ'),
    // `app.certificate_no || app.reference_no` — `:167`. **No `"—"` third
    // arm here**, unlike the certificate mapper's `:133`; `reference_no` is
    // required on the wire.
    refNo: _orElse(app.row.certificateNo ?? '', app.row.referenceNo),
    // `app.subject_name || app.applicant || "—"` — `:168`.
    holderName: _orElse(
      app.row.subjectName,
      _orElse(app.row.applicant, kDocumentAbsent),
    ),
    // `:169-171`:
    //
    // ```ts
    // app.jurisdiction?.district_name
    //   ? `${app.jurisdiction.district_name} · ${app.jurisdiction.province_name ?? ""}`.trim()
    //   : "Lao Citizen Center"
    // ```
    //
    // **`.trim()` removes whitespace, not the separator.** A case with a
    // district and no province renders `"Vientiane ·"` — the interpolation
    // yields `"Vientiane · "` and `trim` takes the trailing space only. That
    // is the source's output and it is what this port produces;
    // specs.md § 7.7 `B5-AC-60` claims `"Vientiane"`, which the source does
    // not do. Recorded in `code-review.md` rather than silently "fixed",
    // because inventing a cleaner string here is L-10 corollary (b).
    office: (district != null && district.isNotEmpty)
        ? '$district · ${province ?? ''}'.trim()
        : kDocumentOfficeFallback,
    fields: fields,
    // `app.issued_at ?? app.updated_at` — `:173`. Nullish, so an empty
    // `issued_at` is kept and formats to the absent sentinel rather than
    // falling through to `updated_at`.
    issued: formatApplicationDate(app.row.issuedAt ?? app.row.updatedAt, languageCode),
    // `app.certificate_no || app.reference_no` — `:174`, the same pair as
    // [DocSpec.refNo] and evaluated independently in the source.
    verifyCode: _orElse(app.row.certificateNo ?? '', app.row.referenceNo),
  );
}

/// JavaScript's `a || b` over strings: an **empty** left side falls through.
///
/// Dart's `??` is not this — it only falls through on null — and the
/// difference is observable on every field the API can send as `""`.
String _orElse(String value, String fallback) =>
    value.isNotEmpty ? value : fallback;

/// The two live mappers — `B5-AC-57` … `B5-AC-64`.
///
/// Every expectation below is derived from `lcc-app/src/app/data/documents.ts`,
/// clause by clause, and the citations are in the test names.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/application/domain/application_formatting.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_detail.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/jurisdiction.dart';
import 'package:lcc_mobile_app/features/documents/domain/doc_spec_mappers.dart';
import 'package:lcc_mobile_app/features/documents/domain/entities/doc_spec.dart';
import 'package:lcc_mobile_app/features/documents/domain/entities/issued_certificate.dart';
import 'package:lcc_mobile_app/i18n/i18n.dart';

import '../../history/history_test_helper.dart';
import '../documents_test_helper.dart';

void main() {
  group('titleCase — B5-AC-62 (`data/documents.ts:63-69`)', () {
    test('splits on - and _ and drops empties', () {
      expect(titleCase('under-review'), 'Under Review');
      expect(titleCase('a_b-c'), 'A B C');
      expect(titleCase('--a--'), 'A');
      expect(titleCase(''), '');
    });

    test('capitalises ONLY the first character — the tail is untouched', () {
      // `w.charAt(0).toUpperCase() + w.slice(1)` — there is no `toLowerCase()`
      // anywhere in the source, so an already-upper word stays upper.
      expect(titleCase('UNDER_REVIEW'), 'UNDER REVIEW');
      expect(titleCase('mcDonald'), 'McDonald');
      expect(titleCase('superseded'), 'Superseded');
    });
  });

  group('docSpecFromCertificate — B5-AC-61, B5-AC-28', () {
    test('builds the six fields in source order and skips empties', () {
      final DocSpec spec = docSpecFromCertificate(
        certFixture(
          certificateNo: 'CERT-1',
          referenceNo: 'REF-1',
          uin: '1-2-3',
          status: 'valid',
          issuedByName: 'Chanthabouly',
          verifyCode: 'VC-1',
        ),
        Lang.en,
      );

      expect(
        spec.fields.map((DocField f) => f.label).toList(),
        <String>[
          'Certificate no.',
          'Reference',
          'UIN',
          'Status',
          'Issued by',
          'Verify code',
        ],
        reason: '`:123-128`, in that order',
      );
      expect(spec.fields.map((DocField f) => f.value).toList(),
          <String>['CERT-1', 'REF-1', '1-2-3', 'Valid', 'Chanthabouly', 'VC-1']);
    });

    test('the push guard drops an absent or empty value entirely', () {
      final DocSpec spec = docSpecFromCertificate(
        certFixture(referenceNo: null, uin: '', issuedByName: null),
        Lang.en,
      );
      expect(spec.fields.map((DocField f) => f.label),
          isNot(contains('Reference')));
      expect(spec.fields.map((DocField f) => f.label), isNot(contains('UIN')));
      expect(spec.fields.map((DocField f) => f.label),
          isNot(contains('Issued by')));
    });

    test('B5-AC-28 — an unknown status renders through titleCase, not unknown',
        () {
      final DocSpec spec =
          docSpecFromCertificate(certFixture(status: 'superseded'), Lang.en);
      expect(
        spec.fields.firstWhere((DocField f) => f.label == 'Status').value,
        'Superseded',
      );
    });

    test('an empty status skips the row rather than pushing titleCase("")', () {
      final DocSpec spec =
          docSpecFromCertificate(certFixture(status: ''), Lang.en);
      expect(spec.fields.map((DocField f) => f.label), isNot(contains('Status')));
    });

    test('the || fallbacks fall through on EMPTY, not only on null', () {
      final DocSpec spec = docSpecFromCertificate(
        certFixture(
          certificateNo: '',
          referenceNo: 'REF-9',
          holderName: '',
          issuedByName: '',
          verifyCode: '',
          serviceName: null,
        ),
        Lang.en,
      );
      // `cert.certificate_no || cert.reference_no || "—"` — `:133`.
      expect(spec.refNo, 'REF-9');
      expect(spec.holderName, '—');
      expect(spec.office, 'Lao Citizen Center');
      // `cert.verify_code || cert.certificate_no || "—"` — `:138`, and both
      // are empty here.
      expect(spec.verifyCode, '—');
      expect(spec.title, 'Official Certificate');
    });
  });

  group('docSpecFromApplication — B5-AC-57 … B5-AC-60', () {
    ApplicationDetail issued({
      String? certificateNo,
      Jurisdiction? jurisdiction,
      String? issuedAt,
    }) {
      final ApplicationDetail base = detailFixture(
        certificateNo: certificateNo,
        issuedAt: issuedAt,
      );
      return jurisdiction == null
          ? base
          : base.copyWith(row: base.row.copyWith(jurisdiction: jurisdiction));
    }

    test('B5-AC-57 — a certificate short-circuits to the certificate mapper',
        () {
      final IssuedCertificate cert = certFixture(certificateNo: 'FROM-CERT');
      final DocSpec merged =
          docSpecFromApplication(issued(certificateNo: 'FROM-CASE'), cert, Lang.en);

      expect(merged, docSpecFromCertificate(cert, Lang.en),
          reason: '`:151` is an early return, not a merge');
      expect(merged.refNo, 'FROM-CERT',
          reason: 'the case\'s own certificate_no must not leak through');
    });

    test('B5-AC-58 — the six fallback fields, in source order', () {
      final DocSpec spec = docSpecFromApplication(
        issued(certificateNo: 'CERT-CASE'),
        null,
        Lang.en,
      );
      expect(
        spec.fields.map((DocField f) => f.label).toList(),
        <String>[
          'Reference',
          'Certificate no.',
          'Status',
          'Province',
          'District',
        ],
        reason: '`:157-162`; the fixture has no village, so that row is skipped '
            'by the push guard rather than rendered blank',
      );
    });

    test('B5-AC-59 — refNo, holderName and issued read their source chains',
        () {
      final DocSpec withCert =
          docSpecFromApplication(issued(certificateNo: 'C-1'), null, Lang.en);
      expect(withCert.refNo, 'C-1', reason: 'certificate_no wins — `:167`');
      expect(withCert.verifyCode, 'C-1', reason: '`:174`, the same pair');

      final DocSpec withoutCert = docSpecFromApplication(issued(), null, Lang.en);
      expect(withoutCert.refNo, 'LCC-2026-000123',
          reason: 'falls through to reference_no');

      expect(withoutCert.holderName, 'Somchai Jr',
          reason: 'subject_name ?? applicant ?? "—" — `:168`');
    });

    test('issued is `issued_at ?? updated_at` — `:173`', () {
      final ApplicationDetail withIssued = issued(issuedAt: '2026-08-14T14:05:00Z');
      expect(
        docSpecFromApplication(withIssued, null, Lang.en).issued,
        formatApplicationDate('2026-08-14T14:05:00Z', 'en'),
      );

      final ApplicationDetail without = issued();
      expect(
        docSpecFromApplication(without, null, Lang.en).issued,
        formatApplicationDate(without.row.updatedAt, 'en'),
        reason: 'no issued_at, so updated_at',
      );
    });

    test('B5-AC-60 — office is the district/province template, TRIMMED', () {
      const Jurisdiction both = Jurisdiction(
        provinceName: 'Vientiane',
        districtName: 'Chanthabouly',
      );
      expect(
        docSpecFromApplication(issued(jurisdiction: both), null, Lang.en).office,
        'Chanthabouly · Vientiane',
      );

      // **The measured behaviour, and it differs from what specs.md § 7.7
      // `B5-AC-60` claims.** The source is
      // `` `${district} · ${province ?? ""}`.trim() `` — `.trim()` removes
      // WHITESPACE, so a district with no province renders `"Chanthabouly ·"`,
      // separator and all. The AC says `"Vientiane"`. The port mirrors the
      // source; `code-review.md` records the discrepancy.
      const Jurisdiction districtOnly = Jurisdiction(districtName: 'Chanthabouly');
      expect(
        docSpecFromApplication(issued(jurisdiction: districtOnly), null, Lang.en)
            .office,
        'Chanthabouly ·',
      );

      const Jurisdiction provinceOnly = Jurisdiction(provinceName: 'Vientiane');
      expect(
        docSpecFromApplication(issued(jurisdiction: provinceOnly), null, Lang.en)
            .office,
        'Lao Citizen Center',
        reason: 'the ternary is on the DISTRICT, so a province alone falls back',
      );
    });

    test('B5-AC-71 / B5-AC-72 — neither live mapper sets hasPhoto or validUntil',
        () {
      final DocSpec fromCase = docSpecFromApplication(issued(), null, Lang.en);
      final DocSpec fromCert = docSpecFromCertificate(certFixture(), Lang.en);

      expect(fromCase.hasPhoto, isFalse);
      expect(fromCert.hasPhoto, isFalse);
      expect(fromCase.validUntil, isNull);
      expect(fromCert.validUntil, isNull);
    });
  });

  group('B5-AC-64 — the CONTENT is locale-dependent', () {
    test('the same certificate builds a different spec in lo', () {
      final IssuedCertificate cert = certFixture();
      final DocSpec en = docSpecFromCertificate(cert, Lang.en);
      final DocSpec lo = docSpecFromCertificate(cert, Lang.lo);

      expect(en, isNot(lo));
      expect(
        en.fields.map((DocField f) => f.label).toList(),
        isNot(lo.fields.map((DocField f) => f.label).toList()),
        reason: 'all six labels go through L(lang, en, lo)',
      );
      expect(en.kicker, 'Civil Registration');
      expect(lo.kicker, 'ທະບຽນພົນລະເມືອງ');
      expect(en.issued, isNot(lo.issued),
          reason: 'the en-GB and lo-LA short-month tables differ');
    });

    test('the office FALLBACK is not localised — the source never localises it',
        () {
      // `"Lao Citizen Center"` is a bare English literal on all three of its
      // sites (`:108`, `:135`, `:171`) even though `lang` is in scope. Mirrored,
      // not improved (L-10 corollary (b)).
      expect(
        docSpecFromCertificate(certFixture(issuedByName: null), Lang.lo).office,
        kDocumentOfficeFallback,
      );
    });
  });
}

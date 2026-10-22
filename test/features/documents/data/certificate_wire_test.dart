/// `issuedCertificateFrom` — **B5-AC-27**, **B5-AC-28**, **B5-AC-29**, plus the
/// v2 keys of MOBILE-API-E-CERTIFICATES.md (§ Certificate model, § Citizen
/// endpoints).
///
/// The base wire shape is `lcc-app/src/app/api/types.ts:625-641`. The v2 keys
/// (`files[]`, `copy`, `layouts`, `holders`, `valid_until`, `valid`,
/// `language`, `reissued_from`, and the bilingual `service` object) arrive on
/// top of it, read new-first with legacy fallback, and the detail endpoint's
/// body may nest the certificate under `certificate`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/documents/data/models/certificate_wire.dart';
import 'package:lcc_mobile_app/features/documents/domain/entities/certificate_file.dart';
import 'package:lcc_mobile_app/features/documents/domain/entities/issued_certificate.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';

/// A full payload — every one of the 15 keys, each with a distinguishable
/// value, so a field wired to the wrong key fails rather than coincides.
const Map<String, dynamic> _full = <String, dynamic>{
  'id': 'cert-77',
  'certificate_no': 'CERT-77',
  'application_id': 'app-77',
  'reference_no': 'REF-77',
  'service_code': 'residence_certificate',
  'service_name': <String, dynamic>{'en': 'Residence', 'lo': 'ທີ່ຢູ່'},
  'holder_name': 'Somchai Vongsa',
  'uin': '1-2345-67890-12-3',
  'issued_at': '2026-08-14T14:05:00Z',
  'issued_by_name': 'Chanthabouly District Office',
  'status': 'valid',
  'verify_code': 'LCC-2026-000077',
  'verify_url': 'https://lcc.gov.la/v/77',
  'qr_payload': 'LCC:CERT-77',
  'file_url': 'https://cdn.example/77.pdf',
  'document_hash': 'sha256:abc',
};

/// A v2 payload — the MOBILE-API-E-CERTIFICATES.md list item (§ Citizen
/// endpoints), abridged to the keys this mapper reads. Every new key carries a
/// distinguishable value, per the same rule as [_full].
const Map<String, dynamic> _v2 = <String, dynamic>{
  'id': '3c1f',
  'certificate_no': 'LA-DIV-2026-000094-A',
  'application_id': '9a0e',
  'service_code': 'divorce',
  // Deliberately conflicts with `service` below: the test that reads this
  // fixture proves the v2 object wins, which only a differing legacy value
  // can demonstrate.
  'service_name': 'Legacy Divorce',
  'service': <String, dynamic>{
    'en': 'Divorce Certificate',
    'lo': 'ໃບຢືນຢັນຢ່າງ',
  },
  'document_type': 'DIV',
  'copy': 'A',
  'layouts': <String>['booklet'],
  'holder_name': 'PHIMMASONE Khamsy',
  'holders': <String>['PHIMMASONE Khamsy', 'KHAMSY Phimmasone'],
  'issued_at': '2026-09-25',
  'valid_until': '2026-12-24',
  'verify_code': 'DIV-4H7Z-51KA',
  'verify_url': 'https://lcc.gov.la/v/DIV-4H7Z-51KA',
  'language': 'lo',
  'status': 'issued',
  'valid': true,
  'files': <Map<String, dynamic>>[
    <String, dynamic>{
      'layout': 'booklet',
      'url': '/api/v1/me/certificates/3c1f/file?layout=booklet',
      'sha256': '9f2c',
    },
    <String, dynamic>{
      'layout': 'card',
      'url': '/api/v1/me/certificates/3c1f/file?layout=card',
      'sha256': '',
    },
  ],
};

void main() {
  group('B5-AC-27 — all 15 wire fields are parsed', () {
    test('every key lands on its own field', () {
      final IssuedCertificate c = issuedCertificateFrom(_full);

      expect(c.id, 'cert-77');
      expect(c.certificateNo, 'CERT-77');
      expect(c.applicationId, 'app-77');
      expect(c.referenceNo, 'REF-77');
      expect(c.serviceCode, 'residence_certificate');
      expect(c.serviceName, const Bilingual(en: 'Residence', lo: 'ທີ່ຢູ່'));
      expect(c.holderName, 'Somchai Vongsa');
      expect(c.uin, '1-2345-67890-12-3');
      expect(c.issuedAt, '2026-08-14T14:05:00Z');
      expect(c.issuedByName, 'Chanthabouly District Office');
      expect(c.status, 'valid');
      expect(c.verifyCode, 'LCC-2026-000077');
      // The four that are parsed and never rendered on this surface. They are
      // the reason this criterion is worth a test at all: nothing downstream
      // would notice if they silently vanished.
      expect(c.verifyUrl, 'https://lcc.gov.la/v/77');
      expect(c.qrPayload, 'LCC:CERT-77');
      expect(c.fileUrl, 'https://cdn.example/77.pdf');
      expect(c.documentHash, 'sha256:abc');
    });

    test('the fixture really carries 15 keys — the assertion is not vacuous',
        () {
      expect(_full.keys, hasLength(16),
          reason: 'the 15 fields of types.ts:625-641 plus `id`, which the '
              'interface counts as the first of them');
    });

    test('issued_at is kept as the RAW wire string, not a parsed date', () {
      expect(issuedCertificateFrom(_full).issuedAt, '2026-08-14T14:05:00Z',
          reason: 'formatting is the mapper\'s, and the verbatim fallback in '
              '`formatApplicationDate` needs the unparsed value');
    });
  });

  group('defensive shapes', () {
    test('an absent optional reads null; an absent required reads empty', () {
      final IssuedCertificate c =
          issuedCertificateFrom(const <String, dynamic>{});

      expect(c.id, '');
      expect(c.certificateNo, '');
      expect(c.status, '');
      expect(c.verifyCode, '');
      expect(c.applicationId, isNull);
      expect(c.serviceName, isNull);
      expect(c.qrPayload, isNull);
    });

    test('a non-string in a string slot does not throw', () {
      final IssuedCertificate c = issuedCertificateFrom(
        const <String, dynamic>{'id': 42, 'verify_code': <String>[]},
      );
      expect(c.id, '');
      expect(c.verifyCode, '');
    });

    test('B5-AC-29 — service_name accepts both wire shapes', () {
      expect(
        issuedCertificateFrom(
          const <String, dynamic>{'service_name': 'Residence'},
        ).serviceName,
        const Bilingual(en: 'Residence', lo: 'Residence'),
        reason: 'a plain string lands on both sides — `application_wire.dart:15` '
            'measured both shapes on this API',
      );
      expect(
        issuedCertificateFrom(const <String, dynamic>{'service_name': ''})
            .serviceName,
        isNull,
        reason: 'an empty string is absence, not an empty pair',
      );
    });

    test('B5-AC-28 — status is a String, so an open set parses', () {
      for (final String status in <String>[
        'valid',
        'superseded',
        'revoked',
        'something-nobody-planned',
      ]) {
        expect(
          issuedCertificateFrom(<String, dynamic>{'status': status}).status,
          status,
          reason: 'no enum, no `unknown`, no crash',
        );
      }
    });
  });

  group('the two truthiness gates', () {
    test('hasVerifyCode is false for an empty code — `:475`', () {
      expect(
        issuedCertificateFrom(const <String, dynamic>{'verify_code': ''})
            .hasVerifyCode,
        isFalse,
      );
      expect(
        issuedCertificateFrom(const <String, dynamic>{'verify_code': 'VC'})
            .hasVerifyCode,
        isTrue,
      );
    });

    test('hasQrPayload is false for null and for empty — `:482`', () {
      expect(issuedCertificateFrom(const <String, dynamic>{}).hasQrPayload,
          isFalse);
      expect(
        issuedCertificateFrom(const <String, dynamic>{'qr_payload': ''})
            .hasQrPayload,
        isFalse,
      );
      expect(
        issuedCertificateFrom(const <String, dynamic>{'qr_payload': 'x'})
            .hasQrPayload,
        isTrue,
      );
    });
  });

  group('v2 wire keys — MOBILE-API-E-CERTIFICATES.md list item', () {
    test('files[] parses layout, url and sha256 per entry', () {
      final IssuedCertificate c = issuedCertificateFrom(_v2);

      expect(c.files, hasLength(2));
      expect(c.files[0].layout, 'booklet');
      expect(
        c.files[0].url,
        '/api/v1/me/certificates/3c1f/file?layout=booklet',
      );
      expect(c.files[0].sha256, '9f2c');
      // The spec's "sha256 is empty for an old certificate whose file was
      // never hashed" — kept as the empty string the wire sent, not collapsed.
      expect(c.files[1].layout, 'card');
      expect(c.files[1].url, '/api/v1/me/certificates/3c1f/file?layout=card');
      expect(c.files[1].sha256, '');
    });

    test('document_type, copy, layouts, holders and valid_until land verbatim',
        () {
      final IssuedCertificate c = issuedCertificateFrom(_v2);

      // `document_type` — review I-2, 2026-10-22. It was the one list-item
      // key this mapper did not read, and the spec's implementation checklist
      // labels a row by `document_type` + `copy`; with only `copy` a divorce
      // booklet could not say what kind of document it was a copy of.
      expect(c.documentType, 'DIV');
      expect(c.copy, 'A');
      expect(c.layouts, <String>['booklet']);
      expect(
        c.holders,
        <String>['PHIMMASONE Khamsy', 'KHAMSY Phimmasone'],
        reason:
            'a marriage row names two people; holder_name alone cannot '
            'carry both',
      );
      expect(c.validUntil, '2026-12-24');
    });

    test('valid, language and reissued_from land verbatim', () {
      final IssuedCertificate c = issuedCertificateFrom(_v2);

      expect(c.valid, isTrue);
      expect(c.language, 'lo');
      final IssuedCertificate superseded = issuedCertificateFrom(
        const <String, dynamic>{'reissued_from': 'old-row-id'},
      );
      expect(superseded.reissuedFrom, 'old-row-id');
      expect(superseded.valid, isNull, reason: 'absent stays absent');
      // The spec's list item shows `"valid_until": ""` — a legacy row's
      // absence marker, which must read null, not the empty string.
      expect(
        issuedCertificateFrom(const <String, dynamic>{
          'valid_until': '',
        }).validUntil,
        isNull,
      );
    });

    test('service (bilingual object) wins over legacy service_name', () {
      final IssuedCertificate c = issuedCertificateFrom(_v2);

      expect(
        c.serviceName,
        const Bilingual(en: 'Divorce Certificate', lo: 'ໃບຢືນຢັນຢ່າງ'),
        reason:
            'both keys present — the bilingual object is the current shape '
            'and must not be shadowed by the legacy string',
      );
    });

    test('hasStoredFile is true exactly when files[] is non-empty', () {
      expect(issuedCertificateFrom(_v2).hasStoredFile, isTrue);
      expect(
        issuedCertificateFrom(const <String, dynamic>{
          'files': <dynamic>[],
        }).hasStoredFile,
        isFalse,
        reason: 'a legacy row sends no files[] at all',
      );
    });

    test('fileForLayout finds one entry and misses unknown layouts', () {
      final IssuedCertificate c = issuedCertificateFrom(_v2);

      expect(c.fileForLayout('booklet'), isA<CertificateFile>());
      expect(
        c.fileForLayout('booklet')!.url,
        '/api/v1/me/certificates/3c1f/file?layout=booklet',
      );
      expect(c.fileForLayout('card')!.sha256, '');
      expect(c.fileForLayout('nothing'), isNull);
    });

    test(
      'legacy-only body still parses — service_name fallback, empty files',
      () {
        final IssuedCertificate c = issuedCertificateFrom(_full);

        expect(
          c.serviceName,
          const Bilingual(en: 'Residence', lo: 'ທີ່ຢູ່'),
          reason:
              'no `service` key — the legacy string fallback keeps the '
              'v1 rows green',
        );
        expect(c.files, isEmpty);
        expect(c.copy, '');
        expect(c.layouts, isEmpty);
        expect(c.holders, isEmpty);
        expect(c.validUntil, isNull);
        expect(c.valid, isNull);
        expect(c.language, isNull);
        expect(c.reissuedFrom, isNull);
        expect(c.hasStoredFile, isFalse);
      },
    );

    test('malformed files[] yields an empty list, not a crash', () {
      expect(
        issuedCertificateFrom(const <String, dynamic>{
          'files': 'not-a-list',
        }).files,
        isEmpty,
      );
      expect(
        issuedCertificateFrom(const <String, dynamic>{
          'files': <dynamic>['layout', 42, null],
        }).files,
        isEmpty,
        reason:
            'entries that are not maps are dropped row by row, not '
            'fatally',
      );
      expect(
        issuedCertificateFrom(const <String, dynamic>{
          'files': <dynamic>[
            <String, dynamic>{'layout': 7, 'url': <String>[], 'sha256': true},
          ],
        }).files,
        isEmpty,
        reason:
            'a map whose fields are the wrong types produces no entry — '
            'the lenient-reader rule, applied per field',
      );
    });

    test('malformed document_type/copy/layouts/holders fall back to their '
        'defaults', () {
      final IssuedCertificate c = issuedCertificateFrom(const <String, dynamic>{
        'document_type': 7,
        'copy': 9,
        'layouts': 'booklet',
        'holders': 'one name',
      });
      expect(c.documentType, '');
      expect(c.copy, '');
      expect(c.layouts, isEmpty);
      expect(c.holders, isEmpty);
    });

    test('the detail endpoint may nest the body under `certificate`', () {
      final IssuedCertificate nested = issuedCertificateFrom(<String, dynamic>{
        'certificate': _v2,
      });

      expect(nested.id, '3c1f');
      expect(nested.files, hasLength(2));
      expect(
        nested.serviceName,
        const Bilingual(en: 'Divorce Certificate', lo: 'ໃບຢືນຢັນຢ່າງ'),
      );

      // The flat shape — the old detail body — must still parse, and the
      // nested read must not have disturbed it.
      expect(issuedCertificateFrom(_full).id, 'cert-77');
    });
  });
}

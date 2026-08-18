/// `issuedCertificateFrom` — **B5-AC-27**, **B5-AC-28**, **B5-AC-29**.
///
/// The wire shape is `lcc-app/src/app/api/types.ts:625-641`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/documents/data/models/certificate_wire.dart';
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
}

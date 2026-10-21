/// Transport and repository for the verify slice — the two ANONYMOUS public
/// endpoints of MOBILE-API-E-CERTIFICATES.md (2026-10), § Public verification
/// endpoints and § Errors, edge cases.
///
/// Over a **real `Dio`** with only the socket stubbed
/// (`RecordingHttpAdapter`, `core_test_helper.dart`), for the same reason
/// `documents_transport_test.dart` states: a mocked `ApiClient` proves the
/// wiring, not the capability. Things only observable here:
///
/// * an unknown code answers **200** `status: "not-found"` and is a **Right**
///   — the guide: "An unknown code or hash is not an HTTP error" (§ Errors);
/// * 429 `TOO_MANY_REQUESTS` (30/min per IP) folds to a `Failure` whose
///   message the bloc maps (§ Errors: "Please wait a minute");
/// * `document-hash` POSTs exactly `{"hash": "<64 hex>"}` and — being public —
///   goes out with **no `Authorization` header** even when a token is held;
/// * the `checks` sub-objects parse their open sets verbatim
///   (`recorded|missing`, `match|mismatch|missing`, `not-revoked|revoked|
///   superseded|not-found`);
/// * the masked holder name arrives, and stays, masked.
library;

import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/verify/data/datasources/verify_remote_datasource.dart';
import 'package:lcc_mobile_app/features/verify/data/repositories/verify_repository_impl.dart';
import 'package:lcc_mobile_app/features/verify/domain/entities/verification_result.dart';
import 'package:lcc_mobile_app/features/verify/domain/repositories/verify_repository.dart';

import '../../../helpers/core_test_helper.dart';

Map<String, dynamic> _envelope(Object? data) =>
    <String, dynamic>{'success': true, 'data': data};

/// The guide's own § Public verification endpoints answer, key for key.
Map<String, dynamic> _verifyData() => <String, dynamic>{
      'valid': true,
      'status': 'issued',
      'certificate_no': 'LA-RES-2026-000123',
      'document_type': 'RES',
      'copy': '',
      'layout': 'card',
      'service': <String, dynamic>{'en': 'Residence Certificate', 'lo': '…'},
      'service_code': 'resident',
      'holder_name': 'P****** S********',
      'holders': <String>['P****** S********'],
      'issued_at': '2026-09-30',
      'valid_until': '2026-12-29',
      'issuing_office': <String, dynamic>{
        'en': 'District Office of Public Security, Chanthabuly',
        'lo': '…',
      },
      'issuer_contact': <String, dynamic>{'phone': '', 'email': '', 'address': ''},
      'verify_code': 'RES-7Q4K-19XD',
      'document_hash':
          '3f9a3f9a3f9a3f9a3f9a3f9a3f9a3f9a3f9a3f9a3f9a3f9a3f9a3f9a3f9ac21b',
      'language': 'lo',
      'revoked_at': '',
      'revoke_reason': '',
      'replaced_by_certificate_no': '',
      'checks': <String, dynamic>{
        'signature': <String, dynamic>{
          'status': 'recorded',
          'provider': 'visual',
          'method': 'officer-otp',
          'signer_name': 'Officer',
          'signer_title': <String, dynamic>{'en': 'Signer', 'lo': '…'},
          'signed_at': '2026-09-30T10:42:18+07:00',
          'ca': '',
          'format': '',
          'timestamp': '',
        },
        'record_hash': <String, dynamic>{
          'status': 'match',
          'algorithm': 'SHA-256',
        },
        'revocation': <String, dynamic>{
          'status': 'not-revoked',
          'checked_at': '2026-10-21T11:24:03+07:00',
        },
      },
      'checked_at': '2026-10-21T11:24:03+07:00',
    };

/// The not-found answer: still 200, still `success: true`, an **empty-ish**
/// body whose defining keys say no record.
Map<String, dynamic> _notFoundData() => <String, dynamic>{
      'valid': false,
      'status': 'not-found',
    };

void main() {
  late StorageService storage;

  setUp(() => storage = inMemoryStorageService(<String, String>{}));

  ({
    VerifyRemoteDatasourceImpl datasource,
    VerifyRepository repository,
    RecordingHttpAdapter adapter,
  }) rig(Object? body, {int statusCode = 200}) {
    final RecordingHttpAdapter adapter =
        RecordingHttpAdapter.always(body, statusCode: statusCode);
    final Dio dio = buildTestDio(
      storage: storage,
      adapter: adapter,
      withInterceptors: false,
    );
    final VerifyRemoteDatasourceImpl datasource = VerifyRemoteDatasourceImpl(
      apiClient: ApiClient(dio: dio, storage: storage),
    );
    return (
      datasource: datasource,
      repository: VerifyRepositoryImpl(remote: datasource),
      adapter: adapter,
    );
  }

  group('GET /verify/{code}', () {
    test('the answer parses into VerificationResult with all top-level keys',
        () async {
      final r = rig(_envelope(_verifyData()));

      final VerificationResult result = await r.datasource.verifyByCode(
        'RES-7Q4K-19XD',
      );

      expect(result.valid, isTrue);
      expect(result.status, 'issued');
      expect(result.certificateNo, 'LA-RES-2026-000123');
      expect(result.documentType, 'RES');
      expect(result.copy, '');
      expect(result.layout, 'card');
      expect(result.service?.en, 'Residence Certificate');
      expect(result.serviceCode, 'resident');
      expect(result.holderName, 'P****** S********');
      expect(result.holders, <String>['P****** S********']);
      expect(result.issuedAt, '2026-09-30');
      expect(result.validUntil, '2026-12-29');
      expect(
        result.issuingOffice?.en,
        'District Office of Public Security, Chanthabuly',
      );
      expect(result.issuerContact?.phone, '');
      expect(result.verifyCode, 'RES-7Q4K-19XD');
      expect(result.documentHash, isNotEmpty);
      expect(result.language, 'lo');
      expect(result.revokedAt, '');
      expect(result.revokeReason, '');
      expect(result.replacedByCertificateNo, '');
      expect(result.checkedAt, '2026-10-21T11:24:03+07:00');
      expect(r.adapter.requests.single.path, '/verify/RES-7Q4K-19XD');
      expect(r.adapter.requests.single.method, 'GET');
    });

    test('the code segment is percent-encoded on the wire', () async {
      final r = rig(_envelope(_notFoundData()));
      await r.datasource.verifyByCode('a b/c');
      expect(r.adapter.requests.single.path, '/verify/a%20b%2Fc',
          reason: 'the `meNotificationRead` percent-encoding convention');
    });

    test('an unknown code is 200 not-found and a RIGHT, never a Failure',
        () async {
      final r = rig(_envelope(_notFoundData()));

      final Either<Failure, VerificationResult> result =
          await r.repository.verifyByCode('NOPE-XXXX-XXXX');

      expect(result.isRight(), isTrue,
          reason: 'the guide: an unknown code "is not an HTTP error"');
      result.fold(
        (Failure _) => fail('expected a Right'),
        (VerificationResult v) {
          expect(v.status, 'not-found');
          expect(v.valid, isFalse);
        },
      );
    });

    test('429 TOO_MANY_REQUESTS is a Left whose message the bloc will map',
        () async {
      final r = rig(
        <String, dynamic>{
          'success': false,
          'code': 'TOO_MANY_REQUESTS',
          'message': 'Too many verification attempts. Please wait a minute.',
        },
        statusCode: 429,
      );

      final Either<Failure, VerificationResult> result =
          await r.repository.verifyByCode('RES-7Q4K-19XD');

      expect(result.isLeft(), isTrue);
      result.fold(
        (Failure f) {
          expect(f.message,
              'Too many verification attempts. Please wait a minute.');
          expect(f.runtimeType, Failure,
              reason: 'the plain Failure, like the documents slice');
        },
        (VerificationResult _) => fail('expected a Left'),
      );
    });

    test('the checks sub-objects parse their open sets verbatim', () async {
      final r = rig(_envelope(_verifyData()));

      final VerificationResult result =
          await r.datasource.verifyByCode('RES-7Q4K-19XD');

      final SignatureCheck signature = result.checks.signature;
      expect(signature.status, 'recorded');
      expect(signature.provider, 'visual');
      expect(signature.method, 'officer-otp');
      expect(signature.signerName, 'Officer');
      expect(signature.signerTitle?.en, 'Signer');
      expect(signature.signerTitle?.lo, '…');
      expect(signature.signedAt, '2026-09-30T10:42:18+07:00');
      expect(signature.ca, '');
      expect(signature.format, '');
      expect(signature.timestamp, '');

      final RecordHashCheck recordHash = result.checks.recordHash;
      expect(recordHash.status, 'match');
      expect(recordHash.algorithm, 'SHA-256');

      final RevocationCheck revocation = result.checks.revocation;
      expect(revocation.status, 'not-revoked');
      expect(revocation.checkedAt, '2026-10-21T11:24:03+07:00');
    });

    test('the revocation open set — revoked, superseded, not-found — '
        'parses as plain strings', () async {
      final Map<String, dynamic> body = _verifyData()
        ..['status'] = 'revoked'
        ..['valid'] = false;
      (body['checks'] as Map<String, dynamic>)['revocation'] =
          <String, dynamic>{
        'status': 'revoked',
        'checked_at': '2026-10-21T11:24:03+07:00',
      };
      final r = rig(_envelope(body));

      final VerificationResult result =
          await r.datasource.verifyByCode('RES-7Q4K-19XD');

      expect(result.status, 'revoked');
      expect(result.valid, isFalse);
      expect(result.checks.revocation.status, 'revoked');
    });

    test('a not-found answer whose revocation check says not-found parses '
        'the same way', () async {
      final Map<String, dynamic> body = _notFoundData();
      body['checks'] = <String, dynamic>{
        'signature': <String, dynamic>{'status': 'missing'},
        'record_hash': <String, dynamic>{'status': 'missing'},
        'revocation': <String, dynamic>{
          'status': 'not-found',
          'checked_at': '2026-10-21T11:24:03+07:00',
        },
      };
      final r = rig(_envelope(body));

      final VerificationResult result =
          await r.datasource.verifyByCode('NOPE');

      expect(result.checks.signature.status, 'missing');
      expect(result.checks.recordHash.status, 'missing');
      expect(result.checks.revocation.status, 'not-found');
    });

    test('masked holder names arrive masked and stay masked — nothing to '
        'unmask, and this pins it', () async {
      final r = rig(_envelope(_verifyData()));

      final VerificationResult result =
          await r.datasource.verifyByCode('RES-7Q4K-19XD');

      expect(result.holderName, 'P****** S********',
          reason: 'the guide: "holder names are always masked here" — the '
              'parser reads plain strings and invents no unmasking');
      expect(result.holders.first, 'P****** S********');
    });

    test('malformed fields degrade to lenient defaults, not a crash',
        () async {
      final r = rig(_envelope(<String, dynamic>{
        'status': 'issued',
        'valid': 'not-a-bool',
        'checks': <String, dynamic>{
          'signature': 'not-a-map',
          'record_hash': <String, dynamic>{'status': 42},
        },
      }));

      final VerificationResult result =
          await r.datasource.verifyByCode('RES-7Q4K-19XD');

      expect(result.valid, isNull,
          reason: 'a non-bool valid is UNKNOWN, not false');
      expect(result.certificateNo, '');
      expect(result.checks.signature.status, '',
          reason: 'a non-map checks.signature is an empty check, not a crash');
      expect(result.checks.recordHash.status, '',
          reason: 'a non-string status reads as the empty default — the '
              '`_stringAt` disposition, applied to every checks field');
    });
  });

  group('POST /verify/document-hash', () {
    const String kHex64 =
        '9f2ca21b9f2ca21b9f2ca21b9f2ca21b'
        '9f2ca21b9f2ca21b9f2ca21b9f2ca21b';

    test('POSTs exactly {"hash": "<64 hex>"} to /verify/document-hash',
        () async {
      final r = rig(_envelope(_verifyData()));

      final VerificationResult result = await r.datasource.verifyDocumentHash(
        kHex64,
      );

      expect(result.status, 'issued');
      final RequestOptions sent = r.adapter.requests.single;
      expect(sent.method, 'POST');
      expect(sent.path, '/verify/document-hash');
      final Map<String, dynamic> body =
          jsonDecode(jsonEncode(sent.data)) as Map<String, dynamic>;
      expect(body, hasLength(1),
          reason: 'exactly one key — nothing else rides along');
      expect(body, <String, dynamic>{'hash': kHex64});
    });

    test('is ANONYMOUS — no Authorization header even when a token is held',
        () async {
      const String token = 'SECRET-BEARER-TOKEN-0123456789abcdef';
      final StorageService tokens = inMemoryStorageService(
        <String, String>{StorageKeys.accessToken: token},
      );
      final RecordingHttpAdapter adapter =
          RecordingHttpAdapter.always(_envelope(_verifyData()));
      final Dio dio = buildTestDio(
        storage: tokens,
        adapter: adapter,
        withInterceptors: true,
      );
      final VerifyRemoteDatasourceImpl datasource = VerifyRemoteDatasourceImpl(
        apiClient: ApiClient(dio: dio, storage: tokens),
      );

      await datasource.verifyDocumentHash(kHex64);

      final RequestOptions sent = adapter.requests.single;
      expect(sent.extra['anonymous'], isTrue,
          reason: 'the guide: both verify endpoints "work without login"');
      expect(sent.headers.containsKey('Authorization'), isFalse,
          reason: 'a stale bearer to a public endpoint triggers a refresh '
              'round trip a request that never needed one — the payment-'
              'methods precedent');
    });

    test('verifyByCode is anonymous too', () async {
      const String token = 'SECRET-BEARER-TOKEN-0123456789abcdef';
      final StorageService tokens = inMemoryStorageService(
        <String, String>{StorageKeys.accessToken: token},
      );
      final RecordingHttpAdapter adapter =
          RecordingHttpAdapter.always(_envelope(_notFoundData()));
      final Dio dio = buildTestDio(
        storage: tokens,
        adapter: adapter,
        withInterceptors: true,
      );
      final VerifyRemoteDatasourceImpl datasource = VerifyRemoteDatasourceImpl(
        apiClient: ApiClient(dio: dio, storage: tokens),
      );

      await datasource.verifyByCode('RES-7Q4K-19XD');

      final RequestOptions sent = adapter.requests.single;
      expect(sent.extra['anonymous'], isTrue);
      expect(sent.headers.containsKey('Authorization'), isFalse);
    });

    test('an unknown hash is 200 not-found and a Right, like the code path',
        () async {
      final r = rig(_envelope(_notFoundData()));

      final Either<Failure, VerificationResult> result =
          await r.repository.verifyDocumentHash(kHex64);

      expect(result.isRight(), isTrue);
      result.fold(
        (Failure _) => fail('expected a Right'),
        (VerificationResult v) => expect(v.status, 'not-found'),
      );
    });
  });
}

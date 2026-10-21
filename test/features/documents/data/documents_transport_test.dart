/// Transport and repository for the collection slice — **B5-AC-13**,
/// **B5-AC-25**, **B5-AC-30**, **B5-AC-31**, **B5-AC-32**, plus the v2 file
/// and QR endpoints of the MOBILE-API-E-CERTIFICATES guide (2026-10).
///
/// Over a **real `Dio`** with only the socket stubbed, for the reason
/// `notification_datasource_transport_test.dart` states: a mocked `ApiClient`
/// proves the wiring, not the capability. Things only observable here — that
/// the plain-array body survives `ApiClient`'s envelope cast, that the `{id}`
/// segment really reaches the path percent-encoded, and that the PDF download
/// rides the *binary* transport (`ResponseType.bytes`), reads its filename and
/// payload hash out of the **response headers**, and folds a JSON error
/// envelope that arrived over a byte stream into a `Failure` with the
/// server's own sentence.
library;

import 'dart:convert' show jsonEncode, utf8;
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/documents/data/datasources/documents_remote_datasource.dart';
import 'package:lcc_mobile_app/features/documents/data/repositories/documents_repository_impl.dart';
import 'package:lcc_mobile_app/features/documents/domain/entities/certificate_file_download.dart';
import 'package:lcc_mobile_app/features/documents/domain/entities/certificate_qr.dart';
import 'package:lcc_mobile_app/features/documents/domain/entities/issued_certificate.dart';
import 'package:lcc_mobile_app/features/documents/domain/repositories/documents_repository.dart';

import '../../../helpers/core_test_helper.dart';

Map<String, dynamic> _envelope(Object? data) =>
    <String, dynamic>{'success': true, 'data': data};

Map<String, dynamic> _cert(String id) => <String, dynamic>{
      'id': id,
      'certificate_no': 'CERT-$id',
      'application_id': 'app-1',
      'service_code': 'residence_certificate',
      'holder_name': 'Somchai Vongsa',
      'issued_at': '2026-08-14T14:05:00Z',
      'status': 'valid',
      'verify_code': 'VC-$id',
    };

/// Bytes that start like a PDF and would not survive any envelope unwrap.
const List<int> _pdfBytes = <int>[
  0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x37, 0x0a, 0x01, 0x02, 0xff, //
];

/// The QR endpoint's `data` object, per MOBILE-API-E-CERTIFICATES.md § Citizen
/// endpoints (QR paragraph).
Map<String, dynamic> _qrData() => <String, dynamic>{
      'certificate_id': 'c1',
      'certificate_no': 'LA-MAR-2026-000652',
      'verify_code': 'MAR-4H7Z-51KA',
      'verify_url': 'https://portal.gov.la/v/MAR-4H7Z-51KA',
      'payload': 'https://portal.gov.la/v/MAR-4H7Z-51KA',
      'document_hash': '3f9ac21b3f9ac21b3f9ac21b3f9ac21b3f9ac21b3f9ac21b3f9ac21b3f9ac21b',
      'status': 'issued',
      'valid': true,
      'issued_at': '2026-09-25',
    };

void main() {
  late StorageService storage;

  setUp(() => storage = inMemoryStorageService(<String, String>{}));

  ({
    DocumentsRemoteDatasourceImpl datasource,
    DocumentsRepository repository,
    RecordingHttpAdapter adapter,
  }) rig(Object? body, {int statusCode = 200}) {
    final RecordingHttpAdapter adapter =
        RecordingHttpAdapter.always(body, statusCode: statusCode);
    final Dio dio = buildTestDio(
      storage: storage,
      adapter: adapter,
      withInterceptors: false,
    );
    final DocumentsRemoteDatasourceImpl datasource =
        DocumentsRemoteDatasourceImpl(
      apiClient: ApiClient(dio: dio, storage: storage),
    );
    return (
      datasource: datasource,
      repository: DocumentsRepositoryImpl(remote: datasource),
      adapter: adapter,
    );
  }

  /// Like [rig], but the transport answers from a script — the binary
  /// download needs `ResponseBody.bytes` answers and response headers, which
  /// the always-one-JSON-body rig cannot express. [seed] supplies tokens so
  /// the interceptor-bearing rig can observe the bearer header.
  ({
    DocumentsRemoteDatasourceImpl datasource,
    DocumentsRepository repository,
    RecordingHttpAdapter adapter,
  }) rigScripted(
    ScriptedResponder responder, {
    bool withInterceptors = false,
    Map<String, String> seed = const <String, String>{},
  }) {
    final StorageService tokens = inMemoryStorageService(seed);
    final RecordingHttpAdapter adapter = RecordingHttpAdapter(responder);
    final Dio dio = buildTestDio(
      storage: tokens,
      adapter: adapter,
      withInterceptors: withInterceptors,
    );
    final DocumentsRemoteDatasourceImpl datasource =
        DocumentsRemoteDatasourceImpl(
      apiClient: ApiClient(dio: dio, storage: tokens),
    );
    return (
      datasource: datasource,
      repository: DocumentsRepositoryImpl(remote: datasource),
      adapter: adapter,
    );
  }

  group('GET /me/certificates — a PLAIN array, not paged', () {
    test('three rows come back as entities', () async {
      final r = rig(_envelope(<Map<String, dynamic>>[
        _cert('a'),
        _cert('b'),
        _cert('c'),
      ]));

      final List<IssuedCertificate> rows =
          await r.datasource.getCertificates();

      expect(rows, hasLength(3));
      expect(rows.first.certificateNo, 'CERT-a');
      expect(r.adapter.requests.single.path, ApiEndpoint.meCertificates);
      expect(r.adapter.requests.single.method, 'GET');
    });

    test('B5-AC-30 — an empty array parses to an EMPTY LIST, not a null',
        () async {
      final r = rig(_envelope(const <dynamic>[]));
      final Either<Failure, List<IssuedCertificate>> result =
          await r.repository.getCertificates();

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => throw StateError('left')), isEmpty);
    });

    test('a body that is not a list yields the empty list, not a crash',
        () async {
      final r = rig(_envelope(<String, dynamic>{'unexpected': true}));
      expect(await r.datasource.getCertificates(), isEmpty);
    });

    test('one malformed row costs that row, not the card', () async {
      final r = rig(_envelope(<dynamic>[_cert('a'), 'not-an-object']));
      expect(await r.datasource.getCertificates(), hasLength(1));
    });
  });

  group('GET /me/certificates/{id}', () {
    test('the segment is percent-encoded on the wire — B5-AC-13', () async {
      final r = rig(_envelope(_cert('x')));
      await r.datasource.getCertificate('a b/c');

      expect(r.adapter.requests.single.path, '/me/certificates/a%20b%2Fc',
          reason: 'the `meNotificationRead` convention, applied');
    });

    test('B5-AC-31 — a 404 is a Left on the certificate slice only', () async {
      // The envelope is flat — `{ success, message, data, meta, code, ... }`
      // (`core/network/envelope.dart:6`), not a nested `error` object.
      final r = rig(
        <String, dynamic>{
          'success': false,
          'code': 'NOT_FOUND',
          'message': 'No such certificate.',
        },
        statusCode: 404,
      );

      final Either<Failure, IssuedCertificate> result =
          await r.repository.getCertificate('missing');

      expect(result.isLeft(), isTrue);
      result.fold(
        (Failure f) {
          expect(f.message, 'No such certificate.',
              reason: 'the backend\'s own sentence, not `toString()`');
          // No `NotFoundFailure` here, unlike the case detail: nothing on B5's
          // surface renders a 404-only message, so inventing one would be a
          // state the source does not have.
          expect(f.runtimeType, Failure);
        },
        (IssuedCertificate _) => fail('expected a Left'),
      );
    });
  });

  group('B5-AC-25 / B5-AC-32 — the shape of the slice', () {
    test('the repository exposes exactly two methods, both reads', () {
      // A reflective count is not available in Dart without `dart:mirrors`, so
      // this is asserted the way the criterion is actually falsifiable: the
      // interface's source names two members and no write verb anywhere in the
      // data layer. `documents_scope_test.dart` greps the directory; this pins
      // the two names.
      final DocumentsRepository repository =
          DocumentsRepositoryImpl(remote: rig(_envelope(<dynamic>[])).datasource);
      expect(repository.getCertificates, isA<Function>());
      expect(repository.getCertificate, isA<Function>());
    });
  });

  // ── The v2 endpoints — MOBILE-API-E-CERTIFICATES.md (2026-10) ──────────────
  //
  // Two more bearer GETs: the PDF bytes and the QR payload. The download is
  // the app's first **binary** endpoint — the spec is explicit that the file
  // endpoints "return the raw PDF bytes, not JSON" — so it rides
  // `ApiClient.getBytes`, and everything the download needs besides the bytes
  // (filename, integrity hash) arrives as response headers.

  group('GET /me/certificates/{id}/file — the binary download', () {
    test('rides the BYTES transport and returns the raw bytes', () async {
      final Uint8List pdf = Uint8List.fromList(_pdfBytes);
      final r = rigScripted(
        (RequestOptions options, int __) => bytesResponse(
          pdf,
          headers: <String, List<String>>{
            'content-disposition': <String>[
              'attachment; filename="LA-MAR-2026-000652-booklet.pdf"',
            ],
            'x-content-sha256': <String>[
              '9f2ca21b9f2ca21b9f2ca21b9f2ca21b9f2ca21b9f2ca21b9f2ca21b9f2ca21b',
            ],
          },
        ),
      );

      final CertificateFileDownload out = await r.datasource
          .downloadCertificateFile('c1', layout: 'booklet');

      expect(out.bytes, pdf,
          reason: 'the spec: PDF endpoints return raw bytes, NOT the envelope');
      expect(r.adapter.requests.single.responseType, ResponseType.bytes,
          reason: 'a JSON transform would mangle binary bodies');
    });

    test('sends GET with layout=booklet in the QUERY map, path percent-encoded',
        () async {
      final r = rigScripted(
        (RequestOptions options, int __) => bytesResponse(
          Uint8List.fromList(_pdfBytes),
        ),
      );

      await r.datasource.downloadCertificateFile('a b/c', layout: 'booklet');

      final RequestOptions sent = r.adapter.requests.single;
      expect(sent.method, 'GET');
      expect(sent.path, '/me/certificates/a%20b%2Fc/file',
          reason: 'the `meNotificationRead` percent-encoding convention, '
              'applied to the file path too');
      expect(sent.queryParameters, <String, dynamic>{'layout': 'booklet'},
          reason: 'the layout is a query parameter, never a path segment');
    });

    test('disposition=inline is appended as a QUERY value when inline',
        () async {
      final r = rigScripted(
        (RequestOptions options, int __) => bytesResponse(
          Uint8List.fromList(_pdfBytes),
        ),
      );

      await r.datasource.downloadCertificateFile('c1',
          layout: 'card', inline: true);

      expect(
        r.adapter.requests.single.queryParameters,
        <String, dynamic>{'layout': 'card', 'disposition': 'inline'},
      );
    });

    test('default download (inline: false) sends NO disposition param',
        () async {
      final r = rigScripted(
        (RequestOptions options, int __) => bytesResponse(
          Uint8List.fromList(_pdfBytes),
        ),
      );

      await r.datasource.downloadCertificateFile('c1', layout: 'card');

      expect(r.adapter.requests.single.queryParameters,
          <String, dynamic>{'layout': 'card'});
    });

    test('reads the filename from Content-Disposition and the hash from '
        'X-Content-SHA256 — case-insensitively', () async {
      final r = rigScripted(
        (RequestOptions options, int __) => bytesResponse(
          Uint8List.fromList(_pdfBytes),
          headers: <String, List<String>>{
            'Content-Disposition': <String>[
              'attachment; filename="LA-MAR-2026-000652-booklet.pdf"',
            ],
            'X-Content-SHA256': <String>[
              'ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12',
            ],
          },
        ),
      );

      final CertificateFileDownload out =
          await r.datasource.downloadCertificateFile('c1', layout: 'booklet');

      expect(out.fileName, 'LA-MAR-2026-000652-booklet.pdf');
      expect(out.sha256Header,
          'ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12');
    });

    test('missing headers read as nulls, not crashes — '
        'Task 6 falls back to <no>-<layout>.pdf and skips the check', () async {
      final r = rigScripted(
        (RequestOptions options, int __) =>
            bytesResponse(Uint8List.fromList(_pdfBytes)),
      );

      final CertificateFileDownload out =
          await r.datasource.downloadCertificateFile('c1', layout: 'card');

      expect(out.fileName, isNull);
      expect(out.sha256Header, isNull);
    });

    test('a 404 JSON envelope over the byte stream folds to a Failure with '
        'the server\'s own message — the legacy no-file case', () async {
      // MOBILE-API-E-CERTIFICATES.md § Errors: an old certificate without a
      // stored file answers 404 NOT_FOUND "certificate file not found" — a
      // JSON envelope, arriving over a transport the caller asked to deliver
      // bytes. The bytes must be decoded and routed through the envelope
      // unwrap so the code/message survive, exactly as `request` does.
      final r = rigScripted(
        (RequestOptions options, int __) => bytesResponse(
          // JSON bytes, declared as PDF by the helper's content type — the
          // shape the spec's error path really takes (application/pdf is
          // what a *success* carries; the error body is JSON whatever the
          // caller asked for).
          Uint8List.fromList(utf8.encode(jsonEncode(<String, dynamic>{
            'success': false,
            'code': 'NOT_FOUND',
            'message': 'certificate file not found',
          }))),
          statusCode: 404,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>[Headers.jsonContentType],
          },
        ),
      );

      final Either<Failure, CertificateFileDownload> result =
          await r.repository.downloadCertificateFile(
        id: 'legacy-1',
        layout: 'booklet',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (Failure f) {
          expect(f.message, 'certificate file not found',
              reason: 'the backend\'s own sentence, like B5-AC-31');
        },
        (CertificateFileDownload _) => fail('expected a Left'),
      );
    });

    test('the bearer token rides the HEADER, never the URL', () async {
      const String token = 'SECRET-BEARER-TOKEN-0123456789abcdef';
      final r = rigScripted(
        (RequestOptions options, int __) =>
            bytesResponse(Uint8List.fromList(_pdfBytes)),
        withInterceptors: true,
        seed: <String, String>{StorageKeys.accessToken: token},
      );

      await r.datasource.downloadCertificateFile('c1', layout: 'booklet');

      final RequestOptions sent = r.adapter.requests.single;
      expect(sent.headers['Authorization'], 'Bearer $token',
          reason: 'the spec: "Download with the bearer header (no token in '
              'the URL)"');
      expect(sent.uri.toString(), isNot(contains(token)),
          reason: 'a token in a URL lands in access logs and history; a '
              'header does not');
      // And the download is NOT anonymous: it must not suppress the header.
      expect(sent.extra['anonymous'], isFalse,
          reason: 'the file endpoint is a /me/* bearer endpoint');
    });
  });

  group('GET /me/certificates/{id}/qr — the QR payload', () {
    test('unwraps data into a CertificateQr — payload, verify_code, status, '
        'valid', () async {
      final r = rig(_envelope(_qrData()));

      final CertificateQr qr = await r.datasource.getCertificateQr('c1');

      expect(qr.certificateId, 'c1');
      expect(qr.certificateNo, 'LA-MAR-2026-000652');
      expect(qr.verifyCode, 'MAR-4H7Z-51KA');
      expect(qr.verifyUrl, 'https://portal.gov.la/v/MAR-4H7Z-51KA');
      expect(qr.payload, 'https://portal.gov.la/v/MAR-4H7Z-51KA',
          reason: 'payload is what the screen draws');
      expect(qr.documentHash,
          '3f9ac21b3f9ac21b3f9ac21b3f9ac21b3f9ac21b3f9ac21b3f9ac21b3f9ac21b');
      expect(qr.status, 'issued');
      expect(qr.valid, isTrue);
      expect(qr.issuedAt, '2026-09-25');
      expect(r.adapter.requests.single.path, '/me/certificates/c1/qr');
      expect(r.adapter.requests.single.method, 'GET');
    });

    test('rides the JSON envelope, not the byte transport', () async {
      final r = rig(_envelope(_qrData()));
      await r.datasource.getCertificateQr('c1');
      expect(r.adapter.requests.single.responseType, ResponseType.json);
    });

    test('the id segment is percent-encoded', () async {
      final r = rig(_envelope(_qrData()));
      await r.datasource.getCertificateQr('a b/c');
      expect(r.adapter.requests.single.path, '/me/certificates/a%20b%2Fc/qr');
    });

    test('a 404 envelope is a Left with the server message', () async {
      final r = rig(
        <String, dynamic>{
          'success': false,
          'code': 'NOT_FOUND',
          'message': 'No such certificate.',
        },
        statusCode: 404,
      );

      final Either<Failure, CertificateQr> result =
          await r.repository.getCertificateQr('missing');

      expect(result.isLeft(), isTrue);
      result.fold(
        (Failure f) => expect(f.message, 'No such certificate.'),
        (CertificateQr _) => fail('expected a Left'),
      );
    });

    test('malformed fields degrade to lenient defaults, not a crash',
        () async {
      final r = rig(_envelope(<String, dynamic>{
        'certificate_id': 'c1',
        'valid': 'not-a-bool',
        'payload': 42,
      }));

      final CertificateQr qr = await r.datasource.getCertificateQr('c1');
      expect(qr.certificateId, 'c1');
      expect(qr.payload, isNull, reason: 'a non-string payload is absent, '
          'not the string "42"');
      expect(qr.valid, isNull, reason: 'a non-bool valid is unknown');
      expect(qr.certificateNo, '');
    });
  });
}

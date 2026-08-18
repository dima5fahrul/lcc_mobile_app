/// Transport and repository for the collection slice — **B5-AC-13**,
/// **B5-AC-25**, **B5-AC-30**, **B5-AC-31**, **B5-AC-32**.
///
/// Over a **real `Dio`** with only the socket stubbed, for the reason
/// `notification_datasource_transport_test.dart` states: a mocked `ApiClient`
/// proves the wiring, not the capability. Two things can only be observed here
/// — that the plain-array body survives `ApiClient`'s envelope cast, and that
/// the `{id}` segment really reaches the path percent-encoded.
library;

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/documents/data/datasources/documents_remote_datasource.dart';
import 'package:lcc_mobile_app/features/documents/data/repositories/documents_repository_impl.dart';
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
}

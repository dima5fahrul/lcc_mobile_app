/// Fixtures and a fake repository for B5.
///
/// ## The fixtures are DECLARED SYNTHETIC (`B5-AC-91`, specs.md § 6.13)
///
/// They are hand-built from `lcc-app/src/app/api/types.ts:625-641`, **not**
/// recorded from the live API. `GET /me/certificates` is authenticated and no
/// token was available to this dispatch (specs.md NV-1, NV-2), so no B5 surface
/// has ever been observed rendering live data. That limitation is restated in
/// `qa-report.md` rather than absorbed; presenting these as recordings would be
/// a FAIL of `B5-AC-91`.
///
/// § 6.13 requires six arrangements and [kCertificatesFixture] carries the
/// first five, with the sixth (an **empty** list) available as
/// `const <IssuedCertificate>[]`:
///
/// 1. matched by `application_id` — [certApplicationMatch]
/// 2. matched only by `certificate_id` — [certIdMatch]
/// 3. matched only by `reference_no` — [certReferenceMatch]
/// 4. `verify_code: ""` — [certNoVerifyCode]
/// 5. no `qr_payload` — [certNoQrPayload]
/// 6. an empty list, which drives the "not available yet" note
library;

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/documents/domain/entities/certificate_file_download.dart';
import 'package:lcc_mobile_app/features/documents/domain/entities/certificate_qr.dart';
import 'package:lcc_mobile_app/features/documents/domain/entities/issued_certificate.dart';
import 'package:lcc_mobile_app/features/documents/domain/repositories/documents_repository.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';

/// One certificate, every field defaulted to something plausible so a test
/// overrides only what it is about.
IssuedCertificate certFixture({
  String id = 'cert-1',
  String certificateNo = 'CERT-0001',
  String? applicationId,
  String? referenceNo,
  String serviceCode = 'residence_certificate',
  Bilingual? serviceName =
      const Bilingual(en: 'Residence Certificate', lo: 'ໃບຢັ້ງຢືນທີ່ຢູ່'),
  String holderName = 'Somchai Vongsa',
  String? uin = '1-2345-67890-12-3',
  String issuedAt = '2026-08-14T14:05:00Z',
  String? issuedByName = 'Chanthabouly District Office',
  String status = 'valid',
  String verifyCode = 'LCC-2026-000123',
  String? verifyUrl = 'https://lcc.gov.la/v/LCC-2026-000123',
  String? qrPayload = 'LCC:CERT-0001',
  String? fileUrl,
  String? documentHash,
}) =>
    IssuedCertificate(
      id: id,
      certificateNo: certificateNo,
      applicationId: applicationId,
      referenceNo: referenceNo,
      serviceCode: serviceCode,
      serviceName: serviceName,
      holderName: holderName,
      uin: uin,
      issuedAt: issuedAt,
      issuedByName: issuedByName,
      status: status,
      verifyCode: verifyCode,
      verifyUrl: verifyUrl,
      qrPayload: qrPayload,
      fileUrl: fileUrl,
      documentHash: documentHash,
    );

/// Arrangement 1 — the first precedence clause (`HistoryDetailPage.tsx:152`).
final IssuedCertificate certApplicationMatch = certFixture(
  id: 'cert-app',
  certificateNo: 'CERT-APP',
  applicationId: 'app-1',
);

/// Arrangement 2 — the second clause (`:153`): matched by `certificate_id`
/// only, so its `application_id` deliberately does **not** point at the case.
final IssuedCertificate certIdMatch = certFixture(
  id: 'cert-id',
  certificateNo: 'CERT-ID',
  applicationId: 'someone-else',
);

/// Arrangement 3 — the third clause (`:154`).
final IssuedCertificate certReferenceMatch = certFixture(
  id: 'cert-ref',
  certificateNo: 'CERT-REF',
  applicationId: 'someone-else',
  referenceNo: 'REF-0001',
);

/// Arrangement 4 — `verify_code: ""`, which the card's truthiness gate
/// (`:475`) must treat as **absent** (`B5-AC-84`).
final IssuedCertificate certNoVerifyCode = certFixture(
  id: 'cert-novc',
  certificateNo: 'CERT-NOVC',
  applicationId: 'app-1',
  verifyCode: '',
);

/// Arrangement 5 — no `qr_payload` (`:482`).
final IssuedCertificate certNoQrPayload = certFixture(
  id: 'cert-noqr',
  certificateNo: 'CERT-NOQR',
  applicationId: 'app-1',
  qrPayload: null,
);

/// A list holding the three matchable arrangements, in an order that lets a
/// test see which clause won.
List<IssuedCertificate> kCertificatesFixture = <IssuedCertificate>[
  certReferenceMatch,
  certIdMatch,
  certApplicationMatch,
];

/// A recording fake — the same instrument `FakeApplicationRepository` is, and
/// for the same reason: most of B5's criteria are claims about the **traffic**
/// (`B5-AC-35` … `B5-AC-42`), which is not visible in a widget tree.
class FakeDocumentsRepository implements DocumentsRepository {
  /// One entry per `getCertificates` call.
  int listCalls = 0;

  /// The ids passed to `getCertificate`, in order — so a test can assert
  /// *which* certificate was asked for, not merely how many times.
  final List<String> oneCalls = <String>[];

  Either<Failure, List<IssuedCertificate>> listAnswer =
      Right<Failure, List<IssuedCertificate>>(const <IssuedCertificate>[]);

  Either<Failure, IssuedCertificate> oneAnswer =
      Left<Failure, IssuedCertificate>(const Failure('no fixture'));

  /// Delay applied to both answers. Set it when a test needs to observe
  /// `certificateLoading`.
  Duration latency = Duration.zero;

  /// Holds the **list** answer open until [releaseList] is called, so a test
  /// can assert what is on screen while the list is genuinely in flight
  /// (`B5-AC-49`).
  bool gateList = false;
  final Completer<void> _listGate = Completer<void>();

  void releaseList() {
    if (!_listGate.isCompleted) _listGate.complete();
  }

  /// The `application_id` filter each call carried — review I-2, 2026-10-22.
  /// Recorded rather than ignored so a test can assert the BLoC asks the
  /// endpoint for *one application's* certificates, which is the behaviour the
  /// three divorce documents depend on.
  final List<String?> listFilters = <String?>[];

  @override
  Future<Either<Failure, List<IssuedCertificate>>> getCertificates({
    String? applicationId,
  }) async {
    listCalls++;
    listFilters.add(applicationId);
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (gateList) await _listGate.future;
    return listAnswer;
  }

  @override
  Future<Either<Failure, IssuedCertificate>> getCertificate(String id) async {
    oneCalls.add(id);
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    return oneAnswer;
  }

  @override
  Future<Either<Failure, CertificateQr>> getCertificateQr(String id) async =>
      Left<Failure, CertificateQr>(const Failure('no QR fixture'));

  @override
  Future<Either<Failure, CertificateFileDownload>> downloadCertificateFile({
    required String id,
    required String layout,
    bool inline = false,
  }) async =>
      Left<Failure, CertificateFileDownload>(const Failure('no file fixture'));
}

/// The collection slice's repository — the two B5 reads plus the two v2
/// sub-path reads the 2026-10 MOBILE-API-E-CERTIFICATES guide added. All
/// four are reads; there is **no write path** in this feature, which is also
/// why the fidelity instrument reports Tier 0 as *N/A — no write path*
/// rather than PASS (§ 6.13).
///
/// The two additions supersede the old "exactly two methods" ruling the same
/// way the endpoint constants do (see `api_endpoint.dart`'s v2 block): the
/// 2026-10 guide gives the file and QR sub-paths live contracts and product
/// requirements, where B5's adjudication had refused them as dead.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/certificate_file_download.dart';
import '../entities/certificate_qr.dart';
import '../entities/issued_certificate.dart';

abstract class DocumentsRepository {
  /// `me.certificates()` — `endpoints.ts:131`, consumed at
  /// `HistoryDetailPage.tsx:149`. A **plain array**, not paged.
  Future<Either<Failure, List<IssuedCertificate>>> getCertificates();

  /// `me.certificate(id)` — `endpoints.ts:132`, consumed at `:157`.
  Future<Either<Failure, IssuedCertificate>> getCertificate(String id);

  /// `GET /me/certificates/{id}/qr` — the QR payload fixed at issue; drawn
  /// on screen from `payload` (2026-10 guide, § Citizen endpoints, QR).
  Future<Either<Failure, CertificateQr>> getCertificateQr(String id);

  /// `GET /me/certificates/{id}/file?layout=…` — the raw PDF bytes with the
  /// `Content-Disposition` filename and `X-Content-SHA256` integrity header
  /// (2026-10 guide, § Citizen endpoints, File). [inline] views rather than
  /// downloads. A legacy certificate without a stored file answers 404 and
  /// folds to a `Failure` with the server's own sentence.
  Future<Either<Failure, CertificateFileDownload>> downloadCertificateFile({
    required String id,
    required String layout,
    bool inline = false,
  });
}

/// The use cases behind the third query — the two B5 reads plus the two v2
/// sub-path reads (file, QR) the 2026-10 MOBILE-API-E-CERTIFICATES guide
/// added. They are deliberately thin: the three-clause precedence that picks
/// *which* certificate a case belongs to (`HistoryDetailPage.tsx:150-160`)
/// is **state**, not a fetch, and lives in `HistoryDetailBloc` where the
/// source puts it — in hooks beside the two queries, not inside either of
/// them (specs.md § 6.6).
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/certificate_file_download.dart';
import '../entities/certificate_qr.dart';
import '../entities/issued_certificate.dart';
import '../repositories/documents_repository.dart';

/// `me.certificates()` — the list.
///
/// **Takes an optional `application_id` since 2026-10-22 (review I-2).** The
/// source's call (`:149`) passed only the abort signal, and the parameter type
/// stays [NoParams]-compatible for it: `GetCertificatesParams()` with no
/// argument sends no query at all, which is byte-identical to the unfiltered
/// request. The filter exists because the spec's § Divorce says so — *"one
/// application yields three certificates … List them with `GET
/// /me/certificates?application_id=…`"* — and § Citizen endpoints, List
/// declares `application_id` among the endpoint's optional query parameters.
class GetCertificates
    implements UseCase<List<IssuedCertificate>, GetCertificatesParams> {
  const GetCertificates({required this.repository});

  final DocumentsRepository repository;

  @override
  Future<Either<Failure, List<IssuedCertificate>>> call(
    GetCertificatesParams params,
  ) =>
      repository.getCertificates(applicationId: params.applicationId);
}

/// [GetCertificates]' parameters — one optional filter, nothing else.
///
/// A dedicated params type rather than `NoParams` so the filter is expressible
/// at all, and **nullable rather than defaulted to `''`** so "no filter" and
/// "filter on the empty string" cannot be confused: the datasource sends the
/// query key only when this is a non-empty string.
class GetCertificatesParams extends Equatable {
  const GetCertificatesParams({this.applicationId});

  /// `?application_id=…` — all certificates of one application, which for a
  /// divorce is the joint card plus booklets A and B.
  final String? applicationId;

  @override
  List<Object?> get props => <Object?>[applicationId];
}

class GetCertificateParams extends Equatable {
  const GetCertificateParams(this.id);

  /// `detail.certificate_id` — `:157`. A server identifier the citizen never
  /// types.
  final String id;

  @override
  List<Object?> get props => <Object?>[id];
}

/// `me.certificate(id)` — the single fetch, fired only when all four of the
/// source's conjuncts hold (`:158`, `B5-AC-39`). The conjunction itself is the
/// BLoC's; this use case is unconditional once called.
class GetCertificate
    implements UseCase<IssuedCertificate, GetCertificateParams> {
  const GetCertificate({required this.repository});

  final DocumentsRepository repository;

  @override
  Future<Either<Failure, IssuedCertificate>> call(
    GetCertificateParams params,
  ) =>
      repository.getCertificate(params.id);
}

/// `GET /me/certificates/{id}/qr` — the QR payload the screen draws, fixed
/// at issue (2026-10 guide, § Citizen endpoints, QR paragraph).
class GetCertificateQr
    implements UseCase<CertificateQr, GetCertificateParams> {
  const GetCertificateQr({required this.repository});

  final DocumentsRepository repository;

  @override
  Future<Either<Failure, CertificateQr>> call(GetCertificateParams params) =>
      repository.getCertificateQr(params.id);
}

/// `GET /me/certificates/{id}/file` — the raw PDF bytes plus the
/// `Content-Disposition` filename and `X-Content-SHA256` integrity header.
/// Returns the download record Task 6 consumes verbatim:
/// `CertificateFileDownload(bytes, fileName?, sha256Header?)`.
class DownloadCertificateFile
    implements UseCase<CertificateFileDownload, DownloadCertificateFileParams> {
  const DownloadCertificateFile({required this.repository});

  final DocumentsRepository repository;

  @override
  Future<Either<Failure, CertificateFileDownload>> call(
    DownloadCertificateFileParams params,
  ) =>
      repository.downloadCertificateFile(
        id: params.id,
        layout: params.layout,
        inline: params.inline,
      );
}

/// The file endpoint's parameters — the certificate row's id, which layout
/// (`card` | `booklet`, from `files[]`), and whether to view rather than
/// download (`disposition=inline`).
class DownloadCertificateFileParams extends Equatable {
  const DownloadCertificateFileParams({
    required this.id,
    required this.layout,
    this.inline = false,
  });

  final String id;
  final String layout;
  final bool inline;

  @override
  List<Object?> get props => <Object?>[id, layout, inline];
}

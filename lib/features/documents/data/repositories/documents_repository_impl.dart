/// Folds the two GETs into `Either<Failure, …>`.
///
/// One `_guard`, both call sites — the shape
/// `notification_repository_impl.dart` uses, with one refinement taken from
/// `application_repository_impl.dart:41-48`: an [ApiException] folds to its own
/// `message`, not to `toString()`. `ApiException.toString()` is
/// `ApiException(404, NOT_FOUND, …)`, which is a debug string and not something
/// a citizen should ever read.
///
/// **No `NotFoundFailure` mapping here, and that is a measurement rather than
/// an omission.** `application_repository_impl.dart` distinguishes 404 because
/// `HistoryDetailPage.tsx:201` branches on `error?.isNotFound` and prints
/// different copy. Nothing on B5's surface does: the certificate card's only
/// failure rendering is `!certificate && !certListQuery.loading` (`:486`), one
/// note for every reason a certificate is missing. Inventing a second, 404-only
/// sentence would be a message the source does not render (`ssd.md` § 11.2 L-10
/// corollary (b)).
///
/// A failure here reaches the state as **the certificate slice's** failure and
/// nothing else — the case detail and the timeline keep their data, because the
/// source runs three independent `useQuery`s (`B5-AC-31`).
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/certificate_file_download.dart';
import '../../domain/entities/certificate_qr.dart';
import '../../domain/entities/issued_certificate.dart';
import '../../domain/repositories/documents_repository.dart';
import '../datasources/documents_remote_datasource.dart';

class DocumentsRepositoryImpl implements DocumentsRepository {
  const DocumentsRepositoryImpl({required this.remote});

  final DocumentsRemoteDatasource remote;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() read) async {
    try {
      return Right<Failure, T>(await read());
    } on ApiException catch (e) {
      return Left<Failure, T>(Failure(e.message));
    } catch (e) {
      // Not an `ApiException` — a parse or a programming error, which has no
      // citizen-facing sentence of its own.
      return Left<Failure, T>(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<IssuedCertificate>>> getCertificates() =>
      _guard(remote.getCertificates);

  @override
  Future<Either<Failure, IssuedCertificate>> getCertificate(String id) =>
      _guard(() => remote.getCertificate(id));

  @override
  Future<Either<Failure, CertificateQr>> getCertificateQr(String id) =>
      _guard(() => remote.getCertificateQr(id));

  @override
  Future<Either<Failure, CertificateFileDownload>> downloadCertificateFile({
    required String id,
    required String layout,
    bool inline = false,
  }) => _guard(
    () => remote.downloadCertificateFile(id, layout: layout, inline: inline),
  );
}

/// The two use cases behind the third query — one per surviving endpoint.
///
/// They are deliberately thin: the three-clause precedence that picks *which*
/// certificate a case belongs to (`HistoryDetailPage.tsx:150-160`) is **state**,
/// not a fetch, and lives in `HistoryDetailBloc` where the source puts it — in
/// hooks beside the two queries, not inside either of them (specs.md § 6.6).
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/issued_certificate.dart';
import '../repositories/documents_repository.dart';

/// `me.certificates()` — the list. Takes no parameters: the source's call
/// (`:149`) passes only the abort signal.
class GetCertificates
    implements UseCase<List<IssuedCertificate>, NoParams> {
  const GetCertificates({required this.repository});

  final DocumentsRepository repository;

  @override
  Future<Either<Failure, List<IssuedCertificate>>> call(NoParams params) =>
      repository.getCertificates();
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

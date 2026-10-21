/// The verify feature's two use cases — thin, like every other slice's: the
/// code-extraction gate and the status→screen routing live elsewhere (the
/// scanner and Task 4's bloc), not here.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/verification_result.dart';
import '../repositories/verify_repository.dart';

/// `GET /verify/{code}` — the scan/typed path. Takes the code as a bare
/// `String` (the `GetApplication` shape): the caller has already run it
/// through `certificateCodeFromScanned`, which is the only producer of a
/// non-null code.
class VerifyByCode implements UseCase<VerificationResult, String> {
  const VerifyByCode({required this.repository});

  final VerifyRepository repository;

  @override
  Future<Either<Failure, VerificationResult>> call(String code) =>
      repository.verifyByCode(code);
}

/// `POST /verify/document-hash` — the PDF check path (Task 7's consumer).
/// Takes the 64-hex SHA-256 as a bare `String`.
class VerifyDocumentHash implements UseCase<VerificationResult, String> {
  const VerifyDocumentHash({required this.repository});

  final VerifyRepository repository;

  @override
  Future<Either<Failure, VerificationResult>> call(String hash) =>
      repository.verifyDocumentHash(hash);
}

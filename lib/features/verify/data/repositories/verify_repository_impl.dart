/// Folds the two public verification calls into `Either<Failure, …>`.
///
/// One `_guard`, both call sites — the `documents_repository_impl.dart`
/// shape verbatim, including its refinement: an [ApiException] folds to its
/// own `message` (the server's sentence, e.g. 429's "Too many verification
/// attempts"), never `toString()`.
///
/// **`not-found` never reaches this guard as a failure.** The guide is
/// explicit (§ Errors, edge cases): an unknown code or hash answers 200
/// `status: "not-found"` — a normal parse, a Right. What DOES fold left is
/// everything the transport genuinely failed at: 429 rate limiting (the bloc
/// maps its message to "Please wait a minute"), network errors, non-2xx.
///
/// No `NotFoundFailure` is invented here, for the same measured reason the
/// documents slice records: nothing below Task 4 renders a 404-only sentence
/// — the not-found *status* is a payload field with its own screen, not an
/// HTTP state.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/verification_result.dart';
import '../../domain/repositories/verify_repository.dart';
import '../datasources/verify_remote_datasource.dart';

class VerifyRepositoryImpl implements VerifyRepository {
  const VerifyRepositoryImpl({required this.remote});

  final VerifyRemoteDatasource remote;

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
  Future<Either<Failure, VerificationResult>> verifyByCode(String code) =>
      _guard(() => remote.verifyByCode(code));

  @override
  Future<Either<Failure, VerificationResult>> verifyDocumentHash(String hash) =>
      _guard(() => remote.verifyDocumentHash(hash));
}

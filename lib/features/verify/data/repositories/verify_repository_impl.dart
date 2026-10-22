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
/// everything the transport genuinely failed at: 429 rate limiting, network
/// errors, non-2xx.
///
/// **429 is the one status that folds to a typed leaf** —
/// `TooManyRequestsFailure` (`verify_failures.dart`), the
/// `application_failures.dart` pattern. The guide gives it a distinct screen
/// ("Please wait a minute; never retry in a loop", § Errors), and Task 4's
/// bloc can only route to that screen if the Left's *type* says so — a plain
/// `Failure` carries no status to branch on. Every other non-2xx stays the
/// plain `Failure`, because nothing renders one sentence per status. **The
/// typed-leaf disposition updated 2026-10-21 for Task 4**: the transport
/// test's original claim ("the plain Failure, like the documents slice")
/// held while the fold had no consumer; the bloc's five-state contract now
/// consumes it.
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
import '../../domain/verify_failures.dart';
import '../datasources/verify_remote_datasource.dart';

class VerifyRepositoryImpl implements VerifyRepository {
  const VerifyRepositoryImpl({required this.remote});

  final VerifyRemoteDatasource remote;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() read) async {
    try {
      return Right<Failure, T>(await read());
    } on ApiException catch (e) {
      if (e.status == 429 || e.code == ApiCode.tooManyRequests) {
        return Left<Failure, T>(TooManyRequestsFailure(e.message));
      }
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

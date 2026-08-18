/// [PrerequisiteRecordRepository] over the one datasource.
///
/// Thin on purpose: no cache, no de-duplication, no retry — see the interface
/// for why each is absent rather than forgotten.
///
/// ## Failure mapping matches the feature's existing half
///
/// `ApiException` → `Failure(e.message)`, i.e. the **API's own sentence**,
/// because that is what the picker renders beneath its generic line
/// (`MarriageCertificatePage.tsx:1214` shows `records.error.message`).
/// Anything else → `Failure(e.toString())`. Identical to
/// `reference_repository_impl.dart:81-86`; a second convention in one feature
/// would mean two different strings reaching one widget.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/prerequisite_record.dart';
import '../../domain/repositories/prerequisite_record_repository.dart';
import '../datasources/prerequisite_record_remote_datasource.dart';

class PrerequisiteRecordRepositoryImpl implements PrerequisiteRecordRepository {
  const PrerequisiteRecordRepositoryImpl({required this.remote});

  final PrerequisiteRecordRemoteDatasource remote;

  @override
  Future<Either<Failure, PrerequisiteRecordPage>> search({
    required String kind,
    required String query,
  }) async {
    try {
      return Right<Failure, PrerequisiteRecordPage>(
        await remote.search(kind: kind, query: query),
      );
    } on ApiException catch (e) {
      return Left<Failure, PrerequisiteRecordPage>(Failure(e.message));
    } catch (e) {
      return Left<Failure, PrerequisiteRecordPage>(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PrerequisiteRecord>> byRecordNo(
    String recordNo,
  ) async {
    try {
      return Right<Failure, PrerequisiteRecord>(
        await remote.byRecordNo(recordNo),
      );
    } on ApiException catch (e) {
      return Left<Failure, PrerequisiteRecord>(Failure(e.message));
    } catch (e) {
      return Left<Failure, PrerequisiteRecord>(Failure(e.toString()));
    }
  }
}

/// The FR-11 record picker's two use cases.
///
/// Two classes rather than one with a mode flag, matching the two distinct
/// wire calls and the two distinct call sites: the debounced list read
/// (`MarriageCertificatePage.tsx:753-757`) and the single-record read fired on
/// tap (`:758`, `:810`).
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/prerequisite_record.dart';
import '../repositories/prerequisite_record_repository.dart';

/// `GET /prerequisite-records?kind=…&search=…&per_page=20`.
class GetPrerequisiteRecords {
  const GetPrerequisiteRecords({required this.repository});

  final PrerequisiteRecordRepository repository;

  Future<Either<Failure, PrerequisiteRecordPage>> call({
    required String kind,
    required String query,
  }) =>
      repository.search(kind: kind, query: query);
}

/// `GET /prerequisite-records/{no}`.
class GetPrerequisiteRecord {
  const GetPrerequisiteRecord({required this.repository});

  final PrerequisiteRecordRepository repository;

  Future<Either<Failure, PrerequisiteRecord>> call(String recordNo) =>
      repository.byRecordNo(recordNo);
}

/// The two `kind` values the two pages send.
///
/// `types.ts:238` also admits `"marriage-certificate"`; **no page requests it**
/// (Marriage `:754`, Divorce `:660`), so it has no constant here. Adding one
/// would be the first half of porting a call the source does not make.
class PrerequisiteRecordKind {
  const PrerequisiteRecordKind._();

  /// Marriage — `MarriageCertificatePage.tsx:754`.
  static const String betrothal = 'betrothal';

  /// Divorce — `DivorceCertificatePage.tsx:660`.
  static const String mediation = 'mediation';
}

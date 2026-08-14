/// `ApplicationRepositoryImpl` — try the datasource, fold every throw into a
/// [Failure].
///
/// `NewsRepositoryImpl`'s shape, **without** its 404 special case. News needs
/// one because `NewsDetailPage.tsx:117` routes a missing article to the *empty*
/// state instead of the *error* state; B7a's list has no such branch — a failed
/// `/applications` is one error panel with one retry (`HistoryPage.tsx:250-264`),
/// whatever the status code. B7b's detail page **does** distinguish not-found
/// (`:200-238`, `B7-AC-54`) and adds its own failure type additively when it
/// lands; adding it here speculatively would be a branch with no reader.
///
/// [Failure.message] carries the exception text for logs. Unlike the web —
/// which prints `list.error.message`, the backend's own sentence
/// (`HistoryPage.tsx:141`) — the Flutter error panel renders fixed bilingual
/// copy, which is the disposition B2a took for `ServicePage` and which every
/// page in this tree has followed since. Recorded as the standing divergence it
/// is rather than re-litigated per batch.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/application_page.dart';
import '../../domain/entities/case_status.dart';
import '../../domain/entities/status_pipeline.dart';
import '../../domain/repositories/application_repository.dart';
import '../datasources/application_remote_datasource.dart';

class ApplicationRepositoryImpl implements ApplicationRepository {
  const ApplicationRepositoryImpl({required this.remote});

  final ApplicationRemoteDatasource remote;

  /// One `try`/`catch`, both call sites — written once so a later reader
  /// cannot find one that folds and one that throws.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() read) async {
    try {
      return Right<Failure, T>(await read());
    } on ApiException catch (e) {
      return Left<Failure, T>(Failure(e.toString()));
    } catch (e) {
      return Left<Failure, T>(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ApplicationPage>> listApplications({
    required int page,
    required int perPage,
    List<CaseStatus>? statuses,
    String? search,
  }) =>
      _guard(() => remote.listApplications(
            page: page,
            perPage: perPage,
            statuses: statuses,
            search: search,
          ));

  /// A `Left` here is **not** an error the citizen sees. `statusCatalogue.ts:67-69`
  /// swallows the failure and keeps the seeded pipeline; the swallow lives in
  /// `HistoryBloc`, not here, so the distinction between "the catalogue
  /// answered" and "it did not" stays available to a caller that wants it
  /// (`B7-AC-27`).
  @override
  Future<Either<Failure, StatusPipeline>> getStatusPipeline() =>
      _guard(remote.getStatusPipeline);
}

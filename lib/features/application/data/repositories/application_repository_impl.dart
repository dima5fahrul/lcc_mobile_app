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
import '../../domain/application_failures.dart';
import '../../domain/entities/application_detail.dart';
import '../../domain/entities/application_page.dart';
import '../../domain/entities/case_status.dart';
import '../../domain/entities/case_timeline.dart';
import '../../domain/entities/picked_attachment.dart';
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

  /// The detail's fold — **B7b, and it is not `_guard`**.
  ///
  /// Two differences from the list's, both required by
  /// `HistoryDetailPage.tsx:200-238` and neither of them applicable above:
  ///
  /// 1. **A 404 becomes [NotFoundFailure].** `:201` branches on
  ///    `error?.isNotFound` and prints different copy (`B7-AC-54`). The list
  ///    has no such branch — one error panel, whatever the status
  ///    (`HistoryPage.tsx:250-264`) — which is why B7a's `_guard` has no reason
  ///    to know about 404 and this one does.
  /// 2. **The message is `e.message`, the API's own sentence — not
  ///    `e.toString()`.** `:205` renders `detailQuery.error?.message`.
  ///    `ApiException.toString()` is `ApiException(500, INTERNAL_ERROR, …)`, a
  ///    Dart type dump; putting that on a citizen's screen is not what the
  ///    source does.
  ///
  /// **`_guard` above still folds `e.toString()`, and B7b did not change it.**
  /// That is a measured inconsistency between the two paths, recorded in B7b's
  /// hand-back for the architect: `B7-AC-35` pins what the list's error panel
  /// renders, so rewriting that string is a behaviour change to a criterion
  /// B7a already discharged, in a file B7b was asked to extend and not to
  /// re-litigate.
  Future<Either<Failure, T>> _guardDetail<T>(Future<T> Function() read) async {
    try {
      return Right<Failure, T>(await read());
    } on ApiException catch (e) {
      return Left<Failure, T>(
        e.isNotFound ? NotFoundFailure(e.message) : Failure(e.message),
      );
    } catch (e) {
      // Not an `ApiException` — a parse or a programming error, which has no
      // citizen-facing sentence of its own. `toString()` is all there is, and
      // it lands in the generic branch, never the not-found one.
      return Left<Failure, T>(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ApplicationDetail>> getApplication(String id) =>
      _guardDetail(() => remote.getApplication(id));

  @override
  Future<Either<Failure, CaseTimeline>> getApplicationTimeline(String id) =>
      _guardDetail(() => remote.getApplicationTimeline(id));

  /// A `Left` here is **not** an error the citizen sees. `statusCatalogue.ts:67-69`
  /// swallows the failure and keeps the seeded pipeline; the swallow lives in
  /// `HistoryBloc`, not here, so the distinction between "the catalogue
  /// answered" and "it did not" stays available to a caller that wants it
  /// (`B7-AC-27`).
  @override
  Future<Either<Failure, StatusPipeline>> getStatusPipeline() =>
      _guard(remote.getStatusPipeline);

  // ── The write half (F1) ────────────────────────────────────────────────────
  //
  // **`_guard`, not `_guardDetail`, and the choice is the observable.**
  // `_guardDetail` folds a 404 into `NotFoundFailure` because the detail page
  // prints different copy for a case that does not exist (`B7-AC-54`). A write
  // has no such branch: `ResidentCertificatePage.tsx:570-580` reads only
  // `err.isValidation` and `err.fields`, and everything that is not a 422 —
  // 404 included — falls through to the same red banner carrying the API's own
  // sentence. Routing a write 404 to `NotFoundFailure` would invent a state the
  // page cannot render.
  //
  // **The 422 is not decoded here either**, and that is the same reasoning
  // pointing the other way: `ApiException` already carries the field map, the
  // page is what owns `FIELD_STEP` and the jump, and a repository that
  // pre-digested it would have to know which step owns which key — which is
  // per-certificate data that does not belong in a shared feature
  // (`F1-AC-63`).

  /// The write half's fold — **neither `_guard` nor `_guardDetail`**.
  ///
  /// It keeps the `ApiException` so the certificate wizard can ask
  /// `isValidation` and read `fieldMap()` (`ResidentCertificatePage.tsx:573-574`,
  /// `F1-AC-63`), and it carries `e.message` — the API's own sentence, which is
  /// what `:711` renders — rather than `_guard`'s `e.toString()`.
  ///
  /// A **404 does not become [NotFoundFailure] here**, unlike `_guardDetail`:
  /// the submit path has no not-found branch, and `:570-580` folds everything
  /// that is not a 422 into the same red banner.
  Future<Either<Failure, T>> _guardWrite<T>(Future<T> Function() write) async {
    try {
      return Right<Failure, T>(await write());
    } on ApiException catch (e) {
      return Left<Failure, T>(ApiFailure(e, e.message));
    } catch (e) {
      return Left<Failure, T>(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ApplicationDetail>> createApplication(
    Map<String, Object?> envelope,
  ) =>
      _guardWrite(() => remote.createApplication(envelope));

  @override
  Future<Either<Failure, ApplicationDetail>> updateApplication(
    String id,
    Map<String, Object?> envelope,
  ) =>
      _guardWrite(() => remote.updateApplication(id, envelope));

  @override
  Future<Either<Failure, Unit>> addAttachment(
    String id, {
    required PickedAttachment file,
    required String slot,
    required String kind,
    String? label,
  }) =>
      _guardWrite(() async {
        await remote.addAttachment(
          id,
          file: file,
          slot: slot,
          kind: kind,
          label: label,
        );
        return unit;
      });

  @override
  Future<Either<Failure, ApplicationDetail>> submitApplication(String id) =>
      _guardWrite(() => remote.submitApplication(id));
}

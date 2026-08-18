/// `ServiceRepositoryImpl` — the catalogue's only repository impl.
///
/// Follows the flutter-boilerplate pattern (try the remote datasource, on
/// exception return `Left(Failure(...))`), **without** the session feature's
/// `ApiException`-rethrow deviation. That deviation exists because
/// `SessionBloc` has to branch on 401/403 to clear tokens; the catalogue is
/// anonymous, has no token to clear, and every failure mode it has — offline,
/// 500, malformed row — collapses to the same user-visible outcome: the
/// error-with-retry state (§ 6.6). A typed error the BLoC would only flatten
/// back into one message buys nothing and would give the page a second failure
/// path to get wrong.
///
/// [Failure.message] carries the exception's text for logs and debugging. On
/// `ServicePage` it is deliberately **not** what the page renders:
/// `ServicePage.tsx:227-232` shows a fixed bilingual sentence ("Could not load
/// the services." / "Check your connection and try again.") and never the
/// server's words, so porting the message to that screen would be a fidelity
/// divergence *and* a leak of backend detail into a public surface.
///
/// ## The `ApiException` arm, and why it exists (2026-08-18, F3 MAJOR-1)
///
/// `ServicePage` is no longer this repository's only consumer. Four certificate
/// pages read `GetServices` through `certificateServiceReader`
/// (`certificates_bloc_injection.dart`) and **render `Failure.message`
/// directly** — Resident `:130`, Birth `:90`, Death `:82`, and, since F3's
/// option-(b) fee wiring, Marriage `marriage_steps.dart:723-727` and Divorce
/// `divorce_steps.dart:741-744`.
///
/// With one bare `catch`, an `ApiException` reached those five screens as
/// `ApiException.toString()` — `ApiException(500, INTERNAL_ERROR, {sentence},
/// requestId: 7f3c…, 2 field(s))` — putting an internal log-correlation token
/// and a validation-response shape in front of a citizen. That is the defect
/// F3's `security-review.md` MAJOR-1 records.
///
/// **The source draws the line where this arm now draws it.** `ApiError extends
/// Error` with `super(message)` (`client.ts:61-68`), so the web's
/// `quote.error.message` is the backend's sentence **alone** — no status, no
/// code, no `requestId`. `MarriageCertificatePage.tsx:1591` renders exactly
/// that. Answering `e.message` is therefore the faithful port, not a
/// hardening: it makes the Dart value equal the JS value the render site was
/// written against.
///
/// The bare `catch` is kept beneath it for everything that is not an
/// `ApiException` (a `DioException`, a `FormatException` on a malformed row).
/// Those carry no server-supplied sentence to prefer, and their text is what
/// the log needs. Same two-arm shape as
/// `prerequisite_record_repository_impl.dart:38-42`.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/service.dart';
import '../../domain/entities/service_category.dart';
import '../../domain/repositories/service_repository.dart';
import '../datasources/service_remote_datasource.dart';
import '../models/service_category_model.dart';
import '../models/service_model.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  const ServiceRepositoryImpl({required this.remote});

  final ServiceRemoteDatasource remote;

  @override
  Future<Either<Failure, List<ServiceCategory>>> getCategories() async {
    try {
      final List<ServiceCategoryModel> rows = await remote.getCategories();
      return Right<Failure, List<ServiceCategory>>(
        rows
            .map((ServiceCategoryModel m) => m.toEntity())
            .toList(growable: false),
      );
    } on ApiException catch (e) {
      return Left<Failure, List<ServiceCategory>>(Failure(e.message));
    } catch (e) {
      return Left<Failure, List<ServiceCategory>>(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Service>>> getServices({
    String? search,
    String? category,
  }) async {
    try {
      final List<ServiceModel> rows =
          await remote.getServices(search: search, category: category);
      return Right<Failure, List<Service>>(
        rows.map((ServiceModel m) => m.toEntity()).toList(growable: false),
      );
    } on ApiException catch (e) {
      return Left<Failure, List<Service>>(Failure(e.message));
    } catch (e) {
      return Left<Failure, List<Service>>(Failure(e.toString()));
    }
  }
}

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
/// [Failure.message] carries the exception's text for logs and debugging. It is
/// deliberately **not** what the page renders: `ServicePage.tsx:227-232` shows
/// a fixed bilingual sentence ("Could not load the services." / "Check your
/// connection and try again.") and never the server's words, so porting the
/// message to the screen would be a fidelity divergence *and* a leak of
/// backend detail into a public surface.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
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
    } catch (e) {
      return Left<Failure, List<Service>>(Failure(e.toString()));
    }
  }
}

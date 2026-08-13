/// The service catalogue's repository contract.
///
/// Two reads, both anonymous (`endpoints.ts:168-171` marks them
/// `anonymous: true` — the catalogue is public and a signed-out citizen browses
/// the full 43).
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/service.dart';
import '../entities/service_category.dart';

abstract class ServiceRepository {
  /// `GET /service-categories`.
  Future<Either<Failure, List<ServiceCategory>>> getCategories();

  /// `GET /services`, optionally narrowed.
  ///
  /// **Both filters are the server's job** (`ServicePage.tsx:301-310`: *"search
  /// and category are handed to the API, not filtered here"*). Passing them
  /// through rather than filtering the already-fetched list is not an
  /// optimisation — a client-side `contains` would match different rows than
  /// the API's matcher and the two surfaces would disagree about what "cert"
  /// finds.
  Future<Either<Failure, List<Service>>> getServices({
    String? search,
    String? category,
  });
}

/// `GetServices` — `GET /services`, optionally narrowed by search and category.
///
/// ## The one place a C-5 filter would go
///
/// SSD § 13 C-5 records that if the product ever decides to show only the
/// services a citizen can actually apply for, the change is "C-2's two call
/// sites plus **one filter in `GetServices`**". That filter is not here and
/// must not be added speculatively — B2 implements C-4 (render everything,
/// dead tap). This comment is the marker so the next person does not have to
/// re-derive where it belongs.
///
/// No `active` filter and no client re-sort either (SSD § 11.2 L-3/L-4): the
/// API returns `sort_order` and the web applies none of its own. Server order.
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/service.dart';
import '../repositories/service_repository.dart';

/// The two filters the catalogue page hands to the API.
///
/// Both nullable and both meaning "do not narrow on this". An empty string is
/// normalised to null at construction: `ApiClient._buildQuery` already drops
/// empty values, but relying on that would make `search: ''` and `search: null`
/// two spellings of one request that only happen to behave alike.
class GetServicesParams extends Equatable {
  GetServicesParams({String? search, String? category})
      : search = (search == null || search.isEmpty) ? null : search,
        category = (category == null || category.isEmpty) ? null : category;

  /// Free-text match, applied by the API.
  final String? search;

  /// A [ServiceCategory.code], applied by the API.
  final String? category;

  /// "Fetch the whole catalogue" — what the page's per-category counts read.
  static final GetServicesParams all = GetServicesParams();

  @override
  List<Object?> get props => <Object?>[search, category];
}

class GetServices implements UseCase<List<Service>, GetServicesParams> {
  const GetServices({required this.repository});

  final ServiceRepository repository;

  @override
  Future<Either<Failure, List<Service>>> call(GetServicesParams params) =>
      repository.getServices(
        search: params.search,
        category: params.category,
      );
}

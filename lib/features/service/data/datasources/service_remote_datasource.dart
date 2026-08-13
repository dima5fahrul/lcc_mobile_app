/// `ServiceRemoteDatasource` — the catalogue's HTTP boundary.
///
/// Ported from `lcc-app/src/app/api/endpoints.ts:167-171` (`catalog.categories`,
/// `catalog.services`). Both are `anonymous: true`: the catalogue is public and
/// a signed-out citizen sees all 43 services. Sending the bearer token anyway
/// would work, but it would also mean a stale token triggered a refresh round
/// trip on a page that never needed one.
///
/// `ApiClient.request<T>` returns the envelope's `data` cast to `T`. These two
/// endpoints return arrays, so `T` is `List<dynamic>` and the row-by-row parse
/// happens here — the wire-map → typed-model boundary stays inside the
/// datasource rather than scattering `fromJson` across repositories.
library;

import '../../../../core/constant/api_endpoint.dart';
import '../../../../core/network/api_client.dart';
import '../models/service_category_model.dart';
import '../models/service_model.dart';

abstract class ServiceRemoteDatasource {
  /// `GET /service-categories` (anonymous).
  Future<List<ServiceCategoryModel>> getCategories();

  /// `GET /services` (anonymous), optionally narrowed by [search] / [category].
  Future<List<ServiceModel>> getServices({String? search, String? category});
}

class ServiceRemoteDatasourceImpl implements ServiceRemoteDatasource {
  const ServiceRemoteDatasourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<ServiceCategoryModel>> getCategories() async {
    // `get<dynamic>`, NOT `get<List<dynamic>>`. ApiClient._send<T> forwards T to
    // Dio, which casts the decoded ENVELOPE — an object — to T. Asking for a List
    // therefore throws before _unwrap ever sees the payload, and the throw surfaces
    // as ApiException(0, NETWORK_ERROR, 'Cannot reach the server'), so it reads as
    // an outage rather than a bug. Every test here mocks ApiClient, so the generic
    // argument never met a transport until B2b probed it against buildTestDio.
    final dynamic raw = await apiClient.get<dynamic>(
      ApiEndpoint.serviceCategories,
      anonymous: true,
    );
    final List<dynamic> rows = raw as List<dynamic>;
    return rows
        .whereType<Map<String, dynamic>>()
        .map(ServiceCategoryModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<ServiceModel>> getServices({
    String? search,
    String? category,
  }) async {
    // Nulls are dropped by `ApiClient._buildQuery`, so "no filter" really does
    // send no parameter rather than `?search=`.
    // `get<dynamic>`, NOT `get<List<dynamic>>`. ApiClient._send<T> forwards T to
    // Dio, which casts the decoded ENVELOPE — an object — to T. Asking for a List
    // therefore throws before _unwrap ever sees the payload, and the throw surfaces
    // as ApiException(0, NETWORK_ERROR, 'Cannot reach the server'), so it reads as
    // an outage rather than a bug. Every test here mocks ApiClient, so the generic
    // argument never met a transport until B2b probed it against buildTestDio.
    final dynamic raw = await apiClient.get<dynamic>(
      ApiEndpoint.services,
      query: <String, dynamic>{'search': search, 'category': category},
      anonymous: true,
    );
    final List<dynamic> rows = raw as List<dynamic>;
    return rows
        .whereType<Map<String, dynamic>>()
        .map(ServiceModel.fromJson)
        .toList(growable: false);
  }
}

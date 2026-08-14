/// The three location reads — `endpoints.ts:215-252`, all `anonymous: true`.
///
/// | Method | Path | Shape |
/// |---|---|---|
/// | [provinces] | `GET /locations/provinces` | plain array |
/// | [districts] | `GET /locations/provinces/{id}/districts` | plain array |
/// | [villages] | `GET /locations/districts/{id}/villages` | **paged**, 200/page |
///
/// ## L-7 — villages page to the end, and the loop is here
///
/// `endpoints.ts:284-292`:
///
/// ```ts
/// const first = await locations.villages(districtId, signal);
/// const rows = [...first.data];
/// for (let page = 2; page <= first.meta.total_pages; page++) {
///   const next = await locations.villages(districtId, signal, { page });
///   rows.push(...next.data);
/// }
/// ```
///
/// Serially, from page 2, inclusive of `total_pages`. Reproduced literally: the
/// select filters as you type over the rows it holds, so one page of 200 hides
/// every village past that and answers "no match" for one that exists
/// (`formFields.tsx:435-437`).
///
/// [PagingMode.firstPageOnly] stops after the first request — the page-local
/// divergence `MarriageCertificatePage.tsx:296-302` has, frozen into the
/// contract now so F3 has a CFI-legal way to express it (specs.md § 6.9 item 1).
///
/// ## One inherited constraint, recorded rather than worked around
///
/// `ApiClient.requestPaged` takes no `anonymous` flag, so the paged village
/// read goes out through the normal interceptor chain and carries a token when
/// one exists — where `endpoints.ts:248` marks it `anonymous: true`. Widening
/// `requestPaged` means editing `lib/core/network/**`, which is an automatic
/// `F0-AC-66` FAIL. The same constraint already applies to B2c's paged
/// `/news` read, which is also anonymous, so this follows the tree's existing
/// precedent rather than inventing a second answer.
library;

import '../../../../core/constant/api_endpoint.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/lookup_key.dart';
import '../../domain/entities/lookup_option.dart';
import '../models/reference_wire.dart';

/// `endpoints.ts:204` — `const VILLAGE_PAGE = 200;` *"The API's own default is
/// 200."*
const int kVillagePageSize = 200;

abstract class LocationRemoteDatasource {
  Future<List<LookupOption>> provinces();

  Future<List<LookupOption>> districts(String provinceId);

  Future<List<LookupOption>> villages(
    String districtId, {
    PagingMode paging = PagingMode.all,
  });
}

class LocationRemoteDatasourceImpl implements LocationRemoteDatasource {
  const LocationRemoteDatasourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<LookupOption>> provinces() => _plainList(
        ApiEndpoint.locationProvinces,
      );

  @override
  Future<List<LookupOption>> districts(String provinceId) => _plainList(
        ApiEndpoint.locationDistricts(provinceId),
      );

  Future<List<LookupOption>> _plainList(String path) async {
    final dynamic rows = await apiClient.get<dynamic>(path, anonymous: true);
    if (rows is! List) return const <LookupOption>[];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(locationRowFrom)
        .toList(growable: false);
  }

  @override
  Future<List<LookupOption>> villages(
    String districtId, {
    PagingMode paging = PagingMode.all,
  }) async {
    final String path = ApiEndpoint.locationVillages(districtId);

    final Paged<dynamic> first = await apiClient.requestPaged<dynamic>(
      path,
      query: <String, dynamic>{'per_page': kVillagePageSize},
    );

    final List<LookupOption> rows = <LookupOption>[
      ..._rowsOf(first),
    ];

    if (paging == PagingMode.firstPageOnly) return rows;

    // `for (let page = 2; page <= first.meta.total_pages; page++)` — serial,
    // and inclusive of the last page.
    for (int page = 2; page <= first.meta.totalPages; page++) {
      final Paged<dynamic> next = await apiClient.requestPaged<dynamic>(
        path,
        query: <String, dynamic>{'page': page, 'per_page': kVillagePageSize},
      );
      rows.addAll(_rowsOf(next));
    }

    return List<LookupOption>.unmodifiable(rows);
  }

  List<LookupOption> _rowsOf(Paged<dynamic> page) => page.data
      .whereType<Map<String, dynamic>>()
      .map(locationRowFrom)
      .toList(growable: false);
}

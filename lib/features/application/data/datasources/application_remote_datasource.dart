/// `ApplicationRemoteDatasource` — the application feature's HTTP boundary.
///
/// Two calls, and the **auth posture differs between them**, which is the one
/// thing this file exists to get right:
///
/// | Method | Path | Auth | Source |
/// |---|---|---|---|
/// | [listApplications] | `GET /applications` | Bearer | `endpoints.ts:321` |
/// | [getStatusPipeline] | `GET /status-catalogue` | **anonymous** | `endpoints.ts:192` |
///
/// Sending a bearer to `/status-catalogue` would work and would still be
/// wrong: a stale token on a public endpoint triggers a refresh round trip on
/// a request that never needed one (`news_remote_datasource.dart`'s note).
/// `B7-AC-22` asserts the absence of the header on the outgoing request rather
/// than the presence of `anonymous: true` in this file — a flag is a
/// configuration value, and the Capability Rule wants the capability.
///
/// ## The repeated `status` parameter (Finding H, `B7-AC-16`)
///
/// `client.ts:188-190` emits `status=a&status=b` for an array. Dio's default
/// `ListFormat` is `multi`, which emits the same shape, so **this port is
/// already correct and the risk is that it silently stops being**. The
/// architect's own prediction that it was broken was wrong (§ 10), and the
/// disposition that survived is a pin, not a fix: `api_client.dart:351-352`'s
/// doc comment describes a list-flattening mechanism `_buildQuery` does not
/// actually contain, so nothing in `lib/**` documents the real behaviour
/// truthfully and nothing asserted it at all.
/// `test/features/application/data/application_datasource_transport_test.dart`
/// asserts the built URI over a real `Dio`, and asserts it is **not**
/// `status[]=`.
///
/// ## Why the reads ask for `dynamic`
///
/// `news_remote_datasource.dart` records the measurement in full: `ApiClient`
/// forwards `T` to `_dio.get<T>()`, Dio casts the decoded **envelope** to `T`,
/// and the envelope is a map. `get<List<dynamic>>` therefore throws before
/// `_unwrap` runs and surfaces as `NETWORK_ERROR` — a served request reported
/// as being offline. One rule, no exceptions: ask for `dynamic`, check here.
library;

import '../../../../core/constant/api_endpoint.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/application_page.dart';
import '../../domain/entities/case_status.dart';
import '../../domain/entities/status_pipeline.dart';
import '../models/application_wire.dart';

abstract class ApplicationRemoteDatasource {
  /// `GET /applications?page=&per_page=[&status=…][&search=]`.
  ///
  /// [statuses] `null` sends **no** `status` key at all — the `all` chip
  /// (`FILTER_STATUSES.all = undefined`, `HistoryPage.tsx:50`). An empty list
  /// would take the array branch and is never what the source sends, so it is
  /// treated as `null` here too.
  ///
  /// [search] must already be trimmed; `''` and `null` both send nothing
  /// (`client.ts:187` skips `undefined`, `null` **and** the empty string).
  Future<ApplicationPage> listApplications({
    required int page,
    required int perPage,
    List<CaseStatus>? statuses,
    String? search,
  });

  /// `GET /status-catalogue` — anonymous.
  Future<StatusPipeline> getStatusPipeline();
}

class ApplicationRemoteDatasourceImpl implements ApplicationRemoteDatasource {
  const ApplicationRemoteDatasourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<ApplicationPage> listApplications({
    required int page,
    required int perPage,
    List<CaseStatus>? statuses,
    String? search,
  }) async {
    final Paged<dynamic> result = await apiClient.requestPaged<dynamic>(
      ApiEndpoint.applications,
      query: <String, dynamic>{
        'page': page,
        'per_page': perPage,
        // The wire strings, not the Dart enum names: `under-review`, not
        // `underReview`. `CaseStatus.wire` is the only place that mapping
        // lives.
        if (statuses != null && statuses.isNotEmpty)
          'status': statuses
              .map((CaseStatus s) => s.wire)
              .toList(growable: false),
        // `ApiClient._buildQuery` drops `null` and `''`, so both spellings of
        // "no search" behave as `client.ts:187` does. Passed through rather
        // than branched on here so there is exactly one skip rule.
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final PageMeta meta = result.meta;
    return ApplicationPage(
      // `whereType` rather than a cast: one malformed row costs that row, not
      // the page (`news_remote_datasource.dart`'s `_rows`).
      rows: result.data
          .whereType<Map<String, dynamic>>()
          .map(applicationRowFrom)
          .toList(growable: false),
      page: meta.page,
      totalPages: meta.totalPages,
      // `meta.total`, and **not** `rows.length`. The four stat tiles ask for
      // one row and read this number (`HistoryPage.tsx:103-104`), so a page
      // result that derived `total` from its own row count would make every
      // tile read `1`. `B7-AC-24` pins it with a fixture whose `meta.total` is
      // 42 and whose `data` has one row.
      total: meta.total,
      hasNext: meta.hasNext,
      hasPrev: meta.hasPrev,
    );
  }

  @override
  Future<StatusPipeline> getStatusPipeline() async {
    final dynamic body = await apiClient.get<dynamic>(
      ApiEndpoint.statusCatalogue,
      anonymous: true,
    );
    // A non-object body is not a catalogue. The seed is returned rather than
    // thrown, because `statusCatalogue.ts:60-61` treats "nothing usable came
    // back" and "the fetch failed" identically — the bar keeps its five
    // stages either way (`B7-AC-26`).
    if (body is! Map<String, dynamic>) return StatusPipeline.seeded;
    return statusPipelineFrom(body);
  }
}

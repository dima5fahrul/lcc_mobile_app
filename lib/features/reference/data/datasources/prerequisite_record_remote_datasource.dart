/// The two `/prerequisite-records` reads — `endpoints.ts:194-198`.
///
/// | Method | Path | Shape |
/// |---|---|---|
/// | [search] | `GET /prerequisite-records` | **paged** — `{data, meta}` |
/// | [byRecordNo] | `GET /prerequisite-records/{no}` | a single object |
///
/// ## Neither is `anonymous`
///
/// `endpoints.ts:194-198` carries no `anonymous: true`, unlike every other
/// endpoint in this feature (`:186`, `:216`, `:223`, `:248`). These two go out
/// through the normal interceptor chain and carry the citizen's token — which
/// is the whole reason the list is empty: it is scoped to records linked to
/// *that* account (`manifest-authenticated.md`:230-232).
///
/// ## `dynamic`, not a typed generic
///
/// The rule `reference_list_remote_datasource.dart` records at length:
/// `ApiClient` forwards `T` to `_dio.get<T>()`, Dio casts the **envelope** to
/// `T`, and the envelope is a map. Asking for a `List` or a typed model makes
/// Dio attempt the cast, throw, and surface a parsed-fine response as
/// `NETWORK_ERROR`.
///
/// ## The only reachable state is EMPTY, and the port does not pretend otherwise
///
/// `data: []` on every account available to this programme, for all three valid
/// `kind` values. This datasource is therefore **ported but never executed
/// against a non-empty response** — its parser is unit-tested against fixtures,
/// and `qa-report.md` records that no execution evidence exists for the loaded
/// state. That is a weaker claim than "the picker works" and is not reported as
/// the stronger one.
library;

import '../../../../core/constant/api_endpoint.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/prerequisite_record.dart';
import '../models/prerequisite_record_wire.dart';

/// `MarriageCertificatePage.tsx:754` / `DivorceCertificatePage.tsx:660` —
/// `per_page: 20`. **Not** the villages' 200: a different endpoint with a
/// different call site, and normalising the two would be inventing a number
/// neither page sends.
const int kPrerequisiteRecordPageSize = 20;

abstract class PrerequisiteRecordRemoteDatasource {
  /// `catalog.prerequisiteRecords({kind, search, per_page})`.
  ///
  /// [query] is handed to `ApiClient` verbatim; **an empty one is then DROPPED
  /// before the URL is built**, because `client.ts:187` is
  /// `if (value === undefined || value === null || value === "") continue;`
  /// and `ApiClient._buildQuery` (`api_client.dart:356-364`) reproduces it.
  ///
  /// So the first query a picker makes — `useDebounced("")` yields `""` —
  /// carries `kind` and `per_page` only. That is measured, not assumed: this
  /// doc said the opposite until the test that checks it was written.
  Future<PrerequisiteRecordPage> search({
    required String kind,
    required String query,
  });

  /// `catalog.prerequisiteRecord(recordNo)`.
  Future<PrerequisiteRecord> byRecordNo(String recordNo);
}

class PrerequisiteRecordRemoteDatasourceImpl
    implements PrerequisiteRecordRemoteDatasource {
  const PrerequisiteRecordRemoteDatasourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<PrerequisiteRecordPage> search({
    required String kind,
    required String query,
  }) async {
    final Paged<dynamic> page = await apiClient.requestPaged<dynamic>(
      ApiEndpoint.prerequisiteRecords,
      query: <String, dynamic>{
        'kind': kind,
        'search': query,
        'per_page': kPrerequisiteRecordPageSize,
      },
    );

    return PrerequisiteRecordPage(
      data: page.data
          .whereType<Map<String, dynamic>>()
          .map(prerequisiteRecordFrom)
          .toList(growable: false),
      total: page.meta.total,
    );
  }

  @override
  Future<PrerequisiteRecord> byRecordNo(String recordNo) async {
    final dynamic payload = await apiClient.get<dynamic>(
      ApiEndpoint.prerequisiteRecord(recordNo),
    );
    if (payload is! Map<String, dynamic>) {
      // A shape the wire should not produce. Throwing keeps it a failure the
      // repository maps to a `Failure` the picker renders, rather than a
      // silently blank record that would pre-fill the couple with empties.
      throw const FormatException(
        'GET /prerequisite-records/{no} did not answer an object',
      );
    }
    return prerequisiteRecordFrom(payload);
  }
}

/// `GET /reference-lists/{type}` — `endpoints.ts:185-186`, `anonymous: true`.
///
/// One call, and the whole of L-2's reference-list half.
///
/// ## `dynamic`, not `List<dynamic>`
///
/// The same rule `news_remote_datasource.dart` records at length: `ApiClient`
/// forwards `T` to `_dio.get<T>()`, Dio casts the **envelope** to `T`, and the
/// envelope is a map. Asking for `List<dynamic>` makes Dio attempt
/// `Map → List`, throw, and surface as `NETWORK_ERROR` — a request that reached
/// the server and parsed fine, reported to the citizen as being offline. Ask
/// for `dynamic` and cast on the value that really is one.
///
/// Here it matters twice over, because this endpoint's `data` is
/// `{type, count, items}` on the live API and a bare array in the branch
/// `formFields.tsx:237` still carries. `referenceRowsFrom` handles both; Dio
/// must not be asked to pick one in advance.
library;

import '../../../../core/constant/api_endpoint.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/lookup_option.dart';
import '../models/reference_wire.dart';

abstract class ReferenceListRemoteDatasource {
  Future<List<LookupOption>> list(String type);
}

class ReferenceListRemoteDatasourceImpl implements ReferenceListRemoteDatasource {
  const ReferenceListRemoteDatasourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<LookupOption>> list(String type) async {
    final dynamic payload = await apiClient.get<dynamic>(
      ApiEndpoint.referenceList(type),
      anonymous: true,
    );
    return referenceRowsFrom(payload)
        .map(referenceItemFrom)
        .toList(growable: false);
  }
}

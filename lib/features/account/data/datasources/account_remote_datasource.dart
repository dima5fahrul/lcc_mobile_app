/// `AccountRemoteDatasource` — the account surface's HTTP boundary, three
/// calls.
///
/// ## Two envelope shapes, and they are not interchangeable
///
/// - `GET`/`PUT /me/preferences` answer an **object**
///   (`endpoints.ts:122-123`), read through `get`/`put<dynamic>`.
/// - `GET /me/documents` answers a **plain array** (`endpoints.ts:115`) — it is
///   `api.get<CitizenDocument[]>` (i.e. `api.get` of a *list* type), **not**
///   `api.paged`, so it does not go through `ApiClient.requestPaged` and there
///   is no `meta` block to discard.
///
/// ## Why the reads ask for `dynamic` and cast here
///
/// `help_remote_datasource.dart`'s header has the full account, and it is not
/// style: `ApiClient._send<T>` forwards `T` to Dio, Dio casts the decoded body
/// to `T`, and the decoded body is always the **envelope map**.
/// `T = List<dynamic>` therefore throws before `_unwrap` runs and surfaces as
/// `NETWORK_ERROR` — a request that reached the server, reported as offline.
/// One rule, no exception to remember.
///
/// ## `PUT` is not `PATCH`
///
/// `apiClient.put`, and the body is [preferencesBody]'s whole object. The
/// `patch` verb exists on the client and using it here would be a one-character
/// divergence that no tier except Tier 0 can see (specs.md § 6.9 leaf 2).
library;

import '../../../../core/constant/api_endpoint.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/citizen_document.dart';
import '../../domain/entities/citizen_preferences.dart';
import '../models/account_wire.dart';

abstract class AccountRemoteDatasource {
  Future<CitizenPreferences> getPreferences();

  Future<CitizenPreferences> savePreferences(CitizenPreferences preferences);

  Future<List<CitizenDocument>> getDocuments();
}

class AccountRemoteDatasourceImpl implements AccountRemoteDatasource {
  const AccountRemoteDatasourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<CitizenPreferences> getPreferences() async {
    final dynamic data = await apiClient.get<dynamic>(
      ApiEndpoint.mePreferences,
    );
    return citizenPreferencesFrom(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  @override
  Future<CitizenPreferences> savePreferences(
      CitizenPreferences preferences) async {
    final dynamic data = await apiClient.put<dynamic>(
      ApiEndpoint.mePreferences,
      body: preferencesBody(preferences),
    );
    // The endpoint echoes the saved object back (`api.put<CitizenPreferences>`).
    // A response that is not an object yields the *sent* value rather than an
    // empty one: the write succeeded — a 4xx/5xx would have thrown — so
    // discarding what we know is true in favour of all-false booleans would
    // flip three switches back in the UI for no reason.
    if (data is! Map<String, dynamic>) return preferences;
    return citizenPreferencesFrom(data);
  }

  @override
  Future<List<CitizenDocument>> getDocuments() async {
    final dynamic data = await apiClient.get<dynamic>(ApiEndpoint.meDocuments);
    if (data is! List<dynamic>) return const <CitizenDocument>[];

    // `whereType` rather than a cast: one malformed row must cost that row, not
    // the card. A `data` that is not a list at all yields an empty list and so
    // the **empty** state, not a crash — the disposition `_rows` takes in
    // `help_remote_datasource.dart` and `notification_remote_datasource.dart`.
    return data
        .whereType<Map<String, dynamic>>()
        .map(citizenDocumentFrom)
        .toList(growable: false);
  }
}

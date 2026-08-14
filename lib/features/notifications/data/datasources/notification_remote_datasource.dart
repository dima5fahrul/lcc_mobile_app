/// `NotificationRemoteDatasource` — the inbox's HTTP boundary, four calls.
///
/// ## Three envelope shapes, and none of them is interchangeable
///
/// - `GET /me/notifications` is **paged** (`api.paged`, `endpoints.ts:136`), so
///   it goes through `ApiClient.requestPaged`. `request` would hand back the
///   envelope's `data` with the `meta` block dropped on the floor — which
///   happens to be all this feature wants, but by accident rather than by
///   contract, and the accident would stop holding the day the bell grows a
///   pager.
/// - `GET /me/notifications/unread-count` answers an **object**
///   (`endpoints.ts:137`), read through `get<dynamic>`.
/// - The two POSTs answer `unknown` and their result is discarded.
///
/// ## Why the reads ask for `dynamic` and cast here
///
/// `help_remote_datasource.dart`'s header has the full account, and it is not
/// style: `ApiClient._send<T>` forwards `T` to `_dio.get<T>()`, Dio casts the
/// decoded body to `T`, and the decoded body is always the **envelope map**.
/// `T = List<dynamic>` therefore throws before `_unwrap` runs and surfaces as
/// `NETWORK_ERROR` — a request that reached the server, reported as offline.
/// One rule, no exception to remember.
///
/// ## The two POSTs send no body, deliberately
///
/// `endpoints.ts:138-139` call `api.post(path)` with no second argument, and
/// `client.ts:234-248` attaches a payload — and the `Content-Type` header —
/// only when `options.body !== undefined`. So the web's mark-read requests
/// carry neither.
///
/// `apiClient.post<dynamic>(path)` leaves `body` null, so Dio sends no payload
/// and the bodies match. **The headers do not**: `ApiClient._send`
/// (`lib/core/network/api_client.dart:257`) sets
/// `contentType: 'application/json'` unconditionally for every non-form
/// request, so these two POSTs carry a header the web's do not. `core/network/`
/// is behaviour-frozen (SSD § 6.6(c)) — making Dio omit the header
/// conditionally is changed behaviour on the one file every request in the app
/// goes through, to remove a header no observed backend rejects. The divergence
/// is **recorded, not fixed** (specs.md § 6.8).
library;

import '../../../../core/constant/api_endpoint.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/notification_entities.dart';
import '../models/notification_wire.dart';

abstract class NotificationRemoteDatasource {
  Future<List<CitizenNotification>> getNotifications({required int perPage});

  Future<int> getUnreadCount();

  Future<void> markRead(String id);

  Future<void> markAllRead();
}

class NotificationRemoteDatasourceImpl implements NotificationRemoteDatasource {
  const NotificationRemoteDatasourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<CitizenNotification>> getNotifications({
    required int perPage,
  }) async {
    final Paged<dynamic> result = await apiClient.requestPaged<dynamic>(
      ApiEndpoint.meNotifications,
      query: <String, dynamic>{'per_page': perPage},
    );

    // `whereType` rather than a cast: one malformed row must cost that row, not
    // the menu. A `data` that is not a list at all yields an empty list and so
    // the **empty** state, not a crash — the same disposition `_rows` takes in
    // `help_remote_datasource.dart`.
    return result.data
        .whereType<Map<String, dynamic>>()
        .map(citizenNotificationFrom)
        .toList(growable: false);
  }

  @override
  Future<int> getUnreadCount() async {
    final dynamic data = await apiClient.get<dynamic>(
      ApiEndpoint.meNotificationsUnreadCount,
    );
    return unreadCountFrom(data);
  }

  @override
  Future<void> markRead(String id) =>
      // No `body:` argument — see the library doc. This is the port of
      // `api.post<unknown>(\`/me/notifications/\${id}/read\`)`.
      apiClient.post<dynamic>(ApiEndpoint.meNotificationRead(id));

  @override
  Future<void> markAllRead() =>
      apiClient.post<dynamic>(ApiEndpoint.meNotificationsReadAll);
}

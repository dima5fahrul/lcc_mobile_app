/// Transport-level guard for `NotificationRemoteDatasourceImpl`, over a **real
/// `Dio`** with only the socket stubbed.
///
/// FACTORY-RULES § Quality Gates' **Capability Rule**: *"a criterion is not
/// discharged by proving a configuration value propagated; it must assert the
/// capability that value was configured to obtain."* Every other test for this
/// datasource hands it a fake repository or a mocked `ApiClient` and therefore
/// proves the wiring, not the capability. Three things can only be observed
/// here:
///
/// 1. **The generic cast.** `help_remote_datasource.dart`'s header records the
///    defect: `ApiClient._send<T>` forwards `T` to `_dio.get<T>()`, Dio casts
///    the decoded body to `T`, and the decoded body is always the **envelope
///    map**. `get<List<dynamic>>` therefore throws before `_unwrap` runs and
///    surfaces as `NETWORK_ERROR` — a request that reached the server, reported
///    as offline. A mocked `ApiClient` never performs that cast.
/// 2. **Paged vs plain.** `/me/notifications` is `api.paged`; the unread count
///    is `api.get`. Two different envelope readers, and § 2.2 Finding H is what
///    the tree already looked like when the second one was guessed.
/// 3. **That the two POSTs really send no body** — the claim Tier 0 NOT
///    APPLICABLE rests on for B9a (B9-AC-22). It is a statement about bytes on
///    the wire, so it is asserted on the wire.
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:lcc_mobile_app/features/notifications/domain/entities/notification_entities.dart';

import '../../../helpers/core_test_helper.dart';
import '../notification_test_helper.dart';

void main() {
  late StorageService storage;

  setUp(() {
    storage = inMemoryStorageService(<String, String>{});
  });

  ({
    NotificationRemoteDatasourceImpl datasource,
    RecordingHttpAdapter adapter
  }) rig(Object? body) {
    final RecordingHttpAdapter adapter = RecordingHttpAdapter.always(body);
    final Dio dio = buildTestDio(
      storage: storage,
      adapter: adapter,
      withInterceptors: false,
    );
    return (
      datasource: NotificationRemoteDatasourceImpl(
        apiClient: ApiClient(dio: dio, storage: storage),
      ),
      adapter: adapter,
    );
  }

  group('GET /me/notifications — PAGED, and it survives the envelope cast', () {
    test('the eight synthetic rows come back as entities', () async {
      final ({
        NotificationRemoteDatasourceImpl datasource,
        RecordingHttpAdapter adapter
      }) r = rig(syntheticEnvelope('me-notifications'));

      final List<CitizenNotification> rows =
          await r.datasource.getNotifications(perPage: 8);

      expect(rows, hasLength(8));
      expect(rows.first.id, 'ntf-0001');
      expect(rows.last.category, 'maintenance');
    });

    test('per_page really reaches the query string — Layout.tsx:117', () async {
      final ({
        NotificationRemoteDatasourceImpl datasource,
        RecordingHttpAdapter adapter
      }) r = rig(syntheticEnvelope('me-notifications'));

      await r.datasource.getNotifications(perPage: 8);

      expect(r.adapter.requests.single.path, ApiEndpoint.meNotifications);
      expect(r.adapter.requests.single.queryParameters['per_page'], 8);
    });

    test('it is NOT anonymous — the /me/* reads carry whatever the '
        'interceptor chain attaches', () async {
      final ({
        NotificationRemoteDatasourceImpl datasource,
        RecordingHttpAdapter adapter
      }) r = rig(syntheticEnvelope('me-notifications'));

      await r.datasource.getNotifications(perPage: 8);

      expect(r.adapter.requests.single.extra['anonymous'], isFalse);
    });

    test('a data that is not a list yields the EMPTY state, not a crash',
        () async {
      final ({
        NotificationRemoteDatasourceImpl datasource,
        RecordingHttpAdapter adapter
      }) r = rig(okEnvelope(<String, dynamic>{'oops': true}));

      expect(await r.datasource.getNotifications(perPage: 8), isEmpty);
    });

    test('one malformed row costs that row, not the menu', () async {
      final ({
        NotificationRemoteDatasourceImpl datasource,
        RecordingHttpAdapter adapter
      }) r = rig(okEnvelope(<dynamic>[
        <String, dynamic>{'id': 'good'},
        'not-an-object',
        42,
      ]));

      final List<CitizenNotification> rows =
          await r.datasource.getNotifications(perPage: 8);
      expect(rows, hasLength(1));
      expect(rows.single.id, 'good');
    });
  });

  group('GET /me/notifications/unread-count — an OBJECT, not an array', () {
    test('the corrected fixture reaches the entity layer as 3', () async {
      final ({
        NotificationRemoteDatasourceImpl datasource,
        RecordingHttpAdapter adapter
      }) r = rig(syntheticEnvelope('me-notifications-unread-count'));

      expect(await r.datasource.getUnreadCount(), 3);
      expect(
        r.adapter.requests.single.path,
        ApiEndpoint.meNotificationsUnreadCount,
      );
    });

    test('THE OLD FIXTURE SHAPE would have answered 0 — § 2.2 Finding H',
        () async {
      // The regression this batch exists to have caught. `"data": []` is what
      // shipped; against a typed `{unread: number}` endpoint it deserialises
      // to zero and the badge silently never appears. No exception, no log —
      // which is why it survived until a batch read the endpoint for real.
      final ({
        NotificationRemoteDatasourceImpl datasource,
        RecordingHttpAdapter adapter
      }) r = rig(okEnvelope(<dynamic>[]));

      expect(await r.datasource.getUnreadCount(), 0);
    });
  });

  group('the two POSTs send NO BODY — the basis for Tier 0 NOT APPLICABLE '
      '(B9-AC-22)', () {
    test('POST /me/notifications/<id>/read', () async {
      final ({
        NotificationRemoteDatasourceImpl datasource,
        RecordingHttpAdapter adapter
      }) r = rig(okEnvelope(null));

      await r.datasource.markRead('ntf-0001');

      final RequestOptions sent = r.adapter.requests.single;
      expect(sent.method, 'POST');
      expect(sent.path, '/me/notifications/ntf-0001/read');
      expect(
        sent.data,
        isNull,
        reason: '`endpoints.ts:138` calls `api.post(path)` with no second '
            'argument, and `client.ts:240` attaches a payload only when '
            '`options.body !== undefined`. Payload equality over an empty '
            'payload is vacuous, which is why B9a reports Tier 0 NOT '
            'APPLICABLE with that reason rather than PASS.',
      );
    });

    test('POST /me/notifications/read-all', () async {
      final ({
        NotificationRemoteDatasourceImpl datasource,
        RecordingHttpAdapter adapter
      }) r = rig(okEnvelope(null));

      await r.datasource.markAllRead();

      final RequestOptions sent = r.adapter.requests.single;
      expect(sent.method, 'POST');
      expect(sent.path, ApiEndpoint.meNotificationsReadAll);
      expect(sent.data, isNull);
    });

    test('THE RECORDED DIVERGENCE — Flutter sends a Content-Type the web does '
        'not, and B9a does not fix it (§ 6.8)', () async {
      final ({
        NotificationRemoteDatasourceImpl datasource,
        RecordingHttpAdapter adapter
      }) r = rig(okEnvelope(null));

      await r.datasource.markAllRead();

      // `ApiClient._send` (`lib/core/network/api_client.dart:257`) sets
      // `contentType: 'application/json'` unconditionally for every non-form
      // request. `client.ts:234-248` sets it ONLY when a body exists, so the
      // web's bodyless POST carries no such header.
      //
      // `lib/core/network/**` is behaviour-frozen (SSD § 6.6(c)): making Dio
      // omit it conditionally is changed behaviour on the one file every
      // request in the app goes through, to remove a header no observed
      // backend rejects. Recorded, NOT fixed — and asserted here so the
      // divergence is a measured fact in the suite rather than a sentence in a
      // report.
      expect(
        r.adapter.requests.single.headers[Headers.contentTypeHeader],
        contains('application/json'),
        reason: 'If this ever fails, someone changed `core/network/` — which '
            'needs an ADR (§ 8.3) — and the divergence note in qa-report.md '
            'is now stale.',
      );
    });

    test('the id segment is percent-encoded — B9-AC-13', () async {
      final ({
        NotificationRemoteDatasourceImpl datasource,
        RecordingHttpAdapter adapter
      }) r = rig(okEnvelope(null));

      await r.datasource.markRead('a/b?c');

      expect(r.adapter.requests.single.path, '/me/notifications/a%2Fb%3Fc/read');
    });
  });
}

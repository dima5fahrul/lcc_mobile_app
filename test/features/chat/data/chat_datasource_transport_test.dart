/// `ChatRemoteDatasourceImpl` at the transport boundary.
///
/// This is where the claims Tier 0 makes about a *body* become claims about a
/// **request**: that `POST /read` really goes out with no payload
/// (B9-AC-26), that the two GETs really use the two different envelope readers
/// § 5 requires, and that `per_page: 100` really reaches the query string.
///
/// The `Content-Type` divergence B9B-DIV-1 records is **observable here and
/// asserted here**, rather than only described in a YAML file — an assertion
/// that the header IS present is what stops the record from quietly going
/// stale if `core/network/` is ever unfrozen and fixed.
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:lcc_mobile_app/features/chat/domain/entities/chat_entities.dart';
import 'package:lcc_mobile_app/features/chat/domain/usecases/chat_usecases.dart';

import '../../../helpers/core_test_helper.dart';
import '../chat_test_helper.dart';

void main() {
  late StorageService storage;

  setUp(() {
    storage = inMemoryStorageService(<String, String>{});
  });

  ({ChatRemoteDatasourceImpl datasource, RecordingHttpAdapter adapter}) rig(
    Object? body,
  ) {
    final RecordingHttpAdapter adapter = RecordingHttpAdapter.always(body);
    final Dio dio = buildTestDio(
      storage: storage,
      adapter: adapter,
      withInterceptors: false,
    );
    return (
      datasource: ChatRemoteDatasourceImpl(
        apiClient: ApiClient(dio: dio, storage: storage),
      ),
      adapter: adapter,
    );
  }

  Map<String, dynamic> envelope(String name) {
    final Map<String, dynamic> fixture = loadSyntheticChatApi(name);
    return okEnvelope(
      fixture['data'],
      meta: fixture['meta'] as Map<String, dynamic>?,
    );
  }

  // ── The two GETs, two envelopes ───────────────────────────────────────────

  group('GET /me/chat/threads — a PLAIN ARRAY, not a page', () {
    test('the four synthetic threads come back as entities', () async {
      final r = rig(envelope('me-chat-threads'));
      final List<ChatThread> rows = await r.datasource.getThreads();

      expect(rows, hasLength(4));
      expect(rows.first.id, 'th-open-1');
      expect(rows.last.status, 'resolved');
    });

    test('it goes to the right path, with NO per_page — the source sends none',
        () async {
      final r = rig(envelope('me-chat-threads'));
      await r.datasource.getThreads();

      expect(r.adapter.requests.single.path, ApiEndpoint.meChatThreads);
      expect(r.adapter.requests.single.queryParameters, isEmpty,
          reason: '`endpoints.ts:155` is `api.get<ChatThread[]>(path, {signal})` '
              '— no query at all, unlike the notification inbox');
      expect(r.adapter.requests.single.method, 'GET');
    });

    test('it is NOT anonymous', () async {
      final r = rig(envelope('me-chat-threads'));
      await r.datasource.getThreads();
      expect(r.adapter.requests.single.extra['anonymous'], isFalse);
    });

    test('a `data` that is not a list yields an EMPTY list, not a crash',
        () async {
      final r = rig(okEnvelope(<String, dynamic>{'oops': true}));
      expect(await r.datasource.getThreads(), isEmpty,
          reason: '`threads.data ?? []` (`:67`) — a malformed list costs the '
              'badge, not the shell');
    });

    test('one malformed row costs that row, not the list', () async {
      final r = rig(okEnvelope(<dynamic>[
        <String, dynamic>{'id': 'th-1', 'status': 'open'},
        'not an object',
        <String, dynamic>{'id': 'th-2', 'status': 'closed'},
      ]));

      final List<ChatThread> rows = await r.datasource.getThreads();
      expect(rows.map((ChatThread t) => t.id), <String>['th-1', 'th-2']);
    });
  });

  group('GET /me/chat/threads/<id>/messages — PAGED', () {
    test('the six synthetic messages come back as entities', () async {
      final r = rig(envelope('me-chat-messages'));
      final List<ChatMessage> rows = await r.datasource.getMessages(
        threadId: 'th-open-1',
        perPage: kChatMessagesPerPage,
      );

      expect(rows, hasLength(6));
      expect(rows.first.senderType, 'bot');
      expect(rows.last.suggestions, hasLength(2));
    });

    test('per_page 100 really reaches the query string — `:82`', () async {
      final r = rig(envelope('me-chat-messages'));
      await r.datasource.getMessages(threadId: 'th-open-1', perPage: 100);

      expect(r.adapter.requests.single.queryParameters['per_page'], 100);
    });

    test('the thread id is percent-encoded into the path', () async {
      final r = rig(envelope('me-chat-messages'));
      await r.datasource.getMessages(threadId: 'a/b?c', perPage: 100);

      expect(r.adapter.requests.single.path,
          '/me/chat/threads/a%2Fb%3Fc/messages',
          reason: 'an unencoded `/` or `?` in a segment silently retargets the '
              'request at a different endpoint');
    });

    test('it goes through the PAGED reader — a response with no `meta` still '
        'parses', () async {
      // `requestPaged` substitutes `PageMeta.empty` when the block is absent,
      // which is what makes the two readers non-interchangeable rather than
      // merely different.
      final r = rig(okEnvelope(<dynamic>[
        <String, dynamic>{'id': 'm1', 'body': 'x'},
      ]));
      expect(
        await r.datasource.getMessages(threadId: 't', perPage: 100),
        hasLength(1),
      );
    });
  });

  // ── The three bodied POSTs ────────────────────────────────────────────────

  group('the three bodied POSTs send exactly what Tier 0 asserts', () {
    test('POST /me/chat/threads — {subject, topic, message}, truncated', () async {
      final r = rig(okEnvelope(<String, dynamic>{
        'thread': <String, dynamic>{'id': 'th-9'},
      }));

      final String long = 'x' * 100;
      final StartedThread created =
          await r.datasource.startThread(subject: long, message: long);

      final RequestOptions request = r.adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, ApiEndpoint.meChatThreads);

      final Map<String, dynamic> body = request.data as Map<String, dynamic>;
      expect(body.keys.toList(), <String>['subject', 'topic', 'message'],
          reason: 'order, not just membership');
      expect((body['subject'] as String).length, 80);
      expect(body['topic'], 'general');
      expect((body['message'] as String).length, 100,
          reason: 'the MESSAGE is never truncated — only the subject is');
      expect(created.thread.id, 'th-9');
    });

    test('POST .../messages — {body}', () async {
      final r = rig(okEnvelope(<String, dynamic>{
        'message': <String, dynamic>{'id': 'm-9'},
      }));

      await r.datasource.sendMessage(threadId: 'th-1', body: 'ຂອບໃຈ');

      final RequestOptions request = r.adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/me/chat/threads/th-1/messages');
      expect(request.data, <String, dynamic>{'body': 'ຂອບໃຈ'});
    });

    test('POST .../close — {rating}', () async {
      final r = rig(okEnvelope(null));
      await r.datasource.closeThread(threadId: 'th-1', rating: 4);

      final RequestOptions request = r.adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/me/chat/threads/th-1/close');
      expect(request.data, <String, dynamic>{'rating': 4});
    });
  });

  // ── B9-AC-26 — the bodyless POST and the recorded divergence ──────────────

  group('B9-AC-26 — POST /me/chat/threads/<id>/read', () {
    test('it sends NO body at all', () async {
      final r = rig(okEnvelope(null));
      await r.datasource.markRead('th-1');

      final RequestOptions request = r.adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/me/chat/threads/th-1/read');
      expect(request.data, isNull,
          reason: '`endpoints.ts:160` is `api.post<unknown>(path)` with no '
              'second argument, and `client.ts:240` attaches a payload only '
              'when `options.body !== undefined`. The BODIES match.');
    });

    test('and it DOES carry a Content-Type the web\'s does not — B9B-DIV-1, '
        'asserted rather than only described', () async {
      final r = rig(okEnvelope(null));
      await r.datasource.markRead('th-1');

      expect(
        r.adapter.requests.single.headers[Headers.contentTypeHeader] ??
            r.adapter.requests.single.contentType,
        contains('application/json'),
        reason: 'THE DIVERGENCE. `api_client.dart:257` sets it '
            'unconditionally; the web sends none on a bodyless POST. '
            '`lib/core/network/**` is behaviour-frozen (SSD § 6.6(c)) so this '
            'is RECORDED, NOT FIXED — and asserting its presence is what stops '
            'b9_divergences.yaml from going stale unnoticed if it ever is.',
      );
    });

    test('the id is percent-encoded here too', () async {
      final r = rig(okEnvelope(null));
      await r.datasource.markRead('a b/c');
      expect(r.adapter.requests.single.path,
          '/me/chat/threads/a%20b%2Fc/read');
    });
  });

  // ── The read side of the POST responses ───────────────────────────────────

  group('the POST responses are parsed, and a malformed one does not throw',
      () {
    test('a create response with no `thread` yields an empty id', () async {
      final r = rig(okEnvelope(<String, dynamic>{'nothing': true}));
      final StartedThread created =
          await r.datasource.startThread(subject: 'a', message: 'a');
      expect(created.thread.id, '');
    });

    test('a send response of null yields an empty SentMessage', () async {
      final r = rig(okEnvelope(null));
      final SentMessage sent =
          await r.datasource.sendMessage(threadId: 't', body: 'b');
      expect(sent.message.id, '');
      expect(sent.suggestions, isNull);
    });
  });
}

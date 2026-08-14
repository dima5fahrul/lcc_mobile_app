/// `ChatRemoteDatasource` — the chat's HTTP boundary, six calls.
///
/// ## Two GETs, two different envelopes
///
/// - `GET /me/chat/threads` is `api.get<ChatThread[]>` (`endpoints.ts:155`) — a
///   **plain array** in `data`, no `meta`. It goes through `ApiClient.request`.
/// - `GET /me/chat/threads/<id>/messages` is `api.paged<ChatMessage>` (`:157`)
///   — a **paged** envelope, so it goes through `ApiClient.requestPaged`. Using
///   `request` would drop the `meta` block silently, which happens to be all
///   this feature wants but by accident rather than by contract.
///
/// ## Why the reads ask for `dynamic` and cast here
///
/// `help_remote_datasource.dart`'s header has the full account and it is not
/// style: `ApiClient._send<T>` forwards `T` to `_dio.get<T>()`, Dio casts the
/// decoded body to `T`, and the decoded body is always the **envelope map**.
/// `T = List<dynamic>` therefore throws before `_unwrap` runs and surfaces as
/// `NETWORK_ERROR` — a request that reached the server, reported as offline.
/// One rule, no exception to remember.
///
/// ## The POST bodies come from `chat_wire.dart`, not from here
///
/// There is deliberately **no JSON literal in this file**. The three bodied
/// POSTs pass a map built by a named function, so Tier 0 asserts the same
/// artefact production sends rather than a re-derivation of it
/// (specs.md § 6.7, B9-AC-23).
///
/// [markRead] passes no `body:` argument at all, matching
/// `api.post<unknown>(path)` at `endpoints.ts:160` over `client.ts:234-248`,
/// which attaches a payload — and the `Content-Type` header — only when
/// `options.body !== undefined`. **The bodies match; the headers do not**:
/// `ApiClient._send` (`lib/core/network/api_client.dart:257`) sets
/// `contentType: 'application/json'` unconditionally. `core/network/` is
/// behaviour-frozen (SSD § 6.6(c)), so the divergence is recorded in
/// `test/features/chat/fidelity/b9_divergences.yaml` and **not fixed here**
/// (§ 6.8, B9-AC-26).
library;

import '../../../../core/constant/api_endpoint.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/chat_entities.dart';
import '../models/chat_wire.dart';

abstract class ChatRemoteDatasource {
  Future<List<ChatThread>> getThreads();

  Future<List<ChatMessage>> getMessages({
    required String threadId,
    required int perPage,
  });

  Future<StartedThread> startThread({
    required String subject,
    required String message,
  });

  Future<SentMessage> sendMessage({
    required String threadId,
    required String body,
  });

  Future<void> markRead(String threadId);

  Future<void> closeThread({required String threadId, required int rating});
}

class ChatRemoteDatasourceImpl implements ChatRemoteDatasource {
  const ChatRemoteDatasourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<ChatThread>> getThreads() async {
    final dynamic data = await apiClient.get<dynamic>(ApiEndpoint.meChatThreads);

    // `whereType` rather than a cast: one malformed row must cost that row, not
    // the launcher badge and not the panel. A `data` that is not a list at all
    // yields an empty list — which is the source's `threads.data ?? []` (`:67`)
    // — rather than a throw.
    return (data is List ? data : const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(chatThreadFrom)
        .toList(growable: false);
  }

  @override
  Future<List<ChatMessage>> getMessages({
    required String threadId,
    required int perPage,
  }) async {
    final Paged<dynamic> result = await apiClient.requestPaged<dynamic>(
      ApiEndpoint.meChatMessages(threadId),
      query: <String, dynamic>{'per_page': perPage},
    );

    return result.data
        .whereType<Map<String, dynamic>>()
        .map(chatMessageFrom)
        .toList(growable: false);
  }

  @override
  Future<StartedThread> startThread({
    required String subject,
    required String message,
  }) async {
    final dynamic data = await apiClient.post<dynamic>(
      ApiEndpoint.meChatThreads,
      body: startThreadRequestBody(subject: subject, message: message),
    );
    return startedThreadFrom(data);
  }

  @override
  Future<SentMessage> sendMessage({
    required String threadId,
    required String body,
  }) async {
    final dynamic data = await apiClient.post<dynamic>(
      ApiEndpoint.meChatMessages(threadId),
      body: sendMessageRequestBody(body: body),
    );
    return sentMessageFrom(data);
  }

  @override
  Future<void> markRead(String threadId) =>
      // No `body:` argument — see the library doc. The port of
      // `api.post<unknown>(\`/me/chat/threads/\${threadId}/read\`)`.
      apiClient.post<dynamic>(ApiEndpoint.meChatThreadRead(threadId));

  @override
  Future<void> closeThread({
    required String threadId,
    required int rating,
  }) =>
      apiClient.post<dynamic>(
        ApiEndpoint.meChatThreadClose(threadId),
        body: closeThreadRequestBody(rating: rating),
      );
}

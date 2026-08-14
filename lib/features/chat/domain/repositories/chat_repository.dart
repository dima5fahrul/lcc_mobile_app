/// The chat's repository contract — six calls, three of which carry a body.
///
/// | Source | Method | Endpoint | Envelope / body |
/// |---|---|---|---|
/// | `CustomerServiceChat.tsx:55` | [getThreads] | `GET /me/chat/threads` | **plain array** |
/// | `:82` | [getMessages] | `GET /me/chat/threads/<id>/messages` | **paged**, `per_page: 100` |
/// | `:106` | [startThread] | `POST /me/chat/threads` | `{subject, topic, message}` |
/// | `:109` | [sendMessage] | `POST /me/chat/threads/<id>/messages` | `{body}` |
/// | `:102` | [markRead] | `POST /me/chat/threads/<id>/read` | **no body** |
/// | `:112` | [closeThread] | `POST /me/chat/threads/<id>/close` | `{rating}` |
///
/// ## The two GETs have different envelopes and they are not interchangeable
///
/// `endpoints.ts:155` is `api.get<ChatThread[]>` — a plain array in `data`,
/// **not** paged. `:157` is `api.paged<ChatMessage>`. Guessing the wrong one is
/// what produced the shape-wrong `me-notifications-unread-count.json`
/// (specs.md § 2.2 Finding H), and this batch has three envelope shapes across
/// four GETs (§ 5).
///
/// ## Tier 0 APPLIES here, unlike everywhere else in this app so far
///
/// Three of the six POSTs carry a JSON body, and one of them holds the batch's
/// only real transform — `subject = message.trim().slice(0, 80)`, in **UTF-16
/// code units** (§ 6.7). The bodies are built by `chat_wire.dart`'s
/// `*RequestBody` functions rather than assembled inline at the call site, so
/// that `test/features/chat/fidelity/tier0_chat_payload_test.dart` can assert
/// the **encoded JSON string** — which gates key order as well as key names
/// (B9-AC-23).
///
/// The `Content-Type` divergence § 6.8 describes applies to [markRead], the one
/// bodyless POST here: `client.ts:240` attaches the header only when
/// `options.body !== undefined`, while `api_client.dart:257` sets it
/// unconditionally. `lib/core/network/**` is behaviour-frozen (SSD § 6.6(c)),
/// so it is **recorded, not fixed** — by name, with both citations, in
/// `test/features/chat/fidelity/b9_divergences.yaml` (B9-AC-26).
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/chat_entities.dart';

abstract class ChatRepository {
  /// `GET /me/chat/threads` — a plain array, refetched on every poll tick
  /// because `tick` is in the query's dependency list (`:55`).
  Future<Either<Failure, List<ChatThread>>> getThreads();

  /// `GET /me/chat/threads/<id>/messages?per_page=100` — **paged**, and the
  /// page block is discarded for the reason `NotificationRepository` gives:
  /// `:89` reads `transcript.data?.data ?? []` and the panel has no pager.
  Future<Either<Failure, List<ChatMessage>>> getMessages({
    required String threadId,
    required int perPage,
  });

  /// `POST /me/chat/threads` with `{subject, topic, message}`.
  ///
  /// The caller reads only `thread.id` (`:141`) but the whole response is
  /// returned: discarding it in the repository would put the decision to ignore
  /// it somewhere a test cannot see.
  Future<Either<Failure, StartedThread>> startThread({
    required String subject,
    required String message,
  });

  /// `POST /me/chat/threads/<id>/messages` with `{body}`.
  Future<Either<Failure, SentMessage>> sendMessage({
    required String threadId,
    required String body,
  });

  /// `POST /me/chat/threads/<id>/read`, **no body**.
  ///
  /// `:102` writes `.catch(() => undefined)`: a failed read-marker is invisible
  /// to the citizen and must not interrupt anything. The `Either` is still
  /// returned so that the decision to ignore it is made at the call site, where
  /// it is visible and testable — the disposition `NotificationRepository` and
  /// `HelpRepository` already use.
  Future<Either<Failure, Unit>> markRead(String threadId);

  /// `POST /me/chat/threads/<id>/close` with `{rating}`.
  ///
  /// `:158-160` swallows the failure with the comment *"the thread stays open;
  /// nothing the citizen must act on"* — and the local `ended` set has already
  /// been updated by then (`:155`), so the panel resets either way.
  Future<Either<Failure, Unit>> closeThread({
    required String threadId,
    required int rating,
  });
}

/// The customer-service chat's three entities.
///
/// Port of `types.ts:722-753`'s `ChatThread`, `ChatMessage` and
/// `SendMessageResult`, plus the `startChatThread` response shape
/// (`endpoints.ts:157`).
///
/// ## Nothing here is `Bilingual`, and that is the measurement
///
/// Every other user-facing label in this app arrives as `{en, lo}`; a reviewer
/// coming from `features/news` or `features/notifications` will expect
/// [ChatThread.subject] to be one too. It is not. **The citizen typed it** —
/// `CustomerServiceChat.tsx:140` derives it from their own message — and so did
/// they type [ChatMessage.body]. A `Bilingual` here would be a shape the wire
/// never sends and would silently render the wrong side of a pair that does
/// not exist (specs.md § 5).
///
/// ## Three fields are on the wire and deliberately unread
///
/// [ChatMessage.attachmentUrl], [ChatMessage.readAt] and
/// [StartedThread.suggestions] / [SentMessage.suggestions] are declared in
/// `types.ts` and rendered by nothing. There is **no attachment UI in the
/// chat**, `read_at` gates nothing, and the chips read the *transcript's* last
/// message (`:187-192`) rather than either POST response. They are modelled
/// because the fields exist on the wire; a widget that read one would be
/// porting a behaviour the source does not have (specs.md § 2.2 Finding D,
/// B9-AC-44).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_entities.freezed.dart';

/// One row of `GET /me/chat/threads` — `types.ts:722-733`.
@freezed
abstract class ChatThread with _$ChatThread {
  const factory ChatThread({
    @Default('') String id,

    /// The citizen's own words, truncated to 80 UTF-16 code units at creation
    /// (`:140`). A plain `String`; see the library doc.
    @Default('') String subject,

    /// Always `"general"` from this client — the literal at `:106`. Kept as a
    /// `String` because it is the server's field and other clients may set it.
    @Default('') String topic,

    /// `"open" | "pending" | "resolved" | "closed"` (`types.ts:726`).
    ///
    /// Modelled as a `String`, not an enum, for the reason
    /// `notification_entities.dart` gives for `severity`: the source never
    /// switches on the closed set, it only asks [isActive]. An enum would have
    /// to decide what an unrecognised fifth value means, and the source answers
    /// that question by simply not matching.
    @Default('') String status,

    /// `assigned_name` — the human agent, once one picks the thread up.
    ///
    /// **Null is load-bearing.** It selects the header title (`:217`) *and* it
    /// suppresses the bot suggestion chips (`:190-191`): once an agent is on
    /// the thread the API stops suggesting and so does the UI.
    String? assignedName,

    /// On the wire, never rendered.
    String? applicationId,
    String? lastMessageAt,

    /// `types.ts:730`. Summed across threads for the launcher badge
    /// (`:127`), and **not** the same number as the notification bell's
    /// unread count — different feature, different endpoint (§ 2.2 Finding B).
    @Default(0) int unreadCitizen,

    /// The 1-5 star rating a closed thread carries. On the wire; the panel
    /// writes it and never reads it back.
    int? rating,
    @Default('') String createdAt,
  }) = _ChatThread;

  const ChatThread._();

  /// `th.status === "open" || th.status === "pending"` — `:68`.
  ///
  /// The whole of the source's status logic. `resolved` and `closed` threads
  /// are left alone and the next message opens a fresh one (`:63-64`).
  bool get isActive => status == 'open' || status == 'pending';
}

/// One message in a transcript — `types.ts:735-745`.
@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    @Default('') String id,
    @Default('') String threadId,

    /// `"citizen" | "agent" | "bot" | "system"` (`types.ts:737`). The only
    /// question asked of it is [isMine] (`:365`); the other three render
    /// identically.
    @Default('') String senderType,

    /// On the wire, never rendered — the header shows
    /// `ChatThread.assignedName`, not this.
    @Default('') String senderName,

    /// Rendered through the two-rule mini-markdown parser (`:402`). **This is
    /// server-supplied text**, which is why `formatted_text.dart` is a
    /// security-review item and not only a fidelity one (§ 6.14, § 7.8).
    @Default('') String body,

    /// `types.ts:740` — `string[] | null | undefined`, and **all three occur**.
    ///
    /// Only the *last* message's list is read, and only when no agent is
    /// assigned (`:187-192`). `null` and `[]` are not distinguished by any
    /// consumer, but they are distinguished here because the wire distinguishes
    /// them and collapsing them at the edge would make the fixture unable to
    /// discriminate.
    List<String>? suggestions,

    /// On the wire, never rendered. There is no attachment UI in the chat.
    String? attachmentUrl,
    String? readAt,

    /// An ISO timestamp rendered through `clockTime` (`:404`). Kept as the raw
    /// `String` the wire sends for the reason `CitizenNotification.sentAt`
    /// documents: the source's formatter answers `""` for an unparseable value
    /// instead of throwing, and parsing at the edge would move that decision to
    /// a place that cannot express it.
    @Default('') String sentAt,
  }) = _ChatMessage;

  const ChatMessage._();

  /// `msg.sender_type === "citizen"` — `:365`. Everything else is "not mine".
  bool get isMine => senderType == 'citizen';
}

/// The body of `POST /me/chat/threads` — `endpoints.ts:157`.
///
/// `:141` reads `created.thread.id` and nothing else. [message] and
/// [suggestions] are modelled because the response carries them.
@freezed
abstract class StartedThread with _$StartedThread {
  const factory StartedThread({
    @Default(ChatThread()) ChatThread thread,
    @Default(ChatMessage()) ChatMessage message,
    List<String>? suggestions,
  }) = _StartedThread;
}

/// `SendMessageResult` — `types.ts:747-750`.
///
/// The caller discards it entirely (`:137` awaits and ignores); the fresh
/// transcript arrives on the next poll. Modelled for the same reason
/// [StartedThread.suggestions] is.
@freezed
abstract class SentMessage with _$SentMessage {
  const factory SentMessage({
    @Default(ChatMessage()) ChatMessage message,
    List<String>? suggestions,
  }) = _SentMessage;
}

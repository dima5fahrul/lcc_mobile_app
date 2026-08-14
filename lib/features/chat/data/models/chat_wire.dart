/// The chat's wire ↔ entity mapping, in both directions.
///
/// Unlike every feature before it, this one has a **request** half: three of
/// the six POSTs carry a JSON body (specs.md § 6.7). The builders live here,
/// beside the readers, so that Tier 0 has one file to assert against and the
/// datasource has no JSON literal in it.
///
/// ## Why the four readers are re-declared rather than imported
///
/// The same call `notification_wire.dart` records: `help_wire.dart` and
/// `notification_wire.dart` hold byte-identical `stringAt` helpers, and
/// importing either would be a `features/chat → features/<other>/data/**` edge
/// that Cross-Feature Isolation forbids (SSD § 4.3) and **G-L3 measures and
/// fails**. SSD § 4.3 names the trade in as many words — *"wire-format
/// duplication is the accepted cost"*.
///
/// This is **not** the same call as `text(Bilingual?, Lang)`, which lives in
/// `lib/i18n/i18n.dart` — neither a feature nor `data/`, crossing no guard, and
/// imported rather than re-implemented wherever this feature needs it. Four B2
/// features re-implemented that one citing G-L3, and G-L3 has nothing to say
/// about `lib/i18n/`.
///
/// There is no `bilingualAt` here at all: **nothing in the chat is bilingual**
/// (`chat_entities.dart`'s library doc has the reason).
///
/// ## THE ONE REAL TRANSFORM, AND IT IS A LAO TRAP
///
/// `CustomerServiceChat.tsx:140`:
///
/// ```ts
/// const created = await start.run({ subject: body.slice(0, 80), message: body });
/// ```
///
/// where `body = raw.trim()` (`:130`). JavaScript's `String.prototype.slice`
/// operates on **UTF-16 code units** — not code points and not graphemes. Dart's
/// `String.substring` is code-unit-based too, so [chatSubject] is a one-liner
/// and the whole difficulty is in *not* writing the other one:
/// `message.characters.take(80)` is grapheme-based, it is what a careful Dart
/// developer reaches for, and for Lao text with combining vowels and tone marks
/// it produces a different answer.
///
/// An ASCII test cannot tell the two apart — for ASCII, code units, code points
/// and graphemes coincide, so every plausible implementation passes. The gate is
/// therefore a Lao fixture that asserts the equality **and the inequality**
/// (B9-AC-21, FACTORY-RULES' Capability Rule).
library;

import '../../domain/entities/chat_entities.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reading
// ─────────────────────────────────────────────────────────────────────────────

/// A string field, or `''`.
String stringAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  return raw is String ? raw : '';
}

/// A string field, or **null** when absent or not a string.
///
/// Distinct from [stringAt] because for `assigned_name` the difference is the
/// whole meaning: null selects the bot title *and* re-enables the suggestion
/// chips (`:190-191`), where `''` would be an agent with a blank name.
String? nullableStringAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  return raw is String ? raw : null;
}

/// An int field, or `0`.
///
/// Accepts a `double` for the reason `help_wire.dart`'s `intAt` does: JSON has
/// one number type and a backend serialising `3.0` is sending an integer.
int intAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is int) return raw;
  if (raw is double) return raw.round();
  if (raw is String) return int.tryParse(raw) ?? 0;
  return 0;
}

/// An int field, or **null**.
int? nullableIntAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is int) return raw;
  if (raw is double) return raw.round();
  return null;
}

/// `suggestions` — `string[] | null | undefined`, and all three occur.
///
/// The distinction between `null` and `[]` is preserved (`types.ts:740`); no
/// consumer branches on it today, but collapsing them at the edge would make a
/// fixture unable to discriminate the two, which is how a test starts passing
/// vacuously.
List<String>? suggestionsAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is! List) return null;
  return raw.whereType<String>().toList(growable: false);
}

/// One row of `GET /me/chat/threads` — `types.ts:722-733`.
ChatThread chatThreadFrom(Map<String, dynamic> json) => ChatThread(
      id: stringAt(json, 'id'),
      subject: stringAt(json, 'subject'),
      topic: stringAt(json, 'topic'),
      status: stringAt(json, 'status'),
      assignedName: nullableStringAt(json, 'assigned_name'),
      applicationId: nullableStringAt(json, 'application_id'),
      lastMessageAt: nullableStringAt(json, 'last_message_at'),
      unreadCitizen: intAt(json, 'unread_citizen'),
      rating: nullableIntAt(json, 'rating'),
      createdAt: stringAt(json, 'created_at'),
    );

/// One message of `GET /me/chat/threads/<id>/messages` — `types.ts:735-745`.
ChatMessage chatMessageFrom(Map<String, dynamic> json) => ChatMessage(
      id: stringAt(json, 'id'),
      threadId: stringAt(json, 'thread_id'),
      senderType: stringAt(json, 'sender_type'),
      senderName: stringAt(json, 'sender_name'),
      body: stringAt(json, 'body'),
      suggestions: suggestionsAt(json, 'suggestions'),
      attachmentUrl: nullableStringAt(json, 'attachment_url'),
      readAt: nullableStringAt(json, 'read_at'),
      sentAt: stringAt(json, 'sent_at'),
    );

/// The `data` of `POST /me/chat/threads` — `{thread, message, suggestions?}`.
///
/// A malformed or absent `thread` yields a default [ChatThread] whose `id` is
/// `''`, and the BLoC treats an empty id as "no thread was created" rather than
/// adopting one that does not exist.
StartedThread startedThreadFrom(Object? data) {
  if (data is! Map<String, dynamic>) return const StartedThread();
  final Object? thread = data['thread'];
  final Object? message = data['message'];
  return StartedThread(
    thread: thread is Map<String, dynamic>
        ? chatThreadFrom(thread)
        : const ChatThread(),
    message: message is Map<String, dynamic>
        ? chatMessageFrom(message)
        : const ChatMessage(),
    suggestions: suggestionsAt(data, 'suggestions'),
  );
}

/// The `data` of `POST /me/chat/threads/<id>/messages` — `types.ts:747-750`.
SentMessage sentMessageFrom(Object? data) {
  if (data is! Map<String, dynamic>) return const SentMessage();
  final Object? message = data['message'];
  return SentMessage(
    message: message is Map<String, dynamic>
        ? chatMessageFrom(message)
        : const ChatMessage(),
    suggestions: suggestionsAt(data, 'suggestions'),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Writing — the Tier 0 surface
// ─────────────────────────────────────────────────────────────────────────────

/// `body.slice(0, 80)` — `:140`. **Eighty UTF-16 code units.**
const int kChatSubjectMaxUnits = 80;

/// `topic: "general"` — `:106`. A hardcoded literal in the source: never
/// derived from the message, never configurable, never sent from anywhere else.
const String kChatTopic = 'general';

/// The subject an agent sees in their queue — `body.slice(0, 80)`.
///
/// `String.substring` is **code-unit-based**, which is what
/// `String.prototype.slice` is. `message.characters.take(80).toString()` is
/// grapheme-based and is the wrong answer; see the library doc for why an ASCII
/// test cannot tell them apart.
///
/// [message] is expected to be **already trimmed** — the source trims once at
/// `:130` and derives both fields from that one string (B9-AC-25).
String chatSubject(String message) => message.length <= kChatSubjectMaxUnits
    ? message
    : message.substring(0, kChatSubjectMaxUnits);

/// `POST /me/chat/threads` — `{subject, topic, message}`, **in that order**.
///
/// Key order is asserted, not incidental: Tier 0 compares the **encoded JSON
/// string** because Dart's `Map` literals preserve insertion order and
/// `jsonEncode` respects it, so gating the order is free — and F0 § 6.2.3
/// already ruled it for the certificate payloads (B9-AC-23).
Map<String, dynamic> startThreadRequestBody({
  required String subject,
  required String message,
}) =>
    <String, dynamic>{
      'subject': chatSubject(subject),
      'topic': kChatTopic,
      'message': message,
    };

/// `POST /me/chat/threads/<id>/messages` — `{body}` (`:109`).
Map<String, dynamic> sendMessageRequestBody({required String body}) =>
    <String, dynamic>{'body': body};

/// `POST /me/chat/threads/<id>/close` — `{rating}` (`:112`).
///
/// `endpoints.ts:161` writes `body ?? {}`, so a call with no rating would send
/// `{}` — but `:157` always supplies one, so the empty case is unreachable from
/// this client and is not modelled.
Map<String, dynamic> closeThreadRequestBody({required int rating}) =>
    <String, dynamic>{'rating': rating};

/// The chat's wire → entity parsing.
///
/// Covers the mixed-shape trap specs.md § 5 records (nothing here is
/// `Bilingual`, and `unread_citizen` / `rating` are ints among strings), the
/// three-way `suggestions` distinction, and **B9-AC-44** — the four wire fields
/// that are modelled and rendered by nothing.
///
/// The rows are read through the **production** `*From` functions from the
/// synthetic fixture, so a fixture that drifts from the parser fails here
/// rather than in a widget test three layers up.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/chat/data/models/chat_wire.dart';
import 'package:lcc_mobile_app/features/chat/domain/entities/chat_entities.dart';

import '../chat_test_helper.dart';

void main() {
  group('ChatThread — `types.ts:722-733`', () {
    test('all four status values are present in the fixture, so `isActive` '
        'is actually exercised', () {
      final List<ChatThread> threads = syntheticThreads();
      expect(
        threads.map((ChatThread t) => t.status).toSet(),
        <String>{'open', 'pending', 'resolved', 'closed'},
        reason: 'a fixture with only `open` rows cannot fail `isActive`',
      );
    });

    test('`isActive` admits open and pending, and nothing else — `:68`', () {
      for (final ChatThread thread in syntheticThreads()) {
        expect(
          thread.isActive,
          thread.status == 'open' || thread.status == 'pending',
          reason: thread.id,
        );
      }
      // A status the API adds tomorrow is inactive, not a crash.
      expect(const ChatThread(status: 'escalated').isActive, isFalse);
      expect(const ChatThread().isActive, isFalse);
    });

    test('subject is a plain String — the citizen typed it', () {
      final ChatThread first = syntheticThreads().first;
      expect(first.subject, isA<String>());
      expect(first.subject, 'ຂ້ອຍຢາກສອບຖາມກ່ຽວກັບໃບຢັ້ງຢືນການເກີດ',
          reason: 'Lao, and NOT a {en, lo} pair — every other user-facing '
              'label in this app is bilingual and this one is not (§ 5)');
    });

    test('the int fields survive the string fields around them', () {
      final List<ChatThread> threads = syntheticThreads();
      expect(threads[0].unreadCitizen, 2);
      expect(threads[2].unreadCitizen, 5);
      expect(threads[2].rating, 4);
      expect(threads[0].rating, isNull);
    });

    test('assigned_name null vs set — the field that selects the header title '
        'AND suppresses the chips', () {
      final List<ChatThread> threads = syntheticThreads();
      expect(threads[0].assignedName, isNull);
      expect(threads[1].assignedName, 'ນາງ ສົມສີ ພົມມະຈັນ');
    });

    test('a malformed row degrades field by field rather than throwing', () {
      final ChatThread thread = chatThreadFrom(<String, dynamic>{
        'id': 42,
        'subject': null,
        'unread_citizen': '7',
        'rating': 3.0,
        'status': <String>['open'],
      });
      expect(thread.id, '');
      expect(thread.subject, '');
      expect(thread.unreadCitizen, 7, reason: 'a numeric string is a number');
      expect(thread.rating, 3, reason: 'JSON has one number type');
      expect(thread.status, '');
      expect(thread.isActive, isFalse);
    });
  });

  group('ChatMessage — `types.ts:735-745`', () {
    test('all four sender_type values are present, so the four-sender '
        'rendering test cannot pass vacuously', () {
      expect(
        syntheticMessages().map((ChatMessage m) => m.senderType).toSet(),
        <String>{'bot', 'citizen', 'agent', 'system'},
      );
    });

    test('`isMine` is citizen and nothing else — `:365`', () {
      for (final ChatMessage message in syntheticMessages()) {
        expect(message.isMine, message.senderType == 'citizen',
            reason: message.id);
      }
      expect(const ChatMessage(senderType: 'operator').isMine, isFalse);
    });

    test('suggestions is three-valued and the fixture holds all three', () {
      final List<ChatMessage> messages = syntheticMessages();
      expect(messages[0].suggestions, isNull, reason: 'absent on the wire');
      expect(messages[3].suggestions, isEmpty, reason: 'an empty array');
      expect(messages.last.suggestions, hasLength(2));
      expect(messages.last.suggestions,
          <String>['Track my application', 'ເວລາເຮັດການ']);
    });

    test('a non-list suggestions value is null, and non-string members are '
        'dropped rather than crashing the transcript', () {
      expect(
        chatMessageFrom(<String, dynamic>{'suggestions': 'nope'}).suggestions,
        isNull,
      );
      expect(
        chatMessageFrom(<String, dynamic>{
          'suggestions': <dynamic>['a', 3, null, 'b'],
        }).suggestions,
        <String>['a', 'b'],
      );
    });

    test('B9-AC-44 — the dead fields are MODELLED', () {
      final List<ChatMessage> messages = syntheticMessages();
      // They are on the wire, so they are parsed. That nothing renders them is
      // asserted in `chat_panel_test.dart`, where "renders nothing" can
      // actually be observed.
      expect(messages[0].readAt, '2026-08-13T09:14:30');
      expect(messages[2].attachmentUrl,
          'https://cdn.example.invalid/never-rendered.pdf');
      expect(messages[1].readAt, isNull);
    });
  });

  group('the POST responses', () {
    test('startedThreadFrom reads the thread the caller needs', () {
      final StartedThread started = startedThreadFrom(<String, dynamic>{
        'thread': <String, dynamic>{'id': 'th-9', 'status': 'open'},
        'message': <String, dynamic>{'id': 'm-9', 'body': 'hi'},
        'suggestions': <String>['a'],
      });
      expect(started.thread.id, 'th-9');
      expect(started.message.body, 'hi');
      expect(started.suggestions, <String>['a'],
          reason: 'on the wire (`endpoints.ts:157`) and read by nothing — '
              '`:141` uses only `created.thread.id` (§ 2.2 Finding D)');
    });

    test('a malformed create response yields an EMPTY thread id, which the '
        'BLoC treats as "no thread was created"', () {
      expect(startedThreadFrom(null).thread.id, '');
      expect(startedThreadFrom('nope').thread.id, '');
      expect(startedThreadFrom(<String, dynamic>{}).thread.id, '');
      expect(
        startedThreadFrom(<String, dynamic>{'thread': 'not a map'}).thread.id,
        '',
      );
    });

    test('sentMessageFrom is parsed and its result is discarded by the caller',
        () {
      final SentMessage sent = sentMessageFrom(<String, dynamic>{
        'message': <String, dynamic>{'id': 'm-10'},
        'suggestions': null,
      });
      expect(sent.message.id, 'm-10');
      expect(sent.suggestions, isNull);
      expect(sentMessageFrom(<String, dynamic>{}).message.id, '');
    });
  });

  group('the readers themselves', () {
    test('stringAt / nullableStringAt differ exactly where it matters', () {
      const Map<String, dynamic> json = <String, dynamic>{'a': null, 'b': 5};
      expect(stringAt(json, 'a'), '');
      expect(stringAt(json, 'missing'), '');
      expect(nullableStringAt(json, 'a'), isNull);
      expect(nullableStringAt(json, 'b'), isNull);
    });

    test('intAt accepts the three shapes JSON can send a number in', () {
      expect(intAt(<String, dynamic>{'n': 3}, 'n'), 3);
      expect(intAt(<String, dynamic>{'n': 3.0}, 'n'), 3);
      expect(intAt(<String, dynamic>{'n': '3'}, 'n'), 3);
      expect(intAt(<String, dynamic>{'n': 'x'}, 'n'), 0);
      expect(intAt(<String, dynamic>{}, 'n'), 0);
    });

    test('nullableIntAt keeps absent distinct from zero — `rating` is optional',
        () {
      expect(nullableIntAt(<String, dynamic>{'r': 0}, 'r'), 0);
      expect(nullableIntAt(<String, dynamic>{}, 'r'), isNull);
      expect(nullableIntAt(<String, dynamic>{'r': 'x'}, 'r'), isNull);
    });

    test('there is no bilingualAt in this feature, and that is the measurement',
        () {
      // `chat_entities.dart` states it: nothing in the chat is `{en, lo}`. If a
      // future field ever is, this test is where the omission gets noticed —
      // every parsed string below came out as a plain String.
      for (final ChatThread t in syntheticThreads()) {
        expect(t.subject, isA<String>());
        expect(t.topic, isA<String>());
      }
      for (final ChatMessage m in syntheticMessages()) {
        expect(m.body, isA<String>());
        expect(m.senderName, isA<String>());
      }
    });
  });

  group('the fixture declares itself synthetic — B9-AC-57', () {
    test('both API fixtures carry an honest provenance', () {
      for (final String name in <String>[
        'me-chat-threads',
        'me-chat-messages',
      ]) {
        final Map<String, dynamic> capture =
            loadSyntheticChatApi(name)['_capture'] as Map<String, dynamic>;
        expect(capture['provenance'] as String, contains('SYNTHETIC'),
            reason: name);
        expect(capture['provenance'] as String, contains('SMS'), reason: name);
        expect(capture['credential'], contains('none'), reason: name);
      }
    });

    test('each records why its values were chosen to discriminate', () {
      for (final String name in <String>[
        'me-chat-threads',
        'me-chat-messages',
      ]) {
        final Map<String, dynamic> capture =
            loadSyntheticChatApi(name)['_capture'] as Map<String, dynamic>;
        expect(capture.containsKey('chosen_to_discriminate'), isTrue,
            reason: '$name: "the synthetic values are chosen to DISCRIMINATE, '
                'not to look plausible" (§ 6.11)');
      }
    });
  });
}

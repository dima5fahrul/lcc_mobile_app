/// The chat panel's nine states — **B9-AC-38**, **B9-AC-42**, **B9-AC-43**,
/// **B9-AC-44**, **B9-AC-47**, and the i18n claims § 6.12 makes.
///
/// Tier 1 (`tier1_chat_test.dart`) gates the *ordered text* of these states
/// against a versioned oracle. This file gates the things a text dump cannot
/// see: which widgets exist, which do not, what the semantics labels say, and
/// what a Lao render measures.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/chat/domain/entities/chat_entities.dart';
import 'package:lcc_mobile_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:lcc_mobile_app/features/chat/presentation/widgets/chat_panel.dart';
import 'package:lcc_mobile_app/features/chat/presentation/widgets/formatted_text.dart';

import '../../../helpers/service_test_helper.dart';
import '../chat_test_helper.dart';

void main() {
  // Assigned by [drive], never in `setUp`. `setUp` runs OUTSIDE `testWidgets`'
  // `FakeAsync` zone, so a BLoC constructed there owns an event queue
  // `tester.pump()` can never drain — events are accepted and silently never
  // handled. `tier1_notifications_test.dart` records the run that proved it and
  // this file re-learned it the same way.
  late FakeChatRepository repository;
  late FakeHelpChannelsRepository help;
  late ChatBloc bloc;

  /// Pumps the panel FIRST, then drives it — the order the zone requires.
  ///
  /// Every test that leaves the panel open with a thread ends by dismissing it,
  /// because an open panel holds a live `Timer.periodic` and `flutter_test`
  /// fails a test that completes with one pending. That is B9-AC-17's mechanism
  /// working, not an inconvenience, so it is honoured rather than suppressed.
  Future<void> drive(
    WidgetTester tester, {
    bool signedIn = true,
    bool open = true,
    Locale locale = const Locale('en'),
    void Function(FakeChatRepository)? setUpRepository,
    void Function(FakeHelpChannelsRepository)? setUpHelp,
  }) async {
    repository = FakeChatRepository();
    help = FakeHelpChannelsRepository();
    setUpRepository?.call(repository);
    setUpHelp?.call(help);
    bloc = chatBlocOver(repository, help: help);
    addTearDown(bloc.close);

    await pumpChatPanel(tester, bloc, locale: locale);
    if (signedIn) {
      bloc.add(const ChatAuthChanged(true));
      await tester.pump();
      await tester.pump();
      await tester.pump();
    }
    if (open) {
      bloc.add(const ChatOpened());
      for (int i = 0; i < 5; i++) {
        await tester.pump();
      }
    }
  }

  /// Shuts the panel so its poll timer is cancelled before the harness looks.
  Future<void> shutdown(WidgetTester tester) async {
    bloc.add(const ChatDismissed());
    await tester.pump();
    await tester.pump();
  }

  // ── signedOut ─────────────────────────────────────────────────────────────

  group('signedOut — `:282-311`', () {
    testWidgets(
      'the prompt replaces the whole body, and there is no composer',
      (WidgetTester tester) async {
        await drive(tester, signedIn: false);

        expect(find.byType(ChatSignInPrompt), findsOneWidget);
        expect(
          find.byType(ChatComposer),
          findsNothing,
          reason: 'a signed-out citizen cannot type',
        );
        expect(find.byType(ChatTranscript), findsNothing);
        expect(find.byType(ChatSuggestionChips), findsNothing);

        await shutdown(tester);
      },
    );

    testWidgets('§ 7.8(3) — NOTHING of a previous conversation survives '
        'sign-out', (WidgetTester tester) async {
      await drive(tester);
      expect(find.byType(ChatTranscript), findsOneWidget);
      // A body from the fixture is on screen.
      expect(find.textContaining('ພວກເຮົາຊ່ວຍຫຍັງ'), findsWidgets);

      bloc.add(const ChatAuthChanged(false));
      for (int i = 0; i < 8; i++) {
        await tester.pump();
      }

      expect(find.byType(ChatSignInPrompt), findsOneWidget);
      expect(
        find.textContaining('ພວກເຮົາຊ່ວຍຫຍັງ'),
        findsNothing,
        reason:
            'the security review item: no transcript may survive a '
            'sign-out. `messages` is guarded on `threadId` (`:89`) and '
            '`threadId` is cleared at `:74-76`.',
      );

      await shutdown(tester);
    });

    testWidgets('the header still renders — the panel is not empty', (
      WidgetTester tester,
    ) async {
      await drive(tester, signedIn: false);
      expect(find.byType(ChatPanelHeader), findsOneWidget);
      expect(find.text('LCC Support'), findsOneWidget);

      await shutdown(tester);
    });
  });

  // ── minimized ─────────────────────────────────────────────────────────────

  testWidgets('minimized — the header and nothing else', (
    WidgetTester tester,
  ) async {
    await drive(tester);
    expect(find.byType(ChatTranscript), findsOneWidget);

    bloc.add(const ChatMinimizeToggled());
    for (int i = 0; i < 4; i++) {
      await tester.pump();
    }

    expect(find.byType(ChatPanelHeader), findsOneWidget);
    expect(find.byType(ChatTranscript), findsNothing);
    expect(find.byType(ChatComposer), findsNothing);
    // `{threadId && !minimized && …}` — `:222`. The end-conversation control
    // hides while minimised even though the thread is still live.
    expect(find.bySemanticsLabel('End this conversation'), findsNothing);

    await shutdown(tester);
  });

  // ── greeting / transcript / pending / typing ──────────────────────────────

  group('the transcript body', () {
    testWidgets('greeting — an empty thread shows the assistant\'s opener, not '
        'an empty state', (WidgetTester tester) async {
      await drive(
        tester,
        setUpRepository: (FakeChatRepository r) => r.emptyTranscript(),
      );

      expect(find.textContaining('Sabaidi!'), findsOneWidget);
      expect(find.byType(ChatBubble), findsOneWidget);

      await shutdown(tester);
    });

    testWidgets('transcript — all six messages render, in order, and only the '
        'citizen\'s is "mine"', (WidgetTester tester) async {
      await drive(tester);

      expect(find.byType(ChatBubble), findsNWidgets(6));
      final Iterable<ChatBubble> bubbles = tester.widgetList<ChatBubble>(
        find.byType(ChatBubble),
      );
      expect(
        bubbles.map((ChatBubble b) => b.mine),
        <bool>[false, true, false, false, false, false],
        reason:
            'only `sender_type == "citizen"` flips (`:365`); agent, bot '
            'and system all render the same way',
      );

      await shutdown(tester);
    });

    testWidgets('the citizen\'s **bold** run is parsed, and the delimiters are '
        'gone', (WidgetTester tester) async {
      await drive(tester);

      final ChatBubble mine = tester
          .widgetList<ChatBubble>(find.byType(ChatBubble))
          .firstWhere((ChatBubble b) => b.mine);
      expect(mine.text, contains('**'), reason: 'the raw body still has them');

      expect(find.byType(ChatFormattedText), findsWidgets);
      expect(
        find.textContaining('**'),
        findsNothing,
        reason: 'nothing on screen shows a delimiter',
      );

      await shutdown(tester);
    });

    testWidgets('the timestamp renders beside a real message and NOT beside '
        'the greeting', (WidgetTester tester) async {
      await drive(tester);
      expect(find.text('09:14'), findsOneWidget);
      expect(find.text('09:19'), findsOneWidget);

      repository.emptyTranscript();
      bloc.add(const ChatPolled());
      for (int i = 0; i < 8; i++) {
        await tester.pump();
      }
      expect(
        find.textContaining(':'),
        findsNothing,
        reason:
            'the greeting bubble has no `sent_at` and the source renders '
            'no stamp for it',
      );

      await shutdown(tester);
    });

    testWidgets('pending — the optimistic bubble appears at 70 % while a send '
        'is in flight', (WidgetTester tester) async {
      await drive(tester);
      repository.latency = const Duration(milliseconds: 200);

      bloc.add(const ChatMessageSubmitted('ກຳລັງສົ່ງ'));
      await tester.pump();
      await tester.pump();

      final Iterable<ChatBubble> bubbles = tester.widgetList<ChatBubble>(
        find.byType(ChatBubble),
      );
      final ChatBubble pending = bubbles.firstWhere(
        (ChatBubble b) => b.opacity != 1,
      );
      expect(pending.text, 'ກຳລັງສົ່ງ');
      expect(pending.mine, isTrue);
      expect(pending.opacity, 0.7, reason: '`opacity-70` — `:412`');
      expect(pending.time, isNull, reason: 'nothing has been sent yet');

      // The latency has to go before the wind-down: `Future.delayed` inside
      // FakeAsync IS a timer, so leaving it set means every fetch the
      // dismissal triggers arms another one and the test ends with one
      // pending.
      repository.latency = Duration.zero;
      await tester.pump(const Duration(milliseconds: 400));
      for (int i = 0; i < 8; i++) {
        await tester.pump();
      }

      await shutdown(tester);
    });

    testWidgets('typing — the indicator shows while a send is in flight', (
      WidgetTester tester,
    ) async {
      await drive(tester);
      expect(find.byType(ChatTypingIndicator), findsNothing);

      repository.latency = const Duration(milliseconds: 200);
      bloc.add(const ChatMessageSubmitted('x'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(ChatTypingIndicator), findsOneWidget);

      repository.latency = Duration.zero;
      await tester.pump(const Duration(milliseconds: 400));
      for (int i = 0; i < 8; i++) {
        await tester.pump();
      }
      expect(find.byType(ChatTypingIndicator), findsNothing);

      await shutdown(tester);
    });
  });

  // ── error ─────────────────────────────────────────────────────────────────

  testWidgets('error — the retry control renders and nothing leaks a Dart '
      'exception string', (WidgetTester tester) async {
    // ONLY the transcript fails. Failing the THREADS read too means no thread
    // is adopted, no transcript is ever requested, and there is no error to
    // render — a green test asserting nothing.
    await drive(
      tester,
      setUpRepository: (FakeChatRepository r) =>
          r.messages = const Left<Failure, List<ChatMessage>>(
            Failure('stubbed transcript failure'),
          ),
    );

    expect(find.text('Try again'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
    expect(
      find.textContaining('Failure'),
      findsNothing,
      reason:
          'B9B-DIV-5: the web prints `transcript.error.message`; this '
          'port prints no message line rather than `ApiException: …`',
    );
    expect(
      find.byType(ChatBubble),
      findsNothing,
      reason:
          'error wins over the greeting — an empty list is never an '
          'acceptable rendering of a failed fetch (SSD § 7.3)',
    );

    await shutdown(tester);
  });

  // ── rating — B9-AC-47 ─────────────────────────────────────────────────────

  group('B9-AC-47 — rateStarLabel renders for n = 1..5 in BOTH locales', () {
    for (final ({Locale locale, String Function(int) expected}) c
        in <({Locale locale, String Function(int) expected})>[
          (locale: const Locale('en'), expected: _en),
          (locale: const Locale('lo'), expected: _lo),
        ]) {
      testWidgets('${c.locale.languageCode} — five rendered labels, not a key '
          'presence check', (WidgetTester tester) async {
        await drive(tester, locale: c.locale);
        bloc.add(const ChatRatingRequested());
        for (int i = 0; i < 4; i++) {
          await tester.pump();
        }

        expect(find.byType(ChatRatingStrip), findsOneWidget);

        for (int n = 1; n <= 5; n++) {
          expect(
            find.bySemanticsLabel(c.expected(n)),
            findsOneWidget,
            reason:
                'A positional-argument mistake produces a key that is '
                'present, a translation that is present, and a label that '
                'reads "{} out of 5" — which a key-presence check passes '
                'and this does not. (n = $n, '
                'locale ${c.locale.languageCode})',
          );
        }

        // …and the placeholder must be GONE, not merely surrounded.
        expect(find.bySemanticsLabel(RegExp(r'\{\}')), findsNothing);

        await shutdown(tester);
      });
    }

    testWidgets('the strip has a prompt and a "not now", and tapping a star '
        'closes the thread with that rating', (WidgetTester tester) async {
      await drive(tester);
      bloc.add(const ChatRatingRequested());
      for (int i = 0; i < 4; i++) {
        await tester.pump();
      }

      expect(find.text('How did we do?'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('4 out of 5'));
      for (int i = 0; i < 8; i++) {
        await tester.pump();
      }

      expect(repository.closeCalls.single.rating, 4);

      await shutdown(tester);
    });

    testWidgets('the chips are hidden while the strip is open — `:494`', (
      WidgetTester tester,
    ) async {
      await drive(tester);
      expect(find.byType(ChatSuggestionChips), findsOneWidget);

      bloc.add(const ChatRatingRequested());
      for (int i = 0; i < 4; i++) {
        await tester.pump();
      }
      expect(find.byType(ChatSuggestionChips), findsNothing);

      await shutdown(tester);
    });
  });

  // ── chips ─────────────────────────────────────────────────────────────────

  group('the chips', () {
    testWidgets('openingQuickReplies — four TRANSLATED labels, not four keys', (
      WidgetTester tester,
    ) async {
      await drive(
        tester,
        setUpRepository: (FakeChatRepository r) => r.emptyTranscript(),
      );

      expect(find.text('How to apply for Birth Certificate?'), findsOneWidget);
      expect(find.text('Track my application'), findsOneWidget);
      expect(find.text('Required documents'), findsOneWidget);
      expect(find.text('Office hours'), findsOneWidget);
      expect(
        find.textContaining('chat.qr'),
        findsNothing,
        reason:
            'a raw key on screen is the failure a key-presence test '
            'cannot see',
      );

      await shutdown(tester);
    });

    testWidgets('and in Lao', (WidgetTester tester) async {
      await drive(
        tester,
        locale: const Locale('lo'),
        setUpRepository: (FakeChatRepository r) => r.emptyTranscript(),
      );

      expect(find.text('ເວລາເຮັດການ'), findsOneWidget);
      expect(find.textContaining('chat.qr'), findsNothing);

      await shutdown(tester);
    });

    testWidgets('botSuggestions — the transcript\'s LAST message wins', (
      WidgetTester tester,
    ) async {
      await drive(tester);

      expect(find.text('Track my application'), findsOneWidget);
      expect(
        find.text('ເວລາເຮັດການ'),
        findsOneWidget,
        reason:
            'both come from `m6.suggestions`, which is a LITERAL list '
            'from the API and is not translated',
      );
      expect(
        find.text('Required documents'),
        findsNothing,
        reason: 'the opening quick replies are gone once a transcript exists',
      );

      await shutdown(tester);
    });

    testWidgets('tapping a chip sends its LABEL', (WidgetTester tester) async {
      await drive(
        tester,
        setUpRepository: (FakeChatRepository r) => r.emptyTranscript(),
      );

      // The FIRST chip: the strip scrolls horizontally, so a later one may be
      // laid out beyond the viewport and `tap` would have to scroll to it.
      await tester.tap(find.text('How to apply for Birth Certificate?'));
      for (int i = 0; i < 8; i++) {
        await tester.pump();
      }

      // A chip sends its LABEL (`:499`), which means the very first message a
      // citizen sends is often one the app wrote — and it goes through the same
      // trim-and-truncate path as anything they type.
      // `sendMessage`, not `startThread`: the fixture's thread is still live,
      // the transcript is merely empty. A chip on a brand-new conversation
      // would start one, and `chat_bloc_test.dart` covers that path.
      expect(repository.sentCalls.single.body,
          'How to apply for Birth Certificate?');

      await shutdown(tester);
    });
  });

  // ── B9-AC-43 — the support-channel shortcuts ──────────────────────────────

  group('B9-AC-43 — the header shortcuts', () {
    testWidgets('both render when both channels are published, and the phone '
        'falls back to `hotline`', (WidgetTester tester) async {
      await drive(tester);

      expect(
        find.bySemanticsLabel('Call us'),
        findsOneWidget,
        reason:
            'the fixture publishes `hotline` and NOT `phone`, so a port '
            'that read only `phone` would render no call button',
      );
      expect(find.bySemanticsLabel('Email us'), findsOneWidget);

      await shutdown(tester);
    });

    testWidgets('each is HIDDEN until its channel is published — `:239`, '
        '`:249`', (WidgetTester tester) async {
      await drive(
        tester,
        setUpHelp: (FakeHelpChannelsRepository h) => h.nonedPublished(),
      );

      expect(find.bySemanticsLabel('Call us'), findsNothing);
      expect(find.bySemanticsLabel('Email us'), findsNothing);
      expect(
        find.byType(ChatPanelHeader),
        findsOneWidget,
        reason: 'the rest of the header is unaffected',
      );

      await shutdown(tester);
    });

    test('the tel: target strips whitespace and the mailto: one does not — the '
        'asymmetry is the source\'s', () {
      expect(chatTelTarget('1590 234'), 'tel:1590234');
      expect(chatTelTarget(' 020 5555 6666 '), 'tel:02055556666');
      expect(chatTelTarget('1590\t234\n'), 'tel:1590234');
      expect(
        chatMailtoTarget('support@lcc.gov.la'),
        'mailto:support@lcc.gov.la',
      );
      expect(
        chatMailtoTarget('a b@c.la'),
        'mailto:a b@c.la',
        reason: '`:251` has no `.replace(/\\s/g, "")` — only `:241` does',
      );
    });
  });

  // ── B9-AC-44 — the dead wire fields render nothing ────────────────────────

  testWidgets('B9-AC-44 — no widget reads attachment_url, read_at or the POST '
      'response\'s suggestions', (WidgetTester tester) async {
    await drive(tester);

    // The fixture puts a real attachment URL on m3 and a real read_at on m1.
    expect(
      syntheticMessages()[2].attachmentUrl,
      'https://cdn.example.invalid/never-rendered.pdf',
    );
    expect(syntheticMessages()[0].readAt, isNotNull);

    expect(
      find.textContaining('cdn.example.invalid'),
      findsNothing,
      reason: 'there is no attachment UI in the chat',
    );
    expect(
      find.textContaining('09:14:30'),
      findsNothing,
      reason: '`read_at` gates nothing and renders nothing',
    );
    expect(find.byIcon(Icons.attach_file), findsNothing);

    await shutdown(tester);
  });

  // ── B9-AC-42 — Lao renders, and taller ────────────────────────────────────

  group('B9-AC-42 — Lao on API text', () {
    testWidgets('a Lao message body renders with no tofu and no overflow', (
      WidgetTester tester,
    ) async {
      await drive(tester);

      // The bodies are the SAME strings in both locales — they are the
      // citizen's and the agent's own words, not a Bilingual pair — so the Lao
      // glyph question is about the font, not the translation.
      expect(find.textContaining('ພວກເຮົາຊ່ວຍຫຍັງທ່ານໄດ້ແດ່'), findsWidgets);
      expect(
        tester.takeException(),
        isNull,
        reason: 'a RenderFlex overflow surfaces as an exception here',
      );

      await shutdown(tester);
    });

    test('the font chain COVERS every Lao code point the chat renders — the '
        'capability, at the cmap', () {
      // MEASURED CORRECTION, twice over.
      //
      // Draft 1 compared the sign-in prompt's height across locales. Wrong
      // surface: its `Text`s pin `height: 1.5`, so both locales wrap into the
      // same fixed line box and the heights come out IDENTICAL (286.0 both
      // ways). Draft 2 compared a Lao bubble to an English one in the same
      // transcript. Also wrong: the two strings wrap to different line counts
      // at 75 % width, so the comparison measures wrapping, not glyphs.
      //
      // The instrument that actually answers "do these glyphs exist" is the one
      // GOR-246 AC-24 was REOPENED to build, and its own doc states the rule
      // this test obeys: *"a criterion is not discharged by proving that a
      // configuration value was propagated"*. `NotoSansLao` is a Lao-only
      // subset, so a family name reaching a `TextTheme` proves nothing — the
      // `cmap` does.
      //
      // Every character class the chat draws, checked against the resolved
      // chain: the 22 `chat` strings, the synthetic transcript's message
      // bodies, and the thread subjects.
      final Set<int> rendered = <int>{};
      for (final ChatMessage m in syntheticMessages()) {
        rendered.addAll(m.body.runes);
      }
      for (final ChatThread t in syntheticThreads()) {
        rendered.addAll(t.subject.runes);
      }
      final Map<String, dynamic> chat =
          (json.decode(File('assets/i18n/lo.json').readAsStringSync())
              as Map<String, dynamic>)['chat'] as Map<String, dynamic>;
      for (final Object? v in chat.values) {
        rendered.addAll((v! as String).runes);
      }

      final Set<int> lao =
          rendered.where((int r) => r >= 0x0E80 && r <= 0x0EFF).toSet();
      expect(lao, isNotEmpty,
          reason: 'if this is empty the corpus has no Lao in it and the '
              'assertion below is vacuous — the exact failure mode AC-24 hit');

      final Set<int> covered = <int>{
        // The two faces the app actually bundles — a list naming faces that
        // are not there would silently shrink the covered set.
        for (final String face in <String>[
          'assets/fonts/NotoSansLao-Regular.ttf',
          'assets/fonts/NotoSansLao-Bold.ttf',
        ])
          if (File(face).existsSync()) ...cmapCodePoints(File(face)),
      };

      expect(covered, isNotEmpty,
          reason: 'no Lao face resolved — a coverage check against an empty '
              'set passes for every input');
      expect(lao.difference(covered), isEmpty,
          reason: 'these Lao code points would render as tofu in the chat: '
              '${lao.difference(covered).map(_hex).join(", ")}');
    });

    testWidgets('neither locale overflows the panel', (
      WidgetTester tester,
    ) async {
      for (final Locale locale in <Locale>[Locale('en'), Locale('lo')]) {
        await drive(tester, signedIn: false, locale: locale);
        expect(tester.takeException(), isNull,
            reason: 'a RenderFlex overflow in ${locale.languageCode} surfaces '
                'as an exception here');
        expect(find.byType(ChatSignInPrompt), findsOneWidget);
      }
    });
  });

  // ── the composer ──────────────────────────────────────────────────────────

  group('the composer', () {
    testWidgets('the placeholder is translated, in both locales', (
      WidgetTester tester,
    ) async {
      await drive(tester);
      final TextField field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration!.hintText, 'Type your message...');
      expect(field.decoration!.hintText, isNot(contains('chat.')));

      await shutdown(tester);
    });

    testWidgets('typing enables the send button and a failed send puts the '
        'text back into the field', (WidgetTester tester) async {
      await drive(tester);

      await tester.enterText(find.byType(TextField), 'ຂໍຄວາມຊ່ວຍເຫຼືອ');
      for (int i = 0; i < 4; i++) {
        await tester.pump();
      }
      expect(bloc.state.canSend, isTrue);

      repository.failEverything();
      await tester.tap(find.bySemanticsLabel('Send message'));
      for (int i = 0; i < 8; i++) {
        await tester.pump();
      }

      final TextField field = tester.widget<TextField>(find.byType(TextField));
      expect(
        field.controller!.text,
        'ຂໍຄວາມຊ່ວຍເຫຼືອ',
        reason:
            'the CONTROLLER, not just the BLoC — this is the assertion '
            'that proves the write-back listener actually runs',
      );

      await shutdown(tester);
    });

    testWidgets('a successful send clears the field', (
      WidgetTester tester,
    ) async {
      await drive(tester);

      await tester.enterText(find.byType(TextField), 'hello');
      for (int i = 0; i < 4; i++) {
        await tester.pump();
      }
      await tester.tap(find.bySemanticsLabel('Send message'));
      for (int i = 0; i < 8; i++) {
        await tester.pump();
      }

      final TextField field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '');

      await shutdown(tester);
    });
  });
}

String _en(int n) => '$n out of 5';
String _lo(int n) => '$n ຈາກ 5';

String _hex(int c) => 'U+${c.toRadixString(16).toUpperCase()}';

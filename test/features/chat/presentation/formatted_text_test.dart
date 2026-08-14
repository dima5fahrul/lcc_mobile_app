/// **B9-AC-40 — `formatText` handles every shape of server-supplied text
/// without throwing and without dropping content.**
///
/// specs.md § 6.14 and § 7.8: this parser runs on **message bodies from the
/// API** (`CustomerServiceChat.tsx:402`), so it is a security-review item and
/// not only a fidelity one. The edge cases below are the ones the source's
/// regex actually has, read off `/\*\*(.*?)\*\*/` rather than imagined.
///
/// ## The no-content-lost property is asserted structurally
///
/// Enumerating edge cases proves the ones enumerated. The invariant at the
/// bottom — *every code unit of the input that is not a paired `**` delimiter
/// appears in exactly one run* — is checked against a corpus that includes
/// asterisk soup, lone surrogates' worth of Lao combining marks, and the
/// fixture's own message bodies. That is the claim the security review needs;
/// the individual cases are how it is debugged when it fails.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/chat/presentation/widgets/formatted_text.dart';

import '../chat_test_helper.dart';

/// The plain text a run list renders, i.e. what `toPlainText()` will produce
/// and what the Tier 1 dump therefore compares.
String _plain(List<ChatTextRun> runs) =>
    runs.map((ChatTextRun r) => r.text).join();

/// The input with its **paired** `**` delimiters removed — what the browser's
/// `textContent` would be for the same markup.
String _withoutPairedDelimiters(String input) {
  final List<String> lines = input.split('\n');
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < lines.length; i++) {
    final String line = lines[i];
    int cursor = 0;
    while (true) {
      final int open = line.indexOf('**', cursor);
      if (open < 0) break;
      final int close = line.indexOf('**', open + 2);
      if (close < 0) break;
      out
        ..write(line.substring(cursor, open))
        ..write(line.substring(open + 2, close));
      cursor = close + 2;
    }
    out.write(line.substring(cursor));
    // Index, not value: '\n\n' is three EMPTY lines, so comparing against
    // `lines.last` matches the first one too and eats a separator.
    if (i < lines.length - 1) out.write('\n');
  }
  return out.toString();
}

void main() {
  group('the two rules — `:171-180`', () {
    test('an ordinary bold run splits into three', () {
      expect(parseChatLine('a **b** c'), <ChatTextRun>[
        const ChatTextRun('a '),
        const ChatTextRun('b', bold: true),
        const ChatTextRun(' c'),
      ]);
    });

    test('a body that is only **bold**', () {
      expect(
        parseChatLine('**bold**'),
        <ChatTextRun>[const ChatTextRun('bold', bold: true)],
      );
    });

    test('two runs pair non-greedily — `(.*?)`, not `(.*)`', () {
      expect(parseChatLine('a **b** c **d** e'), <ChatTextRun>[
        const ChatTextRun('a '),
        const ChatTextRun('b', bold: true),
        const ChatTextRun(' c '),
        const ChatTextRun('d', bold: true),
        const ChatTextRun(' e'),
      ]);
      // A greedy regex would bold `b** c **d` — one run instead of two.
      expect(
        parseChatLine('a **b** c **d** e')
            .where((ChatTextRun r) => r.bold)
            .length,
        2,
      );
    });

    test('adjacent runs — `**a**b**c**`', () {
      expect(parseChatLine('**a**b**c**'), <ChatTextRun>[
        const ChatTextRun('a', bold: true),
        const ChatTextRun('b'),
        const ChatTextRun('c', bold: true),
      ]);
    });
  });

  group('the edge cases the regex actually has', () {
    test('an UNCLOSED `**` is plain text, not a bold run to end of line', () {
      expect(
        parseChatLine('a ** b'),
        <ChatTextRun>[const ChatTextRun('a ** b')],
      );
      expect(_plain(parseChatLine('a ** b')), 'a ** b',
          reason: 'the delimiter itself survives — the regex did not match');
    });

    test('`****` renders nothing and loses nothing', () {
      // JS splits to ["", "", ""] and renders an EMPTY <strong>. An empty
      // TextSpan draws exactly nothing, so the run is dropped; the visual
      // result is identical and no content is lost because there is none.
      expect(parseChatLine('****'), isEmpty);
      expect(_plain(parseChatLine('****')), '');
    });

    test('`**` cannot span a newline — the split on \\n happens FIRST', () {
      final List<ChatTextRun> runs = parseChatText('**a\nb**');
      expect(runs.any((ChatTextRun r) => r.bold), isFalse);
      expect(_plain(runs), '**a\nb**',
          reason: 'neither line contains a pair, so both are plain and the '
              'delimiters stay on screen — which is what the web does');
    });

    test('a lone leading or trailing `**` on its own line', () {
      expect(_plain(parseChatText('**')), '**');
      expect(_plain(parseChatText('x**')), 'x**');
      expect(_plain(parseChatText('**x')), '**x');
    });

    test('the empty string, and a body of only newlines', () {
      expect(parseChatText(''), isEmpty);
      expect(_plain(parseChatText('\n\n')), '\n\n',
          reason: 'three empty lines, two <br/>s');
      expect(
        parseChatText('\n\n').where((ChatTextRun r) => r.text == '\n').length,
        2,
      );
    });

    test('multi-line with a bold run on the second line', () {
      final List<ChatTextRun> runs = parseChatText('one\ntwo **three**');
      expect(_plain(runs), 'one\ntwo three');
      expect(runs.where((ChatTextRun r) => r.bold).single.text, 'three');
    });
  });

  group('§ 7.8 — server-supplied text: never throws, never drops content', () {
    final List<String> corpus = <String>[
      '',
      '*',
      '**',
      '***',
      '****',
      '*****',
      '**********',
      '**a',
      'a**',
      '**a**',
      '**a**b',
      'a**b**c**d',
      '\n',
      '\n**\n',
      '**\n**',
      'ຂ້ອຍຕ້ອງການ **ໃບຢັ້ງຢືນການເກີດ**\nສຳລັບລູກຂອງຂ້ອຍ',
      'ສະບາຍດີ! 👋 **ຍິນດີຕ້ອນຮັບ**',
      '**👋**',
      '<script>alert(1)</script>',
      '**<b>not html</b>**',
      r'\**escaped**',
      'a' * 5000,
      '**${'b' * 5000}**',
    ];

    test('no input throws', () {
      for (final String input in corpus) {
        expect(() => parseChatText(input), returnsNormally, reason: input);
      }
      // Plus every body in the synthetic transcript, which is the shape the
      // API actually sends.
      for (final message in syntheticMessages()) {
        expect(() => parseChatText(message.body), returnsNormally);
      }
    });

    test('no input loses a code unit that is not a paired delimiter', () {
      for (final String input in corpus) {
        expect(
          _plain(parseChatText(input)),
          _withoutPairedDelimiters(input),
          reason: 'content dropped for: ${input.length > 40 ? '${input.substring(0, 40)}…' : input}',
        );
      }
      for (final message in syntheticMessages()) {
        expect(
          _plain(parseChatText(message.body)),
          _withoutPairedDelimiters(message.body),
        );
      }
    });

    test('there is no recursion and no backtracking to exhaust', () {
      // A pathological alternating input that would blow up a naive regex.
      final String pathological = '**a' * 20000;
      expect(() => parseChatText(pathological), returnsNormally);
      // And it still loses nothing at that size — the invariant, not a
      // hand-computed length.
      expect(
        _plain(parseChatText(pathological)),
        _withoutPairedDelimiters(pathological),
      );
    });

    test('markup in the body is TEXT, not markup — there is no HTML path', () {
      final List<ChatTextRun> runs = parseChatText('<b>x</b> & "y"');
      expect(_plain(runs), '<b>x</b> & "y"',
          reason: 'the parser produces TextSpans from plain strings; there is '
              'no HTML renderer in this widget and therefore no injection '
              'surface (§ 7.8 item 1)');
    });
  });

  group('the rendered widget', () {
    testWidgets('a bold run carries w700 and the rest does not', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatFormattedText(
              text: 'a **b** c',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      );

      final Text widget = tester.widget<Text>(find.byType(Text));
      final List<InlineSpan> spans =
          (widget.textSpan! as TextSpan).children!.cast<InlineSpan>();

      expect(spans, hasLength(3));
      expect((spans[0] as TextSpan).style?.fontWeight, isNull);
      expect((spans[1] as TextSpan).style?.fontWeight, FontWeight.w700);
      expect((spans[2] as TextSpan).style?.fontWeight, isNull);
    });

    testWidgets('toPlainText() is what Tier 1 will compare, and it has no '
        'delimiters in it', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatFormattedText(
              text: 'ຂ້ອຍຕ້ອງການ **ໃບຢັ້ງຢືນການເກີດ**\nສຳລັບລູກ',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      );

      final Text widget = tester.widget<Text>(find.byType(Text));
      expect(
        widget.textSpan!.toPlainText(),
        'ຂ້ອຍຕ້ອງການ ໃບຢັ້ງຢືນການເກີດ\nສຳລັບລູກ',
      );
    });
  });
}

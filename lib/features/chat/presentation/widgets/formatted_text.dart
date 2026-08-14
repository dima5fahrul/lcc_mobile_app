/// `formatText` — the two-rule mini-markdown, and **the only rich text in this
/// app**.
///
/// `CustomerServiceChat.tsx:171-180`:
///
/// ```tsx
/// const formatText = (text: string) =>
///   text.split("\n").map((line, i) => (
///     <span key={i}>
///       {line.split(/\*\*(.*?)\*\*/).map((part, j) =>
///         j % 2 === 1 ? <strong key={j}>{part}</strong> : part
///       )}
///       {i < text.split("\n").length - 1 && <br />}
///     </span>
///   ));
/// ```
///
/// Two rules. Split on `\n` into line spans separated by `<br/>`; split each
/// line on the non-greedy `/\*\*(.*?)\*\*/` **with a capture group**, which in
/// JavaScript makes `String.prototype.split` interleave the captures into the
/// result, and bold the odd indices. No nesting, no escaping, no links, no
/// lists, no italics.
///
/// ## Why this is a security-review item and not only a fidelity one
///
/// It is applied to `t("greeting")` (`:358`), to the optimistic bubble (`:424`)
/// — and to **every message body** (`:402`), which arrives from the API. So this
/// parser runs on **server-supplied text**. specs.md § 6.14 and § 7.8 require
/// that it cannot throw and cannot drop content on any input, which is why the
/// implementation below is a linear scan with no recursion and no lookahead
/// rather than a regex with a capture group whose semantics differ between the
/// two languages.
///
/// The `RegExp` route was tried and rejected: Dart's `String.split(RegExp)` does
/// **not** interleave capture groups the way JavaScript's does, so the
/// odd-index-is-bold trick has no Dart equivalent. Reproducing JS `split`'s
/// behaviour on top of Dart's would mean re-deriving the split points from
/// `allMatches` anyway — which is what this does directly, and legibly.
///
/// ## The edge cases are measured, not imagined
///
/// | Input | JS result | Why |
/// |---|---|---|
/// | `a **b** c` | `a `, **b**, ` c` | the ordinary case |
/// | `**bold**` | **bold** | a body that is only bold; the leading and trailing splits are empty strings and React renders nothing for them |
/// | `a ** b` | `a ** b`, plain | unclosed: the regex needs a closing pair, so there is no match and `split` returns the whole line |
/// | `****` | one empty `<strong>` | `(.*?)` matches the empty string; the bold span exists and is empty |
/// | `**a\nb**` | no bold at all | the split on `\n` happens **first**, so a `**` pair can never span a line break |
/// | `a **b** c **d** e` | two bold runs | non-greedy, so `**b**` and `**d**` pair up rather than `b** c **d` |
library;

import 'package:flutter/widgets.dart';

/// One run of the parse: a piece of text and whether it is bold.
///
/// Exposed so the parser can be tested as a pure function — asserting a
/// `TextSpan` tree is asserting the renderer as well, and B9-AC-40's claims are
/// about the parse.
@immutable
class ChatTextRun {
  const ChatTextRun(this.text, {this.bold = false});

  final String text;
  final bool bold;

  @override
  bool operator ==(Object other) =>
      other is ChatTextRun && other.text == text && other.bold == bold;

  @override
  int get hashCode => Object.hash(text, bold);

  @override
  String toString() => bold ? '**$text**' : text;
}

/// One line's worth of runs — `line.split(/\*\*(.*?)\*\*/)` with the odd
/// indices bolded.
///
/// Empty runs are dropped, which is what React does with an empty string child:
/// it renders nothing. `****` is the exception the table above records — the
/// bold run is empty and the `<strong>` still exists — and it is dropped here
/// too, because an empty `TextSpan` with a bold style renders exactly nothing
/// either. **No content is lost in any case**: every code unit of the input
/// that is not one of the paired `**` delimiters appears in exactly one run.
List<ChatTextRun> parseChatLine(String line) {
  final List<ChatTextRun> runs = <ChatTextRun>[];
  int cursor = 0;

  while (true) {
    final int open = line.indexOf('**', cursor);
    if (open < 0) break;
    // Non-greedy `(.*?)`: the FIRST following `**` closes the run.
    final int close = line.indexOf('**', open + 2);
    // Unclosed — the regex does not match, so `split` returns the line whole
    // and everything from `cursor` on is plain text.
    if (close < 0) break;

    if (open > cursor) {
      runs.add(ChatTextRun(line.substring(cursor, open)));
    }
    final String bold = line.substring(open + 2, close);
    if (bold.isNotEmpty) runs.add(ChatTextRun(bold, bold: true));
    cursor = close + 2;
  }

  if (cursor < line.length) runs.add(ChatTextRun(line.substring(cursor)));
  return runs;
}

/// The whole body — `text.split("\n")`, then each line, with `\n` between.
///
/// The newline is carried as its own plain run rather than as a widget break,
/// so a single `Text.rich` renders the body and `text_dump.dart`'s
/// `toPlainText()` flattens it to the same string the web presents. A column of
/// per-line widgets would emit one Tier 1 node per line, where the web's `<br/>`
/// is one text block.
List<ChatTextRun> parseChatText(String text) {
  final List<String> lines = text.split('\n');
  final List<ChatTextRun> runs = <ChatTextRun>[];
  for (int i = 0; i < lines.length; i++) {
    runs.addAll(parseChatLine(lines[i]));
    // `{i < lines.length - 1 && <br />}` — `:177`.
    if (i < lines.length - 1) runs.add(const ChatTextRun('\n'));
  }
  return runs;
}

/// [parseChatText] as a `Text.rich`.
///
/// `<strong>` maps to `FontWeight.w700`, not `FontWeight.bold`'s alias — same
/// value, but written as the weight the browser's default `<strong>` resolves
/// to so the mapping is legible next to the source.
class ChatFormattedText extends StatelessWidget {
  const ChatFormattedText({
    super.key,
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final List<ChatTextRun> runs = parseChatText(text);
    return Text.rich(
      TextSpan(
        style: style,
        children: <InlineSpan>[
          for (final ChatTextRun run in runs)
            TextSpan(
              text: run.text,
              style: run.bold
                  ? const TextStyle(fontWeight: FontWeight.w700)
                  : null,
            ),
        ],
      ),
    );
  }
}

// Regenerates `test/architecture/tr_allowlist.yaml` from the tree.
//
// **This tool may only ever be used to SHRINK the list.** It is here so that a
// batch which removes bare `.tr()` sites can drop their entries without hand-
// editing 300 lines, and so the recorded `line:` values can be refreshed after
// an unrelated edit shifts them. Running it to absorb a *new* bare `.tr()` is
// the exact move G-L8 exists to prevent, and `tr_allowlist_test.dart`'s ceiling
// check will fail the build if it happens.
//
//   dart run tool/generate_tr_allowlist.dart
//
// It prints the new entry count so a commit message can state the ceiling
// (§ 6.15(2), B10-AC-57).
import 'dart:io';

import '../test/architecture/layering_rules.dart';

/// Best-effort owner attribution, by path. Used for the `batch:` field, which
/// is documentation for whoever is shrinking the list — it is not part of the
/// match key, so a wrong guess costs a reader a minute and never a build.
String owningBatch(String path) {
  if (path.startsWith('features/account/')) return 'B8';
  if (path.startsWith('features/auth/')) return 'P0';
  if (path.startsWith('features/chat/')) return 'B9b';
  if (path.startsWith('features/notifications/')) return 'B9a';
  if (path.startsWith('features/help/')) return 'B2c';
  if (path.startsWith('features/news/')) return 'B2c';
  if (path.startsWith('features/service/')) return 'B2a';
  if (path.startsWith('features/home/')) return 'B2b';
  if (path.startsWith('features/history/')) return 'stub';
  if (path.startsWith('features/wallet/')) return 'stub';
  if (path.startsWith('presentation/shell/')) return 'P0';
  if (path.startsWith('presentation/')) return 'B2a';
  if (path.startsWith('core/')) return 'P0';
  return 'unknown';
}

void main() {
  final List<DartFile> files = scanTree(kLibDir);

  final StringBuffer out = StringBuffer();
  out.writeln('# tr_allowlist.yaml — G-L8\'s shrinking allowlist (B10 § 6.7.4).');
  out.writeln('#');
  out.writeln('# Every entry is one `.tr()` call in `lib/**` that does NOT pass');
  out.writeln('# `context:` and therefore reads `Localization.instance`, a global,');
  out.writeln('# registering no `InheritedWidget` dependency. That is D-3.');
  out.writeln('#');
  out.writeln('# ── THE ONE RULE ─────────────────────────────────────────────────');
  out.writeln('#');
  out.writeln('# **ADDING AN ENTRY TO MAKE A BUILD PASS IS FORBIDDEN.**');
  out.writeln('#');
  out.writeln('# This list is a CEILING, not a registry. It exists because B10 could');
  out.writeln('# not migrate ~300 pre-existing sites across four concurrently-authored');
  out.writeln('# batches without becoming unmergeable (§ 6.7.3), and a guard that');
  out.writeln('# failed on all of them would have been switched off within a day');
  out.writeln('# (§ 6.7.4). It converts an unbounded backlog into a countable one.');
  out.writeln('#');
  out.writeln('# If G-L8 fails on your new code, the fix is `.tr(context: context)`.');
  out.writeln('# If your widget has no context — a BLoC, a mapper, a `static final` —');
  out.writeln('# then the string is being resolved outside the widget tree and that is');
  out.writeln('# its own defect (GG-3); raise it, do not list it.');
  out.writeln('#');
  out.writeln('# Every batch after B10 leaves this file SHORTER than it found it.');
  out.writeln('# `tr_allowlist_test.dart` asserts the count never grows.');
  out.writeln('#');
  out.writeln('# ── HOW ENTRIES MATCH ────────────────────────────────────────────');
  out.writeln('#');
  out.writeln('# `file` + `key`, as a multiset — N bare calls on the same key in the');
  out.writeln('# same file need N entries. `line` is recorded for navigation and is');
  out.writeln('# NOT the match key: this tree has concurrent writers, and a');
  out.writeln('# line-keyed list goes stale the moment somebody adds a comment above');
  out.writeln('# a listed call. See `glL8Violations`\' DECLARED DEVIATION note.');
  out.writeln('#');
  out.writeln('# Regenerate (to SHRINK only): dart run tool/generate_tr_allowlist.dart');
  out.writeln();
  out.writeln('entries:');

  int count = 0;
  for (final DartFile file in files) {
    final List<TrCall> bare =
        trCallsIn(file.source).where((TrCall c) => !c.bound).toList();
    if (bare.isEmpty) continue;
    for (final TrCall call in bare) {
      out.writeln('  - file: "${file.path}"');
      out.writeln('    line: ${call.line}');
      out.writeln('    key: "${call.key}"');
      out.writeln('    batch: "${owningBatch(file.path)}"');
      count++;
    }
  }

  File('test/architecture/tr_allowlist.yaml').writeAsStringSync(out.toString());
  stdout.writeln('tr_allowlist.yaml regenerated: $count entries');
}

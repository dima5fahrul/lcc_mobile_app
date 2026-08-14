/// **B10-AC-10 / AC-11 / AC-12** — the allowlist describes the tree, and only
/// ever shrinks.
///
/// ## Why these live here and not in `layering_test.dart`
///
/// `layering_test.dart` runs G-L8 as a **hard gate**: a bare `.tr()` that is
/// not covered fails the build, and the fix is always the same one line. That
/// check is stable — it only ever fires on new code.
///
/// The three checks below are about the *list*, and they can go stale for a
/// reason that is nobody's defect: another batch deleting or renaming a file
/// leaves its entries dead. Keeping them in their own file means the failure
/// arrives with its own name and its own one-command remedy
/// (`dart run tool/generate_tr_allowlist.dart`, which may only shrink), instead
/// of arriving as "the layering test is red" — the shape that gets a guard
/// deleted rather than fixed.
///
/// ## What "complete and minimal" buys (`B10-AC-11`)
///
/// A list that over-covers is a list that quietly permits sites nobody
/// enumerated. Asserting the emptied-allowlist run reports **exactly** the
/// listed multiset proves the file describes this tree rather than a
/// superset of it.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'layering_rules.dart';

const String _allowlistPath = 'test/architecture/tr_allowlist.yaml';

/// The count recorded at B10's merge — the **ceiling** every later batch must
/// come in under (§ 6.15(2)).
///
/// Measured `2026-08-14` against a tree that also held **47** uncommitted bare
/// sites belonging to a concurrently-running batch (see the batch report). The
/// ceiling is therefore an upper bound on B10's own tree *and* on that batch's
/// in-flight state; it is not a claim that 316 sites are B10's debt.
const int kTrAllowlistCeiling = 316;

void main() {
  late final List<DartFile> files;
  late final List<TrAllowEntry> allowlist;
  late final String yaml;

  setUpAll(() {
    files = scanTree(kLibDir);
    yaml = File(_allowlistPath).readAsStringSync();
    allowlist = parseTrAllowlist(yaml);
  });

  test('B10-AC-10 — the file exists, parses, and every entry is complete', () {
    expect(allowlist, isNotEmpty,
        reason: 'An empty allowlist alongside a green G-L8 would mean either '
            'the whole tree is migrated (it is not) or the parser silently '
            'returned nothing.');

    for (final TrAllowEntry entry in allowlist) {
      expect(entry.path, isNotEmpty);
      expect(entry.key, isNotEmpty);
      expect(entry.line, greaterThan(0));
      expect(entry.batch, isNotEmpty,
          reason: 'every entry names an owning batch, so the backlog can be '
              'handed back rather than just counted');
    }
  });

  test('B10-AC-10 — the header forbids growing the list, in as many words', () {
    // The rule is only a rule if the person about to break it reads it. This
    // asserts the sentence is in the file a developer opens when G-L8 fails.
    expect(
      yaml,
      contains('ADDING AN ENTRY TO MAKE A BUILD PASS IS FORBIDDEN'),
      reason: 'B10-AC-10 requires the header to state it. Without the '
          'sentence, the cheapest way past a G-L8 failure is to append four '
          'lines — and the list stops being a ceiling.',
    );
  });

  test('B10-AC-11 — the list is COMPLETE: with it emptied, G-L8 fails on '
      'exactly the listed sites', () {
    final List<String> withEmptyList =
        glL8Violations(files, allowlist: const <TrAllowEntry>[]);

    expect(
      withEmptyList.length,
      allowlist.length,
      reason: 'The allowlist has ${allowlist.length} entries and the tree has '
          '${withEmptyList.length} bare `.tr()` sites. They must agree: more '
          'sites than entries means the list is incomplete and the gate below '
          'is about to fail; more entries than sites means it over-covers and '
          'is permitting something nobody enumerated.\n'
          'Fix: dart run tool/generate_tr_allowlist.dart (SHRINK ONLY).',
    );
  });

  test('B10-AC-11 — the list is MINIMAL: no dead entries', () {
    expect(
      glL8DeadEntries(files, allowlist: allowlist),
      isEmpty,
      reason: 'A dead entry is a permission that outlived its subject. Either '
          'the site was migrated (delete the entry — that is the list '
          'shrinking, which is the point) or the file moved (regenerate).\n'
          'Fix: dart run tool/generate_tr_allowlist.dart',
    );
  });

  test('the ceiling never rises', () {
    expect(
      allowlist.length,
      lessThanOrEqualTo(kTrAllowlistCeiling),
      reason: 'B10 recorded $kTrAllowlistCeiling as the ceiling. A larger list '
          'means a batch added a bare `.tr()` and listed it instead of passing '
          '`context:`. That is forbidden (§ 6.7.4): every batch after B10 '
          'leaves this file shorter than it found it.',
    );
  });

  test('B10-AC-12 — NO B10-authored file appears in the allowlist', () {
    // The batch that writes the guard is the batch most likely to exempt
    // itself from it. These are B10's seven new production files plus the four
    // it edited for D-3; every `.tr()` in all of them passes `context:`.
    const List<String> b10Files = <String>[
      'presentation/boot/loading_screen.dart',
      'presentation/boot/splash_screens.dart',
      'presentation/boot/splash_slide_visual.dart',
      'presentation/boot/onboarding_categories.dart',
      'presentation/common/app_button.dart',
      'features/home/presentation/widgets/tutorial_overlay.dart',
      'features/home/presentation/widgets/tutorial_steps.dart',
      'presentation/shell/app_bottom_nav.dart',
      'presentation/shell/app_top_bar.dart',
      'features/home/presentation/widgets/home_search_field.dart',
    ];

    final Set<String> listed =
        allowlist.map((TrAllowEntry e) => e.path).toSet();

    for (final String path in b10Files) {
      expect(
        listed,
        isNot(contains(path)),
        reason: '$path is B10\'s and must be fully context-bound. An exemption '
            'here would mean the batch that wrote G-L8 wrote itself out of it.',
      );
    }
  });

  test('B10-AC-12 — and the check above is not vacuous: those files really are '
      'in the scan and really do call .tr()', () {
    // Without this, the assertion above would pass just as well if the files
    // had been deleted or renamed — the classic "green because it inspected
    // nothing" failure the sibling guards' positive controls exist for.
    final DartFile splash = files.firstWhere(
      (DartFile f) => f.path == 'presentation/boot/splash_screens.dart',
      orElse: () => throw StateError('splash_screens.dart missing from scan'),
    );

    final List<TrCall> calls = trCallsIn(splash.source);
    expect(calls, isNotEmpty,
        reason: 'splash_screens.dart calls .tr() several times; a scan that '
            'found none is a broken scanner, not a clean file.');
    expect(
      calls.where((TrCall c) => !c.bound),
      isEmpty,
      reason: 'every .tr() in a B10 file passes `context:`',
    );
  });

  test('hero_header.dart is bound — the D-3 fix, seen from the guard', () {
    final DartFile hero = files.firstWhere(
      (DartFile f) =>
          f.path == 'features/home/presentation/widgets/hero_header.dart',
    );
    final Iterable<TrCall> greeting =
        trCallsIn(hero.source).where((TrCall c) => c.key == 'home.greeting');

    expect(greeting, hasLength(1));
    expect(greeting.single.bound, isTrue,
        reason: 'one of the nine strings § 6.6.1 measured going stale');
  });
}

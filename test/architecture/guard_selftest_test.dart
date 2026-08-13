/// **B2-AC-7 — the guard negative control** (specs.md § 6.7.7).
///
/// `layering_test.dart` proves the five guards are *green over `lib/`*. That is
/// only half a signal: a guard that can never fire is also green over `lib/`,
/// and `d22cd98`'s commit message recorded exactly that gap — *"NOT YET PROVEN:
/// the guards have not been observed failing when their rule is violated."*
/// The test file itself worried about the same thing, asserting its scan found
/// files "because a guard that inspects nothing passes trivially, which is
/// worse than failing". That check proves the scanner found files; it does not
/// prove any of the five assertions can fire.
///
/// B2 adds five features under those guards. Five guards of unknown efficacy
/// over five new features is not a control. This file is the control.
///
/// ## What "proven" means here, precisely
///
/// For each guard: point the **production** rule function — the same one
/// `layering_test.dart` calls, imported from `layering_rules.dart`, not a copy
/// — at a scan root containing one deliberate violation, and assert
///
/// 1. it returns **exactly** the expected citation list, `path:line -> uri` and
///    all, not merely something non-empty; and
/// 2. the other four guards return **nothing** for that same tree.
///
/// (2) is not padding. A guard that fires on the wrong file is as broken as one
/// that never fires, and it is the failure mode a "did it go red?" check misses
/// entirely: five rules that all fire on everything would pass a naive
/// negative control and would be worthless.
///
/// ## Why the citations are asserted literally
///
/// The line numbers below are the line numbers in the fixture files. That makes
/// this test brittle against editing a fixture — which is the intent. The
/// fixtures are a specification of what a violation looks like; if one is
/// edited, the person editing it should have to state the new expectation
/// rather than have a `hasLength(1)` quietly absorb it.
library;

import 'package:flutter_test/flutter_test.dart';

import 'layering_rules.dart';

const String _root = 'test/architecture/fixtures/violations';

/// The five rule functions, by name, so a self-test can assert on "every guard
/// other than mine". Keyed exactly as the guard IDs in SSD § 4.7.
final Map<String, List<String> Function(List<DartFile>)> _guards =
    <String, List<String> Function(List<DartFile>)>{
  'G-L1': glL1Violations,
  'G-L2': glL2Violations,
  'G-L3': glL3Violations,
  'G-L4': glL4Violations,
  'G-L5': glL5Violations,
};

/// Asserts every guard except [owner] reports nothing over [files].
void _othersStaySilent(String owner, List<DartFile> files) {
  _guards.forEach((String id, List<String> Function(List<DartFile>) rule) {
    if (id == owner) return;
    expect(
      rule(files),
      isEmpty,
      reason: '$id fired on the $owner fixture. A guard that reports a '
          "violation of somebody else's rule is not enforcing its own — the "
          'citation it produces would send a reader to the wrong defect.',
    );
  });
}

void main() {
  group('the scanner is pointable (§ 6.7.7 minimal change)', () {
    test('scanTree takes the root as a parameter, and finds the fixtures', () {
      // The whole self-test rests on this: with `lib` hardcoded there is no
      // way to run a guard over anything but the production tree, and so no
      // way to observe one failing without breaking the build on purpose.
      expect(scanTree('$_root/g_l1').map((DartFile f) => f.path).toList(),
          <String>['data/model.dart', 'presentation/widget.dart']);
    });

    test('a missing root fails loudly rather than scanning nothing', () {
      expect(
        () => scanTree('$_root/does-not-exist'),
        throwsA(isA<MissingScanRoot>()),
      );
    });

    test('the production root is still `lib`', () {
      expect(kLibDir, 'lib');
    });
  });

  test('G-L1 fires on a presentation file importing data/', () {
    final List<DartFile> files = scanTree('$_root/g_l1');

    expect(
      glL1Violations(files),
      <String>['presentation/widget.dart:3 -> ../data/model.dart'],
    );
    _othersStaySilent('G-L1', files);
  });

  test('G-L2 fires on a domain file importing presentation/', () {
    final List<DartFile> files = scanTree('$_root/g_l2');

    expect(
      glL2Violations(files),
      <String>['domain/entity.dart:3 -> ../presentation/widget.dart'],
    );
    _othersStaySilent('G-L2', files);
  });

  test('G-L3 fires on features/a importing features/b/data', () {
    final List<DartFile> files = scanTree('$_root/g_l3');

    expect(
      glL3Violations(files),
      <String>['[a → b] features/a/di/x.dart:7 -> ../../b/data/y.dart'],
    );
    _othersStaySilent('G-L3', files);
  });

  test('G-L4 fires on a core file importing package:flutter/material.dart', () {
    final List<DartFile> files = scanTree('$_root/g_l4');

    expect(
      glL4Violations(files),
      <String>['core/thing.dart:3 -> package:flutter/material.dart'],
    );
    // The second half of G-L4 is a different rule with a different failure
    // mode, so it gets its own assertion rather than riding on the first.
    expect(glL4Unclassified(files), isEmpty);
    _othersStaySilent('G-L4', files);
  });

  test('G-L5 fires on a presentation file naming authInjection', () {
    final List<DartFile> files = scanTree('$_root/g_l5');

    // Both halves, in the order the rule emits them: the import edge first,
    // then the identifier. One citation apiece.
    expect(
      glL5Violations(files),
      <String>[
        '[di import] presentation/page.dart:8 -> ../di/auth_injection.dart',
        '[locator `authInjection`] presentation/page.dart',
      ],
    );
    _othersStaySilent('G-L5', files);
  });

  group('the two behaviours the guards are quietly built on', () {
    test('comments are stripped, so documenting a rule is not violating it',
        () {
      // `language_toggle.dart`, `app_top_bar.dart` and `auth_page.dart` all
      // name a locator inside a doc comment while explaining the seam. If the
      // stripper regressed, the only route to green would be deleting those
      // explanations — so this is load-bearing, not hygiene.
      const String src = '''
// injection<StorageService>() in a line comment
/* authInjection in a block comment */
/// sessionInjection in a doc comment
const String kept = 'injection';
''';
      final String stripped = stripComments(src);

      expect(stripped, isNot(contains('authInjection')));
      expect(stripped, isNot(contains('sessionInjection')));
      // String CONTENTS survive: `'\${injection<T>()}'` must still be caught.
      expect(stripped, contains("'injection'"));
    });

    test('generated files are excluded from every scan', () {
      // `*.freezed.dart` / `*.g.dart` inherit their source file's placement
      // (§ 4.7) and would otherwise report violations nobody can fix by hand.
      final List<DartFile> lib = scanTree(kLibDir);

      expect(lib, isNotEmpty);
      expect(
        lib.where((DartFile f) =>
            f.path.endsWith('.freezed.dart') || f.path.endsWith('.g.dart')),
        isEmpty,
      );
    });
  });
}

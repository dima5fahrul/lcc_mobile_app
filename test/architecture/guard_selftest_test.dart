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

/// The rule functions, by name, so a self-test can assert on "every guard other
/// than mine". Keyed exactly as the guard IDs in SSD § 4.7.
///
/// **G-L7 joins the map, not just the file** (B9a, B9-AC-8). Adding a guard
/// without adding it here would leave the other six unproven against *its*
/// fixture and it unproven against theirs — which is half the control, and the
/// half that catches a rule firing on somebody else's defect.
///
/// **G-L6 joins the map at F0b** (`F0-AC-74`), in the narrowed form
/// `glL6Violations` documents — `data/` and `core/`, not all of
/// `lib/features/**`. B9a's refusal was of F0's *wording*, which fails on 218
/// measured lines of today's tree; the edge § 6.1.2 row 3 actually names is
/// this one, and nothing else in the map can see it. Its cross-check pulls its
/// weight immediately: G-L1 and G-L2 both live one path segment away from it.
final Map<String, List<String> Function(List<DartFile>)> _guards =
    <String, List<String> Function(List<DartFile>)>{
  'G-L1': glL1Violations,
  'G-L2': glL2Violations,
  'G-L3': glL3Violations,
  'G-L4': glL4Violations,
  'G-L5': glL5Violations,
  'G-L6': glL6Violations,
  'G-L7': glL7Violations,
  // **G-L8 joins the map, not just the file** (B10, `B10-AC-9`), for the same
  // reason G-L7 did. It is bound with an EMPTY allowlist: the point of the
  // cross-check is "does this rule fire on somebody else's fixture", and an
  // allowlist could only ever suppress a report, never cause one.
  'G-L8': _glL8Unlisted,
};

List<String> _glL8Unlisted(List<DartFile> files) =>
    glL8Violations(files, allowlist: const <TrAllowEntry>[]);

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

  test('G-L7 fires on a lib/presentation file importing a feature s '
      'presentation/', () {
    final List<DartFile> files = scanTree('$_root/g_l7');

    // The fixture tree is two files: the offender and the target it reaches
    // for. Asserted here rather than taken on trust, because a G-L7 that
    // reported nothing because the scan found nothing would look identical to
    // a G-L7 that reported nothing because it works.
    expect(
      files.map((DartFile f) => f.path).toList(),
      <String>[
        'features/notifications/presentation/bell.dart',
        'presentation/shell/app_bar_fixture.dart',
      ],
    );

    expect(
      glL7Violations(files),
      <String>[
        'presentation/shell/app_bar_fixture.dart:20 -> '
            '../../features/notifications/presentation/bell.dart',
      ],
    );
    _othersStaySilent('G-L7', files);
  });

  test('B10-AC-9 — G-L8 fires on a bare .tr(), and on nothing else in the '
      'fixture', () {
    final List<DartFile> files = scanTree('$_root/g_l8');

    // Asserted, not assumed: a G-L8 that reported nothing because the scan
    // found nothing looks identical to a G-L8 that works.
    expect(
      files.map((DartFile f) => f.path).toList(),
      <String>['features/planted/presentation/bare_tr_fixture.dart'],
    );

    // EXACTLY two of the fixture's three call sites, by `path:line -> key`.
    // The middle one passes `context:` and must not be here; the third
    // mentions `context` only inside a nested argument and must be.
    expect(
      _glL8Unlisted(files),
      <String>[
        'features/planted/presentation/bare_tr_fixture.dart:23 -> '
            'planted.bare.tr() has no `context:`',
        'features/planted/presentation/bare_tr_fixture.dart:30 -> '
            'planted.nested.tr() has no `context:`',
      ],
    );
    _othersStaySilent('G-L8', files);
  });

  test('B10-AC-9 — and the allowlist really does suppress, one site at a time',
      () {
    // The other half of the control. A guard whose allowlist did nothing would
    // pass the test above and be useless; a guard whose allowlist suppressed
    // everything would pass it too and be worse.
    final List<DartFile> files = scanTree('$_root/g_l8');
    const String path = 'features/planted/presentation/bare_tr_fixture.dart';

    final List<String> oneListed = glL8Violations(
      files,
      allowlist: const <TrAllowEntry>[
        TrAllowEntry(path: path, line: 23, key: 'planted.bare', batch: 'test'),
      ],
    );

    expect(oneListed, <String>['$path:30 -> planted.nested.tr() has no `context:`'],
        reason: 'listing one site suppresses exactly that site');

    // And a line number that no longer matches must NOT break the suppression
    // — that is the declared deviation, asserted rather than described.
    final List<String> wrongLine = glL8Violations(
      files,
      allowlist: const <TrAllowEntry>[
        TrAllowEntry(path: path, line: 999, key: 'planted.bare', batch: 'test'),
      ],
    );
    expect(wrongLine, oneListed,
        reason: 'entries match on `path::key`; `line` is navigation, not the '
            'key. A comment added above a listed call must not turn the guard '
            'red — that is how a guard gets deleted instead of fixed.');

    // But a wrong KEY must not suppress anything.
    final List<String> wrongKey = glL8Violations(
      files,
      allowlist: const <TrAllowEntry>[
        TrAllowEntry(path: path, line: 23, key: 'planted.other', batch: 'test'),
      ],
    );
    expect(wrongKey, hasLength(2),
        reason: 'an entry for a key that is not there suppresses nothing');
  });

  test('B10-AC-9 — a dead entry is reported as dead', () {
    final List<DartFile> files = scanTree('$_root/g_l8');
    const String path = 'features/planted/presentation/bare_tr_fixture.dart';

    expect(
      glL8DeadEntries(
        files,
        allowlist: const <TrAllowEntry>[
          TrAllowEntry(path: path, line: 23, key: 'planted.bare', batch: 't'),
          // `planted.bound` passes `context:` — nothing to exempt.
          TrAllowEntry(path: path, line: 26, key: 'planted.bound', batch: 't'),
        ],
      ),
      <String>[
        '$path::planted.bound — listed 1 time(s), found 0. Delete the surplus '
            'entry: the list may only shrink, and it shrinks by deletion.',
      ],
    );
  });

  test('F0-AC-74 — G-L6 fires on a data/ file importing presentation/', () {
    final List<DartFile> files = scanTree('$_root/g_l6');

    // Assertion 1: the guard reports EXACTLY the planted edge.
    expect(
      glL6Violations(files),
      <String>['data/repo.dart:11 -> ../presentation/widget.dart'],
    );
    // Assertion 2: nobody else claims it.
    _othersStaySilent('G-L6', files);
  });

  test('F0-AC-74 — and G-L6 is green on the real tree', () {
    // The second half of the pair. A guard shown only to fire is a guard that
    // might fire on everything; `layering_test.dart` runs this too, but the
    // pair belongs together in one place because § 6.1.3 asks for "two
    // assertions" and this is the second.
    expect(glL6Violations(scanTree(kLibDir)), isEmpty);
  });

  test('G-L6 is not G-L2 wearing a different name', () {
    // G-L2 forbids `domain/ -> presentation/` and G-L6 forbids
    // `data/ -> presentation/`. Adjacent edges, deliberately split: G-L2 opens
    // with `files.where((f) => f.under('domain'))`, so it is blind to a
    // repository by construction. If a future change taught G-L2 to see this,
    // both would fire and the citations would disagree about which rule broke.
    final List<DartFile> files = scanTree('$_root/g_l6');

    expect(
      glL2Violations(files),
      isEmpty,
      reason: 'G-L2 is expected to be BLIND to a `data/ -> presentation/` edge',
    );
    expect(
      files.firstWhere((DartFile f) => f.path == 'data/repo.dart').under('domain'),
      isFalse,
      reason: 'the specific reason G-L2 cannot see it',
    );
  });

  test('F0-AC-84 — the toUtc() guard FIRES against a planted fixture', () {
    final List<DartFile> files = scanTree('$_root/date_path');

    expect(
      toUtcViolations(files),
      <String>[
        'features/planted/domain/clock_fixture.dart:10 -> '
            'DateTime brokenNow() => DateTime.now().toUtc();',
        'features/planted/domain/clock_fixture.dart:12 -> '
            'String brokenToday() => '
            'DateTime.now().toUtc().toIso8601String().substring(0, 10);',
      ],
    );
  });

  test('F0-AC-84 — and it is green on the real tree', () {
    expect(toUtcViolations(scanTree(kLibDir)), isEmpty);
  });

  test('F0-AC-29 — an unregistered DateTime.now() FIRES', () {
    // The planted file is not in `kDateNowRegister`, so both of its sites are
    // reported. This is the half that catches an F1 page reading the ambient
    // clock inside `buildFormData`.
    final List<DartFile> files = scanTree('$_root/date_path');

    expect(dateNowUnregisteredSites(files), hasLength(2));
    expect(
      dateNowUnregisteredSites(files).first,
      startsWith('features/planted/domain/clock_fixture.dart:10'),
    );
  });

  test('F0-AC-29 — the register really does suppress, and only its own rows',
      () {
    // Capability, not wiring: the same scan over the same tree returns nothing
    // once the offending path is a register key. Asserted by running the rule
    // over the REAL tree, where both register rows exist and are silent, while
    // the fixture's identical construct is not.
    final List<DartFile> lib = scanTree(kLibDir);

    expect(dateNowUnregisteredSites(lib), isEmpty);
    expect(dateNowDeadRegisterRows(lib), isEmpty);

    // And the register is not silently empty — a register with no rows would
    // make both assertions above true for the wrong reason.
    expect(kDateNowRegister, hasLength(2));
    expect(
      kDateNowRegister.keys,
      contains(
        'features/certificates/domain/submission/submission_clock.dart',
      ),
    );
  });

  test('F0-AC-29 — a dead register row is reported as dead', () {
    // The direction that stops the register becoming a waiver. `g_l6/` holds no
    // `DateTime.now()` anywhere, so every register row is dead over it.
    final List<DartFile> files = scanTree('$_root/g_l6');

    expect(dateNowDeadRegisterRows(files), hasLength(kDateNowRegister.length));
    expect(
      dateNowDeadRegisterRows(files).first,
      contains('no such file in the scan'),
    );
  });

  test('F0-AC-40 — the picker-rejection guard FIRES on all three forms', () {
    final List<DartFile> files = scanTree('$_root/picker');
    final List<String> hits = pickerRejectionViolations(files);

    // Four lines, because `allowedExtensions` and `FileType.custom` land on
    // the same one and `mimeType` is reported at its use and at its
    // declaration. The literal list is asserted rather than a count, so editing
    // the fixture forces whoever edits it to restate the expectation.
    expect(hits, <String>[
      'features/planted/presentation/upload_fixture.dart:10 -> '
          "'FileType.custom with allowedExtensions: <String>[pdf]';",
      'features/planted/presentation/upload_fixture.dart:12 -> '
          'bool rejectsByMime(String type) => type == mimeType;',
      'features/planted/presentation/upload_fixture.dart:14 -> '
          "const String mimeType = 'application/pdf';",
      'features/planted/presentation/upload_fixture.dart:16 -> '
          "bool rejectsByExtension(String name) => name.endsWith('.pdf');",
    ]);

    // The line numbers are the FIXTURE's own, which is only true because these
    // scans run over a line-preserving `blankComments` rather than over
    // `DartFile.code` — `stripComments` collapses a block comment to one space
    // and every citation after one would be wrong. `trCallsIn` records the same
    // hazard for G-L8.
  });

  test('F0-AC-40 — and it is green on the real tree, repo-wide', () {
    // Repo-wide is the point. Scoped to `lib/presentation/forms/` this scan
    // could not fail by construction, since F0 builds no upload widget — so
    // the green below is only evidence because the scan root is `lib/`.
    final List<DartFile> lib = scanTree(kLibDir);

    expect(pickerRejectionViolations(lib), isEmpty);
    expect(
      lib.where((DartFile f) => f.segments.first == 'features'),
      isNotEmpty,
      reason: 'the scan must actually reach `lib/features/**` — that is where '
          "F1's uploaders will land and the whole reason this guard is "
          'repo-wide',
    );
  });

  test('F0-AC-22 — the kernel-variant guard FIRES against a planted fixture',
      () {
    final List<DartFile> files = scanTree('$_root/kernel_variant');
    final List<String> hits = forbiddenKernelSymbolViolations(files);

    // The literal list, not a count: editing the fixture forces whoever edits
    // it to restate the expectation. Three declaration KINDS deliberately —
    // a fork can arrive as a class or as a typedef alias, and a scan that only
    // knew `class` would miss `typedef RefList = …` entirely.
    expect(hits, <String>[
      'presentation/forms/widgets/variant_fixture.dart:11 -> class SelectField',
      'presentation/forms/widgets/variant_fixture.dart:13 -> '
          'class ApiLocationFields',
      'presentation/forms/widgets/variant_fixture.dart:15 -> typedef RefList',
    ]);

    // `SelectField` also appears in the fixture's header comment (line 4) and
    // is NOT reported. Documenting the rule is not violating it.
    expect(
      hits.where((String h) => h.contains(':4 ')),
      isEmpty,
      reason: 'a forbidden name inside a COMMENT was reported as a '
          'declaration — every kernel doc comment names these symbols to '
          'explain why the variant is not built, so this scan would report '
          'the documentation as the defect',
    );
  });

  test('F0-AC-22 — and it is green on the real tree', () {
    final List<DartFile> lib = scanTree(kLibDir);

    expect(forbiddenKernelSymbolViolations(lib), isEmpty);
    expect(
      lib.where((DartFile f) => f.path.startsWith('presentation/forms/')),
      isNotEmpty,
      reason: 'the scan must actually reach the kernel — scoped to a directory '
          'that does not exist it is green on nothing',
    );
  });

  test('F0-AC-22 — the guard reads DECLARATIONS, not mentions, in real code',
      () {
    // The load-bearing case, measured rather than asserted in prose: the real
    // kernel's doc comments DO name these symbols, repeatedly. If the scan
    // matched a bare name this test would be red on the shipped tree, and the
    // guard would have to be deleted or the documentation gutted.
    final List<DartFile> lib = scanTree(kLibDir);
    final Iterable<DartFile> kernel =
        lib.where((DartFile f) => f.path.startsWith('presentation/forms/'));

    final List<String> mentions = <String>[
      for (final DartFile f in kernel)
        for (final String symbol in kForbiddenKernelSymbols)
          if (f.source.contains(symbol)) '${f.path} names $symbol',
    ];

    // MEASURED, not assumed. On this tree the list is exactly one entry —
    // `ApiLocationFields`, cited by `location_fields_view.dart` as the source
    // symbol whose *call shape* it reproduces. An earlier draft of this test
    // guessed `SelectField` and was red: the kernel names one of the seven,
    // not all of them, and a self-test that asserts a mention the tree does
    // not contain measures nothing.
    expect(
      mentions,
      isNotEmpty,
      reason: 'the kernel is expected to NAME at least one of the variants it '
          'refuses to build, in a doc comment; if it stopped, this test is '
          'measuring nothing and the one above proves less than it claims',
    );
    expect(forbiddenKernelSymbolViolations(lib), isEmpty);
  });

  test('G-L7 is not G-L3 wearing a different name', () {
    // The two rules describe adjacent edges and the distinction is the whole
    // reason G-L7 had to be written: G-L3 opens with
    // `if (file.feature == null) continue;`, which skips every file under
    // `lib/presentation/` by construction (`layering_rules.dart:364`). That is
    // the hole, and this asserts it is still exactly where G-L7 was aimed —
    // if a future change taught G-L3 to see this edge, the two would both fire
    // on it and the citations would disagree about which rule was broken.
    final List<DartFile> files = scanTree('$_root/g_l7');

    expect(
      glL3Violations(files),
      isEmpty,
      reason: 'G-L3 is expected to be BLIND to this edge. It reporting the '
          'violation would mean the hole G-L7 was written for has been closed '
          'somewhere else, and one of the two rules is now redundant.',
    );

    final DartFile offender = files.firstWhere(
      (DartFile f) => f.path == 'presentation/shell/app_bar_fixture.dart',
    );
    expect(
      offender.feature,
      isNull,
      reason: 'the specific reason G-L3 cannot see it',
    );
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

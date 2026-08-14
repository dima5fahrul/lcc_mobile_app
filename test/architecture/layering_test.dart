/// **G-L1 … G-L5** — the layering guards defined in SSD § 4.7, run over `lib/`.
///
/// Five directory scans over `lib/**/*.dart` (excluding `*.freezed.dart` and
/// `*.g.dart`, which are generated and follow their source file's placement).
/// Each one fails the suite with a `path:line -> uri` list, so a violation
/// names itself rather than making a reviewer diff two trees.
///
/// | Guard | Assertion | Enforces |
/// |---|---|---|
/// | G-L1 | no file under `presentation/` (either kind) imports `**/data/**` | § 3.2 |
/// | G-L2 | no file under `**/domain/**` imports `**/data/**` or `**/presentation/**` | § 3.2 |
/// | G-L3 | no file under `features/A/**` imports `features/B/{data,presentation}/**`, A ≠ B | CFI (§ 4.3) |
/// | G-L4 | no file under `lib/core/**` imports `package:flutter/{material,widgets}.dart` or `features/*/{data,presentation}/**` | § 4.4, § 4.5 |
/// | G-L5 | no file under `lib/presentation/**` or `features/*/presentation/**` names `injection` / `authInjection` / `sessionInjection`, or imports a `**/di/**` path | CR-1 (§ 6.4) |
/// | G-L7 | no file under `lib/presentation/**` imports `features/*/presentation/**` | § 4.4 second half (`ssd.md`:255) |
///
/// **G-L6 is deliberately absent and the number is deliberately unused** — see
/// `layering_rules.dart`'s library doc for the 170 measured lines of today's
/// tree that F0's wording would fail on (B9-AC-9, FU-2).
///
/// **Why G-L5 exists at all.** CR-1 removed the two global-locator reads that
/// lived inside widgets (`LanguageToggle`'s `storage ?? injection<...>()` and
/// `AuthPage.initState`'s `authInjection<AuthBloc>()`). That was a one-time
/// cleanup; B2 adds five more pages, each needing a BLoC, and the cheapest way
/// to give a new page one is the pattern that was just deleted. G-L5 is what
/// makes the fix permanent: the sanctioned seam is "route builders and
/// `main.dart` may resolve from a locator, no widget may", and this test is the
/// half of that sentence a compiler cannot express.
///
/// **The rules themselves live in `layering_rules.dart`** so that
/// `guard_selftest_test.dart` (§ 6.7.7, B2-AC-7) can run *these* five functions
/// against a deliberately-violating fixture tree and prove they fire. Before
/// that self-test existed, `d22cd98`'s commit message recorded the open debt in
/// as many words: *"NOT YET PROVEN: the guards have not been observed failing
/// when their rule is violated."* Every `expect` and every `reason:` below is
/// unchanged from that commit.
library;

import 'package:flutter_test/flutter_test.dart';

import 'layering_rules.dart';

void main() {
  late final List<DartFile> files;

  setUpAll(() {
    files = scanTree(kLibDir);

    expect(
      files,
      isNotEmpty,
      reason: 'Scanned `$kLibDir/` and found no non-generated Dart files. A '
          'guard that inspects nothing passes trivially, which is worse than '
          'failing — treat this as a broken scanner, not a clean tree.',
    );
  });

  test('G-L1 — no presentation file imports a data/ path', () {
    final List<String> violations = glL1Violations(files);

    expect(
      violations,
      isEmpty,
      reason: 'SSD § 3.2: presentation depends on domain, never on data. A '
          'page or BLoC that reaches for a model or a datasource has bound '
          'itself to the wire format. Route the call through a use case and '
          'take the domain entity instead.\nOffenders:\n  '
          '${violations.join('\n  ')}',
    );
  });

  test('G-L2 — no domain file imports a data/ or presentation/ path', () {
    final List<String> violations = glL2Violations(files);

    expect(
      violations,
      isEmpty,
      reason: 'SSD § 3.2: domain is the innermost layer and depends on '
          'nothing outward. Both directions of this edge are defects — a '
          'domain type that knows a model is not portable, and one that knows '
          'a widget is not testable.\nOffenders:\n  '
          '${violations.join('\n  ')}',
    );
  });

  test('G-L3 — no feature imports another feature s data/ or presentation/',
      () {
    final List<String> violations = glL3Violations(files);

    expect(
      violations,
      isEmpty,
      reason: 'Cross-Feature Isolation (SSD § 4.3): one feature may depend on '
          "another feature's `domain/` — that is the shared-kernel edge `auth "
          '→ session/domain` already relies on — but never on its `data/` or '
          "`presentation/`. Reaching into another feature's models or widgets "
          'welds the two release cycles together.\nOffenders:\n  '
          '${violations.join('\n  ')}',
    );
  });

  test('G-L4 — core imports no Flutter UI and no feature data/ or '
      'presentation/', () {
    // ── The rule as § 4.7 words it ───────────────────────────────────────────
    final List<String> violations = glL4Violations(files);

    expect(
      violations,
      isEmpty,
      reason: 'SSD § 4.4 / § 4.5: `lib/core/**` is the layer every feature is '
          'allowed to depend on, so it must not depend on any of them, and it '
          'must stay importable without a widget tree. `material.dart` / '
          "`widgets.dart` in core is how a 'core' utility quietly becomes "
          'un-unit-testable.\nOffenders:\n  ${violations.join('\n  ')}',
    );

    // ── The allowance, stated rather than left implicit ──────────────────────
    // See `glL4Unclassified`'s doc for the nine real `core → features` edges
    // and why exactly two layers are the whole allowance.
    final List<String> unclassified = glL4Unclassified(files);

    expect(
      unclassified,
      isEmpty,
      reason: 'A `core → features/**` import landed in a layer that is '
          'neither `domain/` (the shared kernel, imported not edited) nor '
          '`di/` (the composition root wiring features together). Those two '
          'are the whole allowance. Adding a third means core has grown a '
          'dependency on a feature\'s internals — change the design or widen '
          'this set deliberately, in the SSD first.\nOffenders:\n  '
          '${unclassified.join('\n  ')}',
    );
  });

  test('G-L5 — no presentation file resolves from a global locator', () {
    final List<String> violations = glL5Violations(files);

    expect(
      violations,
      isEmpty,
      reason: 'CR-1 (SSD § 6.4). The seam is: **route builders and `main.dart` '
          'may resolve from a locator; no widget may.** A page needing a BLoC '
          'gets it from a `BlocProvider(create: (_) => xInjection<XBloc>())` in '
          'the route table (`lib/utils/routes/app_routes.dart`); a widget '
          'needing a service takes it as a constructor parameter threaded from '
          'the `ShellRoute` builder. This scales to 21 pages with zero locator '
          'references inside widgets — and every violation below is one more '
          'widget that cannot be pumped in a test without standing a container '
          'up first.\nOffenders:\n  ${violations.join('\n  ')}',
    );
  });

  test('G-L7 — no lib/presentation file imports a feature s presentation/',
      () {
    final List<String> violations = glL7Violations(files);

    expect(
      violations,
      isEmpty,
      reason: '`ssd.md`:255 — `lib/presentation/**` may import `core/**`, '
          '`features/*/domain/**` and other `presentation/**`. It may NOT '
          "import a feature's `presentation/`. The shell is chrome every route "
          'depends on; naming a feature widget there welds the whole app to '
          "that feature's release cycle and makes the shell unpumpable without "
          "the feature's BLoC in the tree.\n"
          'The seam is `AppShell`/`AppTopBar`\'s composed-widget parameters '
          '(specs.md § 6.4): the `ShellRoute` builder in '
          '`lib/utils/routes/app_routes.dart` assembles '
          '`BlocProvider<XBloc>(child: XWidget())` and passes it in. That '
          'builder is not under `lib/presentation/**`, so it is allowed to '
          'know both — and it is already the sanctioned place to resolve from '
          'a container (CR-1).\nOffenders:\n  ${violations.join('\n  ')}',
    );
  });

  test('G-L7 has something to say about — the scan really reaches '
      'lib/presentation', () {
    // The guard above is green over a tree with **zero** such edges, and a
    // rule that inspects nothing is green for the wrong reason. `setUpAll`'s
    // "the scan found files" check does not narrow that: it proves `lib/` is
    // non-empty, not that any file G-L7 filters on survived the filter.
    //
    // `guard_selftest_test.dart` is the real control — it observes G-L7 firing
    // against a planted fixture. This is the cheap companion: it asserts the
    // production scan actually contains the file class the rule is about, so a
    // future refactor that moved or renamed `lib/presentation/` would fail
    // here instead of silently turning G-L7 into a no-op over `lib/`.
    final Iterable<DartFile> shellFiles = files.where(
      (DartFile f) => f.segments.first == 'presentation',
    );

    expect(
      shellFiles,
      isNotEmpty,
      reason: 'G-L7 filters on `segments.first == "presentation"` and the scan '
          'of `$kLibDir/` produced no such file. Either the directory moved or '
          'the scanner stopped reaching it; in both cases G-L7 is now vacuous '
          'over the production tree.',
    );
  });
}

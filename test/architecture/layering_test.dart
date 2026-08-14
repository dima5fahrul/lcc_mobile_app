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
/// | G-L6 | no file under `**/data/**` or `lib/core/**` imports `**/presentation/**` | § 3.2 `ssd.md`:157 |
/// | G-L7 | no file under `lib/presentation/**` imports `features/*/presentation/**` | § 4.4 second half (`ssd.md`:255) |
/// | G-L8 | no `.tr()` in `lib/**` omits `context:`, outside `tr_allowlist.yaml` | D-3 (B10 § 6.7.4) |
/// | O-4a | `toUtc()` appears nowhere in `lib/**` | ADR-0005 O-4 |
/// | O-4b | `DateTime.now()` only at a `kDateNowRegister` site | ADR-0005 O-4 |
/// | R-21 | no code path rejects a picked file by extension or MIME type | specs.md § 6.6.2 |
///
/// **G-L6 lands in F0b, and it is NARROWER than F0's own § 6.1.3 wording** —
/// see `layering_rules.dart`'s `glL6Violations` doc. B9a refused the wording
/// because `grep -rn "presentation/{theme,icons,common,shell}/" lib/features
/// lib/core` returns **218 lines** on this tree (170 at `f530d8e`), every one
/// of them a page importing `presentation/theme/`, which is what that directory
/// is for. Scoped to `data/` and `core/` it is green, and it closes the exact
/// edge § 6.1.2 row 3 names — which nothing in the tree could see.
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

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'layering_rules.dart';

void main() {
  late final List<DartFile> files;
  late final List<TrAllowEntry> trAllowlist;

  setUpAll(() {
    files = scanTree(kLibDir);
    trAllowlist = parseTrAllowlist(
      File('test/architecture/tr_allowlist.yaml').readAsStringSync(),
    );

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

  test('G-L6 — no data/ or core/ file imports a presentation/ path', () {
    final List<String> violations = glL6Violations(files);

    expect(
      violations,
      isEmpty,
      reason: '`ssd.md`:157 — "presentation -> domain, data -> domain, nothing '
          '-> presentation". A repository or a core utility that imports a '
          'widget has inverted the layer it sits in: the wire mapping now '
          'cannot be tested without a widget tree, and the widget cannot be '
          'replaced without touching the data layer.\n'
          'This is the edge RULING 9 was written to prevent (specs.md '
          "§ 6.1.2 row 3): B4's submission executor lives in "
          '`features/certificates/data/`, and the revoked '
          '`lib/presentation/forms/submission/` placement would have had it '
          'importing `lib/presentation/**` by design. G-L1, G-L2, G-L4 and '
          'G-L7 are each scoped elsewhere and none of them could see '
          'it.\nOffenders:\n  ${violations.join('\n  ')}',
    );
  });

  test('G-L6 has something to say about — the scan really reaches data/ and '
      'core/', () {
    // Same positive control as G-L7's, for the same reason: G-L6 is green over
    // a tree with zero such edges, and a rule that inspects nothing is green in
    // exactly the same way.
    expect(
      files.where((DartFile f) => f.under('data')),
      isNotEmpty,
      reason: 'G-L6 filters on `under("data")` and found no such file',
    );
    expect(
      files.where((DartFile f) => f.segments.first == 'core'),
      isNotEmpty,
      reason: 'G-L6 filters on `segments.first == "core"` and found no such file',
    );
  });

  test('ADR-0005 O-4 — toUtc() appears nowhere in lib/', () {
    final List<String> violations = toUtcViolations(files);

    expect(
      violations,
      isEmpty,
      reason: 'ADR-0005 O-4. The web dates every submission with '
          '`new Date().toISOString().slice(0, 10)` — UTC — so in Laos (UTC+7) '
          'every submission made between 00:00 and 07:00 local is dated '
          'YESTERDAY, on eleven call sites reaching eight registered wire '
          'keys. That is the one deliberate divergence this port makes, and '
          'a single `toUtc()` anywhere in `lib/**` puts the defect back.\n'
          'If a date needs formatting, read it from an injected '
          '`SubmissionClock` and use `todayLocal()`.\nOffenders:\n  '
          "${violations.join('\n  ')}",
    );
  });

  test('ADR-0005 O-4 — DateTime.now() only at a registered site', () {
    final List<String> unregistered = dateNowUnregisteredSites(files);

    expect(
      unregistered,
      isEmpty,
      reason: 'The clock is INJECTED, never ambient. A page that reads '
          '`DateTime.now()` inside its `buildFormData` cannot be driven to a '
          'fixed instant, which makes the other ~200 payload keys '
          'incomparable — Tier 0 rests entirely on being able to freeze '
          'this.\nTake a `SubmissionClock` as a parameter. If the site really '
          'is not a date path, add it to `kDateNowRegister` WITH the reason, '
          'so the next reader inherits the argument and not just the '
          "permission.\nOffenders:\n  ${unregistered.join('\n  ')}",
    );

    // The other direction: a register row nobody still needs.
    final List<String> dead = dateNowDeadRegisterRows(files);
    expect(
      dead,
      isEmpty,
      reason: 'A `kDateNowRegister` row whose file no longer holds a '
          '`DateTime.now()`. Membership is recomputed every run precisely so a '
          'permission cannot outlive the thing it permitted — delete the '
          "row.\nDead rows:\n  ${dead.join('\n  ')}",
    );
  });

  test('R-21 — no code path rejects a picked file by type', () {
    final List<String> violations = pickerRejectionViolations(files);

    expect(
      violations,
      isEmpty,
      reason: 'specs.md § 6.6.2. In HTML `accept` filters the picker\'s '
          'default VIEW and rejects nothing — the client performs no MIME or '
          'size validation anywhere. In Flutter `FileType.custom` + '
          '`allowedExtensions` is a hard filter with no escape hatch, so '
          'porting the five `accept` strings that way diverges on ALL FIVE '
          "pages, not on Resident alone.\nThe requirement: a `.pdf` selected "
          'on the Resident form must reach the attachment list. '
          '`AttachmentAcceptPolicy` holds the five source strings as DATA and '
          'is never passed to a picker as a filter.\nOffenders:\n  '
          "${violations.join('\n  ')}",
    );
  });

  test('F0-AC-22 — no kernel VARIANT is declared under presentation/forms/',
      () {
    final List<String> violations = forbiddenKernelSymbolViolations(files);

    expect(
      violations,
      isEmpty,
      reason: 'specs.md § 6.3, RULING 2 — ONE kernel, ZERO variants. Each of '
          '`${kForbiddenKernelSymbols.join('`, `')}` is a CALL SHAPE of a '
          'control the kernel already has, not a control of its own: '
          "Marriage/Divorce's weaker error surface is produced by OMITTING "
          '`failed` / `onRetry` / `emptyMessage` at the call site, exactly as '
          '`formFields.tsx:223` does. A second widget is how one kernel '
          'becomes two that drift, and nothing else in this tree can see one '
          "appear.\nOffenders:\n  ${violations.join('\n  ')}",
    );

    // Non-vacuity. The scan is scoped to `presentation/forms/`, so a scope
    // typo (or the kernel not existing yet) would make it pass on nothing.
    expect(
      files.where((DartFile f) => f.path.startsWith('presentation/forms/')),
      isNotEmpty,
      reason: 'the scan reached no file under `lib/presentation/forms/`',
    );
  });

  test('G-L8 — no .tr() in lib/ omits `context:` outside the allowlist', () {
    final List<String> violations =
        glL8Violations(files, allowlist: trAllowlist);

    expect(
      violations,
      isEmpty,
      reason: 'D-3 (B10 § 6.6). `.tr()` with no `context:` reads '
          '`Localization.instance` — a global — and registers no '
          '`InheritedWidget` dependency, so the string does not repaint when '
          'the citizen changes language. It refreshes on the next navigation '
          'instead, which is the defect, not the behaviour.\n'
          'The fix is `.tr(context: context)`. **Not** removing a `const`: '
          '§ 6.6.3 measured a `const` widget with `context:` refreshing and a '
          'non-const one without it going stale, and commit `d22cd98` had '
          'already removed the `const` from both sites that theory blames '
          'while the defect survived.\n'
          'If the call has no context to pass — a BLoC, a mapper, a '
          '`static final` — the string is being resolved outside the widget '
          'tree, which is GG-3 and its own defect. Raise it; do not append to '
          '`tr_allowlist.yaml`, which may only shrink.\nOffenders:\n  '
          '${violations.join('\n  ')}',
    );
  });

  test('G-L8 has something to say about — the scan really reaches .tr() calls',
      () {
    // Same positive control as G-L7's below, for the same reason: G-L8 is
    // green over a fully-allowlisted tree, and a G-L8 that parsed no calls at
    // all would be green in exactly the same way.
    final int bare = files
        .expand((DartFile f) => trCallsIn(f.source))
        .where((TrCall c) => !c.bound)
        .length;
    final int bound = files
        .expand((DartFile f) => trCallsIn(f.source))
        .where((TrCall c) => c.bound)
        .length;

    expect(bare + bound, greaterThan(100),
        reason: 'the tree has hundreds of `.tr()` calls; finding none means '
            'the scanner stopped reading, not that the tree changed');
    expect(bound, greaterThan(0),
        reason: 'B10 bound at least the nine measured-stale strings. Zero '
            'bound calls means the D-3 fix is not in this tree.');
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

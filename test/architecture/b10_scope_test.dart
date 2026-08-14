/// B10's scope rulings, mechanised — `B10-AC-4`, `B10-AC-5`, `B10-AC-6`,
/// `B10-AC-13`, `B10-AC-43`, `B10-AC-47`, `B10-AC-48`, `B10-AC-49`,
/// `B10-AC-50`.
///
/// § 6.2 and § 6.3 rule `Footer` and `DialogShell` out of scope as
/// **unreachable** and **a framework polyfill**. A ruling recorded only in a
/// spec is a ruling the next batch re-litigates; the point of asserting them
/// here is that re-adding either surface turns the suite red and forces the
/// override to be explicit.
///
/// ## This tree has concurrent writers, and these tests are written for that
///
/// § 2.2 finding 5b: B8a is authoring against the same working tree. Several
/// of B10's git-shaped ACs (`git diff … api_endpoint.dart` is empty) are stated
/// against the *whole* tree and therefore cannot distinguish B10's edits from
/// B8a's. Where that is so, the assertion below is narrowed to the property
/// **B10 actually controls** and the reason is stated at the call site, rather
/// than the test being weakened silently or deleted.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every `.dart` file under `lib/`, as (path, source).
List<({String path, String source})> _libFiles() {
  return Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .map((File f) => (path: f.path, source: f.readAsStringSync()))
      .toList();
}

String _git(List<String> args) {
  final ProcessResult r = Process.runSync('git', args);
  if (r.exitCode != 0) fail('git ${args.join(' ')} failed: ${r.stderr}');
  return (r.stdout as String).trim();
}

/// The Flutter base B10 branched from — `specs.md` metadata.
const String _base = '7db61e7';

void main() {
  test('B10-AC-47 — no `Footer` widget exists anywhere under lib/', () {
    // § 6.2: `Footer.tsx`:35 is `hidden lg:block`; Tailwind v4's stock `lg` is
    // a 1024px VIEWPORT query; a handset never reaches it; and `en/01-home.png`
    // (390×3929) shows FAQ → FAB → bottom nav with no navy band. Porting it
    // would repeat B2's 493 unreachable lines for `/news/:slug`.
    //
    // A stub, a `// TODO`, or a `Visibility(visible: false)` would also fail
    // this — § 6.2 rules those out by name, because an unreachable surface
    // represented by a placeholder is still an unreachable surface.
    // The assertion has to name the SITE footer specifically. A bare
    // `/Footer/` grep is not it: this tree legitimately contains B9's
    // `NotificationMenuFooter` (a bottom-sheet action row) and B8's
    // `_VersionFooter` (the account page's version line). Neither is
    // `Footer.tsx`, and failing on them would make this AC noise that the next
    // batch deletes rather than a ruling that holds.
    //
    // Two signatures, either of which would mean the port happened:
    //   1. a widget class named exactly Footer / AppFooter / SiteFooter;
    //   2. the navy band `#161d3a` — `Footer.tsx`:35's inline
    //      `backgroundColor`, and the one value unique to that surface.
    final List<({String path, String source})> files = _libFiles();

    expect(
      files
          .where((({String path, String source}) f) => RegExp(
                r'class\s+(_?Footer|_?AppFooter|_?SiteFooter)\b',
              ).hasMatch(f.source))
          .map((({String path, String source}) f) => f.path),
      isEmpty,
      reason: 'B10 § 6.2 rules `Footer` OUT OF SCOPE as unreachable on every '
          'viewport a handset has. If this is now wanted, the trigger is a '
          'tablet/desktop target (§ 8.4 FU-4) — a product decision, recorded, '
          'not an implementer\'s.',
    );

    expect(
      files
          .where((({String path, String source}) f) =>
              f.source.toLowerCase().contains('161d3a'))
          .map((({String path, String source}) f) => f.path),
      isEmpty,
      reason: '`#161d3a` is `Footer.tsx`:35\'s navy band and appears nowhere '
          'else in the source. Its presence in `lib/` means the footer was '
          'ported — and `en/01-home.png` (390×3929) shows FAQ → FAB → bottom '
          'nav with no navy band, so it would be ~90 lines no user can reach.',
    );
  });

  test('B10-AC-48 — no `DialogShell`, and no hand-rolled modal a11y', () {
    // § 6.3: `DialogShell.tsx`'s entire payload is `useModalA11y`'s four
    // behaviours — Escape closes, Tab trapped, focus in/restore, scroll lock —
    // all native to `showDialog`/`ModalRoute`. B2 already ruled this in shipped
    // source at both call sites (`lao_id_card.dart`:521-528,
    // `action_banner.dart`:15-17).
    final List<({String path, String source})> files = _libFiles();

    expect(
      files
          .where((({String path, String source}) f) =>
              RegExp(r'class\s+\w*DialogShell\w*\s').hasMatch(f.source))
          .map((({String path, String source}) f) => f.path),
      isEmpty,
      reason: 'porting `DialogShell` yields a widget with zero consumers',
    );

    // The second half, and the one a "no class named DialogShell" grep misses:
    // re-implementing the polyfill under another name. `FocusScope` with
    // explicit trapping, or a manual Escape handler, in a B10 file.
    const List<String> b10Files = <String>[
      'lib/presentation/boot/loading_screen.dart',
      'lib/presentation/boot/splash_screens.dart',
      'lib/presentation/boot/splash_slide_visual.dart',
      'lib/presentation/boot/onboarding_categories.dart',
      'lib/presentation/common/app_button.dart',
      'lib/features/home/presentation/widgets/tutorial_overlay.dart',
      'lib/features/home/presentation/widgets/tutorial_steps.dart',
    ];
    for (final String path in b10Files) {
      final File f = File(path);
      expect(f.existsSync(), isTrue, reason: '$path is missing');
      final String src = f.readAsStringSync();
      for (final String banned in <String>[
        'LogicalKeyboardKey.escape',
        'FocusTrap',
        'RawKeyboardListener',
      ]) {
        expect(
          src.contains(banned),
          isFalse,
          reason: '$path hand-rolls `$banned` — that is `useModalA11y`\'s job '
              'and Flutter already provides it (§ 6.3)',
        );
      }
    }
  });

  test('B10-AC-49 — `glass_icon.dart` is byte-identical to $_base', () {
    // § 6.4: 250 lines, B2a's FU-7 delivery. B10 is a CONSUMER of it (splash
    // slide 1 renders six) and may report a defect in it, never fix it here.
    expect(
      _git(<String>[
        'diff',
        '--numstat',
        _base,
        '--',
        'lib/presentation/common/glass_icon.dart',
      ]),
      isEmpty,
      reason: '`glass_icon.dart` belongs to B2a\'s scope',
    );
  });

  test('B10-AC-50 — `glassTileLight` is not ported (zero web consumers)', () {
    expect(
      _libFiles()
          .where((({String path, String source}) f) =>
              f.source.contains('glassTileLight'))
          .map((({String path, String source}) f) => f.path),
      isEmpty,
      reason: '`glass.ts`\'s `glassTileLight` has zero consumers in '
          '`lcc-app/src`. Porting an unused export is the same class of dead '
          'code as § 6.2\'s Footer.',
    );
  });

  test('B10-AC-13 — `presentation/boot/**` imports no feature presentation',
      () {
    // The direct form of G-L7 for B10's new group. G-L8's sibling guard runs
    // this over the whole tree; asserting it here as well means a regression
    // names `boot/` specifically instead of arriving as a generic G-L7 failure.
    final Iterable<String> offenders = _libFiles()
        .where((({String path, String source}) f) =>
            f.path.startsWith('lib/presentation/boot/'))
        .where((({String path, String source}) f) =>
            RegExp(r'''import\s+['"][^'"]*features/\w+/presentation''')
                .hasMatch(f.source))
        .map((({String path, String source}) f) => f.path);

    expect(
      offenders,
      isEmpty,
      reason: 'G-L7. This is exactly why splash slide 3 takes a '
          '`slide3Visual` slot instead of importing `LaoIdCard` (§ 6.9) — a '
          'direct import here is a build failure, not a style objection.',
    );
  });

  group('B10-AC-43 — `AppButton` ships with real consumers, not as dead code',
      () {
    test('it is imported and used outside its own file', () {
      final List<String> consumers = _libFiles()
          .where((({String path, String source}) f) =>
              !f.path.endsWith('app_button.dart'))
          .where((({String path, String source}) f) =>
              f.source.contains('AppButton('))
          .map((({String path, String source}) f) => f.path)
          .toList();

      expect(
        consumers,
        isNotEmpty,
        reason: '§ 6.5: `AppButton` must ship wired into HomePage\'s live '
            'retry buttons rather than as speculative infrastructure. That is '
            'the § 6.2 lesson applied to B10\'s own output — a widget with no '
            'consumers is the same dead weight as an unreachable surface.',
      );
      expect(
        consumers,
        contains('lib/features/home/presentation/widgets/home_panels.dart'),
        reason: '`HomeErrorNotice` is the Flutter home of the source\'s three '
            '`<Button size="sm" variant="secondary">` retry buttons '
            '(`HomePage.tsx`:331, :471, :635)',
      );
    });

    test('and `HomeErrorNotice` no longer hand-rolls an OutlinedButton', () {
      final String src =
          File('lib/features/home/presentation/widgets/home_panels.dart')
              .readAsStringSync();
      expect(
        src.contains('OutlinedButton('),
        isFalse,
        reason: 'the hand-styled duplicate is what `AppButton` replaces; '
            'leaving it in place beside the import would mean the widget is '
            'imported but not actually the thing on screen',
      );
    });
  });

  group('scope, mechanised (§ 6.15)', () {
    test('B10-AC-4 — zero new dependencies', () {
      expect(
        _git(<String>[
          'diff',
          '--numstat',
          _base,
          '--',
          'pubspec.yaml',
          'pubspec.lock',
        ]),
        isEmpty,
        reason: '§ 4.3 — B10 adds none. No animation package, no carousel, no '
            '`flutter_native_splash`, no `introduction_screen`. Adding one is '
            'an escalation under `ssd.md` § 4.3, not a judgement call.',
      );
    });

    test('B10-AC-5 — `app_shell.dart` is byte-identical', () {
      // The half of AC-5 that is B10's alone. Splash and boot sit ABOVE the
      // shell (§ 6.8) and the tutorial sits INSIDE Home, so the shell needed
      // no edit — the § 3.1 "UNTOUCHED" claim, mechanised.
      expect(
        _git(<String>[
          'diff',
          '--numstat',
          _base,
          '--',
          'lib/presentation/shell/app_shell.dart',
        ]),
        isEmpty,
      );
    });

    test('B10-AC-5 — B10 introduces no endpoint (narrowed; see library doc)',
        () {
      // AC-5 as WRITTEN also requires `api_endpoint.dart` to be byte-identical
      // to $_base. It is not — it carries +36/-0, and **every one of those
      // lines is B8a's** (`me.preferences`, `me.savePreferences`,
      // `me.documents`). B10 contributed none of them, and this suite cannot
      // revert another batch's in-flight work to make its own gate read
      // cleanly (`B10-AC-60`).
      //
      // So the assertion is narrowed to what B10 controls and can honestly
      // prove: **no B10 file names an endpoint at all.** § 5 claims every B10
      // surface is local; § 8.2(5) makes an endpoint a BLOCKED condition. The
      // whole-tree form of AC-5 is reported separately in the batch report.
      const List<String> b10Files = <String>[
        'lib/presentation/boot/loading_screen.dart',
        'lib/presentation/boot/splash_screens.dart',
        'lib/presentation/boot/splash_slide_visual.dart',
        'lib/presentation/boot/onboarding_categories.dart',
        'lib/presentation/common/app_button.dart',
        'lib/features/home/presentation/widgets/tutorial_overlay.dart',
        'lib/features/home/presentation/widgets/tutorial_steps.dart',
      ];
      for (final String path in b10Files) {
        final String src = File(path).readAsStringSync();
        expect(
          src.contains('ApiEndpoint'),
          isFalse,
          reason: '$path references an endpoint. B10\'s scope claims zero; an '
              'endpoint means the scope was wrong (§ 8.2(5)).',
        );
      }
    });

    test('B10-AC-6 — the i18n edits are additive (zero deletions)', () {
      for (final String locale in <String>['en', 'lo']) {
        final String stat = _git(<String>[
          'diff',
          '--numstat',
          _base,
          '--',
          'assets/i18n/$locale.json',
        ]);
        expect(stat, isNotEmpty, reason: '$locale.json should have gained B10\'s keys');

        // `insertions\tdeletions\tpath`
        final List<String> cols = stat.split(RegExp(r'\s+'));
        expect(
          cols[1],
          '0',
          reason: 'assets/i18n/$locale.json shows ${cols[1]} DELETIONS. '
              'i18n is append-only (`ssd.md`:769-770) and every B10 edit to a '
              'shared file must be additive so B6/B7/B8/B10 can merge in any '
              'order (§ 3.1 cross-batch merge statement).',
        );
      }
    });
  });
}

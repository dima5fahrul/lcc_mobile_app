/// **The composition seam — B9-AC-10, and specs.md § 6.16's exit contract to
/// B10.**
///
/// § 6.4's ruling has a stated payoff: *"`AppShell` and `AppTopBar` stay
/// pumpable with no container and no BLoC."* This file is that claim, asserted.
///
/// Two halves, and the second is the one that is easy to lose:
///
/// 1. **The slots work.** A widget handed to `AppShell.topBarActions` lands in
///    the bar, after the language toggle; `floatingAction` lands in the
///    `Scaffold`.
/// 2. **The shell does not know what it is hosting.** No file under
///    `lib/presentation/shell/` imports anything under `features/`.
///
/// ## Why half (2) scans `shell/` and not `lib/presentation/**` — RULING 13
///
/// **This is a re-scoping, not a weakening, and the difference is worth being
/// exact about.** `ssd.md` § 4.4.1 (RULING 13) re-scoped `B9-AC-10` at v1.1;
/// read that section before changing anything here.
///
/// At v1.0 this scan walked all of `lib/presentation/`, which held only
/// `{shell, theme, icons, common}` when it was written. `ssd.md`:296-297
/// **permits** `presentation/** → features/*/domain/**`, so as `forms/`,
/// `payment/` and `boot/` landed, a global scan forbade an edge the SSD allows.
/// Two things followed. It collided head-on with `F0-AC-9`, whose *positive*
/// clause requires `lib/presentation/forms/` to import
/// `features/reference/domain/**` — no placement satisfied both. And before
/// that, silently, it cost B10 real fidelity:
/// `lib/presentation/boot/onboarding_categories.dart` wanted `Bilingual` and
/// the frozen `text(Bilingual?, Lang)` renderer, measured that the import
/// turned this test red, and shipped a hand-written ternary instead. A guard
/// that manufactures the duplication it exists to prevent is inverted.
///
/// Governing ground, per § 4.4.1(1): `ssd.md` § 0.4 item 5 lets a batch spec
/// narrow the SSD **for itself**. `B9-AC-10`'s "Applies to" reads `all`,
/// meaning all of *B9's* sub-batches — but a
/// `Directory('lib/presentation').listSync(recursive: true)` scan outlives B9
/// and binds F0, B10 and F1–F4. That is not a narrowing; it is an amendment to
/// the SSD made by a document that may not amend it.
///
/// **What still covers the surface given up.** Narrowing here surrenders
/// exactly one edge outside `shell/` — `presentation/** → features/*/domain/**`
/// — and that edge is permitted. The two genuinely forbidden edges stay
/// covered, repo-wide and independently, each with a negative control:
///
/// | Forbidden edge | Guard | Scope |
/// |---|---|---|
/// | `presentation/** → features/*/data/**` | **G-L1** | all `lib/presentation/**` |
/// | `presentation/** → features/*/presentation/**` | **G-L7** | all `lib/presentation/**` |
///
/// So nothing is left unguarded; a *duplicate and over-broad* check is deleted
/// and two *precise* ones remain. Do not read the narrowing as licence to relax
/// G-L1 or G-L7 — they are what makes it safe.
///
/// **Inside `shell/` the guard gets no weaker**, and is deliberately stricter
/// than `ssd.md`:296-297: the shell may import **nothing** from `features/`,
/// `domain/` included. That is not layering, it is the inversion-of-control
/// property the criterion was written for (*"the shell does not name what it
/// hosts"*) — the bell composes through `AppTopBar.trailingActions` from
/// `lib/utils/routes/app_routes.dart`, which is not under `lib/presentation/**`.
///
/// **Anti-evasion (§ 4.4.1).** A narrowed scan invites dodging it by putting a
/// shell-ish widget outside `shell/`. `F0-AC-8` and § 4.4's group table close
/// that: they fix the set of `lib/presentation/` subdirectories, so a new
/// `presentation/notifications/` trips the group-list assertion rather than
/// slipping past this scan. **The two assertions must be read as a pair and
/// neither may be narrowed without the other.**
library;

import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/presentation/shell/app_shell.dart';
import 'package:lcc_mobile_app/presentation/shell/app_top_bar.dart';
import 'package:lcc_mobile_app/presentation/shell/language_toggle.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

import '../../helpers/app_test_harness.dart';
import '../../helpers/core_test_helper.dart';

void main() {
  Future<void> pumpShell(
    WidgetTester tester, {
    List<Widget> topBarActions = const <Widget>[],
    Widget? floatingAction,
  }) async {
    await tester.pumpWidget(
      wrapWithLocalization(
        Builder(
          builder: (BuildContext context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: AppShell(
              location: AppNameRoutes.home,
              storage: inMemoryStorageService(<String, String>{}),
              topBarActions: topBarActions,
              floatingAction: floatingAction,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('the shell is pumpable with NOTHING supplied — § 6.16(1)', () {
    testWidgets('AppShell builds with both slots empty',
        (WidgetTester tester) async {
      await pumpShell(tester);

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(AppTopBar), findsOneWidget);
      expect(find.byType(LanguageToggle), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('AppTopBar builds on its own, with no shell around it',
        (WidgetTester tester) async {
      // The whole point of the parameter having a default. Every pre-B9 call
      // site and every existing widget test keeps compiling and passing
      // unchanged, and B10 inherits a bar it can pump.
      await tester.pumpWidget(
        wrapWithLocalization(
          Builder(
            builder: (BuildContext context) => MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: Scaffold(
                appBar: AppTopBar(
                  storage: inMemoryStorageService(<String, String>{}),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AppTopBar), findsOneWidget);
      expect(find.text('LAO CITIZEN CENTER'), findsOneWidget);
    });

    testWidgets('B9a leaves floatingAction NULL — its consumer is B9b',
        (WidgetTester tester) async {
      // The slot lands in B9a because B9a and B9b would otherwise both edit
      // `app_shell.dart`, which is the merge conflict § 2.3 splits the batch to
      // avoid. Nothing in B9a fills it.
      await pumpShell(tester);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).floatingActionButton,
        isNull,
      );
    });
  });

  group('the slots compose', () {
    testWidgets('a topBarAction lands in the bar, AFTER the language toggle',
        (WidgetTester tester) async {
      // `Layout.tsx:361-367` renders `<LanguageToggle />` then
      // `<NotificationMenu />`, in that order, in a `gap-2` row. Order is a
      // fidelity claim, not a preference.
      await pumpShell(
        tester,
        topBarActions: const <Widget>[Text('COMPOSED')],
      );

      expect(find.text('COMPOSED'), findsOneWidget);

      final Offset toggle = tester.getCenter(find.byType(LanguageToggle));
      final Offset composed = tester.getCenter(find.text('COMPOSED'));
      expect(
        composed.dx,
        greaterThan(toggle.dx),
        reason: 'the composed action sits to the RIGHT of the toggle, as the '
            'source orders them',
      );
    });

    testWidgets('several actions compose in order', (WidgetTester tester) async {
      // A `List<Widget>` rather than a single `Widget?` because B10 owns
      // `presentation/common/` and a second composed control there must not
      // need this signature changed again.
      await pumpShell(
        tester,
        topBarActions: const <Widget>[Text('ONE'), Text('TWO')],
      );

      expect(
        tester.getCenter(find.text('TWO')).dx,
        greaterThan(tester.getCenter(find.text('ONE')).dx),
      );
    });

    testWidgets('a floatingAction reaches the Scaffold',
        (WidgetTester tester) async {
      await pumpShell(
        tester,
        floatingAction: const FloatingActionButton(
          onPressed: null,
          child: Icon(Icons.chat_bubble_outline),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  group('B9-AC-10 — the shell does not name what it hosts', () {
    /// The scan's subject, per `ssd.md` § 4.4.1. **Not** `lib/presentation` —
    /// see the library doc for why, and for what covers the rest.
    const String kShell = 'lib/presentation/shell';

    final RegExp directive = RegExp('''^\\s*import\\s+r?['"]([^'"]+)['"]''');

    /// Every `import` directive under [kShell], as `path:line -> uri`.
    List<String> importsUnderShell({required bool onlyFeatures}) {
      final List<String> hits = <String>[];

      for (final FileSystemEntity entity
          in Directory(kShell).listSync(recursive: true)) {
        if (entity is! File) continue;
        final String path = entity.path.replaceAll(r'\', '/');
        if (!path.endsWith('.dart')) continue;

        final List<String> lines = entity.readAsStringSync().split('\n');
        for (int i = 0; i < lines.length; i++) {
          final RegExpMatch? m = directive.firstMatch(lines[i]);
          if (m == null) continue;
          if (onlyFeatures && !m.group(1)!.contains('features/')) continue;
          hits.add('$path:${i + 1} -> ${m.group(1)}');
        }
      }
      return hits;
    }

    List<String> featureImports() => importsUnderShell(onlyFeatures: true);

    test('zero import directives under lib/presentation/shell name a feature',
        () {
      expect(
        featureImports(),
        isEmpty,
        reason: 'B9-AC-10 as re-scoped by `ssd.md` § 4.4.1, and § 8.1(2)\'s '
            'exit gate: the seam is proven by a REAL CONSUMER, not by a '
            'signature. The bell is composed through '
            '`AppTopBar.trailingActions` by the `ShellRoute` builder in '
            '`lib/utils/routes/app_routes.dart` — which is not under '
            '`lib/presentation/shell/` and is already the sanctioned place to '
            'resolve from a container (CR-1). Inside the shell this is '
            'inversion of control, not layering, so `features/*/domain/**` is '
            'refused here too even though `ssd.md`:296-297 permits it '
            'elsewhere under `lib/presentation/**`.\nOffenders:\n  '
            '${featureImports().join('\n  ')}',
      );
    });

    test('the scan is not vacuous — it really reads lib/presentation/shell',
        () {
      // Without this, the assertion above would be green if the directory had
      // been renamed or the glob had stopped matching. `layering_test.dart`
      // makes the same complaint about its own scan for the same reason.
      //
      // The corpus is ~7 files rather than the ~40 the v1.0 global scan
      // walked, so the second half matters MORE after the narrowing, not
      // less: a file count alone still passes if the `import` regex breaks
      // and matches nothing. Both halves, therefore.
      final int dartFiles = Directory(kShell)
          .listSync(recursive: true)
          .whereType<File>()
          .where((File f) => f.path.endsWith('.dart'))
          .length;
      expect(dartFiles, greaterThan(5), reason: '$kShell went missing or empty');

      expect(
        importsUnderShell(onlyFeatures: false),
        isNotEmpty,
        reason: 'the directive regex matched NO import anywhere in $kShell. '
            'Every shell file imports Flutter at least — so this means the '
            'regex is broken and the assertion above is passing vacuously',
      );
    });

    test('COMMENT prose naming a feature is permitted, and there is some',
        () {
      // B9-AC-10 is worded against import DIRECTIVES specifically, and the
      // amended row says so in as many words. Both `app_top_bar.dart` and
      // `app_shell.dart` explain the seam by naming
      // `features/notifications/presentation/bloc/` in their docs — deleting
      // that to satisfy a substring grep would remove the explanation of the
      // rule from the files the rule governs, which is the same trap
      // `layering_rules.dart`'s comment-stripper exists to avoid for G-L5.
      final String topBar =
          File('$kShell/app_top_bar.dart').readAsStringSync();
      expect(topBar, contains('features/'));
      expect(featureImports(), isEmpty);
    });
  });
}

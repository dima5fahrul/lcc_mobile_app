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
///    `lib/presentation/**` imports anything under `features/`. That is
///    **G-L7**'s job at build time, and it is asserted here at the source level
///    too — because G-L7 reads `import` directives and B9-AC-10 is worded as a
///    grep over them, so the two are the same claim stated twice and both are
///    cheap.
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
    /// Every `import` directive under `lib/presentation/`, as `path:line -> uri`.
    List<String> featureImports() {
      final List<String> hits = <String>[];
      final RegExp directive = RegExp('''^\\s*import\\s+r?['"]([^'"]+)['"]''');

      for (final FileSystemEntity entity
          in Directory('lib/presentation').listSync(recursive: true)) {
        if (entity is! File) continue;
        final String path = entity.path.replaceAll(r'\', '/');
        if (!path.endsWith('.dart')) continue;

        final List<String> lines = entity.readAsStringSync().split('\n');
        for (int i = 0; i < lines.length; i++) {
          final RegExpMatch? m = directive.firstMatch(lines[i]);
          if (m == null) continue;
          if (m.group(1)!.contains('features/')) {
            hits.add('$path:${i + 1} -> ${m.group(1)}');
          }
        }
      }
      return hits;
    }

    test('zero import directives under lib/presentation name a feature', () {
      expect(
        featureImports(),
        isEmpty,
        reason: 'B9-AC-10, and § 8.1(2)\'s exit gate: the seam is proven by a '
            'REAL CONSUMER, not by a signature. The bell is composed through '
            '`AppTopBar.trailingActions` by the `ShellRoute` builder in '
            '`lib/utils/routes/app_routes.dart` — which is not under '
            '`lib/presentation/**` and is already the sanctioned place to '
            'resolve from a container (CR-1).\nOffenders:\n  '
            '${featureImports().join('\n  ')}',
      );
    });

    test('the scan is not vacuous — it really reads lib/presentation', () {
      // Without this, the assertion above would be green if the directory had
      // been renamed or the glob had stopped matching. `layering_test.dart`
      // makes the same complaint about its own scan for the same reason.
      final int dartFiles = Directory('lib/presentation')
          .listSync(recursive: true)
          .whereType<File>()
          .where((File f) => f.path.endsWith('.dart'))
          .length;
      expect(dartFiles, greaterThan(5));
    });

    test('COMMENT prose naming a feature is permitted, and there is some',
        () {
      // B9-AC-10 is worded against import DIRECTIVES specifically. Both
      // `app_top_bar.dart` and `app_shell.dart` now explain the seam by naming
      // `features/notifications/presentation/bloc/` in their docs — deleting
      // that to satisfy a substring grep would remove the explanation of the
      // rule from the files the rule governs, which is the same trap
      // `layering_rules.dart`'s comment-stripper exists to avoid for G-L5.
      final String topBar =
          File('lib/presentation/shell/app_top_bar.dart').readAsStringSync();
      expect(topBar, contains('features/'));
      expect(featureImports(), isEmpty);
    });
  });
}

/// `TutorialOverlay` — B10 § 6.10, `B10-AC-22` and `B10-AC-42`.
///
/// ## The skip link on step 6 is the assertion most likely to have been lost
///
/// `TutorialOverlay.tsx`:458 wraps the skip link in `{!isLast && …}`. It is one
/// token in the source, it changes nothing structural, and a port that dropped
/// it would look completely correct on steps 1-5 — which is every screenshot a
/// reviewer is likely to take. `B10-AC-22` names it for that reason, and the
/// test below walks all six steps rather than sampling.
library;

import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/home/presentation/widgets/tutorial_overlay.dart';
import 'package:lcc_mobile_app/features/home/presentation/widgets/tutorial_steps.dart';
import 'package:lcc_mobile_app/presentation/theme/app_spacing.dart';

import '../../../../helpers/app_test_harness.dart';

String _t(String locale, String key) =>
    ((jsonDecode(File('assets/i18n/$locale.json').readAsStringSync())
                as Map<String, dynamic>)['tutorial']
            as Map<String, dynamic>)[key] as String;

/// The bare key (`tutorial.step1Title` → `step1Title`).
String _leaf(String dotted) => dotted.split('.').last;

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onDone,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    wrapWithLocalization(
      startLocale: locale,
      Builder(
        builder: (BuildContext context) => MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: Scaffold(body: TutorialOverlay(onDone: onDone ?? () {})),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The step dots.
///
/// Found by their morph duration rather than by semantics, because the
/// tutorial's dots deliberately carry **no** `aria-label` — unlike the
/// splash's, which have `slideOf`. `tutorial_overlay.dart`:429-433 records that
/// the source's dots have none either, and that adding them would be an
/// accessibility improvement over the source, i.e. still a divergence. So the
/// finder has to key on something else, and the AC is about the COUNT.
Finder _dots() => find.byWidgetPredicate(
      (Widget w) => w is AnimatedContainer && w.duration == AppMotion.dotMorph,
    );

void main() {
  group('B10-AC-22 — Tier 1: six steps, each complete', () {
    testWidgets('exactly 6 steps, walked end to end',
        (WidgetTester tester) async {
      expect(
        kTutorialSteps.length,
        6,
        reason: '`TutorialOverlay.tsx`:30-324 builds six',
      );

      await _pump(tester);

      for (int i = 0; i < kTutorialSteps.length; i++) {
        final TutorialStepSpec step = kTutorialSteps[i];

        expect(
          find.text(_t('en', _leaf(step.titleKey))),
          findsOneWidget,
          reason: 'step ${i + 1}: title missing',
        );
        expect(
          find.text(_t('en', _leaf(step.descKey))),
          findsOneWidget,
          reason: 'step ${i + 1}: description missing',
        );
        expect(
          find.text(_t('en', _leaf(step.badgeKey))),
          findsOneWidget,
          reason: 'step ${i + 1}: badge missing',
        );

        // The badge glyph — lucide where bundled, a named Material stand-in
        // for the two that are not (`Sparkles`, `History`).
        if (step.iconMaterial != null) {
          expect(
            find.byIcon(step.iconMaterial!),
            findsWidgets,
            reason: 'step ${i + 1}: the Material stand-in glyph is missing',
          );
        }

        if (i < kTutorialSteps.length - 1) {
          await tester.tap(find.text(_t('en', 'next')));
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('the dots count 6', (WidgetTester tester) async {
      await _pump(tester);
      expect(_dots(), findsNWidgets(6));
    });

    testWidgets('the skip link is on steps 1-5 and ABSENT on step 6',
        (WidgetTester tester) async {
      await _pump(tester);
      final String skip = _t('en', 'skipTutorial');

      for (int i = 0; i < 5; i++) {
        expect(
          find.text(skip),
          findsOneWidget,
          reason: 'step ${i + 1} should offer skip',
        );
        await tester.tap(find.text(_t('en', 'next')));
        await tester.pumpAndSettle();
      }

      // Step 6.
      expect(
        find.text(_t('en', _leaf(kTutorialSteps.last.titleKey))),
        findsOneWidget,
        reason: 'the walk should have arrived at step 6',
      );
      expect(
        find.text(skip),
        findsNothing,
        reason: 'B10-AC-22: `{!isLast && …}` — `TutorialOverlay.tsx`:458. '
            'Dropping this token looks correct on every step a reviewer is '
            'likely to screenshot.',
      );
      expect(
        find.text(_t('en', 'getStarted')),
        findsOneWidget,
        reason: 'and the CTA changes word on the last step',
      );
    });

    testWidgets('Tier 1 holds in Lao', (WidgetTester tester) async {
      await _pump(tester, locale: const Locale('lo'));
      expect(
        find.text(_t('lo', _leaf(kTutorialSteps.first.titleKey))),
        findsOneWidget,
      );
      expect(
        find.text(_t('en', _leaf(kTutorialSteps.first.titleKey))),
        findsNothing,
      );
    });
  });

  group('B10-AC-42 — close and skip both dismiss, after the 300ms exit', () {
    testWidgets('the X dismisses, and `onDone` fires AFTER the exit runs',
        (WidgetTester tester) async {
      int done = 0;
      await _pump(tester, onDone: () => done++);

      // The close control is an `IconButton` wrapping `LucideIcon(name: 'X')`,
      // not a Material `Icons.close`.
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(
        done,
        0,
        reason: 'B10-AC-42: the 300ms exit runs BEFORE `onDone` '
            '(`TutorialOverlay.tsx`:342-345). Calling it immediately would '
            'unmount the overlay mid-fade and the animation would never be '
            'seen — which no screenshot test would catch.',
      );

      await tester.pump(AppMotion.tutorialExit);
      expect(done, 1);

      // Exactly once.
      await tester.pump(const Duration(seconds: 1));
      expect(done, 1);
    });

    testWidgets('skip dismisses the same way', (WidgetTester tester) async {
      int done = 0;
      await _pump(tester, onDone: () => done++);

      await tester.tap(find.text(_t('en', 'skipTutorial')));
      await tester.pump();
      expect(done, 0);

      await tester.pump(AppMotion.tutorialExit);
      expect(done, 1);
    });

    testWidgets('`getStarted` on the last step dismisses too',
        (WidgetTester tester) async {
      int done = 0;
      await _pump(tester, onDone: () => done++);

      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text(_t('en', 'next')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text(_t('en', 'getStarted')));
      await tester.pump();
      await tester.pump(AppMotion.tutorialExit);

      expect(done, 1);
    });

    test('the exit token is the source\'s 300ms', () {
      expect(AppMotion.tutorialExit, const Duration(milliseconds: 300));
    });
  });

  testWidgets('the scrim really blurs — § 6.10\'s BackdropFilter is not '
      'silently dropped', (WidgetTester tester) async {
    // § 8.4 FU-5: if `BackdropFilter` is ever dropped for performance it must
    // be recorded as a named divergence, never silently. This assertion is
    // what makes "silently" impossible.
    await _pump(tester);
    expect(
      find.byType(BackdropFilter),
      findsWidgets,
      reason: 'the scrim is `rgba(0,0,0,0.6)` + `backdrop-filter: blur(4px)`. '
          'A solid scrim is an acceptable fallback ONLY as a recorded '
          'divergence (§ 8.4 FU-5).',
    );
  });

  testWidgets('Back steps backwards, and is absent on step 1',
      (WidgetTester tester) async {
    await _pump(tester);
    final String back = _t('en', 'back');

    expect(find.text(back), findsNothing, reason: 'no Back on step 1');

    await tester.tap(find.text(_t('en', 'next')));
    await tester.pumpAndSettle();
    expect(find.text(back), findsOneWidget);

    await tester.tap(find.text(back));
    await tester.pumpAndSettle();
    expect(
      find.text(_t('en', _leaf(kTutorialSteps.first.titleKey))),
      findsOneWidget,
    );
  });
}

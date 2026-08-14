/// The boot phase — B10 § 6.8, § 6.10. `B10-AC-31`, `B10-AC-33`,
/// `B10-AC-35` (the mounted half) and `B10-AC-41`.
///
/// ## The phase REPLACES the app; it does not overlay it
///
/// `App.tsx`:195-222 assigns `screen` exclusively per phase, so during
/// `loading` neither `Layout` nor any page is mounted. § 6.8 rejected the
/// overlay shape for a reason no fidelity tier can see: painting the splash
/// above a live `Navigator` mounts `HomePage` behind it and fires
/// `/me/home-summary`, `/services` and `/news` during boot, which the web
/// defers. That is the R-25 class of divergence.
///
/// So the load-bearing assertion in this file is a **negative** one:
/// `find.byType(HomePage)` must find **nothing** while the splash is up. A test
/// that only checked "the splash is visible" would pass against the overlay
/// shape that was rejected.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/session/bloc/session_bloc.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/features/home/presentation/pages/home_page.dart';
import 'package:lcc_mobile_app/features/home/presentation/widgets/tutorial_overlay.dart';
import 'package:lcc_mobile_app/main.dart';
import 'package:lcc_mobile_app/presentation/boot/loading_screen.dart';
import 'package:lcc_mobile_app/presentation/boot/splash_screens.dart';
import 'package:lcc_mobile_app/presentation/theme/app_spacing.dart';

import '../helpers/app_test_harness.dart';

/// Pumps the real `App` **with the boot phase enabled**.
///
/// `pumpAssembledApp` deliberately leaves `bootStorage` null — that is the seam
/// `main.dart` documents, and it is why every pre-B10 flow test still lands
/// straight on Home. B10's own tests are the ones that must supply it.
Future<void> _mountWithBoot(
  WidgetTester tester,
  AppHarness harness, {
  Duration hold = AppMotion.bootHold,
}) async {
  await tester.pumpWidget(
    wrapWithLocalization(
      App(
        sessionBloc: harness.sessionBloc,
        bootStorage: harness.storage,
        bootDuration: hold,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  tearDown(resetHarness);

  testWidgets(
      'REGRESSION — the boot phases sit under a Material ancestor, so the '
      'splash controls do not throw', (WidgetTester tester) async {
    // Found by this test, red before the fix. `_bootApp` built
    // `MaterialApp(home: SplashScreens(...))` with **no `Scaffold`**, and
    // `MaterialApp` does not itself insert a `Material` — that is what
    // `Scaffold` is for. Every `TextButton` / `FilledButton` / `OutlinedButton`
    // / `IconButton` on the splash (Skip, Back, Next, the language toggle) is
    // an `InkResponse`, which asserts *"No Material widget found"* the moment
    // it builds.
    //
    // It survived to here because every widget test of the splash so far
    // supplied its own `Scaffold`, and the boot phase is off by default in the
    // shared harness (`bootStorage == null`). So the one configuration that
    // was never pumped is the one a citizen gets on a fresh install: the
    // onboarding splash rendering a red error screen.
    final AppHarness harness = await bootHarness(firstRun: true);
    await _mountWithBoot(tester, harness);
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreens), findsOneWidget);
    expect(
      tester.takeException(),
      isNull,
      reason: 'the splash must build cleanly in the REAL boot tree, not only '
          'under a test-supplied Scaffold',
    );
    expect(
      find.ancestor(
        of: find.byType(SplashScreens),
        matching: find.byType(Material),
      ),
      findsWidgets,
      reason: 'InkResponse-based controls require a Material ancestor',
    );
  });

  testWidgets(
      'B10-AC-31 — the splash holds until BOTH the hold has elapsed AND the '
      'session has left initial/loading', (WidgetTester tester) async {
    final AppHarness harness = await bootHarness(firstRun: true);
    await _mountWithBoot(tester, harness);

    // Frame 1: the boot screen, and — the part that matters — no app behind it.
    expect(find.byType(LoadingScreen), findsOneWidget);
    expect(
      find.byType(HomePage),
      findsNothing,
      reason: 'B10 § 6.8 rejected the OVERLAY shape precisely because it '
          'mounts HomePage behind the splash and fires three API calls the '
          'web defers. If HomePage is in the tree here, the boot phase is an '
          'overlay and the divergence is invisible to every fidelity tier.',
    );
    expect(find.byType(NavigationBar), findsNothing);

    // Halfway through the hold: still held.
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byType(LoadingScreen), findsOneWidget);
    expect(find.byType(SplashScreens), findsNothing);

    // Run the hold and the session out.
    await tester.pumpAndSettle();

    expect(
      harness.sessionBloc.state.status,
      isNot(SessionStatus.initial),
      reason: 'the session must actually have resolved, otherwise "the splash '
          'advanced" would be evidence that the gate was dropped',
    );
    expect(find.byType(LoadingScreen), findsNothing);
  });

  testWidgets('B10-AC-33 — with the flag set, boot goes STRAIGHT to app and '
      '`SplashScreens` never mounts', (WidgetTester tester) async {
    // `bootHarness()` seeds both flags by default — the returning citizen.
    final AppHarness harness = await bootHarness();
    await _mountWithBoot(tester, harness);

    await tester.pumpAndSettle();

    expect(
      find.byType(SplashScreens),
      findsNothing,
      reason: '`App.tsx`:203 — `setBootPhase(hasSeenOnboarding() ? "app" : '
          '"onboarding")`',
    );
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('B10-AC-34 — with the flag unset, `SplashScreens` mounts, and '
      'finishing it reaches the app', (WidgetTester tester) async {
    final AppHarness harness = await bootHarness(firstRun: true);
    await _mountWithBoot(tester, harness);
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreens), findsOneWidget);
    expect(
      find.byType(HomePage),
      findsNothing,
      reason: 'the onboarding phase replaces the app too, not just the '
          'loading phase',
    );

    // Skip out of it — the shortest path to `finish()`.
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreens), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
    expect(harness.store[StorageKeys.onboardingSeen], '1');
  });

  group('B10-AC-41 / B10-AC-35 — the tutorial gate is the SECOND, independent '
      'flag', () {
    testWidgets('a fresh install shows splash → Home → tutorial over Home',
        (WidgetTester tester) async {
      final AppHarness harness = await bootHarness(firstRun: true);
      await _mountWithBoot(tester, harness);
      await tester.pumpAndSettle();

      expect(find.byType(SplashScreens), findsOneWidget);
      expect(find.byType(TutorialOverlay), findsNothing);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // The splash's own flag is now set — and the tutorial's is NOT, which is
      // the behaviour `manifest.md`:190-191 got wrong and :262-264 corrected.
      expect(harness.store[StorageKeys.onboardingSeen], '1');
      expect(
        harness.store.containsKey(StorageKeys.tutorialSeen),
        isFalse,
        reason: 'B10-AC-35: dismissing the splash must not set the tutorial '
            'flag',
      );

      expect(find.byType(HomePage), findsOneWidget);
      expect(
        find.byType(TutorialOverlay),
        findsOneWidget,
        reason: 'B10-AC-41: the tutorial mounts over Home when '
            '`lcc.tutorial_seen` is unset',
      );
    });

    testWidgets('with `lcc.tutorial_seen` set, the overlay does NOT mount',
        (WidgetTester tester) async {
      final AppHarness harness = await bootHarness();
      await _mountWithBoot(tester, harness);
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(TutorialOverlay), findsNothing);
    });

    testWidgets('dismissing the tutorial sets its flag (`HomePage.tsx`:229)',
        (WidgetTester tester) async {
      final AppHarness harness = await bootHarness(
        firstRun: true,
        seed: <String, String>{StorageKeys.onboardingSeen: '1'},
      );
      await _mountWithBoot(tester, harness);
      await tester.pumpAndSettle();

      // B10-AC-35, the other direction: onboarding seen, tutorial not — the
      // splash is skipped and the tutorial still shows.
      expect(find.byType(SplashScreens), findsNothing);
      expect(find.byType(TutorialOverlay), findsOneWidget);

      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();

      expect(find.byType(TutorialOverlay), findsNothing);
      expect(harness.store[StorageKeys.tutorialSeen], '1');
    });
  });
}

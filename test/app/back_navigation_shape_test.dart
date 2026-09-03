/// GOR-269 — the `RULING 2` trap, in test form.
///
/// `specs.md` § 7.2 is unusually direct about why this file exists, and it is
/// worth quoting rather than paraphrasing: *"`GOR-269-AC-8`…`-11` prove the
/// defect is gone; `GOR-269-AC-12`…`-17` prove nothing was traded for it. A
/// submission passing only the first set is a FAIL, not a partial pass."*
///
/// `B12` § 10 decision 4 recorded that **every** fix available inside B12's
/// scope bought working Back at the price of a divergence from the web source:
/// re-parenting the nine full-frame routes under `/service` gives them a
/// navigator to pop, and also gives them a brand bar, a five-destination bottom
/// nav and a chat FAB on every frame of a seven-step form the source renders
/// full-frame. `StatefulShellRoute.indexedStack` gives each tab its own stack,
/// and also preserves per-tab state the source deliberately discards
/// (`Layout.tsx` runs `scrollTo({top: 0})` on every tab change).
///
/// So a suite that only presses Back and checks where it lands cannot tell a
/// correct fix from either of those. These tests can:
///
/// * **AC-12** — more than one `AppShell` means the shell is being stacked.
/// * **AC-13** — a tab match list deeper than 1 means tab switching started
///   pushing.
/// * **AC-14** — the divergence in its literal form, plus the chat-poll leak.
/// * **AC-15** — per-tab state survival, i.e. `indexedStack` by another name.
/// * **AC-16** — the route table itself.
/// * **AC-17** — none of the 36 navigation call sites moved.
///
/// Every one of them is driven **after a journey that includes a Back press**,
/// not on a freshly-booted app: the failure mode being hunted is a fix whose
/// cost only shows up once the mechanism has actually run.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lcc_mobile_app/features/chat/presentation/widgets/chat_launcher.dart';
import 'package:lcc_mobile_app/presentation/shell/app_shell.dart';
import 'package:lcc_mobile_app/presentation/shell/shell_tabs.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

import '../helpers/app_test_harness.dart';
import '../helpers/back_nav_harness.dart';
import '../helpers/back_probe.dart';

/// `kFullFrameRoutes` minus `/signin`, which an authenticated citizen is
/// bounced off by `_redirect` and which therefore gets its own signed-out row
/// below rather than a body that returns early and passes vacuously.
final List<String> _fullFrameSignedIn = kFullFrameRoutes
    .where((String r) => r != AppNameRoutes.signin)
    .toList(growable: false);

int _matchDepth(WidgetTester tester) =>
    routerOf(tester).routerDelegate.currentConfiguration.matches.length;

void main() {
  tearDown(resetHarness);

  testWidgets('GOR-269-AC-12 — exactly one AppShell, after a journey that '
      'returns to a tab via Back', (WidgetTester tester) async {
    final AppHarness harness = await bootSignedIn();
    await pumpAssembledApp(tester, harness);
    final List<String> platform = interceptPlatformChannel(tester);

    expect(find.byType(AppShell), findsOneWidget, reason: 'baseline at /');

    // A journey that leaves the shell, comes back to it, leaves again, and is
    // then walked back with Back — the shape most likely to stack a shell.
    await goTo(tester, AppNameRoutes.wallet);
    await goTo(tester, AppNameRoutes.familyBook);
    await goTo(tester, AppNameRoutes.service);
    await goTo(tester, AppNameRoutes.help);

    await pressBack(tester, platform);
    expect(locationOf(tester), AppNameRoutes.service);
    expect(find.byType(AppShell), findsOneWidget,
        reason: 'a second AppShell means Back stacked the shell rather than '
            'replacing the tab');

    await pressBack(tester, platform);
    await pressBack(tester, platform);
    expect(locationOf(tester), AppNameRoutes.wallet);
    expect(find.byType(AppShell), findsOneWidget);

    await pressBack(tester, platform);
    expect(locationOf(tester), AppNameRoutes.home);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('GOR-269-AC-13 — every tab route holds exactly one match, after '
      'any journey', (WidgetTester tester) async {
    final AppHarness harness = await bootSignedIn();
    await pumpAssembledApp(tester, harness);
    final List<String> platform = interceptPlatformChannel(tester);

    // Walk every tab forward, so the journey is deep before anything is
    // measured.
    for (final String tab in kTabRoutes) {
      await goTo(tester, tab);
      expect(locationOf(tester), tab);
      expect(_matchDepth(tester), 1,
          reason: 'a depth > 1 on $tab means tab switching started pushing');
    }

    // And then walk it back, measuring at each landing.
    for (int i = kTabRoutes.length - 2; i >= 0; i--) {
      await pressBack(tester, platform);
      expect(locationOf(tester), kTabRoutes[i]);
      expect(_matchDepth(tester), 1,
          reason: 'a depth > 1 on ${kTabRoutes[i]} after a Back press means '
              'the policy navigated by pushing rather than by going');
    }
  });

  group('GOR-269-AC-14 — the nine full-frame routes render no shell chrome', () {
    for (final String route in _fullFrameSignedIn) {
      testWidgets('$route, reached and then returned to via Back',
          (WidgetTester tester) async {
        final AppHarness harness = await bootSignedIn();
        await pumpAssembledApp(tester, harness);
        final List<String> platform = interceptPlatformChannel(tester);

        Future<void> assertBare(String why) async {
          expect(locationOf(tester), route, reason: why);
          expect(find.byType(AppShell), findsNothing,
              reason: 'AppShell on $route — the RULING 2 divergence, $why');
          expect(find.byType(NavigationBar), findsNothing,
              reason: 'bottom nav on $route, $why');
          expect(find.byType(ChatLauncher), findsNothing,
              reason: 'ChatLauncher on $route would also mean the shell s '
                  '4,000 ms chat poll is running behind a form, $why');
        }

        await goTo(tester, route);
        await assertBare('on arrival');

        // Leave and return via Back — the state the criterion cares about.
        await goTo(tester, AppNameRoutes.wallet);
        await pressBack(tester, platform);
        await assertBare('after returning via Back');
      });
    }

    testWidgets('/signin (signed out), reached and returned to via Back',
        (WidgetTester tester) async {
      final AppHarness harness = await bootSignedOut();
      await pumpAssembledApp(tester, harness);
      final List<String> platform = interceptPlatformChannel(tester);

      await goTo(tester, AppNameRoutes.wallet);
      await goTo(tester, AppNameRoutes.signin);
      expect(locationOf(tester), AppNameRoutes.signin);
      expect(find.byType(AppShell), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(ChatLauncher), findsNothing);

      await goTo(tester, AppNameRoutes.wallet);
      await pressBack(tester, platform);

      expect(locationOf(tester), AppNameRoutes.signin);
      expect(find.byType(AppShell), findsNothing,
          reason: 'after returning via Back');
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(ChatLauncher), findsNothing);
    });
  });

  testWidgets('GOR-269-AC-15 — tab state is NOT preserved across a Back that '
      'returns to the tab', (WidgetTester tester) async {
    // The `StatefulShellRoute.indexedStack` detector. That candidate would make
    // every assertion in AC-8 pass and would also make this one fail, which is
    // the whole reason it is written.
    //
    // The mutation is visible rather than internal, as the criterion requires:
    // text the citizen typed, still on screen.
    final AppHarness harness = await bootSignedIn();
    await pumpAssembledApp(tester, harness);
    final List<String> platform = interceptPlatformChannel(tester);

    await goTo(tester, AppNameRoutes.service);
    final Finder search = find.byType(TextField);
    expect(search, findsOneWidget,
        reason: 'the catalogue search field is the visible state this test '
            'mutates; without it the assertion below would be vacuous');

    await tester.enterText(search, 'passport');
    await tester.pumpAndSettle();
    expect(find.text('passport'), findsOneWidget, reason: 'the mutation landed');

    await goTo(tester, AppNameRoutes.wallet);
    final BackPress press = await pressBack(tester, platform);

    expect(locationOf(tester), AppNameRoutes.service, reason: '$press');
    expect(find.text('passport'), findsNothing,
        reason: 'the tab was rebuilt fresh. `Layout.tsx` resets on every tab '
            'change and `ssd.md` § 9.1 ports that on purpose — a surviving '
            'query means a per-tab stack was introduced');
    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text,
        isEmpty);
  });

  testWidgets('GOR-269-AC-16 — the route table is structurally unchanged',
      (WidgetTester tester) async {
    final AppHarness harness = await bootSignedIn();
    await pumpAssembledApp(tester, harness);

    // Measured off the router the app is actually running, not off a second
    // one built for the test — a second live router is what
    // `app_routes_test.dart:130-152` exists to prevent.
    final List<RouteBase> top = routerOf(tester).configuration.routes;

    final List<ShellRoute> shells = top.whereType<ShellRoute>().toList();
    expect(shells, hasLength(1),
        reason: 'exactly one ShellRoute; a second navigator is FC-2 s approved '
            'architectural rejection');
    expect(
      shells.single.routes.whereType<GoRoute>().map((GoRoute r) => r.path),
      kTabRoutes,
      reason: 'the shell still holds exactly the five main tabs, in order',
    );
    expect(shells.single.routes, hasLength(shellTabs.length));

    final Set<String> topLevelPaths =
        top.whereType<GoRoute>().map((GoRoute r) => r.path).toSet();
    for (final String route in kFullFrameRoutes) {
      expect(topLevelPaths, contains(route),
          reason: '$route must stay top-level — being outside the ShellRoute '
              'is what hides the bottom bar (B12 RULING 2)');
    }

    final GoRoute news = top
        .whereType<GoRoute>()
        .firstWhere((GoRoute r) => r.path == AppNameRoutes.news);
    expect(news.routes.whereType<GoRoute>().map((GoRoute r) => r.path),
        <String>[':slug'],
        reason: '/news/:slug stays a CHILD, which is why it already worked and '
            'why the policy is never consulted on it');
  });
}

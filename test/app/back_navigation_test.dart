/// GOR-269 — hardware Back, driven through the assembled app.
///
/// Groups B, C and D of `specs.md` § 7, on the instrument `qa-report.md` § 2.2
/// admitted and `test/helpers/back_probe.dart` documents. The trap tests that
/// prove nothing was *traded* for the fix live next door in
/// `back_navigation_shape_test.dart`; the authorization backstop lives in
/// `back_policy_authorization_test.dart`. Splitting them is not tidiness —
/// `specs.md` § 7.2 is explicit that *"a submission passing only the first set
/// is a FAIL, not a partial pass"*, and three files make it harder to run one
/// and believe the ticket is done.
///
/// **Every row asserts its location before pressing Back.** Eight of the
/// fifteen routes are in `AppRoutes._protectedPaths` and redirect to `/signin`
/// when unauthenticated; without that guard this file would measure `/signin`
/// twelve times and report it as twelve route names. Stage 2 recorded the
/// confound and it is reproduced here rather than re-learned.
///
/// **Both signals are asserted on every press.** See `back_probe.dart` for why
/// one is not enough.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/session/bloc/session_bloc.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/features/news/presentation/pages/news_detail_page.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

import '../helpers/app_test_harness.dart';
import '../helpers/back_nav_harness.dart';
import '../helpers/back_probe.dart';

/// The twelve routes of `qa-report.md` § 2.4's thirteen-strong defect set that
/// an authenticated citizen can reach. `/signin` is the thirteenth and needs a
/// signed-out harness — an authenticated citizen sent to `/signin` is bounced
/// home by `_redirect`, so measuring it here would measure `/`.
const List<String> _defectSetSignedIn = <String>[
  AppNameRoutes.service,
  AppNameRoutes.history,
  AppNameRoutes.wallet,
  AppNameRoutes.account,
  AppNameRoutes.help,
  AppNameRoutes.news,
  AppNameRoutes.residentCertificate,
  AppNameRoutes.birthDeclaration,
  AppNameRoutes.deathDeclaration,
  AppNameRoutes.marriageCertificate,
  AppNameRoutes.divorceCertificate,
  AppNameRoutes.familyBook,
];

void main() {
  tearDown(resetHarness);

  // ── Group B — the fix works ─────────────────────────────────────────────
  group('GOR-269-AC-8 — Back returns to the predecessor on the defect set', () {
    for (final String route in _defectSetSignedIn) {
      testWidgets(route, (WidgetTester tester) async {
        final AppHarness harness = await bootSignedIn();
        await pumpAssembledApp(tester, harness);
        final List<String> platform = interceptPlatformChannel(tester);

        // The predecessor. The app boots here, so `/` is already recorded.
        expect(locationOf(tester), AppNameRoutes.home);
        await goTo(tester, route);

        // The confound guard — eight of these redirect when signed out.
        expect(locationOf(tester), route,
            reason: 'the navigation never landed, so the press below would be '
                'measured against the wrong route');

        final BackPress press = await pressBack(tester, platform);

        expect(press.exited, isFalse,
            reason: 'SystemNavigator.pop was invoked on $route — $press');
        expect(press.popRouteReply, isTrue,
            reason: 'handlePopRoute must report that an observer handled it');
        expect(locationOf(tester), AppNameRoutes.home,
            reason: 'Back must land on the predecessor, not merely not exit');
      });
    }

    testWidgets('${AppNameRoutes.signin} (signed out — the thirteenth)',
        (WidgetTester tester) async {
      final AppHarness harness = await bootSignedOut();
      await pumpAssembledApp(tester, harness);
      final List<String> platform = interceptPlatformChannel(tester);

      expect(harness.sessionBloc.state.status, SessionStatus.unauthenticated);
      await goTo(tester, AppNameRoutes.signin);
      expect(locationOf(tester), AppNameRoutes.signin);

      final BackPress press = await pressBack(tester, platform);

      expect(press.exited, isFalse, reason: '$press');
      expect(press.popRouteReply, isTrue);
      expect(locationOf(tester), AppNameRoutes.home);
    });
  });

  group('GOR-269-AC-9 — the predictive-back channel behaves identically', () {
    // One tab route, one full-frame route and one form route, as specified.
    for (final String route in <String>[
      AppNameRoutes.wallet,
      AppNameRoutes.news,
      AppNameRoutes.familyBook,
    ]) {
      testWidgets(route, (WidgetTester tester) async {
        final AppHarness harness = await bootSignedIn();
        await pumpAssembledApp(tester, harness);
        final List<String> platform = interceptPlatformChannel(tester);

        await goTo(tester, route);
        expect(locationOf(tester), route);

        final BackPress press = await pressPredictiveBack(tester, platform);

        expect(press.exited, isFalse,
            reason: 'the gesture path reached SystemNavigator.pop — $press');
        expect(locationOf(tester), AppNameRoutes.home);
      });
    }
  });

  testWidgets('GOR-269-AC-10 — the multi-hop journey Stage 2 measured walks '
      'back one hop at a time', (WidgetTester tester) async {
    final AppHarness harness = await bootSignedIn();
    await pumpAssembledApp(tester, harness);
    final List<String> platform = interceptPlatformChannel(tester);

    // `qa-report.md` § 2.4.1: visited=[/, /service, /service/resident-certificate],
    // predecessors=2, and one press closed the app.
    await goTo(tester, AppNameRoutes.service);
    await goTo(tester, AppNameRoutes.residentCertificate);
    expect(locationOf(tester), AppNameRoutes.residentCertificate);

    final BackPress first = await pressBack(tester, platform);
    expect(first.exited, isFalse, reason: '$first');
    expect(locationOf(tester), AppNameRoutes.service);

    final BackPress second = await pressBack(tester, platform);
    expect(second.exited, isFalse, reason: '$second');
    expect(locationOf(tester), AppNameRoutes.home);

    // The instrument's own control: a third press has nowhere to go.
    final BackPress third = await pressBack(tester, platform);
    expect(third.exited, isTrue,
        reason: 'the journey is spent, so the app must become exitable again');
  });

  // ── Group C — the protected non-regressions ─────────────────────────────
  group('GOR-269-AC-18 / AC-30 — `/` with no predecessor still exits', () {
    testWidgets('a fresh session at `/` exits on the first press',
        (WidgetTester tester) async {
      final AppHarness harness = await bootSignedIn();
      await pumpAssembledApp(tester, harness);
      final List<String> platform = interceptPlatformChannel(tester);

      expect(locationOf(tester), AppNameRoutes.home);

      final BackPress press = await pressBack(tester, platform);

      expect(press.exited, isTrue,
          reason: 'an app that cannot be exited is worse than the defect — '
              '`fix-plan.md` § 13.4 trigger 1. $press');
      expect(press.popRouteReply, isFalse,
          reason: 'and both signals must agree, as they did on all 18 of '
              "Stage 2's rows");
    });

    testWidgets('the exit stays reachable after a full walk back',
        (WidgetTester tester) async {
      final AppHarness harness = await bootSignedIn();
      await pumpAssembledApp(tester, harness);
      final List<String> platform = interceptPlatformChannel(tester);

      await goTo(tester, AppNameRoutes.wallet);
      await goTo(tester, AppNameRoutes.help);
      await pressBack(tester, platform);
      await pressBack(tester, platform);
      expect(locationOf(tester), AppNameRoutes.home);

      final BackPress press = await pressBack(tester, platform);
      expect(press.exited, isTrue, reason: 'AC-30 / I-8. $press');
    });
  });

  group('GOR-269-AC-19 / AC-22 — `/news/:slug` is untouched', () {
    testWidgets('warm: the navigator pops it to /news and the policy is never '
        'consulted', (WidgetTester tester) async {
      final AppHarness harness = await bootSignedIn();
      await pumpAssembledApp(tester, harness);
      final List<String> platform = interceptPlatformChannel(tester);

      await goTo(tester, AppNameRoutes.news);
      await goTo(tester, kBackProbeArticle);
      expect(locationOf(tester), kBackProbeArticle);
      expect(find.byType(NewsDetailPage), findsOneWidget);
      expect(routerOf(tester).routerDelegate.currentConfiguration.matches.length,
          2,
          reason: 'the child route carries its parent — this is WHY the route '
              'already worked, and the fix must not change it');

      final BackPress press = await pressBack(tester, platform);

      expect(press.platformCalls, isNot(contains('SystemNavigator.pop')),
          reason: 'Stage 2 measured platform=[] on this row. $press');
      expect(press.popRouteReply, isTrue);
      expect(locationOf(tester), AppNameRoutes.news);
      expect(routerOf(tester).routerDelegate.currentConfiguration.matches.length,
          1,
          reason: 'matches went 2 -> 1, i.e. a real navigator pop');
    });

    testWidgets('cold deep link: same, opened straight at the article',
        (WidgetTester tester) async {
      // `AppRoutes.build` does not set `overridePlatformDefaultLocation`, so
      // go_router prefers the platform's `defaultRouteName`. This is a genuine
      // cold start *at* the article — the app boots there, it does not
      // navigate there.
      tester.binding.platformDispatcher.defaultRouteNameTestValue = kBackProbeArticle;
      addTearDown(
        tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
      );

      final AppHarness harness = await bootSignedIn();
      await pumpAssembledApp(tester, harness);
      final List<String> platform = interceptPlatformChannel(tester);

      expect(locationOf(tester), kBackProbeArticle);

      final BackPress press = await pressBack(tester, platform);

      expect(press.exited, isFalse,
          reason: 'the comment this ticket corrected claimed a cold deep link '
              'here has nothing to pop to. It has. $press');
      expect(press.popRouteReply, isTrue);
      expect(locationOf(tester), AppNameRoutes.news);
    });

    testWidgets('and a second press does not walk the citizen back INTO the '
        'article', (WidgetTester tester) async {
      // Not a specified criterion, and the most valuable test in this file.
      //
      // The navigator pop lands the citizen on `/news` without the policy ever
      // running. If the journey recorded that arrival as a *forward* visit, the
      // next press would `go()` straight back to the article and Back would
      // oscillate between two screens forever — a fix that passes AC-19 and is
      // still broken. `BackVisitStack.retreat` is what prevents it and this is
      // the only test that would notice if it stopped.
      final AppHarness harness = await bootSignedIn();
      await pumpAssembledApp(tester, harness);
      final List<String> platform = interceptPlatformChannel(tester);

      await goTo(tester, AppNameRoutes.news);
      await goTo(tester, kBackProbeArticle);

      await pressBack(tester, platform);
      expect(locationOf(tester), AppNameRoutes.news);

      final BackPress second = await pressBack(tester, platform);

      expect(locationOf(tester), isNot(kBackProbeArticle),
          reason: 'Back walked FORWARD into the article it had just left');
      expect(locationOf(tester), AppNameRoutes.home,
          reason: '/news s predecessor is `/`, which is where the citizen came '
              'from. $second');
    });
  });

  testWidgets('GOR-269-AC-21 — a cold deep link at a top-level route still '
      'exits', (WidgetTester tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        AppNameRoutes.wallet;
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );

    final AppHarness harness = await bootSignedIn();
    await pumpAssembledApp(tester, harness);
    final List<String> platform = interceptPlatformChannel(tester);

    expect(locationOf(tester), AppNameRoutes.wallet);

    final BackPress press = await pressBack(tester, platform);

    expect(press.exited, isTrue,
        reason: 'a cold deep link is the START of the task, so exiting is '
            'correct — and this row plus AC-18 are what prove the probe can '
            'still report an exit at all. $press');
    expect(press.popRouteReply, isFalse);
  });

  // ── Group D — the visit-stack invariants, through the assembled app ─────
  testWidgets('GOR-269-AC-23 (I-1) — a location the citizen never saw is never '
      'recorded', (WidgetTester tester) async {
    final AppHarness harness = await bootSignedOut();
    await pumpAssembledApp(tester, harness);
    final List<String> platform = interceptPlatformChannel(tester);

    expect(harness.sessionBloc.state.status, SessionStatus.unauthenticated);
    await goTo(tester, AppNameRoutes.wallet);
    // `/wallet` is NOT protected, so it lands. `/history` is.
    await goTo(tester, AppNameRoutes.history);
    expect(locationOf(tester), '/signin?from=%2Fhistory',
        reason: 'the auth gate redirected, which is the precondition for I-1');

    final BackPress press = await pressBack(tester, platform);

    expect(locationOf(tester), AppNameRoutes.wallet,
        reason: 'Back returns to the last screen the citizen actually saw. '
            '$press');
    expect(locationOf(tester), isNot(AppNameRoutes.history),
        reason: 'recording the REQUESTED location would put a screen they '
            'never reached into their journey');
  });

  testWidgets('GOR-269-AC-24 (I-2) — re-entering the current location does not '
      'deepen the journey', (WidgetTester tester) async {
    final AppHarness harness = await bootSignedIn();
    await pumpAssembledApp(tester, harness);
    final List<String> platform = interceptPlatformChannel(tester);

    await goTo(tester, AppNameRoutes.wallet);
    await goTo(tester, AppNameRoutes.wallet);
    expect(locationOf(tester), AppNameRoutes.wallet);

    final BackPress press = await pressBack(tester, platform);

    expect(locationOf(tester), AppNameRoutes.home,
        reason: "Back reaches /wallet's predecessor, not /wallet. $press");
  });

  testWidgets('GOR-269-AC-25 (I-3) — OQ-8 in test form: `/` stops being '
      'terminal once it has a predecessor', (WidgetTester tester) async {
    final AppHarness harness = await bootSignedIn();
    await pumpAssembledApp(tester, harness);
    final List<String> platform = interceptPlatformChannel(tester);

    await goTo(tester, AppNameRoutes.wallet);
    await goTo(tester, AppNameRoutes.home);
    expect(locationOf(tester), AppNameRoutes.home);

    final BackPress press = await pressBack(tester, platform);

    expect(press.exited, isFalse,
        reason: 'root-is-terminal would exit here, which is the same silent '
            'exit GOR-269 is about, relocated to one route. $press');
    expect(locationOf(tester), AppNameRoutes.wallet);
  });

  testWidgets('GOR-269-AC-27 (I-5) — consecutive presses walk the journey, '
      'they do not oscillate', (WidgetTester tester) async {
    final AppHarness harness = await bootSignedIn();
    await pumpAssembledApp(tester, harness);
    final List<String> platform = interceptPlatformChannel(tester);

    await goTo(tester, AppNameRoutes.service);
    await goTo(tester, AppNameRoutes.help);

    await pressBack(tester, platform);
    expect(locationOf(tester), AppNameRoutes.service);
    await pressBack(tester, platform);
    expect(locationOf(tester), AppNameRoutes.home,
        reason: 'the second press reaches the first location rather than '
            'bouncing back to /help');
  });

  testWidgets('GOR-269-AC-28 (I-6) — after sign-out, Back at /signin exits',
      (WidgetTester tester) async {
    final AppHarness harness = await bootSignedIn();
    await pumpAssembledApp(tester, harness);
    final List<String> platform = interceptPlatformChannel(tester);

    await goTo(tester, AppNameRoutes.wallet);
    await goTo(tester, AppNameRoutes.account);
    expect(locationOf(tester), AppNameRoutes.account);

    harness.sessionBloc.add(const SessionEvent.signOut());
    await tester.pumpAndSettle();
    expect(harness.sessionBloc.state.status, SessionStatus.unauthenticated);
    expect(locationOf(tester), startsWith(AppNameRoutes.signin),
        reason: '`refreshListenable` re-evaluates `_redirect` on the session '
            'edge, with no Back press required');

    final BackPress press = await pressBack(tester, platform);

    expect(press.exited, isTrue,
        reason: 'a retained journey would send Back at /signin to a stale '
            'protected predecessor, which `_redirect` would bounce straight '
            'back — Back would appear dead. $press');
    expect(locationOf(tester), startsWith(AppNameRoutes.signin),
        reason: 'and it certainly must not land on /account');
  });

  testWidgets('GOR-269-AC-29 (I-7 / FC-7) — the journey adds no storage key',
      (WidgetTester tester) async {
    final AppHarness harness = await bootSignedIn();
    await pumpAssembledApp(tester, harness);
    final List<String> platform = interceptPlatformChannel(tester);

    await goTo(tester, AppNameRoutes.service);
    await goTo(tester, AppNameRoutes.familyBook);
    await pressBack(tester, platform);
    await goTo(tester, AppNameRoutes.wallet);
    await pressBack(tester, platform);

    expect(
      harness.store.keys.toSet(),
      <String>{
        StorageKeys.onboardingSeen,
        StorageKeys.tutorialSeen,
        StorageKeys.accessToken,
      },
      reason: 'GOR-245 § 4.2 freezes the key set at three; the journey is '
          'in-memory and session-scoped by design',
    );
  });

  // ── Group E — the wiring ────────────────────────────────────────────────
  testWidgets('GOR-269-AC-31 (FC-5) — the four-field expansion boots without '
      'tripping WidgetsApp.router s assertion', (WidgetTester tester) async {
    final AppHarness harness = await bootSignedIn();
    await pumpAssembledApp(tester, harness);

    final MaterialApp app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.routerConfig, isNull,
        reason: '`routerConfig:` and `backButtonDispatcher:` are mutually '
            'exclusive on WidgetsApp.router; passing both asserts on the first '
            'frame');
    expect(app.routerDelegate, isNotNull);
    expect(app.routeInformationParser, isNotNull);
    expect(app.routeInformationProvider, isNotNull);
    expect(app.backButtonDispatcher, isNotNull,
        reason: 'the whole point of the expansion');
    expect(app.routerDelegate, same(routerOf(tester).routerDelegate),
        reason: 'and it is the SAME router `initState` built, not a second one');
  });
}

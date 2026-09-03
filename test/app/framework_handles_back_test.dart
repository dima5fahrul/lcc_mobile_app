/// GOR-269 `SRE-269-5` — the **platform gate**: what this app tells Android
/// about Back, rather than what it does once Android has already asked.
///
/// ## Why this file exists when eight GOR-269 suites already pass
///
/// Every other test in this repository enters the Back path **below** the gate
/// this file measures. `back_probe.dart`'s [pressBack] injects `popRoute` on
/// `flutter/navigation` and [pressPredictiveBack] drives `flutter/backgesture`;
/// both converge on `WidgetsBinding.handlePopRoute()`, which is the only route
/// to [AppBackButtonDispatcher.didPopRoute]. That is the right instrument for
/// the question *"once the framework is asked, does the policy answer
/// correctly?"* — and it is structurally incapable of answering the question
/// underneath it: **is the framework asked at all?**
///
/// On Android 13+ it is not asked unless the app says so. Three links, each
/// read from the pinned framework source (Flutter 3.44.9,
/// `/opt/homebrew/share/flutter`):
///
/// 1. `NavigatorState._handleHistoryChanged` dispatches
///    `NavigationNotification(canHandlePop: navigatorCanPop || routeBlocksPop)`
///    — `widgets/navigator.dart:3753`.
/// 2. `WidgetsApp._defaultOnNavigationNotification` — the default this app
///    used to leave in place — calls
///    `SystemNavigator.setFrameworkHandlesBack(notification.canHandlePop)`
///    — `widgets/app.dart:1452`.
/// 3. `SystemNavigator.setFrameworkHandlesBack`'s own dartdoc: *"this is used
///    only on Android to inform its use of the predictive back gesture when
///    exiting the app"* — `services/system_navigator.dart:14-19`. And
///    `WidgetsBinding.handlePopRoute`'s: *"back gestures that trigger
///    predictive back are handled entirely by the system and do not trigger
///    this method here in the framework"* — `widgets/binding.dart:1095-1110`.
///
/// Every navigation in this app is `context.go()`, which replaces the stack, so
/// each full-frame route's `Navigator` holds **one page** and `canPop()` is
/// false. The defect's own root cause therefore fed the platform gate: on
/// `4a854da` this app told Android *"I do not handle Back"* on all four routes
/// below, and Android obliged by never delivering the press.
///
/// ## The measurement, and its two controls
///
/// [interceptPlatformChannel]'s `frameworkHandlesBack` out-parameter records
/// the argument of every `setFrameworkHandlesBack` call the real assembled
/// `App` from `lib/main.dart` makes — `pumpAssembledApp`, not
/// `pumpMainComposition`, deliberately: a copy of the composition cannot prove
/// what the shipped composition sends.
///
/// A suite in which every row reported `true` would be indistinguishable from
/// an app that had simply hard-wired `true`, and that app would be **unable to
/// exit** — `fix-plan.md` § 13.4 trigger 1, the one failure the plan calls
/// worse than the defect. So two rows must report `false`:
///
/// * `GOR-269-AC-38` — Back returns to `/` with a one-entry journey, the flag
///   goes back **down**, and the next press really does exit. `AC-18`'s
///   platform-level twin.
/// * `GOR-269-AC-39` — `/news/:slug`, the one route this ticket deliberately
///   does *not* cover, reported `true` on `4a854da` already, through
///   `navigatorCanPop`. It must keep doing so, and for the same reason. This is
///   the row that proves the probe reads the framework's half and not only the
///   policy's.
///
/// ## [resumeApp] is load-bearing, not ceremony
///
/// `_defaultOnNavigationNotification` returns early when the lifecycle is
/// `null` (`widgets/app.dart:1443-1447`), and a widget test leaves it `null`.
/// Without the resume every row here measures an empty list and passes
/// vacuously — which is precisely how 3599 green tests coexisted with a fix
/// that never reached the device.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/features/history/presentation/pages/history_detail_page.dart';
import 'package:lcc_mobile_app/features/history/presentation/widgets/history_row_card.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

import '../helpers/app_test_harness.dart';
import '../helpers/back_nav_harness.dart';
import '../helpers/back_probe.dart';

/// The four routes `SRE-269-5` measured reporting `false` on `4a854da` — one
/// tab, one full-frame service route, and two of the routes the ticket's own
/// § 2.4 reproduction walked.
const List<String> _kCoveredRoutes = <String>[
  AppNameRoutes.wallet,
  AppNameRoutes.account,
  AppNameRoutes.familyBook,
  AppNameRoutes.news,
];

/// The one application the `GOR-269-AC-40` row's list renders.
const String _kRowId = 'app-001';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/fidelity/fixtures/api/$name.json').readAsStringSync())
        as Map<String, dynamic>;

/// Replaces `bootSignedIn`'s deliberately empty `/applications` stub with a
/// one-row page plus the detail's own two reads.
///
/// Lifted from `history_detail_back_test.dart`, which established it, for the
/// same reason it exists there: without a row there is no detail, and without a
/// detail `history_page.dart:143`'s `PopScope` never sets `canPop: false`, so
/// the `routeBlocksPop` branch this row exists to measure is never taken.
void _stubOneApplication(AppHarness harness) {
  final Map<String, dynamic> page = _fixture('applications-page');
  final List<dynamic> rows = page['data'] as List<dynamic>;
  final Map<String, dynamic> row = rows.first as Map<String, dynamic>;

  harness.adapter.onGet(
    ApiEndpoint.applications,
    (dynamic server) => server.reply(200, <String, dynamic>{
      'success': true,
      'message': 'ok',
      'data': <dynamic>[row],
      'meta': const <String, dynamic>{
        'page': 1,
        'per_page': 20,
        'total': 1,
        'total_pages': 1,
        'has_next': false,
        'has_prev': false,
      },
    }),
  );
  harness.adapter.onGet(
    ApiEndpoint.application(_kRowId),
    (dynamic server) => server.reply(
        200, _fixture('application-detail')['issued'] as Map<String, dynamic>),
  );
  harness.adapter.onGet(
    ApiEndpoint.applicationTimeline(_kRowId),
    (dynamic server) => server.reply(200,
        _fixture('application-timeline')['emptyTrail'] as Map<String, dynamic>),
  );
}

void main() {
  tearDown(resetHarness);

  testWidgets(
      'GOR-269-AC-37 — on every route the policy covers, the app tells Android '
      'it handles Back', (WidgetTester tester) async {
    final AppHarness harness = await bootSignedIn();
    final List<bool> gate = <bool>[];
    await pumpAssembledApp(tester, harness);
    interceptPlatformChannel(tester, frameworkHandlesBack: gate);
    await resumeApp(tester);

    for (final String route in _kCoveredRoutes) {
      await goTo(tester, route);

      // The confound guard every GOR-269 row carries: a session that failed to
      // authenticate would sit on `/signin`, where a one-entry journey makes
      // `false` the *correct* answer and this row would pass for the wrong
      // reason.
      expect(locationOf(tester), route,
          reason: 'the citizen must actually be on $route');

      expect(gate, isNotEmpty,
          reason: 'nothing was sent to the platform at all on $route. Either '
              'the app never participates in the gate (SRE-269-5 as measured '
              'on 4a854da), or the lifecycle resume did not take');
      expect(gate.last, isTrue,
          reason: 'on $route the citizen has a predecessor, so Android must '
              'deliver Back into Flutter. Sending false here is the app asking '
              'Android to handle the press itself — which, on API 33+, means '
              'exiting without ever consulting AppBackPolicy. Recorded: $gate');
    }
  });

  testWidgets(
      'GOR-269-AC-38 (AC-18 at the platform gate) — Back to a one-entry '
      'journey lowers the flag again, and the next press exits',
      (WidgetTester tester) async {
    final AppHarness harness = await bootSignedIn();
    final List<bool> gate = <bool>[];
    await pumpAssembledApp(tester, harness);
    final List<String> platform =
        interceptPlatformChannel(tester, frameworkHandlesBack: gate);
    await resumeApp(tester);

    await goTo(tester, AppNameRoutes.wallet);
    expect(gate.last, isTrue, reason: 'the precondition. Recorded: $gate');

    // Back — handled by the policy, which walks the citizen to `/` and leaves
    // the journey at one entry.
    final BackPress first = await pressBack(tester, platform);
    expect(first.exited, isFalse, reason: 'AC-1 still holds. $first');
    expect(locationOf(tester), AppNameRoutes.home);

    expect(gate.last, isFalse,
        reason: 'the journey is back to one entry, so Back must exit from here '
            '— and the app must say so, or Android keeps delivering presses '
            'into a framework that will only ever decline them. A fix that '
            'raised this flag and never lowered it would make the app '
            'inescapable through the predictive-back path. Recorded: $gate');

    // And the flag is not merely cosmetic: the press it describes really does
    // reach `SystemNavigator.pop`.
    final BackPress second = await pressBack(tester, platform);
    expect(second.exited, isTrue,
        reason: 'AC-18 — `/` with a fresh journey still exits. $second');
  });

  testWidgets(
      'GOR-269-AC-39 (AC-19 / AC-22 at the platform gate) — /news/:slug still '
      'reports true, through the navigator and not through the policy',
      (WidgetTester tester) async {
    final AppHarness harness = await bootSignedIn();
    final List<bool> gate = <bool>[];
    await pumpAssembledApp(tester, harness);
    final List<String> platform =
        interceptPlatformChannel(tester, frameworkHandlesBack: gate);
    await resumeApp(tester);

    await goTo(tester, kBackProbeArticle);
    expect(locationOf(tester), kBackProbeArticle);

    expect(gate.last, isTrue,
        reason: 'this route\'s navigator holds two pages, so `navigatorCanPop` '
            'is true and `4a854da` already reported true here. It is the '
            'control: a probe that could only see the policy would not '
            'distinguish this row from AC-37\'s. Recorded: $gate');

    // The behaviour the flag is protecting, unchanged: `maybePop` pops the
    // article and the policy never runs.
    final BackPress press = await pressBack(tester, platform);
    expect(press.exited, isFalse, reason: '$press');
    expect(locationOf(tester), AppNameRoutes.news,
        reason: 'AC-19 / AC-22 — the navigator popped, the policy stayed out');
  });

  testWidgets(
      'GOR-269-AC-40 (B7-AC-75 at the platform gate) — a route that blocks pop '
      'through PopScope keeps reporting true', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 4000);
    addTearDown(tester.view.reset);

    final AppHarness harness = await bootSignedIn();
    _stubOneApplication(harness);
    final List<bool> gate = <bool>[];
    await pumpAssembledApp(tester, harness);
    final List<String> platform =
        interceptPlatformChannel(tester, frameworkHandlesBack: gate);
    await resumeApp(tester);

    await goTo(tester, AppNameRoutes.history);
    expect(locationOf(tester), AppNameRoutes.history);
    expect(find.byType(HistoryRowCard), findsOneWidget,
        reason: 'without the row there is no detail to open and every '
            'assertion below would pass vacuously');

    await tester.tap(find.byType(HistoryRowCard));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryDetailPage), findsOneWidget,
        reason: 'this is the state B7-AC-75 measured as `canPop == false`');

    // With the detail open, `history_page.dart:143` sets `canPop: false`. That
    // makes `routeBlocksPop` true at `navigator.dart:3748` — the framework's
    // *other* route to `canHandlePop`, independent of both `navigatorCanPop`
    // and of `AppBackPolicy`. A fix that replaced the framework's answer
    // instead of widening it would report false here and hand this press to
    // Android, which would close the app on a citizen who meant to close a
    // detail.
    expect(gate.last, isTrue, reason: 'Recorded: $gate');

    final BackPress press = await pressBack(tester, platform);
    expect(press.exited, isFalse, reason: 'B7-AC-75 survives. $press');
    expect(find.byType(HistoryDetailPage), findsNothing,
        reason: 'Back closed the detail, as it did before this change');
    expect(locationOf(tester), AppNameRoutes.history,
        reason: 'and the policy never ran');
  });

  testWidgets(
      'GOR-269-AC-41 — the shipped composition installs the gate handler, not '
      'just the dispatcher', (WidgetTester tester) async {
    final AppHarness harness = await bootSignedIn();
    await pumpAssembledApp(tester, harness);

    final MaterialApp app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    // `GOR-269-AC-31` pins the four-field expansion. This pins the fifth field,
    // and it is a separate row because the two fail for different reasons:
    // dropping the dispatcher breaks every behavioural test in the ticket
    // loudly, while dropping this one breaks nothing any of them can see and
    // silently returns the app to `4a854da`'s device behaviour.
    expect(app.onNavigationNotification, isNotNull,
        reason: 'without it `WidgetsApp` falls back to '
            '`_defaultOnNavigationNotification`, which answers Android with '
            '`Navigator.canPop()` alone — false on every route this app '
            'reaches by `context.go()`');
    expect(app.backButtonDispatcher, isNotNull,
        reason: 'and the two are only useful together: this one is what runs '
            'after Android has agreed to deliver the press');
  });
}

/// GOR-269 `GOR-269-AC-20` — `/history`'s detail keeps intercepting Back, and
/// the app-level policy stays out of its way.
///
/// ## Why this file exists when `history_detail_navigation_test.dart` already
/// covers the same behaviour
///
/// It does not cover the same behaviour, and the difference is the whole point
/// of this ticket's mechanism.
///
/// `history_detail_navigation_test.dart` is the ticket's **positive control**
/// (`qa-report.md` § 2.6) and must pass **unmodified, 7/7** (`GOR-269-AC-3`).
/// But it builds its own one-route `GoRouter` and hands it to a local
/// `MaterialApp.router` as `routerConfig:` — so it runs with the framework's
/// stock `RootBackButtonDispatcher` and has never seen
/// [AppBackButtonDispatcher] at all. It proves B7's guard works; it cannot
/// prove the guard **still** works once GOR-269 installs an app-level policy
/// above it.
///
/// That proof is exactly what `fix-plan.md` § 8.2 claims as the load-bearing
/// property of the selected mechanism:
///
/// > `/history`'s detail `PopScope` intercepts through `maybePop()` — the
/// > policy never runs, and `HistoryReturnedFromDetail` still dispatches.
///
/// A claim of the form *"preserved by construction"* is the kind that is
/// cheapest to believe and most expensive to be wrong about, because the
/// construction it rests on is an ordering — `super.didPopRoute()` before the
/// policy — that a later edit could invert without any other test in this
/// ticket noticing. `specs.md` § 7.7 routes Group C through the assembled-app
/// probe for that reason, and `GOR-269-AC-20` is the Group C row that had no
/// assembled-app test.
///
/// ## The failure this would catch
///
/// Invert the two statements in [AppBackButtonDispatcher.didPopRoute] — consult
/// the policy first, delegate second — and every other GOR-269 test still
/// passes. This one goes red three ways at once: the detail stays open, the
/// location moves off `/history`, and `HistoryReturnedFromDetail` is never
/// dispatched so the list never refetches.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/features/history/presentation/pages/history_detail_page.dart';
import 'package:lcc_mobile_app/features/history/presentation/widgets/history_row_card.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

import '../helpers/app_test_harness.dart';
import '../helpers/back_nav_harness.dart';
import '../helpers/back_probe.dart';

/// The one application the list renders.
///
/// `applications-page.json` ships nine rows; this test slices it to one so the
/// row the citizen taps is unambiguous and its detail can be stubbed by id. The
/// fixture is **read, never written** — `specs.md` § 4.1 puts
/// `test/fidelity/**` out of scope, and reading a recorded payload is how
/// `application_datasource_transport_test.dart` already uses it.
const String _kRowId = 'app-001';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/fidelity/fixtures/api/$name.json').readAsStringSync())
        as Map<String, dynamic>;

/// Replaces the harness's deliberately-empty `/history` stub with a one-row
/// page, plus the two reads the detail fires (`GetApplication`,
/// `GetApplicationTimeline`).
///
/// Registered **after** [bootSignedIn] so it wins: `http_mock_adapter` resolves
/// last-registered-first, which is the ordering
/// `back_nav_harness.dart`'s own `bootSignedIn` doc comment relies on.
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

  // The detail's own two reads. Their payloads do not matter to this test —
  // what matters is that the detail *opens*, so that the pop guard has
  // something to guard — but they are stubbed rather than left to 404 so the
  // detail renders a page instead of an error card.
  final Map<String, dynamic> detail =
      _fixture('application-detail')['issued'] as Map<String, dynamic>;
  harness.adapter.onGet(
    ApiEndpoint.application(_kRowId),
    (dynamic server) => server.reply(200, detail),
  );

  final Map<String, dynamic> timeline =
      _fixture('application-timeline')['emptyTrail'] as Map<String, dynamic>;
  harness.adapter.onGet(
    ApiEndpoint.applicationTimeline(_kRowId),
    (dynamic server) => server.reply(200, timeline),
  );
}

/// Counts reads of `/applications`, which is how `HistoryReturnedFromDetail`
/// becomes observable from outside the BLoC.
///
/// `_closeDetail()` dispatches the event and `HistoryBloc` answers it by
/// re-issuing both the list and the counts (`B7-AC-76`). In the assembled app
/// those are real requests over the stubbed transport, so a rise in this
/// counter across the Back press is the event having been handled — the same
/// measure-the-delta technique `history_detail_navigation_test.dart` uses
/// against its fake repository, applied one layer out.
List<String> _countApplicationReads(AppHarness harness) {
  final List<String> reads = <String>[];
  harness.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        if (options.path.contains(ApiEndpoint.applications)) {
          reads.add(options.uri.toString());
        }
        handler.next(options);
      },
    ),
  );
  return reads;
}

void main() {
  tearDown(resetHarness);

  testWidgets(
      'GOR-269-AC-20 — with a detail open, Back closes the detail, the app '
      'survives, the citizen stays at /history, and the list refetches',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 4000);
    addTearDown(tester.view.reset);

    final AppHarness harness = await bootSignedIn();
    _stubOneApplication(harness);
    await pumpAssembledApp(tester, harness);
    final List<String> platform = interceptPlatformChannel(tester);
    final List<String> reads = _countApplicationReads(harness);

    // The confound guard every Stage 2 row carries: assert where the citizen is
    // *before* pressing Back. `/history` is one of the eight protected paths,
    // so a session that failed to authenticate would sit on `/signin` and this
    // test would measure the wrong route's behaviour entirely.
    await goTo(tester, AppNameRoutes.history);
    expect(locationOf(tester), AppNameRoutes.history);
    expect(find.byType(HistoryRowCard), findsOneWidget,
        reason: 'the one stubbed row must render, or there is no detail to '
            'open and the assertions below would pass vacuously');

    await tester.tap(find.byType(HistoryRowCard));
    await tester.pumpAndSettle();

    expect(find.byType(HistoryDetailPage), findsOneWidget,
        reason: 'the detail is open — this is the state B7-AC-75 measured as '
            '`canPop == false`');
    expect(locationOf(tester), AppNameRoutes.history,
        reason: 'B7-AC-74 — the detail is in-page state, not a route');

    final int readsBeforeBack = reads.length;

    final BackPress press = await pressBack(tester, platform);

    // 1. The app survived. Both signals, per the probe's own contract.
    expect(press.exited, isFalse,
        reason: 'SystemNavigator.pop would have finished the Activity with a '
            'detail merely open. $press');
    expect(press.popRouteReply, isTrue,
        reason: 'the press was claimed by an observer — B7 s pop guard, '
            'reached through super.didPopRoute(). $press');

    // 2. The detail closed and the list came back.
    expect(find.byType(HistoryDetailPage), findsNothing,
        reason: 'Back closed the detail');
    expect(find.byType(HistoryRowCard), findsOneWidget,
        reason: 'and returned the citizen to the list');

    // 3. The citizen is still on /history — the policy did NOT navigate.
    expect(locationOf(tester), AppNameRoutes.history,
        reason: 'the policy must never have run. If the ordering in '
            'AppBackButtonDispatcher.didPopRoute were inverted, the policy '
            'would have consumed this press and walked the citizen back to '
            '/ instead, closing nothing');

    // 4. `HistoryReturnedFromDetail` was dispatched (`B7-AC-76`).
    expect(reads.length, greaterThan(readsBeforeBack),
        reason: 'closing the detail re-issues the list and the counts. No new '
            'read means the event never reached the still-mounted list BLoC, '
            'which is the half of B7-AC-76 that a location assertion alone '
            'cannot see');
  });

  testWidgets(
      'GOR-269-AC-20 — the guarded press did not consume a journey entry: the '
      'next Back still returns to the predecessor',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 4000);
    addTearDown(tester.view.reset);

    final AppHarness harness = await bootSignedIn();
    _stubOneApplication(harness);
    await pumpAssembledApp(tester, harness);
    final List<String> platform = interceptPlatformChannel(tester);

    // `/` → `/history`, so the journey has a predecessor to return to.
    expect(locationOf(tester), AppNameRoutes.home);
    await goTo(tester, AppNameRoutes.history);
    await tester.tap(find.byType(HistoryRowCard));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryDetailPage), findsOneWidget);

    // Press one: absorbed by the pop guard, changes no route.
    await pressBack(tester, platform);
    expect(find.byType(HistoryDetailPage), findsNothing);
    expect(locationOf(tester), AppNameRoutes.history);

    // Press two: now the navigators decline, so the policy runs — and it must
    // still hold `/` beneath `/history`. This is the assertion that catches an
    // arm left set: `AppBackPolicy` opens its retreat window before delegating,
    // and if `_endBack()` did not close it, the guarded press above would have
    // been read as a backward step and quietly rewritten the journey's head.
    final BackPress second = await pressBack(tester, platform);
    expect(second.exited, isFalse, reason: '$second');
    expect(locationOf(tester), AppNameRoutes.home,
        reason: 'the journey still knew /history s predecessor. A guarded '
            'press must leave the journey exactly as it found it');
  });
}

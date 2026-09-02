/// GOR-269 Stage 11 regression — a modal route open over a tab still absorbs
/// Back, and the app-level policy stays out of its way.
///
/// ## Why this file exists
///
/// Stage 11 asks a different question from Stage 9: not *is the fix correct*
/// but *what else did the composition it replaced serve*. `MaterialApp.router`
/// went from one field to four and gained an [AppBackButtonDispatcher], so
/// every pre-existing consumer of Back had to be re-checked. Two classes of
/// consumer absorb a press **without changing the router's location**:
///
/// 1. A widget-level pop guard — `/history`'s detail `PopScope`. Covered by
///    `history_detail_back_test.dart` (`GOR-269-AC-20`).
/// 2. **A real modal route on the root navigator** — `showModalBottomSheet`
///    and `showDialog`. Covered by nothing, before this file.
///
/// They are not the same mechanism and they do not fail the same way.
/// `PopScope` reaches `NavigatorState.maybePop` through
/// `Route.popDisposition == doNotPop`, which fires `onPopInvokedWithResult`
/// and returns true **without touching the history**. A modal route reaches it
/// through `popDisposition == pop`, which calls `pop()` and *does* mutate the
/// navigator's history (`widgets/navigator.dart:5569-5578`). A guard written
/// only against the first proves nothing about the second.
///
/// This app has five such call sites and one of them is in the flow the bugfix
/// workflow names as its first priority area: `showWalletTopUpSheet`
/// (`wallet_top_up_sheet.dart:84`), which is how a citizen tops up the balance
/// `PayApplication` later spends. The other four are `showDialog` in
/// `action_banner.dart` and `lao_id_card.dart`, and `showModalBottomSheet` in
/// `service_detail_sheet.dart` and `wallet_bills_due_section.dart`.
///
/// ## The failure this would catch
///
/// Invert the two statements in [AppBackButtonDispatcher.didPopRoute] —
/// consult the policy before delegating — and Back with the top-up sheet open
/// would navigate the citizen off `/wallet` entirely while leaving the sheet
/// mounted over the new route. `history_detail_back_test.dart` catches the same
/// inversion, but only through the `doNotPop` path; this file is the `pop`
/// path, and it also covers what that one cannot: that a press which really
/// did mutate the navigator's history still leaves the **journey** untouched,
/// because `AppBackPolicy._backDepth`'s window opened and closed around a pop
/// that produced no router notification at all.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/wallet/presentation/widgets/wallet_quick_actions.dart';
import 'package:lcc_mobile_app/features/wallet/presentation/widgets/wallet_top_up_sheet.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

import '../helpers/app_test_harness.dart';
import '../helpers/back_nav_harness.dart';
import '../helpers/back_probe.dart';

/// Taps the `topup` tile, which is `kWalletQuickActions`' first entry
/// (`wallet_quick_actions.dart:96-102`) and the only one of the eight that
/// does anything while signed in (`wallet_page.dart:137`).
Future<void> _openTopUpSheet(WidgetTester tester) async {
  final Finder tile = find
      .descendant(
        of: find.byType(WalletQuickActions),
        matching: find.byType(InkWell),
      )
      .first;

  expect(tile, findsOneWidget,
      reason: 'no quick-action tile rendered, so the tap below would open '
          'nothing and every assertion after it would pass vacuously');

  await tester.tap(tile);
  await tester.pumpAndSettle();
}

void main() {
  tearDown(resetHarness);

  testWidgets(
      'GOR-269 Stage 11 — with a modal sheet open, Back dismisses the sheet, '
      'the app survives, and the citizen stays on /wallet',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 4000);
    addTearDown(tester.view.reset);

    final AppHarness harness = await bootSignedIn();
    await pumpAssembledApp(tester, harness);
    final List<String> platform = interceptPlatformChannel(tester);

    // The confound guard: assert where the citizen is before pressing Back.
    // `/wallet` is protected, so a session that failed to authenticate would
    // sit on `/signin` and this would measure the wrong route entirely.
    await goTo(tester, AppNameRoutes.wallet);
    expect(locationOf(tester), AppNameRoutes.wallet);

    await _openTopUpSheet(tester);

    expect(find.byType(WalletTopUpSheet), findsOneWidget,
        reason: 'the sheet is the modal route this test is about');
    expect(locationOf(tester), AppNameRoutes.wallet,
        reason: 'showModalBottomSheet pushes an imperative route on the root '
            'navigator; it is NOT a go_router location change');

    final BackPress press = await pressBack(tester, platform);

    // 1. The app survived, on both signals the probe reports.
    expect(press.exited, isFalse,
        reason: 'SystemNavigator.pop would have finished the Activity with a '
            'sheet merely open. $press');
    expect(press.popRouteReply, isTrue,
        reason: 'the press was claimed by the navigator popping the modal '
            'route, reached through super.didPopRoute(). $press');

    // 2. The sheet closed.
    expect(find.byType(WalletTopUpSheet), findsNothing,
        reason: 'Back dismissed the sheet');

    // 3. The policy never ran.
    expect(locationOf(tester), AppNameRoutes.wallet,
        reason: 'if the ordering in AppBackButtonDispatcher.didPopRoute were '
            'inverted, the policy would have consumed this press and walked '
            'the citizen back to / with the sheet still mounted over it');
  });

  testWidgets(
      'GOR-269 Stage 11 — the modal press did not consume a journey entry: '
      'the next Back still returns to the predecessor',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 4000);
    addTearDown(tester.view.reset);

    final AppHarness harness = await bootSignedIn();
    await pumpAssembledApp(tester, harness);
    final List<String> platform = interceptPlatformChannel(tester);

    // `/` → `/wallet`, so the journey has a predecessor to return to.
    expect(locationOf(tester), AppNameRoutes.home);
    await goTo(tester, AppNameRoutes.wallet);

    await _openTopUpSheet(tester);
    expect(find.byType(WalletTopUpSheet), findsOneWidget);

    // Press one: absorbed by the modal route, changes no location.
    await pressBack(tester, platform);
    expect(find.byType(WalletTopUpSheet), findsNothing);
    expect(locationOf(tester), AppNameRoutes.wallet);

    // Press two: the navigators now decline, so the policy runs — and it must
    // still hold `/` beneath `/wallet`. This is the assertion that catches an
    // arm left set: the retreat window opens before delegating, and if
    // `_endBack()` did not close it, the dismissing press above would have
    // been read as a backward step and rewritten the journey's head.
    final BackPress second = await pressBack(tester, platform);

    expect(second.exited, isFalse, reason: '$second');
    expect(locationOf(tester), AppNameRoutes.home,
        reason: 'the journey still knew /wallet s predecessor. A press '
            'absorbed by a modal route must leave the journey exactly as it '
            'found it');
  });
}

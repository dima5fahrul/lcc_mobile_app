/// **AC-7, first half** — all five bottom-nav destinations render and
/// navigate.
///
/// Driven through the assembled app rather than by pumping `AppShell` in
/// isolation. Pumping the shell alone would prove the bar draws; it would not
/// prove that tapping a destination reaches the route the router actually
/// serves, which is the half that can break. Sign-in is stubbed authenticated
/// so that `/history` and `/account` are reachable — the *guard* on those two
/// is AC-6 scenario 4's job, not this file's.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/features/account/presentation/pages/account_page.dart';
import 'package:lcc_mobile_app/features/history/presentation/pages/history_page.dart';
import 'package:lcc_mobile_app/features/home/presentation/pages/home_page.dart';
import 'package:lcc_mobile_app/features/service/presentation/pages/service_page.dart';
import 'package:lcc_mobile_app/features/wallet/presentation/pages/wallet_page.dart';
import 'package:lcc_mobile_app/presentation/shell/app_bottom_nav.dart';
import 'package:lcc_mobile_app/presentation/shell/app_shell.dart';
import 'package:lcc_mobile_app/presentation/shell/app_top_bar.dart';
import 'package:lcc_mobile_app/presentation/shell/language_toggle.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

import '../../helpers/app_test_harness.dart';
import '../../helpers/core_test_helper.dart';
import '../../helpers/session_test_helper.dart';

String locationOf(WidgetTester tester) {
  return GoRouter.of(tester.element(find.byType(AppShell)))
      .state
      .uri
      .toString();
}

void main() {
  tearDown(resetHarness);

  /// An authenticated app, so every one of the five destinations is reachable.
  Future<AppHarness> signedInApp(WidgetTester tester) async {
    final AppHarness harness = await bootHarness(
      seed: <String, String>{StorageKeys.accessToken: 'access-abc'},
    );
    harness.adapter.onGet(
      ApiEndpoint.meProfile,
      (server) => server.reply(200, okEnvelope(tCitizenProfileJson())),
    );
    await pumpAssembledApp(tester, harness);
    return harness;
  }

  testWidgets('renders the top bar, the five destinations and the bottom bar',
      (WidgetTester tester) async {
    await signedInApp(tester);

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(AppTopBar), findsOneWidget);
    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.byType(LanguageToggle), findsOneWidget);

    final NavigationBar bar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(bar.destinations, hasLength(5));
    expect(bar.selectedIndex, 0, reason: 'boot lands on home');

    for (final String label in <String>[
      'Home',
      'Service',
      'History',
      'Wallet',
      'Account',
    ]) {
      expect(find.text(label), findsWidgets, reason: '$label destination');
    }
  });

  testWidgets('every destination navigates to its own page and selects itself',
      (WidgetTester tester) async {
    await signedInApp(tester);

    final List<({String label, String path, Type page})> destinations =
        <({String label, String path, Type page})>[
      (label: 'Service', path: AppNameRoutes.service, page: ServicePage),
      (label: 'History', path: AppNameRoutes.history, page: HistoryPage),
      (label: 'Wallet', path: AppNameRoutes.wallet, page: WalletPage),
      (label: 'Account', path: AppNameRoutes.account, page: AccountPage),
      (label: 'Home', path: AppNameRoutes.home, page: HomePage),
    ];

    for (int i = 0; i < destinations.length; i++) {
      final ({String label, String path, Type page}) target = destinations[i];

      await tester.tap(find.text(target.label).last);
      await tester.pumpAndSettle();

      expect(locationOf(tester), target.path, reason: target.label);
      expect(find.byType(target.page), findsOneWidget, reason: target.label);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        shellIndexOf(target.path),
        reason: '${target.label} destination should be selected',
      );
      // The shell survives navigation — one Scaffold, not a stack of them.
      expect(find.byType(AppShell), findsOneWidget);
    }
  });

  testWidgets('tapping the already-selected destination is a no-op',
      (WidgetTester tester) async {
    await signedInApp(tester);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();

    expect(locationOf(tester), AppNameRoutes.home);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('the brand block in the top bar goes home',
      (WidgetTester tester) async {
    await signedInApp(tester);

    await tester.tap(find.text('Wallet').last);
    await tester.pumpAndSettle();
    expect(locationOf(tester), AppNameRoutes.wallet);

    await tester.tap(find.descendant(
      of: find.byType(AppTopBar),
      matching: find.byType(InkWell).first,
    ));
    await tester.pumpAndSettle();

    expect(locationOf(tester), AppNameRoutes.home);
  });
}

/// Index of [path] in the bottom bar, mirrored here so the expectation is
/// independent of the function under test in `shell_tabs_test.dart`.
int shellIndexOf(String path) {
  return const <String>[
    AppNameRoutes.home,
    AppNameRoutes.service,
    AppNameRoutes.history,
    AppNameRoutes.wallet,
    AppNameRoutes.account,
  ].indexOf(path);
}

/// **AC-6** — the five assembled-app flow tests.
///
/// GOR-245 § 7.3 substitutes the >= 70% *integration coverage* threshold with
/// these five enumerated scenarios, because `lcc_mobile_app` is a single client
/// process whose only integration partner lives outside this repository. They
/// run under plain `flutter test`: no simulator, no `integration_test`
/// dependency (§ 4.3 forbids it), Dio stubbed with `http_mock_adapter`.
///
/// Every object below the transport is the production one — `main.dart`'s own
/// `App`, `AppRoutes`, the single `SessionBloc`, the real `AuthBloc`,
/// `AuthPage`, `ApiClient`, both interceptors. That is deliberate: § 2.2's
/// defects **F-1** (no `SessionBloc` provider above the router), **F-2** (a
/// per-resolution `SessionBloc`) and **F-3** (auth feature never registered,
/// `/signin` serving a placeholder) were all invisible to 37 green unit tests.
/// Only an assembled app can catch them, and § 11 asks a reviewer to check
/// exactly that these are closed *by a test* rather than by inspection.
///
/// Scenario 3 drives the real `LoginForm` — phone, password and the math
/// captcha — rather than dispatching `AuthEvent.loginStarted` by hand. Hand
/// dispatching would skip `AuthPage`'s `BlocListener`, which is precisely where
/// F-1 lived.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/di/dependency_injection.dart';
import 'package:lcc_mobile_app/core/session/bloc/session_bloc.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/features/account/presentation/pages/account_page.dart';
import 'package:lcc_mobile_app/features/auth/presentation/pages/auth_page.dart';
import 'package:lcc_mobile_app/features/history/presentation/pages/history_page.dart';
import 'package:lcc_mobile_app/features/home/presentation/pages/home_page.dart';
import 'package:lcc_mobile_app/features/service/presentation/pages/service_page.dart';
import 'package:lcc_mobile_app/features/wallet/presentation/pages/wallet_page.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

import '../helpers/app_test_harness.dart';
import '../helpers/auth_mock_data.dart';
import '../helpers/core_test_helper.dart';
import '../helpers/session_test_helper.dart';

/// The router driving the pumped app. Reached through any mounted element, so
/// the test never has to hold `AppRoutes.build`'s return value — and never has
/// to call `router.dispose()`, which stalls for 30s while `MaterialApp.router`
/// is still mounted.
GoRouter routerOf(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));

String locationOf(WidgetTester tester) => routerOf(tester).state.uri.toString();

Future<void> goTo(WidgetTester tester, String path) async {
  routerOf(tester).go(path);
  await tester.pumpAndSettle();
}

void main() {
  tearDown(resetHarness);

  // ── Scenario 1 ────────────────────────────────────────────────────────────
  testWidgets('1. cold boot with no token resolves unauthenticated, and '
      '/history lands on /signin?from=%2Fhistory', (WidgetTester tester) async {
    final AppHarness harness = await bootHarness();

    await pumpAssembledApp(tester, harness);

    expect(harness.sessionBloc.state.status, SessionStatus.unauthenticated,
        reason: 'SessionStarted must have run and resolved');
    expect(find.byType(HomePage), findsOneWidget);

    await goTo(tester, AppNameRoutes.history);

    expect(locationOf(tester), '/signin?from=%2Fhistory');
    // F-3: /signin serves the real AuthPage, not the inline placeholder.
    expect(find.byType(AuthPage), findsOneWidget);
    expect(find.byType(HistoryPage), findsNothing);
    // The intended destination survives the round trip exactly once decoded —
    // `%2Fhistory` on the wire, `/history` in the page.
    expect(tester.widget<AuthPage>(find.byType(AuthPage)).from, '/history');
    // /signin is mounted outside the ShellRoute, so there is no bottom bar.
    expect(find.byType(NavigationBar), findsNothing);
  });

  // ── Scenario 2 ────────────────────────────────────────────────────────────
  testWidgets('2. cold boot with a stored token reaches authenticated without '
      'ever flashing /signin', (WidgetTester tester) async {
    final AppHarness harness = await bootHarness(
      seed: <String, String>{StorageKeys.accessToken: 'access-abc'},
    );
    // A slow profile call widens the boot window, so the hold is observable
    // instead of being raced away by an instant in-memory reply.
    harness.adapter.onGet(
      ApiEndpoint.meProfile,
      (server) => server.reply(
        200,
        okEnvelope(tCitizenProfileJson(account: tCitizenAccountJsonWith(name: 'Somsak'))),
        delay: const Duration(milliseconds: 300),
      ),
    );

    await mountAssembledApp(tester, harness);
    await tester.pump();

    // Mid-boot: the session has not resolved yet.
    expect(
      harness.sessionBloc.state.status,
      anyOf(SessionStatus.initial, SessionStatus.loading),
    );

    // Asking for a protected route during the boot hold must NOT bounce the
    // citizen — a token may well be about to resolve. This is the branch of
    // `_redirect` that returns null while the status is initial/loading.
    routerOf(tester).go(AppNameRoutes.account);
    await tester.pump();
    expect(find.byType(AuthPage), findsNothing,
        reason: 'a warm boot must not flash the signed-out screen');

    await tester.pumpAndSettle();

    expect(harness.sessionBloc.state.status, SessionStatus.authenticated);
    expect(harness.sessionBloc.state.profile?.name, 'Somsak');
    expect(locationOf(tester), AppNameRoutes.account);
    expect(find.byType(AccountPage), findsOneWidget);
    expect(find.byType(AuthPage), findsNothing);
  });

  // ── Scenario 3 ────────────────────────────────────────────────────────────
  testWidgets('3. a real login hands the session to SessionBloc and the router '
      'releases the citizen to the from destination (guards F-1 and F-2)',
      (WidgetTester tester) async {
    final AppHarness harness = await bootHarness();
    harness.adapter.onPost(
      ApiEndpoint.authLogin,
      (server) => server.reply(200, okEnvelope(tCitizenSessionJson())),
    );
    harness.adapter.onGet(
      ApiEndpoint.meProfile,
      (server) => server.reply(
        200,
        okEnvelope(tCitizenProfileJson(account: tCitizenAccountJsonWith(name: 'Somsak'))),
      ),
    );

    await pumpAssembledApp(tester, harness);

    // F-2, stated as an invariant before the flow runs: every resolution of
    // SessionBloc is the same object the router was handed.
    expect(injection<SessionBloc>(), same(harness.sessionBloc));
    expect(injection<SessionBloc>(), same(injection<SessionBloc>()));

    await goTo(tester, AppNameRoutes.account);
    expect(find.byType(AuthPage), findsOneWidget);
    expect(locationOf(tester), '/signin?from=%2Faccount');

    await _submitLogin(tester);

    // F-1: `AuthPage._onSession` calls `context.read<SessionBloc>()`. Without
    // the provider `main.dart` installs above `MaterialApp.router`, this throws
    // ProviderNotFoundException and the test dies here.
    //
    // F-2: the redirect below can only fire if the BLoC the page dispatched to
    // is the same one the router's refreshListenable is watching.
    expect(harness.sessionBloc.state.status, SessionStatus.authenticated);
    expect(harness.sessionBloc.state.profile?.name, 'Somsak');
    expect(locationOf(tester), AppNameRoutes.account,
        reason: 'the `from` intent must survive the sign-in');
    expect(find.byType(AccountPage), findsOneWidget);
    expect(find.byType(AuthPage), findsNothing);

    // The tokens the server issued are what got persisted.
    expect(harness.store[StorageKeys.accessToken], 'access-abc');
    expect(harness.store[StorageKeys.refreshToken], 'refresh-abc');
  });

  testWidgets('3b. signing in with no `from` intent lands on home',
      (WidgetTester tester) async {
    final AppHarness harness = await bootHarness();
    harness.adapter.onPost(
      ApiEndpoint.authLogin,
      (server) => server.reply(200, okEnvelope(tCitizenSessionJson())),
    );
    harness.adapter.onGet(
      ApiEndpoint.meProfile,
      (server) => server.reply(200, okEnvelope(tCitizenProfileJson())),
    );

    await pumpAssembledApp(tester, harness);
    await goTo(tester, AppNameRoutes.signin);
    expect(tester.widget<AuthPage>(find.byType(AuthPage)).from, isNull);

    await _submitLogin(tester);

    expect(locationOf(tester), AppNameRoutes.home);
    expect(find.byType(HomePage), findsOneWidget);
  });

  // ── Scenario 4 ────────────────────────────────────────────────────────────
  testWidgets('4. while unauthenticated, /history and /account are gated and '
      '/, /service, /wallet are not', (WidgetTester tester) async {
    final AppHarness harness = await bootHarness();
    await pumpAssembledApp(tester, harness);
    expect(harness.sessionBloc.state.status, SessionStatus.unauthenticated);

    // Protected — the set GOR-245 § 4.2 freezes as exactly {/history, /account}.
    for (final String protected in <String>[
      AppNameRoutes.history,
      AppNameRoutes.account,
    ]) {
      await goTo(tester, protected);

      expect(
        locationOf(tester),
        '/signin?from=${Uri.encodeComponent(protected)}',
        reason: '$protected must be gated',
      );
      expect(find.byType(AuthPage), findsOneWidget, reason: protected);

      // Back to a public tab so the next iteration starts from the shell.
      await goTo(tester, AppNameRoutes.home);
    }

    // Public.
    final Map<String, Type> public = <String, Type>{
      AppNameRoutes.home: HomePage,
      AppNameRoutes.service: ServicePage,
      AppNameRoutes.wallet: WalletPage,
    };
    for (final MapEntry<String, Type> entry in public.entries) {
      await goTo(tester, entry.key);

      expect(locationOf(tester), entry.key,
          reason: '${entry.key} must stay reachable signed out');
      expect(find.byType(entry.value), findsOneWidget, reason: entry.key);
      expect(find.byType(AuthPage), findsNothing, reason: entry.key);
    }
  });

  testWidgets('4b. a protected sub-route is gated by its parent prefix',
      (WidgetTester tester) async {
    final AppHarness harness = await bootHarness();
    await pumpAssembledApp(tester, harness);

    await goTo(tester, '/account/settings');

    expect(locationOf(tester), '/signin?from=%2Faccount%2Fsettings');
  });

  // ── Scenario 5 ────────────────────────────────────────────────────────────
  testWidgets('5. sign-out revokes, clears the tokens and redirects off '
      '/account', (WidgetTester tester) async {
    final AppHarness harness = await bootHarness(
      seed: <String, String>{
        StorageKeys.accessToken: 'access-abc',
        StorageKeys.refreshToken: 'refresh-abc',
      },
    );
    harness.adapter.onGet(
      ApiEndpoint.meProfile,
      (server) => server.reply(200, okEnvelope(tCitizenProfileJson())),
    );
    harness.adapter.onPost(
      ApiEndpoint.authLogout,
      (server) => server.reply(200, okEnvelope(null)),
    );

    await pumpAssembledApp(tester, harness);
    expect(harness.sessionBloc.state.status, SessionStatus.authenticated);

    await goTo(tester, AppNameRoutes.account);
    expect(find.byType(AccountPage), findsOneWidget);

    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    expect(harness.sessionBloc.state.status, SessionStatus.unauthenticated);
    expect(harness.sessionBloc.state.profile, isNull);
    expect(harness.store, isEmpty, reason: 'both tokens cleared');
    // Nothing in AccountPage navigates by hand: the router's refreshListenable
    // re-ran `redirect`, found /account protected and the citizen signed out.
    expect(locationOf(tester), '/signin?from=%2Faccount');
    expect(find.byType(AuthPage), findsOneWidget);
    expect(find.byType(AccountPage), findsNothing);
  });

  testWidgets('5b. sign-out still completes when the server-side revoke fails',
      (WidgetTester tester) async {
    final AppHarness harness = await bootHarness(
      seed: <String, String>{
        StorageKeys.accessToken: 'access-abc',
        StorageKeys.refreshToken: 'refresh-abc',
      },
    );
    harness.adapter.onGet(
      ApiEndpoint.meProfile,
      (server) => server.reply(200, okEnvelope(tCitizenProfileJson())),
    );
    harness.adapter.onPost(
      ApiEndpoint.authLogout,
      (server) => server.reply(500, failEnvelope(code: 'INTERNAL_ERROR')),
    );

    await pumpAssembledApp(tester, harness);
    await goTo(tester, AppNameRoutes.account);

    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    expect(harness.sessionBloc.state.status, SessionStatus.unauthenticated,
        reason: 'a failed revoke must never trap the citizen in the session');
    expect(harness.store, isEmpty);
  });

  // ── Cross-cutting ─────────────────────────────────────────────────────────
  testWidgets('the home sign-in CTA routes through the auth gate rather than '
      'hard-coding /signin', (WidgetTester tester) async {
    final AppHarness harness = await bootHarness();
    await pumpAssembledApp(tester, harness);

    await tester.tap(find.text('Sign in to activate'));
    await tester.pumpAndSettle();

    // HomePage sends the citizen to /account (protected) on purpose, so the
    // gate mints the `from` intent instead of the page duplicating it.
    expect(locationOf(tester), '/signin?from=%2Faccount');
  });

  testWidgets('an authenticated citizen visiting /signin is bounced home',
      (WidgetTester tester) async {
    final AppHarness harness = await bootHarness(
      seed: <String, String>{StorageKeys.accessToken: 'access-abc'},
    );
    harness.adapter.onGet(
      ApiEndpoint.meProfile,
      (server) => server.reply(200, okEnvelope(tCitizenProfileJson())),
    );

    await pumpAssembledApp(tester, harness);
    await goTo(tester, AppNameRoutes.signin);

    expect(locationOf(tester), AppNameRoutes.home);
    expect(find.byType(AuthPage), findsNothing);
  });
}

/// Fills the real `LoginForm` — including the `a + b = ?` captcha, whose
/// operands are randomised per mount and so must be read off the screen — and
/// taps Sign In.
Future<void> _submitLogin(
  WidgetTester tester, {
  String phone = '+8562012345',
  String password = 'password123',
}) async {
  final String question = tester
      .widgetList<Text>(find.textContaining(' + '))
      .map((Text t) => t.data ?? '')
      .firstWhere(
        (String s) => RegExp(r'^\d+ \+ \d+ = \?$').hasMatch(s),
        orElse: () => throw StateError('captcha not on screen'),
      );
  final List<int> operands = RegExp(r'\d+')
      .allMatches(question)
      .map((Match m) => int.parse(m.group(0)!))
      .toList();

  final Finder fields = find.byType(TextField);
  expect(fields, findsNWidgets(3), reason: 'login id, password, captcha');

  await tester.enterText(fields.at(0), phone);
  await tester.enterText(fields.at(1), password);
  await tester.enterText(fields.at(2), '${operands[0] + operands[1]}');
  await tester.pumpAndSettle();

  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();
}

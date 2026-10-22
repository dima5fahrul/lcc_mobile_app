/// **User decision, 2026-10-22 — the sign-in screen's door into the public
/// certificate-verification slice.**
///
/// The slice's first in-app door (review C-1) is on the account page, and
/// `/account` is in `AppRoutes._protectedPaths` while the verification routes
/// are public. So the citizen the guide's § Public verification endpoints opens
/// with — *"Two endpoints work without login"* — the one who starts the app to
/// check someone else's certificate, is redirected to
/// `/signin?from=%2Faccount` and, with only that door, could reach **no part**
/// of the verification slice at all. This file pins the second door, on the
/// screen they actually land on.
///
/// ## The assertion is NAVIGATION, not presence
///
/// A label-only test passes for a dead control, which is the exact failure C-1
/// was: three public routes, five result screens, a scanner and a PDF check,
/// all reachable by nothing. So this drives the **real** router — the assembled
/// app from `app_test_harness.dart`, the real `AppRoutes` table, the real
/// `/signin` and `/verify` route builders — taps the affordance and reads the
/// router's own location back, the way
/// `account_page_test.dart:433-439` does for the first door.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lcc_mobile_app/features/auth/presentation/pages/auth_page.dart';
import 'package:lcc_mobile_app/features/verify/di/verify_feature_injection.dart';
import 'package:lcc_mobile_app/features/verify/presentation/pages/verify_code_entry_page.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

import '../../../../helpers/app_test_harness.dart';

/// `account_page_test.dart:46-50`'s pair, for the reason that file records:
/// the originals are private to `app_flow_test.dart`'s `main()` scope, and a
/// cross-test import for two one-liners would couple this file's compilation
/// to a suite it has nothing else to do with.
GoRouter routerOf(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));

String locationOf(WidgetTester tester) =>
    routerOf(tester).state.uri.toString();

/// The pumped surface: `flutter_test`'s **default width**, and tall enough
/// that scrolling has somewhere to go.
///
/// The width is deliberately not a phone's. `LoginForm`'s *Forgot password?* /
/// *Don't have an account?* line is a `Row` with
/// `mainAxisAlignment: spaceBetween` and no flex on either child
/// (`login_form.dart:321-340`), so it overflows horizontally below roughly
/// 570 logical pixels — measured here at 390 px: *"A RenderFlex overflowed by
/// 177 pixels on the right"*, from a `Row` of exactly that shape. That is
/// **pre-existing** (this file's subject is a vertical `Column` appended below
/// it) and out of this round's scope; it is recorded rather than worked
/// around silently, and the width is kept at the framework default so the
/// overflow does not fail a test that is about navigation.
const Size kSurface = Size(800, 2400);

void main() {
  tearDown(resetHarness);

  /// Boots **signed out** and lands on `/signin`, the way a gated tap does.
  ///
  /// The tall surface is load-bearing, not cosmetic — the same measurement
  /// `account_page_test.dart` records. The login form is a seven-field card
  /// inside a `SingleChildScrollView`; at `flutter_test`'s default 800×600 its
  /// last control is outside the viewport, and `tester.tap` on an off-screen
  /// widget hits nothing while reading as "the button did not navigate".
  Future<void> onSignIn(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = kSurface;
    addTearDown(tester.view.reset);

    final AppHarness harness = await bootHarness();
    await pumpAssembledApp(tester, harness);

    // The `/verify` route builder resolves `VerifyBloc` out of the verify
    // container; `bootHarness` does not register it, so a test that navigates
    // there registers it — exactly as `verify_routes_test.dart` and
    // `account_page_test.dart` do.
    await VerifyFeatureInjection.init();

    routerOf(tester).go(AppNameRoutes.account);
    await tester.pumpAndSettle();

    // The premise: the citizen asked for a protected page, the gate bounced
    // them here, and this is the screen they are looking at.
    expect(locationOf(tester), '/signin?from=%2Faccount');
    expect(find.byType(AuthPage), findsOneWidget);
  }

  testWidgets('the sign-in screen offers "Verify a certificate", and tapping '
      'it lands on the public entry page', (WidgetTester tester) async {
    await onSignIn(tester);

    final Finder action = find.text('Verify a certificate');
    expect(action, findsOneWidget,
        reason: 'the door a signed-OUT citizen can actually reach');
    expect(
      find.text('Check any certificate by its code or QR code.'),
      findsOneWidget,
      reason: 'the two keys are REUSED from the account-page door — no '
          'near-duplicate pair, so en/lo key sets are untouched',
    );

    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();

    // The assertion that a presence check cannot make.
    expect(locationOf(tester), AppNameRoutes.verify,
        reason: 'the REAL router moved — the control is wired, not decorative');
    expect(find.byType(VerifyCodeEntryPage), findsOneWidget,
        reason: 'and the real route built the real page');
    expect(find.byType(AuthPage), findsNothing);
  });

  testWidgets('the public entry page is reached with NO session — the gate is '
      'never crossed', (WidgetTester tester) async {
    await onSignIn(tester);

    await tester.ensureVisible(find.text('Verify a certificate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verify a certificate'));
    await tester.pumpAndSettle();

    expect(locationOf(tester), AppNameRoutes.verify);
    // No `?from=`, and no bounce back to `/signin`: the verification routes
    // are deliberately absent from `AppRoutes._protectedPaths`, which is the
    // whole reason this door can exist on an unauthenticated screen.
    expect(locationOf(tester), isNot(contains('from=')));
    expect(find.byType(VerifyCodeEntryPage), findsOneWidget);
  });

  testWidgets('the Lao arm renders, from the same two keys',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = kSurface;
    addTearDown(tester.view.reset);

    final AppHarness harness = await bootHarness();
    await pumpAssembledApp(
      tester,
      harness,
      startLocale: const Locale('lo'),
    );
    await VerifyFeatureInjection.init();

    routerOf(tester).go(AppNameRoutes.signin);
    await tester.pumpAndSettle();

    final Finder action = find.text('ກວດສອບໃບຢັ້ງຢືນ');
    expect(action, findsOneWidget,
        reason: 'the Lao arm of `verify.openAction`, already in lo.json');

    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(locationOf(tester), AppNameRoutes.verify);
  });
}

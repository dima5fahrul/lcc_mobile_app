/// GOR-269 `SR-1` — the authorization backstop, proved with `I-6` disabled.
///
/// `security-review.md` § 3.1 rates this **High** and blocks merge on it, and
/// the reasoning is worth carrying next to the test rather than leaving in the
/// document:
///
/// > `AppRoutes._redirect` is **destination-based** — it runs on every route
/// > match go_router produces, regardless of what triggered it — and
/// > **session-reactive**, because the router's `refreshListenable` is bound to
/// > `SessionBloc.stream`. So it already covers the back policy's own
/// > navigations, **provided those navigations are issued through go_router's
/// > public routing API**. That proviso is the single fact the review's whole
/// > authorization-replay analysis turns on, and `specs.md`'s criteria did not
/// > assert it: `AC-11` asserts *placement*, `AC-17` asserts the 36 pre-existing
/// > call sites, and neither says anything about the policy's **own** call. A
/// > hand-rolled `RouteMatchList` splice or a direct `NavigatorState` push would
/// > bypass route matching entirely, would never reach `_redirect`, and would
/// > look — from every other test in this ticket — exactly like the policy
/// > working correctly.
///
/// `GOR-269-AC-28` proves `I-6` works on the sign-out edge, and
/// `back_policy_session_expiry_test.dart` proves it on the token-expiry one
/// (code review `M-1`). Neither can prove the backstop, because both only
/// exercise states in which the clearing already succeeded. `SR-1` asks for the
/// strictly stronger thing:
/// **disable the clearing, leave a stale protected location on the journey, and
/// show the citizen still cannot reach it.**
///
/// ## The fault injection, stated plainly
///
/// [_pumpWithoutSessionClearing] composes exactly what `main.dart` composes —
/// the real `AppRoutes.build`, the real `AppBackPolicy`, the real
/// `AppBackButtonDispatcher`, the same four-field `MaterialApp.router`, all of
/// it through `back_nav_harness.dart`'s `pumpMainComposition` — **except** that
/// the policy is handed a *decoy* `SessionBloc` that is never driven. The
/// router still watches the real one, so `_redirect` and `refreshListenable`
/// are production; the policy's session listener never fires, so `I-6` never
/// runs. Nothing in `lib/` is modified or stubbed to achieve that, which is
/// what makes this a fault injection rather than a different app: the one
/// argument below is the entire difference from production.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lcc_mobile_app/core/di/dependency_injection.dart';
import 'package:lcc_mobile_app/core/session/bloc/session_bloc.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/session/di/session_injection.dart';
import 'package:lcc_mobile_app/features/session/domain/repositories/session_repository.dart';
import 'package:lcc_mobile_app/features/session/domain/usecases/get_profile.dart';
import 'package:lcc_mobile_app/features/session/domain/usecases/update_profile.dart';
import 'package:lcc_mobile_app/features/account/presentation/pages/account_page.dart';
import 'package:lcc_mobile_app/features/auth/presentation/pages/auth_page.dart';
import 'package:lcc_mobile_app/utils/routes/app_back_policy.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

import '../helpers/app_test_harness.dart';
import '../helpers/back_nav_harness.dart';
import '../helpers/back_probe.dart';

/// A second `SessionBloc` over the same dependencies, never dispatched to.
///
/// Not a mock and not a stub — the real class, simply left in
/// `SessionStatus.initial` for the whole test. The policy subscribes to this
/// one, so its `I-6` latch never observes an authenticated session and
/// therefore never clears, no matter what the app's real session does.
SessionBloc _decoySessionBloc() => SessionBloc(
      storage: injection<StorageService>(),
      getProfile: sessionInjection<GetProfile>(),
      repository: sessionInjection<SessionRepository>(),
      updateProfile: sessionInjection<UpdateProfile>(),
    );

/// `main.dart`'s composition, with the policy's session listener neutered.
Future<GoRouter> _pumpWithoutSessionClearing(
  WidgetTester tester,
  AppHarness harness,
) async {
  final SessionBloc decoy = _decoySessionBloc();
  addTearDown(decoy.close);

  final ({GoRouter router, AppBackPolicy policy}) composed =
      await pumpMainComposition(tester, harness, policySession: decoy);
  return composed.router;
}

void main() {
  tearDown(resetHarness);

  testWidgets('SR-1 — with I-6 disabled, Back cannot reach a protected screen '
      'the citizen is no longer authorized for', (WidgetTester tester) async {
    final AppHarness harness = await bootSignedIn();
    final GoRouter router = await _pumpWithoutSessionClearing(tester, harness);
    final List<String> platform = interceptPlatformChannel(tester);

    expect(harness.sessionBloc.state.status, SessionStatus.authenticated);

    // Walk onto a protected route, so the journey holds it.
    router.go(AppNameRoutes.wallet);
    await tester.pumpAndSettle();
    router.go(AppNameRoutes.account);
    await tester.pumpAndSettle();
    expect(locationOfRouter(router), AppNameRoutes.account);
    expect(find.byType(AccountPage), findsOneWidget,
        reason: 'the precondition: the citizen really was on the protected '
            'screen, so a replay would have something to replay');

    // The session ends. `refreshListenable` re-evaluates `_redirect` against
    // the current location with no Back press required — the pre-existing
    // control this ticket does not modify.
    harness.sessionBloc.add(const SessionEvent.signOut());
    await tester.pumpAndSettle();
    expect(harness.sessionBloc.state.status, SessionStatus.unauthenticated);
    expect(locationOfRouter(router), startsWith(AppNameRoutes.signin));

    // `I-6` never ran, so `/account` is still sitting in the journey. This is
    // the state AC-28 can never reach.
    final BackPress press = await pressBack(tester, platform);

    expect(find.byType(AccountPage), findsNothing,
        reason: 'the protected screen rendered after a Back press taken with '
            'the journey-clearing disabled. That is authorization replay, and '
            'it is only prevented because the policy navigates through '
            "go_router's public API and therefore through `_redirect`. $press");
    expect(find.byType(AuthPage), findsOneWidget);
    expect(locationOfRouter(router), startsWith(AppNameRoutes.signin),
        reason: 'the auth gate caught the policy s own navigation, exactly as '
            'it catches a context.go() from a page');
  });

  testWidgets('SR-1 — the same holds for a protected route reached by Back '
      'from a deeper journey', (WidgetTester tester) async {
    // A second shape: the stale protected location is not the top of the
    // journey but one step down, so the press that reaches it is the second.
    final AppHarness harness = await bootSignedIn();
    final GoRouter router = await _pumpWithoutSessionClearing(tester, harness);
    final List<String> platform = interceptPlatformChannel(tester);

    router.go(AppNameRoutes.account);
    await tester.pumpAndSettle();
    router.go(AppNameRoutes.wallet);
    await tester.pumpAndSettle();
    expect(locationOfRouter(router), AppNameRoutes.wallet);

    harness.sessionBloc.add(const SessionEvent.signOut());
    await tester.pumpAndSettle();
    // `/wallet` is not protected, so the sign-out leaves the citizen on it.
    expect(locationOfRouter(router), AppNameRoutes.wallet);

    await pressBack(tester, platform);

    expect(find.byType(AccountPage), findsNothing,
        reason: 'Back stepped onto the stale /account entry and the auth gate '
            'redirected it');
    expect(locationOfRouter(router), startsWith(AppNameRoutes.signin));
  });

  testWidgets('SR-1 control — the same journey DOES replay while the citizen '
      'is still authorized', (WidgetTester tester) async {
    // Without this row the two above would pass just as well against a policy
    // that never navigates at all. This is what makes them evidence about the
    // auth gate rather than about a broken mechanism.
    final AppHarness harness = await bootSignedIn();
    final GoRouter router = await _pumpWithoutSessionClearing(tester, harness);
    final List<String> platform = interceptPlatformChannel(tester);

    router.go(AppNameRoutes.account);
    await tester.pumpAndSettle();
    router.go(AppNameRoutes.wallet);
    await tester.pumpAndSettle();

    await pressBack(tester, platform);

    expect(locationOfRouter(router), AppNameRoutes.account,
        reason: 'still authenticated, so Back really does return to /account — '
            'the mechanism works, and the two rows above are therefore about '
            'the guard rather than about an inert policy');
    expect(find.byType(AccountPage), findsOneWidget);
  });
}

/// GOR-269 `I-6` on the **expiry** path — code review `M-1`, and the half of
/// `security-review.md` `SR-2` that `AC-28` cannot reach.
///
/// `AC-28` drives `SessionEvent.signOut()`, which emits `unauthenticated`
/// directly (`session_bloc.dart:157-177`). That is one of the two ways a
/// session ends, and it was the only one any test in this ticket exercised — so
/// the policy's session listener could be, and was, keyed to an edge that the
/// *other* way never produces:
///
/// > `_onRefreshProfile` finds the tokens still on disk and emits
/// > **`loading`** (`session_bloc.dart:180-193`); the server then rejects the
/// > token and `_loadProfile`'s 401 branch emits `unauthenticated`
/// > (`session_bloc.dart:273-283`). `authenticated → loading →
/// > unauthenticated`, with no `authenticated → unauthenticated` edge anywhere
/// > in it.
///
/// The consequence on that path was a journey that outlived the session that
/// produced it: `/account` still on it for the next citizen to hand the phone
/// to, and one Back press at `/signin` that visibly did nothing — GOR-269's own
/// defect, relocated rather than removed, which is the phrase the policy's own
/// doc comment uses about it.
///
/// ## The three rows, and why the third is not padding
///
/// Rows 1 and 2 drive the expiry and assert the two things `I-6` promises, on
/// two independent instruments: the assembled `App` from `lib/main.dart`
/// (citizen-visible: Back exits) and `main.dart`'s composition held directly
/// (the model: the journey itself).
///
/// Row 3 is the control on the fix rather than on the defect. The narrowest
/// repair that turns rows 1 and 2 green — *clear on any arrival at
/// `unauthenticated` from a status that is not already `unauthenticated`* —
/// also fires on `unauthenticated → loading → unauthenticated`, which is what a
/// sign-in whose profile call 401s produces. That would wipe an anonymous
/// citizen's `/` → `/news` → `/signin` journey and make Back at `/signin` exit
/// the app, which is the defect this whole ticket exists to remove. Without row
/// 3 that repair passes everything.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/core/session/bloc/session_bloc.dart';
import 'package:lcc_mobile_app/utils/routes/app_back_policy.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

import '../helpers/app_test_harness.dart';
import '../helpers/back_nav_harness.dart';
import '../helpers/back_probe.dart';
import '../helpers/core_test_helper.dart';
import '../helpers/session_test_helper.dart';

/// The server stops honouring the access token.
///
/// Registered **after** the harness's own `/me/profile` stub so it wins — the
/// ordering `back_nav_harness.dart`'s `bootSignedIn` already relies on for
/// `/services`. Nothing else changes: the citizen's tokens are still on disk,
/// which is exactly why `_onRefreshProfile` takes its `loading` branch instead
/// of going straight to `unauthenticated`.
void _rejectTheToken(AppHarness harness) {
  harness.adapter.onGet(
    ApiEndpoint.meProfile,
    (dynamic server) => server.reply(
      401,
      failEnvelope(code: ApiCode.unauthorized, message: 'Token expired'),
    ),
  );
}

/// Records every status the session passes through from now on.
///
/// The emission *order* is asserted rather than only the final state: reaching
/// `unauthenticated` proves nothing here, because `AC-28` reaches it too. What
/// distinguishes this suite is that `loading` sits in between.
List<SessionStatus> _watchSession(SessionBloc bloc) {
  final List<SessionStatus> seen = <SessionStatus>[];
  final sub = bloc.stream.listen((SessionState s) => seen.add(s.status));
  addTearDown(sub.cancel);
  return seen;
}

void main() {
  tearDown(resetHarness);

  testWidgets('M-1 / SR-2 — a session that expires mid-journey is cleared, so '
      'Back at /signin exits instead of bouncing', (WidgetTester tester) async {
    // The assembled app, so this is the citizen's experience and not a model's.
    final AppHarness harness = await bootSignedIn();
    await pumpAssembledApp(tester, harness);
    final List<String> platform = interceptPlatformChannel(tester);

    await goTo(tester, AppNameRoutes.wallet);
    await goTo(tester, AppNameRoutes.account);
    expect(locationOf(tester), AppNameRoutes.account,
        reason: 'the precondition: a real protected journey exists to survive');
    expect(harness.sessionBloc.state.status, SessionStatus.authenticated);

    final List<SessionStatus> seen = _watchSession(harness.sessionBloc);

    // The avatar-upload success path dispatches exactly this
    // (`account_page.dart:188`). The tokens are still on disk, so the bloc
    // goes through `loading` on its way out.
    _rejectTheToken(harness);
    harness.sessionBloc.add(const SessionEvent.refreshProfile());
    await tester.pumpAndSettle();

    expect(
      seen,
      <SessionStatus>[SessionStatus.loading, SessionStatus.unauthenticated],
      reason: 'the path under test is authenticated → loading → '
          'unauthenticated. If this reads [unauthenticated] the row has '
          'silently become a second copy of AC-28 and proves nothing new',
    );
    expect(locationOf(tester), startsWith(AppNameRoutes.signin),
        reason: '`refreshListenable` re-evaluates `_redirect` on the session '
            'edge, with no Back press required');

    final BackPress press = await pressBack(tester, platform);

    expect(press.exited, isTrue,
        reason: 'a journey retained across the expiry sends Back at /signin to '
            'the stale /account, which `_redirect` bounces straight back — one '
            'press that visibly does nothing. $press');
    expect(locationOf(tester), startsWith(AppNameRoutes.signin),
        reason: 'and it certainly must not land on /account');
  });

  testWidgets('M-1 — the expiry empties the journey, not just the one edge '
      'AC-28 drives', (WidgetTester tester) async {
    // The same expiry against `main.dart`'s composition held directly, so the
    // model itself can be asserted rather than inferred from a press.
    final AppHarness harness = await bootSignedIn();
    final ({GoRouter router, AppBackPolicy policy}) app =
        await pumpMainComposition(tester, harness);

    app.router.go(AppNameRoutes.wallet);
    await tester.pumpAndSettle();
    app.router.go(AppNameRoutes.account);
    await tester.pumpAndSettle();

    expect(
      app.policy.journey,
      <String>[
        AppNameRoutes.home,
        AppNameRoutes.wallet,
        AppNameRoutes.account,
      ],
      reason: 'the precondition, stated as the journey rather than as a '
          'location: three entries, the last of them protected',
    );
    expect(app.policy.hasPredecessor, isTrue);

    final List<SessionStatus> seen = _watchSession(harness.sessionBloc);
    _rejectTheToken(harness);
    harness.sessionBloc.add(const SessionEvent.refreshProfile());
    await tester.pumpAndSettle();

    expect(
      seen,
      <SessionStatus>[SessionStatus.loading, SessionStatus.unauthenticated],
    );

    expect(app.policy.journey, isNot(contains(AppNameRoutes.account)),
        reason: '`security-review.md` § 2.3 justification 1 — privacy hygiene '
            'on a shared device. The screens citizen A visited must not be '
            'readable, as a usage shape, by citizen B handed the same phone. '
            'Journey: ${app.policy.journey}');
    expect(app.policy.hasPredecessor, isFalse,
        reason: '§ 2.3 justification 2 — the dead-bounce. Any predecessor left '
            'here is one Back press that navigates, gets redirected, and looks '
            'to the citizen like Back is broken. Journey: '
            '${app.policy.journey}');
  });

  testWidgets('M-1 control — a sign-in whose profile call 401s does NOT clear '
      'a journey that was never authenticated', (WidgetTester tester) async {
    final AppHarness harness = await bootSignedOut();
    final ({GoRouter router, AppBackPolicy policy}) app =
        await pumpMainComposition(tester, harness);

    // An anonymous journey through public routes — nothing here belongs to a
    // session, so nothing here is `I-6`'s to clear.
    app.router.go(AppNameRoutes.news);
    await tester.pumpAndSettle();
    app.router.go(AppNameRoutes.signin);
    await tester.pumpAndSettle();
    expect(
      app.policy.journey,
      <String>[AppNameRoutes.home, AppNameRoutes.news, AppNameRoutes.signin],
    );

    final List<SessionStatus> seen = _watchSession(harness.sessionBloc);

    // `auth_page.dart:173`. The credentials are accepted and the tokens are
    // saved, so the bloc emits `loading`; the profile call then rejects them,
    // and the citizen lands back where they started — having never been
    // authenticated at any point.
    _rejectTheToken(harness);
    harness.adapter.onPost(
      ApiEndpoint.authRefresh,
      (dynamic server) => server.reply(
        401,
        failEnvelope(code: ApiCode.unauthorized, message: 'Token expired'),
      ),
    );
    harness.sessionBloc.add(SessionEvent.signIn(tCitizenSession()));
    await tester.pumpAndSettle();

    expect(
      seen,
      <SessionStatus>[SessionStatus.loading, SessionStatus.unauthenticated],
      reason: 'unauthenticated → loading → unauthenticated: the same shape as '
          'the expiry above, and the reason `I-6` cannot simply be keyed to '
          '"arrived at unauthenticated from something else"',
    );

    expect(
      app.policy.journey,
      <String>[AppNameRoutes.home, AppNameRoutes.news, AppNameRoutes.signin],
      reason: 'no authenticated session ever existed, so there is none to end. '
          'Clearing here would take Back at /signin from "return to the '
          'article" to "exit the app" — GOR-269 s own defect, re-introduced '
          'while fixing M-1',
    );
    expect(app.policy.hasPredecessor, isTrue);
  });
}

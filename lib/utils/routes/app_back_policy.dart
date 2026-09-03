/// GOR-269 — the app-level hardware-Back policy, and the one adapter that
/// installs it.
///
/// Android hardware Back exited the app from 13 of the 15 routes this app
/// mounts (`qa-report.md` § 2.4, measured, 6 byte-identical runs). The cause is
/// not thirteen bugs: it is **one absent policy at one composition point**.
/// Every `context.go()` on a top-level route produces a single-entry match
/// list, so `GoRouterDelegate.popRoute()` finds no page to pop, no
/// `WidgetsBindingObserver` claims the press — the app registers none of its
/// own (`fix-plan.md` § 1.2) — and `WidgetsBinding.handlePopRoute()` falls
/// through to `SystemNavigator.pop()`, which finishes the Activity.
///
/// So the remedy is scaled to the cause rather than to the symptom: one policy,
/// installed once, covering all 13 routes **and every route added after this
/// one**. `root-cause.md` § 9.2 is the ruling — *the 13 routes are the blast
/// radius, not the work items* — and `specs.md` § 7 deliberately writes no
/// route-count acceptance criterion, because a criterion of that shape would be
/// satisfied by thirteen route-local handlers and would certify the very
/// anti-pattern `FU-B12-1` rejected.
///
/// ## The mechanism, and why the order is the load-bearing part
///
/// [AppBackButtonDispatcher] subclasses `RootBackButtonDispatcher` and
/// overrides `didPopRoute()` to call **`super` first**. `super` is
/// `invokeCallback(...)`, which reaches `Router` →
/// `GoRouterDelegate.popRoute()` → each live `NavigatorState.maybePop()`. Only
/// when every navigator has declined does [AppBackPolicy] get consulted.
///
/// That ordering is what preserves the two measured non-regressions **by
/// construction rather than by a re-implemented check**:
///
/// * `/news/:slug` is a child route, so its match list carries two matches and
///   its navigator holds two pages. `maybePop()` pops it to `/news` and the
///   policy is never reached (`qa-report.md` § 2.7).
/// * `/history`'s open detail is guarded by a widget-level pop guard whose
///   `canPop` is false while the detail is showing. `maybePop()` returns true
///   without changing the route, `HistoryReturnedFromDetail` still dispatches,
///   and the policy is never reached (`B7-AC-75`, `B7-AC-76`).
///
/// The obvious alternative — a bare `WidgetsBindingObserver` registered in
/// `_AppState.initState()` — would register *before* the `Router` mounts and
/// therefore be consulted *first*, and would have to re-derive "can the router
/// pop?" by hand to avoid breaking both of the above. Same outcome when
/// correct, strictly more ways to be wrong. `fix-plan.md` § 8.2 rejected it.
///
/// Predictive back (Android 14+) needs no second mechanism: `flutter/backgesture`
/// arrives on its own channel, but `WidgetsBinding._handleCommitBackGesture`
/// falls through to the same `handlePopRoute()` when no observer claims the
/// gesture, so anything installed at the observer level covers both channels
/// (`qa-report.md` § 2.8, `OQ-7` closed).
///
/// ## What this file deliberately does not do
///
/// * **It does not touch the route table.** No mount point moves, no
///   `navigatorKey` is threaded, no second `Navigator` is introduced. The nine
///   full-frame routes stay top-level, which is what hides the bottom bar
///   (`B12` `RULING 2`, `FC-1`), and a nested per-tab stack is an approved
///   architectural rejection (`ssd.md` § 9.3, `FC-2`).
/// * **It does not touch any of the 36 `context.go()` call sites.** Turning
///   some of them into `push()` would fix nine routes, leave the four tabs
///   broken, and keep the shell — and its 4,000 ms chat poll — mounted behind
///   every step of a seven-step form (`fix-plan.md` § 7.1).
/// * **It does not log.** `SR-4` constrains any diagnostic output of the
///   journey to route paths and forbids token or header content; the cheapest
///   way to satisfy a constraint on logging is to emit none, and a navigation
///   journey is not worth a log line on a national-identity app.
/// * **It does not persist anything.** `I-7` / `FC-7` — the secure-storage key
///   set is frozen at three by `GOR-245` § 4.2 and this adds no fourth.
///
/// ## The one security requirement written into the code
///
/// `security-review.md` `SR-1` (High, blocks merge): the policy's navigation
/// **must** go through `GoRouter`'s public routing API. It does — [
/// AppBackPolicy._handleBack] calls `GoRouter.go`, and nothing here reaches for
/// a `NavigatorState` or splices a `RouteMatchList`. That is the whole basis of
/// the review's authorization-replay finding: only a navigation that enters
/// route matching is seen by `AppRoutes._redirect`, which is destination-based
/// and bound to `SessionBloc` through `refreshListenable`. A hand-rolled match
/// splice would bypass the auth gate entirely and would look, from the outside,
/// exactly like this file working correctly.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/session/bloc/session_bloc.dart';
import 'back_visit_stack.dart';

/// Owns the citizen's journey and answers the one question Back asks.
///
/// Three responsibilities, kept apart on purpose (`fix-plan.md` § 8.3):
/// [BackVisitStack] holds the model, this class observes the router and the
/// session to keep it current, and [AppBackButtonDispatcher] is the only piece
/// that faces the Flutter framework.
///
/// Construct once, in `main.dart`, alongside the router. Call [dispose] with
/// the state that owns it.
class AppBackPolicy {
  /// Binds the policy to [router] and [sessionBloc].
  ///
  /// Both listeners are attached here rather than lazily, because the journey
  /// has to be complete from the first resolved location: a policy that starts
  /// observing on the first Back press has already missed every screen the
  /// citizen walked through to reach it.
  AppBackPolicy({
    required GoRouter router,
    required SessionBloc sessionBloc,
    int bound = BackVisitStack.kDefaultBound,
    // An initializing formal would have to be named `_router`, and a named
    // parameter may not start with an underscore. Same trade-off, same
    // resolution, as `core/network/api_client.dart:21`.
    // ignore: prefer_initializing_formals
  })  : _router = router,
        _stack = BackVisitStack(bound: bound),
        _sessionLive = sessionBloc.state.status == SessionStatus.authenticated {
    _router.routerDelegate.addListener(_onRouterChanged);
    _sessionSub = sessionBloc.stream.listen(_onSessionChanged);
    // Seed from whatever the router has already resolved.
    //
    // **A no-op as this app composes today, and the reason is worth stating
    // rather than leaving as a claim that reads the other way** (code review
    // `L-1`): `GoRouterDelegate.currentConfiguration` starts as
    // `RouteMatchList.empty` (`delegate.dart:211`) and the `GoRouter`
    // constructor never parses. `Router.initState` only attaches listeners
    // (Flutter `widgets/router.dart:618-623`); the first parse is kicked off
    // from `_RouterState.restoreState` (Flutter `widgets/router.dart:634-639`)
    // via `RestorationMixin.didChangeDependencies`, which runs after
    // `_AppState.initState` has constructed this — and resolves asynchronously
    // at that. So `configuration.isEmpty` is true here every time,
    // including on a cold deep link; the initial location is recorded by the
    // listener attached one line above, when `setInitialRoutePath` reaches
    // `notifyListeners()` (`delegate.dart:318-322`). That is the path `AC-21`
    // and `AC-22` measure green.
    //
    // Kept, one line, because the constructor's contract above is *the journey
    // is complete from the first resolved location* and this is the only thing
    // that holds it under a construction order in which the router is already
    // mounted. Deleting it would make that contract depend silently on an
    // ordering nothing asserts.
    _onRouterChanged();
  }

  final GoRouter _router;
  final BackVisitStack _stack;

  StreamSubscription<SessionState>? _sessionSub;

  /// Whether an authenticated session has been observed and has not yet ended.
  ///
  /// The latch [_onSessionChanged] reads; see there for why `I-6` is expressed
  /// as a latch on the session rather than as an edge in `SessionBloc`'s
  /// transition graph.
  bool _sessionLive;

  /// How many Back presses are currently in flight.
  ///
  /// While greater than zero, a change in the router's location is read as a
  /// **retreat** rather than as a new visit. Nothing else can supply that
  /// distinction: a navigator pop to `/news` and a `context.go('/news')` from
  /// the article's chevron produce an identical match list, and only the
  /// dispatcher knows which one a Back press caused. See
  /// [BackVisitStack.retreat] for what goes wrong when the distinction is lost.
  ///
  /// **A depth count rather than a flag** (code review `L-4`).
  /// [AppBackButtonDispatcher.didPopRoute] is `async` and awaits
  /// `super.didPopRoute()`, so two presses arriving close together interleave:
  /// with a bool, press B opens the window, press A's `finally` closes it, and
  /// B's own navigation is then recorded as a forward visit. A bool cannot
  /// express *still inside a press*; a count can. It is balanced by
  /// construction — the only two call sites are that method's first line and
  /// its `finally`.
  int _backDepth = 0;

  /// The journey as it stands. Test-facing; the app reads it through
  /// [_handleBack].
  @visibleForTesting
  List<String> get journey => _stack.entries;

  /// Whether Back currently has somewhere to go rather than exiting the app.
  @visibleForTesting
  bool get hasPredecessor => _stack.hasPredecessor;

  /// Opens the retreat window. Called by the dispatcher before it delegates.
  void _beginBack() => _backDepth++;

  /// Closes the retreat window.
  void _endBack() => _backDepth--;

  /// The policy's answer to a Back press no navigator handled.
  ///
  /// Returns true when it navigated (suppressing the exit) and false when the
  /// journey has no predecessor, which lets `WidgetsBinding.handlePopRoute()`
  /// fall through to `SystemNavigator.pop()` and close the app — `I-8`, and the
  /// reason `/` still exits from a fresh session (`AC-18`) and a cold deep link
  /// at a top-level route still exits (`AC-21`).
  ///
  /// The destination is popped off the journey *before* navigating, so the
  /// arrival lands on a head that already holds it and cannot deepen the
  /// journey — `I-5`, the invariant that stops Back oscillating between two
  /// entries forever.
  ///
  /// `GoRouter.go` and nothing else: `SR-1`.
  bool _handleBack() {
    final String? destination = _stack.stepBack();
    if (destination == null) return false;
    _router.go(destination);
    return true;
  }

  /// Releases both subscriptions.
  void dispose() {
    _router.routerDelegate.removeListener(_onRouterChanged);
    unawaited(_sessionSub?.cancel());
    _sessionSub = null;
  }

  /// The journey observation (`fix-plan.md` § 8.3 responsibility 2).
  ///
  /// Reads `currentConfiguration` rather than instrumenting the 36 call sites,
  /// which is what makes the policy cover routes nobody has written yet. It
  /// also reads the **resolved** location, which `I-1` requires: go_router
  /// applies `redirect` during parsing, so by the time the delegate notifies,
  /// an unauthenticated `go('/wallet')` has already become
  /// `/signin?from=%2Fwallet`. Recording the requested location instead would
  /// put a screen the citizen never saw into their back journey (`AC-23`).
  void _onRouterChanged() {
    final RouteMatchList configuration = _router.routerDelegate.currentConfiguration;
    // `RouteMatchList.empty` before the first route resolves — it has no
    // meaningful uri, and recording it would seed the journey with `''`.
    if (configuration.isEmpty) return;

    final String location = configuration.uri.toString();
    if (_backDepth > 0) {
      _stack.retreat(location);
    } else {
      _stack.record(location);
    }
  }

  /// `I-6` — the journey does not survive a session.
  ///
  /// `security-review.md` § 2.3 gives this two independent justifications, and
  /// the ticket's own documents state only the second:
  ///
  /// 1. **Privacy hygiene on a shared device.** Even though § 2.2 measured the
  ///    journey's contents to be non-sensitive route paths, *"citizen A visited
  ///    `/account` then `/wallet`"* is still a usage shape citizen B, handed the
  ///    same phone after A signs out, should not get for free.
  /// 2. **The dead-bounce.** Without clearing, Back at `/signin` would try to
  ///    navigate to a stale protected predecessor, `_redirect` would bounce it
  ///    straight back, and Back would *appear* to do nothing — GOR-269's own
  ///    defect, relocated rather than removed.
  ///
  /// This is defense in depth, **not** the control that stops authorization
  /// replay. That control is `AppRoutes._redirect`, which is destination-based
  /// and session-reactive and therefore sees this policy's navigations like any
  /// other. `security-review.md` § 2.1 is explicit that both are required and
  /// neither substitutes for the other, and
  /// `back_policy_authorization_test.dart` proves the redirect backstop holds
  /// **with this clearing disabled**.
  ///
  /// ## The condition is a latch on the session, not an edge in the bloc
  ///
  /// This first required the **immediately preceding** status to be
  /// `authenticated`, and `SessionBloc` does not always supply that edge. The
  /// reachable token-expiry path is `authenticated → loading →
  /// unauthenticated`: `_onRefreshProfile` still finds tokens on disk and emits
  /// `loading` (`session_bloc.dart:180-193`), then `_loadProfile`'s 401 branch
  /// clears them and emits `unauthenticated` (`session_bloc.dart:273-283`). So
  /// on the one path both justifications above are written for, nothing
  /// cleared: `/account` survived the session that produced it, and the next
  /// Back press bounced off `_redirect` and did nothing (code review `M-1`).
  ///
  /// Widening the edge to *any* arrival at `unauthenticated` from a
  /// non-`unauthenticated` status fixes that path and opens another, because
  /// `loading` is also reached from a signed-out start: a sign-in whose profile
  /// call 401s runs `unauthenticated → loading → unauthenticated`
  /// (`auth_page.dart:173`). That would wipe a journey built entirely by a
  /// citizen who was never authenticated in it, and Back at `/signin` would
  /// exit the app instead of returning to the article they were reading —
  /// GOR-269's own defect written back in on a narrower path.
  ///
  /// **Measured, not reasoned:** with that widened predicate in place,
  /// `back_policy_session_expiry_test.dart`'s control row reports the journey
  /// `['/', '/news', '/signin']` arriving as `[]`. No pre-existing row catches
  /// it — `AC-8`'s signed-out `/signin` row survives it, because the boot-time
  /// `initial → unauthenticated` clear it also causes is immediately undone
  /// when `refreshListenable`'s reparse re-records `/`. That row is therefore
  /// the only guard on this, and deleting it silently re-opens the choice.
  ///
  /// So the predicate is the question `I-6` is actually asking — *did an
  /// authenticated session end?* — held in [_sessionLive] rather than inferred
  /// from the last transition. It also survives a new intermediate status being
  /// added to `SessionStatus`, which an edge predicate does not; that coupling
  /// is what produced `M-1`.
  ///
  /// A token expiry that never reaches `SessionBloc` is still not visible here
  /// — but it is not visible to `_redirect` either, which reads the same single
  /// field, so this neither improves nor worsens that case
  /// (`security-review.md` § 2.1).
  void _onSessionChanged(SessionState state) {
    if (state.status == SessionStatus.authenticated) {
      _sessionLive = true;
      return;
    }
    if (state.status == SessionStatus.unauthenticated && _sessionLive) {
      _sessionLive = false;
      _stack.clear();
    }
  }
}

/// The single composition point: the only thing in this app that faces
/// `WidgetsBinding`'s back channels.
///
/// Supplied to `MaterialApp.router` as `backButtonDispatcher:`. Note that
/// `GoRouter` 16.3.0 hard-initialises its own `RootBackButtonDispatcher` in its
/// constructor initialiser list (`router.dart:244`) and does not accept one as
/// a parameter, and that `WidgetsApp.router` asserts *"If the routerConfig is
/// provided, all the other router delegates must not be provided"*
/// (`app.dart:466-474`). So this cannot be installed through `routerConfig:`;
/// `main.dart` passes the four-field expansion instead — `FC-5`, and
/// `AC-31` is what keeps that wiring honest.
class AppBackButtonDispatcher extends RootBackButtonDispatcher {
  /// Wraps [policy]. One instance, constructed once in `main.dart`.
  AppBackButtonDispatcher(this._policy);

  final AppBackPolicy _policy;

  /// Delegate first, decide second.
  ///
  /// `super.didPopRoute()` is `invokeCallback(Future<bool>.value(false))`,
  /// which reaches `GoRouterDelegate.popRoute()` and every live navigator's
  /// `maybePop()`. A `true` from it means a real route or a route-level guard
  /// handled the press, and the policy must stay out of the way entirely —
  /// that is how `/news/:slug` and `/history`'s detail keep working unchanged.
  ///
  /// The window is opened *before* delegating and closed in a `finally` so that
  /// a location change caused by this press — whoever caused it — is read as a
  /// retreat and not as a new visit. Closing it matters as much as opening it:
  /// `/history`'s detail guard handles the press **without** changing the route,
  /// so no notification arrives, and an arm left set would misread the citizen's
  /// next tab tap as a backward step.
  @override
  Future<bool> didPopRoute() async {
    _policy._beginBack();
    try {
      if (await super.didPopRoute()) return true;
      return _policy._handleBack();
    } finally {
      _policy._endBack();
    }
  }
}

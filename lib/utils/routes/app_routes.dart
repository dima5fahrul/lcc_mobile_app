/// Auth-aware `GoRouter` for the LCC citizen portal.
///
/// Ports `lcc-app/src/app/App.tsx`'s auth gate (`PROTECTED_TABS`,
/// `handleTabChange`, `handleAuthSuccess`) and the hash-based routing in
/// `lcc-app/src/app/routes.ts` onto `go_router`.
///
/// ## What was ported
///
/// - `PROTECTED_TABS` → [AppRoutes._protectedPaths] (`/history`, `/account`
///   for P0-3; the certificate sub-routes land in the next P0 stage).
/// - `handleTabChange` + `requireAuth` → the `redirect` callback: a protected
///   path visited while unauthenticated redirects to
///   `/signin?from=<intended>`, carrying the intended location as a query
///   param so `AuthPage` (P0-6) can return there on success.
/// - `handleAuthSuccess` (the `pendingRef.current ?? "account"` default) →
///   the `/signin` branch of `redirect`: an authenticated user on `/signin`
///   is sent to the `from` param, or `/` when there is none.
/// - The boot-splash hold (`if (bootPhase === "loading" || session.loading)`)
///   → the `loading`/`initial` branch of `redirect`: while the session BLoC
///   has not yet resolved, the redirect returns `null` (no redirect) so the
///   splash/loading route can render instead of bouncing the citizen to
///   `/signin` for a token that may already exist.
///
/// ## Refresh wiring
///
/// `go_router`'s `refreshListenable` re-runs `redirect` whenever the supplied
/// `Listenable` fires. The session state lives in `SessionBloc` (a BLoC, so
/// its state changes are emitted on a `Stream<SessionState>`, not a
/// `Listenable`). [_GoRouterRefreshStream] bridges that: it subscribes to the
/// BLoC's `stream` and calls `notifyListeners()` on every emission, so the
/// router re-evaluates the redirect the moment `loading` → `authenticated`
/// (boot) or `authenticated` → `unauthenticated` (sign-out) lands.
///
/// `StorageService.authStateNotifier` is NOT used as the refresh source on
/// purpose: it starts `false` and `SessionStarted` (the boot handler) only
/// reads the token via `isAuthenticated()` without calling `saveTokens`, so
/// `authStateNotifier.value` stays `false` on a warm boot even when a valid
/// session exists. Reading `SessionBloc.state.status` is the single source of
/// truth that reflects the real, resolved session.
///
/// ## Shell and pages (P0-5)
///
/// The five main tabs (`/`, `/service`, `/history`, `/wallet`, `/account`) are
/// children of a [ShellRoute] that wraps them in `AppShell` — brand bar,
/// language toggle, five-destination bottom nav. Every other route (`/signin`,
/// `/help`, `/news`, `/debug`) is mounted *outside* the shell and therefore
/// renders full-frame with no bottom bar. That structural split is the port of
/// the React `MAIN_TABS` + `translate-y-full` trick: membership in the shell
/// replaces the visibility flag, so a new sub-route cannot forget to hide the
/// bar. See `lib/presentation/shell/app_shell.dart` for the full rationale.
///
/// `/signin` now serves the real `AuthPage` (defect F-3 closed). `/help` and
/// `/news` still serve [_PlaceholderPage]; they are later batches.
///
/// ## Dependency acquisition (CR-1, SSD § 6.4)
///
/// This file is one of exactly two places allowed to read the global service
/// locator — the other is `main.dart`. The SSD's seam is:
///
/// > Route builders and `main.dart` may resolve from a locator. No widget may.
///
/// Route builders are composition-root code: they run once per navigation,
/// they are already the place where a route's shape is decided, and they are
/// not part of anybody's widget tree in a test. So the two dependencies that
/// used to be pulled out of a container from *inside* a widget are pulled out
/// here instead and handed down as constructor arguments / providers:
///
/// - `injection<StorageService>()` → [AppShell] → `AppTopBar` →
///   `LanguageToggle` (was `storage ?? injection<StorageService>()` inside the
///   toggle's tap handler).
/// - `authInjection<AuthBloc>()` → a `BlocProvider<AuthBloc>` above `AuthPage`
///   (was `authInjection<AuthBloc>()` in `AuthPage.initState`).
///
/// Every page added from here on acquires its BLoC the same way, in this
/// table. `G-L5` in `test/architecture/layering_test.dart` is what keeps that
/// true: it fails the build if any file under a `presentation/` directory
/// names `injection` / `authInjection` / `sessionInjection` or imports a
/// `**/di/**` path.
///
/// ## Debug HTTP inspector
///
/// In debug builds the `navigatorKey` is [ChuckerFlutter.navigatorKey] so
/// Chucker's overlay can draw over the router's navigator (boilerplate
/// parity). Release builds use a plain `GlobalKey<NavigatorState>`.
library;

import 'dart:async';

import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/dependency_injection.dart';
import '../../core/session/bloc/session_bloc.dart';
import '../../core/storage/storage_service.dart';
import '../../features/account/presentation/pages/account_page.dart';
import '../../features/auth/di/auth_injection.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/service/presentation/pages/service_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../../presentation/shell/app_shell.dart';
import 'app_name_routes.dart';
import 'route_names.dart';

class AppRoutes {
  AppRoutes._();

  // ── Protected paths (port of `PROTECTED_TABS`) ──────────────────────────
  /// Paths that require an authenticated session. Port of the React
  /// `PROTECTED_TABS` Set. For P0-3 only `history` and `account` are wired;
  /// the certificate sub-routes (`resident-certificate`, `birth-declaration`,
  /// ...) land in the next P0 stage and will be added here then.
  static const Set<String> _protectedPaths = <String>{
    AppNameRoutes.history,
    AppNameRoutes.account,
  };

  // ── Query-param key for the post-sign-in destination ────────────────────
  /// The `from` query param on `/signin` carries the path the citizen
  /// originally requested before the auth gate sent them to sign in. Mirrors
  /// the `pendingTab` ref + `handleAuthSuccess`'s `pendingRef.current ??
  /// "account"` default.
  ///
  /// ## Encode / decode pairing (verified, not assumed)
  ///
  /// [_redirect] writes it with `Uri.encodeComponent(location)`, so `/account`
  /// is emitted as `/signin?from=%2Faccount`. The read side is the `/signin`
  /// route builder below, which takes `state.uri.queryParameters[...]`;
  /// `Uri.queryParameters` percent-**decodes** its values, handing back
  /// `/account`. One encode, one decode — no double-escape, and no manual
  /// `Uri.decodeComponent` on the read side (which would be the bug: it would
  /// decode a second time and mangle any path containing a literal `%`).
  ///
  /// This key is deliberately consumed *only* here. `AuthPage` is handed the
  /// already-decoded value as a constructor argument instead of reaching for
  /// `GoRouterState.of(context)` itself: the router owns the wire format, the
  /// page owns what to do with the destination. That also keeps the feature
  /// layer from importing this router class, which is a layering inversion.
  static const String kFromQueryParam = 'from';

  // ── Router ──────────────────────────────────────────────────────────────
  // P0-2 registered `SessionBloc` as a `registerFactory` on the feature-scoped
  // `sessionInjection` (`GetIt.asNewInstance()`). That is correct for a BLoC
  // scoped to a feature subtree, but a whole-app router must hold a STABLE
  // singleton instance — otherwise the router's refresh stream would listen to
  // a BLoC nobody else populates, and `state.status` would always read
  // `initial`.
  //
  // RESOLVED in P0-5 (defect F-2): the registration is now
  // `registerLazySingleton<SessionBloc>` (see
  // `features/session/di/session_feature_injection.dart`), and `main.dart`
  // resolves it once and hands the same reference to both [build] and the
  // `BlocProvider<SessionBloc>.value` above `MaterialApp.router`. The
  // parameter below stays — it is what makes the router testable without a
  // container — but it is no longer the only thing keeping the instance
  // single.

  /// Builds the configured [GoRouter] against the given [sessionBloc].
  ///
  /// The router holds the supplied instance for its whole lifetime and wires
  /// its `refreshListenable` to the BLoC's state `stream`, so the auth gate
  /// re-evaluates the moment `loading → authenticated` (boot) or
  /// `authenticated → unauthenticated` (sign-out) lands. Call once from
  /// `main.dart` (P0-5) with the app-wide `SessionBloc` singleton.
  static GoRouter build(SessionBloc sessionBloc) {
    return GoRouter(
      navigatorKey:
          kDebugMode ? ChuckerFlutter.navigatorKey : GlobalKey<NavigatorState>(),
      initialLocation: AppNameRoutes.home,
      refreshListenable: _GoRouterRefreshStream(sessionBloc.stream),
      redirect: (context, state) => _redirect(sessionBloc, state),
      routes: _buildRoutes(),
    );
  }

  // ── Redirect (port of `handleTabChange` + `handleAuthSuccess`) ───────────
  static String? _redirect(SessionBloc sessionBloc, GoRouterState state) {
    final status = sessionBloc.state.status;
    final location = state.matchedLocation;

    // Boot hold: while the session is unresolved, do not redirect — a warm
    // boot with a stored token must not flash the signed-out shell. Port of
    // `if (bootPhase === "loading" || session.loading)`.
    if (status == SessionStatus.initial ||
        status == SessionStatus.loading) {
      return null;
    }

    final isAuthenticated = status == SessionStatus.authenticated;

    // Protected path + unauthenticated → sign in, remembering the intent.
    // Port of `requireAuth(intended)` + `navigateTo("auth")`.
    final isProtected = _protectedPaths.any(
      (p) => location == p || location.startsWith('$p/'),
    );
    if (!isAuthenticated && isProtected) {
      final from = Uri.encodeComponent(location);
      return '${AppNameRoutes.signin}?$kFromQueryParam=$from';
    }

    // Already authenticated and on /signin → go to the `from` intent, or home.
    // Port of `handleAuthSuccess` (`pendingRef.current ?? "account"` → here
    // `?? "/"` because the default-destination logic lives in AuthPage P0-6,
    // which reads the same `from` param; with no `from`, home is the safe
    // default and matches the React `navigateTo("home")` fallback).
    if (isAuthenticated && location == AppNameRoutes.signin) {
      final from = state.uri.queryParameters[kFromQueryParam];
      return (from != null && from.isNotEmpty) ? from : AppNameRoutes.home;
    }

    return null;
  }

  // ── Routes ───────────────────────────────────────────────────────────────
  /// Builds a fresh route table.
  ///
  /// A *method*, not the `static final` list P0-3 used, because the
  /// [ShellRoute] added here owns an implicit `GlobalKey<NavigatorState>` for
  /// its inner navigator. A shared list would hand the same key to every
  /// router [build] produces, and two live routers (two widget tests in one
  /// process, or a hot restart) would then mount the same `GlobalKey` twice.
  /// Rebuilding the table per router keeps each one's keys its own. Route
  /// paths, names and order are unchanged from P0-3.
  static List<RouteBase> _buildRoutes() => <RouteBase>[
    // ── Main tabs: wrapped in the app shell (port of `MAIN_TABS`) ──────────
    ShellRoute(
      // CR-1: the shell's `StorageService` is resolved *here*, in the route
      // builder, not inside `LanguageToggle`. Resolved per build rather than
      // hoisted to a field because `injection` is a lazy singleton — every
      // call returns the same instance — and hoisting would make the route
      // table capture a container reading taken before `resetHarness()` runs
      // between two tests.
      builder: (BuildContext context, GoRouterState state, Widget child) =>
          AppShell(
        location: state.matchedLocation,
        storage: injection<StorageService>(),
        child: child,
      ),
      routes: <RouteBase>[
        GoRoute(
          path: AppNameRoutes.home,
          name: RouteNames.home,
          builder: (_, __) => const HomePage(),
        ),
        GoRoute(
          path: AppNameRoutes.service,
          name: RouteNames.service,
          builder: (_, __) => const ServicePage(),
        ),
        GoRoute(
          path: AppNameRoutes.history,
          name: RouteNames.history,
          builder: (_, __) => const HistoryPage(),
        ),
        GoRoute(
          path: AppNameRoutes.wallet,
          name: RouteNames.wallet,
          builder: (_, __) => const WalletPage(),
        ),
        GoRoute(
          path: AppNameRoutes.account,
          name: RouteNames.account,
          builder: (_, __) => const AccountPage(),
        ),
      ],
    ),

    // ── Full-frame routes: outside the shell, so no bottom nav ─────────────
    // `/signin` is a child of no `ShellRoute` on purpose: that is what hides
    // the bottom bar on the auth screen. It is a structural property of the
    // route table, not a flag `AppShell` has to be told about, so a future
    // sub-route cannot forget to hide the bar. Do not move this inside the
    // shell.
    GoRoute(
      path: AppNameRoutes.signin,
      name: RouteNames.signin,
      // `state.uri.queryParameters` returns the percent-DECODED value, so
      // `AuthPage` receives `/account`, not `%2Faccount`. See the
      // [kFromQueryParam] note for the full encode/decode pairing.
      //
      // CR-1: the `AuthBloc` is created here, by the route builder, and owned
      // by this `BlocProvider`. `create:` (not `.value`) is deliberate and is
      // the half that carries the lifetime contract — `BlocProvider(create:)`
      // closes the BLoC it created when the provider leaves the tree, which is
      // exactly the teardown `AuthPage.dispose()` used to perform by hand.
      // `AuthPage` no longer creates it, so `AuthPage` no longer closes it:
      // one creator, one closer, still exactly one `close()` per visit to
      // `/signin`. That per-visit lifetime is required, not incidental — an
      // auth attempt holds a half-typed password and an unverified OTP
      // challenge, and a surviving BLoC would replay a stale
      // `AuthStatus.success` into the next mount's `BlocListener`.
      //
      // `authInjection` registers `AuthBloc` with `registerFactory`, so each
      // resolution is a fresh instance — which is what makes owning-and-
      // closing it correct here, and is the same pairing the page had before.
      builder: (_, GoRouterState state) => BlocProvider<AuthBloc>(
        create: (_) => authInjection<AuthBloc>(),
        child: AuthPage(from: state.uri.queryParameters[kFromQueryParam]),
      ),
    ),
    GoRoute(
      path: AppNameRoutes.help,
      name: RouteNames.help,
      builder: (_, __) => const _PlaceholderPage(title: 'Help'),
    ),
    GoRoute(
      path: AppNameRoutes.news,
      name: RouteNames.news,
      builder: (_, __) => const _PlaceholderPage(title: 'News'),
    ),
    if (kDebugMode)
      GoRoute(
        path: AppNameRoutes.debug,
        name: RouteNames.debug,
        builder: (_, __) => const _PlaceholderPage(title: 'Debug'),
      ),
  ];
}

// ── Refresh adapter: Bloc stream → Listenable ──────────────────────────────
/// Bridges a `Bloc` state `Stream` to the `Listenable` that `go_router`'s
/// `refreshListenable` expects.
///
/// `go_router`'s own examples shipped a `GoRouterRefreshStream` for this
/// exact `flutter_bloc` integration; it was removed from the package in a
/// later release, but the pattern is trivially reimplementable. On every
/// stream emission this calls `notifyListeners()`, which makes the router
/// re-run `redirect` — so the auth gate re-evaluates the moment the session
/// BLoC transitions `loading → authenticated` (boot) or
/// `authenticated → unauthenticated` (sign-out).
///
/// `dispose()` removes the stream subscription; call it when the router is
/// torn down (typically never, since the router lives for the app's
/// lifetime, but it keeps the analyzer honest about resource ownership).
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen(
      (_) => notifyListeners(),
      onError: (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// ── Placeholder page (still used by the not-yet-built routes) ──────────────
/// Inline placeholder. P0-5 replaced it on the five main tabs with the real
/// shell + per-tab pages, and the auth-wiring dispatch replaced it on
/// `/signin` with the real `AuthPage`. It survives for `/help`, `/news` and
/// `/debug`, which keep the router navigable end-to-end until their own
/// batches land.
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title — placeholder (P0-5 wires the real page)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

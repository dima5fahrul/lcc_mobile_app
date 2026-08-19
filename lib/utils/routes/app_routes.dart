/// Auth-aware `GoRouter` for the LCC citizen portal.
///
/// Ports `lcc-app/src/app/App.tsx`'s auth gate (`PROTECTED_TABS`,
/// `handleTabChange`, `handleAuthSuccess`) and the hash-based routing in
/// `lcc-app/src/app/routes.ts` onto `go_router`.
///
/// ## What was ported
///
/// - `PROTECTED_TABS` → [AppRoutes._protectedPaths] — **all eight members**:
///   `/history`, `/account`, and B12's six certificate sub-routes. The source's
///   `PROTECTED_TABS` (`App.tsx:29-38`) holds exactly those eight tabs, so the
///   two sets are the same set. `/service` is deliberately **not** among them.
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
/// `/help`, `/news`, `/debug`, and **B12's six certificate sub-routes**) is
/// mounted *outside* the shell and therefore renders full-frame with no bottom
/// bar. That structural split is the port of the React `MAIN_TABS` +
/// `translate-y-full` trick: membership in the shell replaces the visibility
/// flag, so a new sub-route cannot forget to hide the bar. See
/// `lib/presentation/shell/app_shell.dart` for the full rationale.
///
/// The five main tabs are exactly `MAIN_TABS` (`Layout.tsx:46-52`), and the six
/// certificate tabs are exactly the ones it omits — so `isSubPage` (`:300`) and
/// "is not a child of the shell" are the same predicate, computed once by the
/// table's shape rather than by a flag any route could forget to set.
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
///
/// ## N-4 — `route_names.dart` is gone (SSD § 9.2)
///
/// `RouteNames` mirrored [AppNameRoutes] constant-for-constant, and its own doc
/// admitted the hazard: *"every constant here MUST equal its `AppNameRoutes`
/// twin"*, enforced by a test rather than by the type system. All seven uses
/// were `name:` arguments in this file and nothing ever called `goNamed`, so
/// the second surface bought nothing and could drift. Every `GoRoute.name` now
/// takes the [AppNameRoutes] path constant directly, which is what `RouteNames`
/// resolved to anyway — the route *names* are byte-identical to before.
library;

import 'dart:async';

import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/dependency_injection.dart';
import '../../core/session/bloc/session_bloc.dart';
import '../../core/storage/storage_service.dart';
import '../../features/account/di/account_injection.dart';
import '../../features/account/presentation/bloc/account_documents_bloc.dart';
import '../../features/account/presentation/bloc/account_preferences_bloc.dart';
import '../../features/account/presentation/bloc/account_profile_bloc.dart';
import '../../features/account/presentation/pages/account_page.dart';
import '../../features/application/domain/entities/application_detail.dart';
import '../../features/auth/di/auth_injection.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
// B12 — one container, six pages, five cubits. This is the only file in the
// tree allowed to name all five certificate page directories at once:
// `certificate_page_isolation_guard_test.dart` forbids the edge only *between*
// files under `features/certificates/presentation/`, and route composition is
// what this file is for.
import '../../features/certificates/di/certificates_injection.dart';
import '../../features/certificates/presentation/birth/birth_certificate_page.dart';
import '../../features/certificates/presentation/birth/birth_form_cubit.dart';
import '../../features/certificates/presentation/death/death_certificate_page.dart';
import '../../features/certificates/presentation/death/death_form_cubit.dart';
import '../../features/certificates/presentation/divorce/divorce_certificate_page.dart';
import '../../features/certificates/presentation/divorce/divorce_form_cubit.dart';
import '../../features/certificates/presentation/marriage/marriage_certificate_page.dart';
import '../../features/certificates/presentation/marriage/marriage_form_cubit.dart';
import '../../features/certificates/presentation/resident/resident_certificate_page.dart';
import '../../features/certificates/presentation/resident/resident_form_cubit.dart';
import '../../features/chat/di/chat_injection.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/chat/presentation/widgets/chat_launcher.dart';
import '../../features/documents/domain/entities/issued_certificate.dart';
// B12 — F4's page, its cubit, and the two chrome widgets RULING 6's hold frame
// reuses so the boot window renders the page's own loading state rather than
// something invented for it.
import '../../features/family_book/di/family_book_injection.dart';
import '../../features/family_book/presentation/bloc/family_book_cubit.dart';
import '../../features/family_book/presentation/pages/family_book_page.dart';
import '../../features/family_book/presentation/widgets/family_book_chrome.dart';
import '../../features/family_book/presentation/widgets/family_book_states.dart';
import '../../features/help/di/help_injection.dart';
import '../../features/help/presentation/bloc/help_bloc.dart';
import '../../features/help/presentation/pages/help_page.dart';
import '../../features/history/di/history_injection.dart';
import '../../features/history/presentation/bloc/history_bloc.dart';
import '../../features/history/presentation/bloc/history_detail_bloc.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/home/di/home_injection.dart';
// B12 — the app's shared money formatter, the one `wallet_formatting.dart`,
// `application_formatting.dart` and `family_book_derivations.dart` all import.
// Marriage and Divorce take it as a parameter so their pages carry no
// formatting policy; this is where it is bound to the build's locale.
import '../../features/home/domain/home_formatting.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/widgets/lao_id_card.dart';
import '../../features/home/presentation/widgets/tier_a_image.dart';
import '../../features/news/di/news_injection.dart';
import '../../features/news/presentation/bloc/news_bloc.dart';
import '../../features/news/presentation/bloc/news_detail_bloc.dart';
import '../../features/news/presentation/pages/news_detail_page.dart';
import '../../features/news/presentation/pages/news_page.dart';
import '../../features/notifications/di/notifications_injection.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../../features/notifications/presentation/widgets/notification_bell.dart';
import '../../features/service/di/service_injection.dart';
import '../../features/service/presentation/bloc/service_bloc.dart';
import '../../features/service/presentation/pages/service_page.dart';
import '../../features/wallet/di/wallet_injection.dart';
import '../../features/wallet/presentation/bloc/wallet_bloc.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../../i18n/i18n.dart';
import '../../presentation/boot/splash_slide_visual.dart';
import '../../presentation/documents/document_actions_row.dart';
import '../../presentation/documents/document_viewer.dart' show kDocumentsNs;
import '../../presentation/documents/issued_certificate_card.dart';
import '../../presentation/shell/app_shell.dart';
import 'app_name_routes.dart';

class AppRoutes {
  AppRoutes._();

  // ── Protected paths (port of `PROTECTED_TABS`) ──────────────────────────
  /// Paths that require an authenticated session. Port of the React
  /// `PROTECTED_TABS` Set (`App.tsx:29-38`), which holds **eight** tabs:
  /// `history`, `account` and all six certificate tabs. B12 added the six.
  ///
  /// ## `/service` is NOT here, and that is load-bearing
  ///
  /// The predicate below is `location == p || location.startsWith('$p/')`. The
  /// second branch means adding `/service` would gate the whole catalogue **and
  /// all six certificate children in one line** — turning the one
  /// certificate-adjacent surface with a real Tier 3 baseline (slot `02-service`)
  /// into a redirect, and doing it invisibly, because every criterion about the
  /// six would still pass while a signed-out citizen lost the catalogue.
  /// `/service` is absent from `PROTECTED_TABS` in the source for the same
  /// reason. `B12-AC-23` is the negative control that fails if it ever appears.
  ///
  /// The six are matched on the `==` branch, not the `startsWith` one: each is a
  /// full literal path, so no prefix reasoning is involved in gating them.
  static const Set<String> _protectedPaths = <String>{
    AppNameRoutes.history,
    AppNameRoutes.account,
    // B12 — the six, in `routes.ts:21-26` order.
    AppNameRoutes.residentCertificate,
    AppNameRoutes.birthDeclaration,
    AppNameRoutes.deathDeclaration,
    AppNameRoutes.marriageCertificate,
    AppNameRoutes.divorceCertificate,
    AppNameRoutes.familyBook,
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

  // ── B10 — the splash composition slots (§ 6.9) ───────────────────────────
  //
  // **No new `GoRoute`.** The boot phases are not routes: `App.tsx`:195-222 is
  // a three-phase state machine whose phases have no hash and are not
  // addressable, so making them routes would invent deep-linkable surfaces the
  // source lacks *and* need a redirect guard to stop `/onboarding` being
  // reachable after first run (§ 6.8). `main.dart` mounts them directly.
  //
  // What lands here instead is the **composition**. `lib/presentation/boot/`
  // may not name `LaoIdCard` (G-L7) or `hero-bg.webp` (the Tier A guard), and
  // this file may name both: it is not under `lib/presentation/**`, and it is
  // already the sanctioned place to assemble a feature widget for the shell
  // (`ShellRoute`'s `topBarActions` / `floatingAction`, B9a's seam). G-L7
  // therefore stays green with a **third** proven consumer.

  /// Splash slide 3's card — `SplashScreens.tsx`:157
  /// `<LaoIdCard authenticated interactive={false} name={t("idHolderValue")} />`.
  ///
  /// `name` is read here rather than inside the splash because it is the one
  /// argument the source computes at the call site. `context:` is passed for
  /// the same reason every other B10 `.tr()` does — see G-L8.
  static Widget splashSlide3Visual(BuildContext context) => LaoIdCard(
        authenticated: true,
        interactive: false,
        name: 'onboarding.idHolderValue'.tr(context: context),
      );

  /// The shared splash backdrop — `SplashScreens.tsx`:263-268's `<img>`.
  ///
  /// A [SplashBackdropBuilder] rather than a widget: `TierAImage` needs the
  /// logical paint width to size its decode (B2-AC-31), and that is only known
  /// inside the splash's own layout.
  static Widget splashBackdrop(Alignment alignment, double paintWidth) =>
      TierAImage(
        asset: kHeroBackdrop,
        paintWidth: paintWidth,
        alignment: alignment,
      );

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
      //
      // ── B9a: the composition seam (specs.md § 6.4) ────────────────────────
      //
      // `topBarActions` is where the notification bell is assembled. This
      // builder is the ONLY place in the tree that names both
      // `NotificationsBloc` and `NotificationBell`, and it is allowed to
      // because it is a route builder: CR-1's seam is "route builders and
      // `main.dart` may resolve from a locator; no widget may", and this file
      // is not under `lib/presentation/**`.
      //
      // The point of doing it here rather than inside `AppTopBar` is that
      // `ssd.md`:255 forbids `lib/presentation/** -> features/*/presentation/**`
      // and the bar would need the BLoC *type* to provide it. **G-L7**
      // (`test/architecture/layering_rules.dart`) fails the build if that edge
      // ever appears; it is proved to fire against a planted fixture in
      // `guard_selftest_test.dart`, so it is a guard rather than a comment.
      //
      // `create:` and not `.value`: `notificationsInjection` registers
      // `NotificationsBloc` with `registerFactory`, so each shell build gets a
      // fresh one and the provider closes it on the way out. Required rather
      // than incidental — the BLoC holds one citizen's unread count and their
      // own notices, and a surviving instance would carry both across a
      // sign-out.
      //
      // **No `..add(...)` mount fetch here**, and the asymmetry with `/` and
      // `/service` below is deliberate. Both of the bell's reads are
      // `enabled: isAuthenticated` (`Layout.tsx:115,119`), so there is nothing
      // to fetch until the session resolves; `NotificationBell` dispatches
      // `NotificationsAuthChanged` from `initState` and from a `SessionBloc`
      // listener. Dispatching a start event here would either fire a request
      // for a signed-out citizen or force this builder to read a second BLoC.
      //
      // ── B9b: the second consumer of the same seam ────────────────────────
      //
      // `floatingAction` is the slot B9a added and left null. The chat launcher
      // fills it, assembled here for exactly the reasons the bell is: this
      // builder is the only place in the tree that names both `ChatBloc` and
      // `ChatLauncher`, and it is allowed to because it is a route builder.
      // `AppShell` still names neither, so **G-L7 stays green with two
      // consumers rather than one** — which is what turns B9a's seam from a
      // signature into a proven mechanism (§ 8.1(2)).
      //
      // **`floatingActionButtonLocation` is not set**, and that is the port:
      // the default `endFloat` is bottom-right above the bottom bar, which is
      // `fixed bottom-24 right-4` (`CustomerServiceChat.tsx:549`). The
      // launcher's "main tabs only" rule needs no flag either — a sub-page is
      // mounted outside this `ShellRoute` and simply never builds it
      // (`Layout.tsx:385`, specs.md § 6.3, B9-AC-41).
      //
      // `create:` and not `.value`: `chatInjection` registers `ChatBloc` with
      // `registerFactory`, so each shell build gets a fresh one and the
      // provider **closes** it on the way out. Required rather than incidental
      // twice over — the BLoC holds one citizen's transcript and composer text,
      // and `close()` is what cancels the 4,000 ms poll timer (§ 6.9(1)).
      //
      // **No `..add(...)` mount fetch**, the same asymmetry the bell has: every
      // chat read is gated on `isAuthenticated` and on the panel being open
      // (`:48`, `:56`, `:84`), so there is nothing to fetch until both resolve.
      // `ChatLauncher` dispatches `ChatAuthChanged` from `initState` and from a
      // `SessionBloc` listener.
      builder: (BuildContext context, GoRouterState state, Widget child) =>
          AppShell(
        location: state.matchedLocation,
        storage: injection<StorageService>(),
        topBarActions: <Widget>[
          BlocProvider<NotificationsBloc>(
            create: (_) => notificationsInjection<NotificationsBloc>(),
            child: const NotificationBell(),
          ),
        ],
        floatingAction: BlocProvider<ChatBloc>(
          create: (_) => chatInjection<ChatBloc>(),
          child: const ChatLauncher(),
        ),
        child: child,
      ),
      routes: <RouteBase>[
        // B2b. Same CR-1 pattern as `/service` below: the BLoC is resolved
        // HERE, by the route builder, and owned by this `BlocProvider`.
        // `create:` (not `.value`) carries the lifetime — `homeInjection`
        // registers `HomeBloc` with `registerFactory`, so each visit gets a
        // fresh one and the provider closes it on the way out. Required rather
        // than incidental on this page: the BLoC holds a live debounce `Timer`
        // *and* the citizen's summary and digital-ID data, and a surviving
        // instance would carry one citizen's UIN across a sign-out.
        //
        // `..add(const HomeStarted())` is the mount fetch — the three
        // anonymous `useQuery` calls `HomePage.tsx:171-178` fires on render.
        // The two authenticated ones are not dispatched here: they are
        // `enabled: isAuthenticated`, which re-evaluates when the flag
        // changes, so `HomePage`'s `BlocListener<SessionBloc>` owns them. That
        // keeps this builder from having to read a second BLoC and keeps
        // "signing in mid-visit fills the tiles" working.
        GoRoute(
          path: AppNameRoutes.home,
          name: AppNameRoutes.home,
          builder: (_, __) => BlocProvider<HomeBloc>(
            create: (_) => homeInjection<HomeBloc>()..add(const HomeStarted()),
            // B10 § 6.10: the tutorial's `lcc.tutorial_seen` gate. Resolved
            // here for the same CR-1 reason the BLoC is — a route builder may
            // read the locator, the page may not.
            child: HomePage(storage: injection<StorageService>()),
          ),
        ),
        // CR-1 again, and this is the pattern every B2 page follows: the BLoC
        // is resolved HERE, by the route builder, and owned by this
        // `BlocProvider`. `create:` (not `.value`) carries the lifetime —
        // `serviceInjection` registers `ServiceBloc` with `registerFactory`, so
        // each visit gets a fresh one and the provider closes it on the way
        // out. That per-visit lifetime is required, not incidental: the BLoC
        // holds a live debounce `Timer` and one visit's search results, and a
        // surviving instance would hand the next visit both.
        //
        // `..add(const ServiceStarted())` is the mount fetch — the pair of
        // `useQuery` calls `ServicePage.tsx:298-299` fires on render. Doing it
        // in the builder rather than in `ServicePage.initState` keeps the page
        // a pure function of its BLoC, which is what lets a widget test pump
        // it against any state without a container.
        GoRoute(
          path: AppNameRoutes.service,
          name: AppNameRoutes.service,
          builder: (_, __) => BlocProvider<ServiceBloc>(
            create: (_) =>
                serviceInjection<ServiceBloc>()..add(const ServiceStarted()),
            child: const ServicePage(),
          ),
        ),
        // CR-1 again (B7a). The **existing** `/history` route, with its
        // builder wrapped — no new route, no `_protectedPaths` change, no
        // table reordering. specs.md § 6.6 rules the detail page *in-page
        // state, not a route*: the web swaps the body on `selectedId` and
        // never changes the URL, so a `/history/:id` here would make the
        // detail deep-linkable and back-stackable when the source's is
        // neither — a functional divergence invisible to every fidelity tier.
        //
        // `create:` (not `.value`) carries the lifetime, and
        // `historyInjection` registers `HistoryBloc` with `registerFactory`:
        // the BLoC holds a live 350 ms debounce `Timer` plus one visit's page,
        // filter and search term, and a surviving instance would hand the next
        // visit all four.
        //
        // `..add(const HistoryStarted())` is the mount fetch — the three hooks
        // `HistoryPage.tsx:68`, `:83` and `:99` fire on render. Doing it here
        // rather than in `HistoryPage.initState` keeps the page a pure
        // function of its BLoC, which is what lets a widget test pump it
        // against any state without a container.
        GoRoute(
          path: AppNameRoutes.history,
          name: AppNameRoutes.history,
          // `detailBlocFactory` is B7b, and it is here for **G-L5**: the detail
          // is in-page state, so `HistoryPage` needs a `HistoryDetailBloc` — but
          // a `presentation/` file may not resolve one from a global locator,
          // and `history_page.dart` importing `history_injection.dart` fails
          // that guard (measured). Resolution happens here instead, where every
          // other BLoC in the app is resolved, and the page receives a plain
          // factory it can call without knowing a container exists.
          //
          // A **factory**, not an instance: `registerFactory` means each call
          // yields a fresh BLoC, and the detail carries the open case's id plus
          // two generation counters — one instance reused across two cases would
          // hand the second the first's in-flight answers.
          builder: (_, __) => BlocProvider<HistoryBloc>(
            create: (_) =>
                historyInjection<HistoryBloc>()..add(const HistoryStarted()),
            child: HistoryPage(
              detailBlocFactory: () => historyInjection<HistoryDetailBloc>(),
              // B5's two seams (specs.md § 6.7). Composed here for the same
              // reason `detailBlocFactory` is: this is the file whose whole job
              // is resolution, and it is the only one exempt from G-L5 by
              // construction. **No new `GoRoute`, no `_protectedPaths` entry,
              // no reordering** — B5 creates no route and no page
              // (`B5-AC-21`).
              //
              // They are **builders**, not widgets: both regions are functions
              // of the payload, which a pre-built `Widget?` cannot see
              // (specs.md Finding J). The six strings the card needs are
              // resolved here too, from the `context` this builder already has,
              // so `IssuedCertificateCard` stays pumpable without an
              // `EasyLocalization` ancestor.
              documentActions: (
                ApplicationDetail detail,
                IssuedCertificate? certificate,
              ) =>
                  DocumentActionsRow(
                detail: detail,
                certificate: certificate,
              ),
              certificatePanel: (
                ApplicationDetail detail,
                IssuedCertificate? certificate,
                bool certificateLoading,
              ) =>
                  Builder(
                builder: (BuildContext cardContext) => IssuedCertificateCard(
                  detail: detail,
                  certificate: certificate,
                  certificateLoading: certificateLoading,
                  lang: Lang.fromCode(cardContext.locale.languageCode),
                  headingLabel:
                      '$kDocumentsNs.issuedCertificate'.tr(context: cardContext),
                  certificateNumberLabel: '$kDocumentsNs.certificateNumber'
                      .tr(context: cardContext),
                  issuedOnLabel:
                      '$kDocumentsNs.issuedOn'.tr(context: cardContext),
                  verificationCodeLabel: '$kDocumentsNs.verificationCode'
                      .tr(context: cardContext),
                  qrPayloadLabel:
                      '$kDocumentsNs.qrPayload'.tr(context: cardContext),
                  notAvailableLabel: '$kDocumentsNs.certificateNotAvailable'
                      .tr(context: cardContext),
                ),
              ),
            ),
          ),
        ),
        // CR-1 again (B6a). The **existing** `/wallet` route, builder wrapped.
        // No new `GoRoute`, no `_protectedPaths` change, no reordering
        // (specs.md § 3.1, § 2.2 M) — `/wallet` is a public tab whose *body*
        // branches on `isAuthenticated`, not a gated route, and moving it into
        // `_protectedPaths` would replace the signed-out wallet (the one
        // surface B6a has a Tier 3 reference for, § 2.2 L) with a redirect.
        //
        // `create:` (not `.value`): `walletInjection` registers `WalletBloc`
        // with `registerFactory`, and the instance holds one visit's balance,
        // account number, receipts page and ledger page. A survivor hands all
        // four to whoever signs in next on this device.
        //
        // `..add(const WalletStarted())` dispatches a mount event that
        // **fetches nothing** — all four page queries are
        // `enabled: isAuthenticated` (`WalletPage.tsx:101,105,113,119`) and the
        // flag arrives later as `WalletAuthChanged` from the page's
        // `BlocListener<SessionBloc>`. `B6-AC-25` asserts a mount issues zero
        // requests. It is dispatched anyway because the shape must match
        // `/`, `/service` and `/history` above; see `WalletStarted`'s own
        // doc comment for why the event exists rather than being dropped.
        GoRoute(
          path: AppNameRoutes.wallet,
          name: AppNameRoutes.wallet,
          builder: (_, __) => BlocProvider<WalletBloc>(
            create: (_) =>
                walletInjection<WalletBloc>()..add(const WalletStarted()),
            child: const WalletPage(),
          ),
        ),
        // ── B8a ────────────────────────────────────────────────────────────
        //
        // The three BLoCs `AccountPage` needs are created **HERE**, by the
        // route builder, and owned by these providers. `create:` and not
        // `.value`: `accountInjection` registers all three with
        // `registerFactory`, so each visit gets fresh instances and the
        // providers close them on the way out — each holds one citizen's
        // profile buffer, preference switches and document wallet, and a
        // survivor would hand them to whoever signs in next on this device.
        //
        // **Three, not one** (specs.md § 6.3): the source runs three
        // independent `useQuery` calls (`AccountPage.tsx:189-191`) whose
        // loading and error states render in three different places.
        //
        // **No `..add(...)` mount fetch here.** Unlike `/service` and `/`, the
        // three requests are dispatched from `AccountPage.initState`, because
        // all three are `useQuery(..., [])` — one fetch per *mount of the
        // page*, not per creation of the BLoC, and the two differ if the
        // provider is ever hoisted.
        //
        // ── Recorded deviation from B8-AC-9 ────────────────────────────────
        //
        // specs.md § 3.1 and B8-AC-9 require `app_routes.dart` to be
        // unmodified, on the ground (§ 2.2 Finding I) that `/account` is
        // already routed and the page has no sub-routes. **That ground is
        // correct and it is not the whole requirement**: the page needs its
        // BLoCs provided, and G-L5 forbids any widget under `presentation/`
        // from resolving a locator, so a route builder is the only sanctioned
        // seam (`ssd.md` § 6.4). The spec's Finding I did not consider BLoC
        // provisioning.
        //
        // The change is confined to this one `GoRoute` and is additive.
        // `app_shell.dart` and `app_top_bar.dart` — the files § 6.4's design
        // exists to keep out of B8 because B10's D-3 must edit them — remain
        // **untouched**, which is the half of B8-AC-9 that carries the
        // cross-batch risk. Reported in the hand-back.
        GoRoute(
          path: AppNameRoutes.account,
          name: AppNameRoutes.account,
          builder: (_, __) => MultiBlocProvider(
            providers: <BlocProvider<StateStreamableSource<Object?>>>[
              BlocProvider<AccountProfileBloc>(
                create: (_) => accountInjection<AccountProfileBloc>(),
              ),
              BlocProvider<AccountDocumentsBloc>(
                create: (_) => accountInjection<AccountDocumentsBloc>(),
              ),
              BlocProvider<AccountPreferencesBloc>(
                create: (_) => accountInjection<AccountPreferencesBloc>(),
              ),
            ],
            child: const AccountPage(),
          ),
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
      name: AppNameRoutes.signin,
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
    // B2c. Same CR-1 pattern as `/service` and `/`: the BLoC is resolved HERE
    // and owned by this `BlocProvider`. `create:` carries the lifetime —
    // `helpInjection` registers `HelpBloc` with `registerFactory`, so each
    // visit gets a fresh one and the provider closes it on the way out. That
    // per-visit lifetime is required, not incidental: the BLoC holds a live
    // debounce `Timer`, one visit's search term and page, and which question
    // and guide are expanded.
    GoRoute(
      path: AppNameRoutes.help,
      name: AppNameRoutes.help,
      builder: (_, __) => BlocProvider<HelpBloc>(
        create: (_) => helpInjection<HelpBloc>()..add(const HelpStarted()),
        child: const HelpPage(),
      ),
    ),
    GoRoute(
      path: AppNameRoutes.news,
      name: AppNameRoutes.news,
      builder: (_, __) => BlocProvider<NewsBloc>(
        create: (_) => newsInjection<NewsBloc>()..add(const NewsStarted()),
        child: const NewsPage(),
      ),
      // ── The first parameterised route in this table (B2c) ─────────────────
      //
      // A CHILD of `/news`, not a sibling: `go_router` matches children
      // relative to the parent, so `path: ':slug'` is `/news/:slug`, and the
      // back-navigation stack the detail page's "Back to news" relies on has
      // `/news` beneath it by construction rather than by convention.
      //
      // `NewsDetailBloc` needs the slug at construction, which is why
      // `news_feature_injection.dart` registers it with `registerFactoryParam`
      // rather than `registerFactory`. The parameter is read from
      // `GoRouterState` **here**, in the builder — SSD § 6.4's seam holds
      // exactly as it does for every other page: the builder resolves and
      // provides, and no widget touches a locator (G-L5, which is proven to
      // fire).
      //
      // `state.pathParameters` returns the percent-DECODED segment, and
      // `ApiEndpoint.newsArticle` re-encodes it for the wire. One decode, one
      // encode — the same pairing `kFromQueryParam` documents above, and the
      // reason a slug containing a literal `%` survives the round trip.
      routes: <RouteBase>[
        GoRoute(
          path: ':slug',
          // `name:` is the full path, matching every other route in this
          // table's `AppNameRoutes` convention (N-4).
          name: AppNameRoutes.newsDetail,
          builder: (_, GoRouterState state) => BlocProvider<NewsDetailBloc>(
            create: (_) => newsInjection<NewsDetailBloc>(
              param1: state.pathParameters['slug'] ?? '',
            )..add(const NewsDetailStarted()),
            child: const NewsDetailPage(),
          ),
        ),
      ],
    ),
    // ══ B12 — the six certificate sub-routes ═══════════════════════════════
    //
    // Six landed pages that no citizen could open. F1's Resident, F2's Birth
    // and Death, F3's Marriage and Divorce, F4's FamilyBook: all green under
    // their own widget tests, none reachable, because `app_routes.dart`
    // appeared in no batch's scope table and F4's `blocked.md` B-1 declined to
    // take it on the correct ground that *"a route table edit changes what the
    // shipped app does."* This block is that edit.
    //
    // ── Why all six are TOP-LEVEL and not children of `/service` ────────────
    //
    // Two written commitments in this tree said the opposite —
    // `app_name_routes.dart`'s library doc and `service_page.dart:129-131` —
    // and both were measured wrong (B12 § 2.2 Finding D). `MAIN_TABS` is
    // `{home, service, history, wallet, account}` (`Layout.tsx:46-52`);
    // `isSubPage = !MAIN_TABS.has(activeTab)` (`:300`); a sub-page renders the
    // bottom nav with `translate-y-full` and suppresses `<CustomerServiceChat/>`
    // (`:385-386`). None of the six certificate tabs is in `MAIN_TABS`, so the
    // source renders all six full-frame. A `GoRoute` child of
    // `AppNameRoutes.service` — itself a `ShellRoute` child — would inherit
    // `AppShell` and put a brand bar, a bottom nav and a chat FAB on every
    // frame of a seven-step form. These six join `/signin`, `/help` and `/news`
    // in the structure `:572-577` above already relies on.
    //
    // **A top-level `/service/x` really does match**, and it is not an accident
    // of ordering. go_router 16.3.0's `_matchByNavigatorKeyForGoRoute`
    // (`match.dart:207-281`) prefix-matches `/service` against
    // `/service/resident-certificate`, finds the matched location shorter than
    // the URI, descends into `route.routes` — empty for `/service` — and
    // returns `_empty` at `:275-278`: *"If not finding a sub route match, it is
    // considered not matched for this route even if this route match part of
    // the `remainingLocation`."* Matching then continues to these six.
    // Declaration order is therefore a readability choice, and the order below
    // is `routes.ts:21-26`'s so the two lists diff line for line.
    //
    // `parentNavigatorKey` was the considered alternative — it would keep the
    // path hierarchy and still escape the shell — and it is rejected because
    // `_buildRoutes()` is static with no access to the router's `navigatorKey`,
    // which is computed per-router inside [build] (`:218-219`). Threading it
    // here would break the very property `app_routes_test.dart`'s "two live
    // routers" case exists to protect, to buy a guarantee top-level routes give
    // for free.
    //
    // ── The lifetime contract, and why `create:` is not optional here ───────
    //
    // None of the six pages closes the cubit it is handed: Resident, Birth and
    // Death use `BlocConsumer(bloc: widget.cubit)`, Marriage and Divorce use
    // `BlocProvider.value` (which by contract does not close), and FamilyBook
    // uses `BlocBuilder(bloc: widget.cubit)`. **So this table is the only place
    // a `close()` can happen, and it must**: each cubit holds one citizen's
    // answers, a created draft `case id` and an `uploaded` slot set — the three
    // things `certificates_bloc_injection.dart:6-13` says a survivor would hand
    // to the next citizen. Every registration involved is a
    // `registerFactoryParam`, so `create:` yields a fresh instance per visit and
    // the provider closes it on the way out: exactly one construction and
    // exactly one `close()` per visit (`B12-AC-27`).
    //
    // The `Builder` beneath each provider exists only to read the instance back
    // for the page's `cubit:` argument. Resolving into a local and passing it to
    // both `create:` and the page would construct outside the provider's
    // ownership and break that contract.
    //
    // ── G-L5 is why any of this is here at all ─────────────────────────────
    //
    // `ssd.md`:853 — *"Route builders and `main.dart` may resolve from a
    // locator. No widget may."* Every one of the six pages carries the same
    // doc: *"Resolved by the route builder, never by a widget."* This is the
    // first code in the programme to perform that resolution — the DI container
    // has never been resolved in production
    // (`certificates_feature_injection.dart:21-22`), so a GetIt ordering fault
    // would surface here and nowhere earlier.

    // `/service/resident-certificate` — F1.
    //
    // **No `..load()`**: `resident_certificate_page.dart:100` calls it from
    // `initState`. Adding one here would fire every mount request twice.
    GoRoute(
      path: AppNameRoutes.residentCertificate,
      name: AppNameRoutes.residentCertificate,
      builder: (BuildContext context, GoRouterState state) =>
          BlocProvider<ResidentFormCubit>(
        create: (_) => certificatesInjection<ResidentFormCubit>(
          param1: _langOf(context),
        ),
        child: Builder(
          builder: (BuildContext inner) => ResidentCertificatePage(
            cubit: inner.read<ResidentFormCubit>(),
            onBack: () => inner.go(AppNameRoutes.home),
          ),
        ),
      ),
    ),

    // `/service/birth-declaration` — F2.
    //
    // **`param2` is the `legalBasisText` reader, and the namespace is `birth`.**
    // Getting it wrong is invisible in English: `en.birth.legalBasisText` and
    // `en.death.legalBasisText` are byte-identical and the **Lao strings are
    // not** (B12 § 2.1 item 8, F2's Finding B). A builder that passed `death`
    // here would ship a payload correct in English and wrong in Lao, so
    // `B12-AC-25` is written in Lao only and `B12-AC-36` records that the
    // English form of the same assertion passes against the defect.
    //
    // A **closure**, not a resolved `String`: the value is read at submit
    // (`birth_form_cubit.dart:667`), and `useT("birth")` is current at submit.
    // `context:` is bound because G-L8 fails the build on a bare `.tr()` and
    // the allowlist that would exempt one is shrink-only (`B10-AC-11`). The
    // captured context is this builder's, which lives exactly as long as the
    // provider that owns the cubit, so the closure and the cubit end together.
    //
    // It cannot be omitted: `param2` is typed non-nullable, so GetIt rejects a
    // resolve that omits it with an `ArgumentError` before the factory body
    // runs (`certificates_bloc_injection.dart:429-443`, `F2-AC-25`) — a
    // forgotten `param2` fails loudly at first navigation, not silently.
    GoRoute(
      path: AppNameRoutes.birthDeclaration,
      name: AppNameRoutes.birthDeclaration,
      builder: (BuildContext context, GoRouterState state) =>
          BlocProvider<BirthFormCubit>(
        create: (_) => certificatesInjection<BirthFormCubit>(
          param1: _langOf(context),
          param2: () => 'birth.legalBasisText'.tr(context: context),
        ),
        child: Builder(
          builder: (BuildContext inner) => BirthDeclarationPage(
            cubit: inner.read<BirthFormCubit>(),
            onBack: () => inner.go(AppNameRoutes.home),
          ),
        ),
      ),
    ),

    // `/service/death-declaration` — F2. The `death` namespace, and see the
    // Birth block above for why the two are not interchangeable.
    GoRoute(
      path: AppNameRoutes.deathDeclaration,
      name: AppNameRoutes.deathDeclaration,
      builder: (BuildContext context, GoRouterState state) =>
          BlocProvider<DeathFormCubit>(
        create: (_) => certificatesInjection<DeathFormCubit>(
          param1: _langOf(context),
          param2: () => 'death.legalBasisText'.tr(context: context),
        ),
        child: Builder(
          builder: (BuildContext inner) => DeathDeclarationPage(
            cubit: inner.read<DeathFormCubit>(),
            onBack: () => inner.go(AppNameRoutes.home),
          ),
        ),
      ),
    ),

    // `/service/marriage-certificate` — F3.
    //
    // ── `..load()` HERE, and this is the batch's real defect ────────────────
    //
    // `MarriageCertificatePage` and `DivorceCertificatePage` are
    // `StatelessWidget`s. Their cubits' `load()` methods exist, are documented
    // *"Called once when the page mounts"* (`marriage_form_cubit.dart:370-374`),
    // and **had no caller in `lib/` at all** — only tests invoked them
    // (B12 § 2.2 Finding E). A builder that resolved the cubit and handed it
    // straight to the page would render a marriage form with no nationality
    // list, no ethnicity list, no province list and no fee; and because
    // `_loadRef` folds a failure into an EMPTY list with `loading: false`
    // (`:391-393`), the page shows **no error either**. Reachable, green,
    // silent and useless — which is exactly what `B12-AC-15` alone would pass
    // against, and why `B12-AC-17` asserts the rendered fee instead.
    //
    // This is the same seam `..add(const HomeStarted())` and
    // `..add(const ServiceStarted())` above use, for the reason `:430-434`
    // gives: it keeps the page a pure function of its BLoC. The alternative —
    // making the two pages stateful — edits F3's page files, which B12 § 4.1
    // forbids. The asymmetry with Resident/Birth/Death/FamilyBook is a defect
    // B12 **inherits and declines to normalise**, because normalising it means
    // editing four other batches' page files to make a comment read better
    // (`FU-B12-3`).
    //
    // `formatLak` is the app's shared money formatter
    // (`features/home/domain/home_formatting.dart` — the same one wallet,
    // application and family_book import), bound to this build's locale. The
    // page takes it as a parameter so it carries no formatting policy of its
    // own; passing a local lambda here would be a second policy.
    GoRoute(
      path: AppNameRoutes.marriageCertificate,
      name: AppNameRoutes.marriageCertificate,
      builder: (BuildContext context, GoRouterState state) =>
          BlocProvider<MarriageFormCubit>(
        create: (_) => certificatesInjection<MarriageFormCubit>(
          param1: _langOf(context),
        )..load(),
        child: Builder(
          builder: (BuildContext inner) => MarriageCertificatePage(
            cubit: inner.read<MarriageFormCubit>(),
            onBack: () => inner.go(AppNameRoutes.home),
            formatLak: (int? amount) => formatLak(
              amount,
              Localizations.localeOf(inner).languageCode,
            ),
          ),
        ),
      ),
    ),

    // `/service/divorce-certificate` — F3. Finding E's other half; see the
    // Marriage block above for the whole argument.
    GoRoute(
      path: AppNameRoutes.divorceCertificate,
      name: AppNameRoutes.divorceCertificate,
      builder: (BuildContext context, GoRouterState state) =>
          BlocProvider<DivorceFormCubit>(
        create: (_) => certificatesInjection<DivorceFormCubit>(
          param1: _langOf(context),
        )..load(),
        child: Builder(
          builder: (BuildContext inner) => DivorceCertificatePage(
            cubit: inner.read<DivorceFormCubit>(),
            onBack: () => inner.go(AppNameRoutes.home),
            formatLak: (int? amount) => formatLak(
              amount,
              Localizations.localeOf(inner).languageCode,
            ),
          ),
        ),
      ),
    ),

    // `/service/family-book` — F4, and the one route in this table whose
    // builder makes a decision none of the other five has to make.
    //
    // ── RULING 6 — construct nothing until the session resolves ─────────────
    //
    // `FamilyBookCubit` is the **only cubit in the tree that takes an auth flag
    // at construction** (`family_book_bloc_injection.dart:49-50`,
    // `registerFactoryParam<FamilyBookCubit, bool, void>`), and
    // `FamilyBookViewState.initial` sets `loading: authenticated` — the port of
    // `hooks.ts:46`'s *"`loading` initialises to `enabled`, not `true`"*. So the
    // bool passed here does not merely tune a fetch: **it decides which of the
    // page's eight states the citizen lands in.**
    //
    // Both obvious answers ship a defect in the boot-hold window, where
    // `_redirect` deliberately returns null (`:274-277`) and the page is built
    // anyway:
    //
    // * `param1: true`, on the ground that the route is protected — `load()`
    //   fires with no token yet and a citizen with a valid session gets an
    //   error state.
    // * a single non-reactive `ctx.read<SessionBloc>()` at build time — the read
    //   returns `false`, the cubit is constructed signed-out, and **it stays
    //   that way**. When the session resolves, `refreshListenable` re-runs
    //   `_redirect`, the citizen is now authenticated, no redirect fires, and
    //   the already-mounted page keeps its stale `false`. A citizen with a
    //   valid token sees the signed-out family book until they navigate away.
    //
    // So: while the status is `initial` or `loading`, this route constructs
    // **nothing** and renders the page's own loading chrome; on resolution it
    // constructs once, with the resolved value. The frame below is not a new
    // widget — it is `FamilyBookFrame` with the same four children
    // `family_book_page.dart:85-97` renders for `showsLoading`, so an
    // authenticated citizen sees one continuous loading state across the
    // transition rather than a flash of anything else.
    //
    // `buildWhen` on `status` alone is deliberate: the gate is a function of the
    // status and of nothing else, and a profile arriving later must not be able
    // to rebuild this subtree in a way that could be mistaken for a
    // reconstruction. `B12-AC-39` clause 3 drives the transition inside the
    // test; `B12-AC-40` runs both wrong answers as controls and records that
    // each leaves AC-15, AC-16 and AC-18 green — which is the evidence that this
    // ruling governs something no reachability criterion can see.
    //
    // **Scope**: `/history` and `/account` are also protected and also built
    // during the hold, but their BLoCs take no auth flag, so their fetch timing
    // is a pre-existing programme question and not B12's (`FU-B12-4`). This
    // ruling is confined to the one route whose *constructor* takes the flag.
    //
    // **No `..load()`**: `family_book_page.dart:68-72` calls it from
    // `initState`. This is the Resident/Birth/Death column, not Marriage's —
    // and the interaction with RULING 6 is why the hold matters at all: because
    // the *page* fetches on mount, constructing it with a stale
    // `authenticated: false` does not merely delay a fetch, it fires the wrong
    // one.
    GoRoute(
      path: AppNameRoutes.familyBook,
      name: AppNameRoutes.familyBook,
      builder: (BuildContext context, GoRouterState state) =>
          BlocBuilder<SessionBloc, SessionState>(
        buildWhen: (SessionState a, SessionState b) => a.status != b.status,
        builder: (BuildContext sessionContext, SessionState session) {
          if (session.status == SessionStatus.initial ||
              session.status == SessionStatus.loading) {
            return FamilyBookFrame(
              onBack: () => sessionContext.go(AppNameRoutes.home),
              // `{book && <StepIndicator …>}` — there is no book yet.
              showStepIndicator: false,
              step: 1,
              children: const <Widget>[
                FamilyBookLoadingLine(),
                FamilyBookSkeletonCard(),
                FamilyBookSkeletonCard(),
                FamilyBookSkeletonCard(),
              ],
            );
          }
          return BlocProvider<FamilyBookCubit>(
            create: (_) => familyBookInjection<FamilyBookCubit>(
              param1: session.status == SessionStatus.authenticated,
            ),
            child: Builder(
              builder: (BuildContext inner) => FamilyBookPage(
                cubit: inner.read<FamilyBookCubit>(),
                onBack: () => inner.go(AppNameRoutes.home),
              ),
            ),
          );
        },
      ),
    ),

    if (kDebugMode)
      GoRoute(
        path: AppNameRoutes.debug,
        name: AppNameRoutes.debug,
        builder: (_, __) => const _PlaceholderPage(title: 'Debug'),
      ),
  ];

  // ── B12 — the `Lang` the five certificate cubits are constructed with ─────
  /// **The page's own expression, not `Lang.fromCode`.**
  ///
  /// All five certificate pages compute
  /// `Localizations.localeOf(context).languageCode == 'lo' ? Lang.lo : Lang.en`
  /// in their own `build`, and the cubit's `lang` is `final` with no setter. A
  /// disagreement between the two is **silent**: the page renders one language
  /// and the cubit writes the other into `form_data`.
  ///
  /// `Lang.fromCode` is *not* interchangeable — it falls back to [Lang.lo]
  /// (`i18n.dart:59-68`) where the pages fall back to [Lang.en]. Under the app's
  /// two supported locales (`main.dart:135`) the two agree everywhere, so
  /// nothing is broken today and `B12-AC-24` cannot discriminate between them;
  /// it discriminates against a hardcoded constant and an inverted mapping,
  /// which are the failures actually available here. The divergence is
  /// **`FU-B12-2`** and a third locale makes it live.
  ///
  /// `/service/family-book` does **not** use this: `FamilyBookCubit`'s `param1`
  /// is a `bool authenticated`, and its language arrives at submit through
  /// `requestCopy(Lang)`.
  static Lang _langOf(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'lo'
          ? Lang.lo
          : Lang.en;
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
/// ## N-7 — app-lifetime ownership, stated instead of pretended (SSD § 9.2, CR-7)
///
/// This class used to carry a `dispose()` that cancelled the subscription, and
/// **that method had no call site anywhere in the tree.** `go_router` removes
/// its own listener from a `refreshListenable` but never disposes it, and the
/// one router this app builds is created in `App.initState` and held until the
/// process exits. So the teardown path was unreachable by construction: it read
/// as resource discipline while providing none, and the next reader had to
/// re-derive that before trusting it.
///
/// The subscription is therefore deliberately not retained and deliberately
/// never cancelled — it lives exactly as long as the app does, which is also
/// exactly as long as the `SessionBloc` stream it listens to. **If a second,
/// shorter-lived router is ever built** (a nested navigator, a per-test router
/// that outlives its BLoC), reintroduce cancellation *together with* the call
/// site that invokes it, in the same change.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    stream.asBroadcastStream().listen(
      (_) => notifyListeners(),
      onError: (_) => notifyListeners(),
    );
  }
}

// ── Placeholder page (still used by /debug) ────────────────────────────────
/// Inline placeholder. P0-5 replaced it on the five main tabs with the real
/// shell + per-tab pages, the auth-wiring dispatch replaced it on `/signin`
/// with the real `AuthPage`, and **B2c replaced it on `/help` and `/news`**
/// with the real pages.
///
/// ## Why the class survives (B2-AC-37)
///
/// SSD § 9.2's N-5 assumed B2 deletes it outright. The B2 spec narrowed that:
/// § 3.1's B2c column is *"the `/news`, `/news/:slug`, `/help` builders and the
/// `_PlaceholderPage` deletion"*, and § 7's B2-AC-37 spells out the actual
/// requirement — *"`_PlaceholderPage`'s `/help` and `/news` uses deleted, the
/// `/debug` use retained"*.
///
/// `/debug` is `kDebugMode`-gated and has no page of its own; deleting the
/// class would take the route with it. So the two **uses** are gone and the
/// class stays, with exactly one call site.
///
/// The next batch to give `/debug` a real page deletes this class in the same
/// change. Do not delete it before then — a route that builds nothing is worse
/// than a placeholder that says so.
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

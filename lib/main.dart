/// App entry point.
///
/// Boot order (port of `lcc-app/src/app/App.tsx`'s phases onto the
/// flutter-boilerplate `main.dart` shape):
///
///   1. `WidgetsFlutterBinding.ensureInitialized()`
///   2. `Hive.initFlutter()`             — storage backend
///   3. `AppI18n.init()`                 — `EasyLocalization.ensureInitialized`
///   4. `DependencyInjection().init()`   — StorageService → ApiClient → session
///   5. `Bloc.observer`
///   6. resolve the single `SessionBloc`, dispatch `SessionStarted`
///   7. `runApp`
///
/// Steps 1–5 are unchanged from P0-4; P0-5 adds 6 and swaps the placeholder
/// `MaterialApp` for `MaterialApp.router`.
///
/// ## Defect F-2 — one `SessionBloc`, guaranteed
///
/// `AppRoutes.build(sessionBloc)` wires the router's `refreshListenable` to the
/// BLoC's stream and reads `state.status` inside `redirect`. If the router and
/// the widget tree ever held *different* instances, the redirect would watch a
/// BLoC nobody dispatches to and the auth gate would never fire. Two things
/// now prevent that:
///
/// - `SessionBloc` is a `registerLazySingleton` on the root `injection` (see
///   `core/di/dependency_injection.dart`), so every resolution — from
///   anywhere, forever — returns the same object.
/// - This file resolves it exactly once into [sessionBloc] and hands that one
///   reference to both `AppRoutes.build` and the `BlocProvider.value` that
///   sits **above** `MaterialApp.router`.
///
/// The provider placement is also defect F-1's fix: `AuthPage` calls
/// `context.read<SessionBloc>()`, which needs an ancestor provider or it
/// throws `ProviderNotFoundException` on the first successful login. Providing
/// above the router covers every route, including the ones outside the shell.
///
/// `BlocProvider.value` (not `BlocProvider(create:)`) because the container
/// owns the BLoC's lifetime; `create:` would close a singleton the app still
/// needs when the provider unmounts.
///
/// ## Boot resolve
///
/// `SessionStarted` is dispatched here, before `runApp`. Without it a warm
/// start with a stored token would hang in `SessionStatus.initial` — which the
/// router's `redirect` treats as "still booting, do not redirect" — leaving the
/// citizen on a page that never resolves. Dispatching after the router is built
/// means the refresh stream is already subscribed when
/// `initial → loading → authenticated` lands.
///
/// ## Language
///
/// `easy_localization`'s own `saveLocale` is **off**. The language preference
/// is owned by `StorageService` under the `lcc.lang` key that GOR-245 § 4.2
/// freezes, read back here and passed as `startLocale`. One writer, one key —
/// see `presentation/shell/language_toggle.dart`.
///
/// ## Boot phase (B10 § 6.8) — the splash **replaces** the app
///
/// `App.tsx`:195-222 is a three-phase state machine — `loading` → `onboarding`
/// → `app` — and each phase assigns the `screen` variable **exclusively**.
/// During `loading`, `Layout` and every page are *not mounted*.
///
/// Two Flutter shapes were considered and both alternatives are wrong:
///
/// * **Overlay** — `MaterialApp.builder` painting the splash above a live
///   `Navigator`. Rejected: it mounts `HomePage` behind the splash, so
///   `/me/home-summary`, `/services` and `/news` all fire during boot. The web
///   issues none of them until the splash completes. An observable divergence
///   in network timing that no fidelity tier inspects — the R-25 class.
/// * **Routes** — `/splash` and `/onboarding` as `GoRoute`s. Rejected: the
///   web's phases have no hash and are not addressable, so this would invent
///   deep-linkable surfaces the source lacks and then need a redirect guard to
///   stop `/onboarding` being reachable after first run.
///
/// So [_AppState] holds a [BootPhase] and swaps what it *mounts*. The router is
/// still built once in `initState` and `SessionStarted` is still dispatched
/// there, unchanged.
///
/// ## GOR-269 — hardware Back, and why the wiring below looks redundant
///
/// [_routedApp] hands `MaterialApp.router` five fields where it used to hand
/// one. That is not a refactor and it is not preference: `GoRouter` 16.3.0
/// hard-initialises its own `RootBackButtonDispatcher` in its constructor
/// initialiser list and takes none as a parameter, while `WidgetsApp.router`
/// asserts *"If the routerConfig is provided, all the other router delegates
/// must not be provided"*. `routerConfig:` and `backButtonDispatcher:` are
/// therefore mutually exclusive, and the only pinned-version-valid way to
/// install a custom dispatcher is to read the other three `RouterConfig`
/// members off the same `GoRouter` and pass all four
/// (`fix-plan.md` `FC-5`). Restoring `routerConfig:` and adding the dispatcher
/// beside it trips the assertion on the first frame.
///
/// The fifth is `onNavigationNotification`, and it is not part of that
/// constraint — it is `SRE-269-5`'s fix. `backButtonDispatcher:` decides what
/// happens when Android delivers a Back press; `onNavigationNotification:`
/// decides whether Android delivers it at all. On `targetSdk 36` the delivered
/// fix passed 3599 tests and still exited the app on a physical device, because
/// only the first of those two was wired. Both are the policy's, both are
/// installed here, and neither is sufficient alone.
///
/// **This is the whole of the fix's wiring.** GOR-269 changed no route's mount
/// point, no `navigatorKey`, and none of the 36 `context.go()` call sites — so
/// rolling it back is reverting this one composition (`fix-plan.md` § 13.5),
/// which is the nearest thing this project has to a kill switch given
/// `ADR-0002` leaves no store, no CI/CD and no remote config to flip a flag
/// through.
///
/// The boot phases below are **not** covered by it, and that is a stated limit
/// rather than an oversight: [_bootApp] mounts a plain `MaterialApp` with no
/// `Router`, so no dispatcher is installed and Back during the splash or
/// onboarding still exits. Recorded as `OQ-10` for triage, out of scope here
/// because it was never reproduced (`fix-plan.md` § 4.1).
///
/// **The session gate is ported exactly.** `App.tsx`:200 holds the splash while
/// `bootPhase === "loading" || session.loading`. Here the phase advances only
/// when the timer has elapsed **and** `SessionBloc.state.status` has left
/// `initial`/`loading`. Dropping the second condition reintroduces the
/// signed-out flash the "Boot resolve" note above documents.
///
/// ## [App.bootStorage] is nullable, and that is a test seam stated out loud
///
/// The boot phase needs a [StorageService] to read `lcc.onboarding_seen`.
/// When [App.bootStorage] is null there is nothing to read, so the app mounts
/// the router directly — which is exactly the shape every pre-B10 assembled
/// test pumps, and why 36 existing call sites needed no edit. **Production
/// always supplies it** ([main] below), so the boot phase is never inert in a
/// shipped build; it is exercised by `test/app/boot_phase_test.dart`, which
/// supplies one.
library;

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/di/dependency_injection.dart';
import 'core/observer/app_bloc_observer.dart';
import 'core/session/bloc/session_bloc.dart';
import 'core/storage/storage_service.dart';
import 'i18n/i18n.dart';
import 'presentation/boot/loading_screen.dart';
import 'presentation/boot/splash_screens.dart';
import 'presentation/theme/app_colors.dart';
import 'presentation/theme/app_spacing.dart';
import 'presentation/theme/app_theme.dart';
import 'utils/routes/app_back_policy.dart';
import 'utils/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await AppI18n.init();
  await DependencyInjection().init();
  Bloc.observer = AppBlocObserver();

  // F-2: resolved once, shared by the router and the widget tree.
  final SessionBloc sessionBloc = injection<SessionBloc>();

  // CR-1's seam: `main.dart` is one of exactly two places allowed to read the
  // locator. Resolved once and threaded down, never reached for from a widget.
  final StorageService storage = injection<StorageService>();

  // The persisted UI language (`lcc.lang`, default `lo`).
  final Locale startLocale = Lang.fromCode(await storage.getLang()).toLocale();

  runApp(
    EasyLocalization(
      supportedLocales: const <Locale>[Locale('en'), Locale('lo')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('lo'),
      startLocale: startLocale,
      saveLocale: false,
      child: App(sessionBloc: sessionBloc, bootStorage: storage),
    ),
  );
}

/// `App.tsx`:193's `bootPhase` — `"loading" | "onboarding" | "app"`.
enum BootPhase {
  /// The boot splash. Every launch, `LoadingScreen`.
  loading,

  /// The three onboarding slides. First run only.
  onboarding,

  /// The router and the shell — everything the app normally is.
  app,
}

/// Root widget: the session provider, the router, and the theme.
///
/// Takes [sessionBloc] as a required parameter rather than reaching into the
/// container itself. The container would give the same instance (it is a lazy
/// singleton), but an explicit parameter keeps the dependency visible at the
/// call site and lets a widget test assemble the app against a stub BLoC with
/// no DI setup at all.
class App extends StatefulWidget {
  const App({
    super.key,
    required this.sessionBloc,
    this.bootStorage,
    this.bootDuration = AppMotion.bootHold,
  });

  /// The app-wide session state machine. See the F-2 note above.
  final SessionBloc sessionBloc;

  /// Reads and writes `lcc.onboarding_seen`. **Null disables the boot phase** —
  /// see the "test seam" note in the library doc. `main` always supplies it.
  final StorageService? bootStorage;

  /// `DEFAULT_DURATION` — overridable so a test can assert the hold rather than
  /// wait it out. Production never passes it.
  final Duration bootDuration;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router;

  /// GOR-269's back policy and the dispatcher that installs it.
  ///
  /// Built here rather than in `build` for the same reason [_router] is: the
  /// policy owns the citizen's journey for the life of the app, and one rebuilt
  /// per frame would forget where they had been on every frame.
  late final AppBackPolicy _backPolicy;
  late final AppBackButtonDispatcher _backDispatcher;

  /// Starts at [BootPhase.app] when there is no storage to gate on.
  late BootPhase _phase =
      widget.bootStorage == null ? BootPhase.app : BootPhase.loading;

  /// True once `LoadingScreen`'s own timer has fired. The phase advance needs
  /// **both** this and a resolved session (`App.tsx`:200), so the two are
  /// tracked separately and reconciled in [_maybeLeaveLoading].
  bool _holdElapsed = false;

  StreamSubscription<SessionState>? _sessionSub;

  @override
  void initState() {
    super.initState();
    // Built once and held for the widget's life: a `GoRouter` rebuilt on every
    // `build` would reset the navigation stack on each frame.
    _router = AppRoutes.build(widget.sessionBloc);

    // GOR-269. Constructed here, before the router has parsed anything, so the
    // policy's listener is attached in time to observe the very first resolved
    // location — cold deep link included. See `AppBackPolicy`'s constructor.
    _backPolicy = AppBackPolicy(
      router: _router,
      sessionBloc: widget.sessionBloc,
    );
    _backDispatcher = AppBackButtonDispatcher(_backPolicy);

    if (widget.bootStorage != null) {
      // `|| session.loading` — the second half of the gate. Subscribed rather
      // than polled so a session that resolves *after* the hold still releases
      // the splash; without this the app would sit on the boot screen forever
      // on a slow profile call.
      _sessionSub = widget.sessionBloc.stream.listen((SessionState _) {
        _maybeLeaveLoading();
      });
    }

    // Boot resolve — see the "Boot resolve" note above. Dispatched after the
    // router exists so its refresh stream sees every transition.
    widget.sessionBloc.add(const SessionEvent.started());
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    // Releases the router-delegate listener and the session subscription the
    // policy holds. The router itself is not disposed here — it never was, and
    // GOR-269 does not change that.
    _backPolicy.dispose();
    super.dispose();
  }

  /// `setBootPhase(hasSeenOnboarding() ? "app" : "onboarding")` — `App.tsx`:202.
  ///
  /// Called from two places (the timer and the session stream) and guarded, so
  /// whichever settles last is the one that advances.
  Future<void> _maybeLeaveLoading() async {
    if (!mounted || _phase != BootPhase.loading || !_holdElapsed) return;

    final SessionStatus status = widget.sessionBloc.state.status;
    if (status == SessionStatus.initial || status == SessionStatus.loading) {
      return;
    }

    final bool seen = await widget.bootStorage!.hasSeenOnboarding();
    if (!mounted || _phase != BootPhase.loading) return;
    setState(() => _phase = seen ? BootPhase.app : BootPhase.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SessionBloc>.value(
      value: widget.sessionBloc,
      child: _phase == BootPhase.app ? _routedApp(context) : _bootApp(context),
    );
  }

  /// The app proper.
  Widget _routedApp(BuildContext context) {
    return MaterialApp.router(
      title: 'Lao Citizen Center',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // No dark theme: the React source has none, so there is nothing to
      // port and inventing one is design work this ticket has no source for.
      themeMode: ThemeMode.light,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      // GOR-269 / `FC-5`. The four-field expansion, not `routerConfig:` — see
      // the library doc. All three router members are read off the one
      // `GoRouter` built in `initState`, so this is the same router it always
      // was, handed over in the only shape that can also carry a dispatcher.
      routeInformationProvider: _router.routeInformationProvider,
      routeInformationParser: _router.routeInformationParser,
      routerDelegate: _router.routerDelegate,
      backButtonDispatcher: _backDispatcher,
      // GOR-269 / `SRE-269-5`. The dispatcher above only runs once Android has
      // decided to deliver the press into Flutter, and on `targetSdk 36`
      // Android asks the app first. `WidgetsApp`'s default answer is
      // `Navigator.canPop()`, which is false on every stack-replacing
      // `context.go()` route — so the app was declining Back on exactly the
      // routes the dispatcher exists to serve, and the fix never reached the
      // device. This override widens that answer with the policy's own
      // `hasPredecessor`. See `app_back_policy.dart`'s library doc.
      onNavigationNotification: _backPolicy.onNavigationNotification,
    );
  }

  /// The boot phases — a plain `MaterialApp` with no router, because nothing
  /// here is addressable (§ 6.8).
  ///
  /// ## The `Scaffold` is load-bearing, not boilerplate
  ///
  /// `MaterialApp` does **not** insert a `Material` into the tree; `Scaffold`
  /// is what does. Without one, every `InkResponse`-based control on the
  /// splash — Skip, Back, Next, the language toggle, the tutorial's close
  /// button — asserts *"No Material widget found"* the moment it builds, and a
  /// fresh install meets a red error screen instead of onboarding.
  ///
  /// This was shipped broken and caught by `boot_phase_test.dart`'s regression
  /// case. It survived review because it is invisible from two directions at
  /// once: every widget test of `SplashScreens` supplies its own `Scaffold`,
  /// and the shared harness leaves `bootStorage` null so the boot phase never
  /// mounts in the assembled-app tests either. The one tree that was never
  /// pumped is the one production uses.
  ///
  /// `backgroundColor` is the splash's own base colour rather than the theme's
  /// default white: both children paint over the full viewport, but a white
  /// flash between the phase swap and the first painted frame is visible on a
  /// slow device, and the boot screens are the one place in the app where that
  /// frame is guaranteed to be the citizen's first.
  Widget _bootApp(BuildContext context) {
    return MaterialApp(
      title: 'Lao Citizen Center',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: Scaffold(
        backgroundColor: AppColors.bootGradientEnd,
        body: _phase == BootPhase.loading
            ? LoadingScreen(
                duration: widget.bootDuration,
                onDone: () {
                  _holdElapsed = true;
                  _maybeLeaveLoading();
                },
              )
            : Builder(
                // A `Builder` so the slot factories get a context **below**
                // `MaterialApp`, i.e. one that can see `Localizations`. Reading
                // `onboarding.idHolderValue` off the outer context would throw.
                builder: (BuildContext inner) => SplashScreens(
                  storage: widget.bootStorage!,
                  onDone: () => setState(() => _phase = BootPhase.app),
                  slide3Visual: AppRoutes.splashSlide3Visual(inner),
                  backdropBuilder: AppRoutes.splashBackdrop,
                ),
              ),
      ),
    );
  }
}

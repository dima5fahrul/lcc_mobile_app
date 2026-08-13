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
library;

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
import 'presentation/theme/app_theme.dart';
import 'utils/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await AppI18n.init();
  await DependencyInjection().init();
  Bloc.observer = AppBlocObserver();

  // F-2: resolved once, shared by the router and the widget tree.
  final SessionBloc sessionBloc = injection<SessionBloc>();

  // The persisted UI language (`lcc.lang`, default `lo`).
  final Locale startLocale =
      Lang.fromCode(await injection<StorageService>().getLang()).toLocale();

  runApp(
    EasyLocalization(
      supportedLocales: const <Locale>[Locale('en'), Locale('lo')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('lo'),
      startLocale: startLocale,
      saveLocale: false,
      child: App(sessionBloc: sessionBloc),
    ),
  );
}

/// Root widget: the session provider, the router, and the theme.
///
/// Takes [sessionBloc] as a required parameter rather than reaching into the
/// container itself. The container would give the same instance (it is a lazy
/// singleton), but an explicit parameter keeps the dependency visible at the
/// call site and lets a widget test assemble the app against a stub BLoC with
/// no DI setup at all.
class App extends StatefulWidget {
  const App({super.key, required this.sessionBloc});

  /// The app-wide session state machine. See the F-2 note above.
  final SessionBloc sessionBloc;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Built once and held for the widget's life: a `GoRouter` rebuilt on every
    // `build` would reset the navigation stack on each frame.
    _router = AppRoutes.build(widget.sessionBloc);

    // Boot resolve — see the "Boot resolve" note above. Dispatched after the
    // router exists so its refresh stream sees every transition.
    widget.sessionBloc.add(const SessionEvent.started());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SessionBloc>.value(
      value: widget.sessionBloc,
      child: MaterialApp.router(
        title: 'Lao Citizen Center',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        // No dark theme: the React source has none, so there is nothing to
        // port and inventing one is design work this ticket has no source for.
        themeMode: ThemeMode.light,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        routerConfig: _router,
      ),
    );
  }
}

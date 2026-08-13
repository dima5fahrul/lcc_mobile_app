/// Root dependency-injection scaffold.
///
/// Extends the flutter-boilerplate pattern (`StorageService` → feature
/// injections). Registration order is load-bearing, not cosmetic:
///
///   1. `StorageService`  — everything downstream reads tokens/lang from it.
///   2. `ApiClient`       — owns the configured Dio + Auth/Refresh interceptors,
///                          which resolve `StorageService` when they run.
///   3. `SessionFeatureInjection.init()` — its datasource reaches back into this
///                          container for `ApiClient`.
///   4. `SessionBloc`     — app-wide session state, registered on *this* root
///                          container rather than the session feature's (CR-3:
///                          the router, `main.dart` and three feature pages all
///                          consume it, so it is not feature-scoped). Must come
///                          after step 3 — its closure resolves `GetProfile`
///                          and `SessionRepository` back out of
///                          `sessionInjection`.
///   5. `AuthFeatureInjection.init()`    — last, because the auth flow terminates
///                          in `SessionBloc.add(SessionSignIn(session))`; the
///                          session feature must already be registered when the
///                          first successful login lands.
///
/// Steps 3–5 all register *lazy* singletons, so nothing is actually
/// constructed here — but the plan's ordering is still honoured literally so a
/// later change to an eager registration cannot silently invert the dependency.
///
/// Call [DependencyInjection.init] once at app start, before `runApp`.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/di/auth_feature_injection.dart';
import '../../features/session/di/session_feature_injection.dart';
import '../../features/session/di/session_injection.dart';
import '../../features/session/domain/repositories/session_repository.dart';
import '../../features/session/domain/usecases/get_profile.dart';
import '../network/api_client.dart';
import '../network/dio_network_client.dart';
import '../session/bloc/session_bloc.dart';
import '../storage/storage_service.dart';

final injection = GetIt.instance;

class DependencyInjection {
  /// Public default constructor so boot can call `DependencyInjection().init()`.
  /// The private `._()` form was a leftover from the boilerplate scaffold; the
  /// task's target `main.dart` calls `DependencyInjection().init()`, so expose
  /// a plain constructor here. All real work happens in [init].
  const DependencyInjection();

  /// Register core singletons and every feature container. Call once at boot.
  Future<void> init() async {
    // 1. StorageService — everything else depends on it (tokens, lang).
    injection.registerLazySingleton<StorageService>(
      () => StorageService(const FlutterSecureStorage()),
    );

    // 2. ApiClient — owns the Dio instance with Auth + Refresh interceptors.
    //    ChuckerDioInterceptor is attached in debug builds for network
    //    inspection (per the user's chucker_flutter choice).
    injection.registerLazySingleton<ApiClient>(
      () => ApiClient(
        dio: buildDio(
          storage: injection<StorageService>(),
          extraInterceptors: debugInterceptors(),
        ),
        storage: injection<StorageService>(),
      ),
    );

    // 3. Session feature — owns its datasources, repos and usecases. Must init
    //    AFTER StorageService + ApiClient (its datasource resolves
    //    `injection<ApiClient>()`).
    await SessionFeatureInjection.init();

    // 4. SessionBloc — app-wide, so it lives on the ROOT container (CR-3), not
    //    on `sessionInjection`. It is consumed by the router, `main.dart` and
    //    the home / auth / account pages; scoping it to the session feature's
    //    container misrepresented it as feature-local.
    //
    //    ── F-2 fix (GOR-245 § 2.2) ─────────────────────────────────────────
    //    `registerFactory` handed out a NEW `SessionBloc` on every resolution.
    //    The router (`AppRoutes.build`) wires `refreshListenable` and reads
    //    `state.status` on the instance it is given, while the widget tree
    //    resolves its own — two BLoCs, one of them never dispatched to, so the
    //    auth gate would sit on `SessionStatus.initial` forever and never fire.
    //
    //    `registerLazySingleton` is the fix rather than "resolve once in
    //    `main.dart` and pass the reference around": both give the router and
    //    the tree the same object today, but only this one makes it
    //    *impossible* for a future call site to resolve a second one by
    //    accident. The invariant GOR-245 states — exactly one `SessionBloc`
    //    for the app's lifetime — then holds by construction instead of by
    //    discipline. `main.dart` still resolves it once and passes it
    //    explicitly, so the ownership is readable at the call site too; the
    //    singleton is the belt, the parameter is the braces.
    //
    //    Lifetime: the container outlives the app, so the BLoC is never
    //    closed. That is correct for a session that must survive every route
    //    change — and it is why `main.dart` uses `BlocProvider.value` (which
    //    does not close what it did not create) instead of
    //    `BlocProvider(create:)`.
    //
    //    Registered AFTER step 3: the closure reaches into `sessionInjection`
    //    for `GetProfile` / `SessionRepository`. All registrations are lazy,
    //    so a wrong order here would not fail at registration — it would fail
    //    at first resolution, i.e. at app boot.
    injection.registerLazySingleton<SessionBloc>(
      () => SessionBloc(
        storage: injection<StorageService>(),
        getProfile: sessionInjection<GetProfile>(),
        repository: sessionInjection<SessionRepository>(),
      ),
    );

    // 5. Auth feature (defect F-3). Without this line `authInjection` is empty,
    //    `AuthPage.initState`'s `authInjection<AuthBloc>()` throws, and the
    //    whole 51-file auth feature is dead code no matter what the router
    //    points at. Registered last: `AuthPage` completes a login by handing
    //    the `CitizenSession` to `SessionBloc`, so the session container is a
    //    prerequisite of the auth flow, not the other way round.
    //
    //    `AuthDatasourceInjection` re-exports the root `ApiClient` into
    //    `authInjection` via `() => injection<ApiClient>()` — verified by
    //    reading `features/auth/di/auth_datasource_injection.dart`, which is
    //    why step 2 must precede this and why the auth container does NOT
    //    build a second Dio. Note the deliberate asymmetry with step 4:
    //    `SessionBloc` is a root `registerLazySingleton` (one session for the
    //    app's lifetime, F-2), whereas `AuthFeatureInjection` keeps a
    //    feature-scoped `registerFactory<AuthBloc>` — correct, because an auth
    //    attempt is scoped to one visit to /signin.
    //    See the provider note in `auth_page.dart`.
    await AuthFeatureInjection.init();
  }
}

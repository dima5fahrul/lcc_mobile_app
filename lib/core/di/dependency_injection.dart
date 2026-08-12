/// Root dependency-injection scaffold.
///
/// Extends the flutter-boilerplate pattern (`StorageService` → feature
/// injections). Registration order is load-bearing, not cosmetic:
///
///   1. `StorageService`  — everything downstream reads tokens/lang from it.
///   2. `ApiClient`       — owns the configured Dio + Auth/Refresh interceptors,
///                          which resolve `StorageService` when they run.
///   3. `SessionFeatureInjection.init()` — its datasource reaches back into this
///                          container for `ApiClient`, and `SessionBloc` for
///                          `StorageService`.
///   4. `AuthFeatureInjection.init()`    — last, because the auth flow terminates
///                          in `SessionBloc.add(SessionSignIn(session))`; the
///                          session feature must already be registered when the
///                          first successful login lands.
///
/// Steps 3 and 4 both register *lazy* singletons, so nothing is actually
/// constructed here — but the plan's ordering is still honoured literally so a
/// later change to an eager registration cannot silently invert the dependency.
///
/// Call [DependencyInjection.init] once at app start, before `runApp`.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/di/auth_feature_injection.dart';
import '../../features/session/di/session_feature_injection.dart';
import '../network/api_client.dart';
import '../network/dio_network_client.dart';
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

    // 3. Session feature — owns its datasources, repos, usecases, and the
    //    app-wide `SessionBloc` singleton. Must init AFTER StorageService +
    //    ApiClient (its datasource resolves `injection<ApiClient>()`, its BLoC
    //    resolves `injection<StorageService>()`).
    await SessionFeatureInjection.init();

    // 4. Auth feature (defect F-3). Without this line `authInjection` is empty,
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
    //    build a second Dio. The session feature's DI was *not* copied
    //    wholesale: `SessionFeatureInjection` promotes its BLoC to a
    //    `registerLazySingleton` (one session for the app's lifetime, F-2),
    //    whereas `AuthFeatureInjection` keeps `registerFactory<AuthBloc>` —
    //    correct, because an auth attempt is scoped to one visit to /signin.
    //    See the provider note in `auth_page.dart`.
    await AuthFeatureInjection.init();
  }
}

/// Session feature injection entry point.
///
/// Called from [DependencyInjection.init] AFTER `StorageService` and
/// `ApiClient` are registered on the root container. The ordering matters:
/// the session datasource reaches into the root `injection` for `ApiClient`,
/// and the session BLoC reaches into the root for `StorageService` — both
/// must already be present.
///
/// Mirrors the flutter-boilerplate `MovieFeatureInjection.init()` ordering:
/// datasource → repository → usecase → bloc.
library;

import '../../../core/di/dependency_injection.dart';
import '../../../core/storage/storage_service.dart';
import '../domain/repositories/session_repository.dart';
import '../domain/usecases/get_profile.dart';
import '../presentation/bloc/session_bloc.dart';
import 'session_datasource_injection.dart';
import 'session_injection.dart';
import 'session_repository_injection.dart';
import 'session_usecase_injection.dart';

class SessionFeatureInjection {
  /// Register the session feature. Safe to call once at boot, after the core
  /// singletons are ready.
  static Future<void> init() async {
    SessionDatasourceInjection.inject();
    SessionRepositoryInjection.inject();
    SessionUsecaseInjection.inject();

    // ── F-2 fix (GOR-245 § 2.2) ────────────────────────────────────────────
    // `registerFactory` handed out a NEW `SessionBloc` on every resolution.
    // The router (`AppRoutes.build`) wires `refreshListenable` and reads
    // `state.status` on the instance it is given, while the widget tree
    // resolves its own — two BLoCs, one of them never dispatched to, so the
    // auth gate would sit on `SessionStatus.initial` forever and never fire.
    //
    // `registerLazySingleton` is the fix rather than "resolve once in
    // `main.dart` and pass the reference around": both give the router and the
    // tree the same object today, but only this one makes it *impossible* for
    // a future call site to resolve a second one by accident. The invariant
    // GOR-245 states — exactly one `SessionBloc` for the app's lifetime — then
    // holds by construction instead of by discipline. `main.dart` still
    // resolves it once and passes it explicitly, so the ownership is readable
    // at the call site too; the singleton is the belt, the parameter is the
    // braces.
    //
    // Lifetime: the container outlives the app, so the BLoC is never closed.
    // That is correct for a session that must survive every route change —
    // and it is why `main.dart` uses `BlocProvider.value` (which does not
    // close what it did not create) instead of `BlocProvider(create:)`.
    sessionInjection.registerLazySingleton<SessionBloc>(
      () => SessionBloc(
        storage: injection<StorageService>(),
        getProfile: sessionInjection<GetProfile>(),
        repository: sessionInjection<SessionRepository>(),
      ),
    );
  }
}

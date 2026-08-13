/// Session feature injection entry point.
///
/// Called from [DependencyInjection.init] AFTER `StorageService` and
/// `ApiClient` are registered on the root container. The ordering matters:
/// the session datasource reaches into the root `injection` for `ApiClient`,
/// so it must already be present.
///
/// Mirrors the flutter-boilerplate `MovieFeatureInjection.init()` ordering:
/// datasource → repository → usecase.
///
/// `SessionBloc` is deliberately **not** registered here. It is app-wide
/// session state, not a feature-scoped BLoC, and now lives at
/// `core/session/bloc/` (CR-3) — the root container in
/// `core/di/dependency_injection.dart` owns its registration. This container
/// keeps only the datasource / repository / usecase that the root closure
/// resolves back out of.
library;

import 'session_datasource_injection.dart';
import 'session_repository_injection.dart';
import 'session_usecase_injection.dart';

class SessionFeatureInjection {
  /// Register the session feature. Safe to call once at boot, after the core
  /// singletons are ready.
  static Future<void> init() async {
    SessionDatasourceInjection.inject();
    SessionRepositoryInjection.inject();
    SessionUsecaseInjection.inject();
  }
}

/// Session datasource DI.
///
/// Registers the [ApiClient] (pulled from the root `injection`) and
/// [SessionRemoteDatasource]. The ApiClient is re-registered into
/// [sessionInjection] so the session feature's call sites resolve everything
/// from the same container without reaching back to the root.
library;

import '../../../core/di/dependency_injection.dart';
import '../../../core/network/api_client.dart';
import '../data/datasources/session_remote_datasource.dart';
import 'session_injection.dart';

class SessionDatasourceInjection {
  static void inject() {
    sessionInjection
      ..registerLazySingleton<ApiClient>(() => injection<ApiClient>())
      ..registerLazySingleton<SessionRemoteDatasource>(
        () => SessionRemoteDatasourceImpl(
              apiClient: sessionInjection<ApiClient>(),
            ),
      );
  }
}

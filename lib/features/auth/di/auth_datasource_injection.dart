/// Auth datasource DI.
///
/// Registers the [ApiClient] (pulled from the root `injection`) and
/// [AuthRemoteDatasource]. The ApiClient is re-registered into
/// [authInjection] so the auth feature's call sites resolve everything from
/// the same container without reaching back to the root. Mirrors the session
/// feature's `session_datasource_injection.dart`.
library;

import '../../../core/di/dependency_injection.dart';
import '../../../core/network/api_client.dart';
import '../data/datasources/auth_remote_datasource.dart';
import 'auth_injection.dart';

class AuthDatasourceInjection {
  static void inject() {
    authInjection
      ..registerLazySingleton<ApiClient>(() => injection<ApiClient>())
      ..registerLazySingleton<AuthRemoteDatasource>(
        () => AuthRemoteDatasourceImpl(
          apiClient: authInjection<ApiClient>(),
        ),
      );
  }
}

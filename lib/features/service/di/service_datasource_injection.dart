/// Service catalogue datasource DI.
///
/// Re-registers the root [ApiClient] into [serviceInjection] so every call site
/// in this feature resolves from one container, then registers the datasource
/// on top of it. The `ApiClient` is the *same instance* the root holds — a
/// closure over `injection<ApiClient>()`, not a second client — which is what
/// keeps DI-3 true and the Auth/Refresh interceptors shared.
library;

import '../../../core/di/dependency_injection.dart';
import '../../../core/network/api_client.dart';
import '../data/datasources/service_remote_datasource.dart';
import 'service_injection.dart';

class ServiceDatasourceInjection {
  static void inject() {
    serviceInjection
      ..registerLazySingleton<ApiClient>(() => injection<ApiClient>())
      ..registerLazySingleton<ServiceRemoteDatasource>(
        () => ServiceRemoteDatasourceImpl(
          apiClient: serviceInjection<ApiClient>(),
        ),
      );
  }
}

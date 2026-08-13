/// Home datasource DI.
///
/// Re-registers the root [ApiClient] into [homeInjection] so every call site in
/// this feature resolves from one container, then registers the datasource on
/// top of it. The `ApiClient` is the *same instance* the root holds — a closure
/// over `injection<ApiClient>()`, not a second client — which is what keeps
/// DI-3 true and the Auth/Refresh interceptors shared. Home is the one B2
/// feature with authenticated reads, so sharing the interceptor chain is not
/// merely tidy here: a second client would carry no token and
/// `/me/home-summary` would 401 on every call.
library;

import '../../../core/di/dependency_injection.dart';
import '../../../core/network/api_client.dart';
import '../data/datasources/home_remote_datasource.dart';
import 'home_injection.dart';

class HomeDatasourceInjection {
  static void inject() {
    homeInjection
      ..registerLazySingleton<ApiClient>(() => injection<ApiClient>())
      ..registerLazySingleton<HomeRemoteDatasource>(
        () => HomeRemoteDatasourceImpl(apiClient: homeInjection<ApiClient>()),
      );
  }
}

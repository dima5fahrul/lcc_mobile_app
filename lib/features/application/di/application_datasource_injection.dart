/// Application datasource DI.
///
/// Re-registers the root [ApiClient] into [applicationInjection] so every call
/// site in this feature resolves from one container, then registers the
/// datasource on top of it. The client is the *same instance* the root holds —
/// a closure over `injection<ApiClient>()`, not a second client — which is what
/// keeps DI-3 true and what makes `/applications` carry the Auth and Refresh
/// interceptors it needs.
///
/// `/status-catalogue` is anonymous and needs neither, but it shares the client
/// anyway rather than building a second `Dio`: DI-3 admits no exception for
/// "this call happens not to need a token", and the `anonymous: true` flag on
/// the call is what the interceptors read.
library;

import '../../../core/di/dependency_injection.dart';
import '../../../core/network/api_client.dart';
import '../data/datasources/application_remote_datasource.dart';
import 'application_injection.dart';

class ApplicationDatasourceInjection {
  static void inject() {
    applicationInjection
      ..registerLazySingleton<ApiClient>(() => injection<ApiClient>())
      ..registerLazySingleton<ApplicationRemoteDatasource>(
        () => ApplicationRemoteDatasourceImpl(
          apiClient: applicationInjection<ApiClient>(),
        ),
      );
  }
}

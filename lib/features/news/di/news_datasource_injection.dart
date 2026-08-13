/// News datasource DI.
///
/// Re-registers the root [ApiClient] into [newsInjection] so every call site in
/// this feature resolves from one container, then registers the datasource on
/// top of it. The client is the *same instance* the root holds — a closure over
/// `injection<ApiClient>()`, not a second client — which is what keeps DI-3
/// true. News is wholly anonymous, so it does not need the Auth/Refresh
/// interceptors; it shares them anyway rather than building a second `Dio`,
/// because DI-3 admits no exception for "this feature happens not to need a
/// token".
library;

import '../../../core/di/dependency_injection.dart';
import '../../../core/network/api_client.dart';
import '../data/datasources/news_remote_datasource.dart';
import 'news_injection.dart';

class NewsDatasourceInjection {
  static void inject() {
    newsInjection
      ..registerLazySingleton<ApiClient>(() => injection<ApiClient>())
      ..registerLazySingleton<NewsRemoteDatasource>(
        () => NewsRemoteDatasourceImpl(apiClient: newsInjection<ApiClient>()),
      );
  }
}

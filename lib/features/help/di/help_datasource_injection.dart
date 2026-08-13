/// Help datasource DI.
///
/// Re-registers the root [ApiClient] into [helpInjection] — the *same
/// instance*, a closure over `injection<ApiClient>()`, not a second client
/// (DI-3). Help is the one B2c feature that makes a non-anonymous call
/// (`POST /help/faqs/<id>/feedback`), so sharing the interceptor chain is
/// load-bearing here and not merely tidy.
library;

import '../../../core/di/dependency_injection.dart';
import '../../../core/network/api_client.dart';
import '../data/datasources/help_remote_datasource.dart';
import 'help_injection.dart';

class HelpDatasourceInjection {
  static void inject() {
    helpInjection
      ..registerLazySingleton<ApiClient>(() => injection<ApiClient>())
      ..registerLazySingleton<HelpRemoteDatasource>(
        () => HelpRemoteDatasourceImpl(apiClient: helpInjection<ApiClient>()),
      );
  }
}

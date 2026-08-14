/// Account datasource DI.
///
/// Re-registers the root [ApiClient] into [accountInjection] — the *same
/// instance*, a closure over `injection<ApiClient>()`, not a second client
/// (DI-3). Load-bearing rather than tidy: **all three account calls are
/// authenticated** (none carries `anonymous: true` in `endpoints.ts`), so they
/// need the Auth/Refresh interceptor chain that lives inside the root client.
/// The precedent is `AuthDatasourceInjection`
/// (`dependency_injection.dart:128-129`).
library;

import '../../../core/di/dependency_injection.dart';
import '../../../core/network/api_client.dart';
import '../data/datasources/account_remote_datasource.dart';
import 'account_injection.dart';

class AccountDatasourceInjection {
  static void inject() {
    accountInjection
      ..registerLazySingleton<ApiClient>(() => injection<ApiClient>())
      ..registerLazySingleton<AccountRemoteDatasource>(
        () => AccountRemoteDatasourceImpl(
          apiClient: accountInjection<ApiClient>(),
        ),
      );
  }
}

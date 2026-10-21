/// Verify datasource DI.
///
/// Re-registers the root [ApiClient] into [verifyInjection] — the *same
/// instance*, a closure over `injection<ApiClient>()`, not a second client
/// (DI-3). Load-bearing rather than tidy even though **both verify endpoints
/// are anonymous**: the `anonymous: true` flag rides each call
/// (`verify_remote_datasource.dart`), but the envelope unwrapping, error
/// mapping and base URL the calls need all live inside the root client. The
/// precedent is `DocumentsDatasourceInjection`, which is
/// `NotificationsDatasourceInjection`'s.
library;

import '../../../core/di/dependency_injection.dart';
import '../../../core/network/api_client.dart';
import '../data/datasources/verify_remote_datasource.dart';
import 'verify_injection.dart';

class VerifyDatasourceInjection {
  static void inject() {
    verifyInjection
      ..registerLazySingleton<ApiClient>(() => injection<ApiClient>())
      ..registerLazySingleton<VerifyRemoteDatasource>(
        () => VerifyRemoteDatasourceImpl(
          apiClient: verifyInjection<ApiClient>(),
        ),
      );
  }
}

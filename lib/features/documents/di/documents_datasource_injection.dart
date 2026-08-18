/// Documents datasource DI.
///
/// Re-registers the root [ApiClient] into [documentsInjection] — the *same
/// instance*, a closure over `injection<ApiClient>()`, not a second client
/// (DI-3). Load-bearing rather than tidy: **both certificate calls are
/// authenticated** (neither carries `anonymous: true` in `endpoints.ts`), so
/// they need the Auth/Refresh interceptor chain that lives inside the root
/// client. The precedent is `NotificationsDatasourceInjection`, which is
/// `AuthDatasourceInjection`'s.
library;

import '../../../core/di/dependency_injection.dart';
import '../../../core/network/api_client.dart';
import '../data/datasources/documents_remote_datasource.dart';
import 'documents_injection.dart';

class DocumentsDatasourceInjection {
  static void inject() {
    documentsInjection
      ..registerLazySingleton<ApiClient>(() => injection<ApiClient>())
      ..registerLazySingleton<DocumentsRemoteDatasource>(
        () => DocumentsRemoteDatasourceImpl(
          apiClient: documentsInjection<ApiClient>(),
        ),
      );
  }
}

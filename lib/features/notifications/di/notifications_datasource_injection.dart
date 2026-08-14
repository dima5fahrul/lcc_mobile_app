/// Notification datasource DI.
///
/// Re-registers the root [ApiClient] into [notificationsInjection] — the *same
/// instance*, a closure over `injection<ApiClient>()`, not a second client
/// (DI-3). Load-bearing rather than tidy here: **all four notification calls
/// are authenticated** (none carries `anonymous: true` in `endpoints.ts`), so
/// they need the Auth/Refresh interceptor chain that lives inside the root
/// client. The precedent is `AuthDatasourceInjection`
/// (`dependency_injection.dart:128-129`).
library;

import '../../../core/di/dependency_injection.dart';
import '../../../core/network/api_client.dart';
import '../data/datasources/notification_remote_datasource.dart';
import 'notifications_injection.dart';

class NotificationsDatasourceInjection {
  static void inject() {
    notificationsInjection
      ..registerLazySingleton<ApiClient>(() => injection<ApiClient>())
      ..registerLazySingleton<NotificationRemoteDatasource>(
        () => NotificationRemoteDatasourceImpl(
          apiClient: notificationsInjection<ApiClient>(),
        ),
      );
  }
}

/// Chat datasource DI.
///
/// Re-registers the root [ApiClient] into [chatInjection] — the *same
/// instance*, a closure over `injection<ApiClient>()`, not a second client
/// (DI-3). Load-bearing rather than tidy: **all six chat calls are
/// authenticated** (none carries `anonymous: true` in `endpoints.ts`), so they
/// need the Auth/Refresh interceptor chain that lives inside the root client.
/// The precedent is `AuthDatasourceInjection`
/// (`dependency_injection.dart:128-129`).
library;

import '../../../core/di/dependency_injection.dart';
import '../../../core/network/api_client.dart';
import '../data/datasources/chat_remote_datasource.dart';
import 'chat_injection.dart';

class ChatDatasourceInjection {
  static void inject() {
    chatInjection
      ..registerLazySingleton<ApiClient>(() => injection<ApiClient>())
      ..registerLazySingleton<ChatRemoteDatasource>(
        () => ChatRemoteDatasourceImpl(apiClient: chatInjection<ApiClient>()),
      );
  }
}

/// Family-book datasource DI.
///
/// Re-registers the root [ApiClient] into [familyBookInjection] so every call
/// site in this feature resolves from one container, then registers the
/// datasource on top of it. The client is the *same instance* the root holds —
/// a closure over `injection<ApiClient>()`, not a second client — which is what
/// keeps DI-3 true and what makes both `/me/family-book` calls carry the Auth
/// and Refresh interceptors they need.
///
/// Both of this feature's endpoints are authenticated, so unlike the service
/// catalogue and news there is no `anonymous: true` call here for which the
/// shared client would be merely convenient: it is required.
library;

import '../../../core/di/dependency_injection.dart';
import '../../../core/network/api_client.dart';
import '../data/datasources/family_book_remote_datasource.dart';
import 'family_book_injection.dart';

class FamilyBookDatasourceInjection {
  static void inject() {
    familyBookInjection
      ..registerLazySingleton<ApiClient>(() => injection<ApiClient>())
      ..registerLazySingleton<FamilyBookRemoteDatasource>(
        () => FamilyBookRemoteDatasourceImpl(
          apiClient: familyBookInjection<ApiClient>(),
        ),
      );
  }
}

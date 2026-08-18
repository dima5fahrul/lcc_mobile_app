/// Reference datasource DI — two datasources over **one** shared `ApiClient`.
///
/// The client is re-registered into [referenceInjection] as a closure over
/// `injection<ApiClient>()`, so it is the *same instance* the root holds. That
/// is what keeps DI-3 true: this feature builds no second `Dio`.
///
/// Every endpoint here is `anonymous: true` in `endpoints.ts` (`:186`, `:216`,
/// `:223`, `:248`), so the feature never needs the Auth/Refresh interceptors —
/// and it shares them anyway rather than standing up its own client, because
/// DI-3 admits no exception for "this feature happens not to need a token".
library;

import '../../../core/di/dependency_injection.dart';
import '../../../core/network/api_client.dart';
import '../data/datasources/location_remote_datasource.dart';
import '../data/datasources/prerequisite_record_remote_datasource.dart';
import '../data/datasources/reference_list_remote_datasource.dart';
import 'reference_injection.dart';

class ReferenceDatasourceInjection {
  static void inject() {
    referenceInjection
      ..registerLazySingleton<ApiClient>(() => injection<ApiClient>())
      ..registerLazySingleton<ReferenceListRemoteDatasource>(
        () => ReferenceListRemoteDatasourceImpl(
          apiClient: referenceInjection<ApiClient>(),
        ),
      )
      ..registerLazySingleton<LocationRemoteDatasource>(
        () => LocationRemoteDatasourceImpl(
          apiClient: referenceInjection<ApiClient>(),
        ),
      )
      // F3 — the FR-11 record picker (`ssd.md` § 11.4). The **one datasource
      // in this feature that is not anonymous**: `endpoints.ts:194-198` carries
      // no `anonymous: true`, and the list is scoped to the signed-in
      // citizen's own records, which is why it answers `data: []`.
      ..registerLazySingleton<PrerequisiteRecordRemoteDatasource>(
        () => PrerequisiteRecordRemoteDatasourceImpl(
          apiClient: referenceInjection<ApiClient>(),
        ),
      );
  }
}

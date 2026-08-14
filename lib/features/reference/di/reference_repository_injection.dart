/// Reference repository DI. Lazy (DI-2), over the two datasources registered
/// before it.
///
/// **The lazy singleton is load-bearing here, not conventional.** The in-flight
/// de-duplication map lives on the instance, so a `registerFactory` would hand
/// every caller a fresh empty map and Birth's 19 concurrent lookups would all
/// miss it — `F0-AC-11`'s "same instance on a second call" clause is what
/// discharges DI-2 behaviourally rather than textually.
library;

import '../data/datasources/location_remote_datasource.dart';
import '../data/datasources/reference_list_remote_datasource.dart';
import '../data/repositories/reference_repository_impl.dart';
import '../domain/repositories/reference_repository.dart';
import 'reference_injection.dart';

class ReferenceRepositoryInjection {
  static void inject() {
    referenceInjection.registerLazySingleton<ReferenceRepository>(
      () => ReferenceRepositoryImpl(
        referenceLists: referenceInjection<ReferenceListRemoteDatasource>(),
        locations: referenceInjection<LocationRemoteDatasource>(),
      ),
    );
  }
}

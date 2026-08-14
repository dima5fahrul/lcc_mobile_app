/// Application repository DI. Lazy (DI-2), over the datasource registered
/// before it.
///
/// Registered against **`ApplicationRepository`, the interface**, and not
/// against `ApplicationRepositoryImpl` — `help_repository_injection.dart:11`'s
/// pattern. That is load-bearing here rather than conventional: B6b and B7b
/// both resolve out of this container from their own features, and a
/// registration typed on the impl would make every cross-container consumer
/// depend on `features/application/data/**`, which G-L3 forbids
/// (`B7-AC-8` measures exactly that edge).
library;

import '../data/datasources/application_remote_datasource.dart';
import '../data/repositories/application_repository_impl.dart';
import '../domain/repositories/application_repository.dart';
import 'application_injection.dart';

class ApplicationRepositoryInjection {
  static void inject() {
    applicationInjection.registerLazySingleton<ApplicationRepository>(
      () => ApplicationRepositoryImpl(
        remote: applicationInjection<ApplicationRemoteDatasource>(),
      ),
    );
  }
}

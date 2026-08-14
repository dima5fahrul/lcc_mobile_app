/// Reference use-case DI — one lazy singleton (DI-2), one use case.
library;

import '../domain/repositories/reference_repository.dart';
import '../domain/usecases/get_lookup_options.dart';
import 'reference_injection.dart';

class ReferenceUsecaseInjection {
  static void inject() {
    referenceInjection.registerLazySingleton<GetLookupOptions>(
      () => GetLookupOptions(repository: referenceInjection<ReferenceRepository>()),
    );
  }
}

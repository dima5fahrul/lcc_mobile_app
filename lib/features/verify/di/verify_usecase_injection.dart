/// Verify use-case DI — the two lazy singletons (DI-2), one per repository
/// method.
library;

import '../domain/repositories/verify_repository.dart';
import '../domain/usecases/verify_usecases.dart';
import 'verify_injection.dart';

class VerifyUsecaseInjection {
  static void inject() {
    verifyInjection
      ..registerLazySingleton<VerifyByCode>(
        () => VerifyByCode(
          repository: verifyInjection<VerifyRepository>(),
        ),
      )
      ..registerLazySingleton<VerifyDocumentHash>(
        () => VerifyDocumentHash(
          repository: verifyInjection<VerifyRepository>(),
        ),
      );
  }
}

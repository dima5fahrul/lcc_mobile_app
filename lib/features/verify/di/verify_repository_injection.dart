/// Verify repository DI. Lazy (DI-2), over the datasource registered
/// before it.
library;

import '../data/datasources/verify_remote_datasource.dart';
import '../data/repositories/verify_repository_impl.dart';
import '../domain/repositories/verify_repository.dart';
import 'verify_injection.dart';

class VerifyRepositoryInjection {
  static void inject() {
    verifyInjection.registerLazySingleton<VerifyRepository>(
      () => VerifyRepositoryImpl(
        remote: verifyInjection<VerifyRemoteDatasource>(),
      ),
    );
  }
}

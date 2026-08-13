/// Help repository DI. Lazy (DI-2), over the datasource registered before it.
library;

import '../data/datasources/help_remote_datasource.dart';
import '../data/repositories/help_repository_impl.dart';
import '../domain/repositories/help_repository.dart';
import 'help_injection.dart';

class HelpRepositoryInjection {
  static void inject() {
    helpInjection.registerLazySingleton<HelpRepository>(
      () => HelpRepositoryImpl(remote: helpInjection<HelpRemoteDatasource>()),
    );
  }
}

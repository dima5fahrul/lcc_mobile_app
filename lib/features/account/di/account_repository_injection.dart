/// Account repository DI. Lazy (DI-2), over the datasource registered before
/// it.
library;

import '../data/datasources/account_remote_datasource.dart';
import '../data/repositories/account_repository_impl.dart';
import '../domain/repositories/account_repository.dart';
import 'account_injection.dart';

class AccountRepositoryInjection {
  static void inject() {
    accountInjection.registerLazySingleton<AccountRepository>(
      () => AccountRepositoryImpl(
        remote: accountInjection<AccountRemoteDatasource>(),
      ),
    );
  }
}

/// Wallet repository DI. Lazy (DI-2), over the datasource registered before it.
library;

import '../data/datasources/wallet_remote_datasource.dart';
import '../data/repositories/wallet_repository_impl.dart';
import '../domain/repositories/wallet_repository.dart';
import 'wallet_injection.dart';

class WalletRepositoryInjection {
  static void inject() {
    walletInjection.registerLazySingleton<WalletRepository>(
      () => WalletRepositoryImpl(
        remote: walletInjection<WalletRemoteDatasource>(),
      ),
    );
  }
}

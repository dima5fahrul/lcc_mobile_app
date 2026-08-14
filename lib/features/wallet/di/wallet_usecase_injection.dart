/// Wallet use-case DI — six lazy singletons (DI-2), one per use case.
///
/// [GetTransaction] is registered even though nothing under `presentation/`
/// resolves it (`B6-AC-15`). specs.md § 6.4 rules the *transport* in and the UI
/// out; leaving it unregistered would make the endpoint reachable only by
/// constructing the use case by hand, which is a different thing from "ported
/// and unused" and would make B7's first use of it a change to this file rather
/// than a call.
library;

import '../domain/repositories/wallet_repository.dart';
import '../domain/usecases/wallet_usecases.dart';
import 'wallet_injection.dart';

class WalletUsecaseInjection {
  static void inject() {
    walletInjection
      ..registerLazySingleton<GetWalletOverview>(
        () => GetWalletOverview(
          repository: walletInjection<WalletRepository>(),
        ),
      )
      ..registerLazySingleton<GetWalletEntries>(
        () => GetWalletEntries(
          repository: walletInjection<WalletRepository>(),
        ),
      )
      ..registerLazySingleton<GetTransactions>(
        () => GetTransactions(
          repository: walletInjection<WalletRepository>(),
        ),
      )
      ..registerLazySingleton<GetTransaction>(
        () => GetTransaction(
          repository: walletInjection<WalletRepository>(),
        ),
      )
      ..registerLazySingleton<TopUpWallet>(
        () => TopUpWallet(
          repository: walletInjection<WalletRepository>(),
        ),
      )
      ..registerLazySingleton<GetPaymentMethods>(
        () => GetPaymentMethods(
          repository: walletInjection<WalletRepository>(),
        ),
      );
  }
}

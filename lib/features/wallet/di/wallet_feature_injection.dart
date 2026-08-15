/// Wallet feature injection entry point.
///
/// Ordering inside: datasource → repository → usecase → bloc, mirroring
/// `NotificationsFeatureInjection.init()`.
///
/// ## Why `registerFactory` and not a singleton
///
/// `WalletBloc` holds one visit's money: a balance, an account number, a page
/// of receipts and a page of the ledger. A surviving instance would hand all
/// four to whoever signs in next on the same device — a stricter version of the
/// reason `HelpBloc`, `ServiceBloc` and `NotificationsBloc` are factories, and
/// the one SSD § 12's no-persistent-cache ruling exists to protect. The route
/// builder owns the provider (`BlocProvider(create:)`), so the instance is
/// created and **closed** with the visit.
library;

import '../domain/usecases/list_pending_bills.dart';
import '../domain/usecases/pay_application.dart';
import '../domain/usecases/wallet_usecases.dart';
import '../presentation/bloc/wallet_bloc.dart';
import 'wallet_datasource_injection.dart';
import 'wallet_injection.dart';
import 'wallet_repository_injection.dart';
import 'wallet_usecase_injection.dart';

class WalletFeatureInjection {
  static Future<void> init() async {
    WalletDatasourceInjection.inject();
    WalletRepositoryInjection.inject();
    WalletUsecaseInjection.inject();

    walletInjection.registerFactory<WalletBloc>(
      () => WalletBloc(
        getWalletOverview: walletInjection<GetWalletOverview>(),
        getWalletEntries: walletInjection<GetWalletEntries>(),
        getTransactions: walletInjection<GetTransactions>(),
        getPaymentMethods: walletInjection<GetPaymentMethods>(),
        topUpWallet: walletInjection<TopUpWallet>(),
        // B6b. `ListPendingBills` reaches `applicationInjection` through the
        // closure registered in `WalletUsecaseInjection` — see its library doc
        // for the ordering constraint (`ApplicationFeatureInjection.init()`
        // first, which is `DependencyInjection.init()`'s alphabetical order and
        // therefore needs no DI-6 deviation).
        listPendingBills: walletInjection<ListPendingBills>(),
        payApplication: walletInjection<PayApplication>(),
      ),
    );
  }
}

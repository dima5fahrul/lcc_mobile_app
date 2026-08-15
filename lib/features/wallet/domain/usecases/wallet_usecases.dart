/// The wallet's six use cases.
///
/// One file, for the reason `news_usecases.dart` and `home_usecases.dart` give:
/// the *set* is the page's whole data surface, and six files of five lines each
/// would hide it. The classes stay separate types, so DI registers six lazy
/// singletons (DI-2) and the BLoC's constructor names exactly what it depends
/// on.
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/paged.dart';
import '../entities/payment_method.dart';
import '../entities/transaction.dart';
import '../entities/wallet_entry.dart';
import '../entities/wallet_overview.dart';
import '../repositories/wallet_repository.dart';

/// `per_page: 10` — the ledger (`WalletPage.tsx:117`) **and** the receipts
/// list (`:111`). One number because the source uses one, not because they
/// were assumed to match.
const int kWalletPageSize = 10;

/// `overview?.min_top_up_lak ?? 10000` — `WalletPage.tsx:556`.
///
/// A **call-site** default, ported to the call site (the top-up sheet), not to
/// the model. specs.md § 5.2 ruling 3: keeping it here means an API that starts
/// sending the bound takes effect with no model change.
const int kTopUpMinFallback = 10000;

/// `overview?.max_top_up_lak ?? 50000000` — `:557`.
const int kTopUpMaxFallback = 50000000;

/// `[50000, 100000, 200000, 500000]` — `WalletPage.tsx:784`, before the
/// `>= min && <= max` filter the sheet applies (`:785`, `B6-AC-52`).
const List<int> kTopUpPresets = <int>[50000, 100000, 200000, 500000];

/// `GET /me/wallet`.
class GetWalletOverview implements UseCase<WalletOverview, NoParams> {
  const GetWalletOverview({required this.repository});

  final WalletRepository repository;

  @override
  Future<Either<Failure, WalletOverview>> call(NoParams params) =>
      repository.getOverview();
}

/// Which page of a paged wallet read.
class WalletPageParams extends Equatable {
  const WalletPageParams({required this.page, this.perPage = kWalletPageSize});

  final int page;
  final int perPage;

  @override
  List<Object?> get props => <Object?>[page, perPage];
}

/// `GET /me/wallet/entries?page=&per_page=10` — the ledger.
class GetWalletEntries
    implements UseCase<PagedRows<WalletEntry>, WalletPageParams> {
  const GetWalletEntries({required this.repository});

  final WalletRepository repository;

  @override
  Future<Either<Failure, PagedRows<WalletEntry>>> call(
    WalletPageParams params,
  ) => repository.getEntries(page: params.page, perPage: params.perPage);
}

/// `GET /me/transactions?page=1&per_page=10` — the receipts list.
class GetTransactions
    implements UseCase<PagedRows<Transaction>, WalletPageParams> {
  const GetTransactions({required this.repository});

  final WalletRepository repository;

  @override
  Future<Either<Failure, PagedRows<Transaction>>> call(
    WalletPageParams params,
  ) => repository.getTransactions(page: params.page, perPage: params.perPage);
}

/// `GET /me/transactions/{receiptNo}`.
///
/// **No caller.** specs.md § 6.4 rules the transport in and the UI out; the
/// endpoint has no call site anywhere in `lcc-app/src/app`. `B6-AC-15` asserts
/// that `grep -rn "meTransaction(" lib/features/wallet/presentation lib/presentation`
/// returns zero, and `wallet_datasource_transport_test.dart` exercises it
/// against a fixture so the transport is proven rather than merely declared.
class GetTransaction implements UseCase<Transaction, String> {
  const GetTransaction({required this.repository});

  final WalletRepository repository;

  @override
  Future<Either<Failure, Transaction>> call(String receiptNo) =>
      repository.getTransaction(receiptNo);
}

/// The top-up body — **exactly two fields**, and both are validated before the
/// request is built (`B6-AC-35`, security-review item 9).
class TopUpParams extends Equatable {
  const TopUpParams({required this.amountLak, required this.methodCode});

  final int amountLak;
  final String methodCode;

  @override
  List<Object?> get props => <Object?>[amountLak, methodCode];
}

/// `POST /me/wallet/topup`.
///
/// **This use case moves real money.** specs.md § 4.4 forbids executing it
/// against any host, with no "small test amount" exemption — the precedent is
/// the authenticated baseline capture, where nobody pressed a certificate
/// submit button because it runs create → update → submit → **pay** in one
/// action. Every test of this path is against a mock transport.
class TopUpWallet implements UseCase<Wallet, TopUpParams> {
  const TopUpWallet({required this.repository});

  final WalletRepository repository;

  @override
  Future<Either<Failure, Wallet>> call(TopUpParams params) => repository.topUp(
    amountLak: params.amountLak,
    methodCode: params.methodCode,
  );
}

/// `GET /payment-methods` — the public catalogue, sent **without** a bearer.
class GetPaymentMethods implements UseCase<List<PaymentMethod>, NoParams> {
  const GetPaymentMethods({required this.repository});

  final WalletRepository repository;

  @override
  Future<Either<Failure, List<PaymentMethod>>> call(NoParams params) =>
      repository.getPaymentMethods();
}

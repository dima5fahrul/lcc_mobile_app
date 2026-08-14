/// `WalletRepositoryImpl` — try the datasource, fold every throw into a
/// [Failure].
///
/// Follows `NotificationRepositoryImpl` and `HelpRepositoryImpl` exactly,
/// including their deviation from the session feature: **no `ApiException`
/// rethrow.** Every mode a wallet read has — offline, 500, a 401 after the
/// token expired, a malformed row — collapses to the same user-visible outcome,
/// which for each of the four regions is that region's own error branch with a
/// retry (`WalletPage.tsx:193-201`, `:299-311`, `:437-450`, `:604-616`).
///
/// [Failure.message] carries the exception text. On the web the same string is
/// what the error branches *render* — `{txQuery.error.message}` (`:439`),
/// `{ledgerQuery.error?.message}` (`:607`), `{methods.error.message}` (`:812`),
/// `{topUp.error.message}` (`:876`) — so unlike the notification bell, the
/// wallet **does** put this text on screen. That is the source's behaviour and
/// it is ported; security-review item 2 is the reason it is called out here:
/// the message must never be composed from a balance, an account number or a
/// receipt number, and nothing below composes it at all — it is whatever the
/// envelope's `message` said.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/paged.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/wallet_entry.dart';
import '../../domain/entities/wallet_overview.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';

class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl({required this.remote});

  final WalletRemoteDatasource remote;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() read) async {
    try {
      return Right<Failure, T>(await read());
    } catch (e) {
      return Left<Failure, T>(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WalletOverview>> getOverview() =>
      _guard(remote.getOverview);

  @override
  Future<Either<Failure, PagedRows<WalletEntry>>> getEntries({
    required int page,
    required int perPage,
  }) =>
      _guard(() => remote.getEntries(page: page, perPage: perPage));

  @override
  Future<Either<Failure, PagedRows<Transaction>>> getTransactions({
    required int page,
    required int perPage,
  }) =>
      _guard(() => remote.getTransactions(page: page, perPage: perPage));

  @override
  Future<Either<Failure, Transaction>> getTransaction(String receiptNo) =>
      _guard(() => remote.getTransaction(receiptNo));

  @override
  Future<Either<Failure, Wallet>> topUp({
    required int amountLak,
    required String methodCode,
  }) =>
      _guard(() => remote.topUp(amountLak: amountLak, methodCode: methodCode));

  @override
  Future<Either<Failure, List<PaymentMethod>>> getPaymentMethods() =>
      _guard(remote.getPaymentMethods);
}

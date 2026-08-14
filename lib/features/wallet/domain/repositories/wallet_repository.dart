/// The wallet's repository contract — six calls over six paths.
///
/// | Source | Method | Endpoint | Auth |
/// |---|---|---|---|
/// | `WalletPage.tsx:101` | [getOverview] | `GET /me/wallet` | yes |
/// | `:116-120` | [getEntries] | `GET /me/wallet/entries` (paged) | yes |
/// | `:110-114` | [getTransactions] | `GET /me/transactions` (paged) | yes |
/// | — (no call site) | [getTransaction] | `GET /me/transactions/{receipt_no}` | yes |
/// | `:733` | [topUp] | `POST /me/wallet/topup` | yes |
/// | `:726`, `PaymentSection.tsx:205` | [getPaymentMethods] | `GET /payment-methods` | **anonymous** |
///
/// [getTransaction] has **no call site in the port source** and is here as
/// transport only — specs.md § 6.4 rules it in and `B6-AC-15` proves nothing
/// under `presentation/` reaches it. That is a deliberate difference from B9a's
/// disposition of `deleteNotification`, and § 6.4 states the ground: B9's
/// objection was that porting it would invent UI, and a receipt lookup by
/// number has no UI to invent.
///
/// **`GET /applications/` and `POST /applications/{id}/pay` are not here.**
/// They are B6b's, they belong to `features/application`, and B6a is provably
/// free of them (`B6-AC-45`).
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/paged.dart';
import '../entities/payment_method.dart';
import '../entities/transaction.dart';
import '../entities/wallet_entry.dart';
import '../entities/wallet_overview.dart';

abstract class WalletRepository {
  /// `GET /me/wallet` — the balance, the account number and the last few
  /// ledger entries in one object.
  Future<Either<Failure, WalletOverview>> getOverview();

  /// `GET /me/wallet/entries?page=&per_page=10` — one page of the ledger.
  Future<Either<Failure, PagedRows<WalletEntry>>> getEntries({
    required int page,
    required int perPage,
  });

  /// `GET /me/transactions?page=1&per_page=10` — the receipts list.
  Future<Either<Failure, PagedRows<Transaction>>> getTransactions({
    required int page,
    required int perPage,
  });

  /// `GET /me/transactions/{receiptNo}` — **transport only**, no consumer.
  Future<Either<Failure, Transaction>> getTransaction(String receiptNo);

  /// `POST /me/wallet/topup` with **exactly** `{amount_lak, method_code}`.
  ///
  /// **This moves real money.** specs.md § 4.4 forbids executing it against any
  /// host; it is proven against a mock transport only.
  ///
  /// The response is `{wallet, entry}` (`endpoints.ts:151`), and the page
  /// **discards it** — `onDone` closes the sheet and calls `refreshMoney()`
  /// (`WalletPage.tsx:559-562`), which re-reads `/me/wallet`. Returning `void`
  /// here would be a narrowing the source does not perform; returning the
  /// refreshed [Wallet] is what the endpoint answers. Nothing renders it.
  Future<Either<Failure, Wallet>> topUp({
    required int amountLak,
    required String methodCode,
  });

  /// `GET /payment-methods` — the public catalogue. **Sent without a bearer**
  /// (`endpoints.ts:362`, `anonymous: true`), which is what lets the top-up
  /// sheet populate for a citizen whose token has expired. `B6-AC-24`.
  Future<Either<Failure, List<PaymentMethod>>> getPaymentMethods();
}

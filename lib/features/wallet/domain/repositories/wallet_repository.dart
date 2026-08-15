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
/// **`GET /applications/` is not here.** It is B7a's, it belongs to
/// `features/application`, and B6b reaches it through a DI closure over
/// `applicationInjection` against B7a's own domain interface rather than
/// growing a second datasource for one endpoint (specs.md § 2.3, amended v1.1).
///
/// ## B6b added a **seventh** call, and it is a write (recorded, not slipped in)
///
/// [payApplication] — `POST /applications/{id}/pay`. This file is a B6a § 3.1
/// row and is **not** in B6b's table, so appending to it is a scope deviation
/// and is named in B6b's hand-back. It is also unavoidable: § 3.1 puts *"the
/// pay POST only"* in `features/wallet/data/**` and puts the `PayApplication`
/// use case in `features/wallet/domain/usecases/`, and **G-L2 forbids a
/// `domain/` use case from importing `data/`** — so the two files the table
/// does list cannot be connected without a contract in this one. The
/// alternative, a second segregated port declared inside the use-case file,
/// would keep the letter of the table by giving one repository implementation
/// two interfaces and the DI container two registrations of the same instance;
/// that is more machinery to hide one honest line.
///
/// Why the pay write is the wallet's and not `features/application`'s at all:
/// `ApplicationRepository`'s own doc parks every write — including `pay` — for
/// B4 and states that **no write path may be added to that interface by B7**.
/// § 3.1 puts it here instead. B4 absorbs it later.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/paged.dart';
import '../entities/payment_method.dart';
import '../entities/payment_result.dart';
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

  /// `POST /applications/{applicationId}/pay` with **exactly**
  /// `{method_code}` — B6b.
  ///
  /// **This debits a real balance against a real case.** specs.md § 4.4 forbids
  /// executing it against any host, absolutely, and forbids manufacturing a
  /// case to have something to charge; it is proven against a mock transport
  /// only, and the criteria it would otherwise satisfy are NOT EVALUATED with
  /// that reason.
  ///
  /// **The `Left` is a [PaymentFailure], not a bare [Failure]** — the only
  /// method on this interface for which that is true, and it is not a
  /// decoration: `PaymentSection.tsx:219` branches the whole terminal render on
  /// `charge.error?.code === "INSUFFICIENT_FUNDS"`, and a `Failure` carrying
  /// only a server-authored, localised message cannot answer that question
  /// without matching prose. Every other read on this interface collapses its
  /// error modes into one retry affordance, which is why they do not need it.
  Future<Either<Failure, PaymentResult>> payApplication({
    required String applicationId,
    required String methodCode,
  });
}

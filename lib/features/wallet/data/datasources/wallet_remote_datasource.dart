/// `WalletRemoteDatasource` — the wallet's HTTP boundary, six calls over three
/// envelope shapes.
///
/// | Call | Verb | Envelope | Auth |
/// |---|---|---|---|
/// | [getOverview] | GET `/me/wallet` | object | Bearer |
/// | [getEntries] | GET `/me/wallet/entries` | **paged** | Bearer |
/// | [getTransactions] | GET `/me/transactions` | **paged** | Bearer |
/// | [getTransaction] | GET `/me/transactions/{receipt_no}` | object | Bearer |
/// | [topUp] | POST `/me/wallet/topup` | object | Bearer |
/// | [getPaymentMethods] | GET `/payment-methods` | **array** | **anonymous** |
///
/// ## Why every read asks Dio for `dynamic`
///
/// `help_remote_datasource.dart`'s header carries the full account and it is
/// not style: `ApiClient._send<T>` forwards `T` to `_dio.get<T>()`, Dio casts
/// the decoded body to `T`, and the decoded body is always the **envelope
/// map**. `T = List<dynamic>` therefore throws *before* `_unwrap` runs and
/// surfaces as `NETWORK_ERROR` — a request that reached the server, reported as
/// offline. One rule, no exception to remember.
///
/// ## `/payment-methods` is the one anonymous call in the batch
///
/// `endpoints.ts:362` marks it `anonymous: true`, and [ApiClient.get]'s
/// `anonymous:` flag is what reaches `RequestOptions.extra['anonymous']` and
/// makes `AuthInterceptor` skip the bearer. It is load-bearing rather than
/// tidy: the top-up sheet must populate for a citizen whose access token has
/// just expired, and the signed-out wallet render — the only Tier 3 reference
/// this batch has — depends on the catalogue being reachable with no session.
/// `B6-AC-24` asserts it on the **recorded request**, not on the constant,
/// because a constant marked anonymous that is then sent through an
/// authenticated path is precisely the defect that would not show up in a
/// review.
///
/// ## `topUp` is the only write, and it is never executed against a host
///
/// specs.md § 4.4 forbids `POST /me/wallet/topup` against **any** host,
/// absolutely, with no small-test-amount exemption — it credits a real staging
/// balance. Every test of this method runs against `http_mock_adapter`.
/// [WalletRemoteDatasourceImpl.topUp] builds the body from two already-validated
/// scalars and adds nothing to it: `B6-AC-33` asserts the captured body has
/// **exactly** `amount_lak` and `method_code` — no `currency`, no `note`, no
/// idempotency key.
///
/// ## Where a paged read's `meta` goes
///
/// `ApiClient.requestPaged` answers `Paged<T>` — a **data**-layer type
/// (`core/network/envelope.dart`), which `domain/` may not import (G-L2). It is
/// narrowed here to `PagedRows<T>`, the wallet's own domain page shape, and the
/// narrowing is deliberate about which numbers survive: see `paged.dart`.
library;

import '../../../../core/constant/api_endpoint.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/paged.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/payment_result.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/wallet_entry.dart';
import '../../domain/entities/wallet_overview.dart';
import '../models/wallet_wire.dart';

abstract class WalletRemoteDatasource {
  Future<WalletOverview> getOverview();

  Future<PagedRows<WalletEntry>> getEntries({
    required int page,
    required int perPage,
  });

  Future<PagedRows<Transaction>> getTransactions({
    required int page,
    required int perPage,
  });

  Future<Transaction> getTransaction(String receiptNo);

  Future<Wallet> topUp({required int amountLak, required String methodCode});

  Future<List<PaymentMethod>> getPaymentMethods();

  /// POST `/applications/{id}/pay` — **B6b, and the second write.**
  ///
  /// It lives on the *wallet's* datasource and not on
  /// `features/application/data/`, which is deliberate and is B7a's ruling as
  /// much as B6's: `ApplicationRepository`'s own doc parks every write —
  /// `create`, `update`, `submit`, `addAttachment`, **`pay`** — for B4, and
  /// says no write path may be added to that interface. specs.md § 3.1 puts
  /// *"the pay POST only"* in `features/wallet/data/**` for exactly that
  /// reason. The `/applications` **read** goes the other way: it is B7a's, and
  /// B6b reaches it through a DI closure over `applicationInjection` rather
  /// than adding a second datasource for one endpoint (§ 2.3, amended v1.1).
  Future<PaymentResult> payApplication({
    required String applicationId,
    required String methodCode,
  });
}

class WalletRemoteDatasourceImpl implements WalletRemoteDatasource {
  const WalletRemoteDatasourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<WalletOverview> getOverview() async {
    final dynamic data = await apiClient.get<dynamic>(ApiEndpoint.meWallet);
    return walletOverviewFrom(_object(data, 'GET /me/wallet'));
  }

  @override
  Future<PagedRows<WalletEntry>> getEntries({
    required int page,
    required int perPage,
  }) async {
    final Paged<dynamic> result = await apiClient.requestPaged<dynamic>(
      ApiEndpoint.meWalletEntries,
      query: <String, dynamic>{'page': page, 'per_page': perPage},
    );
    return _pageOf(result, walletEntryFrom);
  }

  @override
  Future<PagedRows<Transaction>> getTransactions({
    required int page,
    required int perPage,
  }) async {
    final Paged<dynamic> result = await apiClient.requestPaged<dynamic>(
      ApiEndpoint.meTransactions,
      query: <String, dynamic>{'page': page, 'per_page': perPage},
    );
    return _pageOf(result, transactionFrom);
  }

  @override
  Future<Transaction> getTransaction(String receiptNo) async {
    final dynamic data = await apiClient.get<dynamic>(
      ApiEndpoint.meTransaction(receiptNo),
    );
    return transactionFrom(_object(data, 'GET /me/transactions/:receipt_no'));
  }

  @override
  Future<Wallet> topUp({
    required int amountLak,
    required String methodCode,
  }) async {
    // **Exactly two keys** (`B6-AC-33`). `WalletPage.tsx:733,746` sends
    // `{amount_lak, method_code}` and nothing else, and the assertion is on
    // this literal because anything a well-meaning implementer might add here —
    // a currency, a client-side idempotency key — would be invisible to every
    // fidelity tier that does not read the request body.
    final dynamic data = await apiClient.post<dynamic>(
      ApiEndpoint.meWalletTopUp,
      body: <String, dynamic>{
        'amount_lak': amountLak,
        'method_code': methodCode,
      },
    );

    // The response is `{wallet, entry}` (`endpoints.ts:151`). The page discards
    // it and re-reads `/me/wallet` (`WalletPage.tsx:559-562`), so a response
    // whose `wallet` block is missing is not an error here — it is a value
    // nothing renders. `Wallet.empty` rather than a throw keeps a successful
    // credit from surfacing as a failed one.
    final Map<String, dynamic> object = _object(data, 'POST /me/wallet/topup');
    final Object? wallet = object['wallet'];
    return wallet is Map<String, dynamic> ? walletFrom(wallet) : Wallet.empty;
  }

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async {
    // `anonymous: true` — `endpoints.ts:362`. See the library doc.
    final dynamic data = await apiClient.get<dynamic>(
      ApiEndpoint.paymentMethods,
      anonymous: true,
    );
    // A **plain array**, not a paged envelope (specs.md § 5.1).
    return rowsOf(data, paymentMethodFrom);
  }

  @override
  Future<PaymentResult> payApplication({
    required String applicationId,
    required String methodCode,
  }) async {
    // **Exactly one key** (`B6-AC-36`) — `endpoints.ts:356` sends
    // `{method_code}` and nothing else, and it is the method's **code**, never
    // its id, its label or its kind. The three near-misses are named because
    // all four are strings on `PaymentMethod` and a mix-up is a 422 at best
    // and a charge against the wrong rail at worst.
    //
    // No idempotency key. Adding one would be a *better* client than the web
    // has, on the one request in this app that moves a citizen's money —
    // exactly the class of silent improvement specs.md § 6.11 forbids, and
    // invisible to every fidelity tier that does not read the request body.
    // Tier 0 reads it (`B6-AC-36`).
    final dynamic data = await apiClient.post<dynamic>(
      ApiEndpoint.applicationPay(applicationId),
      body: <String, dynamic>{'method_code': methodCode},
    );

    return paymentResultFrom(_object(data, 'POST /applications/:id/pay'));
  }

  /// The one place this datasource refuses to be total.
  ///
  /// `wallet_wire.dart`'s readers tolerate every missing *field*, because no
  /// `/me/*` response has ever been recorded and a page rendering `0 ₭` is
  /// diagnosable where a thrown parse is not. A `data` that is not an object at
  /// all is a different thing: it is a broken backend, not an empty wallet, and
  /// silently answering an empty overview would hide it behind the exact zero
  /// state the only available test citizen produces anyway.
  Map<String, dynamic> _object(dynamic data, String what) {
    if (data is Map<String, dynamic>) return data;
    throw FormatException(
      '$what answered a non-object payload: '
      '${data.runtimeType}',
    );
  }

  /// `Paged<dynamic>` (data) → [PagedRows] (domain).
  ///
  /// `whereType` rather than a cast: one malformed row costs that row, not the
  /// page — the disposition `notification_remote_datasource.dart` takes and for
  /// the same reason.
  PagedRows<T> _pageOf<T>(
    Paged<dynamic> result,
    T Function(Map<String, dynamic>) parse,
  ) {
    return PagedRows<T>(
      rows: result.data
          .whereType<Map<String, dynamic>>()
          .map(parse)
          .toList(growable: false),
      page: result.meta.page,
      totalPages: result.meta.totalPages,
      hasNext: result.meta.hasNext,
      hasPrev: result.meta.hasPrev,
    );
  }
}

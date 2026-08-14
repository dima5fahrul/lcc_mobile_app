/// `WalletRemoteDatasourceImpl` — the wallet's HTTP boundary.
///
/// ## Why this file drives a REAL `ApiClient` over a recording transport
///
/// Every other datasource test in this tree mocks `ApiClient` and verifies the
/// call. That is sufficient when the criterion is *which endpoint, which body*.
/// It is **not** sufficient for `B6-AC-24`, which says the anonymity of
/// `/payment-methods` must be asserted *"on the recorded request, not on the
/// constant"* — and a `verify(() => apiClient.get(..., anonymous: true))`
/// asserts the constant. The defect that criterion is aimed at is a call
/// correctly marked anonymous which is then sent down an authenticated path;
/// only the bytes that left the client can distinguish those.
///
/// So: a real `Dio` with the real `AuthInterceptor`, a seeded token, and
/// [RecordingHttpAdapter] capturing `RequestOptions`. `Authorization` present
/// or absent is then a fact about the request, not about the argument list.
///
/// ## § 4.4 — no request in this file reaches a host
///
/// `POST /me/wallet/topup` credits a real staging balance and specs.md § 4.4
/// forbids executing it against **any** host, with no small-amount exemption.
/// The transport here is an in-process adapter; `kTestBaseUrl` is
/// `api.test.invalid`, a reserved-by-RFC-2606 name that cannot resolve even if
/// the adapter were removed. That second property is deliberate: it makes the
/// prohibition survive a future edit that swaps the adapter out.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/paged.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/payment_method.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/transaction.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/wallet_entry.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/wallet_overview.dart';

import '../../../../helpers/core_test_helper.dart';
import '../../wallet_fixtures.dart';

void main() {
  late Map<String, String> store;
  late StorageService storage;
  late RecordingHttpAdapter adapter;
  late WalletRemoteDatasourceImpl datasource;

  /// Boots the client with [responder] as the whole transport, and a token
  /// already in storage so `AuthInterceptor` has something to attach. Without
  /// the seed, "no Authorization header" would be trivially true everywhere and
  /// `B6-AC-24` would pass vacuously — the Capability Rule failure mode.
  void boot(ScriptedResponder responder) {
    store = <String, String>{StorageKeys.accessToken: 'seeded-access-token'};
    storage = inMemoryStorageService(store);
    adapter = RecordingHttpAdapter(responder);
    datasource = WalletRemoteDatasourceImpl(
      apiClient: ApiClient(
        dio: buildTestDio(storage: storage, adapter: adapter),
        storage: storage,
      ),
    );
  }

  void bootWith(Object? body) =>
      boot((RequestOptions _, int __) => jsonResponse(body));

  RequestOptions sent() => adapter.requests.single;

  // ───────────────────────────────────────────────────────────────────────────
  // B6-AC-24 — anonymity, asserted on the recorded request
  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-24 the Authorization header, as it actually left the client', () {
    test('the seed really does attach — the control that makes this non-vacuous',
        () async {
      // If this test ever goes green-by-accident (no token attached anywhere),
      // every "absent" assertion below becomes meaningless. It is the guard on
      // the guard.
      bootWith(okEnvelope(tWalletOverviewJson()));

      await datasource.getOverview();

      expect(sent().headers['Authorization'], 'Bearer seeded-access-token');
    });

    test('/payment-methods is sent WITHOUT an Authorization header', () async {
      // `endpoints.ts:362` marks it `anonymous: true`. The top-up sheet must
      // populate for a citizen whose access token has just expired, and the
      // signed-out wallet — the only Tier 3 reference this batch has — depends
      // on the catalogue being reachable with no session at all.
      bootWith(okEnvelope(<Map<String, dynamic>>[tPaymentMethodJson()]));

      await datasource.getPaymentMethods();

      expect(sent().path, '/payment-methods');
      expect(sent().headers.containsKey('Authorization'), isFalse);
    });

    test('the other five reads/writes ARE sent with one', () async {
      // Named individually rather than looped so a regression names the call.
      Future<void> check(String label, Future<void> Function() call) async {
        await call();
        expect(
          sent().headers['Authorization'],
          'Bearer seeded-access-token',
          reason: '$label lost its bearer',
        );
      }

      bootWith(okEnvelope(tWalletOverviewJson()));
      await check('GET /me/wallet', datasource.getOverview);

      bootWith(okEnvelope(<Map<String, dynamic>>[], meta: pageMetaJson()));
      await check(
        'GET /me/wallet/entries',
        () => datasource.getEntries(page: 1, perPage: 10),
      );

      bootWith(okEnvelope(<Map<String, dynamic>>[], meta: pageMetaJson()));
      await check(
        'GET /me/transactions',
        () => datasource.getTransactions(page: 1, perPage: 10),
      );

      bootWith(okEnvelope(tTransactionJson()));
      await check(
        'GET /me/transactions/:receipt_no',
        () => datasource.getTransaction('RCP-1'),
      );

      bootWith(okEnvelope(<String, dynamic>{'wallet': tWalletJson()}));
      await check(
        'POST /me/wallet/topup',
        () => datasource.topUp(amountLak: 50000, methodCode: 'bcel'),
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B6-AC-33 — the one write's body, exactly two keys
  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-33 POST /me/wallet/topup body', () {
    setUp(() => bootWith(<String, dynamic>{
          'success': true,
          'message': 'OK',
          'data': <String, dynamic>{'wallet': tWalletJson(balanceLak: 70000)},
        }));

    test('carries EXACTLY {amount_lak, method_code} — no third key', () async {
      await datasource.topUp(amountLak: 50000, methodCode: 'bcel');

      final Map<String, dynamic> body =
          jsonDecode(jsonEncode(sent().data)) as Map<String, dynamic>;

      // `hasLength` and not a key-by-key check: the criterion is that nothing
      // was ADDED. A currency, a note or a client-minted idempotency key would
      // be invisible to every fidelity tier that does not read the body, and
      // an assertion listing only the two expected keys would not see them.
      expect(body, hasLength(2));
      expect(body, <String, dynamic>{
        'amount_lak': 50000,
        'method_code': 'bcel',
      });
    });

    test('amount_lak is a JSON number, not a string', () async {
      await datasource.topUp(amountLak: 50000, methodCode: 'bcel');

      final Map<String, dynamic> body =
          jsonDecode(jsonEncode(sent().data)) as Map<String, dynamic>;
      expect(body['amount_lak'], isA<int>());
    });

    test('it is a POST, to /me/wallet/topup, once', () async {
      await datasource.topUp(amountLak: 50000, methodCode: 'bcel');

      expect(sent().method, 'POST');
      expect(sent().path, '/me/wallet/topup');
      expect(adapter.callCount, 1);
    });

    test('a response with no wallet block yields Wallet.empty, not a throw',
        () async {
      // The page discards the response and re-reads `/me/wallet`
      // (`WalletPage.tsx:559-562`), so a missing `wallet` is a value nothing
      // renders — not a failed credit. Throwing here would surface a SUCCESSFUL
      // top-up as an error and invite the citizen to pay twice.
      bootWith(okEnvelope(<String, dynamic>{}));

      expect(await datasource.topUp(amountLak: 1, methodCode: 'bcel'),
          Wallet.empty);
    });

    test('the returned wallet is parsed when it IS present', () async {
      final Wallet w = await datasource.topUp(amountLak: 50000, methodCode: 'bcel');
      expect(w.balanceLak, 70000);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Query parameters and envelopes
  // ───────────────────────────────────────────────────────────────────────────
  group('paged reads', () {
    test('/me/wallet/entries sends page and per_page as given', () async {
      bootWith(okEnvelope(<Map<String, dynamic>>[], meta: pageMetaJson()));

      await datasource.getEntries(page: 3, perPage: 10);

      expect(sent().path, '/me/wallet/entries');
      expect(sent().queryParameters, <String, dynamic>{'page': 3, 'per_page': 10});
    });

    test('/me/transactions sends page and per_page as given', () async {
      bootWith(okEnvelope(<Map<String, dynamic>>[], meta: pageMetaJson()));

      await datasource.getTransactions(page: 1, perPage: 10);

      expect(sent().path, '/me/transactions');
      expect(sent().queryParameters, <String, dynamic>{'page': 1, 'per_page': 10});
    });

    test('meta narrows onto PagedRows — page, totalPages, hasNext, hasPrev',
        () async {
      bootWith(okEnvelope(
        <Map<String, dynamic>>[tWalletEntryJson()],
        meta: pageMetaJson(
          page: 2,
          totalPages: 5,
          hasNext: true,
          hasPrev: true,
        ),
      ));

      final PagedRows<WalletEntry> page =
          await datasource.getEntries(page: 2, perPage: 10);

      expect(page.page, 2);
      expect(page.totalPages, 5);
      expect(page.hasNext, isTrue);
      expect(page.hasPrev, isTrue);
      expect(page.rows, hasLength(1));
    });

    test('ONE malformed row costs that row, not the page', () async {
      // `whereType` rather than a cast — the disposition
      // `notification_remote_datasource.dart` takes. A wallet that refuses to
      // render because one historical entry is odd is worse than one that
      // renders the rest.
      bootWith(okEnvelope(
        <dynamic>[tWalletEntryJson(), 'not-an-object', 42],
        meta: pageMetaJson(),
      ));

      final PagedRows<WalletEntry> page =
          await datasource.getEntries(page: 1, perPage: 10);

      expect(page.rows, hasLength(1));
    });
  });

  group('object reads', () {
    test('/me/wallet parses the overview', () async {
      bootWith(okEnvelope(tWalletOverviewJson(balanceLak: 20000)));

      final WalletOverview o = await datasource.getOverview();

      expect(sent().path, '/me/wallet');
      expect(o.wallet.balanceLak, 20000);
    });

    test('an overview with no wallet block yields Wallet.empty', () async {
      bootWith(okEnvelope(<String, dynamic>{'entry_count': 0}));

      final WalletOverview o = await datasource.getOverview();

      expect(o.wallet, Wallet.empty);
      expect(o.entryCount, 0);
    });

    test('a non-object payload THROWS rather than answering an empty wallet',
        () async {
      // The one place this datasource refuses to be total. A broken backend and
      // an empty wallet must not look the same, because the only test citizen
      // available produces the empty wallet anyway — a silent fallback would
      // hide the breakage behind the state we cannot distinguish it from.
      bootWith(okEnvelope('a string'));

      await expectLater(
        datasource.getOverview(),
        throwsA(isA<FormatException>()),
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B6-AC-15 — the endpoint that is transport-only
  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-15 GET /me/transactions/:receipt_no is ported and tested', () {
    test('it hits the interpolated path and parses a Transaction', () async {
      bootWith(okEnvelope(tTransactionJson(receiptNo: 'RCP-2026-0001')));

      final Transaction t = await datasource.getTransaction('RCP-2026-0001');

      expect(sent().path, '/me/transactions/RCP-2026-0001');
      expect(t.receiptNo, 'RCP-2026-0001');
    });

    test('a receipt number needing escaping is percent-encoded', () async {
      // `Uri.encodeComponent`. Not decorative: a receipt number is server-minted
      // and this is a path segment, so an unescaped `/` would silently retarget
      // the request at a different resource.
      bootWith(okEnvelope(tTransactionJson()));

      await datasource.getTransaction('RCP/2026 0001');

      expect(sent().path, '/me/transactions/RCP%2F2026%200001');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // The anonymous catalogue's own shape
  // ───────────────────────────────────────────────────────────────────────────
  group('GET /payment-methods', () {
    test('parses a PLAIN ARRAY, not a paged envelope', () async {
      bootWith(okEnvelope(<Map<String, dynamic>>[
        tPaymentMethodJson(code: 'bcel'),
        tPaymentMethodJson(code: 'wallet'),
      ]));

      final List<PaymentMethod> rows = await datasource.getPaymentMethods();

      expect(rows.map((PaymentMethod m) => m.code), <String>['bcel', 'wallet']);
    });

    test('a payload that is not a list at all yields EMPTY, not a crash',
        () async {
      bootWith(okEnvelope(<String, dynamic>{'unexpected': true}));

      expect(await datasource.getPaymentMethods(), isEmpty);
    });

    test('settlement and sort_order are on the wire and are NOT modelled',
        () async {
      // security-review item 5: `settlement` carries strings such as
      // `"BCEL · 010-12-00-0045821"`. Not modelling it is what makes it
      // structurally impossible for a bank account number to reach a Flutter
      // log, a persisted state or a BLoC observer.
      bootWith(okEnvelope(<Map<String, dynamic>>[
        <String, dynamic>{
          ...tPaymentMethodJson(),
          'settlement': 'BCEL · 010-12-00-0045821',
          'sort_order': 3,
        },
      ]));

      final PaymentMethod m = (await datasource.getPaymentMethods()).single;

      expect(m.toString(), isNot(contains('010-12-00-0045821')));
      expect(m.toString(), isNot(contains('sort_order')));
    });
  });
}

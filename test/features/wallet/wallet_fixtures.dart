/// Wire-shaped JSON builders and domain-object builders for the wallet tests.
///
/// **Every value here is synthetic** (specs.md § 6.14). No `/me/*` response has
/// ever been recorded from the staging host — the one live test account
/// measures `balance_lak 0`, `recent_entries []`, `entry_count 0` — so these
/// are constructed from `types.ts` and from `WalletPage.tsx`'s reads, not
/// captured. That is exactly why the non-zero balances below matter: they are
/// the only place in this programme where a grouped kip amount exists at all,
/// and the Lao dot separator is otherwise untestable.
///
/// The JSON builders mirror the **wire**, the entity builders mirror the
/// **domain**, and they are kept apart on purpose: a test that means "the
/// datasource parsed this" must start from bytes, and a test that means "the
/// BLoC did this with a parsed value" must not have to re-encode one.
library;

import 'package:lcc_mobile_app/features/wallet/domain/entities/paged.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/payment_method.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/transaction.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/wallet_entry.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/wallet_overview.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Wire JSON — `types.ts` shapes
// ─────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> tWalletJson({
  String id = 'wal-1',
  String accountNo = 'LCC-0000-0001',
  int balanceLak = 0,
}) =>
    <String, dynamic>{
      'id': id,
      'account_no': accountNo,
      'balance_lak': balanceLak,
      'currency': 'LAK',
      'status': 'active',
    };

Map<String, dynamic> tWalletOverviewJson({
  int balanceLak = 0,
  List<Map<String, dynamic>>? recentEntries,
  int entryCount = 0,
  bool canTopUp = true,
  int? minTopUpLak = 10000,
  int? maxTopUpLak = 50000000,
}) =>
    <String, dynamic>{
      'wallet': tWalletJson(balanceLak: balanceLak),
      'recent_entries': recentEntries ?? <Map<String, dynamic>>[],
      'entry_count': entryCount,
      'can_top_up': canTopUp,
      if (minTopUpLak != null) 'min_top_up_lak': minTopUpLak,
      if (maxTopUpLak != null) 'max_top_up_lak': maxTopUpLak,
    };

Map<String, dynamic> tWalletEntryJson({
  String id = 'ent-1',
  String direction = 'credit',
  int amountLak = 20000,
  int balanceAfterLak = 20000,
  String date = '2026-08-06',
}) =>
    <String, dynamic>{
      'id': id,
      'direction': direction,
      'kind': 'topup',
      'amount_lak': amountLak,
      'balance_after_lak': balanceAfterLak,
      'description': <String, dynamic>{'en': 'Top up', 'lo': 'ຕື່ມເງິນ'},
      'reference_no': 'REF-1',
      'method_code': 'bcel',
      'status': 'completed',
      'date': date,
      'occurred_at': '${date}T09:00:00Z',
    };

Map<String, dynamic> tTransactionJson({
  String id = 'txn-1',
  String receiptNo = 'RCP-1',
  int amountLak = 15000,
}) =>
    <String, dynamic>{
      'id': id,
      'receipt_no': receiptNo,
      'application_id': 'app-1',
      'reference_no': 'REF-9',
      'payer_name': 'Somchai',
      'service_code': 'birth-cert',
      'service_name': <String, dynamic>{
        'en': 'Birth certificate',
        'lo': 'ໃບຢັ້ງຢືນການເກີດ',
      },
      'kind': 'payment',
      'method_code': 'bcel',
      'method_label': <String, dynamic>{'en': 'BCEL', 'lo': 'ບີຊີອີແອວ'},
      'amount_lak': amountLak,
      'status': 'paid',
      'paid_at': '2026-08-06T09:00:00Z',
      'date': '2026-08-06',
      'note': null,
    };

Map<String, dynamic> tPaymentMethodJson({
  String code = 'bcel',
  String kind = 'bank',
  bool enabled = true,
  double feePercent = 0,
  String color = '#344EAD',
}) =>
    <String, dynamic>{
      'id': 'pm-$code',
      'code': code,
      'label': <String, dynamic>{'en': code.toUpperCase(), 'lo': code},
      'kind': kind,
      'enabled': enabled,
      'fee_percent': feePercent,
      // English-only on the wire and rendered untranslated — `B6-DIV-2`,
      // Finding J. Deliberately NOT a `Bilingual` here.
      'note': 'Pay from your $code account',
      'logo_url': null,
      'color': color,
    };

/// The seven-row catalogue `B6-AC-53` measures its two filters against.
///
/// **Synthetic, and shaped after the live recording rather than copied from
/// it** — seven rows, `wallet` among them and enabled, one row disabled so the
/// `m.enabled` half of each filter is exercised rather than assumed.
List<Map<String, dynamic>> tPaymentMethodCatalogueJson() =>
    <Map<String, dynamic>>[
      tPaymentMethodJson(code: 'wallet', kind: 'wallet'),
      tPaymentMethodJson(code: 'bcel'),
      tPaymentMethodJson(code: 'ldb'),
      tPaymentMethodJson(code: 'apb'),
      tPaymentMethodJson(code: 'laoqr', kind: 'qr'),
      tPaymentMethodJson(code: 'cash', kind: 'cash'),
      tPaymentMethodJson(code: 'jdb'),
      tPaymentMethodJson(code: 'retired', enabled: false),
    ];

// ─────────────────────────────────────────────────────────────────────────────
// Domain objects
// ─────────────────────────────────────────────────────────────────────────────

Wallet tWallet({int balanceLak = 0, String accountNo = 'LCC-0000-0001'}) =>
    Wallet(
      id: 'wal-1',
      accountNo: accountNo,
      balanceLak: balanceLak,
      currency: 'LAK',
      status: 'active',
    );

WalletOverview tOverview({
  int balanceLak = 0,
  List<WalletEntry> recentEntries = const <WalletEntry>[],
  int entryCount = 0,
  bool canTopUp = true,
  int? minTopUpLak = 10000,
  int? maxTopUpLak = 50000000,
  String accountNo = 'LCC-0000-0001',
}) =>
    WalletOverview(
      wallet: tWallet(balanceLak: balanceLak, accountNo: accountNo),
      recentEntries: recentEntries,
      entryCount: entryCount,
      canTopUp: canTopUp,
      minTopUpLak: minTopUpLak,
      maxTopUpLak: maxTopUpLak,
    );

WalletEntry tEntry({
  String id = 'ent-1',
  String direction = 'credit',
  int amountLak = 20000,
  int balanceAfterLak = 20000,
  String date = '2026-08-06',
}) =>
    WalletEntry(
      id: id,
      direction: direction,
      kind: 'topup',
      amountLak: amountLak,
      balanceAfterLak: balanceAfterLak,
      description: const Bilingual(en: 'Top up', lo: 'ຕື່ມເງິນ'),
      referenceNo: 'REF-1',
      methodCode: 'bcel',
      status: 'completed',
      date: date,
      occurredAt: '${date}T09:00:00Z',
    );

Transaction tTransaction({
  String id = 'txn-1',
  String receiptNo = 'RCP-1',
  int amountLak = 15000,
}) =>
    Transaction(
      id: id,
      receiptNo: receiptNo,
      applicationId: 'app-1',
      referenceNo: 'REF-9',
      payerName: 'Somchai',
      serviceCode: 'birth-cert',
      serviceName: const Bilingual(
        en: 'Birth certificate',
        lo: 'ໃບຢັ້ງຢືນການເກີດ',
      ),
      kind: 'payment',
      methodCode: 'bcel',
      methodLabel: const Bilingual(en: 'BCEL', lo: 'ບີຊີອີແອວ'),
      amountLak: amountLak,
      status: 'paid',
      paidAt: '2026-08-06T09:00:00Z',
      date: '2026-08-06',
      note: null,
    );

PaymentMethod tMethod({
  String code = 'bcel',
  PaymentMethodKind kind = PaymentMethodKind.bank,
  bool enabled = true,
  double feePercent = 0,
  String color = '#344EAD',
}) =>
    PaymentMethod(
      id: 'pm-$code',
      code: code,
      label: Bilingual(en: code.toUpperCase(), lo: code),
      kind: kind,
      enabled: enabled,
      feePercent: feePercent,
      note: 'Pay from your $code account',
      logoUrl: null,
      color: color,
    );

/// The domain-side twin of [tPaymentMethodCatalogueJson].
List<PaymentMethod> tMethodCatalogue() => <PaymentMethod>[
      tMethod(code: 'wallet', kind: PaymentMethodKind.wallet),
      tMethod(code: 'bcel'),
      tMethod(code: 'ldb'),
      tMethod(code: 'apb'),
      tMethod(code: 'laoqr', kind: PaymentMethodKind.qr),
      tMethod(code: 'cash', kind: PaymentMethodKind.cash),
      tMethod(code: 'jdb'),
      tMethod(code: 'retired', enabled: false),
    ];

PagedRows<T> tPage<T>(
  List<T> rows, {
  int page = 1,
  int totalPages = 1,
  bool hasNext = false,
  bool hasPrev = false,
}) =>
    PagedRows<T>(
      rows: rows,
      page: page,
      totalPages: totalPages,
      hasNext: hasNext,
      hasPrev: hasPrev,
    );

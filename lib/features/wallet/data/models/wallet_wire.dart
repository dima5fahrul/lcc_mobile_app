/// The wallet's wire → entity parsing.
///
/// ## Hand-written, and that is a declared deviation from § 5.2's wording
///
/// specs.md § 3.1 and § 5.2 say the models carry *"their own `@JsonKey`
/// mapping"* and ask the implementer to *"verify that `json_serializable`'s
/// default (ignore unknown) is in effect and do not set
/// `disallowUnrecognizedKeys`"*. **This tree does not parse feature payloads
/// that way.** Measured: `features/{news,home,help,notifications,chat,account,
/// reference}/data/models/*_wire.dart` are all hand-written readers;
/// `json_serializable` appears in `lib/` only in `core/network/envelope.dart`.
/// `news_wire.dart:1-10` states the trade and it applies here unchanged — these
/// rows are read once into an entity and never round-tripped, so seven
/// generated models plus seven `.g.dart` files would exist only to be discarded
/// a line later.
///
/// § 5.2's *intent* is satisfied strictly: a hand-written reader ignores
/// unknown keys **by construction**, so the two live-but-undeclared fields —
/// `settlement` and `sort_order` (specs.md § 2.2 Finding H) — cannot reach an
/// entity, and there is no `disallowUnrecognizedKeys` switch to leave off.
///
/// ## Why the readers are re-declared rather than imported
///
/// `features/news/data/models/news_wire.dart` holds byte-identical
/// `stringAt` / `intAt` / `bilingualAt` helpers. Importing them would be a
/// `features/wallet → features/news/data/**` edge, which Cross-Feature
/// Isolation forbids (SSD § 4.3) and **G-L3 measures and fails**. SSD § 4.3
/// names this exact trade: *"wire-format duplication is the accepted cost"*.
///
/// This is **not** the same call as `text(Bilingual?, Lang)`, which lives in
/// `lib/i18n/i18n.dart` — neither a feature nor `data/` — and is imported, not
/// re-implemented. Four B2 features re-implemented that one citing G-L3, and
/// G-L3 has nothing to say about `lib/i18n/`.
///
/// ## Totality is the port, not defensiveness
///
/// **No `/me/wallet`, `/me/wallet/entries` or `/me/transactions` response has
/// ever been recorded** (specs.md § 8.5 gap G-1) — every field name below comes
/// from `types.ts`, which is a client type declaration, not an observation. A
/// missing scalar therefore becomes its zero value rather than a parse failure:
/// a balance card that renders `0 ₭` is visible and diagnosable, where a thrown
/// parse takes the whole page down over one field the API renamed. The one
/// exception is a `data` that is not an object at all, which
/// [WalletRemoteDatasourceImpl] throws on, because that is a broken backend and
/// not an empty wallet.
library;

import '../../../session/domain/entities/bilingual.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/payment_result.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/wallet_entry.dart';
import '../../domain/entities/wallet_overview.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Primitives
// ─────────────────────────────────────────────────────────────────────────────

/// A string field, or `''`.
String stringAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  return raw is String ? raw : '';
}

/// A string field, or **null** when absent or empty.
///
/// The distinction matters here in a way it does not for news: the receipts row
/// prints `tx.paid_at ?? tx.date` (`WalletPage.tsx:506`) and joins
/// `[receipt_no, reference_no, method_label || method_code].filter(Boolean)`
/// (`:489`) — both of which treat `""` and absent identically, which is what
/// `filter(Boolean)` and a JS `??` over an omitted key do.
String? nullableStringAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is! String || raw.isEmpty) return null;
  return raw;
}

/// An integer field, or [fallback].
///
/// Accepts a `double` for the reason `news_wire.dart` gives: JSON has one
/// number type, and a backend that serialises `20000.0` for an amount is
/// sending an integer. **`round()`, not `truncate()`** — a money amount that
/// arrives as `19999.9999` because it went through a float is `20000`, not
/// `19999`.
int intAt(Map<String, dynamic> json, String key, {int fallback = 0}) {
  final Object? raw = json[key];
  if (raw is int) return raw;
  if (raw is double) return raw.round();
  if (raw is String) return int.tryParse(raw) ?? fallback;
  return fallback;
}

/// An integer field, or **null** when absent — for the two top-up bounds,
/// whose absence the *widget* defaults (specs.md § 5.2 ruling 3), so the parser
/// must be able to say "not sent" rather than "zero".
int? nullableIntAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is int) return raw;
  if (raw is double) return raw.round();
  if (raw is String) return int.tryParse(raw);
  return null;
}

/// A fractional field, or `0`. See [PaymentMethod.feePercent] on why
/// `fee_percent` may not go through [intAt].
double doubleAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw) ?? 0;
  return 0;
}

/// A boolean field, or [fallback].
bool boolAt(Map<String, dynamic> json, String key, {bool fallback = false}) {
  final Object? raw = json[key];
  return raw is bool ? raw : fallback;
}

/// `{"en": …, "lo": …}` → both sides; a plain string → that string on **both**
/// sides; anything else → an empty pair.
///
/// Copying a plain string into both sides is faithful, not a shortcut:
/// `text(value, lang)` falls back `wanted || en || lo || ""`, so a
/// single-language field already renders the same text in either locale on the
/// web.
Bilingual bilingualAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is String) return Bilingual(en: raw, lo: raw);
  if (raw is Map<String, dynamic>) {
    return Bilingual(
      en: raw['en'] is String ? raw['en'] as String : '',
      lo: raw['lo'] is String ? raw['lo'] as String : '',
    );
  }
  return const Bilingual(en: '', lo: '');
}

/// [bilingualAt], but **null when the key is absent or both sides are empty**.
///
/// Required by two fallback chains that distinguish "no pair" from "an empty
/// pair": `text(tx.service_name, lang) || tx.service_code || tx.kind` (`:486`)
/// and `text(tx.method_label, lang) || tx.method_code` (`:489`). `text()`
/// answers `''` for both cases, so the chain works either way — but modelling
/// an omitted optional field as a present-but-blank pair would make
/// `Transaction.serviceName == Bilingual(en:'', lo:'')` a state the wire cannot
/// actually produce, and every equality-based BLoC test would encode it.
Bilingual? nullableBilingualAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is String) return raw.isEmpty ? null : Bilingual(en: raw, lo: raw);
  if (raw is! Map<String, dynamic>) return null;
  final String en = raw['en'] is String ? raw['en'] as String : '';
  final String lo = raw['lo'] is String ? raw['lo'] as String : '';
  if (en.isEmpty && lo.isEmpty) return null;
  return Bilingual(en: en, lo: lo);
}

// ─────────────────────────────────────────────────────────────────────────────
// Rows
// ─────────────────────────────────────────────────────────────────────────────

/// `types.ts:542-548` — the wallet itself, nested inside the overview.
Wallet walletFrom(Map<String, dynamic> json) => Wallet(
  id: stringAt(json, 'id'),
  accountNo: stringAt(json, 'account_no'),
  balanceLak: intAt(json, 'balance_lak'),
  currency: stringAt(json, 'currency'),
  status: stringAt(json, 'status'),
);

/// `types.ts:564-571`.
///
/// A missing or malformed `wallet` block yields [Wallet.empty] rather than
/// throwing — the balance card's own zero state, which is what the only
/// available test citizen renders anyway.
WalletOverview walletOverviewFrom(Map<String, dynamic> json) {
  final Object? walletRaw = json['wallet'];
  return WalletOverview(
    wallet: walletRaw is Map<String, dynamic>
        ? walletFrom(walletRaw)
        : Wallet.empty,
    recentEntries: _rowsOf(json['recent_entries'], walletEntryFrom),
    entryCount: intAt(json, 'entry_count'),
    canTopUp: boolAt(json, 'can_top_up'),
    // Nullable: see `WalletOverview`'s library doc and specs.md § 5.2 ruling 3.
    minTopUpLak: nullableIntAt(json, 'min_top_up_lak'),
    maxTopUpLak: nullableIntAt(json, 'max_top_up_lak'),
  );
}

/// `types.ts:550-562`.
WalletEntry walletEntryFrom(Map<String, dynamic> json) => WalletEntry(
  id: stringAt(json, 'id'),
  direction: stringAt(json, 'direction'),
  kind: stringAt(json, 'kind'),
  amountLak: intAt(json, 'amount_lak'),
  balanceAfterLak: intAt(json, 'balance_after_lak'),
  description: bilingualAt(json, 'description'),
  referenceNo: nullableStringAt(json, 'reference_no'),
  methodCode: nullableStringAt(json, 'method_code'),
  status: stringAt(json, 'status'),
  date: stringAt(json, 'date'),
  occurredAt: stringAt(json, 'occurred_at'),
);

/// `types.ts:524-540`.
Transaction transactionFrom(Map<String, dynamic> json) => Transaction(
  id: stringAt(json, 'id'),
  receiptNo: stringAt(json, 'receipt_no'),
  applicationId: nullableStringAt(json, 'application_id'),
  referenceNo: nullableStringAt(json, 'reference_no'),
  payerName: stringAt(json, 'payer_name'),
  serviceCode: stringAt(json, 'service_code'),
  serviceName: nullableBilingualAt(json, 'service_name'),
  kind: stringAt(json, 'kind'),
  methodCode: stringAt(json, 'method_code'),
  methodLabel: nullableBilingualAt(json, 'method_label'),
  amountLak: intAt(json, 'amount_lak'),
  status: stringAt(json, 'status'),
  paidAt: nullableStringAt(json, 'paid_at'),
  date: nullableStringAt(json, 'date'),
  note: nullableStringAt(json, 'note'),
);

/// `types.ts:512-522`, plus the live recording.
///
/// **`settlement` and `sort_order` are on the wire and are not read here** —
/// deliberately (specs.md § 5.2 ruling 2). `settlement` in particular carries
/// strings like `"BCEL · 010-12-00-0045821"`; not modelling it is also why no
/// bank account number can reach a Flutter log or a persisted state
/// (security-review item 5).
PaymentMethod paymentMethodFrom(Map<String, dynamic> json) => PaymentMethod(
  id: stringAt(json, 'id'),
  code: stringAt(json, 'code'),
  label: bilingualAt(json, 'label'),
  kind: PaymentMethodKind.fromWire(stringAt(json, 'kind')),
  enabled: boolAt(json, 'enabled'),
  feePercent: doubleAt(json, 'fee_percent'),
  note: stringAt(json, 'note'),
  logoUrl: nullableStringAt(json, 'logo_url'),
  color: stringAt(json, 'color'),
);

// ─────────────────────────────────────────────────────────────────────────────
// The pay response (B6b)
// ─────────────────────────────────────────────────────────────────────────────

/// `POST /applications/{id}/pay` → [PaymentResult].
///
/// **Reads the union of two shapes** (specs.md § 5.3): `types.ts:573-582`'s
/// flat fields *and* `PaymentSection.tsx:43-57`'s `settled` / `transaction` /
/// four extra `instruction` fields. A server that sends only one of them leaves
/// the other side null, which is precisely what the three resolution rules on
/// [PaymentResult] exist to resolve — so this parser resolves **nothing**. It
/// reads what is there and hands both halves to the entity.
///
/// Totality is the same call the rest of this file makes, and it matters more
/// here: **no pay response has ever been observed** (§ 8.5 gap G-2 for the
/// instruction, § 4.4 for why), so every field name below is a client type
/// declaration. A missing scalar becomes its zero value rather than a throw —
/// a settled charge that renders an empty receipt number is diagnosable, where
/// a `FormatException` on a *successful debit* would tell the citizen their
/// money did not move when it did.
PaymentResult paymentResultFrom(Map<String, dynamic> json) => PaymentResult(
  receiptNo: stringAt(json, 'receipt_no'),
  // `nullableIntAt`, not `intAt`: `amount_lak: 0` and an absent
  // `amount_lak` are **different inputs** to `chargedAmount`'s `??`
  // (`B6-AC-30`). Collapsing them here would make the entity's operator
  // choice untestable and the source's behaviour unreachable.
  amountLak: nullableIntAt(json, 'amount_lak'),
  status: stringAt(json, 'status'),
  paymentState: stringAt(json, 'payment_state'),
  methodCode: stringAt(json, 'method_code'),
  walletBalanceLak: nullableIntAt(json, 'wallet_balance_lak'),
  // Tri-state. `settled: false` and an absent `settled` differ to a reader
  // of the field even though `isSettled` treats both the same, and the
  // source's `result.settled === true` is an identity test over exactly
  // this three-valued input.
  settled: json['settled'] is bool ? json['settled'] as bool : null,
  transaction: _objectAt(json, 'transaction', _paymentTransactionFrom),
  instruction: _objectAt(json, 'instruction', _paymentInstructionFrom),
);

PaymentTransaction _paymentTransactionFrom(Map<String, dynamic> json) =>
    PaymentTransaction(
      receiptNo: nullableStringAt(json, 'receipt_no'),
      amountLak: nullableIntAt(json, 'amount_lak'),
      status: nullableStringAt(json, 'status'),
      methodCode: nullableStringAt(json, 'method_code'),
    );

PaymentInstruction _paymentInstructionFrom(Map<String, dynamic> json) =>
    PaymentInstruction(
      qrPayload: nullableStringAt(json, 'qr_payload'),
      account: nullableStringAt(json, 'account'),
      note: nullableBilingualAt(json, 'note'),
      referenceNo: nullableStringAt(json, 'reference_no'),
      amountLak: nullableIntAt(json, 'amount_lak'),
      steps: _bilingualRowsAt(json, 'steps'),
      expiresAt: nullableStringAt(json, 'expires_at'),
    );

/// A nested object, or **null when the key is absent or is not an object**.
///
/// The nullability is load-bearing rather than defensive: `instruction`'s
/// presence is what switches the whole terminal render from a charge button to
/// a settle-elsewhere panel (`PaymentSection.tsx:445-450`), so "absent" and
/// "present but empty" must not collapse into one another.
T? _objectAt<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) parse,
) {
  final Object? raw = json[key];
  return raw is Map<String, dynamic> ? parse(raw) : null;
}

/// `instruction.steps?: Bilingual[]` — `PaymentSection.tsx:55`.
///
/// Each element goes through [bilingualAt]'s rules by way of a one-key wrapper,
/// so a step sent as a plain string renders in both locales exactly as
/// `text(step, lang)` would on the web. A non-list, or a list of non-objects,
/// yields an empty list and therefore no ordered list at all — the same
/// disposition [_rowsOf] takes.
List<Bilingual> _bilingualRowsAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is! List) return const <Bilingual>[];

  final List<Bilingual> out = <Bilingual>[];
  for (final Object? element in raw) {
    final Bilingual? parsed = nullableBilingualAt(<String, dynamic>{
      'v': element,
    }, 'v');
    if (parsed != null) out.add(parsed);
  }
  return List<Bilingual>.unmodifiable(out);
}

/// `whereType` rather than a cast: one malformed element must cost that row,
/// not the page. A value that is not a list at all yields an empty list — and
/// therefore the **empty** state, not a crash.
List<T> _rowsOf<T>(dynamic raw, T Function(Map<String, dynamic>) parse) =>
    raw is! List
    ? <T>[]
    : raw.whereType<Map<String, dynamic>>().map(parse).toList(growable: false);

/// Public alias of [_rowsOf] for the datasource, which parses top-level arrays.
List<T> rowsOf<T>(dynamic raw, T Function(Map<String, dynamic>) parse) =>
    _rowsOf(raw, parse);

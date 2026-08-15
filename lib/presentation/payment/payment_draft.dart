/// `PaymentSection.tsx:69-118` — the **draft** half's value types, the twelve
/// Lao banks, and the four pure functions the wizard step is built out of.
///
/// ## Why this is F1's and not B6's
///
/// `PaymentSection.tsx:202` — `const live = Boolean(applicationId);` — forks the
/// component in two. `GOR-245-b6-wallet-payment/specs.md` § 6.3 rules the split
/// by name: *"**B6 does NOT own draft mode** (`PaymentSection.tsx:474-670`,
/// `LAO_BANKS`, `isPaymentValid`, `formatCard`, `formatExpiry`). It is
/// **F0/F1/F3's**"*. B6b landed the two shared pieces — `PaymentSummaryCard`
/// (`:246-271`) and `QrPlaceholder` (`:130-161`) — and stopped there, because
/// draft mode reads `useShowErrors` / `FieldError` / `fieldErrorRing` from
/// `formValidation` (`PaymentSection.tsx:16`), which did not exist in `lib/`
/// until F0b closed.
///
/// F1 is the first page to need it. F3 (Marriage, Divorce) is the second and
/// third; nothing here is Resident-specific, which is why it lands in the
/// shared `lib/presentation/payment/` group (B6 § 6.2 RULING 1) rather than in
/// `features/certificates/presentation/resident/`.
///
/// ## `DraftPaymentMethod`, not `PaymentMethodKind`
///
/// `lib/features/wallet/domain/entities/payment_method.dart:64` already
/// declares a `PaymentMethodKind` — `{wallet, bank, cash, qr, other}`, the
/// **API's** classification of a payment rail. The source's
/// `type PaymentMethod = "qr" | "bank" | "cc"` (`:69`) is a different object:
/// it is which **tab the citizen has open** in the draft step, and its `cc` has
/// no inhabitant on the API side at all. Two types with one name in one app is
/// the `FieldError` / `FieldErrorText` situation again
/// (`presentation/forms/validation/field_error.dart:57-61`), and it is resolved
/// the same way: the source name is recorded here, the Dart name disambiguates.
///
/// The two are related by `methodCodeFor` on the page
/// (`ResidentCertificatePage.tsx:494-498`), which maps a
/// [DraftPaymentMethod] onto a live `/payment-methods` row — deliberately, and
/// **lossily**: `cc` and `bank` both resolve to the `bank` kind. That discard is
/// `fsd.md` D-O and it is reproduced, not repaired.
library;

/// `PaymentSection.tsx:69` — `export type PaymentMethod = "qr" | "bank" | "cc"`.
enum DraftPaymentMethod {
  qr,
  bank,

  /// Card. **No `/payment-methods` row has this kind** — `methodCodeFor` folds
  /// it into `bank` (`ResidentCertificatePage.tsx:495`), and Marriage's and
  /// Divorce's static map folds it into `bank-transfer`
  /// (`MarriageCertificatePage.tsx:140-144`). The citizen's card/bank
  /// distinction never reaches the API on any of the three pages.
  cc,
}

/// `PaymentSection.tsx:71-78` — `interface PaymentState`.
///
/// Immutable with a [copyWith], where the source mutates through
/// `onChange(patch)` over a `Partial<PaymentState>` (`:168`). Same observable:
/// the page holds one value and replaces it.
class PaymentDraft {
  const PaymentDraft({
    required this.method,
    required this.bankName,
    required this.cardNumber,
    required this.cardName,
    required this.cardExpiry,
    required this.cardCvv,
  });

  final DraftPaymentMethod method;
  final String bankName;

  /// **As displayed** — i.e. already through [formatCard], so it carries the
  /// group separators. `isPaymentValid` strips them again (`:104`), which is
  /// why the count is 16 and not 19.
  final String cardNumber;
  final String cardName;

  /// `MM/YY` — five characters once [formatExpiry] has inserted the slash.
  final String cardExpiry;
  final String cardCvv;

  PaymentDraft copyWith({
    DraftPaymentMethod? method,
    String? bankName,
    String? cardNumber,
    String? cardName,
    String? cardExpiry,
    String? cardCvv,
  }) => PaymentDraft(
    method: method ?? this.method,
    bankName: bankName ?? this.bankName,
    cardNumber: cardNumber ?? this.cardNumber,
    cardName: cardName ?? this.cardName,
    cardExpiry: cardExpiry ?? this.cardExpiry,
    cardCvv: cardCvv ?? this.cardCvv,
  );

  @override
  bool operator ==(Object other) =>
      other is PaymentDraft &&
      other.method == method &&
      other.bankName == bankName &&
      other.cardNumber == cardNumber &&
      other.cardName == cardName &&
      other.cardExpiry == cardExpiry &&
      other.cardCvv == cardCvv;

  @override
  int get hashCode =>
      Object.hash(method, bankName, cardNumber, cardName, cardExpiry, cardCvv);
}

/// `PaymentSection.tsx:80-82` — `export const blankPayment`.
///
/// **`method` defaults to `qr`**, which is why step 6 of a freshly-opened
/// Resident form is already valid: [isPaymentValid] returns `true` for `qr`
/// unconditionally (`:109`).
const PaymentDraft kBlankPayment = PaymentDraft(
  method: DraftPaymentMethod.qr,
  bankName: '',
  cardNumber: '',
  cardName: '',
  cardExpiry: '',
  cardCvv: '',
);

/// `PaymentSection.tsx:85-98` — `export const LAO_BANKS`, verbatim and in
/// source order.
///
/// Twelve hardcoded commercial banks. Transcribed **as data, in the order the
/// source lists them**, because the dropdown renders in this order and Tier 1
/// reads rendered order. It is not alphabetical and must not be sorted.
///
/// `GOR-245-b6-wallet-payment/specs.md` § 8.5 flags this list as something epic
/// `GOR-248` (API Bank APB) will probably obsolete. That is recorded there;
/// F1's job is to reproduce what the web shows today, so the list is copied
/// rather than replaced with a `/payment-methods` read the web does not make in
/// draft mode.
const List<String> kLaoBanks = <String>[
  'BCEL — Banque pour le Commerce Extérieur Lao',
  'Lao Development Bank (LDB)',
  'Agricultural Promotion Bank (APB)',
  'Joint Development Bank (JDB)',
  'Phongsavanh Bank',
  'ST Bank',
  'BIC Bank Lao',
  'Indochina Bank',
  'Maruhan Japan Bank Lao',
  'Lao-Viet Bank',
  'Lao China Bank',
  'ACLEDA Bank Lao',
];

/// `PaymentSection.tsx:100-110` — `export function isPaymentValid`.
///
/// ```ts
/// if (p.method === "bank") return Boolean(p.bankName);
/// if (p.method === "cc")
///   return (
///     p.cardNumber.replace(/\s/g, "").length === 16 &&
///     p.cardName.trim().length > 0 &&
///     p.cardExpiry.length === 5 &&
///     p.cardCvv.length === 3
///   );
/// return true; // qr
/// ```
///
/// Three details a tidier port loses, each of which changes when
/// `canProceed()` lets the citizen submit:
///
/// 1. **`bankName` is checked for truthiness, not trimmed.** A bank name of
///    `" "` passes on the web. It cannot be produced by the dropdown, so this
///    is unreachable through the UI — reproduced anyway, because "unreachable
///    today" is not "unreachable".
/// 2. **`cardNumber` is stripped of `\s`, not of spaces.** [formatCard] only
///    ever inserts U+0020, so the two agree today; `\s` is what the source
///    says.
/// 3. **`cardExpiry` and `cardCvv` are LENGTH checks, not value checks.**
///    `99/99` and `000` both pass. There is no month range test, no Luhn check
///    and no CVV rule anywhere in the file. Adding one is a port stricter than
///    the web, which is the divergence class no fidelity tier can see.
bool isPaymentValid(PaymentDraft p) {
  if (p.method == DraftPaymentMethod.bank) return p.bankName.isNotEmpty;
  if (p.method == DraftPaymentMethod.cc) {
    return p.cardNumber.replaceAll(RegExp(r'\s'), '').length == 16 &&
        p.cardName.trim().isNotEmpty &&
        p.cardExpiry.length == 5 &&
        p.cardCvv.length == 3;
  }
  return true; // qr
}

/// `PaymentSection.tsx:112-113` — `const formatCard`.
///
/// ```ts
/// v.replace(/\D/g, "").slice(0, 16).replace(/(.{4})/g, "$1 ").trim()
/// ```
///
/// Digits only, capped at 16, grouped in fours, trailing space trimmed. The
/// `.trim()` is load-bearing: a full 16-digit number produces exactly four
/// groups and the replace leaves a trailing space on the last one, so without
/// it every complete card number would render one character wider than the web
/// renders it.
String formatCard(String v) {
  final String digits = v.replaceAll(RegExp(r'\D'), '');
  final String capped = digits.length > 16 ? digits.substring(0, 16) : digits;
  return capped
      .replaceAllMapped(RegExp(r'.{4}'), (Match m) => '${m[0]} ')
      .trim();
}

/// `PaymentSection.tsx:115-118` — `const formatExpiry`.
///
/// ```ts
/// const raw = v.replace(/\D/g, "").slice(0, 4);
/// return raw.length >= 3 ? raw.slice(0, 2) + "/" + raw.slice(2) : raw;
/// ```
///
/// The slash appears at the **third** digit, not the second — so typing `12`
/// shows `12` and typing `123` shows `12/3`. A port that inserts the separator
/// as soon as two digits exist is a different keystroke experience and a
/// different Tier 3 frame.
String formatExpiry(String v) {
  final String digits = v.replaceAll(RegExp(r'\D'), '');
  final String raw = digits.length > 4 ? digits.substring(0, 4) : digits;
  if (raw.length >= 3) return '${raw.substring(0, 2)}/${raw.substring(2)}';
  return raw;
}

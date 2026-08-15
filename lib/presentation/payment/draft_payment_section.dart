/// `PaymentSection.tsx`'s **draft** half — the wizard step three certificate
/// pages mount before a case exists.
///
/// ## This is a shared surface, not Resident's widget
///
/// `PaymentSection.tsx:202` is `const live = Boolean(applicationId);`, and the
/// component is two components either side of it. Resident mounts it with **no**
/// `applicationId` (`ResidentCertificatePage.tsx:1023-1029`) and so do Marriage
/// (`:1598`) and Divorce (`:1546`). `GOR-245-b6-wallet-payment/specs.md` § 6.3
/// assigns draft mode to F0/F1/F3; F0 did not build it, so F1 authors it here —
/// **in the shared `lib/presentation/payment/` group, on F0b's kernel terms:
/// parameter-driven, no service locator, no network** (`specs.md` § 6.5,
/// `F1-AC-45`, `F1-AC-46`). F2 and F3 mount it unchanged.
///
/// A draft-payment defect found at F3 costs the same class of rewrite F1 exists
/// to prevent, which is why this is a second kernel rather than a step widget.
///
/// ## What it does not do
///
/// **No `/payment-methods` read.** The source's draft branch renders one value
/// off that query — `bankRailNote` (`:214`) — and this widget takes it as a
/// [bankRailNote] string instead. The alternative is a widget that cannot be
/// pumped without a container, which is the shape `F0-AC-77` exists to prevent
/// and which `F1-AC-46` re-checks here.
///
/// **No live mode.** `live_payment_section.dart` is B6b's (B6 § 6.3) and
/// nothing in this file branches on an application id.
///
/// ## Icon substitutions, recorded rather than silently absorbed
///
/// `assets/icons/lucide/` holds 89 glyphs and `AppIcons.assetFor` **falls back
/// silently** on an unknown name (`app_icons.dart:114-115`). The source uses
/// four this tree does not carry — `Scan`, `Lock`, `Info` and `CreditCard`'s
/// neighbours — and `assets/` is not one of `specs.md` § 3.1's eleven rows, so
/// adding SVGs is out of scope. Each substitution is named at its call site
/// below and reported as a deviation. It is a Tier 2/Tier 3 finding, not a
/// Tier 0 or Tier 1 one: no string and no payload byte changes.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../features/wallet/domain/wallet_formatting.dart';
import '../forms/validation/field_error.dart';
import '../forms/validation/validation_scope.dart';
import '../forms/widgets/field_base.dart';
import '../forms/widgets/field_label.dart';
import '../icons/lucide_icon.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'payment_draft.dart';
import 'payment_summary_card.dart';
import 'qr_placeholder.dart';

/// `PaymentSection.tsx:30-35` — `COPY`, the component's own bilingual sentence.
///
/// Page-local in the source and page-local here: it is **not** a `payment`
/// namespace key, and promoting it would inflate a namespace whose key count is
/// asserted (`F1-AC-74`/`F1-AC-76` make the same point for Resident's `TXT`).
const String kBankDetailsAfterSubmitEn =
    'The account to pay into and the reference to quote are issued once you '
    'submit this request.';
const String kBankDetailsAfterSubmitLo =
    'ເລກບັນຊີທີ່ຕ້ອງໂອນ ແລະ ເລກອ້າງອີງ ຈະອອກໃຫ້ຫຼັງຈາກທ່ານສົ່ງຄຳຮ້ອງນີ້ແລ້ວ.';

/// `PaymentSection.tsx:474-670` — the whole `!live` branch, plus the summary
/// card above it that both halves share.
class DraftPaymentSection extends StatelessWidget {
  const DraftPaymentSection({
    super.key,
    required this.amount,
    required this.serviceName,
    required this.value,
    required this.onChanged,
    this.reference,
    this.bankRailNote = '',
    this.breakdown = const <PaymentBreakdownItem>[],
  });

  /// The fee in LAK. Rendered by [PaymentSummaryCard] with `formatLak`.
  final int amount;

  /// Already resolved to the reader's language by the caller, matching
  /// [PaymentSummaryCard]'s own contract.
  final String serviceName;

  /// `value` (`:168`). Draft mode keeps its state in the **parent form** — the
  /// source's `const state = value ?? draft` (`:198`) falls back to component
  /// state only in live mode, which this widget does not have. So it is
  /// required here rather than nullable: a draft section holding its own
  /// payment state would be invisible to `canProceed()` (`:449`).
  final PaymentDraft value;

  /// `onChange(patch)` (`:168`), as a whole-value replacement. The source
  /// spreads a `Partial<PaymentState>` over the previous value; the caller does
  /// the same with [PaymentDraft.copyWith], so the merge happens once and in
  /// the place that owns the state.
  final ValueChanged<PaymentDraft> onChanged;

  /// `reference` (`:169`).
  ///
  /// **Accepted and deliberately not rendered.** The prop is read at exactly
  /// one place in the source — `:416`, inside the *live* instruction card — and
  /// draft mode never reaches it. Resident still passes it (`:1028`), so the
  /// parameter exists to keep that call site a faithful transcription rather
  /// than a call site that quietly dropped an argument (`F1-AC-71`). B6b's
  /// live half is where it becomes readable.
  final String? reference;

  /// `enabled.find((m) => m.kind === "bank")?.note ?? ""` — `:214`.
  ///
  /// A **parameter, not a query.** The rail's conditions and cut-off times come
  /// from `/payment-methods` and only the API knows them; the caller already
  /// holds that list for `methodCodeFor` and passes the one string this branch
  /// renders. Empty means the note is not rendered at all (`:576`).
  final String bankRailNote;

  /// `breakdown` (`:172`). Two or more items make the summary itemise
  /// (`:232`) — [PaymentSummaryCard] owns that rule.
  final List<PaymentBreakdownItem> breakdown;

  @override
  Widget build(BuildContext context) {
    // `useShowErrors()` — `:207`. Nullable scope by design: this widget is
    // mounted inside a wizard that provides one and is pumped in tests that do
    // not (`validation_scope.dart:85-91`).
    final bool showErrors = ValidationScope.showErrorsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // `:255-291` — the summary, rendered in BOTH modes, which is why it is
        // B6a's shared widget and not part of the `!live` branch.
        PaymentSummaryCard(
          amount: amount,
          serviceName: serviceName,
          breakdown: breakdown,
        ),
        const SizedBox(height: 20),
        _MethodToggle(value: value.method, onChanged: _pickMethod),
        const SizedBox(height: 20),
        // `:497-670` — exactly one of the three renders, chosen by `state.method`.
        switch (value.method) {
          DraftPaymentMethod.qr => const _QrPanel(),
          DraftPaymentMethod.bank => _BankPanel(
            value: value,
            amount: amount,
            bankRailNote: bankRailNote,
            showErrors: showErrors,
            onChanged: onChanged,
          ),
          DraftPaymentMethod.cc => _CardPanel(
            value: value,
            showErrors: showErrors,
            onChanged: onChanged,
          ),
        },
      ],
    );
  }

  /// `patch({ method: id })` — `:479`.
  ///
  /// **The other five fields survive a tab change**, because the source spreads
  /// a partial over the previous state and never resets. A citizen who types a
  /// card number, switches to QR and switches back still has it. Reproduced by
  /// going through `copyWith`.
  void _pickMethod(DraftPaymentMethod method) =>
      onChanged(value.copyWith(method: method));
}

/// `:475-495` — the three-way segmented control.
class _MethodToggle extends StatelessWidget {
  const _MethodToggle({required this.value, required this.onChanged});

  final DraftPaymentMethod value;
  final ValueChanged<DraftPaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      // `p-1 bg-gray-200 rounded-2xl grid grid-cols-3 gap-1` — `:477`.
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: AppColors.gray200,
        borderRadius: kFieldRadius,
      ),
      child: Row(
        children: <Widget>[
          // `Scan` — **substituted with `QrCode`**; `Scan.svg` is not in the
          // 89-glyph registry and `assets/` is out of § 3.1.
          _tab(context, DraftPaymentMethod.qr, 'payment.methodQr', 'QrCode'),
          const SizedBox(width: 4),
          _tab(
            context,
            DraftPaymentMethod.bank,
            'payment.methodBank',
            'Landmark',
          ),
          const SizedBox(width: 4),
          _tab(
            context,
            DraftPaymentMethod.cc,
            'payment.methodCard',
            'CreditCard',
          ),
        ],
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    DraftPaymentMethod id,
    String labelKey,
    String icon,
  ) {
    final bool selected = value == id;
    // `:483-487` — the selected tab is brand blue on white with a shadow; the
    // rest are `#6B7280` text on the container's own grey, with no fill.
    final Color fg = selected ? AppColors.white : AppColors.gray500;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: () => onChanged(id),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : null,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: selected
                  ? const <BoxShadow>[
                      // `boxShadow: "0 2px 12px #344EAD55"` — `:485`.
                      BoxShadow(
                        color: AppColors.methodTabShadow,
                        blurRadius: 12,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                LucideIcon(name: icon, size: 16, color: fg),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    labelKey.tr(context: context),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `:498-527` — the QR panel.
class _QrPanel extends StatelessWidget {
  const _QrPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // `w-56 h-56 p-4 bg-white rounded-3xl shadow-lg` plus the four corner
        // brackets at `:508-514`.
        Container(
          width: 224,
          height: 224,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gray100),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 15,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const QrPlaceholder(),
        ),
        const SizedBox(height: 20),
        Text(
          'payment.qrScanTitle'.tr(context: context),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.gray700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'payment.qrScanSub'.tr(context: context),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.gray400Inline),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // `Lock` — **substituted with `ShieldCheck`**, same reason as
            // `Scan` above.
            const LucideIcon(
              name: 'ShieldCheck',
              size: 12,
              color: AppColors.gray400Inline,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'payment.qrSecured'.tr(context: context),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.gray400Inline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// `:528-590` — the bank-transfer panel.
class _BankPanel extends StatelessWidget {
  const _BankPanel({
    required this.value,
    required this.amount,
    required this.bankRailNote,
    required this.showErrors,
    required this.onChanged,
  });

  final PaymentDraft value;
  final int amount;
  final String bankRailNote;
  final bool showErrors;
  final ValueChanged<PaymentDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    // `:216` — `showErrors && state.method === "bank" && !state.bankName`.
    // Truthiness, **not** `.trim()`: a bank name of `" "` clears the error on
    // the web (`payment_draft.dart:177-180` records why that is reproduced).
    final bool bankErr = showErrors && value.bankName.isEmpty;
    final String language = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FieldLabel(
          label: Text('payment.selectBank'.tr(context: context)),
          required: true,
        ),
        _BankDropdown(
          value: value.bankName,
          hasError: bankErr,
          onChanged: (String v) => onChanged(value.copyWith(bankName: v)),
        ),
        FieldErrorText(show: bankErr),
        // `:551-573` — the transfer card, rendered only once a bank is chosen.
        if (value.bankName.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: kFieldRadius,
              border: Border.all(color: AppColors.gray100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'payment.transferDetails'.tr(context: context).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray400Inline,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 12),
                _row(
                  context,
                  'payment.bank'.tr(context: context),
                  value.bankName,
                ),
                const SizedBox(height: 12),
                _row(
                  context,
                  'payment.amount'.tr(context: context),
                  formatLak(amount, language),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.gray100),
                const SizedBox(height: 12),
                // `c("bankDetailsAfterSubmit")` — `:571`. The step says when
                // the real payee account arrives rather than inventing one.
                Text(
                  language == 'lo'
                      ? kBankDetailsAfterSubmitLo
                      : kBankDetailsAfterSubmitEn,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
        ],
        // `:575-580` — the rail's own conditions, only when the catalogue
        // published one.
        if (bankRailNote.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          _note(
            // `Info` — **substituted with `HelpCircle`**.
            icon: 'HelpCircle',
            text: bankRailNote,
            color: AppColors.gray500,
          ),
        ],
        const SizedBox(height: 16),
        _note(
          // `Lock` — **substituted with `ShieldCheck`**.
          icon: 'ShieldCheck',
          text: 'payment.bankNote'.tr(context: context),
          color: AppColors.gray400Inline,
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        label,
        style: const TextStyle(fontSize: 14, color: AppColors.gray500),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.gray800,
          ),
        ),
      ),
    ],
  );

  Widget _note({
    required String icon,
    required String text,
    required Color color,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: LucideIcon(name: icon, size: 12, color: color),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(fontSize: 12, color: color, height: 1.5),
        ),
      ),
    ],
  );
}

/// `:534-549` — the `<select>` of [kLaoBanks].
///
/// A `DropdownButton` rather than a modal picker: the source is a native
/// `<select>` with a placeholder `<option value="">`, and
/// `ReferenceSelectView` (the kernel's dropdown) is bound to
/// [ReferenceFieldState] and its loading/failed states, which a hardcoded list
/// does not have.
class _BankDropdown extends StatefulWidget {
  const _BankDropdown({
    required this.value,
    required this.hasError,
    required this.onChanged,
  });

  final String value;
  final bool hasError;
  final ValueChanged<String> onChanged;

  @override
  State<_BankDropdown> createState() => _BankDropdownState();
}

class _BankDropdownState extends State<_BankDropdown> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: fieldDecoration(
        hasError: widget.hasError,
        focused: _focusNode.hasFocus,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          focusNode: _focusNode,
          value: widget.value.isEmpty ? null : widget.value,
          isExpanded: true,
          // `ChevronDown` — the source draws the chevron as an inline `<svg>`
          // at `:545-547`.
          icon: const LucideIcon(
            name: 'ChevronDown',
            size: 16,
            color: AppColors.gray400Inline,
          ),
          // `<option value="">{t("chooseBank")}</option>` — `:541`.
          hint: Text(
            'payment.chooseBank'.tr(context: context),
            style: kFieldPlaceholderStyle,
            overflow: TextOverflow.ellipsis,
          ),
          style: kFieldTextStyle,
          padding: const EdgeInsets.symmetric(vertical: 14),
          // `LAO_BANKS.map(...)` — **source order, not sorted** (`F1-AC-47`).
          items: <DropdownMenuItem<String>>[
            for (final String bank in kLaoBanks)
              DropdownMenuItem<String>(
                value: bank,
                child: Text(
                  bank,
                  overflow: TextOverflow.ellipsis,
                  style: kFieldTextStyle,
                ),
              ),
          ],
          onChanged: (String? v) => widget.onChanged(v ?? ''),
        ),
      ),
    );
  }
}

/// `:591-670` — the card panel: the mock card, then four inputs.
class _CardPanel extends StatelessWidget {
  const _CardPanel({
    required this.value,
    required this.showErrors,
    required this.onChanged,
  });

  final PaymentDraft value;
  final bool showErrors;
  final ValueChanged<PaymentDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    // `:217-220` — four independent error flags, each a **length** test and
    // none of them a value test. `99/99` and `000` are valid on the web.
    final bool numErr =
        showErrors &&
        value.cardNumber.replaceAll(RegExp(r'\s'), '').length != 16;
    final bool nameErr = showErrors && value.cardName.trim().isEmpty;
    final bool expErr = showErrors && value.cardExpiry.length != 5;
    final bool cvvErr = showErrors && value.cardCvv.length != 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _MockCard(value: value),
        const SizedBox(height: 16),
        _CardInput(
          labelKey: 'payment.cardNumber',
          value: value.cardNumber,
          placeholder: '0000 0000 0000 0000',
          hasError: numErr,
          keyboardType: TextInputType.number,
          // `patch({ cardNumber: formatCard(e.target.value) })` — `:625`. The
          // formatter runs on the way IN, which is what makes the stored value
          // the displayed one and what `isPaymentValid`'s 16-after-strip and
          // `cardExpiry.length == 5` both depend on.
          transform: formatCard,
          onChanged: (String v) => onChanged(value.copyWith(cardNumber: v)),
        ),
        const SizedBox(height: 16),
        _CardInput(
          labelKey: 'payment.cardholderName',
          value: value.cardName,
          placeholderKey: 'payment.cardNamePlaceholder',
          hasError: nameErr,
          // `e.target.value.toUpperCase()` — `:637`.
          transform: (String v) => v.toUpperCase(),
          onChanged: (String v) => onChanged(value.copyWith(cardName: v)),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _CardInput(
                labelKey: 'payment.expiryDate',
                value: value.cardExpiry,
                placeholder: 'MM/YY',
                hasError: expErr,
                keyboardType: TextInputType.number,
                maxLength: 5,
                monospace: true,
                transform: formatExpiry,
                onChanged: (String v) =>
                    onChanged(value.copyWith(cardExpiry: v)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CardInput(
                labelKey: 'payment.cvv',
                value: value.cardCvv,
                placeholder: '•••',
                hasError: cvvErr,
                keyboardType: TextInputType.number,
                maxLength: 3,
                obscure: true,
                // `e.target.value.replace(/\D/g, "").slice(0, 3)` — `:659`.
                transform: (String v) {
                  final String d = v.replaceAll(RegExp(r'\D'), '');
                  return d.length > 3 ? d.substring(0, 3) : d;
                },
                onChanged: (String v) => onChanged(value.copyWith(cardCvv: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            // `Lock` — **substituted with `ShieldCheck`**.
            const LucideIcon(
              name: 'ShieldCheck',
              size: 12,
              color: AppColors.gray400Inline,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'payment.cardEncrypted'.tr(context: context),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.gray400Inline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// `:593-620` — the gradient card preview.
class _MockCard extends StatelessWidget {
  const _MockCard({required this.value});

  final PaymentDraft value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        // `linear-gradient(135deg, #344EAD 0%, #1a2d7a 100%)` — `:596`. The
        // same two stops as Resident's success badge (`:624`), which is why
        // Tier 2 compares them together (`F1-AC-56`).
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primary, AppColors.brandGradientEnd],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'payment.cardType'.tr(context: context).toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.6,
              // `text-white/50` — `:600`.
              color: AppColors.cardMetaInk,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            // `state.cardNumber || "•••• •••• •••• ••••"` — `:602`.
            value.cardNumber.isEmpty ? '•••• •••• •••• ••••' : value.cardNumber,
            style: const TextStyle(
              fontSize: 18,
              letterSpacing: 3,
              fontFamily: 'monospace',
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _cardMeta(
                  context,
                  'payment.cardholder',
                  // `state.cardName || t("yourName")` — `:610`.
                  value.cardName.isEmpty
                      ? 'payment.yourName'.tr(context: context)
                      : value.cardName,
                  TextAlign.left,
                ),
              ),
              const SizedBox(width: 12),
              _cardMeta(
                context,
                'payment.expires',
                // `state.cardExpiry || "MM/YY"` — `:616`.
                value.cardExpiry.isEmpty ? 'MM/YY' : value.cardExpiry,
                TextAlign.right,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardMeta(
    BuildContext context,
    String labelKey,
    String text,
    TextAlign align,
  ) => Column(
    crossAxisAlignment: align == TextAlign.right
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        labelKey.tr(context: context).toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 0.8,
          // `text-white/50` — `:609`, `:615`.
          color: AppColors.cardMetaInk,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        text,
        textAlign: align,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
          color: AppColors.white,
        ),
      ),
    ],
  );
}

/// One of the card panel's four `<input>`s.
///
/// Local to this file rather than a kernel widget: the four differ from
/// `formFields.tsx`'s `InputField` in that each one **transforms on the way in**
/// (`formatCard`, `toUpperCase`, `formatExpiry`, the CVV digit strip), and none
/// of them carries a `path` — draft-mode payment fields are not `form_data`
/// keys and no 422 can name one.
class _CardInput extends StatefulWidget {
  const _CardInput({
    required this.labelKey,
    required this.value,
    required this.hasError,
    required this.transform,
    required this.onChanged,
    this.placeholder,
    this.placeholderKey,
    this.keyboardType,
    this.maxLength,
    this.obscure = false,
    this.monospace = false,
  });

  final String labelKey;
  final String value;
  final bool hasError;

  /// Applied to every keystroke before it becomes the value, matching the
  /// source's `onChange={(e) => patch({ x: f(e.target.value) })}`.
  final String Function(String) transform;
  final ValueChanged<String> onChanged;
  final String? placeholder;
  final String? placeholderKey;
  final TextInputType? keyboardType;
  final int? maxLength;
  final bool obscure;
  final bool monospace;

  @override
  State<_CardInput> createState() => _CardInputState();
}

class _CardInputState extends State<_CardInput> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void didUpdateWidget(_CardInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The parent owns the value; when it comes back different from what the
    // field shows — which is what a transform does on almost every keystroke —
    // the controller is corrected and the caret pinned to the end. That is what
    // a React controlled input does for free and what makes `formatExpiry`'s
    // slash appear as you type rather than one character late.
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FieldLabel(
          label: Text(widget.labelKey.tr(context: context)),
          required: true,
        ),
        Container(
          decoration: fieldDecoration(
            hasError: widget.hasError,
            focused: _focusNode.hasFocus,
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            obscureText: widget.obscure,
            keyboardType: widget.keyboardType,
            // `maxLength` on the source's `<input>` caps what the browser
            // accepts; the transform caps it again. Both are kept: the counter
            // is suppressed because the source has none.
            maxLength: widget.maxLength,
            buildCounter:
                (
                  BuildContext context, {
                  required int currentLength,
                  required bool isFocused,
                  required int? maxLength,
                }) => null,
            style: widget.monospace
                ? kFieldTextStyle.copyWith(fontFamily: 'monospace')
                : kFieldTextStyle,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: kFieldPadding,
              hintText:
                  widget.placeholder ??
                  widget.placeholderKey?.tr(context: context),
              hintStyle: kFieldPlaceholderStyle,
            ),
            onChanged: (String raw) => widget.onChanged(widget.transform(raw)),
          ),
        ),
        FieldErrorText(show: widget.hasError),
      ],
    );
  }
}

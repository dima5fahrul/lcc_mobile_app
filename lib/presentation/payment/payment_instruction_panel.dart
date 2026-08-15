/// "Transfer details" — what a method that settles somewhere else answers with.
///
/// `PaymentSection.tsx:388-436`. B6b, § 6.9(5-6).
///
/// ## Nothing here has ever been observed (§ 8.5 gap G-2)
///
/// No `instruction` response has been recorded from any host: the four
/// extension fields exist because `PaymentSection.tsx:51-56` declares them, and
/// § 4.4 forbids executing `POST /applications/:id/pay` to find out. Every
/// Tier 3 verdict for this panel is **NOT EVALUATED with that reason**, and its
/// widget tests run against fixtures the repo declares synthetic. That is
/// evidence about the widget, not about the API.
///
/// ## Three behaviours here are the source's and none of them is tidy
///
/// 1. **The QR renders for a QR-kind method even with no payload at all**
///    (`:391`, `instruction.qr_payload || chosen?.kind === "qr"`). It draws the
///    constant bitmap and nothing beneath it. That is `B6-DIV-3` in its most
///    exposed form — § 6.10 forbids hiding it, adding an encoder, deriving the
///    pattern from the payload, or captioning it with a warning. Security
///    review item 4 (§ 7.9) records what that means for a citizen.
/// 2. **The payload text is the only payable datum on the screen** (`:397`), so
///    it is ported verbatim: 11 px, grey, monospace, wrapping mid-token,
///    centred. The QR above it does not encode it.
/// 3. **The reference falls back three deep** (`:416`):
///    `instruction.reference_no || receiptNo || reference || "—"`. JS `||`, so
///    an empty string falls through at every step — see [_firstNonEmpty].
///
/// ## Amounts are `formatLak` (§ 6.5, `B6-AC-22`)
///
/// `formatLak(instruction.amount_lak ?? chargedAmount, lang)` — `:411`. Note
/// the `??`: an instruction that states `amount_lak: 0` wins over the resolved
/// charge, the same operator choice `PaymentResult.chargedAmount` documents one
/// layer down.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../features/wallet/domain/entities/payment_method.dart';
import '../../features/wallet/domain/entities/payment_result.dart';
import '../../features/wallet/domain/wallet_formatting.dart';
import '../../i18n/i18n.dart';
import '../theme/app_colors.dart';
import 'qr_placeholder.dart';

class PaymentInstructionPanel extends StatelessWidget {
  const PaymentInstructionPanel({
    super.key,
    required this.instruction,
    required this.chosenKind,
    required this.chargedAmount,
    required this.receiptNo,
    required this.reference,
  });

  final PaymentInstruction instruction;

  /// `chosen?.kind` — the kind of the *currently selected* method, which may be
  /// null when the catalogue has not resolved. Drives the QR's second trigger.
  final PaymentMethodKind? chosenKind;

  /// `chargedAmount` — already resolved by the parent through
  /// [PaymentResult.chargedAmount], so the `??` chain lives in the entity where
  /// `B6-AC-30` can unit-test it rather than in a widget.
  final int chargedAmount;

  /// `receiptNo` — likewise already resolved through
  /// [PaymentResult.resolvedReceiptNo].
  final String receiptNo;

  /// The mounting page's `reference` prop — the case's `reference_no`.
  final String reference;

  /// `a || b || c || "—"` with JS truthiness, which for strings means
  /// **empty falls through**. A Dart `??` chain would stop at the first
  /// non-null — i.e. at `''` — and print a blank reference row.
  static String _firstNonEmpty(List<String> candidates) {
    for (final String candidate in candidates) {
      if (candidate.isNotEmpty) return candidate;
    }
    // U+2014 EM DASH, as `:416`.
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final String language = Localizations.localeOf(context).languageCode;
    final Lang lang = Lang.fromCode(language);

    final String payload = instruction.qrPayload ?? '';
    // `:391`. **Not** `payload.isNotEmpty && kind == qr` — the source's `||`
    // shows the bitmap for a QR method that sent no payload at all.
    final bool showQr =
        payload.isNotEmpty || chosenKind == PaymentMethodKind.qr;

    final String account = instruction.account ?? '';
    final String note = text(instruction.note, lang);

    return Container(
      // `bg-white rounded-2xl p-5 border border-gray-100 shadow-sm` — `:389`.
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            // `uppercase tracking-wide` — `:390`. The CSS transform is applied
            // here, not in the JSON, so `payment.transferDetails` keeps the
            // source's own key value and the Lao arm — which has no case — is
            // unaffected by `toUpperCase()`.
            'payment.transferDetails'.tr(context: context).toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.gray400Inline,
              letterSpacing: 0.4,
            ),
          ),
          if (showQr) ...<Widget>[
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: <Widget>[
                  Container(
                    // `w-44 h-44 p-3 bg-white rounded-2xl shadow
                    // border border-gray-100` — `:393`.
                    width: 176,
                    height: 176,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gray100),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: AppColors.cardShadowMedium,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const QrPlaceholder(),
                  ),
                  if (payload.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      payload,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.gray400Inline,
                        fontFamily: 'monospace',
                        fontFamilyFallback: <String>['Courier'],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (account.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            _InstructionRow(
              label: 'payment.accountNo'.tr(context: context),
              value: account,
            ),
          ],
          const SizedBox(height: 16),
          _InstructionRow(
            label: 'payment.amount'.tr(context: context),
            // `instruction.amount_lak ?? chargedAmount` — `??`, see the
            // library doc.
            value: formatLak(instruction.amountLak ?? chargedAmount, language),
          ),
          const SizedBox(height: 16),
          _InstructionRow(
            label: 'payment.reference'.tr(context: context),
            value: _firstNonEmpty(<String>[
              instruction.referenceNo ?? '',
              receiptNo,
              reference,
            ]),
          ),
          if (instruction.hasSteps) ...<Widget>[
            const SizedBox(height: 20),
            for (int i = 0; i < instruction.steps.length; i++)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      // `w-6 h-6 rounded-full` `#EEF2FF` on `#344EAD` — `:429`.
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primarySoft,
                      ),
                      child: Text(
                        // `{i + 1}` — 1-based, `:432`.
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          // **Translated** — `text(step, lang)`, `:434`. Steps
                          // are `Bilingual`, unlike `PaymentMethod.note` three
                          // widgets up, which is not (`B6-DIV-2`).
                          text(instruction.steps[i], lang),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.gray700,
                            height: 1.625,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (note.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              // **Translated** — `text(instruction.note, lang)`, `:435`.
              note,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                height: 1.625,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One `label … value` line — `:402-419`.
class _InstructionRow extends StatelessWidget {
  const _InstructionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.muted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gray800,
            ),
          ),
        ),
      ],
    );
  }
}

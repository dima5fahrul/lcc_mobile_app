/// The payment summary — fee, service, and an optional itemised breakdown.
///
/// `PaymentSection.tsx:246-271`. The one part of `PaymentSection` that is
/// identical in draft mode and in live mode, which is why it is B6a's while the
/// rest of the component is B6b's (live) or F1/F3's (draft).
///
/// ## Why this lives in `lib/presentation/payment/` and not in `features/`
///
/// specs.md § 6.2, RULING 1. `PaymentSection` has **five call sites across
/// three batches** — the wallet's pay sheet, two certificate flows and the
/// history detail page — so it is not one feature's widget, and a
/// `features/wallet/presentation/widgets/` home would force
/// `features/service → features/wallet/presentation/**`, which G-L3 fails. A
/// fifth `lib/presentation/` group is the placement SSD § 4.2 already
/// prescribes for a cross-feature widget.
///
/// The boundary it must keep is **G-L7**: nothing under `lib/presentation/`
/// may import `features/*/presentation/**`. `B6-AC-9` makes it concrete —
/// `grep -rn "features/" lib/presentation/payment` must return **only**
/// `domain/` paths, and this file's single feature import is
/// `features/wallet/domain/wallet_formatting.dart`. That is also why the
/// formatter is reached through the wallet's `domain/` re-export rather than
/// straight from `features/home/domain/`: one feature dependency, named in the
/// batch's own scope table, instead of two.
///
/// ## `formatLak`, **not** `formatKip` (§ 6.5, `B6-AC-22`)
///
/// This is the highest-risk silent divergence in the batch. Both functions
/// format an amount in LAK; they produce **different strings**, and the split
/// is by call site, not by type:
///
/// * `formatLak` — `"20,000 LAK"` / `"20.000 ກີບ"`, comma grouping pinned to
///   `en-US` in **both** locales, and `0` renders as `"Free"` / `"ຟຣີ"`. Six
///   sites, all inside `PaymentSection`: the summary fee (`:250`), the
///   breakdown rows (`:262`), the breakdown total (`:267`), the
///   insufficient-funds copy, the instruction amount and the charge CTA.
/// * `formatKip` — `"20,000 ₭"` / `"20.000 ₭"`, grouping **locale-dependent**.
///   Nine sites, all inside `WalletPage`.
///
/// Three of the six `formatLak` sites are in this file. The other three are
/// B6b's.
///
/// ## No state, no BLoC, no locator (`B6-AC-10`)
///
/// A `StatelessWidget` over four scalars. `lib/presentation/payment/**` holds
/// no `BlocProvider`, no `*Injection`, no `di/` import and — in B6b — no direct
/// use-case call: the charge arrives as a callback. This card takes not even
/// that.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../features/wallet/domain/wallet_formatting.dart';
import '../theme/app_colors.dart';

/// One row of an itemised fee (`breakdown?: {label, amount}[]`, `:100`).
@immutable
class PaymentBreakdownItem {
  const PaymentBreakdownItem({required this.label, required this.amount});

  final String label;
  final int amount;
}

class PaymentSummaryCard extends StatelessWidget {
  const PaymentSummaryCard({
    super.key,
    required this.amount,
    required this.serviceName,
    this.breakdown = const <PaymentBreakdownItem>[],
  });

  /// The fee in LAK. Rendered with [formatLak], never [formatKip].
  final int amount;

  /// Already resolved to the reader's language by the caller — the source
  /// passes `text(paying.service_name, lang)` as a **string** prop
  /// (`WalletPage.tsx:538`), not the `Bilingual` pair, so this widget does no
  /// bilingual resolution and needs no `Bilingual` import.
  final String serviceName;

  /// `const showBreakdown = Boolean(breakdown && breakdown.length > 1)`
  /// — `:232`. **Two or more**, not one: a single-line breakdown would repeat
  /// the total under the total.
  final List<PaymentBreakdownItem> breakdown;

  bool get _showBreakdown => breakdown.length > 1;

  @override
  Widget build(BuildContext context) {
    final String language = Localizations.localeOf(context).languageCode;

    return Container(
      // `bg-white rounded-2xl p-4 border border-gray-100 shadow-sm` — `:247`.
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: AppColors.cardShadow, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'payment.serviceFee'.tr(context: context),
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      // `text-2xl font-bold` at `#344EAD` — `:250`.
                      formatLak(amount, language),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      'payment.service'.tr(context: context),
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      serviceName,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showBreakdown) ...<Widget>[
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1, color: AppColors.gray100),
            const SizedBox(height: 12),
            for (final PaymentBreakdownItem item in breakdown)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.label,
                        style: const TextStyle(fontSize: 14, color: AppColors.muted),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatLak(item.amount, language),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray700,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1, thickness: 1, color: AppColors.gray100),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'payment.total'.tr(context: context),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formatLak(amount, language),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

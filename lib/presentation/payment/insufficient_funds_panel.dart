/// The amber "not enough in your wallet" panel — `PaymentSection.tsx:352-378`.
///
/// B6b, § 6.9(3), and it is one of the two branches `B6-AC-32` requires a
/// widget test for.
///
/// ## Why this is a panel and not the generic error line
///
/// `charge.error?.code === "INSUFFICIENT_FUNDS"` (`:219`) splits the failure in
/// two, and the split is **on the code, never on the message** — see
/// `payment_result.dart`'s `PaymentFailure` for why. When it is true this panel
/// renders *and the generic red line is suppressed* (`:380`,
/// `charge.error && !insufficient`); the suppression is the parent's job and
/// `LivePaymentSection` does it, because only the parent can see both.
///
/// ## The Top-up button is genuinely conditional (`B6-AC-32`)
///
/// `{onTopUp && …}` (`:367`). The wallet's pay sheet supplies the callback and
/// **closes itself first** (`WalletPage.tsx:544-547`); the history detail page
/// does not supply one at all (`HistoryDetailPage.tsx:427-436`), so a citizen
/// looking at a case they cannot afford from *that* screen is told the fee and
/// offered no way forward. Both branches are the source's and both are tested.
///
/// ## The fee is `formatLak`, not `formatKip` (§ 6.5, `B6-AC-22`)
///
/// `formatLak(amount, lang)` — `:363`. This is one of the six `formatLak`
/// sites, all inside `PaymentSection`; the nine `formatKip` sites are all
/// inside `WalletPage`. The two produce different strings for the same integer
/// and `payment_summary_card.dart:26-41` tabulates which is which.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../features/wallet/domain/wallet_formatting.dart';
import '../icons/lucide_icon.dart';
import '../theme/app_colors.dart';

class InsufficientFundsPanel extends StatelessWidget {
  const InsufficientFundsPanel({super.key, required this.amount, this.onTopUp});

  /// The case fee, in LAK — the mounting page's `amount` prop.
  final int amount;

  /// Null when the mount offers no way to top up. See the library doc.
  final VoidCallback? onTopUp;

  @override
  Widget build(BuildContext context) {
    final String language = Localizations.localeOf(context).languageCode;

    return Container(
      // `bg-white rounded-2xl p-4 border border-amber-100` with an inline
      // `backgroundColor: "#FFFBEB"` that wins over `bg-white` — `:353`.
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(16),
        // `border-amber-100` — Tailwind **v3**'s `#FEF3C7` (`:353`), which the
        // theme already holds as `categoryTintTransport`. **Not**
        // `warningBorderSoft` (`#FEF3C6`), which is v4's amber-100 and a
        // different value by one unit of blue. Reused rather than re-declared,
        // per the ruling `app_colors.dart`'s B7a escalation comment records;
        // `wallet_bills_due_section.dart` explains it at length.
        border: Border.all(color: AppColors.categoryTintTransport),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            // `mt-0.5` — `:355`.
            padding: EdgeInsets.only(top: 2),
            child: LucideIcon(
              name: 'AlertCircle',
              size: 20,
              color: AppColors.warningLink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'payment.insufficientTitle'.tr(context: context),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'payment.insufficientBody'.tr(
                    context: context,
                    namedArgs: <String, String>{
                      'amount': formatLak(amount, language),
                    },
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray600,
                    height: 1.5,
                  ),
                ),
                if (onTopUp != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ElevatedButton.icon(
                      onPressed: onTopUp,
                      style: ElevatedButton.styleFrom(
                        // `bg #D97706`, `px-4 py-2 rounded-xl` — `:371`.
                        backgroundColor: AppColors.warningLink,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      // lucide `Plus` is not in `assets/icons/lucide/`;
                      // Material's is the substitution B6a already made for the
                      // same glyph at `wallet_balance_card.dart:214`. FU-10
                      // files the bundle gap.
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(
                        'payment.topUp'.tr(context: context),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

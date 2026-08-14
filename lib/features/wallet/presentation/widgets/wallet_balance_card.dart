/// The gradient header and the balance card — `WalletPage.tsx:152-220`.
///
/// ## The three balance renders, and the two that are easy to lose (§ 6.8(6-7))
///
/// ```
/// {walletQuery.loading && !overview ? "…"
///   : showBalance ? formatKip(balance, lang)
///   : "•••••• ₭"}                                     — :183-189
/// ```
///
/// * **`"…"` is one character, U+2026**, and it shows *only* before the first
///   overview arrives. A refetch with an overview in hand renders the **old**
///   balance, not the ellipsis. [balanceIsPlaceholder] carries that distinction
///   from the BLoC, where `walletQuery.loading && !overview` is computed.
/// * **Hidden renders the literal `"•••••• ₭"`** — six U+2022 BULLET, one
///   ASCII space, U+20AD KIP SIGN. Not a masked number, not a fixed count of
///   digits: the source writes the string. [kHiddenBalance] is that string, and
///   `B6-AC-29` asserts it by code point.
/// * **Hiding the balance hides the account number with it** — `:190` requires
///   `showBalance` as well as a non-empty `account_no`. Two conditions, and
///   dropping the first leaves a citizen's wallet number on screen after they
///   asked for the balance to be hidden.
///
/// The eye is **local `setState` state on the page** (`useState`, `:95`), not
/// BLoC state, so this widget takes it as a parameter and reports taps upward.
/// SSD § 7.2 permits `setState` for exactly this: nothing fetches on it and
/// nothing else reads it.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import 'wallet_panels.dart';

/// `"•••••• ₭"` — `WalletPage.tsx:188`.
///
/// Written as escapes so the six bullets can be counted and the kip sign cannot
/// be confused with a lookalike (U+04A9 ҩ) by eye. `B6-AC-18` / `B6-AC-29`
/// assert both by code point.
const String kHiddenBalance = '•••••• ₭';

/// `"…"` — `:185`. One character, U+2026 HORIZONTAL ELLIPSIS, not three dots.
const String kBalancePlaceholder = '…';

class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({
    super.key,
    required this.balanceText,
    required this.accountNo,
    required this.showBalance,
    required this.isPlaceholder,
    required this.onToggleBalance,
    required this.errorMessage,
    required this.onRetry,
    required this.onTopUp,
    required this.onTransfer,
  });

  /// Already formatted by the page with `formatKip(balance, lang)`. Ignored
  /// when [isPlaceholder] or `!showBalance`.
  final String balanceText;

  final String accountNo;
  final bool showBalance;
  final bool isPlaceholder;
  final VoidCallback onToggleBalance;

  /// `walletQuery.error && isAuthenticated` — `:193`. The pill is absent for a
  /// signed-out visitor even though the query never ran, because on the web a
  /// disabled query has no error.
  final String? errorMessage;
  final VoidCallback onRetry;

  final VoidCallback onTopUp;
  final VoidCallback onTransfer;

  String get _balance {
    if (isPlaceholder) return kBalancePlaceholder;
    return showBalance ? balanceText : kHiddenBalance;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // `px-4 pt-6 pb-10` — `:154`.
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      decoration: const BoxDecoration(
        // `linear-gradient(135deg, #344EAD 0%, #2A3F99 60%, #1E3070 100%)`
        // — `:156-157`. 135° in CSS runs top-left → bottom-right.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.primary,
            AppColors.headerGradientMid,
            AppColors.headerGradientEnd,
          ],
          stops: <double>[0.0, 0.6, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'wallet.title'.tr(context: context),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'wallet.subtitle'.tr(context: context),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.white.withValues(alpha: 0.70),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              // `bg-white/10 backdrop-blur border border-white/20 rounded-2xl`
              // — `:162`. The blur is dropped: a `BackdropFilter` over a flat
              // gradient produces the same pixels and costs a saveLayer.
              color: AppColors.white.withValues(alpha: 0.10),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.20)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        // `uppercase tracking-wider` — the CSS transform is
                        // applied here rather than in the JSON so the key's
                        // value stays byte-identical to the source's.
                        'wallet.availableBalance'.tr(context: context).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 0.6,
                          color: AppColors.white.withValues(alpha: 0.70),
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: showBalance
                          ? 'wallet.hideBalance'.tr(context: context)
                          : 'wallet.showBalance'.tr(context: context),
                      child: InkWell(
                        onTap: onToggleBalance,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: LucideIcon(
                            name: showBalance ? 'Eye' : 'EyeOff',
                            size: 16,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _balance,
                  // `fontSize: "28px", fontWeight: 600` — `:182`, an inline
                  // style rather than a Tailwind class in the source too.
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                // `{overview?.wallet.account_no && showBalance && …}` — `:190`.
                // **Both** conditions; see the library doc.
                if (accountNo.isNotEmpty && showBalance) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    accountNo,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: AppColors.white.withValues(alpha: 0.60),
                    ),
                  ),
                ],
                if (errorMessage != null) ...<Widget>[
                  const SizedBox(height: 12),
                  WalletTryAgainPill(onRetry: onRetry),
                ],
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _HeaderButton(
                        // `Plus` is not in `assets/icons/lucide/`; see
                        // `wallet_panels.dart`'s library doc.
                        icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                        label: 'wallet.topUp'.tr(context: context),
                        onTap: onTopUp,
                        filled: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HeaderButton(
                        // `Send` likewise unbundled.
                        icon: const Icon(Icons.send, size: 16, color: AppColors.white),
                        label: 'wallet.transfer'.tr(context: context),
                        onTap: onTransfer,
                        filled: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `:203-217` — a solid white button and a translucent one, same geometry.
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.filled,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: filled
              ? AppColors.white
              : AppColors.white.withValues(alpha: 0.15),
          border: filled
              ? null
              : Border.all(color: AppColors.white.withValues(alpha: 0.20)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            icon,
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: filled ? AppColors.primary : AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

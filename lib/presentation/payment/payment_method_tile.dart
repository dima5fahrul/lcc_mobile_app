/// One selectable payment rail — `PaymentSection.tsx:316-347`.
///
/// Live mode's method picker row. B6b, per specs.md § 3.1.
///
/// ## It is a different widget from the top-up sheet's row, deliberately
///
/// `wallet_top_up_sheet.dart` draws a rail row too and the two look alike, but
/// they are not the same control and merging them would be a divergence rather
/// than a de-duplication:
///
/// * **Different filters over the same catalogue.** The top-up list is
///   `m.enabled && m.code !== "wallet"` (`WalletPage.tsx:728`) — the wallet
///   cannot top itself up — and this one is `m.enabled` alone
///   (`PaymentSection.tsx:211`). Against the recorded 7-row fixture that is
///   **6** rows and **7** rows (`B6-AC-53`).
/// * **Different geometry.** 36 px tile / 14 px padding / `gray200` idle border
///   there; 40 px tile / 16 px padding / `gray100` idle border, a shadow, and a
///   radio dot here (`:318-345`).
/// * **Different homes.** That one is `features/wallet/presentation/`; this one
///   is `lib/presentation/payment/` because B7 and F1-F3 mount it (§ 6.2).
///   G-L7 forbids the import that sharing would need.
///
/// ## The icon is chosen by `kind`, and one of the four is not bundled
///
/// `m.kind === "wallet" ? Wallet : m.kind === "qr" ? Scan : m.kind === "bank"
/// ? Landmark : CreditCard` (`:319`). Three of those lucide glyphs are in
/// `assets/icons/lucide/`; **`Scan` is not**. `LucideIcon` would silently draw
/// `AppIcons.fallback` (`FileText`) for it — a wrong glyph that never throws,
/// which is the failure mode `app_icons.dart:24-32` describes.
///
/// So `qr` renders Material's `Icons.qr_code_scanner` instead, following the
/// substitution B6a already made in this feature for two unbundled glyphs
/// (`wallet_balance_card.dart:214,224` — `Icons.add` for `Plus`, `Icons.send`
/// for `Send`). Adding an SVG would touch `assets/`, which is not in B6b's
/// § 3.1 table. **FU-10** files the bundle gap.
library;

import 'package:flutter/material.dart';

import '../../features/wallet/domain/entities/payment_method.dart';
import '../../i18n/i18n.dart';
import '../icons/lucide_icon.dart';
import '../theme/app_colors.dart';

class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({
    super.key,
    required this.method,
    required this.active,
    required this.onTap,
  });

  final PaymentMethod method;

  /// `m.code === methodCode` — `:317`. Resolved by the parent, because the
  /// selection is one-of-many and only the parent can see the others.
  final bool active;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Lang lang = Lang.fromCode(
      Localizations.localeOf(context).languageCode,
    );

    // `m.color || "#344EAD"` — `:326,328`. The API's hex, parsed at the widget
    // edge and never stored as a `Color` (`payment_method.dart`'s own rule),
    // with the brand blue as the empty fallback. `B6-AC-41` requires this to be
    // computed at runtime and asserts it with two different API colours.
    final Color accent = AppColors.parseHex(method.color);

    return Semantics(
      selected: active,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          // `bg-white rounded-2xl p-4 border shadow-sm` — `:321`.
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              // `borderColor: active ? "#344EAD" : "#F3F4F6"` — `:323`.
              color: active ? AppColors.primary : AppColors.gray100,
            ),
            boxShadow: <BoxShadow>[
              if (active)
                // `boxShadow: active ? "0 2px 12px #344EAD22" : undefined`
                // — `:324`. `0x22` alpha over the brand blue; the idle row has
                // Tailwind's `shadow-sm`, which is the class on the element.
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0x22 / 0xFF),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                )
              else
                const BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                // `w-10 h-10 rounded-xl` — `:327`.
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  // `${m.color || "#344EAD"}1A` — the runtime 10 %-alpha wash.
                  // `0x1A / 0xFF` is 0.10196…, written as the exact ratio
                  // because rounding to `0.1` lands on `0x19`
                  // (`wallet_top_up_sheet.dart:541-544` says the same).
                  color: accent.withValues(alpha: 0x1A / 0xFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _kindIcon(method.kind, accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      text(method.label, lang),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray800,
                        height: 1.375,
                      ),
                    ),
                    Text(
                      // **Raw, untranslated** — `:337`. `B6-DIV-2`: the API
                      // sends English only and the source renders it with no
                      // `text(…, lang)`, while `instruction.note` two panels
                      // down *is* translated (`:434`). Ported as measured; the
                      // fix belongs at the API and FU-7 files it there.
                      method.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray400Inline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // The radio dot — `:339-344`.
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.gray300,
                    width: 2,
                  ),
                ),
                child: active
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// `:319`'s four-way ternary. See the library doc on why `qr` is Material's.
  Widget _kindIcon(PaymentMethodKind kind, Color accent) {
    switch (kind) {
      case PaymentMethodKind.qr:
        return Icon(Icons.qr_code_scanner, size: 20, color: accent);
      case PaymentMethodKind.wallet:
        return LucideIcon(name: 'Wallet', size: 20, color: accent);
      case PaymentMethodKind.bank:
        return LucideIcon(name: 'Landmark', size: 20, color: accent);
      // `cash` and `other` both fall to the source's final `: CreditCard`.
      case PaymentMethodKind.cash:
      case PaymentMethodKind.other:
        return LucideIcon(name: 'CreditCard', size: 20, color: accent);
    }
  }
}

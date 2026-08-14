/// The eight quick-payment tiles — `WalletPage.tsx:44-60`, `:226-263`.
///
/// ## Seven of the eight are silent no-ops when signed in (`B6-DIV-1`)
///
/// ```
/// const onQuickAction = (id: string) => {
///   if (!isAuthenticated) return onRequireAuth();
///   if (id === "topup") setTopUpOpen(true);
/// };                                          — WalletPage.tsx:144-147
/// ```
///
/// `topup` opens the sheet. `transfer`, `scan`, `mobile`, `electricity`,
/// `water`, `internet` and `fines` fall off the end of the function and **do
/// nothing at all** — no navigation, no dialog, no toast, no disabled state.
/// Same class as the 37 dead service cards B2 ported. Adding any affordance
/// here is invisible to all four fidelity tiers and is therefore a divergence,
/// not an improvement: `B6-AC-48` taps all nine dead controls (these seven plus
/// Transfer and See all) and asserts nothing happened.
///
/// Signed out, **every** tile routes to sign-in (`B6-AC-50`).
///
/// ## Colours
///
/// Six of the eight `{color, bg}` pairs already had `AppColors` members. Two —
/// Scan & Pay and Water — did not, and adding them was the § 8.3 escalation
/// recorded in `blocked.md` and granted. See `app_colors.dart`'s tail block.
///
/// ## The two logo tiles
///
/// `electricity` and `water` carry a raster (`edl-logo.png`, `nampapa-logo.png`)
/// and `:249-255` draws the **logo instead of the glyph**, on a white tile with
/// a `#F3F4F6` hairline instead of the tinted wash. Both rasters are already
/// bundled as `assets/images/edl-logo.webp` / `nampapa-logo.webp` (B2's), so the
/// branch is ported rather than dropped — which is why
/// [WalletQuickAction.accent] and [WalletQuickAction.tint] are unreachable for
/// those two rows and are still declared, exactly as the source declares them.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';

/// One row of `QUICK_ACTIONS` (`WalletPage.tsx:51-60`).
@immutable
class WalletQuickAction {
  const WalletQuickAction({
    required this.id,
    required this.labelKey,
    required this.accent,
    required this.tint,
    this.lucideName,
    this.materialIcon,
    this.logoAsset,
  }) : assert(
          lucideName != null || materialIcon != null,
          'every tile needs a glyph, even the two that draw a logo over it',
        );

  final String id;

  /// The `wallet` namespace key. **All eight resolve** — `B6-AC-55` renders the
  /// grid in both locales and asserts eight non-empty, non-key-echoing labels,
  /// because a grep-driven dead-key sweep marks `qa*` dead (they are reached
  /// through this table, never as a literal at a call site).
  final String labelKey;

  final Color accent;
  final Color tint;

  /// Set when the glyph is bundled in `assets/icons/lucide/`.
  final String? lucideName;

  /// The Material substitute for an unbundled lucide glyph — see
  /// `wallet_panels.dart`'s library doc for why substitution rather than an
  /// asset addition.
  final IconData? materialIcon;

  final String? logoAsset;
}

/// The `electricity` tile's raster (`WalletPage.tsx:56`). B2 bundled it; Tier B
/// (`tier_a_scanner.dart:52`), so it needs no call-site decode constraint.
///
/// A named constant rather than a bare literal because it is referenced from
/// two places that must not drift — the [kWalletQuickActions] row below and the
/// literal `Image.asset` call site in `_QuickTileLogo`.
const String kEdlLogoAsset = 'assets/images/edl-logo.webp';

/// The `water` tile's raster (`WalletPage.tsx:57`). Tier B, as [kEdlLogoAsset].
const String kNampapaLogoAsset = 'assets/images/nampapa-logo.webp';

/// `QUICK_ACTIONS` — eight rows, in the source's order (`:51-60`).
const List<WalletQuickAction> kWalletQuickActions = <WalletQuickAction>[
  WalletQuickAction(
    id: 'topup',
    labelKey: 'wallet.qaTopup',
    materialIcon: Icons.add, // lucide `Plus`, unbundled
    accent: AppColors.categoryAccentFinance, // #16A34A
    tint: AppColors.categoryTintFinance, // #DCFCE7
  ),
  WalletQuickAction(
    id: 'transfer',
    labelKey: 'wallet.qaTransfer',
    materialIcon: Icons.send, // lucide `Send`, unbundled
    accent: AppColors.primary, // #344EAD
    tint: AppColors.primarySoft, // #EEF2FF
  ),
  WalletQuickAction(
    id: 'scan',
    labelKey: 'wallet.qaScan',
    lucideName: 'QrCode',
    accent: AppColors.quickActionAccentScan, // #7C3AED — escalated, granted
    tint: AppColors.quickActionTintScan, // #EDE9FE
  ),
  WalletQuickAction(
    id: 'mobile',
    labelKey: 'wallet.qaMobile',
    materialIcon: Icons.smartphone, // lucide `Smartphone`, unbundled
    accent: AppColors.categoryAccentImmigration, // #0EA5E9
    tint: AppColors.categoryTintImmigration, // #E0F2FE
  ),
  WalletQuickAction(
    id: 'electricity',
    labelKey: 'wallet.qaElectricity',
    lucideName: 'Zap',
    logoAsset: kEdlLogoAsset,
    accent: AppColors.categoryAccentTransport, // #F59E0B
    tint: AppColors.categoryTintTransport, // #FEF3C7
  ),
  WalletQuickAction(
    id: 'water',
    labelKey: 'wallet.qaWater',
    materialIcon: Icons.water_drop_outlined, // lucide `Droplet`, unbundled
    logoAsset: kNampapaLogoAsset,
    accent: AppColors.quickActionAccentWater, // #0891B2 — escalated, granted
    tint: AppColors.quickActionTintWater, // #CFFAFE
  ),
  WalletQuickAction(
    id: 'internet',
    labelKey: 'wallet.qaInternet',
    materialIcon: Icons.wifi, // lucide `Wifi`, unbundled
    accent: AppColors.categoryAccentWelfare, // #DB2777
    tint: AppColors.categoryTintWelfare, // #FCE7F3
  ),
  WalletQuickAction(
    id: 'fines',
    labelKey: 'wallet.qaFines',
    lucideName: 'AlertOctagon',
    accent: AppColors.categoryAccentHealth, // #DC2626
    tint: AppColors.categoryTintHealth, // #FEE2E2
  ),
];

class WalletQuickActions extends StatelessWidget {
  const WalletQuickActions({super.key, required this.onAction});

  /// Receives the tile's `id`. The page decides — sign-in when signed out,
  /// the sheet for `topup`, **nothing at all** for the other seven.
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      // `grid grid-cols-4 gap-3` at 390 px — the `lg:grid-cols-8` branch is
      // unreachable at the fidelity baseline width and is not encoded.
      crossAxisCount: 4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.78,
      children: <Widget>[
        for (final WalletQuickAction a in kWalletQuickActions)
          _QuickTile(action: a, onTap: () => onAction(a.id)),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.action, required this.onTap});

  final WalletQuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool hasLogo = action.logoAsset != null;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              // `backgroundColor: a.logo ? "white" : a.bg` and
              // `border: a.logo ? "1px solid #F3F4F6" : undefined` — `:249`.
              color: hasLogo ? AppColors.white : action.tint,
              border: hasLogo ? Border.all(color: AppColors.gray100) : null,
              borderRadius: BorderRadius.circular(16),
            ),
            child: hasLogo
                ? Padding(
                    // `object-contain p-1.5` — `:252`.
                    padding: const EdgeInsets.all(6),
                    child: _QuickTileLogo(asset: action.logoAsset!),
                  )
                : (action.lucideName != null
                    ? LucideIcon(
                        name: action.lucideName!,
                        size: 20,
                        color: action.accent,
                      )
                    : Icon(action.materialIcon, size: 20, color: action.accent)),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              action.labelKey.tr(context: context),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.15,
                color: AppColors.gray600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The two logo tiles' raster, drawn from a **literal** asset path.
///
/// ## Why a switch and not `Image.asset(action.logoAsset!)`
///
/// B2-AC-31's scanner (`tier_a_scanner.dart`) resolves the first argument of
/// every `Image.asset`/`AssetImage` in `lib/` as a string literal, and reports
/// a call it cannot resolve as an *unresolved Tier A candidate* rather than
/// letting it pass — "I could not tell" is not "it is fine", or the guard would
/// be defeated by exactly `Image.asset(myPath)`. Passing `action.logoAsset!`
/// did precisely that and failed the guard's `lib/` sweep with
/// `wallet_quick_actions.dart:202 -> Image.asset(<dynamic>)`.
///
/// Both rasters are **Tier B** (`tier_a_scanner.dart:52-53`), so B1b § 6.4's
/// carve-out applies and neither needs a `cacheWidth`: they ship a 1x/2.0x/3.0x
/// ladder and Flutter's resolution-aware `AssetImage` picks and decodes the
/// right rung by itself. The obligation this widget discharges is the
/// *literal-path* one, not the decode-constraint one — which is why adding a
/// `cacheWidth` here would be cargo-cult rather than compliance.
///
/// [WalletQuickAction.logoAsset] stays on the table: it is what decides the
/// white-tile-with-hairline branch (`WalletPage.tsx:249`). The table and this
/// switch are held together by [kEdlLogoAsset] / [kNampapaLogoAsset] — one
/// constant each, referenced from both sides — plus the drift test in
/// `wallet_quick_actions_test.dart`, which renders every logo row and asserts
/// it produced a real `AssetImage` at the expected path. Two string literals
/// that merely *looked* equal would rot the first time one was edited.
class _QuickTileLogo extends StatelessWidget {
  const _QuickTileLogo({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return switch (asset) {
      kEdlLogoAsset =>
        Image.asset('assets/images/edl-logo.webp', fit: BoxFit.contain),
      kNampapaLogoAsset =>
        Image.asset('assets/images/nampapa-logo.webp', fit: BoxFit.contain),
      // Unreachable: `kWalletQuickActions` is a `const` table with exactly the
      // two logo rows above. A third would land here loudly at first render
      // rather than drawing a blank 48×48 tile nobody notices.
      _ => throw ArgumentError.value(
          asset,
          'asset',
          'no literal Image.asset call site is declared for this logo; add one '
              'here rather than passing the path through a variable, which '
              'B2-AC-31 rejects',
        ),
    };
  }
}

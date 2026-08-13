/// "Your account at a glance" — `HomePage.tsx:337-390`.
///
/// Four tiles in a 2-column grid: active applications, documents ready, wallet
/// balance, unread notices. Each is a button that navigates to a tab.
///
/// **Authenticated only, and absent rather than empty when signed out.** The
/// whole block is behind `isAuthenticated && summary.data`, and its query is
/// `enabled: isAuthenticated`, so a signed-out citizen sees *nothing here* —
/// not a spinner, not an error, not four zeroes (§ 6.6, manifest F-4). That
/// distinction is enforced upstream by `HomeState.showSummaryTiles`; this
/// widget is only reached when it is true.
///
/// ## Tier 3 is NOT EVALUATED for this region — B2-AC-33
///
/// § 6.5.2(b): the 2026-08-13 baseline was captured unauthenticated, so no
/// reference image of these four tiles exists and none can be produced without
/// a test citizen identity in a national-identity system (F0's blocking
/// question). **Tiers 1 and 2 still bind** — they read the source's strings and
/// the theme's values, not a screenshot — which is why every string below is a
/// dictionary key and every colour a token.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/entities/home_summary.dart';
import '../../domain/home_formatting.dart';

/// One tile's content, resolved from the summary.
class SummaryTile {
  const SummaryTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.destination,
  });

  /// A lucide component name, resolved at compile time — these four are page
  /// chrome, not catalogue data, so they do not go through `AppIcons.service`
  /// (§ 6.3.5 scopes that resolver to API-supplied names).
  final String icon;

  final String value;
  final String label;

  /// The route the tile navigates to. `history` / `account` / `wallet` in the
  /// source's `tab` field (`HomePage.tsx:345,352,359,366`).
  final String destination;
}

/// `HomePage.tsx:339-367`'s array, in order.
List<SummaryTile> summaryTilesFor(
  HomeSummary summary,
  String languageCode, {
  required String historyPath,
  required String accountPath,
  required String walletPath,
}) => <SummaryTile>[
  SummaryTile(
    icon: 'FileClock',
    value: summary.activeApplications.toString(),
    label: 'home.activeApplications'.tr(),
    destination: historyPath,
  ),
  SummaryTile(
    icon: 'FileCheck2',
    value: summary.readyDocuments.toString(),
    label: 'home.readyDocuments'.tr(),
    destination: accountPath,
  ),
  SummaryTile(
    icon: 'Wallet',
    // The only tile whose value is formatted rather than printed:
    // `formatLak(summary.data.wallet_balance_lak, lang)`
    // (`HomePage.tsx:357`), so a zero balance reads "Free"/"ຟຣີ" exactly
    // as the source renders it. That is odd copy for a balance and it is
    // the source's, not an error introduced here.
    value: formatLak(summary.walletBalanceLak, languageCode),
    label: 'home.walletBalance'.tr(),
    destination: walletPath,
  ),
  SummaryTile(
    icon: 'Bell',
    value: summary.unreadNotifications.toString(),
    label: 'home.unreadNotifications'.tr(),
    destination: accountPath,
  ),
];

/// The summary grid's cell shape, shared with the skeleton that stands in for
/// it so the two do not disagree about the page's height.
///
/// The web's tile is `h-24` (96 px) at a 171 px cell, i.e. 1.78 — but that is a
/// CSS box whose overflow is simply not drawn. A Flutter grid cell that is one
/// pixel short throws. 1.35 gives 127 px, which fits the 36 px icon tile, the
/// 20 px value, and a **two-line** label — and the Lao labels
/// ("ຄຳຮ້ອງທີ່ກຳລັງດຳເນີນ") are two lines at this width where the English are one.
const double kSummaryTileAspect = 1.35;

class SummaryTiles extends StatelessWidget {
  const SummaryTiles({super.key, required this.tiles, required this.onTileTap});

  final List<SummaryTile> tiles;
  final ValueChanged<String> onTileTap;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      // `grid grid-cols-2 gap-3`
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.gap12,
      mainAxisSpacing: AppSpacing.gap12,
      childAspectRatio: kSummaryTileAspect,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: tiles.map(_tile).toList(growable: false),
    );
  }

  Widget _tile(SummaryTile tile) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
      child: InkWell(
        onTap: () => onTileTap(tile.destination),
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        child: Container(
          // `bg-white rounded-2xl border border-gray-100 shadow-sm p-4
          //  text-left`
          padding: const EdgeInsets.all(AppSpacing.gap16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
            border: Border.all(color: AppColors.gray100),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: AppColors.cardShadow, blurRadius: 2),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: AppSpacing.tile36,
                height: AppSpacing.tile36,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Center(
                  child: LucideIcon(
                    name: tile.icon,
                    size: AppSpacing.gap20,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.gap10),
              Text(
                tile.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.gray900,
                  fontSize: AppTypography.size20,
                  fontWeight: AppTypography.bold,
                  height: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.gap6),
              Flexible(
                child: Text(
                  tile.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: AppTypography.size12,
                    height: AppTypography.lineSnug,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

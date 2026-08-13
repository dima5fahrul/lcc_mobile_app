/// `ServiceCard` — `ServiceCard.tsx:1-110` — and the "More" tile beside it.
///
/// ## Why Home has its own `ServiceCard` when `features/service/` has one
///
/// The source shares one component ("used on the home menu and the Service page
/// list"). G-L3 forbids the import: `features/home/**` may not reach into
/// `features/service/presentation/**`. The three placements that would avoid a
/// copy are each worse — `lib/presentation/common/` pulls a fourth widget past
/// § 6.3.4's "`GlassIcon` only" ruling, a shared `features/catalogue/` invents
/// a feature the SSD does not have, and B2c would face the same wall again.
///
/// This copy is also **not** a duplicate of B2a's file: B2a's renders the
/// catalogue list, which reads the fee from the row it was handed; this one
/// renders the home menu, which additionally must open the service sheet
/// (`onClick={() => setSelectedService(service)}`, `HomePage.tsx:490`) rather
/// than navigate. Recorded so the next reader does not "de-duplicate" two
/// widgets that answer to different pages.
///
/// ## The hover branch is ported and unreachable, deliberately
///
/// Every colour in this card has a `hover` value (`ServiceCard.tsx:53-100`).
/// A phone has no hover, so the resting branch is what renders — but Flutter's
/// `InkWell` gives a real hover state on a desktop or web build, and dropping
/// the branch would mean the card had no pressed/hover affordance at all where
/// the platform supports one. It is ported, it is one `MouseRegion`, and it
/// costs nothing on the target device.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/common/glass_icon.dart';
import '../../../../presentation/icons/app_icons.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../service/domain/entities/service.dart';
import '../../domain/home_formatting.dart';
import 'bilingual_text.dart';

/// `DEFAULT_ACCENT` — `ServiceCard.tsx:8`, the last link of
/// `service.color ?? category.color ?? "#344EAD"`.
///
/// The middle link — the category's colour — is **not** ported. It reads the
/// static `CATEGORIES` seed table, which `ServicePage.tsx:141-144` records as
/// legacy, and it cannot fire against today's catalogue: all 43 rows carry a
/// `color`. Porting a branch with no input is what `ServiceState.currentCategory`
/// declined to do for the same table, for the same reason.
Color accentFor(Service service) => service.color.isEmpty
    ? AppColors.categoryAccentFallback
    : AppColors.parseHex(service.color);

class HomeServiceCard extends StatefulWidget {
  const HomeServiceCard({
    super.key,
    required this.service,
    required this.onTap,
  });

  final Service service;
  final VoidCallback onTap;

  @override
  State<HomeServiceCard> createState() => _HomeServiceCardState();
}

class _HomeServiceCardState extends State<HomeServiceCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final Service service = widget.service;
    final String languageCode = Localizations.localeOf(context).languageCode;

    // `cfg.fee === 0 && cfg.feeMax == null` (`ServiceCard.tsx:31`). Expressed
    // against the wire row: `fee_is_range` false or `fee_max_lak` not above
    // `fee_lak` is the "no upper bound" case.
    final bool isRange =
        service.feeIsRange && service.feeMaxLak > service.feeLak;
    final bool isFree = service.feeLak == 0 && !isRange;

    final String fee = formatFee(
      fee: service.feeLak,
      feeMax: isRange ? service.feeMaxLak : null,
      languageCode: languageCode,
    );

    final Color titleColor = _hover ? AppColors.white : AppColors.gray800;
    final Color bodyColor = _hover
        ? AppColors.white.withValues(alpha: 0.72)
        : AppColors.muted;
    final Color feeColor = _hover
        ? AppColors.white
        : (isFree ? AppColors.success : AppColors.primary);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: _hover ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
          child: Container(
            // `rounded-2xl p-5 shadow-sm border flex flex-col`
            padding: const EdgeInsets.all(AppSpacing.gap20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
              border: Border.all(
                color: _hover
                    ? AppColors.headerGradientMid
                    : AppColors.gray100,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: AppColors.cardShadow, blurRadius: 2),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                GlassIcon(
                  // Scope-resolved before it reaches `GlassIcon`, which does
                  // not resolve scopes itself (§ 6.3.5): a name in Help's
                  // registry and not Service's must fall back to `FileText`
                  // here, exactly as the web's `serviceIcon()` does.
                  iconName: AppIcons.service(service.icon),
                  color: accentFor(service),
                  size: AppSpacing.tile56,
                ),
                const SizedBox(height: AppSpacing.gap16),
                Text(
                  service.name.forLanguage(languageCode),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: AppTypography.size18,
                    fontWeight: AppTypography.semiBold,
                    height: AppTypography.lineSnug,
                  ),
                ),
                const SizedBox(height: AppSpacing.gap4),
                // `Expanded`, and this is load-bearing rather than cosmetic: a
                // grid cell has a FIXED height, and the same card holds an
                // English description and a Lao one that wraps to a different
                // number of lines (§ 6.5.6 — "there is no canonical page
                // height per route"). Letting the description absorb the slack
                // is what stops the Lao render overflowing a box laid out
                // against the English one, which § 6.5.6 calls a Tier 1
                // failure by name.
                Expanded(
                  child: Text(
                    service.description.forLanguage(languageCode),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                    style: TextStyle(
                      color: bodyColor,
                      fontSize: AppTypography.size15,
                      height: AppTypography.lineSnug,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.gap12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: _hover
                              ? AppColors.white.withValues(alpha: 0.22)
                              : AppColors.gray100,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.gap12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            fee,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: feeColor,
                              // "a range steps down one type size, which keeps
                              // the amount on a single line down to a 360px
                              // screen" — `ServiceCard.tsx:41-45`.
                              fontSize: isRange
                                  ? AppTypography.size12
                                  : AppTypography.size14,
                              fontWeight: AppTypography.semiBold,
                              height: AppTypography.lineSnug,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.gap8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.gap12,
                              vertical: AppSpacing.gap6,
                            ),
                            decoration: BoxDecoration(
                              color: _hover
                                  ? AppColors.white
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull,
                              ),
                            ),
                            child: Text(
                              'home.applyNow'.tr(),
                              style: TextStyle(
                                color: _hover
                                    ? AppColors.primary
                                    : AppColors.white,
                                fontSize: AppTypography.size12,
                                fontWeight: AppTypography.semiBold,
                              ),
                            ),
                          ),
                        ],
                      ),
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

/// The dashed "More" tile — `HomePage.tsx:496-529`.
///
/// Shown only when not searching, and it navigates to the full catalogue
/// (`onTabChange("service")`) rather than opening a sheet.
class MoreServicesTile extends StatefulWidget {
  const MoreServicesTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<MoreServicesTile> createState() => _MoreServicesTileState();
}

class _MoreServicesTileState extends State<MoreServicesTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: _hover ? AppColors.primary : AppColors.moreTileSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.gap20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
              // `border border-dashed borderColor #C7D2FE`. Flutter's
              // `Border` has no dash pattern and a `CustomPainter` for one
              // would be ~60 lines to draw a hairline nobody has reported
              // seeing at 1 logical pixel on a 3x screen. Solid, recorded as a
              // MINOR Tier 3 candidate rather than silently equivalent.
              border: Border.all(color: AppColors.infoBorder),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: AppColors.cardShadow, blurRadius: 2),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const GlassIcon(
                  iconName: 'LayoutGrid',
                  color: AppColors.primary,
                  size: AppSpacing.tile56,
                ),
                const SizedBox(height: AppSpacing.gap16),
                Text(
                  'home.more'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _hover ? AppColors.white : AppColors.gray800,
                    fontSize: AppTypography.size16,
                    fontWeight: AppTypography.semiBold,
                    height: AppTypography.lineSnug,
                  ),
                ),
                const SizedBox(height: AppSpacing.gap4),
                Text(
                  'home.browseAll'.tr(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _hover
                        ? AppColors.white.withValues(alpha: 0.65)
                        // `#9CA3AF`, written inline in the source, so this is
                        // the STOCK grey and not `theme.css`'s accessible
                        // override — see `AppColors.gray400Inline`.
                        : AppColors.gray400Inline,
                    fontSize: AppTypography.size14,
                    height: AppTypography.lineSnug,
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

/// The chevron chip the sliders and links share — one glyph, one colour, three
/// call sites (`HomePage.tsx:586,697,732,782`).
class ChevronLabel extends StatelessWidget {
  const ChevronLabel({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = AppTypography.size14,
    this.leading,
  });

  final String label;
  final Color color;
  final double fontSize;
  final String? leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (leading != null) ...<Widget>[
          LucideIcon(name: leading!, size: AppSpacing.gap16, color: color),
          const SizedBox(width: AppSpacing.gap6),
        ],
        // `Flexible`, because this Row is `mainAxisSize.min` inside a
        // constrained parent: "Browse all help articles" is wider than the
        // gutter at 390 px and an unconstrained `Text` overflows rather than
        // wrapping.
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.gap4),
        LucideIcon(name: 'ChevronRight', size: AppSpacing.gap16, color: color),
      ],
    );
  }
}

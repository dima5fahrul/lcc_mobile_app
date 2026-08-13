/// One category tile in the catalogue's landing grid.
///
/// Port of `ServicePage.tsx:448-472`.
///
/// ## The count line is the only conditional
///
/// ```tsx
/// {count > 0 ? t("serviceCount", { count }) : t("comingSoon")}
/// style={{ color: count > 0 ? "#344EAD" : "#9CA3AF" }}
/// ```
/// `comingSoon` here means "this category has no services", not "this service
/// is not available" — the same key, a different claim. SSD § 13.3's
/// recommendation to reuse `service.comingSoon` on a *disabled service card* is
/// a separate, unimplemented thing (FU-7); do not conflate them when reading
/// the string table.
///
/// With today's catalogue all eight categories have services, so the
/// `comingSoon` branch does not render — which is exactly why it is tested with
/// a stubbed zero-count category rather than assumed.
///
/// ## Hover has no port
///
/// `group-hover:` lifts the card and darkens the chevron. There is no hover on
/// a touch device and Flutter's `InkWell` splash is a different affordance, not
/// a translation of one. Recorded rather than silently dropped: a Tier 3
/// reviewer comparing a desktop screenshot against a phone render will see the
/// resting state on both, because the baseline was captured without a pointer.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/common/glass_icon.dart';
import '../../../../presentation/icons/app_icons.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/entities/service_category.dart';
import 'bilingual_text.dart';
import 'catalogue_grid.dart';
import 'category_seed.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.count,
    required this.onTap,
  });

  final ServiceCategory category;

  /// Services in this category across the **whole** catalogue.
  final int count;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String languageCode = Localizations.localeOf(context).languageCode;
    final CategorySeed? seed = kCategorySeeds[category.code];

    // `c.color || seed?.color || "#344EAD"` — the wire wins, then the seed,
    // then brand blue.
    final Color accent = category.color.isNotEmpty
        ? AppColors.parseHex(
            category.color,
            fallback: seed?.fallbackColor ?? AppColors.categoryAccentFallback,
          )
        : (seed?.fallbackColor ?? AppColors.categoryAccentFallback);

    // `seed?.desc ?? ""` — an unknown category renders a blank blurb, not a
    // missing widget: the source keeps the `<p>` and empties it, so the card
    // keeps its height.
    final String description = seed?.descriptionFor(languageCode) ?? '';

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        child: DecoratedBox(
          decoration: catalogueCardDecoration,
          child: Padding(
            // `p-5`
            padding: const EdgeInsets.all(AppSpacing.gap20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // `flex items-start justify-between mb-4`
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    GlassIcon(
                      // Resolved through the SERVICE scope: `/service-categories`
                      // sends `icon` from the same vocabulary `/services` does,
                      // and `ServicePage.tsx:324` resolves it with the same
                      // `serviceIcon()`.
                      iconName: AppIcons.service(category.icon),
                      color: accent,
                      size: AppSpacing.tile56,
                    ),
                    const LucideIcon(
                      name: 'ChevronRight',
                      size: 16,
                      color: AppColors.gray300,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.gap16),
                // `text-base font-semibold text-gray-800 leading-snug`
                Text(
                  category.name.forLanguage(languageCode),
                  style: const TextStyle(
                    fontSize: AppTypography.size16,
                    fontWeight: AppTypography.semiBold,
                    color: AppColors.gray800,
                    height: AppTypography.lineSnug,
                  ),
                ),
                // `mt-1`
                const SizedBox(height: AppSpacing.gap4),
                // `text-sm text-gray-400 leading-snug` — the CLASS, so the
                // accessible override.
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: AppTypography.size14,
                    color: AppColors.gray400,
                    height: AppTypography.lineSnug,
                  ),
                ),
                // `mt-4`
                const SizedBox(height: AppSpacing.gap16),
                // `text-sm font-medium`, inline colour.
                Text(
                  count > 0
                      ? 'service.serviceCount'.tr(
                          namedArgs: <String, String>{'count': '$count'},
                        )
                      : 'service.comingSoon'.tr(),
                  style: TextStyle(
                    fontSize: AppTypography.size14,
                    fontWeight: AppTypography.medium,
                    // `#9CA3AF` is an INLINE hex in the source and therefore
                    // the stock grey, not `theme.css`'s accessible override.
                    color: count > 0
                        ? AppColors.primary
                        : AppColors.gray400Inline,
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

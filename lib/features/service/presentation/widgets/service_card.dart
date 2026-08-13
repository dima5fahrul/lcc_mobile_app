/// One service tile.
///
/// Port of `lcc-app/src/app/components/ServiceCard.tsx` (110 lines).
///
/// ## The tap is a no-op today, on purpose (C-4)
///
/// ```tsx
/// onClick={() => { if (s.tab) onTabChange(s.tab); }}   // ServicePage.tsx:503-505
/// ```
/// Note the absent `else`. 37 of 43 rows have no `tab` and their card is fully
/// styled, fully tappable and does nothing at all. `ServiceAvailability` is
/// what decides — never `route_path` (C-3) — and today it says no for all 43,
/// because none of the six certificate routes is mounted yet.
///
/// The card is deliberately **not** rendered as disabled. SSD § 13.3 recommends
/// exactly that, with the already-translated `service.comingSoon` string, and
/// it is a better product; it is also a user decision plus an ADR (FU-7) and
/// B2 must not quietly implement it. [ServiceCard] takes [onTap] and calls it
/// or does not; where the disabled treatment would go is the `onTap == null`
/// branch, and it currently looks identical to the enabled one.
///
/// ## What is not ported, and why
///
/// * **Hover.** The whole card inverts to brand blue on hover
///   (`ServiceCard.tsx:56-57,65,71,78,83,100-102`). No hover on touch; the
///   resting state is what the baseline screenshots captured, so it is the only
///   state Tier 3 compares.
/// * **`feeLoading`'s 0.55 opacity** (`:86`). It signals "the seeded fee is
///   being replaced by the catalogue's". This page has no seeded fee — it does
///   not draw a card until `/services` has answered — so the state it
///   represents cannot occur. Porting the opacity would mean porting the seed
///   table to have something to dim.
/// * **The `isRange` type-size step-down and the fee word-split**
///   (`:44-46,81,90-95`) ARE ported: they are the source's answer to a range
///   overflowing a card at 360 px, which is narrower than this app's target
///   width and therefore a live concern, not a desktop one.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/common/glass_icon.dart';
import '../../../../presentation/icons/app_icons.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/entities/service.dart';
import 'bilingual_text.dart';
import 'catalogue_grid.dart';
import 'category_seed.dart';
import 'service_fee.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({super.key, required this.service, required this.onTap});

  final Service service;

  /// Invoked on every tap. Whether it *does* anything is the caller's call —
  /// see the C-4 note above.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String languageCode = Localizations.localeOf(context).languageCode;

    // `service.color ?? CATEGORIES.find(...)?.color ?? DEFAULT_ACCENT`
    // (`ServiceCard.tsx:24-27`).
    final Color accent = service.color.isNotEmpty
        ? AppColors.parseHex(service.color)
        : (kCategorySeeds[service.categoryCode]?.fallbackColor ??
            AppColors.categoryAccentFallback);

    final String fee = formatFee(
      fee: service.feeLak,
      max: service.feeMaxLak,
      isRange: service.feeIsRange,
      languageCode: languageCode,
    );
    final bool free = isFreeFee(
      fee: service.feeLak,
      max: service.feeMaxLak,
      isRange: service.feeIsRange,
    );
    final bool ranged = service.feeIsRange && service.feeMaxLak > service.feeLak;

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
                // `mb-4`
                GlassIcon(
                  iconName: AppIcons.service(service.icon),
                  color: accent,
                  size: AppSpacing.tile56,
                ),
                const SizedBox(height: AppSpacing.gap16),
                // `text-lg font-semibold leading-snug`, inline `#1F2937`
                Text(
                  service.name.forLanguage(languageCode),
                  style: const TextStyle(
                    fontSize: AppTypography.size18,
                    fontWeight: AppTypography.semiBold,
                    color: AppColors.gray800,
                    height: AppTypography.lineSnug,
                  ),
                ),
                // `mt-1`
                const SizedBox(height: AppSpacing.gap4),
                // `text-[15px] leading-snug`, inline `#6B7280`
                Text(
                  service.description.forLanguage(languageCode),
                  style: const TextStyle(
                    fontSize: AppTypography.size15,
                    color: AppColors.muted,
                    height: AppTypography.lineSnug,
                  ),
                ),
                // `mt-4 pt-3 border-t`
                const SizedBox(height: AppSpacing.gap16),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.gray100,
                ),
                const SizedBox(height: AppSpacing.gap12),
                _FeeRow(fee: fee, free: free, ranged: ranged),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The fee and the "Apply Now" chip.
///
/// `flex-col items-start gap-2 sm:flex-row sm:items-center sm:justify-between`
/// — the source stacks them below the `sm` breakpoint (640 px) and only puts
/// them side by side above it. At the app's target width that is **always the
/// stacked branch**, so this is a `Column`. Rendering the row layout would be
/// porting the desktop treatment onto a phone.
class _FeeRow extends StatelessWidget {
  const _FeeRow({required this.fee, required this.free, required this.ranged});

  final String fee;
  final bool free;
  final bool ranged;

  @override
  Widget build(BuildContext context) {
    // `const splitAt = fee.lastIndexOf(" ")` — the currency word is split off
    // so the line can break there before it breaks mid-number.
    final int splitAt = fee.lastIndexOf(' ');
    final String amount = splitAt > 0 ? fee.substring(0, splitAt) : fee;
    final String unit = splitAt > 0 ? fee.substring(splitAt + 1) : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // One `Text`, two spans. The source's `whitespace-nowrap` on the unit
        // has **no Flutter counterpart and needs none**: it exists because CSS
        // would happily break `100,000 LAK` after the space *and* leave the
        // unit orphaned, and Flutter's only break opportunity inside a single
        // word is… none. `LAK` / `ກີບ` is one word with no internal break
        // point, so the span is unbreakable already. Ported as a plain
        // `TextSpan` rather than a `WidgetSpan` for that reason — and because a
        // `WidgetSpan` would put a second `Text` in the tree, which the Tier 1
        // dump would read as two nodes where the web presents one.
        Text.rich(
          TextSpan(
            text: amount,
            children: unit.isEmpty
                ? null
                : <InlineSpan>[TextSpan(text: ' $unit')],
          ),
          style: TextStyle(
            // `${isRange ? "text-xs" : "text-sm"}` — a range steps down one
            // size so the amount stays on one line down to a 360 px screen.
            fontSize: ranged ? AppTypography.size12 : AppTypography.size14,
            fontWeight: AppTypography.semiBold,
            height: AppTypography.lineSnug,
            color: free ? AppColors.success : AppColors.primary,
          ),
        ),
        // `gap-2`
        const SizedBox(height: AppSpacing.gap8),
        // `text-xs font-semibold px-3 py-1.5 rounded-full`, white on brand.
        // The label comes from the HOME namespace: `useT("home")` at
        // `ServiceCard.tsx:18`. It is not a typo in the source and it is not
        // re-homed here — `assets/i18n/*.json` mirrors the React dictionaries
        // namespace for namespace (SSD § 10.2), so moving the key would break
        // the mirror this port is checked against.
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gap12,
            vertical: AppSpacing.gap6,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            'home.applyNow'.tr(),
            softWrap: false,
            style: const TextStyle(
              fontSize: AppTypography.size12,
              fontWeight: AppTypography.semiBold,
              color: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }
}

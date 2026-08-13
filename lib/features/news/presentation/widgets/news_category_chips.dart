/// The category filter row — "All" plus one chip per `/news/categories` row.
///
/// `NewsPage.tsx:90-121`. `flex flex-wrap gap-2`, so the chips wrap rather than
/// scroll; a `Wrap` is the direct port and is also what keeps every chip
/// reachable by a Tier 1 dump (a horizontal `ListView` would build only the
/// ones in frame — the trap B2b's Tier 1 test documents for Home's sliders).
///
/// The **active** chip is painted with the category's own wire colour
/// (`backgroundColor: c.color, borderColor: c.color, color: white`); "All" uses
/// the brand. Inactive is white / `#E5E7EB` / `#4B5563` for every chip.
///
/// `#4B5563` is Tailwind `gray-600`, which the theme holds as
/// `AppColors.gray600` (`#4A5565` — the value the source's own Tailwind build
/// emits; see that token's doc for why the two spellings differ).
library;

import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/entities/news_category.dart';
import '../../domain/news_formatting.dart';
import '../../domain/usecases/news_usecases.dart';
import 'bilingual_text.dart';

class NewsCategoryChips extends StatelessWidget {
  const NewsCategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.allLabel,
    required this.onPick,
  });

  final List<NewsCategory> categories;

  /// A `NewsCategory.code`, or [kNewsAllCategories].
  final String selected;

  final String allLabel;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.gap8,
      runSpacing: AppSpacing.gap8,
      children: <Widget>[
        _Chip(
          label: allLabel,
          active: selected == kNewsAllCategories,
          // `{ backgroundColor: "#344EAD", borderColor: "#344EAD" }` — the
          // "All" chip is the only one whose active colour is a token rather
          // than wire data.
          activeColor: AppColors.primary,
          onTap: () => onPick(kNewsAllCategories),
        ),
        for (final NewsCategory category in categories)
          _Chip(
            label: category.name.forContext(context),
            active: selected == category.code,
            activeColor: _activeColor(category.color),
            onTap: () => onPick(category.code),
          ),
      ],
    );
  }

  /// `{ backgroundColor: c.color, borderColor: c.color }`. A wire value that is
  /// not `#RRGGBB` leaves the CSS declaration invalid, so the chip keeps its
  /// inactive surface; the nearest faithful Flutter rendering of "the colour
  /// did not apply" on an *active* chip is the brand, which is what the
  /// surrounding page is painted with.
  static Color _activeColor(String wire) {
    final int? solid = newsSolid(wire);
    return solid == null ? AppColors.primary : Color(solid);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      // `aria-pressed={active}` — `NewsPage.tsx:93,109`.
      selected: active,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Container(
          // `px-4 py-2 rounded-full text-sm font-medium border`
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gap16,
            vertical: AppSpacing.gap8,
          ),
          decoration: BoxDecoration(
            color: active ? activeColor : AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: active ? activeColor : AppColors.gray200,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? AppColors.white : AppColors.gray600,
              fontSize: AppTypography.size14,
              fontWeight: AppTypography.medium,
            ),
          ),
        ),
      ),
    );
  }
}

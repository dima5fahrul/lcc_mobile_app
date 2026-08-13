/// The pill that names an article's category, tinted with the category's own
/// wire colour.
///
/// `NewsPage.tsx:177-182` and `NewsDetailPage.tsx:41-51` (`CategoryBadge`) are
/// the same span: `text-[11px] font-semibold px-2.5 py-1 rounded-full`, with
/// `backgroundColor: tint(color)` and `color` as the text colour.
///
/// ## Runtime colour, not a token
///
/// `category_color` is published by `/news` and `/news/categories` and changes
/// without an app release, so it is parsed at the edge (`newsSolid` /
/// `newsTint` in `domain/news_formatting.dart`) and never transcribed into
/// `presentation/theme/`. When the wire value is not a `#RRGGBB` string the
/// source falls back to the literal `#EEF2FF` for the wash — which **is**
/// `AppColors.primarySoft`, so the fallback resolves through the theme and this
/// file names no colour of its own (B2-AC-11).
library;

import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/news_formatting.dart';

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({
    super.key,
    required this.label,
    required this.color,
  });

  /// Already resolved to the reading language.
  final String label;

  /// The raw wire value, e.g. `#3752AE`. May be empty or malformed.
  final String color;

  @override
  Widget build(BuildContext context) {
    final int? solid = newsSolid(color);
    final ({int? argb, bool isFallback}) wash = newsTint(color);

    return Container(
      // `px-2.5 py-1`
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gap10,
        vertical: AppSpacing.gap4,
      ),
      decoration: BoxDecoration(
        color: wash.isFallback ? AppColors.primarySoft : Color(wash.argb!),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        // `style={{ color }}` with no fallback on the web: an unusable
        // `category_color` yields `color: ""`, which CSS ignores and the span
        // inherits. `AppColors.primary` is the inherited brand colour on both
        // surfaces this badge appears on, so it is the same rendering.
        style: TextStyle(
          color: solid == null ? AppColors.primary : Color(solid),
          fontSize: AppTypography.size11,
          fontWeight: AppTypography.semiBold,
        ),
      ),
    );
  }
}

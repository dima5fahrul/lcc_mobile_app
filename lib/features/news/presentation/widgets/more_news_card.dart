/// One row of the detail page's "More news" strip.
///
/// `NewsDetailPage.tsx:258-286`: a smaller thumbnail, the category badge, a
/// two-line headline, and a trailing chevron. Distinct from
/// `NewsArticleCard` — no date, no excerpt, no "Read more", and a different
/// thumbnail aspect — so it is its own widget rather than a flag on that one.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/entities/news_article.dart';
import 'bilingual_text.dart';
import 'category_badge.dart';
import 'news_cover.dart';

/// `w-24 h-20` — 96 × 80 CSS px.
const double kMoreThumbWidth = AppSpacing.gap24 * 4;
const double kMoreThumbHeight = AppSpacing.gap40 * 2;

class MoreNewsCard extends StatelessWidget {
  const MoreNewsCard({
    super.key,
    required this.article,
    required this.onTap,
  });

  final NewsArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
      child: Container(
        // `bg-white rounded-2xl border border-gray-100 p-2.5`
        padding: const EdgeInsets.all(AppSpacing.gap10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Row(
          children: <Widget>[
            NewsCover(
              coverUrl: article.coverUrl,
              categoryColor: article.categoryColor,
              width: kMoreThumbWidth,
              height: kMoreThumbHeight,
              radius: AppSpacing.radiusXl,
            ),
            const SizedBox(width: AppSpacing.gap12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CategoryBadge(
                      label: article.categoryName.forContext(context),
                      color: article.categoryColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gap6),
                  Text(
                    article.title.forContext(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.gray800,
                      fontSize: AppTypography.size14,
                      fontWeight: AppTypography.semiBold,
                      height: AppTypography.lineSnug,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.gap12),
            // `aria-hidden` — decorative, so it carries no semantics label.
            const LucideIcon(
              name: 'ChevronRight',
              size: AppSpacing.gap20,
              color: AppColors.gray300,
            ),
          ],
        ),
      ),
    );
  }
}

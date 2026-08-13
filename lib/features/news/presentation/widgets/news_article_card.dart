/// One row of the `/news` list — thumbnail, category badge, date, headline,
/// excerpt, "Read more".
///
/// `NewsPage.tsx:154-199`. The web renders it as an `<a href="#/news/<id>">`;
/// here it is an `InkWell` whose tap the page turns into
/// `context.go('/news/<slug>')` — the same navigation through the router the
/// rest of the app uses, and the reason the slug (not a catalogue position) is
/// the identity: see `NewsRepository`'s doc.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/news_formatting.dart';
import 'bilingual_text.dart';
import 'category_badge.dart';
import 'news_cover.dart';

/// `w-28 h-28` — 112 CSS px. Derived from the scale rather than written bare,
/// and not added to `AppSpacing` (B2c may not touch `presentation/theme/` —
/// see `news_panels.dart`'s note on the same constraint).
const double kNewsThumbSide = AppSpacing.tile56 * 2;

class NewsArticleCard extends StatelessWidget {
  const NewsArticleCard({
    super.key,
    required this.article,
    required this.readMoreLabel,
    required this.onTap,
  });

  final NewsArticle article;
  final String readMoreLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String language = Localizations.localeOf(context).languageCode;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
      child: Container(
        // `flex gap-4 bg-white rounded-2xl border border-gray-100 p-3`
        padding: const EdgeInsets.all(AppSpacing.gap12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NewsCover(
              coverUrl: article.coverUrl,
              categoryColor: article.categoryColor,
              width: kNewsThumbSide,
              height: kNewsThumbSide,
              radius: AppSpacing.radiusXl,
            ),
            const SizedBox(width: AppSpacing.gap16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: CategoryBadge(
                          label: article.categoryName.forContext(context),
                          color: article.categoryColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.gap8),
                      Text(
                        formatNewsDate(article.publishedOn, language),
                        style: const TextStyle(
                          color: AppColors.gray500,
                          fontSize: AppTypography.size12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.gap8),
                  // `text-sm font-semibold leading-snug line-clamp-2`
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
                  const SizedBox(height: AppSpacing.gap4),
                  // `text-xs leading-relaxed line-clamp-2`
                  Text(
                    article.excerpt.forContext(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: AppTypography.size12,
                      height: AppTypography.lineRelaxed,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gap8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        readMoreLabel,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: AppTypography.size12,
                          fontWeight: AppTypography.semiBold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.gap4),
                      const LucideIcon(
                        name: 'ChevronRight',
                        size: AppSpacing.gap14,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

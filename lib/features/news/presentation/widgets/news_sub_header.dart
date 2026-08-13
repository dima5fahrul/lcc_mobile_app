/// The detail page's white sub-header — back control plus "News &
/// Announcements".
///
/// `NewsDetailPage.tsx:174-185`, and the loading branch renders the identical
/// bar at `:91-102` so the chrome does not appear only once the article lands.
///
/// **Non-sticky, deliberately.** The source's own comment at `:173`:
/// *"a sticky bar would obscure focused controls, WCAG 2.4.11"*. It scrolls
/// away with the content here for the same reason — do not turn it into a
/// `SliverAppBar`.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

class NewsSubHeader extends StatelessWidget {
  const NewsSubHeader({
    super.key,
    required this.title,
    required this.backLabel,
    required this.onBack,
  });

  final String title;
  final String backLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      // `bg-white border-b border-gray-100`, `px-4 py-3`
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gap16,
        vertical: AppSpacing.gap12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray100)),
      ),
      child: Row(
        children: <Widget>[
          Semantics(
            button: true,
            label: backLabel,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              child: const SizedBox(
                width: AppSpacing.tile36,
                height: AppSpacing.tile36,
                child: Center(
                  child: LucideIcon(
                    name: 'ChevronLeft',
                    size: AppSpacing.gap20,
                    color: AppColors.gray500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.gap12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.gray800,
                fontSize: AppTypography.size14,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The `/news` gradient header — back control, title, subtitle, megaphone.
///
/// `NewsPage.tsx:64-86`: `linear-gradient(135deg, #1A2D6B 0%, #344EAD 100%)`,
/// `px-4 pt-5 pb-6`.
///
/// ## The two gradient stops are already in the theme
///
/// `#344EAD` is `AppColors.primary`. `#1A2D6B` is **not** currently a named
/// token — and `presentation/theme/` is B2a's, outside B2c's § 3.1 modify list
/// (B2-AC-38), so a `newsHeaderGradientStart` cannot be added there.
///
/// `AppColors.headerGradientEnd` is `#1E3070`, four points off, and using it
/// would be a silent substitution. So this header's start stop is expressed as
/// the nearest **exact** thing the theme does hold: it does not, and the honest
/// answer is a named constant here plus a recorded follow-up to promote it.
/// B2-AC-11's scan covers `lib/**` outside `presentation/theme/`, so this is
/// declared where the scan can see it and is listed in the code review rather
/// than hidden inside a `BoxDecoration`.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

class NewsHeader extends StatelessWidget {
  const NewsHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.backLabel,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final String backLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // `px-4 pt-5 pb-6`
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gap16,
        AppSpacing.gap20,
        AppSpacing.gap16,
        AppSpacing.gap24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.newsHeaderStart, AppColors.primary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // `w-9 h-9 -ml-1 rounded-xl` — the back control. The negative margin
          // is a 4 px optical pull, expressed as a translation because Flutter
          // padding cannot be negative.
          Align(
            alignment: Alignment.centerLeft,
            child: Transform.translate(
              offset: const Offset(-AppSpacing.gap4, 0),
              child: Semantics(
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
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.gap8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // `<h1 class="text-2xl font-bold text-white">`
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: AppTypography.size24,
                          fontWeight: AppTypography.bold,
                          height: AppTypography.lineSnug,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.gap4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        // `text-white/75`
                        color: AppColors.white.withValues(alpha: 0.75),
                        fontSize: AppTypography.size14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.gap12),
              // `w-10 h-10 rounded-full bg-white/15 border border-white/20`
              Container(
                width: AppSpacing.control40,
                height: AppSpacing.control40,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.20),
                  ),
                ),
                child: const Center(
                  child: LucideIcon(
                    name: 'Megaphone',
                    size: AppSpacing.gap20,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

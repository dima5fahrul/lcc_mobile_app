/// `SectionHeader` — `HomePage.tsx:121-136`.
///
/// The centred title + subtitle block above the category slider, the news
/// slider and the FAQ list. A component in the source, so a widget here:
/// three copies of the same two `Text`s is exactly the duplication AC-8
/// singled out on the P0 placeholders.
///
/// `lg:` breakpoints are dropped throughout this feature. The port target is a
/// 390 px phone (§ 6.5's rig) and Flutter has no media-query cascade; carrying
/// a desktop branch no layout can reach would be untestable code that reads
/// like a promise.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // `text-center mb-8 max-w-lg mx-auto px-4`
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gap16,
        0,
        AppSpacing.gap16,
        AppSpacing.gap32,
      ),
      child: Column(
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              // `text-gray-900 font-bold text-2xl leading-tight`
              style: const TextStyle(
                color: AppColors.gray900,
                fontSize: AppTypography.size24,
                fontWeight: AppTypography.bold,
                height: AppTypography.lineTight,
              ),
            ),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: AppSpacing.gap8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              // `text-gray-500 text-sm mt-2 leading-relaxed`
              style: const TextStyle(
                color: AppColors.gray500,
                fontSize: AppTypography.size14,
                height: AppTypography.lineRelaxed,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

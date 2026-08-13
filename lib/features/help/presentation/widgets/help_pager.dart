/// The question list's pager — `‹  page / total  ›`.
///
/// `HelpCenterPage.tsx:367-389`, which is byte-for-byte news' pager including
/// both `aria-label`s. This is help's copy; news holds its own, because G-L3
/// forbids importing another feature's `presentation/` (see
/// `bilingual_text.dart` for the same ruling and the same rejected
/// alternatives).
///
/// `disabled:opacity-40` — an end control stays visible and dimmed, so the
/// pager does not reflow when the citizen reaches one.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

class HelpPager extends StatelessWidget {
  const HelpPager({
    super.key,
    required this.page,
    required this.totalPages,
    required this.hasPrev,
    required this.hasNext,
    required this.previousLabel,
    required this.nextLabel,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final bool hasPrev;
  final bool hasNext;
  final String previousLabel;
  final String nextLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _PagerButton(
          icon: 'ChevronLeft',
          label: previousLabel,
          enabled: hasPrev,
          onTap: onPrevious,
        ),
        const SizedBox(width: AppSpacing.gap12),
        Text(
          '$page / $totalPages',
          style: const TextStyle(
            color: AppColors.gray500,
            fontSize: AppTypography.size12,
          ),
        ),
        const SizedBox(width: AppSpacing.gap12),
        _PagerButton(
          icon: 'ChevronRight',
          label: nextLabel,
          enabled: hasNext,
          onTap: onNext,
        ),
      ],
    );
  }
}

class _PagerButton extends StatelessWidget {
  const _PagerButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Container(
            width: AppSpacing.tile36,
            height: AppSpacing.tile36,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Center(
              child: LucideIcon(
                name: icon,
                size: AppSpacing.gap16,
                color: AppColors.gray500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

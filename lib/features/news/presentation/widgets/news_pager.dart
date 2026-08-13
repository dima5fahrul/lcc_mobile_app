/// The list pager — `‹  page / total  ›`.
///
/// `NewsPage.tsx:205-227` and `HelpCenterPage.tsx:367-389` are the same
/// control, byte for byte, including the two `aria-label`s. This is news' copy;
/// help holds its own, because G-L3 forbids the import (see
/// `bilingual_text.dart` for the same ruling on a smaller widget).
///
/// The **disabled** rendering is `disabled:opacity-40` — the control stays
/// visible and dimmed rather than disappearing, so the pager does not reflow
/// when the citizen reaches an end.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

class NewsPager extends StatelessWidget {
  const NewsPager({
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

  /// `aria-label` — "Previous page" / "ໜ້າກ່ອນ".
  final String previousLabel;

  /// `aria-label` — "Next page" / "ໜ້າຕໍ່ໄປ".
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
        // `{meta.page} / {meta.total_pages}` — the literal spacing matters to
        // a Tier 1 text comparison.
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
        // `disabled:opacity-40`
        opacity: enabled ? 1 : 0.4,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Container(
            // `w-9 h-9 rounded-xl bg-white border border-gray-200`
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

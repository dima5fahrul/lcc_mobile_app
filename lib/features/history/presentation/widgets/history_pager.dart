/// The list pager — `HistoryPage.tsx:406-427`.
///
/// `‹ Back    page / total_pages · total    Next ›`, inside the same white
/// rounded card the rows use.
///
/// ## Three ways it differs from `NewsPager`, all of them the source's
///
/// 1. **It prints `total`.** `{meta.page} / {meta.total_pages} · {meta.total}`
///    (`:418`) — news prints only the two page numbers. This is why
///    `ApplicationPage` carries `total` as a required field where
///    `NewsPageResult` omits it.
/// 2. **Its buttons carry `common.back` / `common.next` as visible labels**
///    (`:415`, `:424`), not as `aria-label`s on icon-only controls.
/// 3. **It is gated on `total_pages > 1` alone** (`:407`), not on
///    `!loading && !error` as well. It stays mounted across a refetch with its
///    buttons disabled, rather than disappearing and reflowing the page.
///
/// A history-local file rather than a reach into news' or help's copy: G-L3
/// forbids the import, and the three differences above mean it would have to be
/// parameterised into something neither surface wants.
///
/// The **disabled** rendering is `disabled:opacity-40` — the control stays
/// visible and dimmed rather than disappearing.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

/// `disabled:opacity-40`.
const double kPagerDisabledOpacity = 0.4;

class HistoryPager extends StatelessWidget {
  const HistoryPager({
    super.key,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.canGoPrev,
    required this.canGoNext,
    required this.previousLabel,
    required this.nextLabel,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;

  /// `meta.total` — the third number, which news' pager has no equivalent of.
  final int total;

  /// `meta.has_prev && !list.loading` (`:411`).
  final bool canGoPrev;

  /// `meta.has_next && !list.loading` (`:422`).
  final bool canGoNext;

  final String previousLabel;
  final String nextLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gap16,
        vertical: AppSpacing.gap12,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _PagerButton(
            icon: 'ChevronLeft',
            label: previousLabel,
            iconLeading: true,
            enabled: canGoPrev,
            onTap: onPrevious,
          ),
          // The literal spacing matters to a Tier 1 text comparison:
          // `{page} / {total_pages} · {total}`, single spaces, a middle dot.
          Text(
            '$page / $totalPages · $total',
            style: const TextStyle(
              fontSize: AppTypography.size12,
              color: AppColors.gray500,
            ),
          ),
          _PagerButton(
            icon: 'ChevronRight',
            label: nextLabel,
            iconLeading: false,
            enabled: canGoNext,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _PagerButton extends StatelessWidget {
  const _PagerButton({
    required this.icon,
    required this.label,
    required this.iconLeading,
    required this.enabled,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool iconLeading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget glyph = LucideIcon(
      name: icon,
      size: AppSpacing.gap14,
      color: AppColors.muted,
    );
    final Widget text = Text(
      label,
      style: const TextStyle(
        fontSize: AppTypography.size12,
        fontWeight: AppTypography.medium,
        color: AppColors.muted,
      ),
    );

    return Opacity(
      opacity: enabled ? 1 : kPagerDisabledOpacity,
      child: GestureDetector(
        // A disabled control must not fire. `IgnorePointer` rather than a null
        // callback so the dimmed pill still occupies its space and the row does
        // not reflow when an end is reached.
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gap12,
            vertical: AppSpacing.gap6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (iconLeading) ...<Widget>[
                glyph,
                const SizedBox(width: AppSpacing.gap4),
                text,
              ] else ...<Widget>[
                text,
                const SizedBox(width: AppSpacing.gap4),
                glyph,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

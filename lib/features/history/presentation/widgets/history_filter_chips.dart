/// The filter chip row — `HistoryPage.tsx:193-219`.
///
/// A leading funnel glyph plus four pills, horizontally scrollable
/// (`overflow-x-auto`). The active pill is filled `#344EAD` with white text;
/// the rest are white with `#6B7280` text and an `#E5E7EB` border (`:203-215`).
///
/// **The chip ids are `kFilterStatuses`' keys** — they index the table that
/// decides what goes on the wire, so a chip whose id drifted from that table
/// would render, highlight, and filter by nothing (`B7-AC-18`). The label keys
/// are *not* parallel to the ids (`pending` → `filterInReview`), which is why
/// both live in `kHistoryFilterChips` rather than being derived from each
/// other.
///
/// **A recorded icon divergence.** The leading glyph is lucide's `Filter`
/// (`:195`), and there is no `Filter.svg` in `assets/icons/lucide/`;
/// `assets/icons/**` is out of B7's scope (§ 4.1). Material's
/// `filter_alt_outlined` — the same funnel — renders instead. Invisible to
/// Tier 1 and Tier 2; recorded here and in the batch report rather than
/// absorbed.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

class HistoryFilterChips extends StatelessWidget {
  const HistoryFilterChips({
    super.key,
    required this.chips,
    required this.active,
    required this.onPick,
  });

  /// `(id, label)` in render order — resolved by the page so this widget holds
  /// no i18n dependency and a test can pump it with plain strings.
  final List<(String, String)> chips;

  /// The selected id.
  final String active;

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.gap32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.gap8),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return const Center(
              child: Icon(
                Icons.filter_alt_outlined,
                size: AppSpacing.gap16,
                color: AppColors.gray400Inline,
              ),
            );
          }

          final (String id, String label) = chips[index - 1];
          final bool isActive = id == active;

          return Center(
            child: GestureDetector(
              onTap: () => onPick(id),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gap14,
                  vertical: AppSpacing.gap6,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: isActive ? AppColors.primary : AppColors.gray200,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTypography.size12,
                    fontWeight: AppTypography.medium,
                    color: isActive ? AppColors.white : AppColors.muted,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

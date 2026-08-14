/// The four count tiles — `HistoryPage.tsx:163-190`.
///
/// A 2×2 grid on mobile (`grid-cols-2 sm:grid-cols-4`; the Flutter surface is
/// phone-width, so the `sm:` arm never applies). Each card is a label, a
/// coloured dot, and the number.
///
/// ## `"—"` while loading, never `0` (`B7-AC-36`)
///
/// `{counts.loading ? "—" : s.value}` (`:186`). The distinction is the whole
/// point: `0` is a true statement about an empty account and a false one about
/// an account whose counts have not arrived, and this surface exists on a
/// build where every real account is empty — so a tile that printed `0` while
/// loading would be indistinguishable from the correct answer and could not be
/// caught by looking at it.
///
/// ## The numbers do not follow the filter chips (§ 6.8)
///
/// Their `useQuery` deps are `[]`. Changing the chip or the search text does
/// not refresh them; returning from the detail does. That lives in
/// `HistoryBloc`, not here — this widget draws whatever it is handed.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../bloc/history_bloc.dart';
import 'history_palette.dart';

/// `{counts.loading ? "—" : s.value}` — the em-dash placeholder.
///
/// The same `"—"` `formatDate` uses for an absent date, and deliberately not a
/// hyphen: `U+2014`, one character.
const String kCountPlaceholder = '—';

/// `fontSize: "22px", fontWeight: 600` — `HistoryPage.tsx:185`.
///
/// Not an `AppTypography` step: 22 is not on the scale, and
/// `lib/presentation/**` is frozen for B7 (`B7-AC-12`), so it is a local
/// constant with its source cited rather than a bare literal or a new step.
const double kTileValueSize = 22;

class HistoryStatTiles extends StatelessWidget {
  const HistoryStatTiles({
    super.key,
    required this.counts,
    required this.loading,
    required this.totalLabel,
    required this.approvedLabel,
    required this.inReviewLabel,
    required this.rejectedLabel,
  });

  final HistoryCounts counts;

  /// `counts.loading`. Every tile prints [kCountPlaceholder] while true.
  final bool loading;

  final String totalLabel;
  final String approvedLabel;
  final String inReviewLabel;
  final String rejectedLabel;

  @override
  Widget build(BuildContext context) {
    // The source's array order, which is also the render order:
    // total, approved, pending, rejected (`:165-169`). Note the third tile's
    // label is `statInReview` while its number is `tiles.pending` — the label
    // and the bucket are not spelled the same, and swapping them would look
    // right.
    final List<(String, int, StatTileStyle)> tiles = <(String, int, StatTileStyle)>[
      (totalLabel, counts.total, kTileTotal),
      (approvedLabel, counts.approved, kTileApproved),
      (inReviewLabel, counts.pending, kTileInReview),
      (rejectedLabel, counts.rejected, kTileRejected),
    ];

    return Column(
      children: <Widget>[
        Row(children: _pair(tiles[0], tiles[1])),
        const SizedBox(height: AppSpacing.gap12),
        Row(children: _pair(tiles[2], tiles[3])),
      ],
    );
  }

  List<Widget> _pair(
    (String, int, StatTileStyle) left,
    (String, int, StatTileStyle) right,
  ) =>
      <Widget>[
        Expanded(child: _Tile(spec: left, loading: loading)),
        const SizedBox(width: AppSpacing.gap12),
        Expanded(child: _Tile(spec: right, loading: loading)),
      ];
}

class _Tile extends StatelessWidget {
  const _Tile({required this.spec, required this.loading});

  final (String, int, StatTileStyle) spec;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final (String label, int value, StatTileStyle style) = spec;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.gap16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: AppTypography.size12,
                    color: AppColors.gray500,
                  ),
                ),
              ),
              // `w-2 h-2 rounded-full` in the tile's colour (`:180-183`).
              Container(
                width: AppSpacing.gap8,
                height: AppSpacing.gap8,
                decoration: BoxDecoration(
                  color: style.color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.gap4),
          Text(
            loading ? kCountPlaceholder : '$value',
            style: TextStyle(
              fontSize: kTileValueSize,
              fontWeight: AppTypography.semiBold,
              color: style.color,
            ),
          ),
        ],
      ),
    );
  }
}

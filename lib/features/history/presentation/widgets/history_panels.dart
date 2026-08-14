/// The three non-data states of `/history`'s list: skeleton, error, empty.
///
/// § 6.6's four-state contract is binding — *every* network-backed surface
/// renders loading · data · empty · error-with-retry, and a missing state is a
/// Tier 1 failure, not polish.
///
/// A history-local file rather than a reach into
/// `features/news/presentation/widgets/news_panels.dart`: G-L3 forbids that
/// import, and the two are not the same widgets anyway — news' skeleton is a
/// card with a 160 px cover, and this one is the row's 12×12 tile plus three
/// bars (`HistoryPage.tsx:236-247`).
library;

import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

/// `py-10` — 40 CSS px, the vertical padding on the empty and error panels
/// (`HistoryPage.tsx:225`, `:251`, `:267`). Both are `p-10`, unlike news' `py-12`.
const double kHistoryPanelPadding = AppSpacing.gap40;

/// `space-y-3` between rows and between skeletons (`:236`).
const double kHistoryRowGap = AppSpacing.gap12;

/// One skeleton row — `HistoryPage.tsx:238-246`.
///
/// Static rather than animated: `animate-pulse` is a Tailwind opacity
/// keyframe, and a widget test that pumps a running animation either settles
/// forever or asserts on a random frame (`NewsSkeleton`'s note).
///
/// **Exactly three of these render, and only while `rows.length == 0`**
/// (`B7-AC-34`). The count lives in `HistoryPage`, not here, so this widget
/// stays a single row a test can find `findsNWidgets(3)` of.
class HistorySkeletonRow extends StatelessWidget {
  const HistorySkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gap20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // `w-12 h-12 rounded-2xl bg-gray-100`
          _Bar(
            height: AppSpacing.tile48,
            width: AppSpacing.tile48,
            radius: AppSpacing.radius2xl,
          ),
          const SizedBox(width: AppSpacing.gap16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // `h-3.5 w-2/5 bg-gray-200`
                FractionallySizedBox(
                  widthFactor: 0.4,
                  child: _Bar(height: 14, color: AppColors.gray200),
                ),
                const SizedBox(height: AppSpacing.gap12),
                // `h-3 w-1/4 bg-gray-100`
                FractionallySizedBox(
                  widthFactor: 0.25,
                  child: _Bar(height: AppSpacing.gap12),
                ),
                const SizedBox(height: AppSpacing.gap12),
                // `h-1.5 w-full bg-gray-100 rounded-full`
                _Bar(height: AppSpacing.gap6, radius: AppSpacing.radiusFull),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.height,
    this.width,
    this.radius = AppSpacing.radiusLg,
    this.color = AppColors.gray100,
  });

  final double height;
  final double? width;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// The shared card chrome of the empty and error panels — `p-10 text-center`
/// with a 14×14 rounded tile above the copy (`:267-278`, `:250-263`).
class _Panel extends StatelessWidget {
  const _Panel({required this.tile, required this.children});

  final Widget tile;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kHistoryPanelPadding),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        children: <Widget>[
          tile,
          const SizedBox(height: AppSpacing.gap12),
          ...children,
        ],
      ),
    );
  }
}

/// `rows.length === 0` — `HistoryPage.tsx:266-279`.
///
/// Two lines: `emptyTitle` always, and **one of two** subtitles —
/// `emptySubtitle` when a search or a non-`all` filter is active, otherwise the
/// lifted `emptyHint` ("Once you submit a request it will show up here.").
/// Both branches are asserted (`B7-AC-33`); the caller decides which, so this
/// widget takes the resolved string and cannot silently render the wrong one.
class HistoryEmptyBlock extends StatelessWidget {
  const HistoryEmptyBlock({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      // `bg-gray-100` + `FileText` at `text-gray-400` (`:268-270`).
      tile: const _GlyphTile(
        background: AppColors.gray100,
        child: LucideGlyph(name: 'FileText', colour: AppColors.gray400Inline),
      ),
      children: <Widget>[
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: AppTypography.size14,
            fontWeight: AppTypography.medium,
            color: AppColors.gray700,
          ),
        ),
        const SizedBox(height: AppSpacing.gap4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: AppTypography.size12,
            color: AppColors.gray400Inline,
          ),
        ),
      ],
    );
  }
}

/// `list.error` — `HistoryPage.tsx:250-264`.
///
/// **The message is the app's own fixed sentence, not the backend's.** The
/// source prints `list.error.message`; `ServicePage.tsx:227-232` — the branch
/// B2a ported and every Flutter page has followed since — does not. Printing a
/// server string on a citizen-facing page is how backend detail leaks into the
/// UI, and the divergence is standing rather than B7's.
///
/// The retry label is the lifted `tryAgain` key (§ 6.11).
class HistoryErrorBlock extends StatelessWidget {
  const HistoryErrorBlock({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      // `bg-red-50` + `AlertOctagon` at `#DC2626` (`:252-253`).
      tile: const _GlyphTile(
        background: AppColors.dangerSoft,
        child: LucideGlyph(name: 'AlertOctagon', colour: AppColors.danger),
      ),
      children: <Widget>[
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: AppTypography.size14,
            fontWeight: AppTypography.medium,
            color: AppColors.gray700,
          ),
        ),
        const SizedBox(height: AppSpacing.gap16),
        // `mt-4 px-4 py-2.5 rounded-xl text-white bg-#344EAD` with a
        // `RefreshCw` to its left (`:256-262`).
        TextButton.icon(
          onPressed: onRetry,
          icon: const LucideGlyph(
            name: 'RefreshCw',
            colour: AppColors.white,
            size: AppSpacing.gap16,
          ),
          label: Text(retryLabel),
          style: TextButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gap16,
              vertical: AppSpacing.gap10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            textStyle: const TextStyle(
              fontSize: AppTypography.size14,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ),
      ],
    );
  }
}

/// `w-14 h-14 rounded-2xl` centred tile — both panels' glyph holder.
class _GlyphTile extends StatelessWidget {
  const _GlyphTile({required this.background, required this.child});

  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: AppSpacing.tile56,
        height: AppSpacing.tile56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        ),
        child: child,
      );
}

/// A lucide glyph at a fixed size — a two-line convenience so the panels do not
/// each restate the `LucideIcon` argument list.
class LucideGlyph extends StatelessWidget {
  const LucideGlyph({
    super.key,
    required this.name,
    required this.colour,
    this.size = AppSpacing.hit24,
  });

  final String name;
  final Color colour;
  final double size;

  @override
  Widget build(BuildContext context) =>
      LucideIcon(name: name, size: size, color: colour);
}

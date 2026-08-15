/// The detail's gradient header — `HistoryDetailPage.tsx:269-307`, and its two
/// reduced forms at `:173-185` (loading) and `:209-219` (error).
///
/// **One widget for all three states, because the back link must survive them.**
/// The source repeats the gradient block three times and the only thing common
/// to all three is the *Back to history* button — which is precisely the control
/// a citizen needs when the case failed to load. Three separate widgets would
/// each have to remember it; `B7-AC-53` and `B7-AC-54` both assert it is there.
///
/// The title/ref/pill trio is therefore nullable rather than required: absent on
/// the loading and error headers, present on the content one.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import 'history_palette.dart';
import 'history_panels.dart';

/// `text-white/80` — the back link (`:178`).
const double kDetailBackAlpha = 0.8;

/// `text-white/70` — the eyebrow and the reference line (`:298`, `:302`).
const double kDetailMutedAlpha = 0.7;

/// `text-white/60` — the `Hash` glyph (`:301`).
const double kDetailGlyphAlpha = 0.6;

/// `bg-white/15` / `border-white/20` — the 14×14 icon tile (`:294`).
const double kDetailTileFillAlpha = 0.15;
const double kDetailTileBorderAlpha = 0.2;

/// `bg-white/20` and `bg-white/10` — the two loading bars (`:182-183`).
const double kDetailSkeletonStrongAlpha = 0.2;
const double kDetailSkeletonWeakAlpha = 0.1;

/// `tracking-wider` on the eyebrow (`:298`) and `tracking-wide` on the status
/// pill (`:286`). Tailwind's scale is em-relative; at these two font sizes both
/// round to ~1 px, so one constant covers both rather than two that differ by
/// less than a device pixel.
const double kDetailTracking = 1;

class HistoryDetailHeader extends StatelessWidget {
  const HistoryDetailHeader({
    super.key,
    required this.backLabel,
    required this.onBack,
    this.eyebrow,
    this.title,
    this.referenceNo,
    this.statusLabel,
    this.statusBackground,
    this.statusForeground,
    this.showSkeletonBars = false,
  });

  /// `t("backToHistory")`.
  final String backLabel;
  final VoidCallback onBack;

  /// `t("applicationLabel")` — the uppercase eyebrow above the service name.
  final String? eyebrow;

  /// `text(detail.service_name, lang)` — `:299`.
  final String? title;

  /// `detail.reference_no` — `:302`.
  final String? referenceNo;

  /// `text(detail.status_label, lang)` — the pill at `:289`. Its colours are
  /// the bucket's, resolved by the caller so this widget holds no table.
  final String? statusLabel;
  final Color? statusBackground;
  final Color? statusForeground;

  /// The loading header's two pulsing bars (`:182-183`).
  final bool showSkeletonBars;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gap16,
        AppSpacing.gap20,
        AppSpacing.gap16,
        AppSpacing.gap32,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.primary,
            AppColors.headerGradientMid,
            AppColors.headerGradientEnd,
          ],
          stops: <double>[0, kHistoryHeaderMidStop, 1],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _BackLink(label: backLabel, onTap: onBack)),
              if (statusLabel != null)
                _StatusPill(
                  label: statusLabel!,
                  background: statusBackground ?? AppColors.white,
                  foreground: statusForeground ?? AppColors.primary,
                ),
            ],
          ),
          if (showSkeletonBars) ...<Widget>[
            const SizedBox(height: AppSpacing.gap24),
            _SkeletonBar(
              widthFactor: 2 / 3,
              height: AppSpacing.gap24,
              alpha: kDetailSkeletonStrongAlpha,
            ),
            const SizedBox(height: AppSpacing.gap8),
            _SkeletonBar(
              widthFactor: 1 / 3,
              height: AppSpacing.gap16,
              alpha: kDetailSkeletonWeakAlpha,
            ),
          ],
          if (title != null) ...<Widget>[
            const SizedBox(height: AppSpacing.gap16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // `w-14 h-14 rounded-2xl bg-white/15 border border-white/20`.
                Container(
                  width: AppSpacing.tile56,
                  height: AppSpacing.tile56,
                  decoration: BoxDecoration(
                    color: AppColors.white
                        .withValues(alpha: kDetailTileFillAlpha),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radius2xl),
                    border: Border.all(
                      color: AppColors.white
                          .withValues(alpha: kDetailTileBorderAlpha),
                    ),
                  ),
                  child: const Center(
                    child: LucideGlyph(
                      name: 'FileText',
                      colour: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.gap16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (eyebrow != null)
                        Text(
                          // `uppercase tracking-wider` (`:298`).
                          eyebrow!.toUpperCase(),
                          style: TextStyle(
                            fontSize: AppTypography.size12,
                            letterSpacing: kDetailTracking,
                            color: AppColors.white
                                .withValues(alpha: kDetailMutedAlpha),
                          ),
                        ),
                      Text(
                        title!,
                        style: const TextStyle(
                          fontSize: AppTypography.size20,
                          fontWeight: AppTypography.semiBold,
                          height: AppTypography.lineTight,
                          color: AppColors.white,
                        ),
                      ),
                      if (referenceNo != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.gap4),
                        Row(
                          children: <Widget>[
                            LucideGlyph(
                              name: 'Hash',
                              size: AppSpacing.gap12,
                              colour: AppColors.white
                                  .withValues(alpha: kDetailGlyphAlpha),
                            ),
                            const SizedBox(width: AppSpacing.gap8),
                            Expanded(
                              child: Text(
                                referenceNo!,
                                style: TextStyle(
                                  fontSize: AppTypography.size14,
                                  color: AppColors.white
                                      .withValues(alpha: kDetailMutedAlpha),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// `<button onClick={onBack}>` with a `ChevronLeft` — `:178-181`.
class _BackLink extends StatelessWidget {
  const _BackLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LucideGlyph(
              name: 'ChevronLeft',
              size: AppSpacing.gap16,
              colour: AppColors.white.withValues(alpha: kDetailBackAlpha),
            ),
            const SizedBox(width: AppSpacing.gap4),
            // **The back link is what shrinks, not the pill.** `:286` gives the
            // status pill `flex-shrink-0` and this button nothing, so when the
            // two do not both fit the label truncates and the pill stays whole.
            // Without this the row overflows at 390 dp with a `SUBMITTED` pill
            // — measured, 7.8 px.
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppTypography.size14,
                  color: AppColors.white.withValues(alpha: kDetailBackAlpha),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The status pill — `:285-290`. `uppercase tracking-wide`, the bucket's
/// `{bg, color}`.
class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gap12,
        vertical: AppSpacing.gap6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: AppTypography.size11,
          fontWeight: AppTypography.semiBold,
          letterSpacing: kDetailTracking,
          color: foreground,
        ),
      ),
    );
  }
}

/// One `animate-pulse` bar in the loading header.
class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({
    required this.widthFactor,
    required this.height,
    required this.alpha,
  });

  final double widthFactor;
  final double height;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: alpha),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg / 2),
        ),
      ),
    );
  }
}

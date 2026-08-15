/// The status hero card — `HistoryDetailPage.tsx:312-422`.
///
/// Five regions in one card: the bucket glyph and headline, the progress bar,
/// the payment/SLA/officer chip row, and the action row.
///
/// ## Two of the four action-row buttons are seams, not omissions (§ 6.1)
///
/// `:379-397` (*View document* / *Download document*) is **B5's** and `:398-409`
/// (*Pay …*) is **B6's**. They arrive as [documentActions] and [paymentAction] —
/// nullable `Widget?`s that render nothing when null, which is what B7b passes.
/// Whether the slot is *offered* is still B7b's: `isIssued` and `canPay` are
/// pure functions of the payload (`application_detail.dart`) and the caller
/// gates on them, so a later batch cannot re-derive `fee_lak > 0` slightly
/// differently and get a button the spec did not intend.
///
/// This widget deliberately does **not** know what goes in either slot. It has
/// no import of `features/{documents,wallet}/**` and `B7-AC-49`/`B7-AC-50` grep
/// for exactly that.
///
/// ## *Contact officer* is enabled-looking and does nothing (§ 6.13)
///
/// `:417-420` has no `onClick`. The port gives it a non-null `onTap` that is an
/// empty callback rather than `onPressed: null`, because the latter renders
/// Material's disabled grey and the web's button is not greyed. `B7-AC-60`
/// asserts the tap produces no navigation, no request and no state change —
/// which is only a meaningful assertion because the button is live.
///
/// Wiring it to B9b's chat, which exists and is right there, would be better
/// than the web and invisible to every fidelity tier. That is the divergence
/// class this comment exists to prevent.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../application/domain/entities/case_status.dart';
import 'history_detail_palette.dart';
import 'history_panels.dart';
// `kChipTextSize` only — the `text-[10px]` both pages' chips use. B7a's chip
// *widget* is private to `history_row_card.dart` and stays that way: the two
// chips differ (this one takes resolved colours, that one a `PaymentChipStyle`
// plus an optional leading glyph), and widening a tested widget's API to share
// twenty lines would put B7a's row rendering at risk for no gain.
import 'history_row_card.dart' show kChipTextSize;

/// `h-1.5` — the progress track (`:332`).
const double kDetailProgressHeight = AppSpacing.gap6;

/// `w-12 h-12` — the hero glyph tile (`:315`).
const double kDetailHeroTile = AppSpacing.tile48;

class HistoryDetailHero extends StatelessWidget {
  const HistoryDetailHero({
    super.key,
    required this.bucket,
    required this.headline,
    required this.sub,
    required this.progressLabel,
    required this.progressPct,
    required this.paymentChipLabel,
    required this.paymentChipBackground,
    required this.paymentChipForeground,
    required this.slaChipLabel,
    required this.isOverdue,
    required this.assignedOfficer,
    required this.refreshLabel,
    required this.onRefresh,
    required this.refreshing,
    required this.contactOfficerLabel,
    this.documentActions,
    this.paymentAction,
  });

  final StatusBucket bucket;
  final String headline;
  final String sub;

  /// `t("overallProgress")`.
  final String progressLabel;

  /// `progressOf(detail.status)` — already resolved against the live pipeline.
  final int progressPct;

  /// `{paymentLabel} · {formatLak(fee_lak)}` — `:346`, resolved by the caller.
  final String paymentChipLabel;
  final Color paymentChipBackground;
  final Color paymentChipForeground;

  /// Either the overdue wording or the SLA wording — the caller picks, because
  /// the two read from different fields and the detail's SLA phrasing is not
  /// the list's (`B7-AC-57`).
  final String slaChipLabel;
  final bool isOverdue;

  /// `detail.assigned_officer && …` — `:367`. Null renders nothing.
  final String? assignedOfficer;

  final String refreshLabel;
  final VoidCallback onRefresh;

  /// `detailQuery.refreshing` — spins the glyph and nothing else (`:414`).
  final bool refreshing;

  final String contactOfficerLabel;

  /// **B5's slot** — `:379-397`. Null in B7b.
  final Widget? documentActions;

  /// **B6's slot** — `:398-409`. Null in B7b.
  final Widget? paymentAction;

  @override
  Widget build(BuildContext context) {
    final HistoryDetailTheme theme = historyDetailThemeFor(bucket);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.gap20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _HeroGlyph(bucket: bucket, theme: theme),
              const SizedBox(width: AppSpacing.gap16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      headline,
                      style: TextStyle(
                        fontSize: AppTypography.size14,
                        fontWeight: AppTypography.semiBold,
                        color: theme.color,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.gap2),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontSize: AppTypography.size12,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.gap12),
                    _ProgressBar(
                      label: progressLabel,
                      pct: progressPct,
                      colour: theme.color,
                    ),
                    const SizedBox(height: AppSpacing.gap12),
                    _ChipRow(
                      paymentLabel: paymentChipLabel,
                      paymentBackground: paymentChipBackground,
                      paymentForeground: paymentChipForeground,
                      slaLabel: slaChipLabel,
                      isOverdue: isOverdue,
                      assignedOfficer: assignedOfficer,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // `mt-5 pt-5 border-t border-gray-100` (`:378`).
          const SizedBox(height: AppSpacing.gap20),
          const Divider(height: 1, thickness: 1, color: AppColors.gray100),
          const SizedBox(height: AppSpacing.gap20),
          Wrap(
            spacing: AppSpacing.gap8,
            runSpacing: AppSpacing.gap8,
            children: <Widget>[
              // B5's slot, then B6's — the source's order (`:379`, `:398`).
              if (documentActions != null) documentActions!,
              if (paymentAction != null) paymentAction!,
              _SecondaryButton(
                label: refreshLabel,
                onTap: onRefresh,
                glyph: 'RefreshCw',
                spinning: refreshing,
              ),
              // § 6.13 — live, and a no-op. Not disabled.
              _SecondaryButton(
                label: contactOfficerLabel,
                onTap: () {},
                glyph: kDetailContactOfficerIcon,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `StatusIcon` on `theme.bg` — `:314-319`.
class _HeroGlyph extends StatelessWidget {
  const _HeroGlyph({required this.bucket, required this.theme});

  final StatusBucket bucket;
  final HistoryDetailTheme theme;

  @override
  Widget build(BuildContext context) {
    final String? lucideName = kDetailHeroLucideIcon[bucket];

    return Container(
      width: kDetailHeroTile,
      height: kDetailHeroTile,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
      ),
      child: lucideName != null
          ? LucideGlyph(name: lucideName, colour: theme.color)
          // `XCircle` has no asset — see `history_detail_palette.dart`.
          : Icon(
              kDetailRejectedFallbackIcon,
              size: AppSpacing.hit24,
              color: theme.color,
            ),
    );
  }
}

/// The label/percentage line plus the track — `:327-338`.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.label,
    required this.pct,
    required this.colour,
  });

  final String label;
  final int pct;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                fontSize: AppTypography.size11,
                color: AppColors.muted,
              ),
            ),
            Text(
              // `{progressPct}%` — the bare integer plus a percent sign, which
              // is what the source interpolates (`:330`).
              '$pct%',
              style: const TextStyle(
                fontSize: AppTypography.size11,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gap6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: Container(
            height: kDetailProgressHeight,
            color: AppColors.gray100,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct / 100,
              child: Container(color: colour),
            ),
          ),
        ),
      ],
    );
  }
}

/// The payment chip, the SLA-or-overdue chip, and the optional officer —
/// `:341-373`.
class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.paymentLabel,
    required this.paymentBackground,
    required this.paymentForeground,
    required this.slaLabel,
    required this.isOverdue,
    required this.assignedOfficer,
  });

  final String paymentLabel;
  final Color paymentBackground;
  final Color paymentForeground;
  final String slaLabel;
  final bool isOverdue;
  final String? assignedOfficer;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.gap8,
      runSpacing: AppSpacing.gap8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        HistoryDetailChip(
          label: paymentLabel,
          background: paymentBackground,
          foreground: paymentForeground,
        ),
        // `is_overdue ? {#FEE2E2,#DC2626} : {#EEF2FF,#344EAD}` — `:348-366`.
        HistoryDetailChip(
          label: slaLabel,
          background: isOverdue
              ? AppColors.categoryTintHealth
              : AppColors.primarySoft,
          foreground: isOverdue ? AppColors.danger : AppColors.primary,
        ),
        if (assignedOfficer != null && assignedOfficer!.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const LucideGlyph(
                name: 'User',
                size: AppSpacing.gap12,
                colour: AppColors.muted,
              ),
              const SizedBox(width: AppSpacing.gap4),
              Text(
                assignedOfficer!,
                style: const TextStyle(
                  fontSize: kChipTextSize,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// A `rounded-full text-[10px] font-semibold px-2.5 py-1` pill — the payment,
/// SLA and overdue chips (`:342-366`).
///
/// Takes **resolved colours**, not a state enum: the SLA and overdue chips are
/// not payment states and have no `PaymentState` to look up, so a widget keyed
/// on one would need a second constructor for them. Also public, so the
/// timeline's ETA chip (`:501-506`) reuses it rather than restating the pill.
class HistoryDetailChip extends StatelessWidget {
  const HistoryDetailChip({
    super.key,
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
        horizontal: AppSpacing.gap10,
        vertical: AppSpacing.gap4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: kChipTextSize,
          fontWeight: AppTypography.semiBold,
          color: foreground,
        ),
      ),
    );
  }
}

/// `border border-gray-200 text-gray-700` — the two B7-owned action buttons
/// (`:410-420`).
class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.onTap,
    required this.glyph,
    this.spinning = false,
  });

  final String label;
  final VoidCallback onTap;
  final String glyph;

  /// `animate-spin` on the `RefreshCw` glyph only (`:414`).
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    final Widget icon = LucideGlyph(
      name: glyph,
      size: AppSpacing.gap16,
      colour: AppColors.gray700,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gap16,
          vertical: AppSpacing.gap10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            spinning
                ? _Spinner(child: icon)
                : icon,
            const SizedBox(width: AppSpacing.gap8),
            // Flexible for the same reason the back link is: a long Lao label
            // in a narrow `Wrap` run would otherwise overflow rather than
            // truncate. The `Wrap` bounds the width, so this is safe next to
            // `MainAxisSize.min`.
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppTypography.size14,
                  fontWeight: AppTypography.medium,
                  color: AppColors.gray700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `animate-spin` — a continuous 1 s rotation, Tailwind's default.
///
/// A `RotationTransition` rather than an implicit animation so it is
/// deterministic under `pumpWidget`: a test can assert the widget is present
/// without the frame scheduler ever settling, which `pumpAndSettle` on an
/// infinite animation cannot do.
class _Spinner extends StatefulWidget {
  const _Spinner({required this.child});

  final Widget child;

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RotationTransition(turns: _controller, child: widget.child);
}

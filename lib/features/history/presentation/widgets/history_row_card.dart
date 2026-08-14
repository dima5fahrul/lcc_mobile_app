/// One application row — `HistoryPage.tsx:283-402`.
///
/// Seven things, in order: the icon with its status ring, the service name and
/// `Ref · reference_no`, the status chip, the progress bar with its step
/// counter, the payment chip, the SLA chip, and the submitted date beside a
/// *View details* affordance (`B7-AC-41`).
///
/// ## `text(...)` comes from the frozen `lib/i18n/i18n.dart`
///
/// `service_name` and `status_label` are `Bilingual`, and `text(value, lang)`
/// at `i18n.dart:90` is the port of `types.ts:17-22`'s fallback chain
/// (`wanted || en || lo || ""`). It is imported, not re-implemented: four B2
/// features each wrote their own copy on the belief that G-L3 forbade the
/// import, and it does not — `lib/i18n/` is neither another feature's
/// `presentation/` nor its `data/`.
///
/// ## The step counter and the bar disagree, on purpose (§ 6.15, `B7-AC-30`)
///
/// A `draft` row is absent from the pipeline, so `indexOf` is `-1`:
/// `Math.max(1, stage + 1)` clamps the counter to **"Step 1 of 5"** while
/// `progressOf`'s second branch gives the bar **8 %**. Both numbers are the
/// source's and both are ported; correcting either would be the port quietly
/// improving on the thing it is a port of, and would be invisible to every
/// fidelity tier.
///
/// ## A recorded icon divergence
///
/// The rejected bucket's ring glyph is lucide `XCircle`, which is not in
/// `assets/icons/lucide/`, and `assets/icons/**` is out of B7's scope (§ 4.1).
/// Material's `cancel_outlined` renders for that bucket only. The SLA chip's
/// leading glyph is lucide `Timer`, likewise absent; Material's
/// `timer_outlined` renders. Both are recorded in `history_palette.dart` and in
/// the batch report.
library;

import 'package:flutter/material.dart';

import '../../../../i18n/i18n.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../application/domain/entities/application_row.dart';
import '../../../application/domain/entities/case_status.dart';
import '../../../application/domain/entities/status_pipeline.dart';
import 'history_palette.dart';

/// `text-[10px]` — the chips' font size. Below `AppTypography.size11`, which is
/// the smallest step on the scale, and `lib/presentation/**` is frozen for B7,
/// so it is a local constant with its source cited.
const double kChipTextSize = 10;

/// `text-[11px]` — the progress line and the submitted date.
const double kMetaTextSize = AppTypography.size11;

class HistoryRowCard extends StatelessWidget {
  const HistoryRowCard({
    super.key,
    required this.row,
    required this.pipeline,
    required this.lang,
    required this.refLabel,
    required this.stepProgress,
    required this.submittedOn,
    required this.viewDetails,
    required this.paymentLabel,
    required this.slaLabel,
    required this.onTap,
  });

  final ApplicationRow row;
  final StatusPipeline pipeline;
  final Lang lang;

  /// `t("ref")` — the word before the reference number, not the number.
  final String refLabel;

  /// `t("stepProgress", {current, total, label})`, already interpolated.
  final String stepProgress;

  /// `t("submittedOn", {date})`, already interpolated.
  final String submittedOn;

  final String viewDetails;

  /// `paymentLabel(item.payment_state, lang)`, resolved through the lifted key.
  final String paymentLabel;

  /// The SLA chip's sentence — the overdue arm or the waiting arm, resolved by
  /// the page (`B7-AC-42`).
  final String slaLabel;

  /// `setSelectedId(item.id)` — `HistoryPage.tsx:287`. B7a has no detail to
  /// open; the page passes a callback that B7b will point at its own state.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final StatusBucket bucket = row.bucket;
    final StatusChipStyle chip = statusChipStyleFor(bucket);
    final int progress = pipeline.progressFor(row.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.gap20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
          border: Border.all(color: AppColors.gray100),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: AppColors.cardShadow, blurRadius: AppSpacing.gap4),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _StatusRingIcon(bucket: bucket, chip: chip),
            const SizedBox(width: AppSpacing.gap16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _TitleRow(row: row, lang: lang, chip: chip, refLabel: refLabel),
                  const SizedBox(height: AppSpacing.gap12),
                  _Progress(
                    label: stepProgress,
                    percent: progress,
                    bucket: bucket,
                  ),
                  const SizedBox(height: AppSpacing.gap12),
                  Wrap(
                    spacing: AppSpacing.gap8,
                    runSpacing: AppSpacing.gap8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      _Chip(
                        label: paymentLabel,
                        style: paymentChipStyleFor(row.paymentState),
                      ),
                      _Chip(
                        label: slaLabel,
                        style: slaChipStyle(isOverdue: row.isOverdue),
                        // lucide `Timer` is absent from the shipped icon set —
                        // see the library doc.
                        leading: Icons.timer_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.gap12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          submittedOn,
                          style: const TextStyle(
                            fontSize: kMetaTextSize,
                            color: AppColors.gray400Inline,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            viewDetails,
                            style: const TextStyle(
                              fontSize: AppTypography.size12,
                              fontWeight: AppTypography.medium,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.gap4),
                          const LucideIcon(
                            name: 'ChevronRight',
                            size: AppSpacing.gap14,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `w-12 h-12 rounded-2xl bg-#EEF2FF` with a `FileText`, and a 5×5 status badge
/// pinned to its top-right (`HistoryPage.tsx:293-311`).
class _StatusRingIcon extends StatelessWidget {
  const _StatusRingIcon({required this.bucket, required this.chip});

  final StatusBucket bucket;
  final StatusChipStyle chip;

  @override
  Widget build(BuildContext context) {
    final String? lucideName = kStatusLucideIcon[bucket];

    return SizedBox(
      width: AppSpacing.tile56,
      height: AppSpacing.tile56,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: AppSpacing.tile48,
            height: AppSpacing.tile48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
            ),
            child: const LucideIcon(
              name: 'FileText',
              size: AppSpacing.gap20,
              color: AppColors.primary,
            ),
          ),
          Positioned(
            top: -AppSpacing.gap4,
            left: AppSpacing.tile48 - AppSpacing.gap16,
            child: Container(
              width: AppSpacing.gap20,
              height: AppSpacing.gap20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: chip.background,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
              child: lucideName != null
                  ? LucideIcon(
                      name: lucideName,
                      size: AppSpacing.gap12,
                      color: chip.foreground,
                    )
                  // `XCircle` — absent from the shipped lucide set (§ 4.1).
                  : Icon(
                      Icons.cancel_outlined,
                      size: AppSpacing.gap12,
                      color: chip.foreground,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Service name + `Ref · reference_no`, with the status chip to the right
/// (`:314-334`).
class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.row,
    required this.lang,
    required this.chip,
    required this.refLabel,
  });

  final ApplicationRow row;
  final Lang lang;
  final StatusChipStyle chip;
  final String refLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                text(row.serviceName, lang),
                style: const TextStyle(
                  fontSize: AppTypography.size14,
                  fontWeight: AppTypography.semiBold,
                  height: AppTypography.lineSnug,
                  color: AppColors.gray800,
                ),
              ),
              const SizedBox(height: AppSpacing.gap2),
              // `{t("ref")} · {item.reference_no}` — the separator is the
              // middle dot, and a Tier 1 dump sees it.
              Text(
                '$refLabel · ${row.referenceNo}',
                style: const TextStyle(
                  fontSize: AppTypography.size12,
                  color: AppColors.gray400Inline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.gap12),
        // `uppercase tracking-wide` — the status chip is the one uppercased
        // string on the row. It applies to the *rendered* label, so the Lao
        // arm is uppercased too and simply has no cased characters to change.
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gap10,
            vertical: AppSpacing.gap4,
          ),
          decoration: BoxDecoration(
            color: chip.background,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            text(row.statusLabel, lang).toUpperCase(),
            style: TextStyle(
              fontSize: kChipTextSize,
              fontWeight: AppTypography.semiBold,
              letterSpacing: 0.4,
              color: chip.foreground,
            ),
          ),
        ),
      ],
    );
  }
}

/// The step line and the bar — `HistoryPage.tsx:337-360`.
class _Progress extends StatelessWidget {
  const _Progress({
    required this.label,
    required this.percent,
    required this.bucket,
  });

  final String label;
  final int percent;
  final StatusBucket bucket;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: kMetaTextSize,
                  color: AppColors.gray500,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                fontSize: kMetaTextSize,
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gap6),
        // `h-1.5 bg-gray-100 rounded-full overflow-hidden` with a filled child
        // at `width: {pct}%`.
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: Container(
            height: AppSpacing.gap6,
            color: kProgressTrack,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percent / 100,
              child: Container(color: progressBarColour(bucket)),
            ),
          ),
        ),
      ],
    );
  }
}

/// A rounded pill — the payment and SLA chips share one shape (`:355-382`).
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.style, this.leading});

  final String label;
  final PaymentChipStyle style;
  final IconData? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gap8,
        vertical: AppSpacing.gap2,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (leading != null) ...<Widget>[
            Icon(leading, size: AppSpacing.gap12, color: style.foreground),
            const SizedBox(width: AppSpacing.gap4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: kChipTextSize,
              fontWeight: AppTypography.semiBold,
              color: style.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

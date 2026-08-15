/// The application-progress timeline — `HistoryDetailPage.tsx:497-586`.
///
/// A card header with an optional ETA chip, then **one of four** bodies:
/// skeleton, error-with-retry, empty, or the trail. The order is the source's
/// ladder at `:510-540` and is load-bearing — see `HistoryDetailState`, which
/// computes all four predicates so this widget branches on booleans rather than
/// re-deriving `events.length === 0` three times.
///
/// ## The connector is drawn by the event *above* it, and breaks on error
///
/// `:551-553`: the vertical rule is rendered by every event except the last,
/// running from that event's dot down to the next. Its colour is
/// `isError ? "#E5E7EB" : "#16A34A"` — **grey, not red**. A rejected event
/// therefore *breaks* the green trail rather than continuing it in another
/// colour, which is the entire visual point and is easy to get wrong by writing
/// `danger` for symmetry with the dot (`B7-AC-64`).
///
/// ## `isCurrent` is `isLast && !isError`
///
/// `:545`. The indigo ring marks "this is where the case is now", and a case
/// that ended in rejection is not *waiting* anywhere — so the last event of a
/// rejected trail gets the red treatment and **no** ring (`B7-AC-65`).
library;

import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../application/domain/entities/case_event.dart';
import 'history_detail_hero.dart' show HistoryDetailChip;
import 'history_detail_palette.dart';
import 'history_panels.dart';

/// `w-6 h-6` — the dot (`:555`).
const double kTimelineDot = AppSpacing.hit24;

/// `pl-9` — 36 px, the text column's inset, clearing the 24 px dot plus its
/// gutter (`:550`). Written as a literal for `kChipTextSize`'s reason: the
/// spacing scale has no 36 px *gap* token (`tile36` is a tile size, a different
/// thing resized for different reasons) and adding one to
/// `lib/presentation/theme/**` is outside B7b's scope (§ 4.1).
const double kTimelineTextInset = 36;

/// `pb-5 last:pb-0` — the gap between events (`:550`).
const double kTimelineEventGap = AppSpacing.gap20;

/// `w-0.5` — the connector (`:552`).
const double kTimelineLineWidth = 2;

/// `left-3` — the connector's centre, i.e. half the dot (`:552`).
const double kTimelineLineLeft = kTimelineDot / 2 - kTimelineLineWidth / 2;

/// `[0,1,2].map` — three skeleton rows (`:512`).
const int kTimelineSkeletonRows = 3;

class HistoryDetailTimeline extends StatelessWidget {
  const HistoryDetailTimeline({
    super.key,
    required this.title,
    required this.etaLabel,
    required this.loading,
    required this.failed,
    required this.empty,
    required this.errorMessage,
    required this.retryLabel,
    required this.onRetry,
    required this.emptyLabel,
    required this.events,
    required this.eventLabels,
    required this.eventTimestamps,
  });

  /// `t("applicationProgress")`.
  final String title;

  /// `t("eta", {value})`, already resolved — **null when the chip must not
  /// render**. The `due_at && bucket === "pending"` test is the caller's
  /// (`ApplicationDetail.showsEta`), so this widget cannot render an ETA for a
  /// rejected case by accident (`B7-AC-68`).
  final String? etaLabel;

  final bool loading;
  final bool failed;
  final bool empty;

  /// `timelineQuery.error.message` — **the backend's own sentence** (`:524`),
  /// exactly as the list renders `list.error.message`. `B7-AC-35` pinned that
  /// shape one page over; this is the same one.
  final String errorMessage;
  final String retryLabel;
  final VoidCallback onRetry;

  final String emptyLabel;

  final List<CaseEvent> events;

  /// `text(event.status_label, lang) || event.to_status` — `:572`, resolved per
  /// event by the caller because `text()` needs the locale and this widget
  /// takes none. Parallel to [events] by index.
  final List<String> eventLabels;

  /// `formatDateTime(event.occurred_at, lang)` — `:574`, same reason.
  final List<String> eventTimestamps;

  @override
  Widget build(BuildContext context) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTypography.size14,
                    fontWeight: AppTypography.semiBold,
                    color: AppColors.gray800,
                  ),
                ),
              ),
              if (etaLabel != null)
                HistoryDetailChip(
                  label: etaLabel!,
                  background: AppColors.categoryTintTransport, // #FEF3C7
                  foreground: AppColors.warningLink, // #D97706
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.gap20),
          _body(context),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (loading) {
      return const Column(
        children: <Widget>[
          _SkeletonEvent(),
          SizedBox(height: AppSpacing.gap16),
          _SkeletonEvent(),
          SizedBox(height: AppSpacing.gap16),
          _SkeletonEvent(),
        ],
      );
    }

    if (failed) {
      return _TimelineError(
        message: errorMessage,
        retryLabel: retryLabel,
        onRetry: onRetry,
      );
    }

    if (empty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.gap8),
        child: Text(
          emptyLabel,
          style: const TextStyle(
            fontSize: AppTypography.size14,
            color: AppColors.gray400Inline,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < events.length; i++)
          _TimelineEvent(
            event: events[i],
            label: eventLabels[i],
            timestamp: eventTimestamps[i],
            isLast: i == events.length - 1,
          ),
      ],
    );
  }
}

/// One `<li>` — `:550-581`.
class _TimelineEvent extends StatelessWidget {
  const _TimelineEvent({
    required this.event,
    required this.label,
    required this.timestamp,
    required this.isLast,
  });

  final CaseEvent event;
  final String label;
  final String timestamp;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final bool isError = event.isError;
    final bool isCurrent = isLast && !isError;
    final String actorAndNote = event.actorAndNote;

    return IntrinsicHeight(
      child: Stack(
        children: <Widget>[
          // The connector, omitted on the last event (`:551`).
          if (!isLast)
            Positioned(
              left: kTimelineLineLeft,
              top: kTimelineDot,
              bottom: 0,
              width: kTimelineLineWidth,
              child: ColoredBox(
                color: isError ? kTimelineLineError : kTimelineLineOk,
              ),
            ),
          Padding(
            padding: EdgeInsets.only(
              left: kTimelineTextInset,
              bottom: isLast ? 0 : kTimelineEventGap,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTypography.size14,
                    fontWeight: AppTypography.medium,
                    color: isError ? kTimelineTextError : kTimelineTextOk,
                  ),
                ),
                const SizedBox(height: AppSpacing.gap2),
                Text(
                  timestamp,
                  style: const TextStyle(
                    fontSize: AppTypography.size12,
                    color: AppColors.gray400Inline,
                  ),
                ),
                // `(actor_name || note) && …` — `:575`. Both absent renders
                // nothing at all, not an empty line (`B7-AC-67`).
                if (actorAndNote.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.gap4),
                  Text(
                    actorAndNote,
                    style: const TextStyle(
                      fontSize: AppTypography.size12,
                      height: AppTypography.lineRelaxed,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: _TimelineDot(isError: isError, isCurrent: isCurrent),
          ),
        ],
      ),
    );
  }
}

/// The 24 px dot, with the indigo ring when current — `:554-566`.
class _TimelineDot extends StatelessWidget {
  const _TimelineDot({required this.isError, required this.isCurrent});

  final bool isError;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kTimelineDot,
      height: kTimelineDot,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isError ? kTimelineDotBgError : kTimelineDotBgOk,
        shape: BoxShape.circle,
        // `boxShadow: 0 0 0 4px rgba(52,78,173,0.15)` — a *spread* with no blur,
        // which is a ring rather than a shadow.
        boxShadow: isCurrent
            ? <BoxShadow>[
                BoxShadow(
                  color: kTimelineCurrentRing
                      .withValues(alpha: kTimelineCurrentRingOpacity),
                  spreadRadius: kTimelineCurrentRingWidth,
                ),
              ]
            : null,
      ),
      child: isError
          // `XCircle` has no asset — `history_detail_palette.dart`.
          ? const Icon(
              kDetailRejectedFallbackIcon,
              size: AppSpacing.gap16,
              color: kTimelineDotError,
            )
          : const LucideGlyph(
              name: 'CheckCircle', // source: CheckCircle2
              size: AppSpacing.gap16,
              colour: kTimelineDotOk,
            ),
    );
  }
}

/// `timelineQuery.error && events.length === 0` — `:522-533`.
class _TimelineError extends StatelessWidget {
  const _TimelineError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.gap16),
        child: Column(
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppTypography.size14,
                color: AppColors.gray700,
              ),
            ),
            const SizedBox(height: AppSpacing.gap12),
            InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gap16,
                  vertical: AppSpacing.gap8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const LucideGlyph(
                      name: 'RefreshCw',
                      size: AppSpacing.gap16,
                      colour: AppColors.white,
                    ),
                    const SizedBox(width: AppSpacing.gap8),
                    Text(
                      retryLabel,
                      style: const TextStyle(
                        fontSize: AppTypography.size14,
                        fontWeight: AppTypography.semiBold,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One pulsing row — `:513-519`.
class _SkeletonEvent extends StatelessWidget {
  const _SkeletonEvent();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: kTimelineDot,
          height: kTimelineDot,
          decoration: const BoxDecoration(
            color: AppColors.gray100,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.gap12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 1 / 3,
                child: Container(
                  height: AppSpacing.gap12,
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg / 2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.gap8),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 1 / 4,
                child: Container(
                  height: AppSpacing.gap10,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg / 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

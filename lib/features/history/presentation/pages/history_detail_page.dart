/// One case — `lcc-app/src/app/components/HistoryDetailPage.tsx` (686 lines).
///
/// ## Not a route (§ 6.6)
///
/// The web swaps `HistoryPage`'s body on `selectedId` and never changes the URL.
/// A `/history/:id` route would make the detail deep-linkable and back-stackable
/// when the web's is neither — a *functional* divergence invisible to every
/// fidelity tier. So this is a plain widget that `HistoryPage` renders in place
/// of its list, and `app_routes.dart` is untouched.
///
/// ## Four seams — two filled by B5, two still B6's
///
/// `documentActions` and `certificatePanel` are **B5's** and are now supplied;
/// `paymentAction` and `paymentPanel` are **B6's** and are still `Widget?`,
/// still null (`B5-AC-46`). What B7b owns is whether a slot is offered —
/// [ApplicationDetail.isIssued] and `.canPay` — so B5 fills a slot rather than
/// re-deriving the condition.
///
/// ## The two B5 seams are BUILDERS, and that is a correction to § 6.1
///
/// A pre-built `Widget?` cannot be a function of the payload, and both B5
/// regions are: the action row's spec is
/// `docSpecFromApplication(detail, certificate, lang)`
/// (`HistoryDetailPage.tsx:247`) and the certificate card's four rows read
/// `certificate?.certificate_no ?? detail.certificate_no` and three more
/// (`:468-484`). A widget that reached for `detail` itself would have to import
/// `features/history/presentation/bloc/**`, which is a **G-L7** violation from
/// `lib/presentation/**`. So the two are retyped to builders that receive what
/// they need (specs.md Finding J, § 6.7); B6's two are untouched, and § 8.4
/// FU-3 hands B6 the same finding for its own pair.
///
/// `history_detail_hero.dart` is **not** edited: this page calls the builder
/// and hands the hero a resolved `Widget?`, so the hero's own field, its `Wrap`
/// and the source's button order are byte-identical (`B5-AC-48`).
///
/// The proof that the seams are real and not decoration is negative and is
/// grepped: `lib/features/history/**` names no certificate, PDF, document-viewer
/// or payment type, and imports no `features/{documents,wallet}/**`
/// (`B7-AC-49`, `B7-AC-50`).
///
/// ## The certificate card is a seam, so `certificate_no` alone renders nothing
///
/// `:456` is `isIssued && (certificate || detail.certificate_no)`. The first
/// disjunct needs `/me/certificates`, which is B5's and which `B7-AC-51` greps
/// `lib/**` to prove absent. The second is on the detail payload and B7b *could*
/// render a one-field card from it — and does not, because half of a card whose
/// other three rows need B5's payload is worse than the slot B5 fills whole.
/// Recorded here because it is the one place a reader will reasonably ask why a
/// field the port parses is not drawn.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../i18n/i18n.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../application/domain/application_formatting.dart';
import '../../../application/domain/entities/application_detail.dart';
import '../../../application/domain/entities/case_event.dart';
import '../../../application/domain/entities/case_status.dart';
import '../../../application/domain/entities/status_pipeline.dart';
// The CFI edge, domain only — `ssd.md` § 4.3, § 4.4.1 RULING 13. The seam
// builders' second parameter is this entity; nothing here reaches into
// `features/documents/{data,presentation}/**` (`B5-AC-20`).
import '../../../documents/domain/entities/issued_certificate.dart';
// `formatLak` arrives via `application_formatting.dart:76`, which re-exports it
// from `features/home/domain/` rather than copying it — B7a's call, and
// `wallet_formatting.dart:29`'s precedent ("copying would be two formatLaks
// that drift"). Note this is the opposite disposition from the two date
// formatters, which § 6.7 *does* copy — because those genuinely differ from
// their `news_formatting` counterparts in the absent-value sentinel, and this
// does not differ from anything.
import '../bloc/history_detail_bloc.dart';
import '../widgets/history_detail_cards.dart';
import '../widgets/history_detail_header.dart';
import '../widgets/history_detail_hero.dart';
import '../widgets/history_detail_palette.dart';
import '../widgets/history_detail_timeline.dart';
import '../widgets/history_labels.dart';
import '../widgets/history_palette.dart';
import '../widgets/history_panels.dart';

/// `[0, 1, 2].map(...)` — three skeleton cards (`:187`, `B7-AC-53`).
const int kDetailSkeletonCards = 3;

/// `space-y-5` — the gap between the content column's cards (`:310`).
const double kDetailCardGap = AppSpacing.gap20;

class HistoryDetailPage extends StatelessWidget {
  const HistoryDetailPage({
    super.key,
    required this.pipeline,
    required this.onBack,
    this.documentActions,
    this.paymentAction,
    this.paymentPanel,
    this.certificatePanel,
  });

  /// The live `/status-catalogue` order, owned by `HistoryBloc` and passed down
  /// rather than re-fetched: `progressOf`'s denominator must be the same 5 the
  /// list counted against, or the same case reads a different percentage on the
  /// two screens.
  final StatusPipeline pipeline;

  /// Returns to the list. The caller also dispatches `HistoryReturnedFromDetail`
  /// so the list and counts refetch (`HistoryPage.tsx:120-124`, `B7-AC-76`).
  final VoidCallback onBack;

  /// **B5** — the *View document* / *Download document* pair (`:379-397`).
  ///
  /// A builder, not a `Widget?`: the pair's `DocSpec` is
  /// `docSpecFromApplication(detail, certificate, lang)` (`:247`). See the
  /// library doc.
  final Widget Function(
    ApplicationDetail detail,
    IssuedCertificate? certificate,
  )? documentActions;

  /// **B6** — the *Pay …* button (`:398-409`). Still a plain `Widget?`; B6's
  /// two seams have the identical defect and fixing them here would be B5
  /// absorbing B6 (§ 8.4 FU-3).
  final Widget? paymentAction;

  /// **B6** — `PaymentSection` (`:425-438`).
  final Widget? paymentPanel;

  /// **B5** — the issued-certificate card (`:456-494`).
  ///
  /// `certificateLoading` is a **separate** parameter and is not folded into a
  /// nullable certificate: `:486` is a three-state gate
  /// (`!certificate && !certListQuery.loading`), and collapsing it would render
  /// *"not available yet"* while the list is still in flight (`B5-AC-49`).
  final Widget Function(
    ApplicationDetail detail,
    IssuedCertificate? certificate,
    bool certificateLoading,
  )? certificatePanel;

  @override
  Widget build(BuildContext context) {
    final Lang lang = Lang.fromCode(context.locale.languageCode);
    final String languageCode = lang == Lang.lo ? kLaoCode : 'en';

    return BlocBuilder<HistoryDetailBloc, HistoryDetailState>(
      builder: (BuildContext context, HistoryDetailState state) {
        final String backLabel =
            '$kHistoryNs.backToHistory'.tr(context: context);

        // `detailQuery.loading && !detail` — `:170`.
        if (state.showSkeleton) {
          return _Shell(
            header: HistoryDetailHeader(
              backLabel: backLabel,
              onBack: onBack,
              showSkeletonBars: true,
            ),
            children: <Widget>[
              for (int i = 0; i < kDetailSkeletonCards; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: kDetailCardGap),
                const _SkeletonCard(),
              ],
              const SizedBox(height: kDetailCardGap),
              Center(
                child: Text(
                  'common.loading'.tr(context: context),
                  style: const TextStyle(
                    fontSize: AppTypography.size12,
                    color: AppColors.gray400Inline,
                  ),
                ),
              ),
            ],
          );
        }

        // `if (!detail)` — `:200`, after the loading branch.
        if (state.showDetailError) {
          return _Shell(
            header: HistoryDetailHeader(
              backLabel: backLabel,
              onBack: onBack,
            ),
            children: <Widget>[
              HistoryErrorBlock(
                // `:201-206` — a THREE-way choice, and the shape differs from
                // the list's. Not-found prints the app's own fixed sentence;
                // any other failure prints the backend's `error.message`, with
                // the app's generic sentence only when the `Failure` carries
                // none. `detailNotFound` is a separate field rather than a
                // substring test on the message, so a reworded backend
                // sentence cannot flip the branch (`B7-AC-54`).
                message: state.detailNotFound
                    ? '$kHistoryNs.detailNotFound'.tr(context: context)
                    : state.detailError.isNotEmpty
                        ? state.detailError
                        : '$kHistoryNs.detailLoadError'.tr(context: context),
                retryLabel: '$kHistoryNs.tryAgain'.tr(context: context),
                onRetry: () => context
                    .read<HistoryDetailBloc>()
                    .add(const HistoryDetailRetried()),
              ),
            ],
          );
        }

        final ApplicationDetail detail = state.detail!;
        return _content(context, state, detail, lang, languageCode, backLabel);
      },
    );
  }

  Widget _content(
    BuildContext context,
    HistoryDetailState state,
    ApplicationDetail detail,
    Lang lang,
    String languageCode,
    String backLabel,
  ) {
    final StatusBucket bucket = detail.bucket;
    final HistoryDetailTheme theme = historyDetailThemeFor(bucket);
    final PaymentChipStyle payment = paymentChipStyleFor(detail.row.paymentState);
    final List<CaseEvent> events = state.events;

    return _Shell(
      header: HistoryDetailHeader(
        backLabel: backLabel,
        onBack: onBack,
        eyebrow: '$kHistoryNs.applicationLabel'.tr(context: context),
        title: text(detail.row.serviceName, lang),
        referenceNo: detail.row.referenceNo,
        statusLabel: text(detail.row.statusLabel, lang),
        statusBackground: theme.background,
        statusForeground: theme.color,
      ),
      children: <Widget>[
        HistoryDetailHero(
          bucket: bucket,
          headline: theme.headlineKey.tr(context: context),
          sub: theme.subKey.tr(context: context),
          progressLabel: '$kHistoryNs.overallProgress'.tr(context: context),
          progressPct: pipeline.progressFor(detail.row.status),
          // `{paymentLabel(state, lang)} · {formatLak(fee_lak, lang)}` —
          // `:346`. `formatLak(0)` is `Free`/`ຟຣີ`, not `0 LAK`
          // (`serviceConfig.ts:40`, `B7-AC-56`).
          paymentChipLabel:
              '${kPaymentLabelKeys[detail.row.paymentState]!.tr(context: context)}'
              ' · ${formatLak(detail.row.feeLak, languageCode)}',
          paymentChipBackground: payment.background,
          paymentChipForeground: payment.foreground,
          // `:348-366`. The overdue arm is byte-identical to the list's; the
          // waiting arm is NOT — the detail says "{n} of {m} SLA days" where
          // the list says "{n}/{m} days" (`B7-AC-57`).
          slaChipLabel: detail.row.isOverdue
              ? '$kHistoryNs.slaOverdue'.tr(
                  context: context,
                  namedArgs: <String, String>{
                    'days': '${detail.row.daysOverdue}',
                  },
                )
              : '$kHistoryNs.slaWaitingDetail'.tr(
                  context: context,
                  namedArgs: <String, String>{
                    'waiting': '${detail.row.daysWaiting}',
                    'sla': '${detail.row.slaDays}',
                  },
                ),
          isOverdue: detail.row.isOverdue,
          assignedOfficer: detail.row.assignedOfficer,
          refreshLabel: '$kHistoryNs.refreshStatus'.tr(context: context),
          onRefresh: () => context
              .read<HistoryDetailBloc>()
              .add(const HistoryDetailRefreshed()),
          refreshing: state.refreshing,
          contactOfficerLabel:
              '$kHistoryNs.contactOfficer'.tr(context: context),
          // The two action-row seams, offered only when the payload says so.
          // The gate is unchanged — `isIssued ? … : null` (`:379`) — and only
          // what sits inside it became a call (`B5-AC-47`).
          documentActions: detail.isIssued
              ? documentActions?.call(detail, state.certificate)
              : null,
          paymentAction: detail.canPay ? paymentAction : null,
        ),

        // B6's `PaymentSection` — `canPay && paying` (`:425`). The `paying`
        // half is B6's own local toggle, so B7b gates on `canPay` only and
        // hands B6 the slot.
        if (detail.canPay && paymentPanel != null) ...<Widget>[
          const SizedBox(height: kDetailCardGap),
          HistoryDetailCard(child: paymentPanel!),
        ],

        if (detail.showsRejectionNote) ...<Widget>[
          const SizedBox(height: kDetailCardGap),
          HistoryDetailRejection(
            title: '$kHistoryNs.whyRejected'.tr(context: context),
            reason: detail.row.reasonNote!,
          ),
        ],

        // B5's certificate card. The gate is `isIssued && (certificate ||
        // detail.certificate_no)` (`:456`) — **both disjuncts**, which
        // `HistoryDetailState.showsCertificatePanel` carries so that
        // `certificateNo` is not named in this file (the narrowed
        // `forbiddenIdentifiers` guard scans `pages/`, § 6.8). Gating on
        // `isIssued` alone would draw an empty white card for an issued case
        // with neither a certificate nor a number — see that getter's doc for
        // why this deviates from § 6.7's literal wording.
        if (state.showsCertificatePanel && certificatePanel != null) ...<Widget>[
          const SizedBox(height: kDetailCardGap),
          HistoryDetailCard(
            child: certificatePanel!(
              detail,
              state.certificate,
              state.certificateLoading,
            ),
          ),
        ],

        const SizedBox(height: kDetailCardGap),
        HistoryDetailTimeline(
          title: '$kHistoryNs.applicationProgress'.tr(context: context),
          // `detail.due_at && bucket === "pending"` — `:500`.
          etaLabel: detail.showsEta
              ? '$kHistoryNs.eta'.tr(
                  context: context,
                  namedArgs: <String, String>{
                    'value':
                        formatApplicationDate(detail.row.dueAt, languageCode),
                  },
                )
              : null,
          loading: state.timelineLoading,
          failed: state.timelineFailed,
          empty: state.timelineEmpty,
          errorMessage: state.timelineError,
          retryLabel: '$kHistoryNs.tryAgain'.tr(context: context),
          onRetry: () => context
              .read<HistoryDetailBloc>()
              .add(const HistoryDetailTimelineRetried()),
          emptyLabel: '$kHistoryNs.timelineEmpty'.tr(context: context),
          events: events,
          // `text(event.status_label, lang) || event.to_status` — `:572`.
          eventLabels: events
              .map((CaseEvent e) => e.labelOr(text(e.statusLabel, lang)))
              .toList(growable: false),
          eventTimestamps: events
              .map((CaseEvent e) =>
                  formatApplicationDateTime(e.occurredAt, languageCode))
              .toList(growable: false),
        ),

        const SizedBox(height: kDetailCardGap),
        HistoryDetailAttachments(
          title: '$kHistoryNs.attachments'.tr(context: context),
          emptyLabel: '$kHistoryNs.attachmentsEmpty'.tr(context: context),
        ),

        const SizedBox(height: kDetailCardGap),
        HistoryDetailInfo(
          title: '$kHistoryNs.applicationInfo'.tr(context: context),
          referenceLabel: '$kHistoryNs.referenceNumber'.tr(context: context),
          referenceValue: detail.row.referenceNo,
          submittedLabel: '$kHistoryNs.submitted'.tr(context: context),
          submittedValue: formatApplicationDateTime(
            detail.row.submittedOrCreatedAt,
            languageCode,
          ),
          officeLabel: '$kHistoryNs.processingOffice'.tr(context: context),
          officeValue: detail.row.jurisdiction.officeLine,
          feeLabel: '$kHistoryNs.serviceFee'.tr(context: context),
          feeValue: formatLak(detail.row.feeLak, languageCode),
        ),
      ],
    );
  }
}

/// The gradient header plus the `-mt-4` content column every state shares
/// (`:172`, `:186`, `:310`).
class _Shell extends StatelessWidget {
  const _Shell({required this.header, required this.children});

  final Widget header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            header,
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gap16,
                0,
                AppSpacing.gap16,
                AppSpacing.gap24,
              ),
              child: Transform.translate(
                offset: const Offset(0, -AppSpacing.gap16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One of the three loading cards — `:188-192`.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return HistoryDetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _bar(1 / 3, AppSpacing.gap16, AppColors.gray200),
          const SizedBox(height: AppSpacing.gap12),
          _bar(2 / 3, AppSpacing.gap12, AppColors.gray100),
          const SizedBox(height: AppSpacing.gap12),
          _bar(1 / 2, AppSpacing.gap12, AppColors.gray100),
        ],
      ),
    );
  }

  Widget _bar(double factor, double height, Color colour) =>
      FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: factor,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: colour,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg / 2),
          ),
        ),
      );
}

/// `/history` — every case the citizen has opened.
///
/// Ports `lcc-app/src/app/components/HistoryPage.tsx` (435 lines): header and
/// search, four count tiles, four filter chips, the four-state list, and the
/// pager.
///
/// ## The signed-out branch is NOT ported (§ 6.5, and this is deliberate)
///
/// `/history` is in `AppRoutes._protectedPaths` (`app_routes.dart:145-146`), so
/// an unauthenticated citizen is redirected to `/signin?from=%2Fhistory` before
/// this widget is built. `HistoryPage.tsx:223-234`'s signed-out card is
/// reachable in the web only through a mid-session `tokens.clear()`; in Flutter
/// the same event is intercepted by `refreshListenable` + `redirect`
/// (`app_routes.dart:202`). A widget for it would be **unreachable by
/// construction** — the `YourIdPage` / `/news/:slug` disposition, where B2
/// shipped 493 lines for a route that could never match.
///
/// The placeholder this file replaces already stated the reasoning ("a second
/// in-page check would be dead code that could drift from the real gate"), and
/// B7 keeps it. The consequence for the queries is that the BLoC carries no
/// `enabled` flag: it fetches on `HistoryStarted`.
///
/// ## The detail is B7b's
///
/// § 6.6 rules the detail **in-page state, not a route** — the web swaps the
/// body on `selectedId` and never changes the URL. B7a therefore adds no route
/// and no `PopScope`; [_onRowTapped] is the seam B7b fills, and
/// `HistoryReturnedFromDetail` (which refetches the list **and** the counts,
/// `HistoryPage.tsx:120-124`) is already implemented and already tested by
/// counting requests, so B7b inherits a working `onBack` rather than a stub.
///
/// ## Where the numbers come from
///
/// Nothing on this page counts rows. The four tiles read four separate
/// `meta.total`s (§ 6.8); the pager prints `meta.total`; the progress bar reads
/// the live pipeline. A row count would be a different number on every one of
/// them.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../i18n/i18n.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../application/domain/application_formatting.dart';
import '../../../application/domain/entities/application_row.dart';
import '../bloc/history_bloc.dart';
import '../widgets/history_filter_chips.dart';
import '../widgets/history_header.dart';
import '../widgets/history_labels.dart';
import '../widgets/history_pager.dart';
import '../widgets/history_panels.dart';
import '../widgets/history_row_card.dart';
import '../widgets/history_stat_tiles.dart';

/// `[0, 1, 2].map(...)` — exactly three skeleton rows (`:236`, `B7-AC-34`).
const int kHistorySkeletonRows = 3;

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Lang lang = Lang.fromCode(context.locale.languageCode);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (BuildContext context, HistoryState state) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                HistoryHeader(
                  title: '$kHistoryNs.title'.tr(context: context),
                  subtitle: '$kHistoryNs.subtitle'.tr(context: context),
                  searchPlaceholder: '$kHistoryNs.searchPlaceholder'.tr(context: context),
                  onSearchChanged: (String value) => context
                      .read<HistoryBloc>()
                      .add(HistorySearchChanged(value)),
                ),
                Padding(
                  // `-mt-4` — the content column overlaps the header
                  // (`HistoryPage.tsx:161`).
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
                      children: <Widget>[
                        HistoryStatTiles(
                          counts: state.counts,
                          loading: state.countsLoading,
                          totalLabel: '$kHistoryNs.statTotal'.tr(context: context),
                          approvedLabel: '$kHistoryNs.statApproved'.tr(context: context),
                          inReviewLabel: '$kHistoryNs.statInReview'.tr(context: context),
                          rejectedLabel: '$kHistoryNs.statRejected'.tr(context: context),
                        ),
                        const SizedBox(height: AppSpacing.gap20),
                        HistoryFilterChips(
                          chips: kHistoryFilterChips
                              .map(((String, String) c) => (c.$1, c.$2.tr(context: context)))
                              .toList(growable: false),
                          active: state.filter,
                          onPick: (String id) => context
                              .read<HistoryBloc>()
                              .add(HistoryFilterPicked(id)),
                        ),
                        const SizedBox(height: AppSpacing.gap20),
                        _ListRegion(state: state, lang: lang),
                        if (state.showPager) ...<Widget>[
                          const SizedBox(height: AppSpacing.gap20),
                          HistoryPager(
                            page: state.result.page,
                            totalPages: state.result.totalPages,
                            total: state.result.total,
                            canGoPrev: state.canGoPrev,
                            canGoNext: state.canGoNext,
                            previousLabel: 'common.back'.tr(context: context),
                            nextLabel: 'common.next'.tr(context: context),
                            onPrevious: () => context
                                .read<HistoryBloc>()
                                .add(const HistoryPreviousPage()),
                            onNext: () => context
                                .read<HistoryBloc>()
                                .add(const HistoryNextPage()),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The four-state list — the source's `? :` ladder at `:222-403`, minus its
/// first arm (§ 6.5).
///
/// The order is load-bearing and is the source's: **skeleton → error → empty →
/// rows**. Checking `rows.isEmpty` before `error` would render "No applications
/// found" for a failed request, which is a different and much worse sentence.
class _ListRegion extends StatelessWidget {
  const _ListRegion({required this.state, required this.lang});

  final HistoryState state;
  final Lang lang;

  @override
  Widget build(BuildContext context) {
    if (state.showSkeleton) {
      return const Column(
        children: <Widget>[
          HistorySkeletonRow(),
          SizedBox(height: kHistoryRowGap),
          HistorySkeletonRow(),
          SizedBox(height: kHistoryRowGap),
          HistorySkeletonRow(),
        ],
      );
    }

    if (state.listFailed) {
      return HistoryErrorBlock(
        // **The backend's sentence, not the app's** — `:254` renders
        // `{list.error.message}` verbatim. An earlier cut printed a fixed
        // `history.listError` string instead, citing `news.listError` as
        // precedent; measured against the source that is a divergence, and
        // ADR-0001 makes the shipped web the authority (`B7-AC-35`).
        //
        // `history.listError` survives as the fallback for a `Failure` that
        // carries no message — a blank error card would be worse than a
        // generic one — and stays in the namespace, so the i18n edit remains
        // append-only for B6/B8/B10.
        message: state.listError.isNotEmpty
            ? state.listError
            : '$kHistoryNs.listError'.tr(context: context),
        retryLabel: '$kHistoryNs.tryAgain'.tr(context: context),
        onRetry: () =>
            context.read<HistoryBloc>().add(const HistoryListRetried()),
      );
    }

    if (state.listEmpty) {
      return HistoryEmptyBlock(
        title: '$kHistoryNs.emptyTitle'.tr(context: context),
        // `search || filter !== "all" ? t("emptySubtitle") : <the lifted
        // hint>` — `HistoryPage.tsx:274-277`. Both arms, `B7-AC-33`.
        subtitle: state.isFiltered
            ? '$kHistoryNs.emptySubtitle'.tr(context: context)
            : '$kHistoryNs.emptyHint'.tr(context: context),
      );
    }

    return Column(
      children: <Widget>[
        for (int i = 0; i < state.rows.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: kHistoryRowGap),
          _row(context, state.rows[i]),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, ApplicationRow row) {
    final String languageCode = lang == Lang.lo ? kLaoCode : 'en';

    return HistoryRowCard(
      row: row,
      pipeline: state.pipeline,
      lang: lang,
      refLabel: '$kHistoryNs.ref'.tr(context: context),
      // `t("stepProgress", {current: Math.max(1, stage + 1), total:
      // pipeline.length, label: text(item.status_label, lang)})` — `:333-337`.
      stepProgress: '$kHistoryNs.stepProgress'.tr(
        context: context,
        namedArgs: <String, String>{
          'current': '${state.pipeline.stepFor(row.status)}',
          'total': '${state.pipeline.length}',
          'label': text(row.statusLabel, lang),
        },
      ),
      // `t("submittedOn", {date: formatDate(item.submitted_at ??
      // item.created_at, lang)})` — `:390-392`.
      submittedOn: '$kHistoryNs.submittedOn'.tr(
        context: context,
        namedArgs: <String, String>{
          'date': formatApplicationDate(row.submittedOrCreatedAt, languageCode),
        },
      ),
      viewDetails: '$kHistoryNs.viewDetails'.tr(context: context),
      paymentLabel: kPaymentLabelKeys[row.paymentState]!.tr(context: context),
      // `:375-381`: the overdue arm and the waiting arm, both lifted keys.
      slaLabel: row.isOverdue
          ? '$kHistoryNs.slaOverdue'.tr(
              context: context,
              namedArgs: <String, String>{'days': '${row.daysOverdue}'},
            )
          : '$kHistoryNs.slaWaiting'.tr(
              context: context,
              namedArgs: <String, String>{
                'waiting': '${row.daysWaiting}',
                'sla': '${row.slaDays}',
              },
            ),
      // The detail is B7b's (§ 6.6). Tapping a row does nothing in B7a, and
      // that is the seam rather than a stub: B7b points this at its in-page
      // state and dispatches `HistoryReturnedFromDetail` on the way back.
      onTap: () {},
    );
  }
}

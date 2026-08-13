/// `/help` — the help centre.
///
/// Port of `lcc-app/src/app/components/HelpCenterPage.tsx` (534 lines).
///
/// ## Five regions, each with its own four states (§ 6.6, B2-AC-16)
///
/// | Region | loading | data | empty | error |
/// |---|---|---|---|---|
/// | topics | 4 pill skeletons | "All topics" + one per topic | "All topics" alone | + retry **(added)** |
/// | questions | 4 row skeletons | up to 10 cards | `noResults` + `noResultsDesc` | `ErrorBlock` |
/// | guides | 2 row skeletons | one card per guide | "No guides…" | `ErrorBlock` |
/// | guide body | 3 bars | the body | — (a guide always has one) | `ErrorBlock` inside the panel |
/// | channels | 4 tile skeletons | 2-up tile grid | "Contact support" link | `ErrorBlock` |
///
/// Four of the five error branches are the source's own `ErrorBlock` call
/// sites. The **topics' is an addition** — `:226` renders
/// `(categories.data ?? []).map(...)` with no error branch at all, so a failed
/// fetch silently shows "All topics" and nothing else. § 6.6 makes
/// error-with-retry mandatory per network-backed surface and B2-AC-16 says an
/// empty list is never an acceptable rendering of a failed fetch. The addition
/// is recorded in the Tier 1 oracle as `topics.error`, sourced to
/// `ADDED by B2c — § 6.6 / B2-AC-16`.
///
/// The **channels' empty state is not a message** — it is the "Contact support"
/// link to `/account` (`:479-486`). Ported as the source has it.
///
/// ## No locator read here (G-L5, SSD § 6.4)
///
/// The BLoC arrives through a `BlocProvider` the `/help` route builder created.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../presentation/icons/app_icons.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../../utils/routes/app_name_routes.dart';
import '../../domain/entities/help_entities.dart';
import '../../domain/usecases/help_usecases.dart';
import '../bloc/help_bloc.dart';
import '../widgets/faq_card.dart';
import '../widgets/guide_card.dart';
import '../widgets/help_header.dart';
import '../widgets/help_pager.dart';
import '../widgets/help_panels.dart';
import '../widgets/help_search_field.dart';
import '../widgets/help_topic_chips.dart';
import '../widgets/support_channel_tile.dart';

/// `a.helpful >= 5` — `HelpCenterPage.tsx:302`.
const int kHelpPopularThreshold = 5;

/// `h-16` — 64 CSS px, the channel-tile skeleton's height (`:473`). Derived
/// from `AppSpacing`'s scale rather than written bare, and not added to
/// `AppSpacing` itself: `lib/presentation/theme/**` is outside B2c's § 3.1
/// modify list (B2-AC-38).
const double _channelSkeletonHeight = AppSpacing.gap32 * 2;

/// `CATEGORY_TAB` — `HelpCenterPage.tsx:64-68`. A help category that names an
/// app tab gets a deep link on its answers. Three entries, exactly as written.
const Map<String, String> kHelpCategoryTab = <String, String>{
  'services': 'service',
  'payments': 'wallet',
  'account': 'account',
};

/// The tab → path table, restricted to routes that exist in Flutter today.
const Map<String, String> kHelpTabPaths = <String, String>{
  'service': AppNameRoutes.service,
  'wallet': AppNameRoutes.wallet,
  'account': AppNameRoutes.account,
};

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // `min-h-full` with no page background — the band supplies the colour at
      // the top and the body is the app surface below it.
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<HelpBloc, HelpState>(
          builder: (BuildContext context, HelpState state) =>
              _HelpBody(state: state),
        ),
      ),
    );
  }
}

class _HelpBody extends StatelessWidget {
  const _HelpBody({required this.state});

  final HelpState state;

  HelpBloc _bloc(BuildContext context) => context.read<HelpBloc>();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        HelpHeader(
          title: 'help.title'.tr(),
          subtitle: 'help.subtitle'.tr(),
          // `tc("back")` — the COMMON namespace, not help's. `:164`.
          backLabel: 'common.back'.tr(),
          onBack: () => context.go(AppNameRoutes.home),
          search: HelpSearchField(
            query: state.query,
            label: 'help.searchLabel'.tr(),
            placeholder: 'help.searchPlaceholder'.tr(),
            clearLabel: 'help.clearSearch'.tr(),
            onChanged: (String value) =>
                _bloc(context).add(HelpSearchChanged(value)),
            onCleared: () => _bloc(context).add(const HelpSearchCleared()),
          ),
        ),
        Padding(
          // `px-4 py-8`
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gap16,
            vertical: AppSpacing.gap32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _topics(context),
              if (state.showResultCount) ...<Widget>[
                const SizedBox(height: AppSpacing.gap20),
                _resultCount(),
              ],
              const SizedBox(height: AppSpacing.gap16),
              _questions(context),
              if (state.showPager) ...<Widget>[
                const SizedBox(height: AppSpacing.gap24),
                HelpPager(
                  page: state.faqs.page,
                  totalPages: state.faqs.totalPages,
                  hasPrev: state.faqs.hasPrev,
                  hasNext: state.faqs.hasNext,
                  previousLabel: 'help.previousPage'.tr(),
                  nextLabel: 'help.nextPage'.tr(),
                  onPrevious: () => _bloc(context).add(const HelpPreviousPage()),
                  onNext: () => _bloc(context).add(const HelpNextPage()),
                ),
              ],
              const SizedBox(height: AppSpacing.gap40),
              _guides(context),
              const SizedBox(height: AppSpacing.gap40),
              _stillStuck(context),
            ],
          ),
        ),
      ],
    );
  }

  // ── Topics ─────────────────────────────────────────────────────────────────

  Widget _topics(BuildContext context) {
    if (state.categoriesLoading) {
      return const Wrap(
        spacing: AppSpacing.gap8,
        runSpacing: AppSpacing.gap8,
        alignment: WrapAlignment.center,
        children: <Widget>[
          HelpSkeleton(
            height: AppSpacing.tile36,
            width: AppSpacing.gap40 * 2,
            radius: AppSpacing.radiusFull,
          ),
          HelpSkeleton(
            height: AppSpacing.tile36,
            width: AppSpacing.gap40 * 3,
            radius: AppSpacing.radiusFull,
          ),
          HelpSkeleton(
            height: AppSpacing.tile36,
            width: AppSpacing.gap40 * 3,
            radius: AppSpacing.radiusFull,
          ),
          HelpSkeleton(
            height: AppSpacing.tile36,
            width: AppSpacing.gap40 * 2,
            radius: AppSpacing.radiusFull,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        HelpTopicChips(
          categories: state.categories,
          selected: state.topic,
          allLabel: 'help.allTopics'.tr(),
          onPick: (String code) => _bloc(context).add(HelpTopicPicked(code)),
        ),
        // The § 6.6 addition — see the library doc.
        if (state.categoriesFailed)
          HelpErrorBlock(
            message: 'help.topicsError'.tr(),
            retryLabel: 'help.retry'.tr(),
            onRetry: () => _bloc(context).add(const HelpCategoriesRetried()),
            verticalPadding: AppSpacing.gap16,
          ),
      ],
    );
  }

  /// `total === 1 ? t("resultsOne") : t("resultsMany", { count: total })` —
  /// `:254`, inside an `aria-live="polite"` region.
  Widget _resultCount() {
    final int total = state.faqs.total;
    return Semantics(
      liveRegion: true,
      child: Text(
        total == 1
            ? 'help.resultsOne'.tr()
            : 'help.resultsMany'.tr(
                namedArgs: <String, String>{'count': total.toString()},
              ),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.gray500,
          fontSize: AppTypography.size12,
        ),
      ),
    );
  }

  // ── Questions ──────────────────────────────────────────────────────────────

  Widget _questions(BuildContext context) {
    if (state.faqsLoading) {
      return const Column(children: <Widget>[
        _RowSkeleton(),
        SizedBox(height: AppSpacing.gap12),
        _RowSkeleton(),
        SizedBox(height: AppSpacing.gap12),
        _RowSkeleton(),
        SizedBox(height: AppSpacing.gap12),
        _RowSkeleton(),
      ]);
    }

    if (state.faqsFailed) {
      return HelpErrorBlock(
        message: 'help.faqsError'.tr(),
        retryLabel: 'help.retry'.tr(),
        onRetry: () => _bloc(context).add(const HelpFaqsRetried()),
      );
    }

    if (state.faqsEmpty) {
      // `:271-274` — two lines, not one, and neither is a retry.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: kHelpEmptyPaddingY),
        child: Column(
          children: <Widget>[
            Text(
              'help.noResults'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.gray800,
                fontSize: AppTypography.size16,
                fontWeight: AppTypography.semiBold,
              ),
            ),
            const SizedBox(height: AppSpacing.gap6),
            Text(
              'help.noResultsDesc'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.gray500,
                fontSize: AppTypography.size14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: <Widget>[
        for (int i = 0; i < state.faqs.items.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.gap12),
          _faqCard(context, state.faqs.items[i]),
        ],
      ],
    );
  }

  Widget _faqCard(BuildContext context, FaqItem item) {
    final ({int index, String icon}) meta =
        helpCategoryMeta(state.categories, item.category);

    return FaqCard(
      item: item,
      open: state.openFaqId == item.id,
      swatch: AppColors.helpSwatch(meta.index),
      iconName: AppIcons.help(meta.icon),
      showPopular: item.helpful >= kHelpPopularThreshold && !state.searching,
      popularLabel: 'help.popular'.tr(),
      relatedLabel: 'help.relatedService'.tr(),
      relatedTab: kHelpCategoryTab[item.category],
      helpfulPrompt: 'help.helpfulPrompt'.tr(),
      thanksLabel: 'help.feedbackThanks'.tr(),
      yesLabel: 'help.voteYes'.tr(),
      noLabel: 'help.voteNo'.tr(),
      vote: state.votes[item.id],
      onToggle: () => _bloc(context).add(HelpFaqToggled(item.id)),
      onVote: (bool helpful) =>
          _bloc(context).add(HelpFaqVoted(id: item.id, helpful: helpful)),
      onRelated: (String tab) =>
          context.go(kHelpTabPaths[tab] ?? AppNameRoutes.home),
    );
  }

  // ── Step-by-step guides ────────────────────────────────────────────────────

  Widget _guides(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            'help.guidesTitle'.tr(),
            style: const TextStyle(
              color: AppColors.gray900,
              fontSize: AppTypography.size18,
              fontWeight: AppTypography.bold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.gap16),
        if (state.guidesLoading)
          const Column(children: <Widget>[
            _RowSkeleton(),
            SizedBox(height: AppSpacing.gap12),
            _RowSkeleton(),
          ])
        else if (state.guidesFailed)
          HelpErrorBlock(
            message: 'help.guidesError'.tr(),
            retryLabel: 'help.retry'.tr(),
            onRetry: () => _bloc(context).add(const HelpGuidesRetried()),
          )
        else if (state.guidesEmpty)
          Text(
            'help.guidesEmpty'.tr(),
            style: const TextStyle(
              color: AppColors.gray500,
              fontSize: AppTypography.size14,
            ),
          )
        else
          Column(
            children: <Widget>[
              for (int i = 0; i < state.guides.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: AppSpacing.gap12),
                GuideCard(
                  guide: state.guides[i],
                  open: state.openGuideSlug == state.guides[i].slug,
                  body: state.bodyIsFor(state.guides[i].slug)
                      ? state.guideBody
                      : null,
                  bodyFailed: state.openGuideSlug == state.guides[i].slug &&
                      state.guideBodyFailed,
                  errorMessage: 'help.guideBodyError'.tr(),
                  retryLabel: 'help.retry'.tr(),
                  onToggle: () => _bloc(context)
                      .add(HelpGuideToggled(state.guides[i].slug)),
                  onRetry: () => _bloc(context).add(const HelpGuideRetried()),
                ),
              ],
            ],
          ),
      ],
    );
  }

  // ── Still stuck ────────────────────────────────────────────────────────────

  Widget _stillStuck(BuildContext context) {
    return Container(
      // `rounded-2xl border border-gray-100 bg-white p-6 text-center`
      padding: const EdgeInsets.all(AppSpacing.gap24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        children: <Widget>[
          Text(
            'help.stillStuck'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.gray800,
              fontSize: AppTypography.size16,
              fontWeight: AppTypography.semiBold,
            ),
          ),
          const SizedBox(height: AppSpacing.gap6),
          Text(
            'help.stillStuckDesc'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.gray500,
              fontSize: AppTypography.size14,
              height: AppTypography.lineRelaxed,
            ),
          ),
          const SizedBox(height: AppSpacing.gap20),
          _channels(context),
        ],
      ),
    );
  }

  Widget _channels(BuildContext context) {
    if (state.channelsLoading) {
      return const Column(children: <Widget>[
        HelpSkeleton(
          height: _channelSkeletonHeight,
          radius: AppSpacing.radiusXl,
        ),
        SizedBox(height: AppSpacing.gap12),
        HelpSkeleton(
          height: _channelSkeletonHeight,
          radius: AppSpacing.radiusXl,
        ),
        SizedBox(height: AppSpacing.gap12),
        HelpSkeleton(
          height: _channelSkeletonHeight,
          radius: AppSpacing.radiusXl,
        ),
        SizedBox(height: AppSpacing.gap12),
        HelpSkeleton(
          height: _channelSkeletonHeight,
          radius: AppSpacing.radiusXl,
        ),
      ]);
    }

    if (state.channelsFailed) {
      return HelpErrorBlock(
        message: 'help.channelsError'.tr(),
        retryLabel: 'help.retry'.tr(),
        onRetry: () => _bloc(context).add(const HelpChannelsRetried()),
      );
    }

    if (state.channelsEmpty) {
      // `:479-486` — the empty state is the account link, not a message.
      return HelpPrimaryButton(
        label: 'help.contactSupport'.tr(),
        onPressed: () => context.go(AppNameRoutes.account),
        trailing: const LucideIcon(
          name: 'ChevronRight',
          size: AppSpacing.gap16,
          color: AppColors.white,
        ),
      );
    }

    return Column(
      children: <Widget>[
        for (int i = 0; i < state.channels.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.gap12),
          SupportChannelTile(
            channel: state.channels[i],
            // `icon(ch.icon, MessageCircle)` — `:490`. This is the ONE call
            // site whose fallback is not `FileText`, so it is applied here
            // rather than inside `AppIcons.help` (whose doc records that the
            // source's second parameter is never otherwise passed).
            iconName: _channelIcon(state.channels[i].icon),
          ),
        ],
      ],
    );
  }

  /// `icon(name, MessageCircle)` — resolve through the help scope, but fall
  /// back to `MessageCircle` rather than `FileText`.
  static String _channelIcon(String name) {
    final String resolved = AppIcons.help(name);
    return resolved == AppIcons.fallback && name != AppIcons.fallback
        ? 'MessageCircle'
        : resolved;
  }
}

/// `bg-white rounded-2xl border border-gray-100 p-4` with a square and a bar —
/// the skeleton both accordions use (`:262-265`, `:397-400`).
class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gap16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        border: Border.all(color: AppColors.gray100),
      ),
      child: const Row(
        children: <Widget>[
          HelpSkeleton(height: AppSpacing.gap32, width: AppSpacing.gap32),
          SizedBox(width: AppSpacing.gap12),
          Expanded(child: HelpSkeleton(height: AppSpacing.gap16)),
        ],
      ),
    );
  }
}

/// `/news` — the news list.
///
/// Port of `lcc-app/src/app/components/NewsPage.tsx` (231 lines).
///
/// ## The four states, per region (§ 6.6, B2-AC-16)
///
/// | Region | loading | data | empty | error |
/// |---|---|---|---|---|
/// | chips | 4 pill skeletons | "All" + one per category | "All" alone | "All" + retry |
/// | list | 4 card skeletons | up to 6 cards | `news.empty` | message + `Try again` |
///
/// The **chips' error-with-retry is an addition**. The source renders
/// `categories.data ?? []` (`:103`) — a failed category fetch silently shows
/// "All" and nothing else, with no way to recover. § 6.6 makes
/// error-with-retry mandatory per network-backed surface, and B2-AC-16 says an
/// empty list is never an acceptable rendering of a failed fetch. The addition
/// is recorded in the Tier 1 oracle as `categories.error`, sourced to
/// `ADDED by B2c — § 6.6 / B2-AC-16`, so the oracle states it rather than the
/// diff hiding it.
///
/// ## No locator read here (G-L5, SSD § 6.4)
///
/// The BLoC arrives through a `BlocProvider` the `/news` route builder created.
/// This page names no container.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../utils/routes/app_name_routes.dart';
import '../../domain/entities/news_article.dart';
import '../bloc/news_bloc.dart';
import '../widgets/news_article_card.dart';
import '../widgets/news_category_chips.dart';
import '../widgets/news_header.dart';
import '../widgets/news_pager.dart';
import '../widgets/news_panels.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // `min-h-full bg-[#F0F2F8]`
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<NewsBloc, NewsState>(
          builder: (BuildContext context, NewsState state) =>
              _NewsBody(state: state),
        ),
      ),
    );
  }
}

class _NewsBody extends StatelessWidget {
  const _NewsBody({required this.state});

  final NewsState state;

  NewsBloc _bloc(BuildContext context) => context.read<NewsBloc>();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        NewsHeader(
          title: 'news.title'.tr(),
          subtitle: 'news.subtitle'.tr(),
          backLabel: 'news.back'.tr(),
          // `onBack` is `navigateTo("home")` on the web (`App.tsx`'s
          // `onBack={() => navigateTo("home")}`). `context.pop()` would be
          // wrong for a deep link opened directly at `/news`, which has nothing
          // to pop to.
          onBack: () => context.go(AppNameRoutes.home),
        ),
        Padding(
          // `px-4 py-6`
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gap16,
            vertical: AppSpacing.gap24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _chips(context),
              const SizedBox(height: AppSpacing.gap20),
              _list(context),
              if (state.showPager) ...<Widget>[
                const SizedBox(height: AppSpacing.gap24),
                NewsPager(
                  page: state.result.page,
                  totalPages: state.result.totalPages,
                  hasPrev: state.result.hasPrev,
                  hasNext: state.result.hasNext,
                  previousLabel: 'news.previousPage'.tr(),
                  nextLabel: 'news.nextPage'.tr(),
                  onPrevious: () => _bloc(context).add(const NewsPreviousPage()),
                  onNext: () => _bloc(context).add(const NewsNextPage()),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Category chips ─────────────────────────────────────────────────────────

  Widget _chips(BuildContext context) {
    if (state.categoriesLoading) {
      return const Wrap(
        spacing: AppSpacing.gap8,
        runSpacing: AppSpacing.gap8,
        children: <Widget>[
          NewsSkeleton(
            height: AppSpacing.tile36,
            width: AppSpacing.gap40 * 2,
            radius: AppSpacing.radiusFull,
          ),
          NewsSkeleton(
            height: AppSpacing.tile36,
            width: AppSpacing.gap40 * 3,
            radius: AppSpacing.radiusFull,
          ),
          NewsSkeleton(
            height: AppSpacing.tile36,
            width: AppSpacing.gap40 * 2,
            radius: AppSpacing.radiusFull,
          ),
          NewsSkeleton(
            height: AppSpacing.tile36,
            width: AppSpacing.gap40 * 3,
            radius: AppSpacing.radiusFull,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        NewsCategoryChips(
          categories: state.categories,
          selected: state.filter,
          allLabel: 'news.allCategories'.tr(),
          onPick: (String code) =>
              _bloc(context).add(NewsCategoryPicked(code)),
        ),
        // The § 6.6 addition — see the library doc.
        if (state.categoriesFailed)
          NewsErrorBlock(
            message: 'news.categoriesError'.tr(),
            retryLabel: 'news.retry'.tr(),
            onRetry: () => _bloc(context).add(const NewsCategoriesRetried()),
            verticalPadding: AppSpacing.gap16,
          ),
      ],
    );
  }

  // ── The list ───────────────────────────────────────────────────────────────

  Widget _list(BuildContext context) {
    if (state.listLoading) {
      // `[0,1,2,3].map(...)` — four card skeletons, `NewsPage.tsx:127`.
      return Column(
        children: <Widget>[
          for (int i = 0; i < 4; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.gap16),
            const _CardSkeleton(),
          ],
        ],
      );
    }

    if (state.listFailed) {
      return NewsErrorBlock(
        message: 'news.listError'.tr(),
        retryLabel: 'news.retry'.tr(),
        onRetry: () => _bloc(context).add(const NewsListRetried()),
      );
    }

    if (state.listEmpty) {
      return NewsEmptyBlock(message: 'news.empty'.tr());
    }

    return Column(
      children: <Widget>[
        for (int i = 0; i < state.articles.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.gap16),
          Builder(
            builder: (BuildContext context) {
              final NewsArticle article = state.articles[i];
              return NewsArticleCard(
                article: article,
                readMoreLabel: 'news.readMore'.tr(),
                onTap: () => context.go('${AppNameRoutes.news}/${article.slug}'),
              );
            },
          ),
        ],
      ],
    );
  }
}

/// `NewsPage.tsx:128-136` — a thumbnail block beside four text bars.
class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gap12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        border: Border.all(color: AppColors.gray100),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          NewsSkeleton(
            height: kNewsThumbSide,
            width: kNewsThumbSide,
            radius: AppSpacing.radiusXl,
          ),
          SizedBox(width: AppSpacing.gap16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: AppSpacing.gap4),
                NewsSkeleton(
                  height: AppSpacing.gap16,
                  width: AppSpacing.gap24 * 4,
                  radius: AppSpacing.radiusFull,
                ),
                SizedBox(height: AppSpacing.gap8),
                NewsSkeleton(height: AppSpacing.gap16),
                SizedBox(height: AppSpacing.gap8),
                NewsSkeleton(height: AppSpacing.gap12),
                SizedBox(height: AppSpacing.gap8),
                NewsSkeleton(height: AppSpacing.gap12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

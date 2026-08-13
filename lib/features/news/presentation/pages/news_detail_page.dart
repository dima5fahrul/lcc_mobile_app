/// `/news/:slug` — one article.
///
/// Port of `lcc-app/src/app/components/NewsDetailPage.tsx` (294 lines).
///
/// ## The four renders, in the source's own order (`:88-155`)
///
/// 1. `resolving` → the skeleton (sub-header + hero block + bars)
/// 2. `loadError && !loadError.isNotFound` → message, `Try again`, back link
/// 3. `!article` → `news.empty` plus a back link, **and no retry** (a 404
///    cannot be retried into existence)
/// 4. otherwise → hero, meta row, title, paragraphs, related service, more news
///
/// ## A recorded divergence from the running web app — read this before Tier 3
///
/// **At `62f8a529` this page never reaches render 4 in a browser.**
/// `routes.ts:60` composes
/// `new RegExp("^#" + NEWS_DETAIL.source)` where `NEWS_DETAIL` already begins
/// with `^`, producing `^#^\/news\/([^/]+)$` — a pattern that cannot match any
/// string. So `newsIdFromHash()` always returns `null`, `App.tsx:183` passes
/// `id={null}`, `slug` is `undefined`, the `enabled: Boolean(slug)` detail
/// query never fires, and every visit to `#/news/<anything>` renders render 3.
/// Verified against the live rig: `GET /news/<slug>` is never issued.
///
/// The Flutter route is a real path parameter, so this page **does** reach
/// render 4. That is a deliberate divergence from the running application and
/// an alignment with the component's source, which is unambiguous about what it
/// draws. It is escalated rather than absorbed: it moves `NewsDetailPage` off
/// specs.md § 6.5.2(a)'s "missing but CAPTURABLE" premise for the article
/// render, and baseline slot 15 therefore captures render 3 — the only state
/// the web can show — with the article render reported Tier 3 NOT EVALUATED,
/// by name, for this reason.
///
/// Tiers 1 and 2 are unaffected and remain blocking: they read the **source**,
/// not a screenshot (§ 6.5.2(b)'s own reasoning, and `test/fidelity/README.md`
/// limit 3).
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../../utils/routes/app_name_routes.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/news_formatting.dart';
import '../bloc/news_detail_bloc.dart';
import '../widgets/bilingual_text.dart';
import '../widgets/category_badge.dart';
import '../widgets/more_news_card.dart';
import '../widgets/news_cover.dart';
import '../widgets/news_panels.dart';
import '../widgets/news_sub_header.dart';

/// `h-52` — the hero's 208 CSS px height. (`sm:h-64` is a ≥640 px breakpoint;
/// the app's canonical viewport is 390, so the small value is the one that
/// applies. `AppSpacing.skeletonServiceCard` is that same 208 and is reused
/// rather than re-derived, per its own doc.)
const double kNewsHeroHeight = AppSpacing.skeletonServiceCard;

class NewsDetailPage extends StatelessWidget {
  const NewsDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<NewsDetailBloc, NewsDetailState>(
          builder: (BuildContext context, NewsDetailState state) =>
              _DetailBody(state: state),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.state});

  final NewsDetailState state;

  /// `onBack` — `App.tsx` wires it to `navigateTo("news")`. `context.go`, not
  /// `pop`, because a deep link opened straight at `/news/<slug>` has nothing
  /// to pop to.
  void _back(BuildContext context) => context.go(AppNameRoutes.news);

  @override
  Widget build(BuildContext context) {
    if (state.loading) return _skeleton(context);
    if (state.failed) return _error(context);
    if (state.missing) return _empty(context);
    return _article(context, state.article!);
  }

  // ── 1. Loading ─────────────────────────────────────────────────────────────

  Widget _skeleton(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        NewsSubHeader(
          title: 'news.title'.tr(),
          backLabel: 'news.backToNews'.tr(),
          onBack: () => _back(context),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.gap16,
            vertical: AppSpacing.gap24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              NewsSkeleton(
                height: kNewsHeroHeight,
                radius: AppSpacing.radius3xl,
                color: AppColors.gray200,
              ),
              SizedBox(height: AppSpacing.gap20),
              NewsSkeleton(
                height: AppSpacing.gap16,
                width: AppSpacing.gap32 * 4,
                radius: AppSpacing.radiusFull,
                color: AppColors.gray200,
              ),
              SizedBox(height: AppSpacing.gap16),
              NewsSkeleton(height: AppSpacing.gap24, color: AppColors.gray200),
              SizedBox(height: AppSpacing.gap20),
              NewsSkeleton(height: AppSpacing.gap12, color: AppColors.gray200),
              SizedBox(height: AppSpacing.gap12),
              NewsSkeleton(height: AppSpacing.gap12, color: AppColors.gray200),
              SizedBox(height: AppSpacing.gap12),
              NewsSkeleton(height: AppSpacing.gap12, color: AppColors.gray200),
              SizedBox(height: AppSpacing.gap12),
              NewsSkeleton(height: AppSpacing.gap12, color: AppColors.gray200),
            ],
          ),
        ),
      ],
    );
  }

  // ── 2. Error, with retry AND a way back ────────────────────────────────────

  Widget _error(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.gap32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            NewsErrorBlock(
              message: 'news.detailError'.tr(),
              retryLabel: 'news.retry'.tr(),
              onRetry: () =>
                  context.read<NewsDetailBloc>().add(const NewsDetailRetried()),
              verticalPadding: 0,
            ),
            const SizedBox(height: AppSpacing.gap16),
            _BackToNewsLink(onTap: () => _back(context)),
          ],
        ),
      ),
    );
  }

  // ── 3. Missing (404) — no retry ────────────────────────────────────────────

  Widget _empty(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.gap32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            NewsEmptyBlock(message: 'news.empty'.tr(), verticalPadding: 0),
            const SizedBox(height: AppSpacing.gap16),
            _BackToNewsLink(onTap: () => _back(context)),
          ],
        ),
      ),
    );
  }

  // ── 4. The article ─────────────────────────────────────────────────────────

  Widget _article(BuildContext context, NewsArticle article) {
    final String language = Localizations.localeOf(context).languageCode;
    final List<String> paragraphs = article.paragraphs(language);
    final String? related = _relatedTab(article);

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        NewsSubHeader(
          title: 'news.title'.tr(),
          backLabel: 'news.backToNews'.tr(),
          onBack: () => _back(context),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gap16,
            vertical: AppSpacing.gap24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Hero — `rounded-3xl overflow-hidden h-52`
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) =>
                    NewsCover(
                  coverUrl: article.coverUrl,
                  categoryColor: article.categoryColor,
                  width: constraints.maxWidth,
                  height: kNewsHeroHeight,
                  radius: AppSpacing.radius3xl,
                ),
              ),
              const SizedBox(height: AppSpacing.gap20),
              _metaRow(context, article, language),
              const SizedBox(height: AppSpacing.gap12),
              // `<h1 class="text-2xl font-bold leading-snug">`
              Semantics(
                header: true,
                child: Text(
                  article.title.forContext(context),
                  style: const TextStyle(
                    color: AppColors.gray900,
                    fontSize: AppTypography.size24,
                    fontWeight: AppTypography.bold,
                    height: AppTypography.lineSnug,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.gap16),
              // `paragraphs.length > 0 ? paragraphs : [excerpt]` — `:228`.
              for (final String para in paragraphs.isNotEmpty
                  ? paragraphs
                  : <String>[article.excerpt.forContext(context)])
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.gap16),
                  child: Text(
                    para,
                    style: const TextStyle(
                      color: AppColors.gray600,
                      fontSize: AppTypography.size15,
                      height: AppTypography.lineRelaxed,
                    ),
                  ),
                ),
              if (related != null) ...<Widget>[
                const SizedBox(height: AppSpacing.gap16),
                _relatedPanel(context, article, related),
              ],
              if (state.showMore) ...<Widget>[
                const SizedBox(height: AppSpacing.gap32),
                Semantics(
                  header: true,
                  child: Text(
                    'news.moreNews'.tr(),
                    style: const TextStyle(
                      color: AppColors.gray900,
                      fontSize: AppTypography.size18,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.gap16),
                for (int i = 0; i < state.more.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: AppSpacing.gap12),
                  Builder(
                    builder: (BuildContext context) {
                      final NewsArticle other = state.more[i];
                      return MoreNewsCard(
                        article: other,
                        onTap: () =>
                            context.go('${AppNameRoutes.news}/${other.slug}'),
                      );
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// The meta row: badge · date · read time · views. The last two are rendered
  /// only when `> 0` (`:211`, `:217`).
  Widget _metaRow(
    BuildContext context,
    NewsArticle article,
    String language,
  ) {
    return Wrap(
      spacing: AppSpacing.gap12,
      runSpacing: AppSpacing.gap8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        CategoryBadge(
          label: article.categoryName.forContext(context),
          color: article.categoryColor,
        ),
        _MetaItem(
          icon: 'Calendar',
          label: formatNewsDate(article.publishedOn, language),
        ),
        if (article.readMinutes > 0)
          _MetaItem(
            icon: 'Clock',
            // `${read_minutes} min read` / `ອ່ານ ${read_minutes} ນາທີ` —
            // `:214`. Interpolated through the dictionary so both locales'
            // word order survives; the source hard-codes the two strings.
            label: 'news.readMinutes'.tr(
              namedArgs: <String, String>{
                'count': article.readMinutes.toString(),
              },
            ),
          ),
        if (article.viewCount > 0)
          _MetaItem(
            icon: 'Eye',
            // `{article.view_count}` — the bare number, no label.
            label: article.viewCount.toString(),
          ),
      ],
    );
  }

  /// `:236-251` — the related-service panel.
  Widget _relatedPanel(
    BuildContext context,
    NewsArticle article,
    String tab,
  ) {
    final int? accent = newsSolid(article.categoryColor);

    return Container(
      // `rounded-2xl border border-gray-100 bg-white p-5`
      padding: const EdgeInsets.all(AppSpacing.gap20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            // `uppercase tracking-wide` — the CSS transform is applied here so
            // the dictionary keeps its natural-case string (Lao has no case,
            // and `toUpperCase()` is a no-op on it, exactly as in the browser).
            'news.relatedTitle'.tr().toUpperCase(),
            style: TextStyle(
              color: accent == null ? AppColors.primary : Color(accent),
              fontSize: AppTypography.size12,
              fontWeight: AppTypography.semiBold,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.gap6),
          Text(
            'news.relatedDesc'.tr(),
            style: const TextStyle(
              color: AppColors.gray500,
              fontSize: AppTypography.size14,
            ),
          ),
          const SizedBox(height: AppSpacing.gap16),
          Align(
            alignment: Alignment.centerLeft,
            child: NewsPrimaryButton(
              label: 'news.openService'.tr(),
              onPressed: () => context.go(_pathForTab(tab)),
              trailing: const LucideIcon(
                name: 'ArrowRight',
                size: AppSpacing.gap16,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `article.tags?.find(tag => tag in TAB_TO_PATH) ?? (category === "service"
  /// ? "service" : undefined)` — `:165-167`.
  ///
  /// `TAB_TO_PATH`'s keys are `routes.ts:12-27`; the six certificate sub-routes
  /// have no Flutter page yet (F0–F4 build them), so they are **not** in
  /// [_tabPaths] and a tag naming one falls through to the `service` fallback
  /// rather than deep-linking to a route that does not exist.
  static String? _relatedTab(NewsArticle article) {
    for (final String tag in article.tags) {
      if (_tabPaths.containsKey(tag)) return tag;
    }
    return article.category == 'service' ? 'service' : null;
  }

  static String _pathForTab(String tab) => _tabPaths[tab] ?? AppNameRoutes.home;

  /// The subset of `TAB_TO_PATH` that has a Flutter route today
  /// (`app_name_routes.dart`). `auth` maps to `/signin`, as it does on the web.
  static const Map<String, String> _tabPaths = <String, String>{
    'home': AppNameRoutes.home,
    'service': AppNameRoutes.service,
    'history': AppNameRoutes.history,
    'wallet': AppNameRoutes.wallet,
    'account': AppNameRoutes.account,
    'help': AppNameRoutes.help,
    'news': AppNameRoutes.news,
    'auth': AppNameRoutes.signin,
  };
}

/// `‹ Back to news` — the text link on the error and empty renders
/// (`:128-135`, `:145-152`).
class _BackToNewsLink extends StatelessWidget {
  const _BackToNewsLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.gap4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const LucideIcon(
                name: 'ChevronLeft',
                size: AppSpacing.gap16,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.gap6),
              Text(
                'news.backToNews'.tr(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: AppTypography.size14,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One `<span class="flex items-center gap-1.5 text-gray-500 text-xs">` of the
/// meta row. The icon is `aria-hidden` on the web, so it carries no label.
class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LucideIcon(
          name: icon,
          size: AppSpacing.gap14,
          color: AppColors.gray500,
        ),
        const SizedBox(width: AppSpacing.gap6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.gray500,
            fontSize: AppTypography.size12,
          ),
        ),
      ],
    );
  }
}

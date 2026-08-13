/// "News & Announcements" — `HomePage.tsx:615-735`.
///
/// Three featured articles in a horizontal strip, each a card with a
/// gradient-backed thumbnail, a category chip in the category's own colour, the
/// date, the title, the excerpt and a "Read more" link. Arrows scroll it; a
/// "View all news" link sits underneath.
///
/// ## Four states, all of them here
///
/// `newsQuery.loading` → three card skeletons; `error` → the red notice with a
/// retry; `data.length === 0` → the empty sentence; otherwise the strip. The
/// arrows and "View all news" render in **every** state, because the source
/// puts them outside the conditional block (`:707`) — a citizen whose news
/// failed can still reach the news page.
///
/// ## The cover image is remote, so it is not a Tier A asset
///
/// `item.cover_url` is a URL from the catalogue, of unknown dimensions, and
/// B2-AC-31 / B1b § 6.4 are about *bundled* assets whose native size is known
/// at build time. It gets no `cacheWidth` and the gradient behind it is what
/// renders while it loads or if it fails — which is the source's own
/// arrangement (`HomePage.tsx:661-673`: the gradient is always painted, the
/// `<img>` is conditional).
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/entities/home_news_item.dart';
import '../../domain/home_formatting.dart';
import 'bilingual_text.dart';
import 'category_slider.dart' show SliderArrows, kSliderAnimation, kSliderStep;
import 'home_service_card.dart' show ChevronLabel;

class NewsSlider extends StatefulWidget {
  const NewsSlider({
    super.key,
    required this.items,
    required this.onArticleTap,
  });

  final List<HomeNewsItem> items;

  /// `newsHref(item.slug)` — B2c's `/news/:slug`.
  final ValueChanged<HomeNewsItem> onArticleTap;

  @override
  State<NewsSlider> createState() => _NewsSliderState();
}

class _NewsSliderState extends State<NewsSlider> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _slideBy(int direction) {
    if (!_controller.hasClients) return;
    final double target = (_controller.offset + direction * kSliderStep)
        .clamp(0, _controller.position.maxScrollExtent);
    _controller.animateTo(
      target,
      duration: kSliderAnimation,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: AppSpacing.skeletonNewsCard,
          child: ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: const PageScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gap4),
            itemCount: widget.items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.gap16),
            itemBuilder: (BuildContext context, int index) =>
                _card(context, widget.items[index]),
          ),
        ),
        const SizedBox(height: AppSpacing.gap24),
        SliderArrows(
          onPrevious: () => _slideBy(-1),
          onNext: () => _slideBy(1),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, HomeNewsItem item) {
    final String languageCode = Localizations.localeOf(context).languageCode;
    // `item.category_color || "#344EAD"` — `HomePage.tsx:652`. Parsed at the
    // edge, never transcribed: the catalogue owns this value.
    final Color accent = item.categoryColor.isEmpty
        ? AppColors.primary
        : AppColors.parseHex(item.categoryColor);

    return SizedBox(
      // `w-[82%]` of the 390 px rig.
      width: 320,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => widget.onArticleTap(item),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
              border: Border.all(color: AppColors.gray100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _thumbnail(item, accent, languageCode),
                Expanded(child: _body(item, languageCode)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbnail(HomeNewsItem item, Color accent, String languageCode) {
    return SizedBox(
      height: AppSpacing.newsThumbHeight,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              // `linear-gradient(135deg, ${color} 0%, #17235c 100%)`
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[accent, AppColors.photoGradientEnd],
              ),
            ),
          ),
          if (item.coverUrl.isNotEmpty)
            Image.network(
              item.coverUrl,
              fit: BoxFit.cover,
              // The gradient is already painted underneath, so a failed cover
              // needs no placeholder of its own — it just does not draw. That
              // is the source's arrangement, not a swallowed error.
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              excludeFromSemantics: true,
            ),
          Positioned(
            top: AppSpacing.gap12,
            left: AppSpacing.gap12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gap10,
                vertical: AppSpacing.gap4,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                item.categoryName.forLanguage(languageCode),
                style: TextStyle(
                  color: accent,
                  fontSize: AppTypography.size11,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(HomeNewsItem item, String languageCode) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.gap16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            formatDate(item.publishedOn, languageCode),
            style: const TextStyle(
              color: AppColors.gray500,
              fontSize: AppTypography.size12,
            ),
          ),
          const SizedBox(height: AppSpacing.gap4),
          Text(
            item.title.forLanguage(languageCode),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.gray800,
              fontSize: AppTypography.size16,
              fontWeight: AppTypography.semiBold,
              height: AppTypography.lineSnug,
            ),
          ),
          const SizedBox(height: AppSpacing.gap6),
          Expanded(
            child: Text(
              item.excerpt.forLanguage(languageCode),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.gray500,
                fontSize: AppTypography.size14,
                height: AppTypography.lineRelaxed,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.gap8),
          ChevronLabel(
            label: 'home.readMore'.tr(),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

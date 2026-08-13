/// `HomeNewsItem` — one card of Home's "News & Announcements" slider.
///
/// `GET /news?per_page=3&featured=true` (`HomePage.tsx:172-175`), a **paged**
/// endpoint, so the rows arrive inside `{data, meta}` rather than as a bare
/// array.
///
/// ## Why this is not `features/news/`'s entity
///
/// Because `features/news/**` is **B2c's**, and § 3.1 states the sub-batch
/// scopes are disjoint after B2a. B2b and B2c run concurrently against the same
/// repository (§ 2.3), so a shared entity would be a file two dispatches both
/// create. Cross-Feature Isolation would permit `home → news/domain` once B2c
/// lands (G-L3 allows the `domain/` edge); it does not permit B2b to author
/// B2c's directory to get it.
///
/// The consequence is a real and deliberate duplication: B2c will hold a wider
/// `NewsArticle` (body, tags, author, view counts, read minutes) for the list
/// and detail pages. This one carries the **nine fields Home's card renders**
/// and nothing else, which is why it is a projection with its own name rather
/// than a half-populated copy of B2c's. Consolidating the two — if the wider
/// entity turns out to be a superset in practice — is a follow-up for whoever
/// lands second, not something B2b can do alone.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/bilingual.dart';

part 'home_news_item.freezed.dart';

@freezed
abstract class HomeNewsItem with _$HomeNewsItem {
  const factory HomeNewsItem({
    @Default('') String id,

    /// The article's stable key. `newsHref(item.slug)` (`HomePage.tsx:656`)
    /// builds `#/news/<slug>`; the Flutter route is B2c's `/news/:slug`.
    @Default('') String slug,
    @Default(Bilingual(en: '', lo: '')) Bilingual categoryName,

    /// `#RRGGBB`, or empty. **Data, not a token** — `item.category_color ||
    /// "#344EAD"` (`HomePage.tsx:652`) is the source's own fallback chain and
    /// the value behind it changes without an app release, so it is parsed at
    /// the edge and never transcribed (see `AppColors`' note on runtime colour
    /// families).
    @Default('') String categoryColor,
    @Default(Bilingual(en: '', lo: '')) Bilingual title,
    @Default(Bilingual(en: '', lo: '')) Bilingual excerpt,

    /// A remote thumbnail URL, or empty. The card draws the category gradient
    /// underneath either way (`HomePage.tsx:661-673`), so an absent cover is a
    /// styled card rather than a hole.
    @Default('') String coverUrl,

    /// `item.published_date || item.published_at` is the source's precedence
    /// (`HomePage.tsx:684`); both are kept so the fallback is expressible.
    @Default('') String publishedDate,
    @Default('') String publishedAt,
  }) = _HomeNewsItem;

  const HomeNewsItem._();

  /// `item.published_date || item.published_at` — `HomePage.tsx:684`.
  String get publishedOn =>
      publishedDate.isNotEmpty ? publishedDate : publishedAt;
}

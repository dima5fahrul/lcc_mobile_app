/// `NewsArticle` — one article, in both the list and the detail shape.
///
/// Port of `types.ts`'s `NewsArticle`. Three endpoints return it:
///
/// | Source | Endpoint | Carries `body`? |
/// |---|---|---|
/// | `NewsPage.tsx:45` | `GET /news` (paged) | no |
/// | `newsData.ts:19` | `GET /news?per_page=100` (the catalogue) | no |
/// | `NewsDetailPage.tsx:73` | `GET /news/<slug>` | **yes** |
///
/// ## One entity, not two
///
/// The wire shape is the same interface in the source (`body?: Bilingual`) and
/// the detail page's own guard is `detail.data?.slug === slug`, i.e. it
/// identifies the article by slug and not by "is this the rich one". Splitting
/// it into `NewsListItem` / `NewsArticleDetail` would force a conversion at the
/// one place the two must agree — the "More news" strip, which renders
/// catalogue rows *inside* the detail page.
///
/// So `body` is `Bilingual?`: **null means "this row came from a list
/// endpoint"**, which is a real distinction the detail page acts on
/// (`paragraphs.length > 0 ? paragraphs : [excerpt]`, `:228`) and an empty
/// `Bilingual` could not express.
///
/// ## Why this is not `features/home/`'s `HomeNewsItem`
///
/// `HomeNewsItem`'s own doc records the split from B2b's side and names the
/// consolidation as "a follow-up for whoever lands second". B2c is second, and
/// it is **not** taking it: `lib/features/home/**` is outside B2c's § 3.1 scope
/// and outside the dispatch's write boundary. The two entities are a genuine
/// projection pair (Home draws nine fields; this draws eighteen), so merging
/// them means editing Home's, and that is a separate, reviewable change.
/// Recorded here so the duplication is a decision on the record rather than an
/// oversight.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/bilingual.dart';

part 'news_article.freezed.dart';

@freezed
abstract class NewsArticle with _$NewsArticle {
  const factory NewsArticle({
    @Default('') String id,

    /// The API's key for an article, and the Flutter route parameter:
    /// `/news/:slug`. See `news_repository.dart` for why the port does **not**
    /// carry the web's numeric `#/news/3` position bridge.
    @Default('') String slug,

    /// The category *code* (`announcement`, `service`, …) — used by
    /// `NewsDetailPage.tsx:167`'s `article.category === "service"` related-tab
    /// fallback, which is a code comparison and not a label one.
    @Default('') String category,
    @Default(Bilingual(en: '', lo: '')) Bilingual categoryName,

    /// `#RRGGBB`, or empty. Data, not a token — see [NewsCategory.color].
    @Default('') String categoryColor,
    @Default(Bilingual(en: '', lo: '')) Bilingual title,
    @Default(Bilingual(en: '', lo: '')) Bilingual excerpt,

    /// **Null when the row came from a list endpoint** — see the library doc.
    Bilingual? body,

    /// A remote hero/thumbnail URL, or empty. The card and the hero both draw
    /// the category gradient underneath either way (`NewsPage.tsx:161-173`,
    /// `NewsDetailPage.tsx:189-202`), so an absent cover is a styled surface
    /// rather than a hole.
    @Default('') String coverUrl,
    @Default('') String author,
    @Default('') String source,

    /// `NewsDetailPage.tsx:166` looks for a tag that names an app tab.
    @Default(<String>[]) List<String> tags,
    @Default(false) bool featured,
    @Default(false) bool pinned,

    /// Both are rendered only when `> 0` (`NewsDetailPage.tsx:211,217`).
    @Default(0) int viewCount,
    @Default(0) int readMinutes,
    @Default('') String publishedDate,
    @Default('') String publishedAt,
  }) = _NewsArticle;

  const NewsArticle._();

  /// The date the pages print. Both call sites pass `published_date`
  /// (`NewsPage.tsx:183`, `NewsDetailPage.tsx:209`); `published_at` is the
  /// fallback for a row that carries only the timestamp, which the recorded
  /// staging payload does not exercise but the wire type permits.
  String get publishedOn =>
      publishedDate.isNotEmpty ? publishedDate : publishedAt;

  /// `text(article.body, lang).split("\n").map(trim).filter(Boolean)` —
  /// `NewsDetailPage.tsx:158-161`.
  ///
  /// Returns `[]` when there is no body, which is what makes the caller's
  /// `paragraphs.length > 0 ? paragraphs : [excerpt]` fallback expressible.
  List<String> paragraphs(String languageCode) {
    final Bilingual? value = body;
    if (value == null) return const <String>[];
    final String wanted = languageCode == 'lo' ? value.lo : value.en;
    final String resolved =
        wanted.isNotEmpty ? wanted : (value.en.isNotEmpty ? value.en : value.lo);
    return resolved
        .split('\n')
        .map((String p) => p.trim())
        .where((String p) => p.isNotEmpty)
        .toList(growable: false);
  }
}

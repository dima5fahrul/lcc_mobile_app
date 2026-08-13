/// News' wire → entity parsing, hand-written rather than generated.
///
/// Same trade `home_wire.dart` records and for the same reasons: these rows are
/// read once into an entity and never round-tripped, so five generated
/// `@freezed` models plus five `.g.dart` files would exist only to be discarded
/// a line later. What generation would buy — that the parse cannot silently
/// disagree with the entity — is bought instead by parsing the **recorded
/// staging payloads** (B2-AC-36), which is stronger: `json_serializable`
/// validates a hand-written fixture against a hand-written model and both can
/// be wrong together.
///
/// ## The mixed wire shape is real on these endpoints
///
/// § 5's table names `/news` and `/help/faqs` as the endpoints that send a
/// **plain string** where `/services` sends `{en, lo}`. [bilingualAt] accepts
/// both. The recorded payload at `oracle/api/news.json` happens to send objects
/// today; the type in `types.ts` and § 5's measurement both say a string is
/// permitted, and a parser that assumed the object shape would parse the
/// fixture happily and throw on a future row — surfacing as an error panel that
/// looks like a network problem.
///
/// A missing scalar becomes its zero value rather than a parse failure, for the
/// reason `bilingual_converter.dart` gives: a half-populated pair renders one
/// language blank, which is visible and diagnosable; a thrown parse error takes
/// the whole page down over one bad field.
library;

import '../../../session/domain/entities/bilingual.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/entities/news_category.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Primitives
// ─────────────────────────────────────────────────────────────────────────────

/// A string field, or `''`.
String stringAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  return raw is String ? raw : '';
}

/// An integer field, or `fallback`.
///
/// Accepts a `double` for the reason `home_wire.dart` gives: JSON has one
/// number type, and a backend that serialises `3.0` for `read_minutes` is
/// sending an integer.
int intAt(Map<String, dynamic> json, String key, {int fallback = 0}) {
  final Object? raw = json[key];
  if (raw is int) return raw;
  if (raw is double) return raw.round();
  if (raw is String) return int.tryParse(raw) ?? fallback;
  return fallback;
}

/// A boolean field, or `fallback`.
bool boolAt(Map<String, dynamic> json, String key, {bool fallback = false}) {
  final Object? raw = json[key];
  return raw is bool ? raw : fallback;
}

/// A list of strings, dropping non-string elements. Never null.
List<String> stringListAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is! List) return const <String>[];
  return raw.whereType<String>().toList(growable: false);
}

/// **The mixed-shape reader** (§ 5, B2-AC-36).
///
/// * `{"en": …, "lo": …}` → both sides, each defaulting to `''`
/// * `"a plain string"` → that string on **both** sides
/// * anything else → an empty pair
///
/// Copying a plain string into both sides is faithful, not a shortcut:
/// `text(value, lang)` (`types.ts:17-22`) falls back `wanted || en || lo || ""`,
/// so a single-language field already renders the same text in either locale on
/// the web.
Bilingual bilingualAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is String) return Bilingual(en: raw, lo: raw);
  if (raw is Map<String, dynamic>) {
    return Bilingual(
      en: raw['en'] is String ? raw['en'] as String : '',
      lo: raw['lo'] is String ? raw['lo'] as String : '',
    );
  }
  return const Bilingual(en: '', lo: '');
}

/// [bilingualAt], but **null when the key is absent** rather than an empty
/// pair.
///
/// Only `body` uses this, and the distinction is load-bearing: null means "this
/// row came from a list endpoint and has no body", which
/// `NewsArticle.paragraphs` turns into the excerpt fallback
/// (`NewsDetailPage.tsx:228`). An empty `Bilingual` could not express it.
Bilingual? nullableBilingualAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw == null) return null;
  if (raw is String || raw is Map<String, dynamic>) return bilingualAt(json, key);
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Rows
// ─────────────────────────────────────────────────────────────────────────────

/// One row of `GET /news/categories`.
NewsCategory newsCategoryFrom(Map<String, dynamic> json) => NewsCategory(
      id: stringAt(json, 'id'),
      code: stringAt(json, 'code'),
      name: bilingualAt(json, 'name'),
      color: stringAt(json, 'color'),
    );

/// One row of `GET /news`, `GET /news?per_page=100` or `GET /news/<slug>`.
///
/// Parses **every** field the wire carries, including the ones no current
/// surface draws, for the reason `home_wire.dart`'s `serviceFrom` gives: a
/// partial construction would make the entity mean something different
/// depending on which call built it, and the "More news" strip renders
/// catalogue rows and detail rows side by side.
NewsArticle newsArticleFrom(Map<String, dynamic> json) => NewsArticle(
      id: stringAt(json, 'id'),
      slug: stringAt(json, 'slug'),
      category: stringAt(json, 'category'),
      categoryName: bilingualAt(json, 'category_name'),
      categoryColor: stringAt(json, 'category_color'),
      title: bilingualAt(json, 'title'),
      excerpt: bilingualAt(json, 'excerpt'),
      body: nullableBilingualAt(json, 'body'),
      coverUrl: stringAt(json, 'cover_url'),
      author: stringAt(json, 'author'),
      source: stringAt(json, 'source'),
      tags: stringListAt(json, 'tags'),
      featured: boolAt(json, 'featured'),
      pinned: boolAt(json, 'pinned'),
      viewCount: intAt(json, 'view_count'),
      readMinutes: intAt(json, 'read_minutes'),
      publishedDate: stringAt(json, 'published_date'),
      publishedAt: stringAt(json, 'published_at'),
    );

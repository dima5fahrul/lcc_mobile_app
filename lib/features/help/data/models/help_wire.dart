/// The help centre's wire → entity parsing.
///
/// Same trade `news_wire.dart` and `home_wire.dart` record: hand-written,
/// because these rows are read once into an entity and never round-tripped, and
/// the guarantee generation would buy is bought instead by parsing the
/// **recorded staging payloads** (B2-AC-36).
///
/// `/help/faqs` is one of the two endpoints § 5 measured sending a **plain
/// string** where `/services` sends `{en, lo}`, so [bilingualAt] accepts both
/// shapes on every field.
library;

import '../../../session/domain/entities/bilingual.dart';
import '../../domain/entities/help_entities.dart';

/// A string field, or `''`.
String stringAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  return raw is String ? raw : '';
}

/// An integer field, or `fallback`. Accepts a `double` — JSON has one number
/// type and a backend serialising `5.0` for `helpful` is sending an integer.
int intAt(Map<String, dynamic> json, String key, {int fallback = 0}) {
  final Object? raw = json[key];
  if (raw is int) return raw;
  if (raw is double) return raw.round();
  if (raw is String) return int.tryParse(raw) ?? fallback;
  return fallback;
}

/// A list of strings, dropping non-string elements. Never null.
List<String> stringListAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is! List) return const <String>[];
  return raw.whereType<String>().toList(growable: false);
}

/// **The mixed-shape reader** (§ 5, B2-AC-36) — `{en,lo}`, a plain string on
/// both sides, or an empty pair.
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

/// [bilingualAt], but **null when the key is absent** — see
/// [HelpArticle.body] for why the distinction has to survive parsing.
Bilingual? nullableBilingualAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw == null) return null;
  if (raw is String || raw is Map<String, dynamic>) return bilingualAt(json, key);
  return null;
}

/// One row of `GET /help/categories`.
FaqCategory faqCategoryFrom(Map<String, dynamic> json) => FaqCategory(
      id: stringAt(json, 'id'),
      code: stringAt(json, 'code'),
      name: bilingualAt(json, 'name'),
      icon: stringAt(json, 'icon'),
    );

/// One row of `GET /help/faqs`.
FaqItem faqItemFrom(Map<String, dynamic> json) => FaqItem(
      id: stringAt(json, 'id'),
      category: stringAt(json, 'category'),
      question: bilingualAt(json, 'question'),
      answer: bilingualAt(json, 'answer'),
      tags: stringListAt(json, 'tags'),
      helpful: intAt(json, 'helpful'),
      notHelpful: intAt(json, 'not_helpful'),
    );

/// One row of `GET /help/articles`, or the object from
/// `GET /help/articles/<slug>` — the same shape, differing only in whether
/// `body` is present.
HelpArticle helpArticleFrom(Map<String, dynamic> json) => HelpArticle(
      id: stringAt(json, 'id'),
      slug: stringAt(json, 'slug'),
      title: bilingualAt(json, 'title'),
      body: nullableBilingualAt(json, 'body'),
    );

/// One row of `GET /help/channels`.
SupportChannel supportChannelFrom(Map<String, dynamic> json) => SupportChannel(
      id: stringAt(json, 'id'),
      kind: stringAt(json, 'kind'),
      label: bilingualAt(json, 'label'),
      value: stringAt(json, 'value'),
      hours: bilingualAt(json, 'hours'),
      icon: stringAt(json, 'icon'),
    );

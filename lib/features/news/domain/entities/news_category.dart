/// `NewsCategory` — one chip in the news list's category filter.
///
/// Port of `types.ts`'s `NewsCategory`, served by `GET /news/categories`
/// (`endpoints.ts:369`, `anonymous: true`). Four rows on staging today:
/// `announcement` · `service` · `policy` · `event`.
///
/// [color] is **data, not a token.** `NewsPage.tsx:113` paints the active chip
/// with `c.color` straight off the wire, and the value changes without an app
/// release, so it is parsed at the edge and never transcribed into
/// `presentation/theme/` (see `AppColors`' note on runtime colour families).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/bilingual.dart';

part 'news_category.freezed.dart';

@freezed
abstract class NewsCategory with _$NewsCategory {
  const factory NewsCategory({
    @Default('') String id,

    /// The filter value sent back as `?category=<code>` — `NewsPage.tsx:108`.
    @Default('') String code,
    @Default(Bilingual(en: '', lo: '')) Bilingual name,

    /// `#RRGGBB`, or empty.
    @Default('') String color,
  }) = _NewsCategory;
}

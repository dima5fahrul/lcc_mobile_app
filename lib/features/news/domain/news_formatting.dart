/// The two pure string transforms the news pages perform.
///
/// In `domain/` and importing nothing from Flutter, for the reason
/// `home_formatting.dart` gives: these are table lookups over a value and a
/// language code, and `presentation/widgets/` is inside GOR-246 AC-5's coverage
/// **exclusion** set — which is exactly where a month-index-off-by-one would go
/// unmeasured.
///
/// ## Why [formatNewsDate] is a third copy of the same date formatter
///
/// The source has it twice already: `NewsPage.tsx:17-26` and
/// `NewsDetailPage.tsx:26-35` each declare their own `day()`, byte-identical.
/// `home_formatting.dart` holds the Flutter port of `HomePage.tsx`'s.
///
/// The alternatives were weighed and rejected:
///
/// * **Import `features/home/domain/home_formatting.dart`.** G-L3 permits it
///   (Cross-Feature Isolation allows the `domain/` edge), so this is legal —
///   and it is a dependency pointing the wrong way. News does not depend on
///   Home in any sense a reader would expect, and the coupling would make
///   deleting or reshaping Home a news-page problem.
/// * **Hoist it to `lib/core/`.** The right long-term home, and out of B2c's
///   § 3.1 scope: `lib/core/**` is listed for `api_endpoint.dart` and
///   `dependency_injection.dart` only.
///
/// So: a copy, declared as one. The duplication is **not** left to discipline —
/// `test/features/news/domain/news_formatting_test.dart` asserts this function
/// and `home_formatting.formatDate` agree over a corpus that includes every
/// month boundary, so the two cannot drift silently. Consolidating them into
/// `lib/core/` is a follow-up (FU), not a thing to do quietly inside a batch
/// whose file list forbids it.
library;

/// `'lo'` selects Lao; anything else is English. Mirrors the source's
/// `lang === "lo" ? … : …` rather than an exhaustive switch it does not do.
const String kLao = 'lo';

/// `en-GB` short month names as CLDR resolves `{ month: "short" }` — note
/// **`Sept`**, four characters, which is en-GB's abbreviation and not `Sep`.
const List<String> kNewsShortMonthsEn = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec',
];

/// `lo-LA` short month names, as CLDR resolves `{ month: "short" }`.
const List<String> kNewsShortMonthsLo = <String>[
  'ມ.ກ.', 'ກ.ພ.', 'ມ.ນ.', 'ມ.ສ.', 'ພ.ພ.', 'ມິ.ຖ.',
  'ກ.ລ.', 'ສ.ຫ.', 'ກ.ຍ.', 'ຕ.ລ.', 'ພ.ຈ.', 'ທ.ວ.',
];

/// `day(value, lang)` — `NewsPage.tsx:17-26` / `NewsDetailPage.tsx:26-35`.
///
/// `"2026-08-09"` → `"09 Aug 2026"` / `"09 ສ.ຫ. 2026"`.
///
/// Both fallbacks are the source's, not defensiveness:
/// * absent/empty → `""` (`if (!value) return ""`)
/// * unparseable → the input **verbatim**
///   (`Number.isNaN(d.getTime()) → return value`)
///
/// The second matters: a malformed date must print as itself rather than blank
/// the meta row or take the card down.
String formatNewsDate(String? value, String languageCode) {
  if (value == null || value.isEmpty) return '';

  final DateTime? parsed = DateTime.tryParse(value);
  if (parsed == null) return value;

  final List<String> months =
      languageCode == kLao ? kNewsShortMonthsLo : kNewsShortMonthsEn;
  final String day = parsed.day.toString().padLeft(2, '0');
  return '$day ${months[parsed.month - 1]} ${parsed.year}';
}

/// `tint(color)` — `NewsPage.tsx:29-31` / `NewsDetailPage.tsx:37-39`.
///
/// A category colour at ~10 % opacity for the badge wash: the source appends
/// the alpha byte `1A` to a `#RRGGBB` string, and falls back to the literal
/// `#EEF2FF` for anything that is not exactly six hex digits.
///
/// Returned as `(argb, isFallback)` rather than a `Color` because this file is
/// `domain/` and may not import `dart:ui`. The caller maps `isFallback` onto
/// `AppColors.primarySoft`, which **is** `#EEF2FF` — so the literal lives in
/// the theme where B2-AC-11 requires it, and this function never names it.
({int? argb, bool isFallback}) newsTint(String color) {
  final int? rgb = parseSixDigitHex(color);
  if (rgb == null) return (argb: null, isFallback: true);
  // `${color}1A` — 0x1A/0xFF ≈ 10.2 % alpha, the source's own value.
  return (argb: 0x1A000000 | rgb, isFallback: false);
}

/// `/^#[0-9a-fA-F]{6}$/` → the 24-bit RGB value, or null.
///
/// The regex is the source's, and it is strict on purpose: `#FFF`, `#RRGGBBAA`
/// and a bare `RRGGBB` all take the fallback branch on the web, so they must
/// take it here too.
int? parseSixDigitHex(String color) {
  if (color.length != 7 || !color.startsWith('#')) return null;
  for (int i = 1; i < 7; i++) {
    final int c = color.codeUnitAt(i);
    final bool hex = (c >= 0x30 && c <= 0x39) || // 0-9
        (c >= 0x41 && c <= 0x46) || // A-F
        (c >= 0x61 && c <= 0x66); // a-f
    if (!hex) return null;
  }
  return int.parse(color.substring(1), radix: 16);
}

/// The opaque ARGB behind a `#RRGGBB` wire colour, or null when it is not one.
///
/// Separate from [newsTint] because the two source expressions are separate:
/// the badge *text* and the gradient use `item.category_color` raw
/// (`NewsPage.tsx:163,179`) while only the badge *background* is tinted.
int? newsSolid(String color) {
  final int? rgb = parseSixDigitHex(color);
  return rgb == null ? null : 0xFF000000 | rgb;
}

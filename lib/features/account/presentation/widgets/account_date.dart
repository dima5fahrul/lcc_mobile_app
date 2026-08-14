/// `formatDate` — `AccountPage.tsx:80-89`, all three branches.
///
/// ```tsx
/// function formatDate(value: string | undefined, lang: Lang): string {
///   if (!value) return "—";
///   const d = new Date(value);
///   if (Number.isNaN(d.getTime())) return value;
///   return d.toLocaleDateString(lang === "lo" ? "lo-LA" : "en-GB",
///     { day: "2-digit", month: "short", year: "numeric" });
/// }
/// ```
///
/// **The middle branch is not an accident and it is ported** (B8-AC-27): an
/// unparseable value is echoed back *raw*, not replaced by the em dash and not
/// swallowed. A citizen whose record carries a malformed date sees the
/// malformed date, which is how anyone finds out it is malformed.
library;

import 'package:easy_localization/easy_localization.dart';

import '../../../../i18n/i18n.dart';

/// The three-branch port. [value] is the raw wire string.
///
/// ## `intl` is doing the same job `toLocaleDateString` does, with one caveat
///
/// `{day: "2-digit", month: "short", year: "numeric"}` under `en-GB` is
/// `dd MMM yyyy`; `DateFormat('dd MMM yyyy', 'en_GB')` is the same pattern
/// against the same CLDR data `Intl` ships, so the English column matches
/// exactly.
///
/// **For `lo-LA` it is a match only as far as the app's bundled locale data
/// reaches.** `easy_localization` initialises `intl` with the locales the app
/// declares, and `lo` month abbreviations come from CLDR just as the browser's
/// do — but the browser's ICU version and `package:intl`'s are pinned
/// separately and can disagree on an abbreviation. That is unmeasurable here
/// (no Tier 3 reference for this page exists at all, specs.md § 2.2 Finding C)
/// and is recorded rather than assumed away: the Lao date string is
/// **NOT EVALUATED** against the web's rendering, and B8-AC-27 gates the three
/// *branches*, not the Lao glyph sequence.
String formatAccountDate(String? value, Lang lang) {
  // `if (!value) return "—"` — JavaScript truthiness, so `""` takes this branch
  // too. `optionalStringAt` in `account_wire.dart` already collapses `""` to
  // null, so both arrive here as null.
  if (value == null || value.isEmpty) return '—';

  // `new Date(value)` then `Number.isNaN(d.getTime())`.
  final DateTime? parsed = DateTime.tryParse(value);
  if (parsed == null) return value; // the echo branch

  // ── `tryParse` is NOT `new Date` on an out-of-range component ─────────────
  //
  // Measured while writing `documents_card_test.dart`, and it is a real
  // divergence rather than a nicety:
  //
  //   JavaScript   new Date("2026-13-45")        → Invalid Date  → echo
  //   Dart         DateTime.tryParse("2026-13-45") → 2027-02-14  → "14 Feb 2027"
  //
  // Dart's parser accepts the syntax and lets month 13 and day 45 **overflow**
  // into the following year. Left alone, a malformed date on a citizen's
  // document would render as a confident, wrong, plausible-looking date —
  // strictly worse than the source's behaviour of showing the raw string,
  // because nobody would ever notice it. So the components are checked back
  // against what was written, and a mismatch takes the echo branch.
  //
  // Only the ISO date prefix is checked: that is the only shape the API sends
  // (`types.ts` types both fields `string` and every recorded `/me/*` payload
  // uses ISO-8601), and it is the only shape whose components can be read back
  // without re-implementing a date parser.
  final RegExpMatch? iso =
      RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
  if (iso != null &&
      (int.parse(iso.group(1)!) != parsed.year ||
          int.parse(iso.group(2)!) != parsed.month ||
          int.parse(iso.group(3)!) != parsed.day)) {
    return value;
  }

  return DateFormat('dd MMM yyyy', lang == Lang.lo ? 'lo_LA' : 'en_GB')
      .format(parsed);
}

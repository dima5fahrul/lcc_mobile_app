/// The four pure string transforms Home performs, ported as functions.
///
/// They live in `domain/` and import nothing from Flutter because that is what
/// they are: arithmetic and table lookups over a value and a language code.
/// Putting them in `presentation/widgets/` would have put them inside GOR-246
/// AC-5's coverage **exclusion** set, and every one of them is the kind of code
/// that fails on a boundary nobody looks at — a zero fee, a one-character name,
/// a month index off by one.
library;

/// The languages the app renders. `'lo'` selects Lao; anything else is
/// English, matching the source's `lang === "lo" ? … : …` shape rather than an
/// exhaustive switch it does not perform.
const String kLao = 'lo';

// ─────────────────────────────────────────────────────────────────────────────
// Money — `serviceConfig.ts:38-53`
// ─────────────────────────────────────────────────────────────────────────────

/// `n.toLocaleString("en-US")` — thousands separated by commas, **in both
/// locales**.
///
/// The source pins the grouping locale to `en-US` and only the *currency word*
/// changes with the language (`serviceConfig.ts:41-42`). That is not an
/// oversight to improve on: Lao renders Arabic numerals with comma grouping,
/// and switching to a locale-aware grouper would produce a different string
/// from the web for the same amount, which is a Tier 1 failure.
String groupThousands(int value) {
  final bool negative = value < 0;
  final String digits = value.abs().toString();
  final StringBuffer out = StringBuffer();

  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }

  return negative ? '-$out' : out.toString();
}

/// `formatLak(n, lang)` — `serviceConfig.ts:38-43`.
///
/// * `null` → `"—"` (an em dash: "not configured", not "free")
/// * `0` → `"Free"` / `"ຟຣີ"`
/// * otherwise → `"20,000 LAK"` / `"20,000 ກີບ"`
///
/// The `null` branch is reachable: `getServiceConfig` returns `fee: null` for a
/// service with no configured price, and the wallet tile calls this with the
/// balance, which the summary can omit.
String formatLak(int? amount, String languageCode) {
  if (amount == null) return '—';
  if (amount == 0) return languageCode == kLao ? 'ຟຣີ' : 'Free';
  final String number = groupThousands(amount);
  return languageCode == kLao ? '$number ກີບ' : '$number LAK';
}

/// `formatFee(cfg, lang)` — `serviceConfig.ts:46-53`.
///
/// A **range** only when all three of the source's conditions hold:
/// `feeMax != null && fee != null && feeMax > fee`. A `fee_max_lak` that is
/// zero, absent or equal to `fee_lak` is not a range — every catalogue row but
/// `marriage` is in that state today, and treating `0` as an upper bound would
/// print `"20,000–0 LAK"` on 42 of 43 services.
///
/// Note the separator is an EN DASH (`–`, U+2013), not a hyphen. The source
/// writes it that way and a Tier 1 text comparison is byte-exact.
String formatFee({
  required int? fee,
  required int? feeMax,
  required String languageCode,
}) {
  if (feeMax != null && fee != null && feeMax > fee) {
    final String low = groupThousands(fee);
    final String high = groupThousands(feeMax);
    return languageCode == kLao
        ? '$low–$high ກີບ'
        : '$low–$high LAK';
  }
  return formatLak(fee, languageCode);
}

// ─────────────────────────────────────────────────────────────────────────────
// Masking — `Hero.tsx:25-38`
// ─────────────────────────────────────────────────────────────────────────────

/// `maskValue(value, keep)` — keep the first and last *real* character, replace
/// every other non-separator with `•`.
///
/// `"Bounmy Sisavath"` → `"B••••• •••••••h"`, `"1-2540-08842-15"` with
/// `keep: ' -'` → `"1-••••-•••••-•5"`.
///
/// The two subtleties the source has and a naive rewrite loses:
///
/// 1. **`first` and `last` index into the whole string, not into the run.** A
///    separator between them stays a separator; only the ends are exempt.
/// 2. **A one-character value has `first == last`**, so it is returned intact
///    rather than masked to a single bullet. That is the branch a signed-in
///    citizen with a single-character display name would hit, and it is why
///    the two indices are compared rather than counted.
///
/// Iterates over *runes*, not UTF-16 code units, so a Lao name is masked by
/// character rather than by surrogate half.
String maskValue(String value, {String keep = ' '}) {
  final List<int> runes = value.runes.toList(growable: false);
  final Set<int> keepCodes = keep.runes.toSet();

  int first = -1;
  int last = -1;
  for (int i = 0; i < runes.length; i++) {
    if (!keepCodes.contains(runes[i])) {
      if (first == -1) first = i;
      last = i;
    }
  }

  final StringBuffer out = StringBuffer();
  for (int i = 0; i < runes.length; i++) {
    final bool exempt =
        keepCodes.contains(runes[i]) || i == first || i == last;
    out.write(exempt ? String.fromCharCode(runes[i]) : '•');
  }
  return out.toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// Dates — `HomePage.tsx:96-105`
// ─────────────────────────────────────────────────────────────────────────────

/// `en-GB` short month names, as CLDR resolves them for
/// `{ month: "short" }` — note **`Sept`**, four characters, which is en-GB's
/// abbreviation and not the three-letter US `Sep`.
const List<String> kShortMonthsEn = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec',
];

/// `lo-LA` short month names, as CLDR resolves them for `{ month: "short" }`.
///
/// Transcribed from the ICU output rather than invented, because this is the
/// one table in this file a reviewer cannot check by reading English.
const List<String> kShortMonthsLo = <String>[
  'ມ.ກ.', 'ກ.ພ.', 'ມ.ນ.', 'ມ.ສ.', 'ພ.ພ.', 'ມິ.ຖ.',
  'ກ.ລ.', 'ສ.ຫ.', 'ກ.ຍ.', 'ຕ.ລ.', 'ພ.ຈ.', 'ທ.ວ.',
];

/// `formatDate(value, lang)` — `"2026-08-06"` → `"06 Aug 2026"` /
/// `"06 ສ.ຫ. 2026"`.
///
/// ## Why the month names are a table and not `intl`
///
/// `package:intl`'s `DateFormat` needs `initializeDateFormatting()` before it
/// can format a non-`en_US` locale, and reaching for it would mean importing a
/// package this app does not declare — a transitive dependency of
/// `easy_localization`, which `depend_on_referenced_packages` correctly fails
/// `flutter analyze` for. `pubspec.yaml` is out of scope for B2b (§ 3.1), so
/// the two twelve-row tables above are the port, and they are exactly the
/// strings ICU produces.
///
/// ## The two fallbacks are the source's, not defensiveness
///
/// An empty/absent value returns `''` and an unparseable one returns the input
/// **verbatim** (`Number.isNaN(d.getTime()) → return value`). Both matter: the
/// news card prints this straight into a `Text`, and a row with a malformed
/// date must show the raw string rather than blank the line or take the slider
/// down.
String formatDate(String? value, String languageCode) {
  if (value == null || value.isEmpty) return '';

  final DateTime? parsed = DateTime.tryParse(value);
  if (parsed == null) return value;

  final List<String> months =
      languageCode == kLao ? kShortMonthsLo : kShortMonthsEn;
  final String day = parsed.day.toString().padLeft(2, '0');
  return '$day ${months[parsed.month - 1]} ${parsed.year}';
}

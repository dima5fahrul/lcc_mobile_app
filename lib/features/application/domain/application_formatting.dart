/// The pure string transforms the application surfaces perform.
///
/// In `domain/` and importing nothing from Flutter, for the reason
/// `news_formatting.dart` and `home_formatting.dart` both give: these are
/// table lookups over a value and a language code, and
/// `presentation/widgets/` is inside GOR-246 AC-5's coverage **exclusion** set
/// — which is exactly where a month-index off-by-one would go unmeasured.
///
/// ## [formatApplicationDate] is the FOURTH copy of this transform
///
/// `formatDate` (`HistoryDetailPage.tsx:85-94`) joins `NewsPage.tsx:17-26`,
/// `NewsDetailPage.tsx:26-35` and `HomePage.tsx`'s. `news_formatting.dart`
/// already holds the Flutter port of the news pair.
///
/// **It differs from `news_formatting.formatNewsDate` in exactly one respect:
/// the absent-value sentinel is `"—"` here and `""` there.** Everything else —
/// the `en-GB`/`lo-LA` short-month tables, the `dd` zero-pad, the
/// return-the-input-verbatim-when-unparseable fallback — is identical.
///
/// The alternatives were weighed and rejected on `news_formatting.dart`'s own
/// grounds:
///
/// * **Import `features/news/domain/news_formatting.dart`.** CFI (`ssd.md`
///   § 4.3) and G-L3 both permit the `domain/` edge, so it is legal — and it
///   points a dependency the wrong way. `features/application/` is the tree's
///   shared-kernel feature for cases; making it depend on **news** to render a
///   date would make deleting or reshaping news an applications problem, for
///   four consumers.
/// * **Hoist it to `lib/core/`.** The right long-term home and out of B7a's
///   § 3.1 scope, which lists `lib/core/**` for `api_endpoint.dart` and
///   `dependency_injection.dart` only. Doing it here would be a
///   behaviour-frozen-adjacent edit smuggled inside a feature batch.
///
/// So: a copy, declared as one. **The duplication is not left to discipline.**
/// `test/features/application/domain/application_formatting_test.dart` asserts
/// that this function and `news_formatting.formatNewsDate` agree on **every**
/// non-empty input across a corpus covering all twelve months and both
/// locales, **and that they differ on the empty input** — so neither the
/// agreement nor the one deliberate difference can drift silently.
/// Consolidating the two into `lib/core/` is a follow-up (FU-10), not a thing
/// to do quietly inside a batch whose file list forbids it.
///
/// ## Timezone
///
/// `new Date(value).toLocaleDateString(...)` renders in the **device's local
/// zone**, not UTC — a `2026-12-31T23:59:00Z` timestamp reads `01 Jan 2027` at
/// UTC+7. `DateTime.parse` on a `Z`-suffixed string yields a UTC `DateTime`,
/// so this function calls [DateTime.toLocal] to reproduce that. Every test
/// that asserts a formatted date must therefore **pin a timezone** or it
/// passes in Vientiane and fails in CI (specs.md § 6.7, `B7-AC-79`).
///
/// ## B7b adds the second formatter and imports the third (§ 6.7)
///
/// [formatApplicationDateTime] is `formatDateTime`
/// (`HistoryDetailPage.tsx:96-104`) — the date above plus a **locale-invariant**
/// 24-hour `HH:MM`. § 6.7 names this file as its home, which is why it lands
/// here rather than in `features/history/`.
///
/// `formatLak` is **imported from `features/home/domain/home_formatting.dart`
/// and re-exported**, not copied. That is `wallet_formatting.dart:32-35`'s
/// ruling verbatim — G-L3 permits `features/A → features/B/domain/**`, the
/// money format already has two copies in this tree (`home_formatting.dart:50`
/// and `service_fee.dart:68`) and a third would be the one that drifts. Note
/// this is the **opposite** disposition from the date table above, and
/// deliberately so: there the alternative was a dependency on `features/news/`
/// for a table `application` could own outright, here `wallet` has already
/// pointed the identical arrow at `home` and `wallet_formatting.dart:29` names
/// B7 as a coming consumer.
library;

/// `formatLak(n, lang)` — `serviceConfig.ts:38-43`, re-exported.
///
/// `HistoryDetailPage.tsx:346`, `:407` and `:641` all render it, and `:641`'s
/// zero case is the one with a surprise in it: **`formatLak(0)` is `Free` /
/// `ຟຣີ`, not `0 LAK`** (`B7-AC-56`).
export '../../home/domain/home_formatting.dart' show formatLak, groupThousands;

/// `'lo'` selects Lao; anything else is English. Mirrors the source's
/// `lang === "lo" ? … : …` rather than an exhaustive switch it does not do.
///
/// Declared here rather than imported from `news_formatting.dart` so this file
/// has **no** `features/news/**` import at all — see the library doc. The edge
/// would be CFI-legal and would still point the wrong way.
const String kLaoCode = 'lo';

/// `en-GB` short month names as CLDR resolves `{ month: "short" }`.
///
/// Note **`Sept`** — four characters, en-GB's abbreviation, not `Sep`.
/// Measured from a live ICU probe rather than inferred (specs.md § 6.7).
///
/// This is declared as its own constant, and asserted equal to
/// `news_formatting.kNewsShortMonthsEn` **by test** rather than aliased to it,
/// for the same reason the function is a copy: `features/application/` does
/// not depend on `features/news/`. The test imports both and compares them
/// element by element, so the tables cannot drift either.
const List<String> kApplicationShortMonthsEn = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec',
];

/// `lo-LA` short month names, as CLDR resolves `{ month: "short" }`.
const List<String> kApplicationShortMonthsLo = <String>[
  'ມ.ກ.', 'ກ.ພ.', 'ມ.ນ.', 'ມ.ສ.', 'ພ.ພ.', 'ມິ.ຖ.', //
  'ກ.ລ.', 'ສ.ຫ.', 'ກ.ຍ.', 'ຕ.ລ.', 'ພ.ຈ.', 'ທ.ວ.',
];

/// The absent-value sentinel — `if (!value) return "—"`,
/// `HistoryDetailPage.tsx:86`. **This is the single character that
/// distinguishes this formatter from news'**, which returns `""`.
const String kAbsentDate = '—';

/// `formatDate(value, lang)` — `HistoryDetailPage.tsx:85-94`.
///
/// `"2026-08-14T14:05:00Z"` → `"14 Aug 2026"` / `"14 ສ.ຫ. 2026"` at UTC+7.
///
/// Three behaviours, all the source's:
/// * absent/empty → [kAbsentDate] (`"—"`), **not** `""`.
/// * unparseable → the input **verbatim**
///   (`Number.isNaN(d.getTime()) → return value`). A malformed date must print
///   as itself rather than blank the row.
/// * otherwise `dd MMM yyyy` in the reader's locale, in the **local** zone.
String formatApplicationDate(String? value, String languageCode) {
  if (value == null || value.isEmpty) return kAbsentDate;

  final DateTime? parsed = DateTime.tryParse(value);
  if (parsed == null) return value;

  final DateTime local = parsed.toLocal();
  final List<String> months = languageCode == kLaoCode
      ? kApplicationShortMonthsLo
      : kApplicationShortMonthsEn;
  final String day = local.day.toString().padLeft(2, '0');
  return '$day ${months[local.month - 1]} ${local.year}';
}

/// `formatDateTime(value, lang)` — `HistoryDetailPage.tsx:96-104`.
///
/// ```ts
/// return `${formatDate(value, lang)}, ${d.toLocaleTimeString(
///   lang === "lo" ? "lo-LA" : "en-GB", { hour: "2-digit", minute: "2-digit" })}`;
/// ```
///
/// `"2026-08-14T14:05:00Z"` → `"14 Aug 2026, 21:05"` / `"14 ສ.ຫ. 2026, 21:05"`
/// at UTC+7.
///
/// ## The time part is LOCALE-INVARIANT, and that is a measurement
///
/// specs.md § 6.7 probed ICU live rather than inferring: `{hour: "2-digit",
/// minute: "2-digit"}` resolves to the same zero-padded 24-hour `HH:MM` under
/// both `en-GB` and `lo-LA`. There is therefore **no Lao time table here, and
/// an AC that "verified" one would be verifying nothing** (`B7-AC-79`). Only
/// the month name differs between the two renders, and that difference lives in
/// [formatApplicationDate].
///
/// The two fallbacks are the date formatter's, reached the same way and for the
/// same reason — absent → `"—"`, unparseable → the input **verbatim**
/// (`:97-99`, `B7-AC-78`). They are re-derived here rather than delegated
/// because the source re-derives them: `formatDateTime`'s guards run *before*
/// it calls `formatDate`, so an unparseable input returns the raw value with no
/// `", HH:MM"` appended.
///
/// Local zone, like the date — see the library doc's timezone note. A test that
/// asserts a time without pinning `TZ` passes in Vientiane and fails in CI.
String formatApplicationDateTime(String? value, String languageCode) {
  if (value == null || value.isEmpty) return kAbsentDate;

  final DateTime? parsed = DateTime.tryParse(value);
  if (parsed == null) return value;

  final DateTime local = parsed.toLocal();
  final String hour = local.hour.toString().padLeft(2, '0');
  final String minute = local.minute.toString().padLeft(2, '0');
  return '${formatApplicationDate(value, languageCode)}, $hour:$minute';
}

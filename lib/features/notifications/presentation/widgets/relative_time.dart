/// `relativeTime` — *"3 minutes ago" in the reader's language, from an ISO
/// timestamp.*
///
/// Port of `Layout.tsx:72-94`, behaviour for behaviour.
///
/// ## Why this is hand-written
///
/// The source calls `new Intl.RelativeTimeFormat(locale, {numeric: "auto"})`.
/// Dart's `intl` has **no** `RelativeTimeFormat` — `timeago` and its
/// equivalents are rejected by specs.md § 4.3 (B9 adds zero dependencies, and
/// `timeago`'s phrasing is its own, not CLDR's). So the mapping is written out,
/// and every value below was **measured**, not recalled:
///
/// ```
/// node -e "const r=new Intl.RelativeTimeFormat('lo-LA',{numeric:'auto'});
///          console.log(r.format(-2,'day'))"
/// ```
///
/// run against the same Node/ICU the port source is built with.
///
/// ## `numeric: "auto"` is the whole reason this file is not four lines
///
/// "auto" is what produces *"yesterday"* instead of *"1 day ago"*. The measured
/// surprise — and it is the one a careful implementer gets wrong — is that
/// **English and Lao do not have the same auto forms**:
///
/// | unit | en-GB auto at | lo-LA auto at |
/// |---|---|---|
/// | year / month / week | ±1 | ±1 |
/// | day | ±1 | **±1 and ±2** |
/// | hour / minute | none | none |
///
/// Lao names the day before yesterday (`ມື້ກ່ອນ`) and the day after tomorrow
/// (`ມື້ຮື`) as single words; English does not. A port that handled ±1 in both
/// locales — the obvious reading of "auto" — would render `2 ມື້ກ່ອນ` where the
/// web renders `ມື້ກ່ອນ`, in the language most of this app's citizens read, and
/// no fidelity tier below Tier 1 could see it. Hence B9-AC-39's requirement
/// that the auto forms be **asserted individually per locale** rather than
/// assumed.
///
/// The zero cases (`"today"`, `"this hour"`) are in CLDR but are unreachable
/// here: `|seconds| < 60` short-circuits to `notifJustNow` before the step
/// table runs, and every later step is entered only when `|seconds| >= size`,
/// which makes `|round(seconds / size)| >= 1`. They are omitted rather than
/// written and left dead.
library;

import '../../../../i18n/i18n.dart';

/// One row of `Layout.tsx:82-89`'s `steps` table: a unit and its size in
/// seconds. Order is load-bearing — the first match wins.
typedef _Step = ({String unit, int size});

const List<_Step> _steps = <_Step>[
  (unit: 'year', size: 31536000),
  (unit: 'month', size: 2592000),
  (unit: 'week', size: 604800),
  (unit: 'day', size: 86400),
  (unit: 'hour', size: 3600),
  (unit: 'minute', size: 60),
];

/// The `numeric: "auto"` special forms, `'<unit>:<signed n>'` → phrase.
///
/// Measured from ICU, not transcribed from a style guide. Everything absent
/// from this table falls through to the numeric template, which is exactly what
/// `Intl.RelativeTimeFormat` does.
const Map<String, String> _autoEn = <String, String>{
  'year:-1': 'last year',
  'year:1': 'next year',
  'month:-1': 'last month',
  'month:1': 'next month',
  'week:-1': 'last week',
  'week:1': 'next week',
  'day:-1': 'yesterday',
  'day:1': 'tomorrow',
};

const Map<String, String> _autoLo = <String, String>{
  'year:-1': 'ປີກາຍ',
  'year:1': 'ປີໜ້າ',
  'month:-1': 'ເດືອນແລ້ວ',
  'month:1': 'ເດືອນໜ້າ',
  'week:-1': 'ອາທິດແລ້ວ',
  'week:1': 'ອາທິດໜ້າ',
  'day:-1': 'ມື້ວານ',
  'day:1': 'ມື້ອື່ນ',
  // The two English has no word for.
  'day:-2': 'ມື້ກ່ອນ',
  'day:2': 'ມື້ຮື',
};

/// The unit noun the numeric template interpolates. English pluralises on
/// `|n| != 1`; Lao has no plural form, which is why the two are separate tables
/// rather than one with a suffix rule.
const Map<String, String> _unitEn = <String, String>{
  'year': 'year',
  'month': 'month',
  'week': 'week',
  'day': 'day',
  'hour': 'hour',
  'minute': 'minute',
};

const Map<String, String> _unitLo = <String, String>{
  'year': 'ປີ',
  'month': 'ເດືອນ',
  'week': 'ອາທິດ',
  'day': 'ມື້',
  'hour': 'ຊົ່ວໂມງ',
  'minute': 'ນາທີ',
};

/// `rtf.format(n, unit)` with `numeric: "always"` — the fall-through.
///
/// en-GB: `2 days ago` / `in 2 days`, singular at `|n| == 1`.
/// lo-LA: `2 ມື້ກ່ອນ` / `ໃນອີກ 2 ມື້`.
String _numeric(int n, String unit, Lang lang) {
  final bool past = n < 0;
  final int magnitude = n.abs();

  if (lang == Lang.lo) {
    // One space, after the number only: `5 ປີກ່ອນ`, not `5 ປີ ກ່ອນ`.
    //
    // The past form is assembled in two steps rather than written as
    // `'$magnitude ${noun}ກ່ອນ'`. Lao script is outside Dart's identifier set,
    // so the interpolation would terminate at the noun anyway and the braces
    // are flagged as unnecessary — but `'$magnitude $nounກ່ອນ'` puts the
    // variable name and the suffix in one unbroken run of glyphs, which is
    // exactly the kind of line a reader mis-parses.
    final String noun = _unitLo[unit]!;
    const String ago = 'ກ່ອນ';
    return past ? '$magnitude $noun$ago' : 'ໃນອີກ $magnitude $noun';
  }

  final String noun = _unitEn[unit]! + (magnitude == 1 ? '' : 's');
  return past ? '$magnitude $noun ago' : 'in $magnitude $noun';
}

/// `Intl.RelativeTimeFormat(locale, {numeric: "auto"}).format(n, unit)`.
String _format(int n, String unit, Lang lang) {
  final Map<String, String> table = lang == Lang.lo ? _autoLo : _autoEn;
  return table['$unit:$n'] ?? _numeric(n, unit, lang);
}

/// `relativeTime(iso, lang, justNow)` — `Layout.tsx:73-94`.
///
/// [justNow] is the already-translated `layout.notifJustNow` string, passed in
/// exactly as the source passes `t("notifJustNow")` (`:272`). It is a parameter
/// rather than a `.tr()` call inside so this function stays pure and unit
/// testable with no `EasyLocalization` in the tree.
///
/// [now] is injectable for the same reason: the source reads `Date.now()`
/// (`:77`), and a test that cannot pin the clock cannot assert a boundary.
/// Production call sites omit it.
///
/// **Returns `""` for a missing OR unparseable timestamp** (`:74`, `:76`), and
/// this is load-bearing rather than defensive: JavaScript's
/// `new Date("nonsense").getTime()` is `NaN` and the component renders an empty
/// line, where Dart's `DateTime.parse` **throws**. An uncaught `FormatException`
/// inside a notification row would be a crash the source does not have
/// (specs.md § 6.13, B9-AC-39). `DateTime.tryParse` closes that, completely:
/// there is no input for which this function throws.
///
/// ## A residual divergence, measured, bounded and NOT papered over
///
/// § 6.13 anticipated one direction — Dart throwing where JS yields `NaN`. It
/// is wider than that in both directions, and neither half is reachable from a
/// conformant backend. Measured, `DateTime.tryParse` vs `new Date(…)`:
///
/// | Input | JS | Dart |
/// |---|---|---|
/// | `not-a-timestamp`, `???`, `ມື້ວານ`, `""` | `NaN` → `""` | `null` → `""` |
/// | `2026-08-13T23:50:00.000Z`, `2026-08-13` | parses | parses, same instant |
/// | `2026-02-30` | rolls to Mar 2 | rolls to Mar 2 |
/// | `2026-13-45T99:99:99Z` | `NaN` → `""` | **rolls to 2027-02-18** |
/// | `2026-08-13T25:00:00Z` | `NaN` → `""` | **rolls to Aug 14 01:00** |
/// | `2026-8-3` (unpadded) | parses, legacy fallback | **`null` → `""`** |
///
/// So Dart is *more* tolerant of out-of-range components and *less* tolerant of
/// unpadded ones. Both cases require a backend emitting something that is not
/// ISO-8601, and `types.ts` types every `sent_at` as an ISO timestamp.
///
/// **Not "fixed" here, and that is a decision.** Closing it means either a
/// hand-written range validator — which would catch the out-of-range half and
/// not the unpadded half, looking complete while being partial — or a full
/// second date parser, which is a bug surface of its own for an input no
/// observed payload produces. The boundary is instead **asserted** in
/// `relative_time_test.dart`, so a future change to the parser reports what it
/// changed instead of moving the line silently. Reported as a measured finding
/// rather than absorbed into a PASS.
String relativeTime(
  String? iso,
  Lang lang,
  String justNow, {
  DateTime? now,
}) {
  if (iso == null || iso.isEmpty) return '';

  final DateTime? then = DateTime.tryParse(iso);
  if (then == null) return '';

  final DateTime reference = now ?? DateTime.now();

  // `Math.round((then - Date.now()) / 1000)` — `:77`. Dart's `round()` on a
  // negative half rounds away from zero where JavaScript's `Math.round` rounds
  // toward +∞; at second resolution over a step table whose smallest bucket is
  // 60 s, the two can only differ for a value already inside the `< 60`
  // short-circuit below, so the distinction cannot reach the output.
  final int seconds =
      ((then.millisecondsSinceEpoch - reference.millisecondsSinceEpoch) / 1000)
          .round();

  if (seconds.abs() < 60) return justNow;

  for (final _Step step in _steps) {
    if (seconds.abs() >= step.size) {
      return _format((seconds / step.size).round(), step.unit, lang);
    }
  }

  // `:93` — unreachable given the `< 60` guard above and the 60 s final step,
  // and present because the source has it.
  return justNow;
}

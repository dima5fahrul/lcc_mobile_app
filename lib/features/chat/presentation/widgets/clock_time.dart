/// `clockTime` — the message-bubble timestamp.
///
/// `CustomerServiceChat.tsx:20-25`:
///
/// ```ts
/// function clockTime(value: string | undefined): string {
///   if (!value) return "";
///   const d = new Date(value);
///   if (Number.isNaN(d.getTime())) return "";
///   return d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
/// }
/// ```
///
/// ## The two empty-string guards are load-bearing
///
/// specs.md § 6.13 states why, and it is the difference between a quiet bubble
/// and a crash: a Dart `DateTime.parse` on a malformed string **throws** where
/// JavaScript's `new Date` yields `NaN` and the component renders `""`. An
/// uncaught `FormatException` inside a chat bubble is a failure mode the source
/// does not have, and the transcript is server-supplied. [chatClockTime] uses
/// `tryParse` for exactly that reason and B9-AC-39's chat half asserts it.
///
/// ## `tryParse` is NOT sufficient on its own, and § 6.13 does not say so
///
/// **Measured, and it corrects a premise in the spec.** § 6.13 frames the whole
/// difficulty as "Dart throws where JS yields `NaN`", so `tryParse` looks like
/// the complete answer. It is not: Dart's ISO parser **rolls out-of-range
/// components over** where ECMAScript's rejects them outright.
///
/// ```
/// new Date("2026-13-45T99:99:99")   -> Invalid Date  -> clockTime = ""
/// DateTime.parse("2026-13-45T99:99:99") -> 2027-02-18 04:40:39  -> "04:40"
///
/// new Date("2026-02-30T10:00:00Z")  -> Invalid Date  -> clockTime = ""
/// DateTime.parse("2026-02-30T10:00:00Z") -> 2026-03-02 10:00Z   -> "10:00"
/// ```
///
/// A `tryParse`-only port therefore prints a plausible, wrong time for a
/// malformed timestamp where the source prints nothing — quieter than a crash
/// and harder to notice. [_componentsSurvivedParsing] closes it by checking
/// that the calendar fields in the string are the ones that came back out.
///
/// ## Two measured divergences from `toLocaleTimeString`, both recorded
///
/// Recorded in `test/features/chat/fidelity/b9_divergences.yaml` rather than
/// absorbed, because neither is visible to any tier:
///
/// 1. **Locale.** The source passes `[]` — the *host* locale, whatever the
///    device is set to — where every other formatter in this app is explicit
///    (`Layout.tsx:73` pins `lo-LA` / `en-GB` for `relativeTime`). This port
///    renders a fixed zero-padded 24-hour `HH:mm`, which is what **both** of
///    the app's two locales resolve to for
///    `{hour: "2-digit", minute: "2-digit"}` — `en-GB` and `lo-LA` are both
///    24-hour. A device set to `en-US` would render `02:05 PM` on the web and
///    `14:05` here. Reproducing the host-locale read would make the Tier 1
///    oracle a function of the machine running the test, which is a worse
///    trade than a bounded, stated divergence.
/// 2. **Date-only strings.** `new Date("2026-08-13")` is parsed as **UTC** by
///    ECMAScript's date-only form, where `DateTime.parse('2026-08-13')` is
///    local. The wire sends full ISO timestamps (`types.ts:744`, `sent_at`), so
///    no observed payload reaches this path; it is stated because a reader
///    checking the guard should know which input it does not cover.
///
/// Date-**time** strings agree: both languages treat a form with no `Z` and no
/// offset as local, and both honour an explicit `Z`.
library;

/// `clockTime(value)` — `HH:mm` in local time, or `''`.
///
/// `''` for a null value, for an empty value, and for anything
/// `DateTime.tryParse` cannot read. **Never throws.**
String chatClockTime(String? value) {
  if (value == null || value.isEmpty) return '';

  // `Number.isNaN(d.getTime())` — `:22`. `tryParse` is the non-throwing form
  // and the whole reason this is a function rather than an inline `DateFormat`.
  final DateTime? parsed = DateTime.tryParse(value);
  if (parsed == null) return '';

  // …and the half `tryParse` does not cover. See the library doc.
  if (!_componentsSurvivedParsing(value, parsed)) return '';

  // `toLocaleTimeString` renders in the host's zone; `toLocal()` is that. A
  // timestamp with no zone marker is already local on both sides, so this is
  // the identity for the fixtures and the conversion for a `Z` payload.
  final DateTime local = parsed.toLocal();

  // `{hour: "2-digit", minute: "2-digit"}` — zero-padded, both fields.
  // Hand-formatted rather than `DateFormat.Hm(locale)`: `intl`'s date symbols
  // are not initialised for `lo` in this app, and `Hm` would silently fall back
  // to `en_US`'s pattern for the Lao locale — a locale-dependent format bug
  // hiding behind a locale-aware API.
  final String hh = local.hour.toString().padLeft(2, '0');
  final String mm = local.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

/// Whether the calendar fields written in [value] are the ones [parsed] came
/// back with.
///
/// The rollover check. `DateTime.parse('2026-02-30…')` answers March 2nd
/// rather than refusing, so the only way to tell a real date from a rolled-over
/// one is to compare what went in against what came out.
///
/// [parsed] is compared **before** any `toLocal()`: for a `Z` or offset form
/// `DateTime.parse` returns a UTC instant whose own fields are the ones written
/// in the string, so the comparison is like for like. Converting first would
/// make every timestamp outside UTC fail this check.
///
/// A string with no recognisable `YYYY-MM-DD` prefix is **accepted** — Dart's
/// `tryParse` already rejected everything this function could usefully judge,
/// and inventing a stricter grammar here would reject forms the wire does not
/// send and the source would have rendered.
bool _componentsSurvivedParsing(String value, DateTime parsed) {
  final RegExpMatch? date = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})',
  ).firstMatch(value);
  if (date == null) return true;

  if (parsed.year != int.parse(date.group(1)!) ||
      parsed.month != int.parse(date.group(2)!) ||
      parsed.day != int.parse(date.group(3)!)) {
    return false;
  }

  final RegExpMatch? time = RegExp(
    r'^\d{4}-\d{2}-\d{2}[T ](\d{2}):(\d{2})',
  ).firstMatch(value);
  if (time == null) return true;

  return parsed.hour == int.parse(time.group(1)!) &&
      parsed.minute == int.parse(time.group(2)!);
}

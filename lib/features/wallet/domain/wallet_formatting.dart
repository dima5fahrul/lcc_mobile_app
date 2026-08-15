/// The wallet's own pure transforms: [formatKip], [formatDay], [daysUntil] and
/// [parseTopUpAmount].
///
/// **[daysUntil] was added by B6b**, and the split is a spec artefact worth
/// naming rather than hiding: specs.md § 3.1's **B6a** row for this file lists
/// *"`formatKip`, `formatDay`, `daysUntil`"*, while `B6-AC-21` — the criterion
/// that gates `daysUntil`'s `ceil` semantics and its injected clock — is tagged
/// **B6b**, because the Bills Due card is its only caller and that card is
/// B6b's. B6a shipped the two formatters its own surfaces needed and left the
/// third; B6b, the consumer, lands it under the criterion that gates it. The
/// file is not in B6b's § 3.1 table, so this is a recorded scope deviation, not
/// a licence — see the hand-back report.
///
/// In `domain/` for the reason `home_formatting.dart:1-9` argues: they are
/// arithmetic and table lookups over a value and a language code, and putting
/// them under `presentation/widgets/` would put them inside the coverage
/// **exclusion** set — which is exactly where the boundary bugs live. It also
/// makes them the *only* place the wallet's Lao grouping is testable, since
/// `balance_lak 0` on the one test account means no rendered surface can ever
/// show a grouped number (specs.md § 6.12's account-limit register).
///
/// ## What this file imports rather than redefines
///
/// [groupThousands], [formatLak], [kShortMonthsEn], [kShortMonthsLo] and [kLao]
/// come from `features/home/domain/home_formatting.dart`. That is legal —
/// G-L3 permits `features/A → features/B/domain/**` — and it is the ruling of
/// specs.md § 6.6, taken over both copying and relocating:
///
/// * **Copying** would be two `formatLak`s that drift. SSD § 4.3's
///   *"wire-format duplication is the accepted cost"* clause is about
///   `@JsonKey` knowledge, not about arithmetic.
/// * **Relocating** would touch `features/home/{domain,presentation}` (6
///   files), `features/news/domain/news_formatting.dart` and two test files,
///   all outside § 3.1 — and it is not obvious the destination is
///   `features/wallet/domain/` rather than a new shared home. **FU-9** files
///   the question; B6 does not answer it under time pressure.
///
/// Money formatting living in `features/home/domain/` is a placement accident
/// of B2b, not a decision. B5, B6, B7 and F1-F4 all need it.
library;

import '../../home/domain/home_formatting.dart';

export '../../home/domain/home_formatting.dart'
    show formatLak, groupThousands, kLao;

/// **U+20AD KIP SIGN.** Named so the code point is asserted once, by value,
/// rather than eyeballed at nine call sites (`B6-AC-18`).
///
/// It is not `₭`-lookalike U+04A9 (ҩ), not `K`. `WalletPage.tsx:64` writes the
/// real glyph and a Tier 1 comparison is byte-exact.
const String kKipSign = '₭';

/// **`formatKip(amount, lang)` — `WalletPage.tsx:62-65`. NOT [formatLak]. NOT
/// [groupThousands].**
///
/// ```
/// `${amount < 0 ? "-" : ""}${Math.abs(amount).toLocaleString(
///     lang === "lo" ? "lo-LA" : "en-US")} ₭`
/// ```
///
/// ## The grouping separator is LOCALE-DEPENDENT, and that is the trap
///
/// [formatLak] pins `en-US` in **both** locales, and `home_formatting.dart:20-27`
/// documents why in a comment that is correct *for `formatLak`* and wrong if
/// carried across:
///
/// > *"Lao renders Arabic numerals with comma grouping, and switching to a
/// > locale-aware grouper would produce a different string from the web…"*
///
/// `formatKip` does not pin anything — it passes `lo-LA` through. Measured on
/// a full-ICU runtime (`node`, ICU 78.3, the same build that renders `ສ.ຫ.`
/// for August, so the ICU data is real):
///
/// ```
///      1000  lo-LA "1.000"       en-US "1,000"
///     20000  lo-LA "20.000"      en-US "20,000"
///   1234567  lo-LA "1.234.567"   en-US "1,234,567"
///  50000000  lo-LA "50.000.000"  en-US "50,000,000"
/// ```
///
/// **Dots.** An implementer who reuses [groupThousands] here ships `20,000 ₭`
/// where the web shows `20.000 ₭`, in Lao, on the largest number on the
/// screen — and **no Tier 3 image can catch it**, because the only wallet
/// reference that exists (slot `04-wallet`) has a balance of zero.
/// `B6-AC-16` and `B6-AC-17` gate exactly that.
///
/// Also measured, because it is the way a locale-aware grouper usually differs
/// and it would have been the wrong fix: `lo-LA` has **no minimum-grouping-digits
/// quirk**. `1000` groups (`"1.000"`), `999` does not (`"999"`). Same threshold
/// as `en-US`, so only the separator character differs.
///
/// ## The sign is applied outside the grouping
///
/// `Math.abs` first, `"-"` prefixed to the result. Ported structurally, not as
/// `value.toString()` on a negative, so a negative can never pick up a
/// locale's own minus glyph.
///
/// | Input | `en` | `lo` |
/// |---|---|---|
/// | `0` | `0 ₭` | `0 ₭` |
/// | `500` | `500 ₭` | `500 ₭` |
/// | `20000` | `20,000 ₭` | `20.000 ₭` |
/// | `1234567` | `1,234,567 ₭` | `1.234.567 ₭` |
/// | `-5000` | `-5,000 ₭` | `-5.000 ₭` |
String formatKip(int amount, String languageCode) {
  final String sign = amount < 0 ? '-' : '';
  final int magnitude = amount.abs();

  // `groupThousands` is the `en-US` grouper and is used ONLY here (`B6-AC-17`).
  // Its own sign handling never fires: it is fed an absolute value.
  final String grouped = languageCode == kLao
      ? _groupThousandsLao(magnitude)
      : groupThousands(magnitude);

  return '$sign$grouped $kKipSign';
}

/// `toLocaleString('lo-LA')` for a non-negative integer — identical digit
/// grouping to [groupThousands], separated by `.` instead of `,`.
///
/// Written out rather than `groupThousands(v).replaceAll(',', '.')` so the two
/// groupers are independently readable and neither can be "simplified" into the
/// other by someone who has not read [formatKip]'s doc.
String _groupThousandsLao(int value) {
  final String digits = value.toString();
  final StringBuffer out = StringBuffer();

  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
    out.write(digits[i]);
  }

  return out.toString();
}

/// **`formatDay(value, lang)` — `WalletPage.tsx:67-76`.**
///
/// Identical construction to `home_formatting.dart`'s `formatDate` **except the
/// absent-value branch**, and the one character is the whole reason this is not
/// a call to that:
///
/// * `formatDay(null)` / `formatDay('')` → **`"—"`** (U+2014 EM DASH) —
///   `WalletPage.tsx:68`, `if (!value) return "—";`
/// * `formatDate(null)` / `formatDate('')` → `""` — `home_formatting.dart:167`
///
/// A ledger row printing `06 Aug 2026 · 20,000 ₭` would print ` · 20,000 ₭`
/// with a leading gap if the em dash were dropped.
///
/// Unparseable input returns the input **verbatim**, which both functions share
/// (`Number.isNaN(d.getTime()) → return value`).
///
/// The month tables are imported, not re-transcribed. `kShortMonthsLo` index 7
/// was independently re-verified for this batch — full-ICU `node` renders
/// `2026-08-06` as `06 ສ.ຫ. 2026` under `lo-LA` with
/// `{day: "2-digit", month: "short", year: "numeric"}`, and `06 Aug 2026`
/// under `en-GB`. Note the source uses **`en-GB`**, not `en-US`, for this one
/// (`:71`) — which is why `kShortMonthsEn` carries the four-character `Sept`.
String formatDay(String? value, String languageCode) {
  if (value == null || value.isEmpty) return '—';

  final DateTime? parsed = DateTime.tryParse(value);
  if (parsed == null) return value;

  final List<String> months = languageCode == kLao
      ? kShortMonthsLo
      : kShortMonthsEn;
  final String day = parsed.day.toString().padLeft(2, '0');
  return '$day ${months[parsed.month - 1]} ${parsed.year}';
}

/// **`daysUntil(value)` — `WalletPage.tsx:78-84`.** Whole days from now until
/// [value]; negative once the date has passed, `null` when there is no date.
///
/// ```ts
/// function daysUntil(value: string | undefined): number | null {
///   if (!value) return null;
///   const due = new Date(value).getTime();
///   if (Number.isNaN(due)) return null;
///   return Math.ceil((due - Date.now()) / 86_400_000);
/// }
/// ```
///
/// ## `ceil`, and it is the whole behaviour (`B6-AC-21`)
///
/// A bill due in **thirty minutes** is `1`, not `0` — `Math.ceil(0.0208…)`. It
/// reads as "due today" rather than "due now", and every chip in the Bills Due
/// card is keyed off it: `overdue` when negative, amber when `<= 3`, grey
/// otherwise (`:334-343`). A `truncate()` or a `round()` port would move the
/// overdue boundary by up to a day on a surface that tells a citizen a fee is
/// late.
///
/// `Math.ceil` and Dart's `double.ceil()` both round toward **+∞**, so they
/// agree on negatives too: `-1.5` → `-1` in both. A bill 30 minutes *past* due
/// is `0`, not `-1` — still not overdue by this number alone, which is why
/// `:333` ORs it with the server's own `is_overdue` flag rather than trusting
/// the arithmetic.
///
/// ## The clock is a parameter, and that is a testability requirement
///
/// `B6-AC-21` requires it: *"The clock is injected — no test reads
/// `DateTime.now()` directly."* A test that computed its own expectation from
/// `DateTime.now()` would be asserting the implementation against itself and
/// would pass with the `ceil` replaced by anything monotonic. [now] defaults to
/// the real clock so no call site has to thread one.
///
/// ## Timezone
///
/// `new Date(value).getTime()` and `DateTime.parse(…).millisecondsSinceEpoch`
/// are both absolute instants, so the subtraction is timezone-free. The port
/// therefore does **not** normalise to local midnight — neither does the
/// source, and doing so would change `daysUntil` for every citizen east of
/// UTC+7's date line at exactly the times a due date matters most.
int? daysUntil(String? value, {DateTime? now}) {
  if (value == null || value.isEmpty) return null;

  final DateTime? due = DateTime.tryParse(value);
  if (due == null) return null;

  final DateTime clock = now ?? DateTime.now();
  final int deltaMs = due.millisecondsSinceEpoch - clock.millisecondsSinceEpoch;

  // `86_400_000` — the source's own literal, one day in milliseconds.
  return (deltaMs / 86400000).ceil();
}

/// **`Number(amount.replace(/[^\d]/g, "")) || 0` — `WalletPage.tsx:735`.**
///
/// The integer that goes into the top-up body, from the text the citizen typed.
/// Three transforms, and porting only the first two is the defect Tier 0 exists
/// to catch (`B6-AC-34`):
///
/// 1. **Strip every non-digit.** `"12a3"` → `"123"`, not a parse failure.
/// 2. **Coerce.** `Number("0050000")` → `50000`; leading zeros are not octal
///    and not an error.
/// 3. **`|| 0`.** `Number("")` is `0`, and `NaN` is falsy, so `""` and `"abc"`
///    both land on `0` rather than on null.
///
/// A naive `int.tryParse(raw)` gets `"12a3"` **wrong** — it answers `null`,
/// where the web answers `123`. That is a different amount of money, silently,
/// from the same keystrokes.
///
/// | Input | Result |
/// |---|---|
/// | `"12a3"` | `123` |
/// | `""` | `0` |
/// | `"abc"` | `0` |
/// | `"0050000"` | `50000` |
/// | `"50,000"` | `50000` |
/// | `"-500"` | `500` — the minus is not a digit, so it is stripped. The web does the same; there is no negative top-up. |
///
/// **Beyond the source's reachable range**, a digit string too long for a
/// 64-bit `int` yields `0` rather than a wrapped or thrown value. JS would
/// produce an imprecise `double` there. Unreachable in practice — the field is
/// bounded by `max_top_up_lak` (50,000,000 by default) and the guard runs
/// before the request is built (`B6-AC-35`, security item 9) — and `0` fails
/// that guard, which is the safe direction for a money field.
int parseTopUpAmount(String raw) {
  final String digits = raw.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.isEmpty) return 0;
  return int.tryParse(digits) ?? 0;
}

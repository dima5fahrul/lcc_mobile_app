/// The one date-time on the verification surface, read on the calendar the
/// spec judges by — **review M-7, 2026-10-22**.
///
/// MOBILE-API-E-CERTIFICATES.md § Authentication and conventions splits the
/// wire's two temporal shapes, and they are not interchangeable:
///
/// | Topic | Rule |
/// | --- | --- |
/// | Dates | `YYYY-MM-DD` (ISO 8601). **Validity is judged on the Vientiane calendar (UTC+7).** |
/// | Date-times | RFC 3339 with offset, e.g. `2026-09-30T10:42:18+07:00`. |
///
/// `issued_at` and `valid_until` are plain dates: they carry no offset, no
/// instant, and nothing to convert — `formatDate` renders them as written and
/// must keep doing so. `revoked_at` is the date-**time**, and that is where the
/// defect was: `DateTime.parse('2026-10-22T00:30:00+07:00')` yields a `DateTime`
/// whose `isUtc` is true and whose `.day` is **21**, because parsing an offset
/// normalises to UTC. A revocation at half past midnight in Vientiane therefore
/// rendered as the previous day — on the one screen whose entire job is telling
/// somebody whether to accept a document.
///
/// So the instant is moved onto the Vientiane calendar before the date is read
/// off it, and the result is handed to the app's shared `formatDate` so the
/// month tables and both locales stay in one place.
library;

/// A `Z` or a `±HH:MM` / `±HHMM` suffix — the thing that makes a value an
/// *instant* rather than a calendar date.
final RegExp _kOffset = RegExp(r'(?:Z|z|[+-]\d{2}:?\d{2})$');

/// A time component at all: `T10:42` or the RFC 3339-permitted space form.
final RegExp _kHasTime = RegExp(r'[Tt ]\d{2}:\d{2}');

/// [value] as the `YYYY-MM-DD` it falls on in Vientiane (UTC+7).
///
/// Three inputs, three answers, and the distinction is the point:
///
/// 1. **An offset-bearing date-time** (`2026-10-22T00:30:00+07:00`,
///    `2026-10-21T17:30:00Z`) → shifted to UTC+7 and reduced to its date:
///    `2026-10-22` for both, because they are the same instant.
/// 2. **A plain date** (`2026-09-30`) → returned unchanged. There is no instant
///    to shift and no offset to honour; shifting it would invent one.
/// 3. **A naive date-time, no offset** (`2026-09-30T10:42:18`) → returned
///    unchanged. `DateTime.parse` would read it in the *device's* zone, so
///    shifting would make the rendered day depend on where the phone is, which
///    is worse than trusting the server's own wall clock. The spec says every
///    date-time carries an offset; this branch is for the server that forgets.
///
/// An unparseable value comes back verbatim, which is `formatDate`'s own
/// contract for the same case — this function never swallows a string the
/// screen would otherwise show.
String vientianeCalendarDate(String value) {
  if (value.isEmpty) return value;
  if (!_kHasTime.hasMatch(value) || !_kOffset.hasMatch(value)) return value;

  final DateTime? parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  // **No `toUtc()`, and not for style:** `layering_test.dart`'s ADR-0005 O-4
  // forbids the call anywhere in `lib/**`, because the web dates every
  // submission with `new Date().toISOString()` and that UTC read is the one
  // defect this port deliberately diverges from. It is also unnecessary here:
  // `DateTime.parse` of a string carrying `Z` or an offset returns a DateTime
  // that **is already UTC** (`isUtc == true`), and `_kOffset` above is what
  // guarantees we only reach this line for such a string. The `isUtc` check
  // is the belt: if that documented property ever stopped holding, this
  // returns the value verbatim rather than shifting by a device-local
  // interpretation.
  if (!parsed.isUtc) return value;

  final DateTime vientiane = parsed.add(const Duration(hours: 7));
  final String month = vientiane.month.toString().padLeft(2, '0');
  final String day = vientiane.day.toString().padLeft(2, '0');
  return '${vientiane.year.toString().padLeft(4, '0')}-$month-$day';
}

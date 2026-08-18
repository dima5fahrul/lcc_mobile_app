/// Two pure helpers Marriage and Divorce declare **byte-identically**, held
/// once — `specs.md` § 6.2 RULING 1, option (c).
///
/// `MarriageCertificatePage.tsx:681-693` · `DivorceCertificatePage.tsx:587-599`.
/// Finding K measured both spans as byte-identical text.
///
/// ## Why these are here and `spousePayload` is NOT
///
/// These two take their inputs as arguments and know nothing about either
/// page's shape. `spousePayload` knows 13 keys on Marriage and 8 on Divorce,
/// and one of them is renamed (`residence_certificate_ref` ->
/// `marriage_certificate_ref`). § 6.5 forbids sharing it, for the reason
/// Birth and Death may not share `parentData`, and
/// `tier0_payload_equality_test.dart:541-563` already asserts the delta. A
/// shared helper would be correct for most keys and silently wrong for the
/// rest.
///
/// ## `today()` is the eleventh helper and is deliberately absent
///
/// `MarriageCertificatePage.tsx:678` / `DivorceCertificatePage.tsx:584` are
/// also byte-identical — `new Date().toISOString().slice(0, 10)`, i.e. **UTC**.
/// `ADR-0005` disposes it FIX: one injected `SubmissionClock` reading LOCAL
/// time. Porting a `today()` into this file would reintroduce the ambient
/// clock read the ADR removed, so the eleventh duplicated helper is discharged
/// by `SubmissionClock`, not transcribed here. Its four register rows are
/// `tier0_divergences.yaml`:151-181.
library;

/// `const both = (a, b) => (a.trim() && b.trim() ? a.trim() : "");`
///
/// Marriage `:693`, Divorce `:599`.
///
/// **It trims both, tests both, returns A's trimmed value, and collapses to
/// `""` when either is blank.** Three properties a Dart port loses one at a
/// time:
///
/// 1. `b` is trimmed **for the test only** — B's value never reaches the wire
///    through this function, so the trim on `b` is observable solely through
///    the collapse (a whitespace-only B yields `""`, not A).
/// 2. The returned value is `a.trim()`, not `a`. The sub-object beneath the
///    mirror emits `s.dob` **untrimmed**, which is the asymmetry
///    `tier0_payload_equality_test.dart:571-600` (`F0-AC-83`) measures on the
///    `whitespace` fixture — a port that trimmed uniformly fails there and
///    nowhere else.
/// 3. The collapse is `""`, never null and never the key's absence.
///
/// `F3-NV-5`: the collapse branch is **structurally unreachable under
/// execution** on both pages — every mirrored key is separately mandatory in
/// `spouseValid` (Marriage `:839-848`, Divorce `:737-741`), so no state that
/// reaches `submitCase` can have a blank one. It is unit-tested here and
/// `oracle_coverage.yaml`:275-333 registers the Entry A gap.
String both(String a, String b) =>
    (a.trim().isNotEmpty && b.trim().isNotEmpty) ? a.trim() : '';

/// `payloadString(payload, ...keys)` — Marriage `:681-692`, Divorce `:587-598`.
///
/// Reads the first usable value out of a prerequisite record's free-form
/// payload, trying each key in order:
///
/// ```ts
/// if (typeof value === "string" && value.trim()) return value;
/// if (typeof value === "number") return String(value);
/// ```
///
/// Two details that are easy to normalise away:
///
/// - a **string** must be non-blank after trimming to be accepted, but the
///   value returned is the **untrimmed** original;
/// - a **number** is accepted unconditionally, including `0`, which stringifies
///   to `"0"` rather than being skipped as falsy.
///
/// JS `String(n)` on an integral double prints `5`, not `5.0`; Dart's
/// `toString()` on a `double` prints `5.0`. `jsonDecode` gives `int` for an
/// integral JSON number, so the common case is already right — the explicit
/// `int` branch keeps it right when a `double` arrives.
String payloadString(Map<String, Object?>? payload, List<String> keys) {
  if (payload == null) return '';
  for (final String key in keys) {
    final Object? value = payload[key];
    if (value is String && value.trim().isNotEmpty) return value;
    if (value is int) return '$value';
    if (value is double) {
      return value == value.roundToDouble() && value.isFinite
          ? '${value.toInt()}'
          : '$value';
    }
  }
  return '';
}

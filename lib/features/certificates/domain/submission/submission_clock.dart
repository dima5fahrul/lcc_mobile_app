/// The one clock every date on a submission payload is read from — and the one
/// deliberate divergence from the web in the whole product.
///
/// ## What the web does, and why it is wrong
///
/// All five pages declare, byte-identically:
///
/// ```ts
/// const today = () => new Date().toISOString().slice(0, 10);
/// ```
///
/// (`ResidentCertificatePage.tsx:148`, `BirthDeclarationPage.tsx:164`,
/// `DeathDeclarationPage.tsx:169`, `MarriageCertificatePage.tsx:678`,
/// `DivorceCertificatePage.tsx:584`.)
///
/// `toISOString()` is **UTC**. In Laos (UTC+7) every submission made between
/// 00:00 and 07:00 local time is dated **yesterday** — on eleven call sites
/// reaching eight registered wire keys. ADR-0005 rules this FIXED rather than
/// reproduced: [todayLocal] reads local time.
///
/// It is the only divergence, it is bounded by the closed 16-row register at
/// `test/fidelity/tier0_divergences.yaml`, and ADR-0005 point 5 carries the
/// **positive** assertion that keeps the fix visible after freezing hides it:
/// at the injected instant `2026-08-14T02:00:00+07:00` this returns
/// `2026-08-14` while the web-derived oracle for the same key holds
/// `2026-08-13`. Both halves are required (`F0-AC-28`).
///
/// ## The clock is INJECTED, never ambient
///
/// `DateTime.now()` appears **once** in `lib/**`'s date path — in
/// [SubmissionClock.system] below — and nowhere else. A page that calls
/// `DateTime.now()` inside its `buildFormData` cannot be driven to a fixed
/// instant, which makes ~200 other payload keys incomparable: Tier 0's whole
/// matrix rests on being able to freeze this. `toUtc()` is forbidden anywhere
/// under `lib/**` (ADR-0005 O-4), enforced by
/// `test/architecture/date_path_test.dart` with a planted-fixture self-test
/// (`F0-AC-29`, `F0-AC-84`).
///
/// ## Placement
///
/// ADR-0005 O-1 put this in `lib/presentation/forms/`. RULING 9 moved the whole
/// submission contract to `features/certificates/domain/submission/` and the
/// clock moved with the contract it exists to serve — one consuming feature, so
/// `ssd.md` § 4.2 row 2, not row 3. Recorded as **FU-10**, an amendment to
/// ADR-0005 rather than a silent deviation from it (specs.md § 6.1.2).
library;

class SubmissionClock {
  /// The clock every test and every Tier 0 run uses: an explicit instant
  /// source.
  const SubmissionClock(this.now);

  /// A clock fixed at [instant]. The shape Tier 0 injects.
  SubmissionClock.fixed(DateTime instant) : now = (() => instant);

  /// **The single `DateTime.now()` site in the date path.**
  ///
  /// Written as an explicit `() => DateTime.now()` closure rather than the
  /// `DateTime.now` tear-off on purpose: the tear-off spells `DateTime.now`
  /// with no parentheses and would slip past the repo-wide guard that makes
  /// this site the only registered one.
  SubmissionClock.system() : now = (() => DateTime.now());

  /// Reads the current instant. **Local**, never converted.
  final DateTime Function() now;

  /// `yyyy-MM-dd` in **local** time — the fixed `today()`.
  ///
  /// Deliberately hand-formatted rather than routed through
  /// `DateTime.toIso8601String().substring(0, 10)`: on a local `DateTime` that
  /// expression happens to give the same answer today, and it is one
  /// `.toUtc()` away from silently reintroducing the defect this method exists
  /// to remove. Zero-padding is explicit for the same reason.
  String todayLocal() {
    final DateTime t = now();
    final String month = t.month.toString().padLeft(2, '0');
    final String day = t.day.toString().padLeft(2, '0');
    return '${t.year.toString().padLeft(4, '0')}-$month-$day';
  }
}

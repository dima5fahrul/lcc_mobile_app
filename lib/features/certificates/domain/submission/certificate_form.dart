/// The five certificate submissions that share the submission contract.
///
/// **Five, not six.** `FamilyBookPage.tsx:204` builds
/// `me.requestFamilyBookCopy({reason})` and `:236` fires it with a bilingual
/// constant — no case, no draft, no `form_data`, no attachment, no reference
/// number. It is not a certificate submission and it is excluded by name
/// (specs.md § 6.2.4). An implementer must **not** add a sixth member here to
/// make F4 fit; F4's own single-POST path is F4's.
///
/// The enum exists so the per-page registries below it can be written as a
/// `switch` with **no `default` arm** — Dart's exhaustiveness check then makes
/// a missing page a compile error rather than a runtime fallback
/// (`F0-AC-32`). A `Map` literal keyed by `String` cannot do that, which is why
/// [SubmissionPlan.all]'s string keys are *derived from* this enum rather than
/// being the source of truth.
library;

enum CertificateForm {
  /// `ResidentCertificatePage.tsx:508` — `service_code: SERVICE_CODE`.
  resident('resident'),

  /// `BirthDeclarationPage.tsx:821` — `service_code: SERVICE_CODE`.
  birth('birth'),

  /// `DeathDeclarationPage.tsx:845` — `service_code: SERVICE_CODE`.
  death('death'),

  /// `MarriageCertificatePage.tsx:958` — `service_code: "marriage"`.
  marriage('marriage'),

  /// `DivorceCertificatePage.tsx:854` — `service_code: "divorce"`.
  divorce('divorce'),
  ;

  const CertificateForm(this.serviceCode);

  /// The literal `service_code` this page puts on the create envelope. It is
  /// also the key this form appears under in [SubmissionPlan.all], so the map
  /// key and the wire value cannot drift apart.
  final String serviceCode;
}

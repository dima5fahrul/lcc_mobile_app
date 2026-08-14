/// One step in a certificate submission sequence.
///
/// The *plan* records only that a step is or is not in the sequence, and in
/// what order. The **condition** under which a step runs belongs to the page:
/// Resident pays on `decided.fee_lak > 0`
/// (`ResidentCertificatePage.tsx:535`), Marriage and Divorce on
/// `fee_lak > 0 && payment_state !== "paid"`
/// (`MarriageCertificatePage.tsx:987`, `DivorceCertificatePage.tsx:883`).
/// Encoding those here would be authoring five pages' logic in a batch that
/// writes no page (specs.md § 6.2.2).
library;

enum SubmissionStep {
  /// `POST /applications` — the create envelope, **without** the case
  /// reference, because the reference does not exist until this call returns.
  create,

  /// `PATCH /applications/{id}` — the update envelope, **with** the case
  /// reference bound in. See `CaseReferenceBinding` for the two mechanics.
  update,

  /// `POST /applications/{id}/attachments`, once per file.
  attach,

  /// `POST /applications/{id}/submit`.
  submit,

  /// `POST /applications/{id}/pay`. **Absent from Birth and Death**: payment is
  /// a separate mutation the review step triggers
  /// (`BirthDeclarationPage.tsx:847-853`, `DeathDeclarationPage.tsx:871-877`),
  /// not a step inside `submitCase`.
  pay,
}

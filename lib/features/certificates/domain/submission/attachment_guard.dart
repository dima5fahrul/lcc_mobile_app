/// How a page decides an attachment has already been sent, so a retry does not
/// re-upload it.
///
/// ## D-I is recorded here, not fixed here
///
/// `fsd.md` § 13.1 assigns D-I ("a replaced file is never re-uploaded") to F0.
/// It is **not F0's**: the guards are page state
/// (`ResidentCertificatePage.tsx:457`; `MarriageCertificatePage.tsx:972`) and
/// F0 builds no uploader (specs.md § 4.3, § 6.3.6). What F0 owes is the
/// *contract* the fix has to satisfy, which is [AttachmentGuard.slotKeyed]'s
/// doc below: **the guard keys on file identity, not on slot.** That is the
/// fix, expressed as the declaration F1 must meet.
library;

enum AttachmentGuard {
  /// A `Set` of already-sent slot names.
  ///
  /// Resident `uploaded.current.has(attachment.slot)`
  /// (`ResidentCertificatePage.tsx:457`, `:526`); Birth
  /// `uploaded.current.has("child.hospital_notice")`
  /// (`BirthDeclarationPage.tsx:738`, `:840`); Death the same at `:762`,
  /// `:864`.
  ///
  /// **D-I lives exactly here.** Keying on the slot means replacing the file in
  /// a slot that has already been sent skips the upload, so the citizen's
  /// second choice never reaches the API. F1's implementation of this guard
  /// must key on the **identity of the file** (path/bytes/handle), not on the
  /// slot name — same declared guard, corrected key.
  slotKeyed,

  /// One boolean for the whole submission.
  ///
  /// Marriage `attachmentsSent` (`MarriageCertificatePage.tsx:972-977`),
  /// Divorce the same (`DivorceCertificatePage.tsx:868-873`). Coarser than
  /// [slotKeyed] and it carries the same defect one level up.
  singleFlag,

  /// No attachment step in the sequence at all.
  ///
  /// Reserved for a page with no uploader. **No inhabitant of
  /// `SubmissionPlan.all` uses it today** — all five pages attach — and
  /// FamilyBook, which really has no uploader, is excluded from the plan
  /// entirely (specs.md § 6.2.4). It exists so a future page's absence of
  /// attachments is *declared* rather than expressed by leaving the field
  /// nullable.
  none,
}

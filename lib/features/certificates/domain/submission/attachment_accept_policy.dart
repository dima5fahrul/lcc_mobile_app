/// The five `accept` strings the web's file inputs carry, **verbatim, as
/// data** — RULING 5 (specs.md § 6.6).
///
/// ## This is documentation and an oracle target. It is NOT a filter.
///
/// In HTML, `accept` filters the picker's *default view*. It is advisory: the
/// browser does not reject a file selected past it, and the client performs no
/// MIME or size validation anywhere — no page reads `size_bytes`, no page
/// inspects `File.type` (`ResidentCertificatePage.tsx:213-221`,
/// `MarriageCertificatePage.tsx:379-383`).
///
/// In Flutter, `FilePicker` with `FileType.custom` + `allowedExtensions` is a
/// **hard filter with no escape hatch**. Porting these strings as
/// `allowedExtensions` therefore diverges on **all five** pages, not on
/// Resident alone — Birth's `image/*,application/pdf` would become a hard
/// filter the web does not have either. Resident is not a special case; it is
/// the loudest instance of a general error, and the earlier "FIX Resident"
/// framing located the problem in the wrong place (specs.md § 6.6.1).
///
/// ## The binding requirement F1–F3 inherit
///
/// > **No code path may reject a picked file on the basis of its extension or
/// > MIME type. A `.pdf` selected on the Resident form must reach the
/// > attachment list.**
///
/// It is stated as a behaviour rather than an API because the picker plugin is
/// `F0-NV-4` and F0 adds no dependency (specs.md § 4.3). It is enforced
/// repo-wide by the guard in
/// `test/architecture/picker_rejection_test.dart` (`F0-AC-40`), which scans
/// **`lib/**`** — not just `lib/presentation/forms/` — because F0 builds no
/// uploader, so the real risk surface is F1's `features/certificates/`, which
/// does not exist yet.
///
/// What remains open and is **not** decided here: whether Resident's picker
/// *default view* should be image-first (matching the web's hint) or all-files.
/// That is presentation, it is Tier 3's business, and under this ruling it
/// carries no capability loss. `fsd.md` Q-3 is narrowed, not answered (FU-4).
library;

import 'certificate_form.dart';

class AttachmentAcceptPolicy {
  const AttachmentAcceptPolicy._();

  /// `ResidentCertificatePage.tsx:226` — `accept="image/*"`. The one page whose
  /// hint excludes PDF.
  static const String resident = 'image/*';

  /// `BirthDeclarationPage.tsx:366` — `accept="image/*,application/pdf"`.
  static const String birth = 'image/*,application/pdf';

  /// `DeathDeclarationPage.tsx:360` — `accept="image/*,application/pdf"`.
  static const String death = 'image/*,application/pdf';

  /// `MarriageCertificatePage.tsx:388` — `accept="image/*,.pdf"`. Note the
  /// **extension** spelling, where Birth and Death use the **MIME** spelling
  /// for the same intent. Three spellings, five pages.
  static const String marriage = 'image/*,.pdf';

  /// `DivorceCertificatePage.tsx:391` — `accept="image/*,.pdf"`.
  static const String divorce = 'image/*,.pdf';

  /// The five, by page.
  ///
  /// There is **no sixth, normalised value**. Collapsing the three spellings to
  /// one would be a port better than the web, which is a divergence no tier can
  /// see (`F0-AC-39`). FamilyBook has no upload control and no entry.
  static const Map<CertificateForm, String> byForm = <CertificateForm, String>{
    CertificateForm.resident: resident,
    CertificateForm.birth: birth,
    CertificateForm.death: death,
    CertificateForm.marriage: marriage,
    CertificateForm.divorce: divorce,
  };

  /// Where each value was read from, so `F0-AC-39`'s citations are checkable
  /// against the pinned source rather than against this file.
  static const Map<CertificateForm, String> srcByForm = <CertificateForm, String>{
    CertificateForm.resident: 'ResidentCertificatePage.tsx:226',
    CertificateForm.birth: 'BirthDeclarationPage.tsx:366',
    CertificateForm.death: 'DeathDeclarationPage.tsx:360',
    CertificateForm.marriage: 'MarriageCertificatePage.tsx:388',
    CertificateForm.divorce: 'DivorceCertificatePage.tsx:391',
  };
}

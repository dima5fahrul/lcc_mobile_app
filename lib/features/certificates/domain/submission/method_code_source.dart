/// Where a page's `method_code` comes from — the live `/payment-methods` list,
/// or a static per-page map.
///
/// This is a **`pay` body**, not `form_data`, so it sits outside Tier 0's two
/// oracles and no fidelity tier can catch getting it the wrong way round. That
/// is exactly why it is declared here rather than left to whoever writes the
/// page (specs.md § 6.4.2 item 5).
///
/// `fsd.md` D-O escalates the `cc → bank-transfer` discard to the user
/// separately. F0 records the mechanic and does not pre-empt that.
library;

import 'certificate_form.dart';

enum MethodCodeSource {
  /// Resolve from the live `/payment-methods` response, falling back to a
  /// literal when nothing matches.
  ///
  /// Resident picks by *kind* (`qr` → `"qr"`, everything else → `"bank"`) and
  /// falls back per-branch (`ResidentCertificatePage.tsx:494-498`); Birth and
  /// Death prefer an enabled `qr` row, then any enabled row, then `"laoqr"`
  /// (`BirthDeclarationPage.tsx:809-813`, `DeathDeclarationPage.tsx:833-837`).
  /// The two shapes differ; both are `liveList`, and F1/F2 transcribe their
  /// own.
  liveList,

  /// A `const` map on the page, with no network read at all.
  ///
  /// `MarriageCertificatePage.tsx:140-144` and
  /// `DivorceCertificatePage.tsx:125-129`, byte-identical:
  /// `{qr: "laoqr", bank: "bank-transfer", cc: "bank-transfer"}` — a card
  /// payment settles as a bank transfer, and the `cc` distinction is discarded.
  staticMap,
}

/// The per-page registry, as an exhaustive `switch` with **no `default` arm**.
///
/// A `Map` literal would let a sixth page be added with no entry and resolve to
/// `null`, and a `default` arm would resolve it to whichever source the author
/// thought was the safe one. Neither is safe: picking [liveList] for a static
/// page issues a request the web never makes, and picking [staticMap] for a
/// live page sends a code the gateway may not know. Dart's enum exhaustiveness
/// makes the missing arm a **compile error** instead (`F0-AC-32`).
MethodCodeSource methodCodeSourceFor(CertificateForm form) {
  switch (form) {
    case CertificateForm.resident:
      return MethodCodeSource.liveList;
    case CertificateForm.birth:
      return MethodCodeSource.liveList;
    case CertificateForm.death:
      return MethodCodeSource.liveList;
    case CertificateForm.marriage:
      return MethodCodeSource.staticMap;
    case CertificateForm.divorce:
      return MethodCodeSource.staticMap;
  }
}

/// The `file:line` each registry decision was read from, so the split is
/// checkable against the source rather than against itself.
const Map<CertificateForm, String> kMethodCodeSourceSrc =
    <CertificateForm, String>{
  CertificateForm.resident: 'ResidentCertificatePage.tsx:494-498',
  CertificateForm.birth: 'BirthDeclarationPage.tsx:809-813',
  CertificateForm.death: 'DeathDeclarationPage.tsx:833-837',
  CertificateForm.marriage: 'MarriageCertificatePage.tsx:140-144',
  CertificateForm.divorce: 'DivorceCertificatePage.tsx:125-129',
};

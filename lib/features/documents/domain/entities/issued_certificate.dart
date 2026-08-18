/// `IssuedCertificate` — one issued certificate, as `GET /me/certificates`
/// and `GET /me/certificates/{id}` return it.
///
/// Ported from `lcc-app/src/app/api/types.ts:625-641` (`Certificate`), **all
/// 15 wire fields** (`B5-AC-27`), including the four the History surface parses
/// and never renders — see the per-field notes below.
///
/// ## Why not `Certificate`
///
/// Two collisions, both real in this tree:
///
/// * `features/certificates/` is the **submission** slice — the hand-ported
///   forms, `SubmissionPlan`, `CaseReferenceBinding`. `features/documents/` is
///   the **collection** slice: what exists after a case is issued. They share
///   no type and must not import each other (specs.md § 6.5, `B5-AC-24`).
/// * `ApplicationRow.certificateNo` already carries the *case's* certificate
///   number, which is not this object.
///
/// ## `status` is a plain `String`, deliberately (specs.md § 5)
///
/// `docSpecFromCertificate` (`data/documents.ts:126`) does `titleCase(cert.status)`
/// on it — an **open set** the source never closes. An enum here would add a
/// failure mode the source lacks (`ssd.md` § 11.2 L-10): a payload with
/// `status: "superseded"` must render `Superseded`, not `unknown` and not a
/// crash (`B5-AC-28`).
///
/// ## `verify_code` is required in the source, and empty means absent
///
/// `types.ts:637` types it non-optional, so it is a required `String` here.
/// The card gates on **truthiness** (`HistoryDetailPage.tsx:475`), so `""` must
/// behave as absent — [hasVerifyCode] is that gate, named rather than repeated
/// at each of the two render sites.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/bilingual.dart';

part 'issued_certificate.freezed.dart';

@freezed
abstract class IssuedCertificate with _$IssuedCertificate {
  const factory IssuedCertificate({
    required String id,
    required String certificateNo,

    /// The **first** clause of the three-step resolution at
    /// `HistoryDetailPage.tsx:150-156`.
    String? applicationId,

    /// The **third** clause of that resolution.
    String? referenceNo,
    required String serviceCode,

    /// The shared kernel's [Bilingual], **imported not redefined**
    /// (`ssd.md` § 4.6, `B5-AC-29`).
    Bilingual? serviceName,
    required String holderName,
    String? uin,

    /// Kept as the **raw wire string**: formatting is the mapper's job and the
    /// card renders it through `formatApplicationDate` (`:473`), which needs
    /// the unparsed value to reproduce the source's verbatim fallback.
    required String issuedAt,
    String? issuedByName,

    /// A plain `String`, not an enum — see the library doc.
    required String status,
    required String verifyCode,

    /// Parsed, **not rendered**: no call site on this surface reads it.
    /// Carried because `application_row.dart`'s rule is that every field the
    /// wire sends is parsed.
    String? verifyUrl,
    String? qrPayload,

    /// Parsed, **not rendered** — the History path always *generates* the
    /// document (`HistoryDetailPage.tsx:651` passes a `spec`, never a URL).
    /// The Account branch that would read this — a remote PDF URL in an
    /// `<iframe>` — stays deferred (specs.md § 6.11, FU-1).
    String? fileUrl,

    /// Parsed, **not rendered** — its only reader in the source was the
    /// document-hash check in the `verification` namespace, whose two endpoints
    /// have zero call sites (specs.md Finding A).
    ///
    /// **The Dart name is `documentHash` because specs.md § 5's field table
    /// says so, and that makes `B5-AC-9` unsatisfiable as written**: that
    /// criterion greps `lib/` for the identifier while `B5-AC-27` requires all
    /// 15 wire fields including this one. The two cannot both hold. § 5 wins —
    /// an entity that silently drops a wire field is the defect
    /// `application_row.dart` wrote its rule against — and the conflict is
    /// reported rather than resolved by renaming the field to dodge a grep.
    String? documentHash,
  }) = _IssuedCertificate;

  const IssuedCertificate._();

  /// `certificate?.verify_code &&` — `HistoryDetailPage.tsx:475`, and
  /// `code &&` at `DocumentViewer.tsx:150`. **Empty is absent**, because both
  /// gates are JavaScript truthiness (`B5-AC-84`).
  bool get hasVerifyCode => verifyCode.isNotEmpty;

  /// `certificate?.qr_payload &&` — `:482`, and `payload &&` at `:164`.
  bool get hasQrPayload => qrPayload != null && qrPayload!.isNotEmpty;
}

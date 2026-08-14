/// `CitizenDocument` — one row of `GET /me/documents`.
///
/// Ported verbatim from `lcc-app/src/app/api/types.ts:343-355`. Backs the "My
/// Documents" card, `AccountPage.tsx:392-490` — 99 of the source page's 749
/// lines, and a block that appears in neither `roadmap.md` § B8's endpoint list
/// nor the B8 dispatch (specs.md § 2.2 Finding B).
///
/// `title` is [Bilingual], the shared-kernel type at
/// `features/session/domain/entities/bilingual.dart` (`ssd.md` § 4.6) —
/// **imported, not redefined**. It is read with `text(Bilingual?, Lang)` from
/// `lib/i18n/i18n.dart` (`AccountPage.tsx:442` is `text(doc.title, lang)`),
/// which is also imported and not re-implemented: four B2 features
/// re-implemented that function citing G-L3, and G-L3 has nothing to say about
/// `lib/i18n/`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/bilingual.dart';

part 'citizen_document.freezed.dart';

/// `status: "valid" | "expired" | "missing"` — a **closed three-value union**
/// in the source, with a fourth member here.
///
/// [unknown] exists because the API may grow a value and a crash is not an
/// acceptable response to that (specs.md § 5). It is not a divergence: the
/// source's `docStatus` (`AccountPage.tsx:297-302`) is a two-branch ternary
/// whose final `else` catches everything that is neither `valid` nor `expired`
/// and labels it `missing` — so an unknown string already renders as "Not on
/// file" in the web. [unknown] therefore maps to the same badge as [missing]
/// while staying distinguishable in a test (B8-AC-26).
enum DocumentStatus {
  valid,
  expired,
  missing,

  /// A `status` the source's union does not contain. Renders as [missing].
  unknown;

  /// `doc.status === "valid" ? … : doc.status === "expired" ? … : …`
  static DocumentStatus parse(String raw) => switch (raw) {
        'valid' => DocumentStatus.valid,
        'expired' => DocumentStatus.expired,
        'missing' => DocumentStatus.missing,
        _ => DocumentStatus.unknown,
      };
}

@freezed
abstract class CitizenDocument with _$CitizenDocument {
  const factory CitizenDocument({
    required String id,
    required String type,
    required Bilingual title,
    required String number,
    required DocumentStatus status,
    String? issuedAt,
    String? expiresAt,
    required String authority,
    required bool available,
    String? fileUrl,
    String? verifyCode,
  }) = _CitizenDocument;

  const CitizenDocument._();

  /// `const openable = Boolean(doc.available && doc.file_url)` —
  /// `AccountPage.tsx:427`.
  ///
  /// **B8 renders the `false` branch for every row** — `c("notReady")` — even
  /// when this is true, because View/Download and `DocumentViewer` are deferred
  /// to FU-2 (specs.md § 6.6). The getter exists so the deferral is a *choice
  /// made at the render site* against a ported predicate, rather than a
  /// predicate that was never ported; FU-2's owner turns the branch on without
  /// re-deriving it. See `document_row.dart`.
  bool get openable => available && (fileUrl?.isNotEmpty ?? false);
}

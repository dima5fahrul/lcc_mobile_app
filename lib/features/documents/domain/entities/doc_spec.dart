/// `DocSpec` / `DocField` — the printable document, as a value.
///
/// Ported verbatim from `lcc-app/src/app/lib/document.ts:13-34`. Pure value
/// objects: they know nothing about the wire, nothing about a canvas and
/// nothing about a locale — the mappers in `doc_spec_mappers.dart` resolve the
/// language *before* building one, exactly as the source's
/// `docSpecFrom*(…, lang)` do.
///
/// That split is what makes `B5-AC-87` and `B5-AC-64` a testable pair: the
/// **chrome** the painter draws around a spec is locale-invariant (Finding N —
/// `document.ts` never receives `lang`), while the **content** inside a spec is
/// not.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'doc_spec.freezed.dart';

/// `interface DocField { label: string; value: string }` — `document.ts:13-16`.
@freezed
abstract class DocField with _$DocField {
  const factory DocField({
    required String label,
    required String value,
  }) = _DocField;
}

/// `interface DocSpec` — `document.ts:18-34`, field for field.
@freezed
abstract class DocSpec with _$DocSpec {
  const factory DocSpec({
    /// Big document title, e.g. "National Identity Card".
    required String title,

    /// Small kicker above the title, e.g. "Civil Registration".
    /// Painted **upper-cased** (`:124`), so it is stored as written.
    required String kicker,
    required String refNo,
    required String holderName,

    /// Issuing office / authority.
    required String office,
    @Default(<DocField>[]) List<DocField> fields,
    required String issued,

    /// `validUntil?: string` — **absent on both live mappers**, so the
    /// *VALID UNTIL* half of the strip never renders on the History path
    /// (`B5-AC-72`). The field exists because the painter's source draws it
    /// conditionally and porting the condition is cheaper than porting a
    /// painter that cannot express it.
    String? validUntil,

    /// Short verification code shown in the footer + faux QR.
    required String verifyCode,

    /// `hasPhoto?: boolean` — `doc.type.includes("id") || …("passport")`
    /// (`data/documents.ts:113`), which only `docSpecFromDocument` sets. That
    /// mapper is **dead** (Finding D) and is not ported, so on the History path
    /// this is **always false** (`B5-AC-71`).
    @Default(false) bool hasPhoto,
  }) = _DocSpec;
}

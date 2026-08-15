/// `Attachment` — one file hung off a case.
///
/// Ported field-for-field from `lcc-app/src/app/api/types.ts:450-460`
/// (**9 fields, none optional**).
///
/// ## Every field is parsed, including the four nothing draws
///
/// `HistoryDetailPage.tsx:602-624` reads `id`, `label`, `file_name`, `slot`,
/// `size_bytes`, `uploaded_at` and `file_url`. `kind` and `mime_type` are read
/// by nothing on this surface. They are parsed anyway, on
/// `application_row.dart`'s stated rule — *"a partial construction makes the
/// entity mean something subtly different from the row it came from"* — and
/// because B5's document viewer selects on exactly those two.
///
/// ## What the port renders today: the empty state, and nothing else
///
/// specs.md § 6.14 offered three dispositions for the attachment **rows** and
/// ruled that the implementer may not choose between them — § 10 does. § 10's
/// *"What this approval is not"* paragraph names `url_launcher` in its
/// exclusion list, so the dependency is **not** approved by name, which § 6.14
/// resolves to its third option: *"rows omitted, empty state shipped, and the
/// gap recorded as an explicit NOT EVALUATED plus a follow-up"* — and
/// explicitly **not** the second option, an inert visible row, which
/// `B7-AC-71` makes an automatic FAIL.
///
/// This entity is therefore parsed and counted but not rendered row-by-row.
/// The count is load-bearing even so: `attachments.length === 0` (`:596`) is
/// what selects the empty state, and a detail with two attachments must not
/// print *"No files are attached to this case."* See
/// `history_detail_attachments.dart`.
///
/// [sizeKb] lives here rather than in the widget so the `max(1, …)` clamp is
/// measurable without rendering a row that is not rendered.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'attachment.freezed.dart';

@freezed
abstract class Attachment with _$Attachment {
  const factory Attachment({
    required String id,

    /// `"document" | "photo" | "signature" | "stamp"` (`types.ts:452`).
    ///
    /// Carried as the wire string rather than an enum: nothing in B7 branches
    /// on it, and an enum would need the same [CaseStatus.unknown]-shaped
    /// escape hatch to survive a fifth kind — cost with no reader. B5 models it
    /// properly when it builds the viewer that selects on it.
    required String kind,
    required String slot,
    required String label,
    required String fileName,
    required String fileUrl,

    // **`mime_type` (`types.ts:457`) is deliberately NOT carried**, and this is
    // the § 6.9 `STATUS_META` disposition rather than an oversight. Measured:
    // `grep -n mime HistoryDetailPage.tsx` returns nothing — the attachments
    // card renders label-or-filename, slot, KB and the upload date (`:603-624`)
    // and never the MIME type. Porting the field would model a value with zero
    // readers on either side.
    //
    // It also trips **R-21** (`layering_test.dart:275`), which forbids the
    // identifier repo-wide because `.mimeType` is how a file-type rejection
    // gets hand-rolled once the picker is open. This entity is read-only and
    // reaches no picker, so the guard's hit here was a false positive — but the
    // right answer to a false positive on a field nothing reads is to drop the
    // field, not to widen the guard. `PickedAttachment` (`:44`) and
    // `application_usecases.dart:266` already record the same stance for the
    // upload direction; this makes the read direction agree with them.
    required int sizeBytes,
    required String uploadedAt,
  }) = _Attachment;

  const Attachment._();

  /// `a.label || a.file_name` — `HistoryDetailPage.tsx:617`.
  ///
  /// JS `||` on a string is falsy-on-empty, so a `label: ""` falls through to
  /// the filename. A Dart `??` would not: it would render an empty line.
  String get displayName => label.isNotEmpty ? label : fileName;

  /// `Math.max(1, Math.round(a.size_bytes / 1024))` — `HistoryDetailPage.tsx:619`.
  ///
  /// The clamp is the interesting half: a 100-byte file rounds to `0` and the
  /// source prints **`1 KB`**, never `0 KB` (`B7-AC-70`). `Math.round` and
  /// Dart's `num.round()` disagree only on exact `.5` for negatives, and a byte
  /// count is non-negative, so they agree on every reachable input.
  int get sizeKb {
    final int rounded = (sizeBytes / 1024).round();
    return rounded < 1 ? 1 : rounded;
  }
}

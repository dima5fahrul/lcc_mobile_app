/// `ResidentCertificatePage.tsx:39-44` — `interface UploadedFile`, the file the
/// citizen has chosen but not yet sent.
///
/// ```ts
/// interface UploadedFile {
///   name: string;
///   preview: string | null;
///   /** The real file, kept so it can be attached to the case on submit. */
///   file: File;
/// }
/// ```
///
/// ## Why this is in `features/application/domain/` and not next to the page
///
/// Each web page declares its own `UploadedFile` (Resident `:39`, Marriage
/// `:44`, and so on) because TypeScript has no cheaper option. Here it crosses
/// a layer *and* a feature: the certificate page produces it and
/// [ApplicationRepository.addAttachment] consumes it, so under `ssd.md` § 4.3
/// it has to be a domain entity — *"Domain entities are the only shared
/// currency"* — and under G-L3 it has to live in the feature that owns the
/// method taking it. `features/certificates/` reaches
/// `features/application/domain/` and never its `data/`, which is exactly the
/// CFI shape the four write methods were put here for (`specs.md` § 6.3).
///
/// It was first written under `features/certificates/domain/entities/`. That
/// path is not one of `specs.md` § 3.1's eleven rows, so `F1-AC-77` moves it
/// here rather than widening the table.
///
/// ## `preview` is `bytes`, and it is not a data URL
///
/// The web reads the file twice: once as a data URL for the `<img src>`
/// (`ResidentCertificatePage.tsx:217-220` `FileReader.readAsDataURL`) and once
/// as the raw `File` for the multipart POST. Flutter's `Image.memory` takes the
/// bytes directly, so one read serves both and there is no base64 round trip.
/// The observable — a thumbnail of the picked image above its filename — is
/// identical.
///
/// [bytes] is nullable for exactly the reason `preview` is: `FileReader.onload`
/// may not have produced anything, and `:229-232` renders a camera glyph in
/// place of the thumbnail when it did not.
///
/// ## R-21 — this type carries no file-type field, deliberately
///
/// There is no `extension`, no `mimeType` and no `kind` here beyond the slot's
/// own declared `kind`, because nothing in the client may branch on the picked
/// file's type: *"a `.pdf` selected on the Resident form must reach the
/// attachment list"* (`attachment_accept_policy.dart:22-24`,
/// `layering_rules.dart` `pickerRejectionViolations`). A field that existed
/// would be a field something could later filter on.
library;

import 'dart:typed_data';

class PickedAttachment {
  const PickedAttachment({
    required this.name,
    required this.bytes,
    this.path,
  });

  /// `picked.name` (`ResidentCertificatePage.tsx:219`) — the filename as the
  /// picker reported it, rendered under the thumbnail at `:236`.
  final String name;

  /// The file's contents. Null when the picker returned a path but no bytes,
  /// which is the analogue of `FileReader` yielding no `preview`.
  final Uint8List? bytes;

  /// The on-device path, when the platform gave one. Not on the wire and not
  /// rendered; kept so an upload can stream from disk instead of holding a
  /// large scan in memory.
  final String? path;

  @override
  String toString() => 'PickedAttachment($name, ${bytes?.length ?? 0} B)';
}

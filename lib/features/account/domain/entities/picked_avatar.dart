/// The photograph the citizen chose for their avatar but has not yet sent —
/// the port of the `File` that `AccountPage.tsx:235` pulls off the input and
/// `endpoints.ts:109` appends to the form.
///
/// ```ts
/// uploadAvatar: (file: File) => {
///   const form = new FormData();
///   form.append("file", file);
///   return api.upload<{ avatar_url: string }>("/me/avatar", form);
/// },
/// ```
///
/// That is the **entire** upload handler in the oracle. Three lines, and this
/// type carries the two things they use: the bytes and the name.
///
/// ## Why this is not `features/application/domain/entities/picked_attachment.dart`
///
/// `PickedAttachment` is the same shape and the certificate forms already use
/// it — but it belongs to `features/application/`, and `B8-AC-7` (as amended by
/// specs.md § 9.9) allows `features/account/**` to reach only
/// `session/domain/**`, `auth/domain/**` and its own `di/` composition root.
/// Importing it would be a new cross-feature edge that `account_scope_test.dart`
/// fails on. So the account feature declares its own, exactly as the web
/// declares `UploadedFile` once per page rather than sharing one
/// (`ResidentCertificatePage.tsx:39`, Marriage `:44`, and so on).
///
/// **The duplication is the sanctioned cost, not an oversight.** `ssd.md` § 4.3
/// accepts wire-shape duplication across features precisely to keep the
/// dependency graph a tree; `F1-AC-77` made the same call in the opposite
/// direction when it moved `PickedAttachment` out of `features/certificates/`.
///
/// ## R-21 — no file-type field, and that is load-bearing
///
/// There is no `extension`, no `mimeType`, no `kind`. `AccountPage.tsx:344`'s
/// `accept="image/*"` filters what the OS picker *shows* and **rejects
/// nothing** — a citizen who navigates to a `.pdf` in the picker can still
/// choose it and the web will upload it. A field here would be a field
/// something could later filter on, and
/// `layering_rules.dart`'s `pickerRejectionViolations` scans the whole repo for
/// exactly that. `security-review-b8b.md` § 12(a) S-2 restates the rule for
/// this batch.
///
/// ## [toString] prints a byte count, never the bytes
///
/// `security-review-b8b.md` § 7 asks for this explicitly: *"`PickedAttachment.toString()`
/// returns the filename and a byte count, never the bytes. That is the right
/// shape and it should be preserved if B8b introduces its own picked-file type
/// rather than reusing this one."* A `toString` that dumped a JPEG into a log
/// line would put a citizen's face in the log surface `B8-AC-45` gates.
library;

import 'dart:typed_data';

class PickedAvatar {
  const PickedAvatar({required this.name, required this.bytes, this.path});

  /// The filename as the picker reported it, sent verbatim as the multipart
  /// part's `filename` — the analogue of the browser putting `File.name` on the
  /// wire. Unsanitised, which is `security-review-b8b.md`'s `B8b-6` (F1's `S-3`
  /// recurring on a sixth surface). **Ported as measured**: sanitising here
  /// would change the bytes of a multipart body that Tier 0 gates.
  final String name;

  /// The file's contents, byte-for-byte as the picker returned them.
  ///
  /// **Nothing in this port may re-encode, resize, strip or inspect them.**
  /// See [PickedAvatar]'s upload path in `account_remote_datasource.dart` for
  /// the full ruling and its authority.
  final Uint8List? bytes;

  /// The on-device path, when the platform gave one. Not on the wire and not
  /// rendered — kept only because `file_picker` reports it.
  ///
  /// On Android that path **is** a plaintext copy the plugin wrote into
  /// `getCacheDir()/file_picker/<millis>/<name>` and never deletes
  /// (`security-review-b8b.md` § 3.3, `B8b-2`, MEDIUM). B8b neither creates nor
  /// closes that behaviour: it is `file_picker`'s, it has been live on five
  /// certificate surfaces since F1, and **FU-16** owns the fix
  /// (`FilePicker.platform.clearTemporaryFiles()`). Named here so the next
  /// reader of this field does not have to rediscover it.
  final String? path;

  @override
  String toString() => 'PickedAvatar($name, ${bytes?.length ?? 0} B)';
}

/// Opening the OS picker for the avatar, as a parameter — B8b.
///
/// The web's control is a hidden `<input type="file" accept="image/*">` that a
/// transparent button clicks (`AccountPage.tsx:333-347`). Flutter has no hidden
/// input, so the tap calls the picker directly; [AvatarFilePicker] is that call
/// hoisted into a parameter so a widget test can drive the whole upload path
/// without a platform channel. The idiom is `ResidentFilePicker`
/// (`resident_fields.dart:50`), not invented here.
library;

import 'package:file_picker/file_picker.dart';

import '../../domain/entities/picked_avatar.dart';

/// What opening a picker and getting a photograph back looks like.
///
/// Null means the citizen cancelled — the analogue of
/// `const file = e.target.files?.[0]; … if (!file) return;`
/// (`AccountPage.tsx:235-237`). Cancelling must **not** clear an existing
/// avatar; it does nothing at all.
typedef AvatarFilePicker = Future<PickedAvatar?> Function();

/// The default picker: `file_picker`, with **no type filter at all**.
///
/// ## Zero new dependencies, and that is a criterion
///
/// `file_picker: ^8.1.7` has been in `pubspec.yaml` since F1 (`7ee0e0b`),
/// resolving to 8.3.7, and five certificate forms already drive it. B8b adds
/// **none** — `git diff -- pubspec.yaml pubspec.lock` over this batch is empty.
/// `B8-AC-57` originally demanded *"exactly one"* new dependency and was
/// **amended 2026-08-19 (Amendment 2)**, because the only way to satisfy the
/// count was to ship `image_picker` beside a picker the tree already has.
///
/// **`image_picker` is forbidden, on two independent grounds.** It requires
/// `NSPhotoLibraryUsageDescription` in `ios/Runner/Info.plist` — a tree frozen
/// by specs.md § 4.1, which § 8.3 item 2 makes **BLOCKED, not widened** — and
/// its `imageQuality` / `maxWidth` / `maxHeight` parameters re-encode, which
/// drops EXIF as a side effect and is the exact mechanism by which an L-10(b)
/// divergence enters unnoticed (`security-review-b8b.md` § 4.2).
/// `file_picker` contributes **zero** Android permissions — a `<queries>`
/// element and nothing else — because it goes through the Storage Access
/// Framework, which is why F1 landed a five-upload wizard without touching a
/// platform tree.
///
/// ## R-21 — no `type:`, no `allowedExtensions:`
///
/// This reproduces `resident_fields.dart:59-63` exactly. `accept="image/*"` at
/// `AccountPage.tsx:344` filters what the OS picker *shows* and **rejects
/// nothing**: a citizen who navigates to a `.pdf` can still choose it and the
/// web will upload it. `FileType.image` here would be a hard filter the web
/// does not have — a capability the citizen loses, which is L-10(b) again.
/// `layering_rules.dart`'s `pickerRejectionViolations` scans the whole repo for
/// the four forms this rule takes; `security-review-b8b.md` § 12(a) S-2
/// restates it for this batch.
///
/// ## `FileType.image` WOULD ALSO DESTROY THE EXIF. Measured, in this package.
///
/// This is the sharper half of the rule and it is **not** in
/// `security-review-b8b.md`, which attributes the accidental-re-encode hazard to
/// `image_picker` alone (§ 4.2). It is in `file_picker` too, gated on one
/// argument. Read in `file_picker-8.3.7`:
///
/// 1. `lib/src/file_picker.dart:99` — `allowCompression` defaults **`true`**,
///    `compressionQuality` defaults **`30`**. Both are on without being asked
///    for.
/// 2. `lib/src/file_picker_io.dart:156` sends `"fileType": type.name`.
/// 3. `FilePickerPlugin.java:167-185` maps `"any"` → `"*/*"` and `"image"` →
///    `"image/*"`.
/// 4. `FilePickerDelegate.java:125`:
///    `if (Objects.equals(type, "image/*") && allowCompression && compressionQuality > 0)`
///    → `FileUtils.compressImage(…)`, which is
///    `BitmapFactory.decodeStream` followed by
///    `Bitmap.compress(JPEG, 30, …)` (`FileUtils.java:95-102`).
///
/// A `Bitmap` holds pixels and no APP1 segment, so **the citizen's GPS,
/// timestamp and device identifiers would be gone** — the exact outcome
/// `ADR-0001` and L-10(b) forbid the port from producing, arrived at by
/// accident.
///
/// **`FileType.any` is what makes the defaults inert**: `"*/*" != "image/*"`, so
/// the branch never fires. That is why the argument list below is not a style
/// choice, and why omitting `type:` is load-bearing for *metadata integrity* and
/// not only for accepting a `.pdf`.
///
/// **No test in this batch can see a regression here.** This function is never
/// executed by any test — the [AvatarFilePicker] seam exists so tests inject a
/// fake — so `tier0_avatar_payload_test.dart`'s byte-identity proof covers the
/// datasource, not the picker. `avatar_picker_scope_test.dart` scans this call's
/// **text** instead, and it is the only thing standing here. Recorded as
/// **FU-21** (`b8b-security-notes.md` § 2a); five certificate call sites are the
/// same one argument away from the same outcome.
///
/// ## What `withData: true` does and does not buy
///
/// It reads the bytes into the heap, which is what
/// `MultipartFile.fromBytes` needs. It does **not** avoid a disk copy:
/// `file_picker`'s `FileUtils.openFileStream` writes every picked file to
/// `getCacheDir()/file_picker/<millis>/<name>` (iOS: `NSTemporaryDirectory()`)
/// *unconditionally*, before `withData` is even consulted, and nothing in this
/// port calls `clearTemporaryFiles()`. That is `security-review-b8b.md`'s
/// `B8b-2` (MEDIUM), it is `file_picker`'s behaviour rather than B8b's, it has
/// been live on five certificate surfaces since F1, and **FU-16** owns the fix.
/// Named here because [PickedAvatar.path] is where a reader meets it.
Future<PickedAvatar?> pickAvatarFile() async {
  final FilePickerResult? result = await FilePicker.platform.pickFiles(
    withData: true,
  );
  final PlatformFile? file = result?.files.singleOrNull;
  if (file == null) return null;
  return PickedAvatar(
    name: file.name,
    bytes: file.bytes,
    path: file.path,
  );
}

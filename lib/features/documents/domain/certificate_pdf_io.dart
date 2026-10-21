/// The stored-PDF IO primitives — the device half of the file endpoint
/// (MOBILE-API-E-CERTIFICATES.md, 2026-10, § Citizen endpoints, File:
/// "store the bytes, and open them in the platform PDF viewer").
///
/// ## Why this lives in the domain layer, and why it resolves DI
///
/// The three sinks (`openPdfBytes`, `savePdfBytes`) and the integrity check
/// (`sha256Matches`) are pure device operations — no `data/` transport, no
/// `presentation/` widget — so the domain layer is where both the e-cert
/// widget (`lib/presentation/documents/`) and Task 7's verify slice can reach
/// them without a layering breach. G-L2 forbids `domain/` → `{data,
/// presentation}`; it does not forbid `domain/` → `di/`, and the fetch's
/// default (`fetchStoredCertificateFile`) resolves `DownloadCertificateFile`
/// through `documentsInjection` here for the same reason the plan's DI row
/// anticipated a wiring need: a `lib/presentation/**` widget is G-L5-blind to
/// every locator, and the alternative — threading a fetch closure from
/// `app_routes.dart` through the B5 seam — buys a third parameter the widget
/// test would have to fake anyway. The default keeps the widget pure; every
/// test injects its own fetch and never resolves the container.
///
/// ## Every platform edge is a parameter with a production default
///
/// `path_provider` (temp dir), `open_filex` (viewer handoff) and
/// `file_picker`'s save dialog run on device; a test injects the parameter and
/// no channel ever starts. The seams mirror `document_viewer.dart`'s
/// `DocumentSaver` typedef, which exists for exactly this reason.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/error/failure.dart';
import '../di/documents_injection.dart';
import '../domain/entities/certificate_file_download.dart';
import '../domain/entities/certificate_qr.dart';
import 'usecases/documents_usecases.dart';

/// Fetches one stored certificate file through Task 2's use case.
///
/// `inline: true` is the View path (`disposition=inline`, the guide's "view
/// instead of download"); `inline: false` is Download. The bearer token rides
/// the `Authorization` header inside the interceptor chain — never the URL.
typedef CertificateFileFetcher = Future<Either<Failure, CertificateFileDownload>>
    Function({
  required String id,
  required String layout,
  bool inline,
});

/// Opens `bytes` as `fileName` in the platform PDF viewer.
typedef CertificatePdfOpener = Future<void> Function(
  Uint8List bytes,
  String fileName,
);

/// Saves `bytes` under `fileName` through the platform save dialog. The
/// chosen path is discarded — the citizen's cancel is invisible too, exactly
/// as `DocumentViewer`'s save renders nothing on either outcome.
typedef CertificatePdfSaver = Future<void> Function(
  Uint8List bytes,
  String fileName,
);

/// `X-Content-SHA256` integrity — true unless the header is **present and
/// different**.
///
/// An absent, empty or blank header means "no recorded fingerprint" (a legacy
/// file whose bytes were never hashed) and the check **passes** — absence is
/// not mismatch, and failing it would brick every pre-hashing certificate.
/// Hex case and surrounding whitespace are the transport's, not the hash's,
/// so both are ignored before comparing.
bool sha256Matches(Uint8List bytes, String? headerHex) {
  if (headerHex == null) return true;
  final String expected = headerHex.trim().toLowerCase();
  if (expected.isEmpty) return true;
  return sha256.convert(bytes).toString() == expected;
}

/// The production temp directory — the cache dir, which needs no permission
/// and is per-app, matching "store the bytes".
Future<Directory> defaultCertificateTempDir() => getTemporaryDirectory();

/// The production handoff: `open_filex` resolves the PDF viewer from the
/// file's own type — no MIME is guessed here.
Future<void> defaultOpenPdf(String path) => OpenFilex.open(path);

/// The production save sink: the same `FilePicker.platform.saveFile` call
/// `document_viewer.dart`'s `saveDocumentFile` makes, which **requires**
/// `bytes` on Android and iOS. No type-filter argument is passed —
/// `F1-AC-44` bans them repo-wide.
Future<void> _defaultSavePdf(Uint8List bytes, String fileName) async {
  await FilePicker.platform.saveFile(fileName: fileName, bytes: bytes);
}

/// The basename of a wire-supplied filename, on every platform.
///
/// The `Content-Disposition` filename is server data an attacker can
/// influence only through the server, but it is still unvalidated wire
/// input joined into a filesystem path — `../../../etc/passwd` or `a/b.pdf`
/// must never escape the temp directory. The name is split on **both**
/// separators (the host's own and `/`, which a cross-platform payload can
/// carry on any host), empty parts and `..` are dropped, and the last
/// surviving part is taken. Empty result → the caller's inert fallback.
String sanitizePdfFileName(String fileName) {
  final List<String> parts = fileName
      .split('/')
      .expand((String part) => part.split(Platform.pathSeparator))
      .where((String part) => part.isNotEmpty && part != '..')
      .toList();
  return parts.isEmpty ? '' : parts.last;
}

/// View half: writes `bytes` under `fileName` in the (injectable) temp
/// directory, then hands **exactly that path** to the (injectable) platform
/// viewer. The written file is the guide's "store the bytes" step; the name
/// is the `Content-Disposition` filename the download record carries,
/// [sanitizePdfFileName]-stripped to a basename before the join.
Future<void> openPdfBytes(
  Uint8List bytes,
  String fileName, {
  Future<Directory> Function()? tempDir,
  Future<void> Function(String path)? open,
}) async {
  final Directory dir = await (tempDir ?? defaultCertificateTempDir)();
  String name = sanitizePdfFileName(fileName);
  if (name.isEmpty || name == '.') name = 'certificate.pdf';
  final File file = File(
    dir.path.endsWith(Platform.pathSeparator)
        ? '${dir.path}$name'
        : '${dir.path}${Platform.pathSeparator}$name',
  );
  await file.writeAsBytes(bytes, flush: true);
  await (open ?? defaultOpenPdf)(file.path);
}

/// Download half: the save dialog under the given name. The null answer (the
/// citizen cancelled) is discarded, exactly as `DocumentViewer`'s download
/// discards it — the web renders nothing on either outcome. The signature
/// matches [CertificatePdfSaver] exactly so the widget can bind it as its
/// default; tests inject at the widget, not here.
Future<void> savePdfBytes(Uint8List bytes, String fileName) async {
  await _defaultSavePdf(bytes, fileName);
}

/// The production fetch behind `CertificateFileActions.fetchStoredFile` —
/// Task 2's `DownloadCertificateFile` through the documents container.
Future<Either<Failure, CertificateFileDownload>> fetchStoredCertificateFile({
  required String id,
  required String layout,
  bool inline = false,
}) =>
    documentsInjection<DownloadCertificateFile>()(
      DownloadCertificateFileParams(id: id, layout: layout, inline: inline),
    );

/// The production QR fetch behind the viewer's conditional QR panel —
/// Task 2's `GetCertificateQr` through the same container, for the same
/// G-L5 reason as [fetchStoredCertificateFile]. Answers the endpoint's
/// `payload` (the link fixed at issue, per the guide's QR paragraph) or
/// null when the fetch fails or carries none — the panel draws nothing,
/// it does not error.
typedef CertificateQrFetcher = Future<String?> Function(String certificateId);

Future<String?> fetchCertificateQrPayload(String certificateId) async {
  final Either<Failure, CertificateQr> result =
      await documentsInjection<GetCertificateQr>()(
    GetCertificateParams(certificateId),
  );
  return result.fold(
    (Failure _) => null,
    (CertificateQr qr) =>
        (qr.payload != null && qr.payload!.isNotEmpty) ? qr.payload : null,
  );
}

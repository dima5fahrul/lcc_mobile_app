/// `CertificateFileDownload` — everything one PDF download yields: the bytes
/// plus the two response headers the file endpoint sends beside them
/// (MOBILE-API-E-CERTIFICATES.md, 2026-10, § Citizen endpoints, File).
///
/// A plain class, not freezed: [bytes] is a big mutable-ish `Uint8List` that
/// freezed's `==`/`hashCode` would try to deep-compare, and a download is
/// passed forward once — to the viewer or the file sink — never diffed.
///
/// ## The two optionals are the fallback contract
///
/// * [fileName] — from `Content-Disposition: attachment; filename="…"`.
///   Task 6 falls back to `<certificate_no>-<layout>.pdf` when null.
/// * [sha256Header] — from `X-Content-SHA256`, the hash of exactly these
///   bytes. Empty/null means "no recorded fingerprint" (a legacy
///   certificate), and the integrity check is skipped, not failed —
///   `sha256Matches` in the consuming task treats empty as pass.
///
/// The bearer token travels in the `Authorization` **header** (attached by
/// the interceptor chain), never in a URL — see
/// `certificate_file.dart` § The URL is kept relative.
library;

import 'dart:typed_data';

/// One downloaded certificate file.
class CertificateFileDownload {
  const CertificateFileDownload({
    required this.bytes,
    this.fileName,
    this.sha256Header,
  });

  /// The raw PDF bytes, exactly as the server sent them.
  final Uint8List bytes;

  /// The server's filename, parsed from `Content-Disposition`; null when the
  /// header is absent or carries no `filename=` parameter.
  final String? fileName;

  /// The `X-Content-SHA256` header — the hash of [bytes] — or null when the
  /// server sent none (a legacy file with no recorded fingerprint).
  final String? sha256Header;
}

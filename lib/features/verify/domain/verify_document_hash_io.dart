/// The on-device PDF check's two device-side primitives — hashing a file the
/// citizen picked, and running the hex through Task 3's
/// `POST /verify/document-hash` (MOBILE-API-E-CERTIFICATES.md, 2026-10,
/// § Checking a PDF on the device).
///
/// ## Why this lives in the domain layer, and why it resolves DI
///
/// Same `certificate_pdf_io.dart` reasoning, copied forward for Task 7:
/// [sha256HexOfBytes] is a pure device operation with no `data/` transport
/// and no `presentation/` widget, so it belongs in `domain/` where the verify
/// slice's page can reach it without a layering breach. G-L2 forbids
/// `domain/` → `{data, presentation}`; it does not forbid `domain/` → `di/`,
/// and [verifyDocumentHashByHash] resolves [VerifyDocumentHash] through
/// `verifyInjection` here for exactly the reason `fetchStoredCertificateFile`
/// does: a `lib/features/verify/presentation/**` file is G-L5-blind to every
/// locator (`layering_test.dart`'s table), so the production default a page
/// parameter needs has to be handed to it from outside `presentation/`. The
/// default keeps the PDF-check page pure; every test injects its own fetcher
/// and never touches the container.
///
/// ## The hash itself: chunked, not `sha256.convert(bytes)` in one call
///
/// The guide's own device samples (Android's `MessageDigest` loop, iOS's
/// `CryptoKit`) both feed a 64 KiB buffer rather than loading the whole file
/// into one call, and this mirrors that shape over the in-memory byte list
/// `file_picker` hands back (`withData: true`): `sha256.startChunkedConversion`
/// is fed 64 KiB slices and the digest is read off the sink's single capture
/// once `close()` has run, so a several-MB booklet PDF never has `convert`'s
/// entire call frame plus the hasher's own buffering alive at once. `Digest`
/// renders lower-case hex via its own `toString()` — the same reader
/// `certificate_pdf_io.dart`'s `sha256Matches` already relies on — so the
/// 64-char lower-case contract (§ Checking a PDF on the device, step 2) is
/// satisfied with no extra formatting step to get wrong.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';

import '../../../core/error/failure.dart';
import '../di/verify_injection.dart';
import 'entities/verification_result.dart';
import 'usecases/verify_usecases.dart';

/// Captures the one `Digest` [Hash.startChunkedConversion] emits on `close()`.
/// `crypto` keeps its own `DigestSink` private to `src/`, so this is the
/// smallest `Sink<Digest>` that can read it back out.
class _DigestCapture implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}

/// SHA-256 of [bytes], as 64 lower-case hex characters — exactly what
/// `POST /verify/document-hash`'s `{"hash": "<hex>"}` expects.
///
/// Feeds [sha256]'s chunked sink in 64 KiB slices rather than calling
/// `sha256.convert(bytes)` once; see the library doc for why that matters on
/// a multi-page certificate PDF.
String sha256HexOfBytes(List<int> bytes) {
  final _DigestCapture capture = _DigestCapture();
  final ByteConversionSink sink = sha256.startChunkedConversion(capture);

  const int chunkSize = 64 * 1024;
  for (int offset = 0; offset < bytes.length; offset += chunkSize) {
    final int end =
        (offset + chunkSize < bytes.length) ? offset + chunkSize : bytes.length;
    sink.add(bytes.sublist(offset, end));
  }
  sink.close();

  return capture.value.toString();
}

/// Calling [VerifyDocumentHash] with a hex digest, as a parameter — the
/// PDF-check page's seam, the same shape `CertificateFileFetcher` and its
/// siblings in `certificate_pdf_io.dart` take.
typedef VerifyDocumentHashFetcher = Future<Either<Failure, VerificationResult>>
    Function(String hash);

/// The production fetch behind the PDF-check page's default: Task 3's
/// `VerifyDocumentHash` through the verify container.
Future<Either<Failure, VerificationResult>> verifyDocumentHashByHash(
  String hash,
) =>
    verifyInjection<VerifyDocumentHash>()(hash);

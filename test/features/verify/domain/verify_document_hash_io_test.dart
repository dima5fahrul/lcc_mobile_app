/// `sha256HexOfBytes` — the device-side half of § Checking a PDF on the
/// device, step 2: "Compute SHA-256 and write it as 64 lower-case hex
/// characters."
///
/// `verifyDocumentHashByHash` is the one-line DI-resolving wrapper
/// `certificate_pdf_io_test.dart` leaves untested for the same reason: it is
/// a direct pass-through to `verifyInjection<VerifyDocumentHash>()`, and the
/// page test drives that contract by injecting its own
/// `VerifyDocumentHashFetcher` stub instead of booting the container.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/verify/domain/verify_document_hash_io.dart';

void main() {
  group('sha256HexOfBytes', () {
    test('the published NIST vector: "abc"', () {
      expect(
        sha256HexOfBytes(utf8.encode('abc')),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('the empty-string vector', () {
      expect(
        sha256HexOfBytes(const <int>[]),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('is exactly 64 lower-case hex characters', () {
      final String hex = sha256HexOfBytes(utf8.encode('a certificate PDF'));
      expect(hex.length, 64);
      expect(hex, hex.toLowerCase());
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hex), isTrue);
    });

    test('a buffer spanning many 64 KiB chunks matches sha256.convert '
        'computed in one call', () {
      // 3 chunks and a bit, so the chunking loop's last (short) slice is
      // exercised too — the exact shape a multi-page booklet PDF has.
      final Uint8List bytes = Uint8List.fromList(
        List<int>.generate(64 * 1024 * 3 + 777, (int i) => i % 256),
      );

      expect(sha256HexOfBytes(bytes), sha256.convert(bytes).toString());
    });

    test('a buffer exactly one chunk long', () {
      final Uint8List bytes = Uint8List(64 * 1024);
      expect(sha256HexOfBytes(bytes), sha256.convert(bytes).toString());
    });

    // ── Review M-5, 2026-10-22 ──────────────────────────────────────────────
    //
    // The function read `capture.value.toString()`, and `Digest?.toString()`
    // on a null answers the literal string `"null"` — so a sink that never
    // emitted would have POSTed `{"hash": "null"}` rather than refusing. It
    // now captures to a local and throws `StateError` instead.
    //
    // **The throw has NO direct test, and that is reported rather than faked.**
    // `crypto`'s `startChunkedConversion` always emits on `close()`, the sink
    // is a private class in this library, and there is no seam to hand it a
    // different one — so the branch is unreachable by construction. Widening
    // the public API to make an impossible case observable would be a worse
    // trade than this note. What IS asserted is the property the branch
    // protects: the output is a digest, never a sentinel.

    test('M-5 — the output is never the literal string "null"', () {
      for (final List<int> input in <List<int>>[
        const <int>[],
        <int>[0],
        utf8.encode('a certificate PDF'),
        List<int>.generate(64 * 1024 + 1, (int i) => i % 256),
      ]) {
        final String hex = sha256HexOfBytes(input);
        expect(hex, isNot('null'));
        expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hex), isTrue,
            reason: 'a non-digest answer of any shape is the defect — the '
                '64-hex contract is what the endpoint is promised');
      }
    });
  });
}

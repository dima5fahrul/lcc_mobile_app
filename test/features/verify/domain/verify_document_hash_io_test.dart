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
  });
}

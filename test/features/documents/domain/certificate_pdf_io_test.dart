/// `certificate_pdf_io.dart` — the stored-PDF IO primitives the e-certificates
/// View/Download actions run through (2026-10 guide § Citizen endpoints, File:
/// "store the bytes, and open them in the platform PDF viewer").
///
/// The integrity vector is the standard NIST SHA-256 vector for `abc`, so the
/// `crypto` wiring is pinned against a published answer rather than against
/// itself. The temp-file case injects **both** the directory accessor and the
/// opener — no platform channel (`path_provider`, `open_filex`) ever runs in a
/// test.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/documents/domain/certificate_pdf_io.dart';

void main() {
  group('sha256Matches', () {
    // NIST SHA-256 vector for "abc".
    const String kAbcSha =
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';
    final Uint8List abc = Uint8List.fromList(<int>[97, 98, 99]);

    test('true when the header is the hash of exactly these bytes', () {
      expect(sha256Matches(abc, kAbcSha), isTrue);
    });

    test('false when one byte differs', () {
      final Uint8List abd = Uint8List.fromList(<int>[97, 98, 100]);
      expect(sha256Matches(abd, kAbcSha), isFalse);
    });

    test('an EMPTY header means no recorded fingerprint — the check passes',
        () {
      // The interface contract: `sha256Header` empty (a legacy file whose
      // bytes were never hashed) is *absence*, not mismatch.
      expect(sha256Matches(abc, ''), isTrue);
    });

    test('a null header behaves as empty — the download record is nullable',
        () {
      expect(sha256Matches(abc, null), isTrue);
    });

    test('hex case and surrounding whitespace are ignored', () {
      expect(sha256Matches(abc, ' ${kAbcSha.toUpperCase()} '), isTrue);
    });
  });

  group('openPdfBytes', () {
    test('writes the bytes under the given name in the injected directory, '
        'then hands exactly that file path to the platform viewer', () async {
      final Directory dir =
          await Directory.systemTemp.createTemp('cert_pdf_io_test');
      addTearDown(() => dir.delete(recursive: true));

      final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3]);
      final List<String> opened = <String>[];

      await openPdfBytes(
        bytes,
        'LA-MAR-2026-000652-card.pdf',
        tempDir: () async => dir,
        open: (String path) async => opened.add(path),
      );

      final File written = File('${dir.path}/LA-MAR-2026-000652-card.pdf');
      expect(written.existsSync(), isTrue,
          reason: 'the store half — the temp file carries the given name');
      expect(written.readAsBytesSync(), equals(bytes),
          reason: 'the bytes on disk are the bytes downloaded, unmodified');
      expect(opened, <String>[written.path],
          reason: 'the open half receives exactly the written file');
    });
  });
}

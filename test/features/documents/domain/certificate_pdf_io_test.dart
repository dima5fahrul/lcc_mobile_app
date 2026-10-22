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

    test('M-1 — a traversal filename lands inside the temp dir as its '
        'basename', () async {
      final Directory dir =
          await Directory.systemTemp.createTemp('cert_pdf_io_test');
      addTearDown(() => dir.delete(recursive: true));

      final List<String> opened = <String>[];
      await openPdfBytes(
        Uint8List.fromList(<int>[1]),
        '../../../etc/passwd',
        tempDir: () async => dir,
        open: (String path) async => opened.add(path),
      );

      expect(opened.single, '${dir.path}/passwd',
          reason: 'the Content-Disposition filename is attacker-influenced '
              'wire data; every path component is stripped before the join');
      expect(File('${dir.path}/passwd').existsSync(), isTrue);
    });

    test('M-1 — a nested filename keeps the basename only', () async {
      final Directory dir =
          await Directory.systemTemp.createTemp('cert_pdf_io_test');
      addTearDown(() => dir.delete(recursive: true));

      final List<String> opened = <String>[];
      await openPdfBytes(
        Uint8List.fromList(<int>[1]),
        'a/b.pdf',
        tempDir: () async => dir,
        open: (String path) async => opened.add(path),
      );

      expect(opened.single, '${dir.path}/b.pdf');
      expect(Directory('${dir.path}/a').existsSync(), isFalse);
    });

    test('M-1 — a name that reduces to nothing becomes an inert fallback',
        () async {
      final Directory dir =
          await Directory.systemTemp.createTemp('cert_pdf_io_test');
      addTearDown(() => dir.delete(recursive: true));

      final List<String> opened = <String>[];
      await openPdfBytes(
        Uint8List.fromList(<int>[1]),
        '..',
        tempDir: () async => dir,
        open: (String path) async => opened.add(path),
      );

      expect(opened.single, startsWith('${dir.path}/'),
          reason: 'never the directory itself — a fallback name instead');
    });
  });

  // ── Review M-2, 2026-10-22 — the SAVE half sanitises too ──────────────────
  //
  // `savePdfBytes` handed the wire's `Content-Disposition` filename to
  // `FilePicker.saveFile` verbatim while `openPdfBytes` above stripped it, so
  // one of the two halves of the same header was defended and the other was
  // not.

  group('savePdfBytes', () {
    test('the server filename reaches the save dialog unchanged when it is '
        'already a plain basename', () async {
      final List<String> saved = <String>[];
      await savePdfBytes(
        Uint8List.fromList(<int>[1, 2, 3]),
        'LA-MAR-2026-000652-booklet.pdf',
        save: (Uint8List _, String name) async => saved.add(name),
      );

      expect(saved, <String>['LA-MAR-2026-000652-booklet.pdf']);
    });

    test('M-2 — a traversal or nested filename is reduced to its basename',
        () async {
      for (final (String given, String want) in <(String, String)>[
        ('../../../etc/passwd', 'passwd'),
        ('a/b.pdf', 'b.pdf'),
        ('../../x.pdf', 'x.pdf'),
      ]) {
        final List<String> saved = <String>[];
        await savePdfBytes(
          Uint8List.fromList(<int>[1]),
          given,
          save: (Uint8List _, String name) async => saved.add(name),
        );
        expect(saved, <String>[want], reason: given);
      }
    });

    test('M-2 — a name that reduces to nothing becomes the same inert '
        'fallback the View path uses', () async {
      for (final String given in <String>['..', '', '/', '.']) {
        final List<String> saved = <String>[];
        await savePdfBytes(
          Uint8List.fromList(<int>[1]),
          given,
          save: (Uint8List _, String name) async => saved.add(name),
        );
        expect(saved, <String>['certificate.pdf'], reason: 'given "$given"');
      }
    });

    test('the bytes are passed through untouched', () async {
      final Uint8List bytes = Uint8List.fromList(<int>[9, 8, 7]);
      final List<Uint8List> seen = <Uint8List>[];
      await savePdfBytes(
        bytes,
        'x.pdf',
        save: (Uint8List b, String _) async => seen.add(b),
      );

      expect(seen.single, same(bytes),
          reason: 'sanitising the NAME must not re-encode the FILE — the '
              'bytes are what verification hashes');
    });
  });
}

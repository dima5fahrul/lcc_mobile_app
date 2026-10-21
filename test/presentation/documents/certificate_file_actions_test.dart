/// `CertificateFileActions` — the per-`files[]` *View* / *Download* pair the
/// 2026-10 guide's File paragraph requires beside the legacy faux-PDF row
/// (`renderDocumentPdf`), which stays untouched for rows without `files[]`.
///
/// Everything platform-reaching is injected: the fetch answers a scripted
/// `Either<Failure, CertificateFileDownload>`, the sinks record. No platform
/// channel (`OpenFilex`, `FilePicker`, `path_provider`) ever runs here.
library;

import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/documents/domain/entities/certificate_file.dart';
import 'package:lcc_mobile_app/features/documents/domain/entities/certificate_file_download.dart';
import 'package:lcc_mobile_app/features/documents/domain/entities/issued_certificate.dart';
import 'package:lcc_mobile_app/presentation/documents/document_actions_row.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';

import '../../features/documents/documents_test_helper.dart';
import '../../helpers/app_test_harness.dart';

/// NIST SHA-256 of `abc` — the fingerprint `DownloadCertificateFile`'s
/// `X-Content-SHA256` header carries in the matched fixture.
const String kAbcSha =
    'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';

/// A scripted fetch: each call pops the next answer.
typedef ScriptedFetch = Future<Either<Failure, CertificateFileDownload>>
    Function({required String id, required String layout, bool inline});

class _RecordingSinks {
  final List<String> opened = <String>[];
  final List<String> saved = <String>[];

  Future<void> open(Uint8List bytes, String fileName) async =>
      opened.add(fileName);

  Future<void> save(Uint8List bytes, String fileName) async =>
      saved.add(fileName);
}

void main() {
  Future<_RecordingSinks> pumpActions(
    WidgetTester tester, {
    required ScriptedFetch fetch,
    IssuedCertificate? certificate,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    final _RecordingSinks sinks = _RecordingSinks();
    await tester.pumpWidget(wrapWithLocalization(
      startLocale: locale,
      Builder(
        builder: (BuildContext context) => MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: Scaffold(
            body: CertificateFileActions(
              certificate: certificate ?? certFixture(),
              fetchStoredFile: fetch,
              openPdf: sinks.open,
              savePdf: sinks.save,
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    return sinks;
  }

  IssuedCertificate twoFiles() => certFixture().copyWith(
        files: <CertificateFile>[
          const CertificateFile(
              layout: 'card', url: '/f/card', sha256: kAbcSha),
          const CertificateFile(
              layout: 'booklet', url: '/f/booklet', sha256: kAbcSha),
        ],
      );

  /// A right answer whose bytes hash to [kAbcSha], with the server filename.
  Either<Failure, CertificateFileDownload> okFile({
    String? fileName = 'LA-MAR-2026-000652-card.pdf',
    String? sha256Header = kAbcSha,
  }) =>
      Right<Failure, CertificateFileDownload>(CertificateFileDownload(
        bytes: Uint8List.fromList(<int>[97, 98, 99]),
        fileName: fileName,
        sha256Header: sha256Header,
      ));

  group('the per-layout buttons', () {
    testWidgets('two files render two View and two Download buttons',
        (WidgetTester tester) async {
      await pumpActions(tester,
          certificate: twoFiles(),
          fetch: ({required id, required layout, inline = false}) async =>
              okFile());

      expect(find.text('View document'), findsNWidgets(2));
      expect(find.text('Download document'), findsNWidgets(2));
    });

    testWidgets('hasStoredFile == false renders nothing at all',
        (WidgetTester tester) async {
      await pumpActions(tester,
          certificate: certFixture().copyWith(files: const <CertificateFile>[]),
          fetch: ({required id, required layout, inline = false}) async =>
              okFile());

      expect(find.text('View document'), findsNothing);
      expect(find.text('Download document'), findsNothing);
    });

    testWidgets('a null certificate renders nothing',
        (WidgetTester tester) async {
      await pumpActions(tester,
          certificate: null,
          fetch: ({required id, required layout, inline = false}) async =>
              okFile());

      expect(find.text('View document'), findsNothing);
      expect(find.text('Download document'), findsNothing);
    });
  });

  group('View — disposition=inline, then the platform viewer', () {
    testWidgets('fetches inline for the tapped layout, opens with the '
        'server filename', (WidgetTester tester) async {
      final List<String> layouts = <String>[];
      final List<bool> inlineFlags = <bool>[];
      final _RecordingSinks sinks = await pumpActions(tester,
          certificate: twoFiles(),
          fetch: ({required id, required layout, inline = false}) async {
            layouts.add(layout);
            inlineFlags.add(inline);
            return okFile();
          });

      await _tapAndDrain(tester, find.text('View document').first);

      expect(layouts, <String>['card'],
          reason: 'the tapped file is fetched by its own layout');
      expect(inlineFlags, <bool>[true],
          reason: 'View is disposition=inline (guide § File)');
      expect(sinks.opened, <String>['LA-MAR-2026-000652-card.pdf'],
          reason: 'the Content-Disposition filename reaches the viewer path');
    });
  });

  group('Download — integrity gate', () {
    testWidgets('matching hash saves under the server filename',
        (WidgetTester tester) async {
      final _RecordingSinks sinks = await pumpActions(tester,
          certificate: twoFiles(),
          fetch: ({required id, required layout, inline = false}) async =>
              okFile());

      await _tapAndDrain(tester, find.text('Download document').first);

      expect(sinks.saved, <String>['LA-MAR-2026-000652-card.pdf']);
      expect(sinks.opened, isEmpty,
          reason: 'Download never opens the viewer');
    });

    testWidgets('no server filename falls back to '
        '<certificate_no>-<layout>.pdf', (WidgetTester tester) async {
      final _RecordingSinks sinks = await pumpActions(tester,
          certificate: twoFiles(),
          fetch: ({required id, required layout, inline = false}) async =>
              okFile(fileName: null));

      await _tapAndDrain(tester, find.text('Download document').first);

      expect(sinks.saved, <String>['CERT-0001-card.pdf']);
    });

    testWidgets('a MISMATCHED hash surfaces verify.integrityFailed and '
        'saves nothing', (WidgetTester tester) async {
      final _RecordingSinks sinks = await pumpActions(tester,
          certificate: twoFiles(),
          fetch: ({required id, required layout, inline = false}) async =>
              okFile(sha256Header:
                  'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef'));

      await _tapAndDrain(tester, find.text('Download document').first);

      expect(sinks.saved, isEmpty, reason: 'the gate runs before any sink');
      expect(sinks.opened, isEmpty);
      expect(find.text('Integrity check failed'), findsOneWidget,
          reason: 'verify.integrityFailed, the snackbar the gate surfaces');
    });

    testWidgets('an EMPTY hash header is absence, not mismatch — the save '
        'proceeds', (WidgetTester tester) async {
      final _RecordingSinks sinks = await pumpActions(tester,
          certificate: twoFiles(),
          fetch: ({required id, required layout, inline = false}) async =>
              okFile(sha256Header: ''));

      await _tapAndDrain(tester, find.text('Download document').first);

      expect(sinks.saved, hasLength(1));
    });

    testWidgets('a fetch Failure surfaces the server message, opens nothing',
        (WidgetTester tester) async {
      final _RecordingSinks sinks = await pumpActions(tester,
          certificate: twoFiles(),
          fetch: ({required id, required layout, inline = false}) async =>
              Left<Failure, CertificateFileDownload>(
                  const Failure('certificate file not found')));

      await _tapAndDrain(tester, find.text('Download document').first);

      expect(sinks.saved, isEmpty);
      expect(sinks.opened, isEmpty);
      expect(find.text('certificate file not found'), findsOneWidget);
    });
  });

  group('the Lao arm', () {
    testWidgets('verify.integrityFailed renders in Lao',
        (WidgetTester tester) async {
      await pumpActions(
        tester,
        locale: const Locale('lo'),
        certificate: twoFiles(),
        fetch: ({required id, required layout, inline = false}) async =>
            okFile(sha256Header:
                'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef'),
      );

      await _tapAndDrain(tester, find.text('ດາວໂຫຼດເອກະສານ').first);

      expect(find.text('ກວດສອບຄວາມຖືກຕ້ອງຂອງໄຟລ໌ບໍ່ສຳເລັດ'), findsOneWidget);
    });
  });
}

Future<void> _tapAndDrain(WidgetTester tester, Finder target) async {
  await tester.tap(target);
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 400)),
  );
  await tester.pump();
}

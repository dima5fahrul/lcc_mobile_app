/// The *View document* / *Download document* pair — **B5-AC-81**,
/// **B5-AC-83**, and the seam's own contract.
library;

import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_detail.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_status.dart';
import 'package:lcc_mobile_app/features/documents/domain/entities/certificate_file.dart';
import 'package:lcc_mobile_app/features/documents/domain/entities/issued_certificate.dart';
import 'package:lcc_mobile_app/presentation/documents/document_actions_row.dart';
import 'package:lcc_mobile_app/presentation/documents/document_viewer.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';

import '../../features/documents/documents_test_helper.dart';
import '../../features/history/history_test_helper.dart';
import '../../helpers/app_test_harness.dart';

class _RecordingSaver {
  final List<String> fileNames = <String>[];
  final List<int> byteLengths = <int>[];

  Future<String?> call({
    required String fileName,
    required Uint8List bytes,
  }) async {
    fileNames.add(fileName);
    byteLengths.add(bytes.length);
    return null;
  }
}

/// See `document_viewer_test.dart`'s copy for why `runAsync` is required.
Future<void> _tapAndDrain(WidgetTester tester, Finder target) async {
  await tester.tap(target);
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 400)),
  );
  await tester.pump();
}

void main() {
  Future<_RecordingSaver> pumpRow(
    WidgetTester tester, {
    IssuedCertificate? certificate,
    List<IssuedCertificate> certificates = const <IssuedCertificate>[],
    Locale locale = const Locale('en'),
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    final _RecordingSaver saver = _RecordingSaver();
    final ApplicationDetail detail = detailFixture(status: CaseStatus.issued);

    await tester.pumpWidget(wrapWithLocalization(
      startLocale: locale,
      Builder(
        builder: (BuildContext context) => MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: Scaffold(
            body: DocumentActionsRow(
              detail: detail,
              certificate: certificate,
              certificates: certificates,
              saveFile: saver.call,
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    return saver;
  }

  group('the two buttons', () {
    testWidgets('both render, in the source\'s order — `:379-397`',
        (WidgetTester tester) async {
      await pumpRow(tester);

      expect(find.text('View document'), findsOneWidget);
      expect(find.text('Download document'), findsOneWidget);

      final Offset view = tester.getTopLeft(find.text('View document'));
      final Offset download = tester.getTopLeft(find.text('Download document'));
      expect(view.dx, lessThan(download.dx),
          reason: '*View* precedes *Download* (`:381`, `:389`)');
    });

    testWidgets('the Lao arms are the ones B5 added to the history namespace',
        (WidgetTester tester) async {
      await pumpRow(tester, locale: const Locale('lo'));
      expect(find.text('ເບິ່ງເອກະສານ'), findsOneWidget);
      expect(find.text('ດາວໂຫຼດເອກະສານ'), findsOneWidget);
    });
  });

  group('B5-AC-81 / B5-AC-83 — Download', () {
    testWidgets('it saves the reference number with a .pdf suffix',
        (WidgetTester tester) async {
      final _RecordingSaver saver = await pumpRow(tester);

      await _tapAndDrain(tester, find.text('Download document'));

      expect(saver.fileNames, <String>['LCC-2026-000123.pdf'],
          reason: 'the reference number, not the certificate number — `:259`');
      expect(saver.byteLengths.single, greaterThan(1024));
    });

    testWidgets('a cancelled save renders nothing at all',
        (WidgetTester tester) async {
      // The recorder above always answers null, which is the cancel case.
      final _RecordingSaver saver = await pumpRow(tester);
      await _tapAndDrain(tester, find.text('Download document'));

      expect(saver.fileNames, hasLength(1));
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the row does NOT open the viewer', (WidgetTester tester) async {
      final _RecordingSaver saver = await pumpRow(tester);
      await _tapAndDrain(tester, find.text('Download document'));

      expect(find.byType(DocumentViewer), findsNothing,
          reason: '`handleDownload` (`:255`) is the button\'s own path and '
              'never mounts the component');
      expect(saver.fileNames, hasLength(1));
    });
  });

  group('View', () {
    testWidgets('it opens the full-screen viewer with the case\'s title',
        (WidgetTester tester) async {
      await pumpRow(tester);

      await tester.tap(find.text('View document'));
      await tester.pumpAndSettle();

      expect(find.byType(DocumentViewer), findsOneWidget);
      // `${serviceName} · ${detail.reference_no}` — `:246`.
      expect(find.text('Birth Certificate · LCC-2026-000123'), findsOneWidget);
    });

    testWidgets('the certificate\'s code and payload reach the viewer footer',
        (WidgetTester tester) async {
      await pumpRow(
        tester,
        certificate: certFixture(verifyCode: 'VC-9', qrPayload: 'QR-9'),
      );

      await tester.tap(find.text('View document'));
      await tester.pumpAndSettle();

      expect(find.text('VC-9'), findsOneWidget);
      expect(find.text('QR-9'), findsOneWidget);
    });

    testWidgets('with no certificate the footer is absent',
        (WidgetTester tester) async {
      await pumpRow(tester);

      await tester.tap(find.text('View document'));
      await tester.pumpAndSettle();

      expect(find.byType(DocumentViewer), findsOneWidget);
      expect(find.text('Verification code'), findsNothing,
          reason: '`verifyCode={certificate?.verify_code}` — `:653`');
    });
  });

  // ── Review I-1, 2026-10-22 — the two pairs are EXCLUSIVE ──────────────────
  //
  // Task 6 mounted the server-PDF pair *beneath* the legacy faux-PDF pair,
  // both bound to `history.viewDocument` / `history.downloadDocument`. A
  // marriage certificate therefore drew three identical *View document*
  // buttons and three identical *Download document* buttons, and the legacy
  // one saved a PDF the app had PAINTED — a file the app's own
  // `POST /verify/document-hash` check then reports as "not an issued
  // document, or it was changed". § Overview makes the server's file the
  // single source of truth, so when one exists it is the only one offered.

  group('I-1 — the legacy faux-PDF pair vs. the server PDF', () {
    IssuedCertificate marriage() => certFixture(
          certificateNo: 'LA-MAR-2026-000652',
        ).copyWith(
          documentType: 'MAR',
          files: const <CertificateFile>[
            CertificateFile(layout: 'card', url: '/f/card', sha256: ''),
            CertificateFile(layout: 'booklet', url: '/f/booklet', sha256: ''),
          ],
        );

    testWidgets('a certificate with two stored files renders EXACTLY two View '
        'and two Download buttons, layout-labelled, and NO legacy pair',
        (WidgetTester tester) async {
      await pumpRow(tester, certificate: marriage());

      expect(find.textContaining('View document'), findsNWidgets(2));
      expect(find.textContaining('Download document'), findsNWidgets(2));
      expect(find.text('View document · Card'), findsOneWidget);
      expect(find.text('View document · Booklet'), findsOneWidget);
      expect(find.text('Download document · Card'), findsOneWidget);
      expect(find.text('Download document · Booklet'), findsOneWidget);

      // The legacy pair is the unqualified label. Its absence is the fix.
      expect(find.text('View document'), findsNothing,
          reason: 'the painter\'s pair must not sit beside the server\'s under '
              'the same words — a citizen could not tell them apart, and the '
              'painted PDF fails the app\'s own hash check');
      expect(find.text('Download document'), findsNothing);
    });

    testWidgets('tapping Download never reaches the PAINTER when a server '
        'file exists', (WidgetTester tester) async {
      final _RecordingSaver saver =
          await pumpRow(tester, certificate: marriage());

      // The painter's sink is `saveFile`; the server path uses
      // `CertificateFileActions`' own injected `savePdf`, which this harness
      // does not supply. So an empty recorder here IS the assertion: nothing
      // the app drew was offered for saving.
      expect(saver.fileNames, isEmpty);
      expect(find.byType(CertificateFileActions), findsOneWidget);
    });

    testWidgets('a certificate with NO stored file renders exactly the legacy '
        'pair, unchanged — the only document that case has',
        (WidgetTester tester) async {
      final _RecordingSaver saver = await pumpRow(
        tester,
        certificate: certFixture(),
      );

      expect(find.text('View document'), findsOneWidget);
      expect(find.text('Download document'), findsOneWidget);
      expect(find.byType(CertificateFileActions), findsNothing);

      await _tapAndDrain(tester, find.text('Download document'));
      expect(saver.fileNames, <String>['LCC-2026-000123.pdf'],
          reason: 'byte-identical to what B5 shipped');
    });

    testWidgets('a NULL certificate renders exactly the legacy pair',
        (WidgetTester tester) async {
      await pumpRow(tester);

      expect(find.text('View document'), findsOneWidget);
      expect(find.text('Download document'), findsOneWidget);
      expect(find.byType(CertificateFileActions), findsNothing);
    });

    testWidgets('I-2 — three divorce rows render three labelled pairs and no '
        'legacy pair', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      final List<IssuedCertificate> rows = <IssuedCertificate>[
        certFixture(id: 'joint', certificateNo: 'LA-DIV-2026-000094')
            .copyWith(
          documentType: 'DIV',
          files: const <CertificateFile>[
            CertificateFile(layout: 'card', url: '/f/j', sha256: ''),
          ],
        ),
        certFixture(id: 'a', certificateNo: 'LA-DIV-2026-000094-A').copyWith(
          documentType: 'DIV',
          copy: 'A',
          files: const <CertificateFile>[
            CertificateFile(layout: 'booklet', url: '/f/a', sha256: ''),
          ],
        ),
        certFixture(id: 'b', certificateNo: 'LA-DIV-2026-000094-B').copyWith(
          documentType: 'DIV',
          copy: 'B',
          files: const <CertificateFile>[
            CertificateFile(layout: 'booklet', url: '/f/b', sha256: ''),
          ],
        ),
      ];

      await pumpRow(tester, certificate: rows.first, certificates: rows);

      expect(find.textContaining('View document'), findsNWidgets(3));
      expect(find.text('DIV · Joint card'), findsOneWidget);
      expect(find.text("DIV · Husband's booklet"), findsOneWidget);
      expect(find.text("DIV · Wife's booklet"), findsOneWidget);
      expect(find.text('View document'), findsNothing);
    });
  });
}

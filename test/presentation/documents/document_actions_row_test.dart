/// The *View document* / *Download document* pair — **B5-AC-81**,
/// **B5-AC-83**, and the seam's own contract.
library;

import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_detail.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_status.dart';
import 'package:lcc_mobile_app/features/documents/di/documents_injection.dart';
import 'package:lcc_mobile_app/features/documents/domain/entities/certificate_file.dart';
import 'package:lcc_mobile_app/features/documents/domain/entities/certificate_file_download.dart';
import 'package:lcc_mobile_app/features/documents/domain/entities/issued_certificate.dart';
import 'package:lcc_mobile_app/features/documents/domain/usecases/documents_usecases.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';
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

/// Records every stored-file fetch and answers the guide's own 404 sentence.
///
/// `DocumentActionsRow` builds `CertificateFileActions` itself, with that
/// widget's **production** `fetchStoredFile` default — which resolves
/// `DownloadCertificateFile` out of `documentsInjection`
/// (`certificate_pdf_io.dart`). A test that wants to TAP a server-file button
/// through the row therefore has to register that use case, which is what the
/// one case below does.
///
/// The answer is a `Left` on purpose: `CertificateFileActionsState._run`
/// surfaces the failure's own sentence in a snackbar and returns **before**
/// `savePdf`, so the real server path runs end to end and no platform channel
/// (`FilePicker`, `path_provider`, `open_filex`) is ever reached.
class _RecordingFileRepo extends FakeDocumentsRepository {
  /// One `id/layout/inline=…` per call, in order.
  final List<String> downloads = <String>[];

  @override
  Future<Either<Failure, CertificateFileDownload>> downloadCertificateFile({
    required String id,
    required String layout,
    bool inline = false,
  }) async {
    downloads.add('$id/$layout/inline=$inline');
    return Left<Failure, CertificateFileDownload>(
      const Failure('certificate file not found'),
    );
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

    // **Review residual, 2026-10-22 — this case used to assert nothing.** It
    // pumped the row and checked that `saver.fileNames` was empty, which an
    // untouched recorder satisfies vacuously: no tap ever happened, so the
    // test passed whatever the production code did. It now performs the tap
    // its own name claims, and the two halves of the property are asserted
    // together — the server fetch FIRED, and the painter's sink did not.
    testWidgets('tapping Download never reaches the PAINTER when a server '
        'file exists — it reaches the SERVER fetch instead',
        (WidgetTester tester) async {
      final _RecordingFileRepo repo = _RecordingFileRepo();
      documentsInjection.registerFactory<DownloadCertificateFile>(
        () => DownloadCertificateFile(repository: repo),
      );
      addTearDown(documentsInjection.reset);

      final _RecordingSaver saver =
          await pumpRow(tester, certificate: marriage());
      expect(find.byType(CertificateFileActions), findsOneWidget);

      await _tapAndDrain(tester, find.text('Download document · Card'));

      // The server path ran: the tapped row's own id and layout reached the
      // file endpoint's use case, as a download (`inline=false`).
      expect(repo.downloads, <String>['cert-1/card/inline=false'],
          reason: 'the tap must land on the SERVER file, which is the only '
              'document § Overview makes authoritative');
      // And the painter's sink — `DocumentActionsRow.saveFile`, the legacy
      // faux-PDF path — stayed untouched. This is the half the old vacuous
      // assertion only appeared to make.
      expect(saver.fileNames, isEmpty,
          reason: 'nothing the app DREW was offered for saving');
      expect(saver.byteLengths, isEmpty);
      expect(find.byType(DocumentViewer), findsNothing);
      expect(tester.takeException(), isNull);
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

    /// The spec's § Divorce arrangement, with the bilingual `service` object a
    /// v2 row carries (§ Citizen endpoints, List). [service] is nullable so
    /// the same builder covers the v2 row and the legacy row that sends none.
    List<IssuedCertificate> divorceRows({
      Bilingual? service = const Bilingual(
        en: 'Divorce Certificate',
        lo: 'ໃບຢັ້ງຢືນການຢ່າຮ້າງ',
      ),
    }) =>
        <IssuedCertificate>[
          certFixture(id: 'joint', certificateNo: 'LA-DIV-2026-000094')
              .copyWith(
            serviceName: service,
            documentType: 'DIV',
            files: const <CertificateFile>[
              CertificateFile(layout: 'card', url: '/f/j', sha256: ''),
            ],
          ),
          certFixture(id: 'a', certificateNo: 'LA-DIV-2026-000094-A').copyWith(
            serviceName: service,
            documentType: 'DIV',
            copy: 'A',
            files: const <CertificateFile>[
              CertificateFile(layout: 'booklet', url: '/f/a', sha256: ''),
            ],
          ),
          certFixture(id: 'b', certificateNo: 'LA-DIV-2026-000094-B').copyWith(
            serviceName: service,
            documentType: 'DIV',
            copy: 'B',
            files: const <CertificateFile>[
              CertificateFile(layout: 'booklet', url: '/f/b', sha256: ''),
            ],
          ),
        ];

    testWidgets('I-2 — three divorce rows render three labelled pairs and no '
        'legacy pair', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      final List<IssuedCertificate> rows = divorceRows();

      await pumpRow(tester, certificate: rows.first, certificates: rows);

      expect(find.textContaining('View document'), findsNWidgets(3));
      // The human-facing half is the bilingual `service`, not the `DIV` wire
      // code — review, 2026-10-22.
      expect(find.text('Divorce Certificate · Joint card'), findsOneWidget);
      expect(
          find.text("Divorce Certificate · Husband's booklet"), findsOneWidget);
      expect(find.text("Divorce Certificate · Wife's booklet"), findsOneWidget);
      expect(find.textContaining('DIV'), findsNothing);
      expect(find.text('View document'), findsNothing);
    });

    testWidgets('a Lao reader gets the Lao arm of `service`, never `DIV`',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      final List<IssuedCertificate> rows = divorceRows();

      await pumpRow(
        tester,
        certificate: rows.first,
        certificates: rows,
        locale: const Locale('lo'),
      );

      expect(find.text('ໃບຢັ້ງຢືນການຢ່າຮ້າງ · ບັດຮ່ວມ'), findsOneWidget);
      expect(find.textContaining('DIV'), findsNothing,
          reason: 'the defect this fixes: `DIV · ບັດຮ່ວມ` is half a sentence '
              'and half an enum');
    });

    testWidgets('with NO `service` the heading falls back to document_type',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      final List<IssuedCertificate> rows = divorceRows(service: null);

      await pumpRow(tester, certificate: rows.first, certificates: rows);

      expect(find.text('DIV · Joint card'), findsOneWidget);
      expect(find.text("DIV · Husband's booklet"), findsOneWidget);
      expect(find.text("DIV · Wife's booklet"), findsOneWidget);
    });
  });
}

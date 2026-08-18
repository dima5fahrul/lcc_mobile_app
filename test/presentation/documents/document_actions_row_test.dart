/// The *View document* / *Download document* pair — **B5-AC-81**,
/// **B5-AC-83**, and the seam's own contract.
library;

import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_detail.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_status.dart';
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
}

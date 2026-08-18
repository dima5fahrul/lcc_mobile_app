/// The viewer — **B5-AC-77** … **B5-AC-85**, and **B5-AC-88**.
///
/// Most of these are **negative**: three of `DocumentViewer.tsx`'s five render
/// branches cannot fire in the shipped web app, so porting them would be a
/// MAJOR fidelity defect under `ssd.md` § 11.2 L-10 corollary (b). A negative
/// claim about a widget is only worth something if the widget is actually
/// mounted and rendering, so every group below pumps it first and then asserts
/// what is *not* there.
library;

import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/documents/domain/entities/doc_spec.dart';
import 'package:lcc_mobile_app/presentation/documents/document_viewer.dart';
import 'package:lcc_mobile_app/presentation/theme/app_colors.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';

import '../../helpers/app_test_harness.dart';
import 'document_page_painter_test.dart' show kFixedSpec, kPinnedVerifyCode;

/// A recording sink. `null` is the citizen cancelling the save dialog.
class _RecordingSaver {
  _RecordingSaver({this.answer = '/tmp/RES-0001.pdf'});

  final String? answer;
  final List<String> fileNames = <String>[];
  final List<int> byteLengths = <int>[];

  Future<String?> call({
    required String fileName,
    required Uint8List bytes,
  }) async {
    fileNames.add(fileName);
    byteLengths.add(bytes.length);
    return answer;
  }
}

/// Taps *Download* and lets the **real** async complete.
///
/// `renderDocumentPdf` awaits `ui.Picture.toImage`, which is driven by the
/// engine and not by `FakeAsync` — inside a plain `testWidgets` body that
/// future never resolves and the save is never issued. Measured: the first cut
/// of these three cases asserted an empty recorder and would have "passed" a
/// download path that did nothing. `runAsync` is what makes the assertion real.
Future<void> _tapDownload(WidgetTester tester) async {
  await tester.tap(find.text('Download'));
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 400)),
  );
  await tester.pump();
}

void main() {
  Future<void> pumpViewer(
    WidgetTester tester, {
    String? verifyCode,
    String? qrPayload,
    DocSpec spec = kFixedSpec,
    _RecordingSaver? saver,
    VoidCallback? onClose,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrapWithLocalization(
      startLocale: locale,
      Builder(
        builder: (BuildContext context) => MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: Scaffold(
            body: DocumentViewer(
              title: 'Residence Certificate · LCC-2026-000123',
              spec: spec,
              downloadName: 'LCC-2026-000123.pdf',
              verifyCode: verifyCode,
              qrPayload: qrPayload,
              onClose: onClose ?? () {},
              saveFile: (saver ?? _RecordingSaver()).call,
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  group('what IS rendered', () {
    testWidgets('the header band, the title, Download and a labelled close',
        (WidgetTester tester) async {
      await pumpViewer(tester);

      expect(find.text('Residence Certificate · LCC-2026-000123'),
          findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      // `aria-label={tc("close")}` — `:102`. The glyph carries the label; there
      // is no visible "Close" text in the source either.
      expect(find.bySemanticsLabel('Close'), findsOneWidget);

      final Container band = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Residence Certificate · LCC-2026-000123'),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(band.color, AppColors.primary, reason: '`bg-[#344EAD]` — `:89`');
    });

    testWidgets('the document itself is painted', (WidgetTester tester) async {
      await pumpViewer(tester);
      expect(find.bySemanticsLabel('document-page'), findsOneWidget);
    });
  });

  group('B5-AC-77 … B5-AC-80 — the three dead branches are NOT ported', () {
    testWidgets('no loading skeleton and no common.loading string',
        (WidgetTester tester) async {
      await pumpViewer(tester);
      expect(find.text('Loading…'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('no error card and no Try again', (WidgetTester tester) async {
      await pumpViewer(tester);
      expect(find.text('Try again'), findsNothing);
      expect(find.text('ລອງໃໝ່'), findsNothing);
    });

    testWidgets('no "not available to view yet" empty state',
        (WidgetTester tester) async {
      await pumpViewer(tester);
      expect(find.textContaining('not available to view yet'), findsNothing);
      expect(find.textContaining('ຍັງບໍ່ພ້ອມໃຫ້ເບິ່ງ'), findsNothing);
    });

    testWidgets('B5-AC-80 — it renders from its parameters alone',
        (WidgetTester tester) async {
      // No BLoC ancestor, no container, no repository anywhere in the tree —
      // and it still renders. That is the capability claim; a grep would only
      // prove the file does not mention one.
      await pumpViewer(tester);
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('document-page'), findsOneWidget);
    });
  });

  group('B5-AC-84 / B5-AC-88 — the footer, four arrangements', () {
    testWidgets('a code and a payload: both render, and the payload has no '
        'label', (WidgetTester tester) async {
      await pumpViewer(
        tester,
        verifyCode: kPinnedVerifyCode,
        qrPayload: 'LCC:CERT-0001',
      );

      expect(find.text('Verification code'), findsOneWidget);
      expect(find.text(kPinnedVerifyCode), findsOneWidget);
      expect(find.text('LCC:CERT-0001'), findsOneWidget);
      // `:164-169` renders the value beside an icon and nothing else. Inventing
      // a label here is L-10 corollary (b).
      expect(find.text('QR payload'), findsNothing);
      expect(find.text('QR'), findsNothing);
    });

    testWidgets('a code and no payload: the code alone',
        (WidgetTester tester) async {
      await pumpViewer(tester, verifyCode: kPinnedVerifyCode);
      expect(find.text('Verification code'), findsOneWidget);
      expect(find.text('LCC:CERT-0001'), findsNothing);
    });

    testWidgets('neither: no footer at all', (WidgetTester tester) async {
      await pumpViewer(tester);
      expect(find.text('Verification code'), findsNothing);
    });

    testWidgets('an EMPTY verifyCode behaves as absent — `:150` is truthiness',
        (WidgetTester tester) async {
      await pumpViewer(tester, verifyCode: '', qrPayload: 'LCC:CERT-0001');
      expect(find.text('Verification code'), findsNothing);
      expect(find.text('LCC:CERT-0001'), findsNothing,
          reason: 'the payload lives INSIDE the code\'s block (`:150-171`), so '
              'no code means no payload either');
    });

    testWidgets('an empty payload beside a real code renders no payload row',
        (WidgetTester tester) async {
      await pumpViewer(tester, verifyCode: kPinnedVerifyCode, qrPayload: '');
      expect(find.text('Verification code'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code), findsNothing);
    });

    testWidgets('the Lao label is the source\'s arm', (WidgetTester tester) async {
      await pumpViewer(
        tester,
        verifyCode: kPinnedVerifyCode,
        locale: const Locale('lo'),
      );
      expect(find.text('ລະຫັດກວດສອບ'), findsOneWidget);
    });
  });

  group('B5-AC-81 / B5-AC-83 — Download', () {
    testWidgets('it saves the exact filename, with real PDF bytes',
        (WidgetTester tester) async {
      final _RecordingSaver saver = _RecordingSaver();
      await pumpViewer(tester, saver: saver);

      await _tapDownload(tester);

      expect(saver.fileNames, <String>['LCC-2026-000123.pdf'],
          reason: '`${'\$'}{detail.reference_no}.pdf` — `:259`, `:652`');
      expect(saver.byteLengths.single, greaterThan(1024),
          reason: 'the bytes are the rendered page, not an empty buffer — '
              'a saver handed nothing would still record a call');
    });

    testWidgets('a COMPLETED save renders nothing', (WidgetTester tester) async {
      await pumpViewer(tester, saver: _RecordingSaver());

      await _tapDownload(tester);

      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.textContaining('aved'), findsNothing);
    });

    testWidgets('a CANCELLED save renders nothing either',
        (WidgetTester tester) async {
      // `saveFile` returns null when the citizen dismisses the platform dialog.
      // The web has no cancel state at all — the browser just writes the file
      // — so inventing a message here is L-10 corollary (b).
      final _RecordingSaver saver = _RecordingSaver(answer: null);
      await pumpViewer(tester, saver: saver);

      await _tapDownload(tester);

      expect(saver.fileNames, hasLength(1));
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('close', () {
    testWidgets('tapping the close glyph calls onClose',
        (WidgetTester tester) async {
      int closed = 0;
      await pumpViewer(tester, onClose: () => closed++);

      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pump();

      expect(closed, 1);
    });
  });

  group('B5-AC-85 — the dialog is FULL SCREEN, not a centred card', () {
    testWidgets('showDocumentViewer opens a zero-inset dialog over a '
        'black/60 barrier', (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrapWithLocalization(
        Builder(
          builder: (BuildContext context) => MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: Builder(
              builder: (BuildContext inner) => Scaffold(
                body: TextButton(
                  onPressed: () => showDocumentViewer(
                    inner,
                    title: 'T',
                    spec: kFixedSpec,
                    downloadName: 'x.pdf',
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ));

      await tester.pump();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final Dialog dialog = tester.widget<Dialog>(find.byType(Dialog));
      expect(dialog.insetPadding, EdgeInsets.zero,
          reason: '`fixed inset-0` — `:85`');
      expect(dialog.shape, const RoundedRectangleBorder(),
          reason: 'no rounding: the source is a full-bleed column, not a card');

      final ModalBarrier barrier = tester.widgetList<ModalBarrier>(
        find.byType(ModalBarrier),
      ).firstWhere((ModalBarrier b) => b.color != null);
      expect(barrier.color, AppColors.black.withValues(alpha: 0.6),
          reason: '`bg-black/60`');

      // And it really fills the viewport.
      final Size painted = tester.getSize(find.byType(DocumentViewer));
      expect(painted.width, 390);
      expect(painted.height, 844);
    });
  });
}

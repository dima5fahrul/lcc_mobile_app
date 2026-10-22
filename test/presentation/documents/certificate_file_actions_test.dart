/// `CertificateFileActions` — the per-`files[]` *View* / *Download* pair the
/// 2026-10 guide's File paragraph requires. For rows **without** `files[]` the
/// legacy faux-PDF row (`renderDocumentPdf`) is what renders instead, and
/// `document_actions_row_test.dart` owns that half of the switch.
///
/// **Review I-1 / I-2, 2026-10-22.** Two things changed here and both are
/// asserted below:
///
/// * every button carries its **layout** — *View document · Card* — because
///   two buttons reading the same four words is not a choice a citizen can
///   make;
/// * the widget takes **every certificate row of the case**, not one, because
///   a divorce issues three (joint card, booklet A, booklet B) and the single
///   `certFromList` match hid two of them.
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
import 'package:lcc_mobile_app/presentation/documents/document_viewer.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../features/documents/documents_test_helper.dart';
import '../../helpers/app_test_harness.dart';

/// NIST SHA-256 of `abc` — the fingerprint `DownloadCertificateFile`'s
/// `X-Content-SHA256` header carries in the matched fixture.
const String kAbcSha =
    'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';

/// A scripted fetch: each call pops the next answer.
typedef ScriptedFetch = Future<Either<Failure, CertificateFileDownload>>
    Function({required String id, required String layout, bool inline});

/// I-1 — the viewer's conditional QR fetch. Scripted per certificate id.
class _ScriptedQrFetch {
  final Map<String, String> answers;
  final List<String> calls = <String>[];

  _ScriptedQrFetch(this.answers);

  Future<String?> call(String certificateId) async {
    calls.add(certificateId);
    return answers[certificateId];
  }
}

class _RecordingSinks {
  final List<String> opened = <String>[];
  final List<String> saved = <String>[];

  Future<void> open(Uint8List bytes, String fileName) async =>
      opened.add(fileName);

  Future<void> save(Uint8List bytes, String fileName) async =>
      saved.add(fileName);
}

void main() {
  // The QR cache is process-lifetime by design (the payload is fixed at
  // issue); tests must start with it empty or the null-answer case would
  // read a previous test's fetch.
  setUp(() => kCertificateQrCache.clear());

  Future<_RecordingSinks> pumpActions(
    WidgetTester tester, {
    required ScriptedFetch fetch,
    IssuedCertificate? certificate,
    List<IssuedCertificate> certificates = const <IssuedCertificate>[],
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
              certificates: certificates,
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
    testWidgets('two files render two View and two Download buttons, each '
        'LABELLED BY ITS LAYOUT (review I-1)',
        (WidgetTester tester) async {
      await pumpActions(tester,
          certificate: twoFiles(),
          fetch: ({required id, required layout, inline = false}) async =>
              okFile());

      expect(find.textContaining('View document'), findsNWidgets(2));
      expect(find.textContaining('Download document'), findsNWidgets(2));

      // The point of I-1: the two pairs are DISTINGUISHABLE. An unqualified
      // 'View document' is the bug, so it must not be on screen at all.
      expect(find.text('View document · Card'), findsOneWidget);
      expect(find.text('View document · Booklet'), findsOneWidget);
      expect(find.text('Download document · Card'), findsOneWidget);
      expect(find.text('Download document · Booklet'), findsOneWidget);
      expect(find.text('View document'), findsNothing);
      expect(find.text('Download document'), findsNothing);

      // A single row needs no `document_type`/`copy` heading — there is
      // nothing to tell it apart from (review I-2's "renders as before").
      expect(find.text('MAR'), findsNothing);
      expect(find.text('MAR · Joint card'), findsNothing);
    });

    testWidgets('an UNKNOWN layout is labelled with the server\'s own word',
        (WidgetTester tester) async {
      await pumpActions(tester,
          certificate: certFixture().copyWith(
            files: <CertificateFile>[
              const CertificateFile(
                  layout: 'poster', url: '/f/poster', sha256: kAbcSha),
            ],
          ),
          fetch: ({required id, required layout, inline = false}) async =>
              okFile());

      // `layout` is an open set (§ Certificate model's table grows by row), so
      // a value this build has not been told about is shown verbatim rather
      // than mislabelled as Card.
      expect(find.text('View document · poster'), findsOneWidget);
    });

    testWidgets('hasStoredFile == false renders nothing at all',
        (WidgetTester tester) async {
      await pumpActions(tester,
          certificate: certFixture().copyWith(files: const <CertificateFile>[]),
          fetch: ({required id, required layout, inline = false}) async =>
              okFile());

      expect(find.textContaining('View document'), findsNothing);
      expect(find.textContaining('Download document'), findsNothing);
    });

    testWidgets('a null certificate renders nothing',
        (WidgetTester tester) async {
      await pumpActions(tester,
          certificate: null,
          fetch: ({required id, required layout, inline = false}) async =>
              okFile());

      expect(find.textContaining('View document'), findsNothing);
      expect(find.textContaining('Download document'), findsNothing);
    });
  });

  // ── Review I-2 — a divorce's THREE documents ──────────────────────────────

  group('I-2 — every certificate row of the application renders', () {
    /// The spec's § Divorce arrangement: *"one application yields three
    /// certificates: the joint card and booklets A (husband) and B (wife)"* —
    /// same `application_id`, one `copy` each, one file each.
    List<IssuedCertificate> divorceRows() => <IssuedCertificate>[
          certFixture().copyWith(
            id: 'div-joint',
            certificateNo: 'LA-DIV-2026-000094',
            documentType: 'DIV',
            copy: '',
            files: <CertificateFile>[
              const CertificateFile(
                  layout: 'card', url: '/f/joint', sha256: kAbcSha),
            ],
          ),
          certFixture().copyWith(
            id: 'div-a',
            certificateNo: 'LA-DIV-2026-000094-A',
            documentType: 'DIV',
            copy: 'A',
            files: <CertificateFile>[
              const CertificateFile(
                  layout: 'booklet', url: '/f/a', sha256: kAbcSha),
            ],
          ),
          certFixture().copyWith(
            id: 'div-b',
            certificateNo: 'LA-DIV-2026-000094-B',
            documentType: 'DIV',
            copy: 'B',
            files: <CertificateFile>[
              const CertificateFile(
                  layout: 'booklet', url: '/f/b', sha256: kAbcSha),
            ],
          ),
        ];

    testWidgets('three rows render three pairs, each headed by its '
        'document_type and copy', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      await pumpActions(tester,
          certificate: divorceRows().first,
          certificates: divorceRows(),
          fetch: ({required id, required layout, inline = false}) async =>
              okFile());

      expect(find.textContaining('View document'), findsNWidgets(3));
      expect(find.textContaining('Download document'), findsNWidgets(3));

      // The labels the spec names: `""` joint card, `A` husband's booklet,
      // `B` wife's booklet.
      expect(find.text('DIV · Joint card'), findsOneWidget);
      expect(find.text("DIV · Husband's booklet"), findsOneWidget);
      expect(find.text("DIV · Wife's booklet"), findsOneWidget);
    });

    testWidgets('the tapped row\'s OWN id and layout reach the fetch — the '
        'wife\'s booklet is downloadable, which is the defect I-2 names',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      final List<String> ids = <String>[];
      final List<String> layouts = <String>[];
      final _RecordingSinks sinks = await pumpActions(tester,
          certificate: divorceRows().first,
          certificates: divorceRows(),
          fetch: ({required id, required layout, inline = false}) async {
            ids.add(id);
            layouts.add(layout);
            return okFile(fileName: null);
          });

      // Booklet B's pair is the third block; find it through its heading's
      // sibling rather than by index, so the assertion survives a layout
      // change.
      final Finder downloads =
          find.textContaining('Download document · Booklet');
      expect(downloads, findsNWidgets(2));
      await _tapAndDrain(tester, downloads.last);

      expect(ids, <String>['div-b'],
          reason: 'the LAST booklet block is booklet B — not the first row');
      expect(layouts, <String>['booklet']);
      expect(sinks.saved, <String>['LA-DIV-2026-000094-B-booklet.pdf'],
          reason: 'the fallback filename is built from THAT row\'s number');
    });

    testWidgets('a row with no stored file is skipped, not drawn empty',
        (WidgetTester tester) async {
      await pumpActions(tester,
          certificate: divorceRows().first,
          certificates: <IssuedCertificate>[
            divorceRows().first,
            divorceRows()[1].copyWith(files: const <CertificateFile>[]),
          ],
          fetch: ({required id, required layout, inline = false}) async =>
              okFile());

      expect(find.textContaining('View document'), findsNWidgets(1));
      expect(find.text("DIV · Husband's booklet"), findsNothing);
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

      await _tapAndDrain(tester, find.text('View document · Card'));

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

      await _tapAndDrain(tester, find.text('Download document · Card'));

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

      await _tapAndDrain(tester, find.text('Download document · Card'));

      expect(sinks.saved, <String>['CERT-0001-card.pdf']);
    });

    testWidgets('a MISMATCHED hash surfaces verify.integrityFailed and '
        'saves nothing', (WidgetTester tester) async {
      final _RecordingSinks sinks = await pumpActions(tester,
          certificate: twoFiles(),
          fetch: ({required id, required layout, inline = false}) async =>
              okFile(sha256Header:
                  'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef'));

      await _tapAndDrain(tester, find.text('Download document · Card'));

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

      await _tapAndDrain(tester, find.text('Download document · Card'));

      expect(sinks.saved, hasLength(1));
    });

    testWidgets('a fetch Failure surfaces the server message, opens nothing',
        (WidgetTester tester) async {
      final _RecordingSinks sinks = await pumpActions(tester,
          certificate: twoFiles(),
          fetch: ({required id, required layout, inline = false}) async =>
              Left<Failure, CertificateFileDownload>(
                  const Failure('certificate file not found')));

      await _tapAndDrain(tester, find.text('Download document · Card'));

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

      await _tapAndDrain(tester, find.text('ດາວໂຫຼດເອກະສານ · ບັດ'));

      expect(find.text('ກວດສອບຄວາມຖືກຕ້ອງຂອງໄຟລ໌ບໍ່ສຳເລັດ'), findsOneWidget);
    });
  });

  group('I-1 — the viewer QR panel, conditional fetch', () {
    testWidgets('payload present → no fetch, renders the payload',
        (WidgetTester tester) async {
      final _ScriptedQrFetch qr = _ScriptedQrFetch(<String, String>{});
      await pumpViewerWithQr(
        tester,
        certificate: certFixture(qrPayload: 'LCC:CERT-0001'),
        qrFetch: qr.call,
      );

      expect(qr.calls, isEmpty,
          reason: 'the hasQrPayload fast path never hits the endpoint');
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('payload absent + verifyCode → fetches the endpoint and '
        'renders its payload', (WidgetTester tester) async {
      final _ScriptedQrFetch qr =
          _ScriptedQrFetch(<String, String>{'cert-1': 'LCC:FETCHED'});
      await pumpViewerWithQr(
        tester,
        // The v2 list item carries no qr_payload — the case that motivated I-1.
        certificate: certFixture(qrPayload: null, verifyCode: 'VC-9'),
        qrFetch: qr.call,
      );
      await tester.pump();

      expect(qr.calls, <String>['cert-1']);
      expect(find.byType(QrImageView), findsOneWidget);
      // The strip's payload TEXT still shows the fetched value.
      expect(find.text('LCC:FETCHED'), findsOneWidget);
    });

    testWidgets('the fetch is cached per certificate id',
        (WidgetTester tester) async {
      final _ScriptedQrFetch qr =
          _ScriptedQrFetch(<String, String>{'cert-1': 'LCC:FETCHED'});
      await pumpViewerWithQr(
        tester,
        certificate: certFixture(qrPayload: null, verifyCode: 'VC-9'),
        qrFetch: qr.call,
      );
      await tester.pump();
      final int callsAfterFirst = qr.calls.length;

      // Re-render the same viewer (a second pump of the widget tree) — the
      // cache must answer without a second call.
      await pumpViewerWithQr(
        tester,
        certificate: certFixture(qrPayload: null, verifyCode: 'VC-9'),
        qrFetch: qr.call,
      );
      await tester.pump();

      expect(qr.calls.length, callsAfterFirst,
          reason: 'one fetch per certificate id, not one per render');
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('payload absent + no verifyCode → nothing renders',
        (WidgetTester tester) async {
      final _ScriptedQrFetch qr =
          _ScriptedQrFetch(<String, String>{'cert-1': 'LCC:FETCHED'});
      await pumpViewerWithQr(
        tester,
        certificate: certFixture(qrPayload: null, verifyCode: ''),
        qrFetch: qr.call,
      );
      await tester.pump();

      expect(qr.calls, isEmpty,
          reason: 'the strip only exists beside a code (`:150` gates it)');
      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('the endpoint answers null → no QR, no crash',
        (WidgetTester tester) async {
      final _ScriptedQrFetch qr = _ScriptedQrFetch(<String, String>{});
      await pumpViewerWithQr(
        tester,
        certificate: certFixture(qrPayload: null, verifyCode: 'VC-9'),
        qrFetch: qr.call,
      );
      await tester.pump();

      expect(qr.calls, <String>['cert-1']);
      expect(find.byType(QrImageView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

/// I-1 — pumps the viewer exactly as `DocumentActionsRow.View` mounts it
/// (the seam `document_viewer.dart` exposes to a certificate-bearing caller),
/// with the QR fetch scripted. This is the panel's test surface: the same
/// widget `showDocumentViewer` builds, driven through the same parameter the
/// row hands it.
Future<void> pumpViewerWithQr(
  WidgetTester tester, {
  required IssuedCertificate certificate,
  required Future<String?> Function(String) qrFetch,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(wrapWithLocalization(
    startLocale: const Locale('en'),
    Builder(
      builder: (BuildContext context) => MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: Scaffold(
          body: CertificateQrPanel(
            certificate: certificate,
            qrPayload: certificate.qrPayload,
            fetchQr: qrFetch.call,
          ),
        ),
      ),
    ),
  ));
  // The strip resolves its label through `.tr()`, and easy_localization
  // loads its bundle asynchronously — frame 1 renders an ErrorWidget until
  // the delegate answers. A second pump is what makes the assertions see
  // the real tree (the same reason pumpActions pumps once more).
  await tester.pump();
}

Future<void> _tapAndDrain(WidgetTester tester, Finder target) async {
  await tester.tap(target);
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 400)),
  );
  await tester.pump();
}

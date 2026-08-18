/// The issued-certificate card — the four rows of `HistoryDetailPage.tsx:456-494`,
/// **B5-AC-49** and **B5-AC-84**'s card half.
///
/// The last group is the **drift guard** for the one thing G-L7 forced B5 to
/// restate: `history_detail_cards.dart` made `HistoryDetailInfoRow` public
/// specifically for this card, and `lib/presentation/**` may not import
/// `features/*/presentation/**`. So the row is written twice, and this file is
/// what stops the two copies diverging silently — the failure B7b's own comment
/// predicted.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/application/domain/application_formatting.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_detail.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_status.dart';
import 'package:lcc_mobile_app/features/documents/domain/entities/issued_certificate.dart';
import 'package:lcc_mobile_app/features/history/presentation/widgets/history_detail_cards.dart';
import 'package:lcc_mobile_app/i18n/i18n.dart';
import 'package:lcc_mobile_app/presentation/documents/issued_certificate_card.dart';
import 'package:lcc_mobile_app/presentation/theme/app_colors.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';

import '../../features/documents/documents_test_helper.dart';
import '../../features/history/history_test_helper.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    IssuedCertificate? certificate,
    bool certificateLoading = false,
    String? certificateNo,
    String? issuedAt,
    Lang lang = Lang.en,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 1200);
    addTearDown(tester.view.reset);

    final ApplicationDetail detail = detailFixture(
      status: CaseStatus.issued,
      certificateNo: certificateNo,
      issuedAt: issuedAt,
    );

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: IssuedCertificateCard(
            detail: detail,
            certificate: certificate,
            certificateLoading: certificateLoading,
            lang: lang,
            headingLabel: 'Issued certificate',
            certificateNumberLabel: 'Certificate number',
            issuedOnLabel: 'Issued on',
            verificationCodeLabel: 'Verification code',
            qrPayloadLabel: 'QR payload',
            notAvailableLabel:
                'The verification code for this certificate is not available yet.',
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  group('the two unconditional rows — `:465-474`', () {
    testWidgets('the certificate\'s own number wins over the case\'s',
        (WidgetTester tester) async {
      await pumpCard(
        tester,
        certificate: certFixture(certificateNo: 'FROM-CERT'),
        certificateNo: 'FROM-CASE',
      );

      expect(find.text('Issued certificate'), findsOneWidget);
      expect(find.text('Certificate number'), findsOneWidget);
      expect(find.text('FROM-CERT'), findsOneWidget);
      expect(find.text('FROM-CASE'), findsNothing);
    });

    testWidgets('with no certificate it falls back to the case\'s number',
        (WidgetTester tester) async {
      await pumpCard(tester, certificateNo: 'FROM-CASE');
      expect(find.text('FROM-CASE'), findsOneWidget);
    });

    testWidgets('with neither it renders the em dash — `:468`',
        (WidgetTester tester) async {
      await pumpCard(tester);
      // **Two**, and both are the source's: the number row's own `?? "—"`
      // (`:468`) and `formatDate(undefined)` in the Issued-on row (`:473`,
      // `application_formatting.dart`'s `kAbsentDate`). The fixture supplies
      // neither value, so both fall back.
      expect(find.text(kAbsentDate), findsNWidgets(2));
    });

    testWidgets('Issued on prefers the certificate\'s date — `:473`',
        (WidgetTester tester) async {
      await pumpCard(
        tester,
        certificate: certFixture(issuedAt: '2026-08-14T14:05:00Z'),
        issuedAt: '2020-01-01T00:00:00Z',
      );

      expect(find.text('Issued on'), findsOneWidget);
      expect(
        find.text(formatApplicationDate('2026-08-14T14:05:00Z', 'en')),
        findsOneWidget,
      );
      expect(
        find.text(formatApplicationDate('2020-01-01T00:00:00Z', 'en')),
        findsNothing,
      );
    });

    testWidgets('and falls back to the case\'s', (WidgetTester tester) async {
      await pumpCard(tester, issuedAt: '2020-01-01T00:00:00Z');
      expect(
        find.text(formatApplicationDate('2020-01-01T00:00:00Z', 'en')),
        findsOneWidget,
      );
    });
  });

  group('B5-AC-84 — the two conditional rows', () {
    testWidgets('both render when both values are present',
        (WidgetTester tester) async {
      await pumpCard(
        tester,
        certificate: certFixture(verifyCode: 'VC-1', qrPayload: 'QR-1'),
      );

      expect(find.text('Verification code'), findsOneWidget);
      expect(find.text('VC-1'), findsOneWidget);
      expect(find.text('QR payload'), findsOneWidget);
      expect(find.text('QR-1'), findsOneWidget);
    });

    testWidgets('an EMPTY verify_code hides its row — `:475` is truthiness',
        (WidgetTester tester) async {
      await pumpCard(tester, certificate: certNoVerifyCode);
      expect(find.text('Verification code'), findsNothing);
    });

    testWidgets('an absent qr_payload hides its row — `:482`',
        (WidgetTester tester) async {
      await pumpCard(tester, certificate: certNoQrPayload);
      expect(find.text('QR payload'), findsNothing);
      expect(find.text('Verification code'), findsOneWidget,
          reason: 'the two gates are independent');
    });

    testWidgets('an EMPTY qr_payload hides it too', (WidgetTester tester) async {
      await pumpCard(tester, certificate: certFixture(qrPayload: ''));
      expect(find.text('QR payload'), findsNothing);
    });
  });

  group('B5-AC-49 — the note is a THREE-state gate', () {
    const String note =
        'The verification code for this certificate is not available yet.';

    testWidgets('no certificate and the list has ANSWERED: the note shows',
        (WidgetTester tester) async {
      await pumpCard(tester, certificateNo: 'CERT-1');
      expect(find.text(note), findsOneWidget);
    });

    testWidgets('no certificate but the list is IN FLIGHT: no note',
        (WidgetTester tester) async {
      await pumpCard(tester, certificateNo: 'CERT-1', certificateLoading: true);
      expect(find.text(note), findsNothing,
          reason: 'collapsing `!certificate && !loading` to `certificate == '
              'null` would render a sentence the source does not render at '
              'that moment');
    });

    testWidgets('a certificate resolved: no note, loading or not',
        (WidgetTester tester) async {
      await pumpCard(tester, certificate: certApplicationMatch);
      expect(find.text(note), findsNothing);

      await pumpCard(
        tester,
        certificate: certApplicationMatch,
        certificateLoading: true,
      );
      expect(find.text(note), findsNothing);
    });
  });

  group('the heading glyph is the source\'s green — `:459`', () {
    testWidgets('#16A34A, not the brand blue', (WidgetTester tester) async {
      await pumpCard(tester, certificate: certApplicationMatch);
      expect(AppColors.trackingDone.toARGB32(), 0xFF16A34A);
    });
  });

  group('the row is a faithful restatement of HistoryDetailInfoRow', () {
    testWidgets('every token matches, so the G-L7-forced copy cannot drift',
        (WidgetTester tester) async {
      // B7b's `history_detail_cards.dart:281-284` made its row public *for this
      // card* and warned that "a private copy there would drift from this
      // one". G-L7 forbids the import it anticipated, so the copy exists — and
      // this is the mechanism that keeps the warning from coming true.
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Column(
            children: <Widget>[
              CertificateInfoRow(glyph: 'Hash', label: 'L', value: 'V'),
              HistoryDetailInfoRow(glyph: 'Hash', label: 'L', value: 'V'),
            ],
          ),
        ),
      ));
      await tester.pump();

      final List<Container> tiles = tester
          .widgetList<Container>(find.byType(Container))
          .where((Container c) => c.constraints?.maxWidth == kCertificateRowTile)
          .toList();
      expect(tiles, hasLength(2), reason: 'one tile from each row');
      expect(
        (tiles[0].decoration! as BoxDecoration).color,
        (tiles[1].decoration! as BoxDecoration).color,
        reason: 'the `#EEF2FF` glyph tint',
      );
      expect(tiles[0].constraints, tiles[1].constraints,
          reason: 'the 36 px tile');

      final List<Text> labels = tester
          .widgetList<Text>(find.text('L'))
          .toList();
      expect(labels, hasLength(2));
      expect(labels[0].style, labels[1].style, reason: 'the label style');

      final List<Text> values = tester
          .widgetList<Text>(find.text('V'))
          .toList();
      expect(values, hasLength(2));
      expect(values[0].style, values[1].style, reason: 'the value style');
    });
  });
}

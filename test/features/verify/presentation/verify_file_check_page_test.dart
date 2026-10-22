/// `VerifyFileCheckPage` — § Checking a PDF on the device's four answer
/// branches, driven with a stubbed picker and a stubbed
/// `VerifyDocumentHashFetcher` (no platform channel, no transport).
///
/// The branch under heaviest test is the fourth: "A found file whose
/// `status` is `revoked`, `superseded` or `expired` matches, but must not be
/// accepted: show the status screen" — a certificate whose `verify_code`
/// equals the one being viewed AND whose `status` is `revoked` must render
/// the REVOKED screen, never the match copy, even though the code
/// comparison alone would call it a match.
library;

import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/verify/domain/entities/verification_result.dart';
import 'package:lcc_mobile_app/features/verify/presentation/pages/verify_file_check_page.dart';

import '../../../helpers/app_test_harness.dart';
import '../verify_fixture.dart';

/// The code the citizen was viewing before tapping "Check a PDF file" — the
/// fixtures' own default `verify_code`.
const String kViewedCode = 'RES-7Q4K-19XD';

/// Synthetic bytes standing in for a picked PDF — the hash's input is never
/// asserted directly here (that is `verify_document_hash_io_test.dart`'s
/// job); only [stubFetcher]'s canned answer matters to this page.
final Uint8List _fileBytes = Uint8List.fromList(<int>[1, 2, 3, 4, 5]);

/// A picker that returns [bytes] once — standing in for a citizen who chose
/// a file. `null` stands in for a cancel.
Future<Uint8List?> Function() stubPicker(Uint8List? bytes) =>
    () async => bytes;

/// A `VerifyDocumentHashFetcher` that answers [answer] regardless of the hex
/// it is handed — the page's job under test is what it renders for a given
/// server answer, not the hashing itself.
Future<Either<Failure, VerificationResult>> Function(String) stubFetcher(
  Either<Failure, VerificationResult> answer,
) =>
    (String hash) async => answer;

Future<void> _pump(
  WidgetTester tester, {
  required Future<Uint8List?> Function() pickFile,
  required Future<Either<Failure, VerificationResult>> Function(String)
      verifyDocumentHash,
  String viewedVerifyCode = kViewedCode,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(390, 1400);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(wrapWithLocalization(
    Builder(
      builder: (BuildContext context) => MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: VerifyFileCheckPage(
          viewedVerifyCode: viewedVerifyCode,
          pickFile: pickFile,
          verifyDocumentHash: verifyDocumentHash,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('branch 1 — match: status != not-found and verify_code == viewed',
      () {
    testWidgets('card layout → the match copy and "Card"',
        (WidgetTester tester) async {
      await _pump(
        tester,
        pickFile: stubPicker(_fileBytes),
        verifyDocumentHash: stubFetcher(
          Right(issuedResult().copyWith(verifyCode: kViewedCode, layout: 'card')),
        ),
      );

      await tester.tap(find.text('Choose a file'));
      await tester.pumpAndSettle();

      expect(find.text('This file matches the issued document.'),
          findsOneWidget);
      expect(find.textContaining('Card'), findsOneWidget);
    });

    testWidgets('booklet layout → the match copy and "Booklet" (a marriage '
        'booklet matches too)', (WidgetTester tester) async {
      await _pump(
        tester,
        pickFile: stubPicker(_fileBytes),
        verifyDocumentHash: stubFetcher(
          Right(issuedResult()
              .copyWith(verifyCode: kViewedCode, layout: 'booklet')),
        ),
      );

      await tester.tap(find.text('Choose a file'));
      await tester.pumpAndSettle();

      expect(find.text('This file matches the issued document.'),
          findsOneWidget);
      expect(find.textContaining('Booklet'), findsOneWidget);
    });
  });

  group('branch 2 — found, but a different verify_code', () {
    testWidgets('shows the other certificate\'s number, not the match copy',
        (WidgetTester tester) async {
      await _pump(
        tester,
        pickFile: stubPicker(_fileBytes),
        verifyDocumentHash: stubFetcher(
          Right(issuedResult().copyWith(
            verifyCode: 'RES-9ZZZ-0000',
            certificateNo: 'LA-RES-2026-000999',
          )),
        ),
      );

      await tester.tap(find.text('Choose a file'));
      await tester.pumpAndSettle();

      expect(
        find.text('This file matches the issued document.'),
        findsNothing,
        reason: 'a different code is not a match',
      );
      expect(find.text('This is a genuine certificate, but a different one'),
          findsOneWidget);
      expect(find.textContaining('LA-RES-2026-000999'), findsOneWidget);
    });
  });

  group('branch 3 — not-found', () {
    testWidgets('shows the "not an issued document" copy',
        (WidgetTester tester) async {
      await _pump(
        tester,
        pickFile: stubPicker(_fileBytes),
        verifyDocumentHash: stubFetcher(Right(notFoundResult())),
      );

      await tester.tap(find.text('Choose a file'));
      await tester.pumpAndSettle();

      expect(find.text('Not an issued document'), findsOneWidget);
      expect(
        find.text(
            'This file is not an issued document, or it was changed.'),
        findsOneWidget,
      );
    });
  });

  group('branch 4 — a found, SAME-code file whose status is revoked, '
      'superseded or expired: the status screen WINS over the match copy',
      () {
    testWidgets('revoked + matching verify_code → REVOKED, not the match '
        'copy', (WidgetTester tester) async {
      await _pump(
        tester,
        pickFile: stubPicker(_fileBytes),
        verifyDocumentHash: stubFetcher(
          Right(revokedResult().copyWith(verifyCode: kViewedCode)),
        ),
      );

      await tester.tap(find.text('Choose a file'));
      await tester.pumpAndSettle();

      expect(
        find.text('This file matches the issued document.'),
        findsNothing,
        reason: 'the status screen must win — a revoked certificate\'s own '
            'file still hashes to its issued fingerprint, which is exactly '
            'the trap this branch guards against',
      );
      expect(find.text('Revoked — do not accept'), findsOneWidget);
      expect(find.textContaining('Reported lost by the holder'),
          findsOneWidget,
          reason: 'revoke_reason, the REVOKED screen\'s "also show"');
    });

    testWidgets('superseded + matching verify_code → REPLACED, not the '
        'match copy', (WidgetTester tester) async {
      await _pump(
        tester,
        pickFile: stubPicker(_fileBytes),
        verifyDocumentHash: stubFetcher(
          Right(supersededResult().copyWith(verifyCode: kViewedCode)),
        ),
      );

      await tester.tap(find.text('Choose a file'));
      await tester.pumpAndSettle();

      expect(find.text('This file matches the issued document.'),
          findsNothing);
      expect(find.text('Replaced — do not accept'), findsOneWidget);
      expect(find.textContaining('LA-RES-2026-000456'), findsOneWidget,
          reason: 'replaced_by_certificate_no');
    });

    testWidgets('expired + matching verify_code → EXPIRED, not the match '
        'copy', (WidgetTester tester) async {
      await _pump(
        tester,
        pickFile: stubPicker(_fileBytes),
        verifyDocumentHash: stubFetcher(
          Right(expiredResult().copyWith(
            verifyCode: kViewedCode,
            validUntil: '2026-12-29',
          )),
        ),
      );

      await tester.tap(find.text('Choose a file'));
      await tester.pumpAndSettle();

      expect(find.text('This file matches the issued document.'),
          findsNothing);
      expect(find.text('Expired'), findsOneWidget);
      expect(find.textContaining('29 Dec 2026'), findsOneWidget,
          reason: 'valid_until, EXPIRED\'s "also show"');
    });
  });

  group('the picker cancel — null means nothing happens', () {
    testWidgets('no checking state, no result, no crash',
        (WidgetTester tester) async {
      await _pump(
        tester,
        pickFile: stubPicker(null),
        verifyDocumentHash: stubFetcher(Right(issuedResult())),
      );

      await tester.tap(find.text('Choose a file'));
      await tester.pumpAndSettle();

      expect(find.text('This file matches the issued document.'),
          findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('a transport failure', () {
    testWidgets('renders the server\'s own sentence', (WidgetTester tester) async {
      await _pump(
        tester,
        pickFile: stubPicker(_fileBytes),
        verifyDocumentHash: stubFetcher(
          const Left<Failure, VerificationResult>(Failure('network error')),
        ),
      );

      await tester.tap(find.text('Choose a file'));
      await tester.pumpAndSettle();

      expect(find.text('Could not check this file'), findsOneWidget);
      expect(find.text('network error'), findsOneWidget);
    });
  });
}

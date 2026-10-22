/// `VerifyResultPage` — the five status screens, the honest checks copy, and
/// the PDF-check gate.
///
/// The page is pumped as a pure function of its bloc (no container, no real
/// router beyond the two destinations its buttons push to), for the same
/// reason `notification_bell_test.dart` pumps the bell on a hand-built
/// `GoRouter`: the page's contract is *given this state, render this*, and the
/// route table's own reachability is `test/utils/routes/`' subject.
///
/// Every title/extras claim below is the guide's "Which screen to show" table
/// and "Checks, worded honestly" subsection, read as a UI contract:
///
/// * issued → VALID + type, number, masked holder, issued date, `valid_until`
///   when set, issuing office;
/// * expired → EXPIRED + the `valid_until` date;
/// * revoked → REVOKED + `revoked_at`, `revoke_reason`;
/// * superseded → REPLACED + `replaced_by_certificate_no`;
/// * not-found → NOT FOUND + the rescan / retype affordance.
///
/// The honesty claims are negative on purpose: `recorded` renders "on file"
/// and the word "verified" appears NOWHERE, because the guide forbids wording
/// the signature check as verified/valid; `ca`/`format`/`timestamp` render
/// only when non-empty; the PDF-check button is gated on
/// `record_hash.status != 'missing'` (§ Checking a PDF on the device).
library;

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/verify/domain/entities/verification_result.dart';
import 'package:lcc_mobile_app/features/verify/domain/verify_failures.dart';
import 'package:lcc_mobile_app/features/verify/presentation/bloc/verify_bloc.dart';
import 'package:lcc_mobile_app/features/verify/presentation/pages/verify_result_page.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

import '../../../helpers/app_test_harness.dart' show wrapWithLocalization;
import '../verify_fixture.dart';
import 'verify_bloc_test.dart';

/// Stub destination the PDF-check button pushes to — Task 7 replaces the
/// route's target; the button and its gate are what this file pins.
const String kFileCheckStub = 'FILE-CHECK-STUB';

/// Stub destination the not-found affordances push to.
const String kEntryStub = 'ENTRY-STUB';

/// Pumps [VerifyResultPage] at a private `/result` location over a bloc wired
/// through [FakeVerifyRepository], plus the two stub destinations the page's
/// buttons navigate to.
///
/// The surface is tall on purpose, the same reason
/// `history_test_helper.dart`'s `pumpHistoryPage` gives: the page's body is a
/// `ListView`, and a default ~390x600 test viewport lays out only the
/// children that fit it — the PDF-check button below the details and checks
/// cards would never be built (and so never found) without the extra height.
Future<VerifyBloc> pumpPage(
  WidgetTester tester,
  FakeVerifyRepository repository, {
  Size surface = const Size(390, 4000),
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = surface;
  addTearDown(tester.view.reset);

  final VerifyBloc bloc = verifyBlocOver(repository);
  addTearDown(bloc.close);

  await tester.pumpWidget(
    wrapWithLocalization(
      Builder(
        builder: (BuildContext context) => MaterialApp.router(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          routerConfig: GoRouter(
            initialLocation: '/result',
            routes: <RouteBase>[
              GoRoute(
                path: '/result',
                builder: (_, __) => BlocProvider<VerifyBloc>.value(
                  value: bloc,
                  child: const VerifyResultPage(),
                ),
              ),
              GoRoute(
                path: AppNameRoutes.verifyFileCheck,
                builder: (_, __) =>
                    const Scaffold(body: Text(kFileCheckStub)),
              ),
              GoRoute(
                path: AppNameRoutes.verify,
                builder: (_, __) => const Scaffold(body: Text(kEntryStub)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return bloc;
}

/// Drives the bloc to a result through the real submission path and settles.
Future<void> submit(
  WidgetTester tester,
  VerifyBloc bloc,
  String code,
) async {
  bloc.add(VerifySubmitted(code));
  await tester.pumpAndSettle();
}

void main() {
  late FakeVerifyRepository repository;

  setUp(() {
    repository = FakeVerifyRepository();
  });

  group('the five status screens — the guide\'s "Which screen to show" table',
      () {
    testWidgets('issued → VALID with type, number, masked holder, issued '
        'date, valid_until and issuing office', (WidgetTester tester) async {
      final VerifyBloc bloc = await pumpPage(tester, repository);
      await submit(tester, bloc, 'RES-7Q4K-19XD');

      expect(find.text('Valid'), findsOneWidget);
      expect(find.text('Residence Certificate'), findsOneWidget,
          reason: 'the certificate type, the table\'s first "also show"');
      expect(find.text('LA-RES-2026-000123'), findsOneWidget);
      expect(find.text('P****** S********'), findsOneWidget,
          reason: 'the masked holder, shown exactly as the server sent it — '
              'nothing here unmasks it');
      expect(find.text('30 Sept 2026'), findsOneWidget,
          reason: 'issued_at, formatted');
      expect(find.text('29 Dec 2026'), findsOneWidget,
          reason: 'valid_until IS set on the guide\'s example, so it shows');
      expect(
        find.text('District Office of Public Security, Chanthabuly'),
        findsOneWidget,
        reason: 'issuing office',
      );
      expect(find.text("An officer's signature is on file"), findsOneWidget);
      expect(find.text('Not revoked'), findsOneWidget);
    });

    testWidgets('issued + empty CA fields → the CA/format/timestamp rows are '
        'absent, and the honest wording never says "verified"',
        (WidgetTester tester) async {
      final VerifyBloc bloc = await pumpPage(tester, repository);
      await submit(tester, bloc, 'RES-7Q4K-19XD');

      expect(find.text('Certificate authority (CA)'), findsNothing,
          reason: 'ca stays empty until the national CA is connected — show '
              'them only when non-empty');
      expect(find.text('Signature format'), findsNothing);
      expect(find.text('Timestamp'), findsNothing);

      final Iterable<String> rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((Text t) => t.data ?? t.textSpan?.toPlainText() ?? '');
      expect(
        rendered.where((String s) => s.toLowerCase().contains('verified')),
        isEmpty,
        reason: 'signature.status "recorded" must never be worded as '
            '"verified" or "valid" (§ Checks, worded honestly)',
      );
    });

    testWidgets('issued + non-empty CA fields → the three rows render with '
        'their values', (WidgetTester tester) async {
      repository.byCode = Right(issuedResultWithCa());
      final VerifyBloc bloc = await pumpPage(tester, repository);
      await submit(tester, bloc, 'RES-7Q4K-19XD');

      expect(find.text('Certificate authority (CA)'), findsOneWidget);
      expect(find.text('National Digital CA'), findsOneWidget);
      expect(find.text('Signature format'), findsOneWidget);
      expect(find.text('PAdES-B-LT'), findsOneWidget);
      expect(find.text('Timestamp'), findsOneWidget);
      expect(find.text('2026-09-30T10:42:18+07:00'), findsOneWidget);
    });

    testWidgets('expired → EXPIRED with the valid_until date',
        (WidgetTester tester) async {
      repository.byCode = Right(expiredResult());
      final VerifyBloc bloc = await pumpPage(tester, repository);
      await submit(tester, bloc, 'RES-7Q4K-19XD');

      expect(find.text('Expired'), findsOneWidget);
      expect(find.text('29 Dec 2026'), findsOneWidget,
          reason: 'the EXPIRED row\'s "also show" is the valid_until date');
    });

    testWidgets('revoked → REVOKED with revoked_at and the reason',
        (WidgetTester tester) async {
      repository.byCode = Right(revokedResult());
      final VerifyBloc bloc = await pumpPage(tester, repository);
      await submit(tester, bloc, 'RES-7Q4K-19XD');

      expect(find.text('Revoked — do not accept'), findsOneWidget);
      expect(find.text('15 Oct 2026'), findsOneWidget, reason: 'revoked_at');
      expect(find.text('Reported lost by the holder'), findsOneWidget,
          reason: 'revoke_reason');
    });

    testWidgets('superseded → REPLACED with the replacing certificate number',
        (WidgetTester tester) async {
      repository.byCode = Right(supersededResult());
      final VerifyBloc bloc = await pumpPage(tester, repository);
      await submit(tester, bloc, 'RES-7Q4K-19XD');

      expect(find.text('Replaced — do not accept'), findsOneWidget);
      expect(find.text('LA-RES-2026-000456'), findsOneWidget,
          reason: 'replaced_by_certificate_no');
    });

    testWidgets('not-found → NOT FOUND with the rescan / retype affordance, '
        'and no checks section', (WidgetTester tester) async {
      repository.byCode = Right(notFoundResult());
      final VerifyBloc bloc = await pumpPage(tester, repository);
      await submit(tester, bloc, 'RES-0000-0000');

      expect(find.text('Not found'), findsOneWidget);
      expect(find.text('Scan the QR code again'), findsOneWidget,
          reason: 'the table\'s "invite to rescan"');
      expect(find.text('Type the code instead'), findsOneWidget,
          reason: 'the invite to retype');
      expect(find.text('Checks'), findsNothing,
          reason: 'a not-found answer has no certificate to check — its '
              'checks block (revocation: not-found) is not rendered');
    });

    testWidgets('the not-found affordances navigate — retype opens the entry '
        'page', (WidgetTester tester) async {
      repository.byCode = Right(notFoundResult());
      final VerifyBloc bloc = await pumpPage(tester, repository);
      await submit(tester, bloc, 'RES-0000-0000');

      await tester.tap(find.text('Type the code instead'));
      await tester.pumpAndSettle();
      expect(find.text(kEntryStub), findsOneWidget);
    });

    testWidgets('an unknown status renders its word as the title — the open '
        'set never crashes and never collapses to "unknown"',
        (WidgetTester tester) async {
      repository.byCode = Right(issuedResult().copyWith(status: 'suspended'));
      final VerifyBloc bloc = await pumpPage(tester, repository);
      await submit(tester, bloc, 'RES-7Q4K-19XD');

      expect(find.text('suspended'), findsOneWidget,
          reason: 'the entity\'s standing rule: a new status renders as its '
              'word');
    });
  });

  group('the record_hash gate and the PDF-check offer', () {
    testWidgets('mismatch → the warn renders and the PDF-check button offers '
        'itself, wired to its route', (WidgetTester tester) async {
      repository.byCode = Right(issuedResult()
          .copyWith(
            checks: issuedResult().checks.copyWith(
                  recordHash: issuedResult().checks.recordHash.copyWith(
                        status: 'mismatch',
                      ),
                ),
          ));
      final VerifyBloc bloc = await pumpPage(tester, repository);
      await submit(tester, bloc, 'RES-7Q4K-19XD');

      expect(
        find.text("The server's stored copy could not be confirmed"),
        findsOneWidget,
        reason: 'the mismatch warn',
      );
      expect(find.text('Check a PDF file'), findsOneWidget);

      await tester.tap(find.text('Check a PDF file'));
      await tester.pumpAndSettle();
      expect(find.text(kFileCheckStub), findsOneWidget,
          reason: 'the button is wired now; Task 7 replaces the destination '
              'page, not the gate');
    });

    testWidgets('match → the check states itself and the PDF-check button '
        'still offers (the guide offers it whenever record_hash is not '
        'missing)', (WidgetTester tester) async {
      final VerifyBloc bloc = await pumpPage(tester, repository);
      await submit(tester, bloc, 'RES-7Q4K-19XD');

      expect(
        find.text("The server's stored file matches the issued fingerprint"),
        findsOneWidget,
      );
      expect(find.text('Check a PDF file'), findsOneWidget);
    });

    testWidgets('missing → the row explains the absence and the PDF-check '
        'button is HIDDEN', (WidgetTester tester) async {
      repository.byCode = Right(issuedResult()
          .copyWith(
            checks: issuedResult().checks.copyWith(
                  recordHash: issuedResult().checks.recordHash.copyWith(
                        status: 'missing',
                      ),
                ),
          ));
      final VerifyBloc bloc = await pumpPage(tester, repository);
      await submit(tester, bloc, 'RES-7Q4K-19XD');

      expect(find.text('No stored file fingerprint (older certificate)'),
          findsOneWidget);
      expect(find.text('Check a PDF file'), findsNothing,
          reason: 'an old certificate has no stored fingerprint, so a genuine '
              'file could never match — § Checking a PDF on the device');
    });
  });

  group('the non-result states', () {
    testWidgets('loading renders the checking state, not a stale result',
        (WidgetTester tester) async {
      // A Completer the test controls: with none, the fake's answer
      // resolves on the same microtask flush a plain `pump()` performs, and
      // `loading` is never the frame on screen to find — see the fake's own
      // doc for why this is a Completer and not a real timer.
      final Completer<Either<Failure, VerificationResult>> pending =
          Completer<Either<Failure, VerificationResult>>();
      repository.pendingByCode = pending;
      final VerifyBloc bloc = await pumpPage(tester, repository);
      bloc.add(const VerifySubmitted('RES-7Q4K-19XD'));
      // TWO plain pumps, not one and not `pumpAndSettle`. One is not
      // enough: `bloc.add` delivers through the bloc's own event stream and
      // `BlocConsumer` listens on a second stream, both async-scheduled, so
      // a single `pump()` builds a frame before either hop lands (found 0,
      // not a stale "Valid" — measured). `pumpAndSettle` is not the fix
      // either and was tried first: `_CheckingBody` renders a
      // `CircularProgressIndicator`, whose indeterminate animation never
      // stops scheduling frames, so `pumpAndSettle` never sees "settled"
      // and throws `pumpAndSettle timed out` (also measured). Two bounded
      // pumps is what actually lands on the `loading` frame.
      await tester.pump();
      await tester.pump();

      expect(find.text('Checking…'), findsOneWidget);
      expect(find.text('Valid'), findsNothing);

      // Settle the pending answer so nothing outlives this test.
      pending.complete(Right(issuedResult()));
      await tester.pumpAndSettle();
    });

    testWidgets('429 renders the wait-a-minute screen, with no retry affordance'
        ' that could be wired into a loop', (WidgetTester tester) async {
      repository.byCode = const Left(TooManyRequestsFailure('too many'));
      final VerifyBloc bloc = await pumpPage(tester, repository);
      await submit(tester, bloc, 'RES-7Q4K-19XD');

      expect(find.text('Too many checks'), findsOneWidget);
      expect(find.text('Please wait a minute, then try again.'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing,
          reason: '"never retry in a loop" — the screen offers no button');
    });

    testWidgets('a generic failure renders the server\'s own sentence',
        (WidgetTester tester) async {
      repository.byCode = const Left(Failure('The server could not be reached.'));
      final VerifyBloc bloc = await pumpPage(tester, repository);
      await submit(tester, bloc, 'RES-7Q4K-19XD');

      expect(find.text('The server could not be reached.'), findsOneWidget,
          reason: 'Task 3 folds the API sentence into Failure.message; the '
              'page renders it verbatim');
    });
  });
}

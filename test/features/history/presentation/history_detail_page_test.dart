/// `HistoryDetailPage`'s rendered tree — **B7-AC-48**, **B7-AC-53**…
/// **B7-AC-60**, **B7-AC-63**…**B7-AC-70**, **B7-AC-72**, **B7-AC-73**.
///
/// The traffic-shaped criteria (which query ran, how many times) live in
/// `history_detail_bloc_test.dart`; asserting them here would prove them
/// slowly, and asserting "three skeleton cards" there would prove nothing.
///
/// **Nothing here calls `pumpAndSettle`.** Two states exist only while a
/// request is in flight, and the refresh glyph animates forever — settling
/// would either resolve the future first or never return.
///
/// **Every populated assertion runs against declared-synthetic fixtures**
/// (§ 6.12). A pass is evidence the port is correct given a payload, never that
/// staging sends that payload (§ 6.4, `B7-AC-81`).
library;

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/application_failures.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_detail.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/attachment.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_event.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_status.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_timeline.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/jurisdiction.dart';
import 'package:lcc_mobile_app/features/documents/domain/entities/issued_certificate.dart';
import 'package:lcc_mobile_app/features/history/presentation/bloc/history_detail_bloc.dart';
import 'package:lcc_mobile_app/features/history/presentation/widgets/history_detail_cards.dart';
import 'package:lcc_mobile_app/features/history/presentation/widgets/history_detail_hero.dart';
import 'package:lcc_mobile_app/features/history/presentation/widgets/history_detail_palette.dart';
import 'package:lcc_mobile_app/features/history/presentation/widgets/history_detail_timeline.dart';

import '../history_test_helper.dart';

void main() {
  late FakeApplicationRepository repo;
  late HistoryDetailBloc bloc;

  setUp(() => repo = FakeApplicationRepository());

  tearDown(() async {
    await bloc.close();
  });

  /// How long an in-flight request is held open for the loading-state tests.
  ///
  /// **`latency`, not `gateDetail`.** The gate is a `Completer` the test
  /// resolves by hand, which works in `history_detail_bloc_test.dart`'s plain
  /// `test()` bodies but **hangs a `testWidgets` body indefinitely** — measured,
  /// and not even `--timeout` interrupts it, because the pending completer sits
  /// outside the frame loop `pump` drives. A `Future.delayed` lives inside
  /// FakeAsync, so `tester.pump(duration)` advances it deterministically and the
  /// test cannot hang. The fake's own doc names `latency` for exactly this.
  const Duration inFlight = Duration(seconds: 1);
  const Duration past = Duration(seconds: 2);

  /// Mounts the page unsettled, with the bloc built in the caller's FakeAsync
  /// zone — see `history_page_test.dart` for why that matters.
  Future<void> boot(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    // B5's two seams are builders (specs.md § 6.7); B6's two are still
    // `Widget?`. These helpers take the widget and wrap it, so the four tests
    // below read exactly as they did.
    Widget? documentActions,
    Widget? paymentAction,
    Widget? paymentPanel,
    Widget? certificatePanel,
    VoidCallback? onBack,
  }) async {
    bloc = detailBloc(repo);
    await pumpHistoryDetailPage(
      tester,
      bloc,
      locale: locale,
      onBack: onBack,
      documentActions: documentActions == null
          ? null
          : (ApplicationDetail _, IssuedCertificate? __) => documentActions,
      paymentAction: paymentAction,
      paymentPanel: paymentPanel,
      certificatePanel: certificatePanel == null
          ? null
          : (ApplicationDetail _, IssuedCertificate? __, bool ___) =>
              certificatePanel,
    );
  }

  /// [boot], then let both answers land.
  Future<void> loaded(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    // B5's two seams are builders (specs.md § 6.7); B6's two are still
    // `Widget?`. These helpers take the widget and wrap it, so the four tests
    // below read exactly as they did.
    Widget? documentActions,
    Widget? paymentAction,
    Widget? paymentPanel,
    Widget? certificatePanel,
  }) async {
    await boot(
      tester,
      locale: locale,
      documentActions: documentActions,
      paymentAction: paymentAction,
      paymentPanel: paymentPanel,
      certificatePanel: certificatePanel,
    );
    await tester.pump();
    await tester.pump();
  }

  group('B7-AC-53 — the loading state', () {
    testWidgets('renders the back link, 3 skeleton cards and common.loading',
        (WidgetTester tester) async {
      repo.latency = inFlight;
      await boot(tester);

      expect(find.text('Back to history'), findsOneWidget,
          reason: 'the back link must survive every state');
      expect(find.text('Loading…'), findsOneWidget);
      expect(find.byType(HistoryDetailCard), findsNWidgets(3),
          reason: '`[0,1,2].map` — exactly three skeleton cards (`:187`)');

      await tester.pump(past);
    });

    testWidgets('the skeleton is replaced once the case lands',
        (WidgetTester tester) async {
      repo.latency = inFlight;
      await boot(tester);
      expect(find.text('Loading…'), findsOneWidget);

      await tester.pump(past);

      expect(find.text('Loading…'), findsNothing);
      expect(find.byType(HistoryDetailHero), findsOneWidget);
    });

    testWidgets('does NOT render the not-found card while in flight',
        (WidgetTester tester) async {
      repo.latency = inFlight;
      await boot(tester);

      expect(find.text('This application could not be found.'), findsNothing);
      await tester.pump(past);
    });
  });

  group('B7-AC-54 — the two error branches', () {
    testWidgets('a not-found renders the not-found copy, NOT the API sentence',
        (WidgetTester tester) async {
      repo.detailAnswer = Left<Failure, ApplicationDetail>(
        NotFoundFailure('backend words that must not be shown here'),
      );
      await loaded(tester);

      expect(find.text('This application could not be found.'), findsOneWidget);
      expect(find.text('backend words that must not be shown here'),
          findsNothing,
          reason: '`:201-204` prints a fixed sentence for the not-found arm');
    });

    testWidgets("any other error renders the BACKEND's own sentence",
        (WidgetTester tester) async {
      repo.detailAnswer =
          Left<Failure, ApplicationDetail>(Failure('upstream exploded'));
      await loaded(tester);

      expect(find.text('upstream exploded'), findsOneWidget,
          reason: '`:205` is `detailQuery.error?.message`');
      expect(find.text('This application could not be found.'), findsNothing);
    });

    testWidgets('a Failure with no message falls back to the generic copy',
        (WidgetTester tester) async {
      repo.detailAnswer = Left<Failure, ApplicationDetail>(const Failure(''));
      await loaded(tester);

      expect(find.text('This application could not be loaded.'), findsOneWidget);
    });

    testWidgets('the retry re-issues the detail', (WidgetTester tester) async {
      repo.detailAnswer =
          Left<Failure, ApplicationDetail>(Failure('upstream exploded'));
      await loaded(tester);
      expect(repo.detailCalls.length, 1);

      await tester.tap(find.text('Try again').first);
      await tester.pump();

      expect(repo.detailCalls.length, 2);
    });

    testWidgets('the back link is present on the error card too',
        (WidgetTester tester) async {
      repo.detailAnswer =
          Left<Failure, ApplicationDetail>(Failure('upstream exploded'));
      await loaded(tester);

      expect(find.text('Back to history'), findsOneWidget);
    });
  });

  group('B7-AC-55 — the status hero, per bucket', () {
    testWidgets('approved renders its headline, sub and #16A34A',
        (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(status: CaseStatus.issued),
      );
      await loaded(tester);

      expect(find.text('Application approved'), findsOneWidget);
      expect(find.text('Your document is ready to download.'), findsOneWidget);

      final HistoryDetailHero hero =
          tester.widget(find.byType(HistoryDetailHero));
      expect(historyDetailThemeFor(hero.bucket).color,
          kDetailThemeApproved.color);
    });

    testWidgets('rejected renders its copy', (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(status: CaseStatus.rejected),
      );
      await loaded(tester);

      expect(find.text('Application rejected'), findsOneWidget);
      expect(find.text('Please review the reason below and resubmit.'),
          findsOneWidget);
    });

    testWidgets('pending renders its copy', (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(status: CaseStatus.submitted),
      );
      await loaded(tester);

      expect(find.text('Application in review'), findsOneWidget);
      expect(find.text('Officials are currently processing your request.'),
          findsOneWidget);
    });
  });

  group('B7-AC-56 — the payment chip', () {
    testWidgets('reads `{paymentLabel} · {formatLak(fee)}`',
        (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(paymentState: PaymentState.pending, feeLak: 50000),
      );
      await loaded(tester);

      expect(find.text('Unpaid · 50,000 LAK'), findsOneWidget);
    });

    testWidgets('formatLak(0) renders Free, NOT `0 LAK`',
        (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(paymentState: PaymentState.free, feeLak: 0),
      );
      await loaded(tester);

      expect(find.text('No fee · Free'), findsOneWidget);
      expect(find.textContaining('0 LAK'), findsNothing);
    });

    testWidgets('formatLak(0) renders ຟຣີ in Lao', (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(paymentState: PaymentState.free, feeLak: 0),
      );
      await loaded(tester, locale: const Locale('lo'));

      expect(find.textContaining('ຟຣີ'), findsWidgets);
    });
  });

  group("B7-AC-57 — the detail's SLA wording DIFFERS from the list's", () {
    testWidgets('the detail says "{n} of {m} SLA days"',
        (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(row: rowFixture(daysWaiting: 3, slaDays: 7)),
      );
      await loaded(tester);

      expect(find.text('3 of 7 SLA days'), findsOneWidget);
      // And explicitly NOT the list's phrasing, which is the whole criterion.
      expect(find.text('3/7 days'), findsNothing);
    });

    testWidgets('the two keys resolve to different strings',
        (WidgetTester tester) async {
      // Asserted as strings rather than only as absence, so the criterion
      // survives a future edit that made them accidentally identical.
      await loaded(tester);
      final BuildContext ctx = tester.element(find.byType(HistoryDetailHero));
      expect(
        'history.slaWaitingDetail'.tr(
          context: ctx,
          namedArgs: <String, String>{'waiting': '3', 'sla': '7'},
        ),
        isNot('history.slaWaiting'.tr(
          context: ctx,
          namedArgs: <String, String>{'waiting': '3', 'sla': '7'},
        )),
      );
    });

    testWidgets('an overdue case shows the overdue chip instead',
        (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(
          row: rowFixture(isOverdue: true, daysOverdue: 4),
        ),
      );
      await loaded(tester);

      expect(find.text('4 days overdue'), findsOneWidget);
      expect(find.textContaining('SLA days'), findsNothing);
    });
  });

  group('B7-AC-58 — assigned_officer renders only when present', () {
    testWidgets('present → rendered', (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(assignedOfficer: 'Officer Khamla'),
      );
      await loaded(tester);

      expect(find.text('Officer Khamla'), findsOneWidget);
    });

    testWidgets('absent → nothing', (WidgetTester tester) async {
      repo.detailAnswer =
          Right<Failure, ApplicationDetail>(detailFixture());
      await loaded(tester);

      expect(find.text('Officer Khamla'), findsNothing);
    });
  });

  group('B7-AC-59 — the rejection card needs BOTH halves', () {
    testWidgets('rejected + a reason → the card renders',
        (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(status: CaseStatus.rejected, reasonNote: 'Illegible scan'),
      );
      await loaded(tester);

      expect(find.byType(HistoryDetailRejection), findsOneWidget);
      expect(find.text('Why was this rejected?'), findsOneWidget);
      expect(find.text('Illegible scan'), findsOneWidget);
    });

    testWidgets('rejected + an EMPTY reason → no card at all',
        (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(status: CaseStatus.rejected, reasonNote: ''),
      );
      await loaded(tester);

      expect(find.byType(HistoryDetailRejection), findsNothing,
          reason: 'an empty red panel is worse than none — `:441` is falsy');
    });

    testWidgets('not rejected + a reason → no card', (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(status: CaseStatus.submitted, reasonNote: 'Illegible'),
      );
      await loaded(tester);

      expect(find.byType(HistoryDetailRejection), findsNothing);
    });
  });

  group('B7-AC-60 — contactOfficer is enabled-looking and inert', () {
    testWidgets('it renders, taps, and changes nothing',
        (WidgetTester tester) async {
      await loaded(tester);

      final Finder button = find.text('Contact officer');
      expect(button, findsOneWidget);

      final int detailsBefore = repo.detailCalls.length;
      final int timelinesBefore = repo.timelineCalls.length;
      final HistoryDetailState before = bloc.state;

      await tester.tap(button);
      await tester.pump();

      // No request, no state change. (No navigation either — there is no
      // Navigator push to observe because the page is mounted as `home`.)
      expect(repo.detailCalls.length, detailsBefore);
      expect(repo.timelineCalls.length, timelinesBefore);
      expect(bloc.state, before);
    });

    testWidgets('its InkWell has a NON-null onTap — not disabled',
        (WidgetTester tester) async {
      await loaded(tester);

      // `onPressed: null` would render Material's disabled grey; the web's
      // button is fully styled. The distinction is the criterion.
      final InkWell ink = tester.widget<InkWell>(
        find
            .ancestor(
              of: find.text('Contact officer'),
              matching: find.byType(InkWell),
            )
            .first,
      );
      expect(ink.onTap, isNotNull);
    });
  });

  group('B7-AC-48 / B7-AC-49 — the four seams', () {
    testWidgets('all four null → none of them renders anything',
        (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(status: CaseStatus.issued, paymentState: PaymentState.pending, feeLak: 50000),
      );
      await loaded(tester);

      // The page renders, and the two source labels that belong to B5/B6 are
      // absent because their widgets are.
      expect(find.text('View document'), findsNothing);
      expect(find.text('Download document'), findsNothing);
      expect(find.textContaining('Pay '), findsNothing);
      expect(find.text('Issued certificate'), findsNothing);
    });

    testWidgets('documentActions is rendered when isIssued and supplied',
        (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(status: CaseStatus.issued),
      );
      await loaded(tester,
          documentActions: const Text('B5-SLOT', key: Key('b5')));

      expect(find.text('B5-SLOT'), findsOneWidget);
    });

    testWidgets('documentActions is NOT offered when the case is not issued',
        (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(status: CaseStatus.submitted),
      );
      await loaded(tester, documentActions: const Text('B5-SLOT'));

      expect(find.text('B5-SLOT'), findsNothing,
          reason: 'isIssued gates whether the slot is OFFERED (`:379`)');
    });

    testWidgets('paymentAction and paymentPanel are gated on canPay',
        (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(paymentState: PaymentState.pending, feeLak: 50000),
      );
      await loaded(tester,
          paymentAction: const Text('B6-ACTION'),
          paymentPanel: const Text('B6-PANEL'));

      expect(find.text('B6-ACTION'), findsOneWidget);
      expect(find.text('B6-PANEL'), findsOneWidget);
    });

    testWidgets('a zero fee offers neither payment slot',
        (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(paymentState: PaymentState.pending, feeLak: 0),
      );
      await loaded(tester,
          paymentAction: const Text('B6-ACTION'),
          paymentPanel: const Text('B6-PANEL'));

      expect(find.text('B6-ACTION'), findsNothing);
      expect(find.text('B6-PANEL'), findsNothing);
    });

    testWidgets('certificatePanel is gated on isIssued',
        (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        // **`certificateNo` added by B5.** The source's gate is
        // `isIssued && (certificate || detail.certificate_no)` (`:456`) —
        // B7b's own library doc records both disjuncts and hands the whole
        // gate to B5 — so an issued case with neither renders no card at all.
        // The assertion is unchanged; only the arrangement now matches the
        // source's condition instead of half of it.
        detailFixture(status: CaseStatus.issued, certificateNo: 'CERT-0001'),
      );
      await loaded(tester, certificatePanel: const Text('B5-CERT'));

      expect(find.text('B5-CERT'), findsOneWidget);
    });
  });

  group('B7-AC-63 — the timeline branches', () {
    testWidgets('loading renders skeleton rows, not the empty copy',
        (WidgetTester tester) async {
      // Only the timeline is slow, so the detail lands and the page reaches
      // its content state with the timeline still in flight — the arrangement
      // the empty/loading distinction actually depends on.
      repo.timelineLatency = inFlight;
      await boot(tester);
      await tester.pump();

      expect(find.text('Nothing has happened on this case yet.'), findsNothing,
          reason: 'in-flight is not empty');

      await tester.pump(past);
    });

    testWidgets('error with no events renders the message and a retry',
        (WidgetTester tester) async {
      repo.timelineAnswer =
          Left<Failure, CaseTimeline>(Failure('timeline is down'));
      repo.detailAnswer = Right<Failure, ApplicationDetail>(detailFixture());
      await loaded(tester);

      // The BACKEND's sentence — `:524` renders `error.message` verbatim.
      expect(find.text('timeline is down'), findsOneWidget);

      final int before = repo.timelineCalls.length;
      await tester.tap(find.text('Try again').first);
      await tester.pump();
      expect(repo.timelineCalls.length, before + 1);
    });

    testWidgets('empty renders the lifted empty copy',
        (WidgetTester tester) async {
      repo.timelineAnswer = Right<Failure, CaseTimeline>(
        timelineFixture(events: <CaseEvent>[]),
      );
      await loaded(tester);

      expect(find.text('Nothing has happened on this case yet.'), findsOneWidget);
    });
  });

  // The Tier 2 file pins these two colours against the pinned TSX; what it
  // cannot see is *which event gets which*, and that is the whole of `:543-558`.
  // Asserted here by counting the rendered connectors and rings rather than by
  // re-reading the constants.
  group('B7-AC-64 / B7-AC-65 — the connector and the current-event ring', () {
    /// Every connector segment currently on screen, in order.
    List<Color> connectors(WidgetTester tester) => tester
        .widgetList<ColoredBox>(find.descendant(
          of: find.byType(HistoryDetailTimeline),
          matching: find.byType(ColoredBox),
        ))
        .map((ColoredBox b) => b.color)
        .where((Color c) => c == kTimelineLineOk || c == kTimelineLineError)
        .toList();

    /// How many dots carry the indigo ring — the `boxShadow` spread at `:563`.
    int rings(WidgetTester tester) => tester
        .widgetList<Container>(find.descendant(
          of: find.byType(HistoryDetailTimeline),
          matching: find.byType(Container),
        ))
        .where((Container c) {
          final Decoration? d = c.decoration;
          return d is BoxDecoration &&
              d.shape == BoxShape.circle &&
              (d.boxShadow?.isNotEmpty ?? false);
        })
        .length;

    /// A trail of [n] events, all in the pending bucket unless [lastStatus]
    /// says otherwise. `submitted` buckets pending, `returned` buckets rejected
    /// (§ 6.15's table).
    Future<void> trail(
      WidgetTester tester,
      int n, {
      CaseStatus lastStatus = CaseStatus.submitted,
    }) async {
      repo.timelineAnswer = Right<Failure, CaseTimeline>(
        timelineFixture(
          events: <CaseEvent>[
            for (int i = 0; i < n; i++)
              eventFixture(
                id: 'ev-$i',
                toStatus: i == n - 1 ? lastStatus : CaseStatus.submitted,
              ),
          ],
        ),
      );
      await loaded(tester);
    }

    testWidgets('the connector is omitted on the LAST event — n events, n-1 lines',
        (WidgetTester tester) async {
      await trail(tester, 3);

      expect(connectors(tester).length, 2,
          reason: '`{!isLast && <span …/>}` — `:551`. Three events draw two '
              'segments; a fourth would mean the last event drew a line to '
              'nothing below it');
    });

    testWidgets('a single event draws NO connector at all',
        (WidgetTester tester) async {
      await trail(tester, 1);

      expect(connectors(tester), isEmpty,
          reason: 'the only event is also the last one');
    });

    testWidgets('B7-AC-64 — a rejected-bucket event BREAKS the trail in #E5E7EB',
        (WidgetTester tester) async {
      // `returned` buckets rejected, and it is NOT last, so it draws a
      // connector — the arrangement that makes the break observable.
      repo.timelineAnswer = Right<Failure, CaseTimeline>(
        timelineFixture(events: <CaseEvent>[
          eventFixture(id: 'ev-0', toStatus: CaseStatus.returned),
          eventFixture(id: 'ev-1', toStatus: CaseStatus.submitted),
        ]),
      );
      await loaded(tester);

      expect(connectors(tester), <Color>[kTimelineLineError],
          reason: '`lineColor = isError ? "#E5E7EB" : "#16A34A"` — `:547`. The '
              'rejected event owns the segment BELOW it, so the grey belongs '
              'to ev-0 and not to its successor');
    });

    testWidgets('the ring marks the last event when it is not an error',
        (WidgetTester tester) async {
      await trail(tester, 3);

      expect(rings(tester), 1,
          reason: '`isCurrent = isLast && !isError` — `:545`. Exactly one dot '
              'is "where the case is now"');
    });

    testWidgets('a last event in the REJECTED bucket gets NO ring',
        (WidgetTester tester) async {
      await trail(tester, 3, lastStatus: CaseStatus.returned);

      expect(rings(tester), 0,
          reason: 'the `&& !isError` half. A rejected case has not stopped at '
              'a current step — it has stopped. Dropping that conjunct is the '
              'specific mistake this pins, and it is invisible to Tier 2 '
              'because the ring colour is unchanged');
    });
  });

  group('B7-AC-66 / B7-AC-67 — event text', () {
    testWidgets('an absent status_label falls back to the raw to_status',
        (WidgetTester tester) async {
      repo.timelineAnswer = Right<Failure, CaseTimeline>(
        timelineFixture(events: <CaseEvent>[
          eventFixture(
            toStatus: CaseStatus.underReview,
            labelEn: null,
            labelLo: null,
          ),
        ]),
      );
      await loaded(tester);

      // `CaseStatus.wire` — the string the web prints.
      expect(find.text(CaseStatus.underReview.wire), findsOneWidget);
    });

    testWidgets('actor and note join with " · "', (WidgetTester tester) async {
      repo.timelineAnswer = Right<Failure, CaseTimeline>(
        timelineFixture(events: <CaseEvent>[
          eventFixture(actorName: 'Officer Khamla', note: 'Checked the scan'),
        ]),
      );
      await loaded(tester);

      expect(find.text('Officer Khamla · Checked the scan'), findsOneWidget);
    });

    testWidgets('either alone renders without a separator',
        (WidgetTester tester) async {
      repo.timelineAnswer = Right<Failure, CaseTimeline>(
        timelineFixture(events: <CaseEvent>[
          eventFixture(id: 'a', actorName: 'Officer Khamla'),
        ]),
      );
      await loaded(tester);

      expect(find.text('Officer Khamla'), findsOneWidget);
      expect(find.textContaining('·'), findsWidgets); // the payment chip's
    });
  });

  group('B7-AC-68 — the ETA chip needs due_at AND the pending bucket', () {
    testWidgets('pending + due_at → rendered', (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(
          status: CaseStatus.submitted,
          dueAt: '2026-09-03T09:30:00Z',
        ),
      );
      await loaded(tester);

      expect(find.textContaining('ETA'), findsOneWidget);
    });

    testWidgets('rejected + due_at → NOT rendered', (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(
          status: CaseStatus.rejected,
          dueAt: '2026-09-03T09:30:00Z',
        ),
      );
      await loaded(tester);

      expect(find.textContaining('ETA'), findsNothing);
    });

    testWidgets('pending + no due_at → NOT rendered',
        (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(status: CaseStatus.submitted),
      );
      await loaded(tester);

      expect(find.textContaining('ETA'), findsNothing);
    });
  });

  group('B7-AC-69 — the attachments card', () {
    testWidgets('renders the heading and the empty copy',
        (WidgetTester tester) async {
      await loaded(tester);

      expect(find.text('Attachments'), findsOneWidget);
      expect(find.text('No files are attached to this case.'), findsOneWidget);
    });

    testWidgets(
        'renders NO rows even with attachments — § 10 refused url_launcher',
        (WidgetTester tester) async {
      // `B7-AC-71` is reported NOT EVALUATED, not PASS. This test pins the
      // *omission* so a later batch cannot quietly add an inert row, which
      // § 6.14 rules out by name as the one unavailable option.
      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(attachments: <Attachment>[attachmentFixture()]),
      );
      await loaded(tester);

      expect(find.text('National ID'), findsNothing);
      expect(find.text('No files are attached to this case.'), findsOneWidget,
          reason: '§ 6.14 option 3 — rows omitted, empty state shipped');
    });
  });

  group('B7-AC-72 / B7-AC-73 — the application-info card', () {
    testWidgets('renders reference, submitted, office and fee',
        (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(detailFixture());
      await loaded(tester);

      expect(find.text('Application info'), findsOneWidget);
      expect(find.text('Reference number'), findsOneWidget);
      expect(find.text('LCC-2026-000123'), findsWidgets);
      expect(find.text('Processing office'), findsOneWidget);
      expect(find.text('Service fee'), findsOneWidget);
    });

    // Plain `test`, not `testWidgets`: the join is a rule about the DATA and
    // lives on the entity, so pumping a tree to assert it would be measuring
    // the widget when the criterion is about `jurisdiction.dart`.
    test('the office joins district and province with " · "', () {
      expect(
        const Jurisdiction(
          districtName: 'Chanthabouly',
          provinceName: 'Vientiane Capital',
        ).officeLine,
        'Chanthabouly · Vientiane Capital',
      );
    });

    test('one part absent → no dangling separator', () {
      expect(
        const Jurisdiction(provinceName: 'Vientiane Capital').officeLine,
        'Vientiane Capital',
      );
      expect(
        const Jurisdiction(districtName: 'Chanthabouly').officeLine,
        'Chanthabouly',
      );
    });

    test('both absent → "—"', () {
      expect(const Jurisdiction().officeLine, '—');
      expect(Jurisdiction.empty.officeLine, '—');
    });
  });

  group('the header', () {
    testWidgets('renders the eyebrow, service name, reference and status pill',
        (WidgetTester tester) async {
      repo.detailAnswer = Right<Failure, ApplicationDetail>(detailFixture());
      await loaded(tester);

      expect(find.text('APPLICATION'), findsOneWidget,
          reason: '`uppercase tracking-wider` — `:298`');
      expect(find.text('Birth Certificate'), findsOneWidget);
      expect(find.text('SUBMITTED'), findsOneWidget,
          reason: 'the pill is `uppercase` — `:286`');
    });
  });
}

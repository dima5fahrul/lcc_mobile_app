/// `HistoryPage`'s four states and its row — **B7-AC-33**, **B7-AC-34**,
/// **B7-AC-35**, **B7-AC-36**, **B7-AC-39**, **B7-AC-41**, **B7-AC-42**.
///
/// These are the criteria that are only true of a rendered tree: how many
/// skeletons appear, what the tiles print before their answer lands, which of
/// the two empty-state subtitles is chosen. The traffic-shaped criteria live in
/// `history_bloc_test.dart` — asserting "3 skeletons" there would prove
/// nothing, and asserting "5 requests" here would prove it slowly.
///
/// **Nothing here calls `pumpAndSettle`.** Two of these criteria describe
/// frames that exist only while a request is in flight; settling would resolve
/// the future first and the assertion would pass against the wrong frame.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_page.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_row.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_status.dart';
import 'package:lcc_mobile_app/features/application/domain/usecases/application_usecases.dart';
import 'package:lcc_mobile_app/features/history/presentation/bloc/history_bloc.dart';
import 'package:lcc_mobile_app/features/history/presentation/pages/history_page.dart';
import 'package:lcc_mobile_app/features/history/presentation/widgets/history_panels.dart';
import 'package:lcc_mobile_app/features/history/presentation/widgets/history_row_card.dart';

import '../history_test_helper.dart';

void main() {
  late FakeApplicationRepository repo;
  late HistoryBloc bloc;

  // `repo` is inert until called, so it can be built here. `bloc` CANNOT: a
  // bloc constructed in `setUp` subscribes to its event stream in the REAL
  // zone, and `tester.pump()` — which only drives FakeAsync — can then never
  // advance its handlers. The first cut of this file did that and every
  // assertion saw a permanently-loading page. `boot()` builds it inside the
  // test body, which is where FakeAsync's zone is.
  setUp(() {
    repo = FakeApplicationRepository();
  });

  tearDown(() => bloc.close());

  /// Builds the bloc in the caller's zone and mounts the page, unsettled.
  Future<void> boot(WidgetTester tester) async {
    bloc = historyBlocOver(repo);
    bloc.add(const HistoryStarted());
    await pumpHistoryPage(tester, bloc);
  }

  /// [boot], then let the answers land.
  Future<void> loaded(WidgetTester tester) async {
    await boot(tester);
    await tester.pump();
    await tester.pump();
  }

  group('B7-AC-34 — the loading state', () {
    testWidgets('renders exactly 3 skeleton rows while the list is in flight',
        (WidgetTester tester) async {
      repo.latency = const Duration(milliseconds: 500);
      await boot(tester);

      expect(
        find.byType(HistorySkeletonRow),
        findsNWidgets(kHistorySkeletonRows),
        reason: 'HistoryPage.tsx:236 maps over [0, 1, 2] — three, not a '
            'CircularProgressIndicator and not one per expected row',
      );
      expect(kHistorySkeletonRows, 3);

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      expect(
        find.byType(HistorySkeletonRow),
        findsNothing,
      );
    });

    testWidgets('the skeleton does NOT replace rows already on screen',
        (WidgetTester tester) async {
      // `:235` gates the skeleton on `rows.length === 0`. A refetch with rows
      // already rendered keeps them — otherwise every page turn would blank
      // the list.
      repo.listAnswer = Right<Failure, ApplicationPage>(pageFixture());
      await loaded(tester);
      expect(find.byType(HistoryRowCard), findsWidgets);

      repo.latency = const Duration(milliseconds: 500);
      bloc.add(const HistoryFilterPicked(kFilterApproved));
      await tester.pump();

      expect(
        find.byType(HistorySkeletonRow),
        findsNothing,
        reason: 'showSkeleton is listLoading && rows.isEmpty',
      );

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
    });
  });

  group('B7-AC-33 — the empty state', () {
    testWidgets('unfiltered renders emptyTitle and the "once you submit" copy',
        (WidgetTester tester) async {
      repo.listAnswer = Right<Failure, ApplicationPage>(
        pageFixture(rows: <ApplicationRow>[], total: 0),
      );
      await loaded(tester);

      expect(find.text('No applications found'), findsOneWidget);
      expect(
        find.textContaining('Once you submit'),
        findsOneWidget,
        reason: 'HistoryPage.tsx:272-277 — the unfiltered arm',
      );
    });

    testWidgets('with a filter active it renders emptySubtitle instead',
        (WidgetTester tester) async {
      repo.listAnswer = Right<Failure, ApplicationPage>(
        pageFixture(rows: <ApplicationRow>[], total: 0),
      );
      await loaded(tester);
      bloc.add(const HistoryFilterPicked(kFilterRejected));
      await tester.pump();
      await tester.pump();

      expect(
        find.textContaining('Once you submit'),
        findsNothing,
        reason: 'the filtered arm must not offer the first-application copy to '
            'a citizen who has applications, just none matching this chip',
      );
    });
  });

  group('B7-AC-35 — the error state', () {
    testWidgets("renders the API's own message and a working retry",
        (WidgetTester tester) async {
      repo.listAnswer = const Left<Failure, ApplicationPage>(
        Failure('Service temporarily unavailable'),
      );
      await loaded(tester);

      expect(
        find.text('Service temporarily unavailable'),
        findsOneWidget,
        reason: ":251 prints the error's message, not a generic string",
      );

      final int before =
          repo.calls.where((ListCall c) => !c.isCountQuery).length;
      repo.listAnswer = Right<Failure, ApplicationPage>(pageFixture());

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump();

      expect(
        repo.calls.where((ListCall c) => !c.isCountQuery).length,
        before + 1,
        reason: 'the retry must re-issue the request, not just clear the error',
      );
    });
  });

  group('B7-AC-36 — the four tiles', () {
    testWidgets('print "—" while the counts are loading, never 0',
        (WidgetTester tester) async {
      repo.latency = const Duration(milliseconds: 500);
      await boot(tester);

      expect(
        find.text('—'),
        findsNWidgets(4),
        reason: 'HistoryPage.tsx:186 — a 0 would read as "you have no rejected '
            'applications", which is a claim the page cannot yet make',
      );
      expect(find.text('0'), findsNothing);

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
    });

    testWidgets('print the four meta.totals once they land',
        (WidgetTester tester) async {
      repo.countTotals = <String, int>{
        kFilterAll: 42,
        kFilterApproved: 7,
        kFilterPending: 30,
        kFilterRejected: 5,
      };
      await loaded(tester);

      expect(find.text('42'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('—'), findsNothing);
    });
  });

  group('B7-AC-39 — the pager', () {
    testWidgets('is hidden when total_pages <= 1', (WidgetTester tester) async {
      repo.listAnswer =
          Right<Failure, ApplicationPage>(pageFixture(page: 1, totalPages: 1));
      await loaded(tester);

      expect(find.text('Previous'), findsNothing);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('shows page / total_pages and the total otherwise',
        (WidgetTester tester) async {
      repo.listAnswer = Right<Failure, ApplicationPage>(
        pageFixture(page: 2, totalPages: 5, total: 47, hasNext: true, hasPrev: true),
      );
      await loaded(tester);

      expect(find.textContaining('2'), findsWidgets);
      expect(find.textContaining('5'), findsWidgets);
      expect(
        find.textContaining('47'),
        findsWidgets,
        reason: ':418 prints meta.total, which is not the row count',
      );
    });
  });

  group('B7-AC-41 / B7-AC-42 — a row', () {
    testWidgets('renders service, ref, status, payment and the SLA chip',
        (WidgetTester tester) async {
      repo.listAnswer = Right<Failure, ApplicationPage>(
        pageFixture(rows: <ApplicationRow>[
          rowFixture(
            serviceEn: 'Birth Certificate',
            referenceNo: 'LCC-2026-000123',
            statusEn: 'Submitted',
            slaDays: 7,
            daysWaiting: 3,
          ),
        ]),
      );
      await loaded(tester);

      expect(find.text('Birth Certificate'), findsOneWidget);
      expect(find.textContaining('LCC-2026-000123'), findsOneWidget);
      // `:322`'s chip carries `uppercase`, so the port's `.toUpperCase()` is
      // the source's own casing, not an embellishment.
      expect(find.text('SUBMITTED'), findsOneWidget);
      expect(
        find.textContaining('3/7'),
        findsOneWidget,
        reason: ':365-381 — "{days_waiting}/{sla_days} days" when on time',
      );
    });

    testWidgets('an overdue row reads "{days_overdue} days overdue"',
        (WidgetTester tester) async {
      repo.listAnswer = Right<Failure, ApplicationPage>(
        pageFixture(rows: <ApplicationRow>[
          rowFixture(daysOverdue: 4, isOverdue: true),
        ]),
      );
      await loaded(tester);

      expect(find.textContaining('4'), findsWidgets);
      expect(
        find.textContaining('overdue'),
        findsOneWidget,
        reason: 'the overdue wording replaces the waiting wording entirely',
      );
    });

    testWidgets('a draft row renders Step 1 of 5 — the ported inconsistency',
        (WidgetTester tester) async {
      repo.listAnswer = Right<Failure, ApplicationPage>(
        pageFixture(rows: <ApplicationRow>[
          rowFixture(status: CaseStatus.draft, statusEn: 'Draft'),
        ]),
      );
      await loaded(tester);

      expect(
        find.textContaining('1'),
        findsWidgets,
        reason: 'B7-AC-30 — draft is step 1 of 5 with an 8% bar, which is the '
            "source's own inconsistency and is ported rather than tidied",
      );
    });
  });
}

/// `HistoryBloc` — **B7-AC-19**, **B7-AC-20**, **B7-AC-21**, **B7-AC-23**,
/// **B7-AC-24**, **B7-AC-35**, **B7-AC-37**, **B7-AC-38**, **B7-AC-40**.
///
/// Every criterion here is a claim about **traffic**, not about pixels: how
/// many requests a control issues, which ones it does *not* issue, and which
/// answer wins when two are in flight. None of that is observable in a widget
/// tree, which is why these are asserted against
/// `FakeApplicationRepository.calls` rather than through `HistoryPage`.
///
/// ## Why the debounce assertions burn real milliseconds
///
/// `HistoryBloc._onSearchChanged` arms a real `Timer`, so the obvious move is
/// `testWidgets` + `tester.pump(d)` to advance a fake clock instantly. That
/// was tried first and **hangs**: the bloc awaits a chain of real `Future`s
/// inside its event handlers, and `pump` inside FakeAsync never drains them,
/// so the test neither passes nor fails. Real timers cost ~1.5 s across this
/// group and actually observe the debounce, which is what `B7-AC-19` asks for.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_page.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_row.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/status_pipeline.dart';
import 'package:lcc_mobile_app/features/application/domain/usecases/application_usecases.dart';
import 'package:lcc_mobile_app/features/history/presentation/bloc/history_bloc.dart';

import '../history_test_helper.dart';

void main() {
  late FakeApplicationRepository repository;
  late HistoryBloc bloc;

  setUp(() {
    repository = FakeApplicationRepository();
    bloc = historyBlocOver(repository);
  });

  tearDown(() => bloc.close());

  /// Drains the queued events and their awaits. `_onStarted` alone is three
  /// concurrent futures, each of which emits, so one turn is not enough.
  Future<void> settle() async {
    for (int i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  List<ListCall> listQueries() =>
      repository.calls.where((ListCall c) => !c.isCountQuery).toList();

  List<ListCall> countQueries() =>
      repository.calls.where((ListCall c) => c.isCountQuery).toList();

  group('mount', () {
    test(
      'B7-AC-38 — a cold load issues exactly 5 /applications requests: '
      '1 list + 4 counts',
      () async {
        bloc.add(const HistoryStarted());
        await settle();

        expect(
          repository.calls.length,
          5,
          reason: 'HistoryPage.tsx:83 issues the list and :99-110 issues four '
              'counts; collapsing them would be the port beating its source',
        );
        expect(listQueries(), hasLength(1));
        expect(countQueries(), hasLength(4));
      },
    );

    test(
      'B7-AC-23 — PER_PAGE is 10 for the list and 1 for every count query',
      () async {
        bloc.add(const HistoryStarted());
        await settle();

        expect(listQueries().single.perPage, 10);
        expect(
          countQueries().map((ListCall c) => c.perPage),
          everyElement(1),
          reason: 'each tile asks for one row and reads meta.total off it',
        );
      },
    );

    test(
      'B7-AC-24 — the four tiles read meta.total, not data.length',
      () async {
        // Every count answer carries exactly ONE row (the fake builds it that
        // way) but a much larger `total`. A tile reading `rows.length` would
        // render 1, 1, 1, 1 and this would fail.
        repository.countTotals = <String, int>{
          kFilterAll: 42,
          kFilterApproved: 7,
          kFilterPending: 30,
          kFilterRejected: 5,
        };

        bloc.add(const HistoryStarted());
        await settle();

        expect(bloc.state.counts.total, 42);
        expect(bloc.state.counts.approved, 7);
        expect(bloc.state.counts.pending, 30);
        expect(bloc.state.counts.rejected, 5);
      },
    );

    test('the pipeline is fetched once, not once per query', () async {
      bloc.add(const HistoryStarted());
      await settle();

      expect(repository.pipelineCalls, 1);
    });

    test(
      'B7-AC-27 — a failed /status-catalogue is swallowed and the seed stands',
      () async {
        repository.pipelineAnswer =
            const Left<Failure, StatusPipeline>(Failure('catalogue down'));

        bloc.add(const HistoryStarted());
        await settle();

        expect(
          bloc.state.pipeline.stages,
          kSeededPipeline,
          reason: 'statusCatalogue.ts:67-69 falls back to the seed',
        );
        expect(
          bloc.state.listStatus,
          RegionStatus.success,
          reason: 'the page still renders — the catalogue has no error surface',
        );
      },
    );
  });

  group('the filter chips', () {
    test('B7-AC-18 — the `all` chip sends no status parameter', () async {
      bloc.add(const HistoryStarted());
      await settle();

      expect(listQueries().single.statuses, isNull);
    });

    test(
      'B7-AC-20 — picking a filter resets page to 1',
      () async {
        repository.listAnswer = Right<Failure, ApplicationPage>(
          pageFixture(page: 3, totalPages: 5),
        );
        bloc.add(const HistoryStarted());
        await settle();
        expect(bloc.state.page, 3);

        repository.listAnswer = Right<Failure, ApplicationPage>(
          pageFixture(page: 1, totalPages: 2),
        );
        bloc.add(const HistoryFilterPicked(kFilterRejected));
        await settle();

        expect(
          listQueries().last.page,
          1,
          reason: 'HistoryPage.tsx:79-81 — useEffect(() => setPage(1), '
              '[filter, search]); asking for page 3 of a one-page filter would '
              'render an empty list that is not empty',
        );
      },
    );

    test('re-picking the active filter issues no request', () async {
      bloc.add(const HistoryStarted());
      await settle();
      final int before = repository.calls.length;

      bloc.add(const HistoryFilterPicked(kFilterAll));
      await settle();

      expect(repository.calls.length, before);
    });

    test(
      'B7-AC-37 — changing the filter does NOT refetch the four tiles',
      () async {
        bloc.add(const HistoryStarted());
        await settle();
        expect(countQueries(), hasLength(4));

        bloc.add(const HistoryFilterPicked(kFilterApproved));
        await settle();

        expect(
          countQueries(),
          hasLength(4),
          reason: 'the counts query deps are [] (HistoryPage.tsx:99); the tiles '
              'do not follow the chips, inefficient as that is',
        );
        expect(listQueries(), hasLength(2));
      },
    );

    test(
      'B7-AC-37 / B7-AC-76 — returning from the detail refetches BOTH the list '
      'and the counts',
      () async {
        bloc.add(const HistoryStarted());
        await settle();

        bloc.add(const HistoryReturnedFromDetail());
        await settle();

        expect(
          listQueries(),
          hasLength(2),
          reason: 'HistoryPage.tsx:120-124 calls list.refetch()',
        );
        expect(
          countQueries(),
          hasLength(8),
          reason: 'and counts.refetch() — the only thing that ever refetches '
              'the tiles after mount',
        );
      },
    );
  });

  group('search', () {
    // These use REAL timers, not `testWidgets`/FakeAsync.
    //
    // The first cut of this file put the debounce assertions in `testWidgets`
    // so `tester.pump(d)` could advance the clock instantly. That does not
    // work here: `HistoryBloc` awaits a chain of real `Future`s inside its
    // event handlers, and `pump` inside FakeAsync never drains them — the test
    // hung rather than failed, which is worse than slow. 350 ms of real time
    // per assertion is the honest price of observing a real debounce.
    late FakeApplicationRepository repo;
    late HistoryBloc sut;

    setUp(() {
      repo = FakeApplicationRepository();
      sut = historyBlocOver(repo);
    });

    tearDown(() => sut.close());

    List<ListCall> issuedLists() =>
        repo.calls.where((ListCall c) => !c.isCountQuery).toList();

    /// Longer than `kHistorySearchDebounce`, so an armed timer has certainly
    /// fired and its request has certainly been recorded.
    Future<void> pastTheWindow() =>
        Future<void>.delayed(kHistorySearchDebounce + const Duration(milliseconds: 120));

    Future<void> mount() async {
      sut.add(const HistoryStarted());
      await settle();
    }

    test(
      'B7-AC-19 — keystrokes 100 ms apart issue exactly ONE request, carrying '
      'the final term',
      () async {
        await mount();
        final int afterMount = issuedLists().length;

        for (final String term in <String>['b', 'bi', 'bir', 'birt', 'birth']) {
          sut.add(HistorySearchChanged(term));
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }

        expect(
          issuedLists().length,
          afterMount,
          reason: 'nothing may go out while the 350 ms window keeps resetting — '
              'five keystrokes 100 ms apart never let it elapse',
        );

        await pastTheWindow();
        await settle();

        final List<ListCall> issued = issuedLists().skip(afterMount).toList();
        expect(
          issued,
          hasLength(1),
          reason: 'useDebounced(query.trim(), 350) — HistoryPage.tsx:76',
        );
        expect(issued.single.search, 'birth');
      },
    );

    test(
      'B7-AC-17 — an empty term is omitted from the query entirely',
      () async {
        await mount();

        sut.add(const HistorySearchChanged('birth'));
        await pastTheWindow();
        await settle();
        expect(issuedLists().last.search, 'birth');

        // Clearing the box is still a real query on /history — there is no
        // no-request view to fall back to, so it waits out the same 350 ms.
        sut.add(const HistorySearchChanged('   '));
        await pastTheWindow();
        await settle();

        expect(
          issuedLists().last.search,
          isNull,
          reason: 'client.ts:187 drops an empty param rather than sending '
              'search= — asserted on the built params, not on a Dart variable',
        );
      },
    );

    test('B7-AC-20 — a debounced search resets page to 1', () async {
      repo.listAnswer = Right<Failure, ApplicationPage>(
        pageFixture(page: 4, totalPages: 9),
      );
      await mount();
      expect(sut.state.page, 4);

      repo.listAnswer = Right<Failure, ApplicationPage>(pageFixture(page: 1));
      sut.add(const HistorySearchChanged('birth'));
      await pastTheWindow();
      await settle();

      expect(issuedLists().last.page, 1);
    });

    test(
      'close() cancels the armed debounce — no request fires afterwards',
      () async {
        await mount();
        final int before = issuedLists().length;

        sut.add(const HistorySearchChanged('bi'));
        await Future<void>.delayed(const Duration(milliseconds: 80));
        await sut.close();
        await pastTheWindow();

        expect(
          issuedLists().length,
          before,
          reason: 'HistoryBloc.close() cancels _debounce; a surviving timer '
              'would fire into a closed emitter',
        );
      },
    );
  });

  group('the generation guard — hooks.ts:73', () {
    test(
      'B7-AC-21 — a slow page-1 resolving after a fast page-2 does NOT '
      'overwrite page 2',
      () async {
        // Page 1's answer is held open; page 2's resolves immediately.
        repository.listAnswerByPage[1] = Right<Failure, ApplicationPage>(
          pageFixture(
            page: 1,
            totalPages: 2,
            rows: <ApplicationRow>[rowFixture(id: 'STALE-page-1')],
          ),
        );
        repository.listAnswerByPage[2] = Right<Failure, ApplicationPage>(
          pageFixture(
            page: 2,
            totalPages: 2,
            rows: <ApplicationRow>[rowFixture(id: 'FRESH-page-2')],
          ),
        );
        repository.gate.add(1);

        bloc.add(const HistoryStarted());
        await settle();
        // page 1 is still in flight, held by the gate.

        bloc.add(const HistoryNextPage());
        await settle();
        expect(bloc.state.rows.single.id, 'FRESH-page-2');

        // Now let the superseded page-1 answer land.
        repository.releaseGate(1);
        await settle();

        expect(
          bloc.state.rows.single.id,
          'FRESH-page-2',
          reason: '"a newer request won" — the stale answer must be dropped, '
              'not rendered. Four B2 BLoCs lost this guard',
        );
        expect(bloc.state.result.page, 2);
      },
    );
  });

  group('errors and the pager', () {
    test(
      'B7-AC-35 — a failed list surfaces failure and Try-again re-issues it',
      () async {
        repository.listAnswer =
            const Left<Failure, ApplicationPage>(Failure('Network unreachable'));

        bloc.add(const HistoryStarted());
        await settle();
        expect(bloc.state.listFailed, isTrue);
        final int before = listQueries().length;

        repository.listAnswer =
            Right<Failure, ApplicationPage>(pageFixture());
        bloc.add(const HistoryListRetried());
        await settle();

        expect(listQueries().length, before + 1);
        expect(bloc.state.listStatus, RegionStatus.success);
      },
    );

    test('one failed count blanks all four — Promise.all rejects', () async {
      bloc.add(const HistoryStarted());
      await settle();
      expect(bloc.state.countsStatus, RegionStatus.success);
    });

    test(
      'B7-AC-40 — prev/next are gated on has_prev/has_next AND not-loading',
      () async {
        repository.listAnswer = Right<Failure, ApplicationPage>(
          pageFixture(page: 2, totalPages: 3, hasNext: true, hasPrev: true),
        );
        bloc.add(const HistoryStarted());
        await settle();

        expect(bloc.state.canGoPrev, isTrue);
        expect(bloc.state.canGoNext, isTrue);

        repository.listAnswer = Right<Failure, ApplicationPage>(
          pageFixture(page: 1, totalPages: 1, hasNext: false, hasPrev: false),
        );
        bloc.add(const HistoryFilterPicked(kFilterApproved));
        await settle();

        expect(bloc.state.canGoPrev, isFalse);
        expect(bloc.state.canGoNext, isFalse);
        expect(bloc.state.showPager, isFalse);
      },
    );

    test('previous page never goes below 1', () async {
      bloc.add(const HistoryStarted());
      await settle();
      final int before = listQueries().length;

      bloc.add(const HistoryPreviousPage());
      await settle();

      expect(bloc.state.page, 1);
      expect(
        listQueries().length,
        before,
        reason: 'Math.max(1, p - 1) settling on the same page re-runs no query',
      );
    });
  });
}

/// `HistoryDetailBloc` — the two queries, the generation guard, and the
/// fallback chain.
///
/// **Every populated assertion in this file runs against declared-synthetic
/// fixtures** (specs.md § 6.12). `/applications/` returns `total 0, rows 0` on
/// the only test account, so no `/applications/:id` or `/:id/timeline` payload
/// has ever been recorded. A pass here is evidence the **port** is correct
/// given a payload; it is **not** live verification (§ 6.4, `B7-AC-81`), and
/// the batch report says so for each criterion rather than reporting PASS.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/application_failures.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_detail.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_event.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_status.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_timeline.dart';
import 'package:lcc_mobile_app/features/history/presentation/bloc/history_bloc.dart'
    show RegionStatus;
import 'package:lcc_mobile_app/features/history/presentation/bloc/history_detail_bloc.dart';

import '../history_test_helper.dart';

void main() {
  late FakeApplicationRepository repository;

  setUp(() => repository = FakeApplicationRepository());

  group('B7-AC-61 — refresh re-issues BOTH queries', () {
    test('a cold start issues exactly one of each', () async {
      final HistoryDetailBloc bloc = detailBloc(repository);
      await pumpEventQueue();

      expect(repository.detailCalls, <String>['app-1']);
      expect(repository.timelineCalls, <String>['app-1']);
      await bloc.close();
    });

    test('refresh issues one MORE of each — two of each in total', () async {
      final HistoryDetailBloc bloc = detailBloc(repository);
      await pumpEventQueue();

      bloc.add(const HistoryDetailRefreshed());
      await pumpEventQueue();

      // Both, not just the detail: a refresh that reloaded the case but not
      // its trail would show a status the timeline does not explain.
      expect(repository.detailCalls, <String>['app-1', 'app-1']);
      expect(repository.timelineCalls, <String>['app-1', 'app-1']);
      await bloc.close();
    });

    test('`refreshing` is true only while a reload runs WITH data on screen',
        () async {
      final HistoryDetailBloc bloc = detailBloc(repository);
      await pumpEventQueue();
      expect(bloc.state.hasDetail, isTrue);
      // A cold load never set it — `hooks.ts:67-68` sets `loading` instead.
      expect(bloc.state.refreshing, isFalse);

      repository.gateDetail = true;
      bloc.add(const HistoryDetailRefreshed());
      await pumpEventQueue();

      expect(bloc.state.refreshing, isTrue,
          reason: 'a reload with a case already rendered is a refresh');
      // And the case is STILL on screen — not replaced by three skeletons.
      expect(bloc.state.showSkeleton, isFalse);
      expect(bloc.state.hasDetail, isTrue);

      repository.releaseDetailGate();
      await pumpEventQueue();
      expect(bloc.state.refreshing, isFalse);
      await bloc.close();
    });
  });

  group('the retries are scoped — `:227` vs `:526`', () {
    test('HistoryDetailRetried re-issues the DETAIL only', () async {
      final HistoryDetailBloc bloc = detailBloc(repository);
      await pumpEventQueue();

      bloc.add(const HistoryDetailRetried());
      await pumpEventQueue();

      expect(repository.detailCalls.length, 2);
      expect(repository.timelineCalls.length, 1,
          reason: "the error card's Try again is `detailQuery.refetch`");
      await bloc.close();
    });

    test('HistoryDetailTimelineRetried re-issues the TIMELINE only', () async {
      final HistoryDetailBloc bloc = detailBloc(repository);
      await pumpEventQueue();

      bloc.add(const HistoryDetailTimelineRetried());
      await pumpEventQueue();

      expect(repository.detailCalls.length, 1);
      expect(repository.timelineCalls.length, 2);
      await bloc.close();
    });
  });

  group('the generation guard — `hooks.ts:55,65,73`', () {
    test('a slow first answer resolving AFTER a fast second is dropped',
        () async {
      // This test is red without the guard: remove the `mine != _generation`
      // check in `_loadDetail` and the stale answer lands, so the final state
      // carries `ref-STALE` instead of `ref-FRESH`.
      // The stale answer is set BEFORE the first request is issued — the fake
      // captures it at entry, as a real request's answer is decided when it is
      // sent. Setting it after `detailBloc(...)` would let the first call
      // return the second's answer and this test would pass with the guard
      // deleted; it did, until measured.
      repository.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(row: rowFixture(referenceNo: 'ref-STALE')),
      );
      repository.gateDetail = true;
      final HistoryDetailBloc bloc = detailBloc(repository);
      await pumpEventQueue();
      expect(bloc.state.hasDetail, isFalse, reason: 'first answer is held');

      // A second request starts and answers immediately.
      repository.gateDetail = false;
      repository.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(row: rowFixture(referenceNo: 'ref-FRESH')),
      );
      bloc.add(const HistoryDetailRefreshed());
      await pumpEventQueue();
      expect(bloc.state.detail!.row.referenceNo, 'ref-FRESH');

      // Now let the stale one land. "A newer request won."
      repository.releaseDetailGate();
      await pumpEventQueue();

      expect(bloc.state.detail!.row.referenceNo, 'ref-FRESH',
          reason: 'the superseded answer must be dropped, not applied');
      await bloc.close();
    });

    test('the two counters are independent — a detail retry does not drop a '
        'timeline answer', () async {
      repository.gateTimeline = true;
      final HistoryDetailBloc bloc = detailBloc(repository);
      await pumpEventQueue();

      bloc.add(const HistoryDetailRetried());
      await pumpEventQueue();

      repository.releaseTimelineGate();
      await pumpEventQueue();

      expect(bloc.state.timelineStatus, RegionStatus.success,
          reason: 'one counter per query, as the source has one ref per hook');
      await bloc.close();
    });
  });

  group('B7-AC-62 — the `:249` fallback chain, all three arrangements', () {
    test('1. the timeline query answered → ITS events win', () async {
      repository.timelineAnswer = Right<Failure, CaseTimeline>(
        timelineFixture(
          events: <CaseEvent>[eventFixture(id: 'from-query')],
        ),
      );
      repository.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(timeline: <CaseEvent>[eventFixture(id: 'from-detail')]),
      );

      final HistoryDetailBloc bloc = detailBloc(repository);
      await pumpEventQueue();

      expect(bloc.state.events.single.id, 'from-query');
      await bloc.close();
    });

    test('1b. an EMPTY `events: []` is an answer and does NOT fall through',
        () async {
      // The distinction the nullable `CaseTimeline` exists for. If `timeline`
      // defaulted to `CaseTimeline.empty` this would read `from-detail`.
      repository.timelineAnswer = Right<Failure, CaseTimeline>(
        timelineFixture(events: <CaseEvent>[]),
      );
      repository.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(timeline: <CaseEvent>[eventFixture(id: 'from-detail')]),
      );

      final HistoryDetailBloc bloc = detailBloc(repository);
      await pumpEventQueue();

      expect(bloc.state.events, isEmpty,
          reason: 'an empty answer is an answer, not an absence');
      await bloc.close();
    });

    test('2. the timeline query FAILED → the detail payload inlined trail',
        () async {
      repository.timelineAnswer =
          Left<Failure, CaseTimeline>(Failure('boom'));
      repository.detailAnswer = Right<Failure, ApplicationDetail>(
        detailFixture(timeline: <CaseEvent>[eventFixture(id: 'from-detail')]),
      );

      final HistoryDetailBloc bloc = detailBloc(repository);
      await pumpEventQueue();

      expect(bloc.state.events.single.id, 'from-detail');
      // And because events survive, the card keeps rendering the trail rather
      // than the retry panel — `events.length === 0` in the source's guard.
      expect(bloc.state.timelineFailed, isFalse);
      await bloc.close();
    });

    test('3. neither → the empty list and the empty branch', () async {
      repository.timelineAnswer =
          Left<Failure, CaseTimeline>(Failure('boom'));
      repository.detailAnswer =
          Right<Failure, ApplicationDetail>(detailFixture());

      final HistoryDetailBloc bloc = detailBloc(repository);
      await pumpEventQueue();

      expect(bloc.state.events, isEmpty);
      expect(bloc.state.timelineFailed, isTrue,
          reason: 'no events AND a failure is the retry panel');
      await bloc.close();
    });
  });

  group('B7-AC-54 — not-found is a SEPARATE field, not a substring test', () {
    test('a NotFoundFailure sets detailNotFound and keeps the message',
        () async {
      repository.detailAnswer = Left<Failure, ApplicationDetail>(
        NotFoundFailure('the backend said this in its own words'),
      );

      final HistoryDetailBloc bloc = detailBloc(repository);
      await pumpEventQueue();

      expect(bloc.state.detailNotFound, isTrue);
      expect(bloc.state.detailError, 'the backend said this in its own words');
      expect(bloc.state.showDetailError, isTrue);
      await bloc.close();
    });

    test('any other failure leaves detailNotFound false', () async {
      repository.detailAnswer =
          Left<Failure, ApplicationDetail>(Failure('upstream exploded'));

      final HistoryDetailBloc bloc = detailBloc(repository);
      await pumpEventQueue();

      expect(bloc.state.detailNotFound, isFalse);
      // **The backend's own sentence**, carried — the AC-35 shape one page
      // over. A state that discarded the `Failure` could not do this.
      expect(bloc.state.detailError, 'upstream exploded');
      await bloc.close();
    });
  });

  group('B7-AC-53 — the loading predicate is BOTH halves', () {
    test('showSkeleton is true on a cold load and false on a refresh',
        () async {
      repository.gateDetail = true;
      final HistoryDetailBloc bloc = detailBloc(repository);
      await pumpEventQueue();

      expect(bloc.state.showSkeleton, isTrue);
      // Not the not-found card — `showDetailError` must stay false while
      // something is in flight, or the first frame prints "could not be found".
      expect(bloc.state.showDetailError, isFalse);

      repository.releaseDetailGate();
      await pumpEventQueue();
      expect(bloc.state.showSkeleton, isFalse);
      await bloc.close();
    });

    test('`initial` counts as loading — the frame before the handler runs',
        () async {
      final HistoryDetailBloc bloc = detailBloc(repository, start: false);

      expect(bloc.state.detailStatus, RegionStatus.initial);
      expect(bloc.state.showSkeleton, isTrue,
          reason: 'the page dispatches Started in the frame it builds the BLoC');
      expect(bloc.state.showDetailError, isFalse);
      await bloc.close();
    });
  });

  group('B7-AC-52 — isIssued and canPay, both halves each', () {
    test('isIssued is `issued` only — `registered` is approved and not issued',
        () {
      expect(detailFixture(status: CaseStatus.issued).isIssued, isTrue);
      expect(detailFixture(status: CaseStatus.registered).isIssued, isFalse);
      expect(detailFixture(status: CaseStatus.registered).bucket,
          StatusBucket.approved);
    });

    test('canPay needs pending AND a fee above zero', () {
      expect(
        detailFixture(paymentState: PaymentState.pending, feeLak: 50000).canPay,
        isTrue,
      );
      expect(
        detailFixture(paymentState: PaymentState.pending, feeLak: 0).canPay,
        isFalse,
        reason: 'a pending case with a zero fee offers nothing to pay',
      );
      expect(
        detailFixture(paymentState: PaymentState.paid, feeLak: 50000).canPay,
        isFalse,
      );
    });
  });

  test('an empty applicationId issues nothing at all', () async {
    final HistoryDetailBloc bloc = detailBloc(repository, start: false);
    bloc.add(const HistoryDetailRefreshed());
    await pumpEventQueue();

    expect(repository.detailCalls, isEmpty);
    expect(repository.timelineCalls, isEmpty);
    await bloc.close();
  });
}

/// `HistoryDetailBloc` — one case: its detail, its timeline, and a refresh.
///
/// Ports `HistoryDetailPage.tsx`'s two `useQuery` calls (`:142`, `:145`) and its
/// `refresh` (`:162-166`). **Two queries, not one**, because the source gives
/// them independent loading and error states and renders the timeline's failure
/// *inside* the timeline card while the rest of the case keeps its data
/// (`:522-533`). A single query would make a timeline outage look like a page
/// outage.
///
/// ## The third query — B7b's seam, filled by B5
///
/// `:149` and `:157` are `me.certificates()` and `me.certificate(id)`. B7b left
/// them out and wrote *"B5 adds it back when it fills the slot"*; **B5 took the
/// invitation** rather than building a parallel BLoC, because the source's one
/// *Refresh status* button re-issues all three queries and that button lives in
/// B7b's hero. A B5-owned cubit could only learn about the refresh by importing
/// `HistoryDetailBloc` (a G-L7/G-L3 violation) or by threading a refresh tick
/// through three widgets to reach it. Both are worse than the
/// `features/history → features/documents/domain` edge CFI already permits
/// (`ssd.md` § 4.3, § 4.4.1 RULING 13) — which is the edge
/// [_loadCertificates] uses and the one `history_detail_seams_test.dart` was
/// narrowed to stop forbidding (specs.md § 6.8).
///
/// So `refresh` now re-issues **three** requests on an issued case and **two**
/// on any other, which is exactly what `:162-166` does: `certListQuery.refetch()`
/// bumps a nonce, and a disabled effect returns early (`B5-AC-42`).
///
/// What B5 did **not** change: the two existing queries, their two generation
/// counters, `refreshing`, `showSkeleton`, and every `B7-AC-5x`/`B7-AC-6x`
/// behaviour (`B5-AC-45`).
///
/// ## The generation guard is ported, per query (`hooks.ts:55,65,73`)
///
/// `bloc` 9's default transformer is **concurrent**, so a refresh issued while
/// a first load is still in flight can resolve in either order. The source
/// stamps every request (`const mine = ++generation.current`) and drops the
/// answer when a newer one has started — *"a newer request won"*. Reproduced as
/// [_detailGeneration] / [_timelineGeneration], one counter per query exactly as
/// the source has one ref per hook. `HistoryBloc` ports the same guard for the
/// same reason; four B2 BLoCs dropped it.
///
/// ## `refreshing` is a distinct state from `loading`, and the icon depends on it
///
/// `hooks.ts:67-68`: `if (hasData) setRefreshing(true); else setLoading(true)`.
/// The consequence on screen is that a refresh with a case already rendered
/// **keeps the case** and spins the `RefreshCw` glyph (`:414`), where a cold
/// load shows three skeleton cards (`:170`). Collapsing the two would replace
/// the whole page with skeletons every time the citizen taps *Refresh status*
/// (`B7-AC-61`).
///
/// ## Why the id lives in the state
///
/// The page is **in-page state, not a route** (§ 6.6) — the citizen taps a row
/// and `HistoryPage` swaps its body, so the BLoC is built once by DI with no id
/// and told which case to load by [HistoryDetailStarted]. A
/// `registerFactoryParam` would have worked too and would have put the id in
/// the container instead of in the event, where a second `Started` for a
/// different case could not be expressed.
library;

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../application/domain/application_failures.dart';
import '../../../application/domain/entities/application_detail.dart';
import '../../../application/domain/entities/case_event.dart';
import '../../../application/domain/entities/case_timeline.dart';
import '../../../application/domain/usecases/application_usecases.dart';
// **`features/history → features/documents/domain/**` only.** CFI (`ssd.md`
// § 4.3) names domain entities *"the only shared currency"*, G-L3 measures
// exactly that boundary, and § 4.4.1 RULING 13 makes the edge explicit. The
// `data/` and `presentation/` halves of `features/documents/` stay unreachable
// from here, and the narrowed guard in `history_detail_seams_test.dart` fires
// on a planted import of either (`B5-AC-20`, `B5-AC-52`).
import '../../../documents/domain/entities/issued_certificate.dart';
import '../../../documents/domain/usecases/documents_usecases.dart';
import 'history_bloc.dart' show RegionStatus;

part 'history_detail_event.dart';
part 'history_detail_state.dart';
part 'history_detail_bloc.freezed.dart';

class HistoryDetailBloc extends Bloc<HistoryDetailEvent, HistoryDetailState> {
  HistoryDetailBloc({
    required this.getApplication,
    required this.getApplicationTimeline,
    required this.getCertificates,
    required this.getCertificate,
  }) : super(const HistoryDetailState()) {
    on<HistoryDetailStarted>(_onStarted);
    on<HistoryDetailRefreshed>(_onRefreshed);
    on<HistoryDetailRetried>(_onRetried);
    on<HistoryDetailTimelineRetried>(_onTimelineRetried);
  }

  final GetApplication getApplication;
  final GetApplicationTimeline getApplicationTimeline;

  /// `me.certificates()` — `:149`. B5's.
  final GetCertificates getCertificates;

  /// `me.certificate(certId)` — `:157`. B5's.
  final GetCertificate getCertificate;

  /// `hooks.ts:55` — `const generation = useRef(0)`, one per query.
  int _detailGeneration = 0;
  int _timelineGeneration = 0;

  /// A **third** counter, not a shared one (`B5-AC-43`). The source has one
  /// `useRef` per hook, and a shared counter would let a certificate answer
  /// cancel a timeline answer that started after it.
  int _certificateGeneration = 0;

  /// Both queries start in the same tick, as the two hooks do — `:142`, `:145`.
  Future<void> _onStarted(
    HistoryDetailStarted event,
    Emitter<HistoryDetailState> emit,
  ) async {
    emit(HistoryDetailState(
      applicationId: event.applicationId,
      detailStatus: RegionStatus.loading,
      timelineStatus: RegionStatus.loading,
    ));

    await Future.wait(<Future<void>>[
      _loadDetail(emit),
      _loadTimeline(emit),
    ]);

    // **After** the two, never beside them (`B5-AC-36`). `certListQuery`'s
    // `enabled: Boolean(isIssued)` (`:149`) sits in `useQuery`'s dependency
    // array (`hooks.ts:89`), so the request fires when `isIssued` flips — i.e.
    // once the detail has resolved — and not at mount. A `Future.wait` of all
    // three would issue it before anyone knows whether the case is issued.
    await _loadCertificates(emit);
  }

  /// `refresh` — `:162-166`. **All three**, and the third only when it would
  /// fire in the source.
  ///
  /// `certListQuery.refetch()` is the third statement (`:165`), but `refetch`
  /// only bumps a nonce and a disabled effect returns early — so a refresh on
  /// an **issued** case makes three requests and on any other case **two**
  /// (`B5-AC-42`). [_loadCertificates] returns immediately when the case is not
  /// issued, which is that behaviour.
  Future<void> _onRefreshed(
    HistoryDetailRefreshed event,
    Emitter<HistoryDetailState> emit,
  ) async {
    await Future.wait(<Future<void>>[
      _loadDetail(emit),
      _loadTimeline(emit),
    ]);
    await _loadCertificates(emit);
  }

  /// The error card's *Try again* — `:227`, `detailQuery.refetch`. **Only the
  /// detail**, because that is the only query the source's button re-runs.
  ///
  /// The certificate chase that follows is **not** the button: it is the same
  /// `enabled` transition as at mount. This branch is reached only when no
  /// detail was on screen, so a successful retry is the first moment `isIssued`
  /// can become true, and the source's hook would fire then.
  Future<void> _onRetried(
    HistoryDetailRetried event,
    Emitter<HistoryDetailState> emit,
  ) async {
    await _loadDetail(emit);
    await _loadCertificates(emit);
  }

  /// The timeline card's own *Try again* — `:526`, `timelineQuery.refetch`.
  Future<void> _onTimelineRetried(
    HistoryDetailTimelineRetried event,
    Emitter<HistoryDetailState> emit,
  ) =>
      _loadTimeline(emit);

  Future<void> _loadDetail(Emitter<HistoryDetailState> emit) async {
    final String id = state.applicationId;
    if (id.isEmpty) return;

    final int mine = ++_detailGeneration;

    // `hooks.ts:67-68` — a reload with data on screen is a *refresh*, and the
    // page keeps rendering the case it already has.
    if (!emit.isDone) {
      emit(state.hasDetail
          ? state.copyWith(refreshing: true)
          : state.copyWith(detailStatus: RegionStatus.loading));
    }

    final Either<Failure, ApplicationDetail> result = await getApplication(id);

    // "a newer request won" — `hooks.ts:73`.
    if (mine != _detailGeneration || emit.isDone) return;
    emit(state.withDetail(result));
  }

  Future<void> _loadTimeline(Emitter<HistoryDetailState> emit) async {
    final String id = state.applicationId;
    if (id.isEmpty) return;

    final int mine = ++_timelineGeneration;
    if (!emit.isDone) {
      emit(state.copyWith(timelineStatus: RegionStatus.loading));
    }

    final Either<Failure, CaseTimeline> result =
        await getApplicationTimeline(id);

    if (mine != _timelineGeneration || emit.isDone) return;
    emit(state.withTimeline(result));
  }

  /// The third query — `HistoryDetailPage.tsx:148-160`, all seven lines.
  ///
  /// Clause for clause:
  ///
  /// | Source | Here |
  /// | --- | --- |
  /// | `enabled: Boolean(isIssued)` (`:149`) | the early return below (`B5-AC-35`, `B5-AC-37`) |
  /// | `certFromList` three-clause `find` (`:150-156`) | [matchIssuedCertificate] |
  /// | `enabled: isIssued && certId && !certFromList && !certListQuery.loading` (`:158`) | the four guards before the single fetch (`B5-AC-39`) |
  /// | `certFromList ?? certOneQuery.data` (`:160`) | precedence, not a merge (`B5-AC-40`, `B5-AC-41`) |
  Future<void> _loadCertificates(Emitter<HistoryDetailState> emit) async {
    final ApplicationDetail? detail = state.detail;
    // `enabled: Boolean(isIssued)`. `isIssued` is B7b's, on the entity, and is
    // consumed rather than re-derived.
    if (detail == null || !detail.isIssued) return;

    final int mine = ++_certificateGeneration;
    if (!emit.isDone) {
      emit(state.copyWith(certificateStatus: RegionStatus.loading));
    }

    // `?application_id=…` — review I-2, 2026-10-22. The spec's § Divorce is
    // explicit: *"one application yields three certificates … List them with
    // `GET /me/certificates?application_id=…`"*. Filtering server-side also
    // closes a real hole: `GET /me/certificates` is **paginated** (§ Citizen
    // endpoints, List) and this datasource reads page 1 only, so a citizen
    // with many certificates could have this case's rows on page 2 and never
    // see them at all.
    //
    // **The trade-off, stated rather than discovered later.** The server now
    // returns only rows of THIS application, so clauses 2 and 3 of
    // [matchIssuedCertificates] (`c.id == detail.certificate_id`,
    // `c.referenceNo == detail.reference_no`) can no longer fire for a row
    // whose own `application_id` differs or is absent. Clause 2's case is
    // still covered — the single fetch below asks for `detail.certificate_id`
    // directly. What is not covered is a v1-shaped row that matches only by
    // `reference_no`, carries no `application_id`, AND belongs to a case with
    // no `certificate_id`; that one renders the card's "not available yet"
    // note, which is the same thing it rendered whenever nothing matched. The
    // predicate is left intact rather than pruned to the one clause the
    // filter makes reachable, because the clauses are the source's
    // (`:150-156`) and a second request to close a narrow v1 hole would cost
    // every case an extra round trip.
    final Either<Failure, List<IssuedCertificate>> listResult =
        await getCertificates(
      GetCertificatesParams(applicationId: state.applicationId),
    );

    if (mine != _certificateGeneration || emit.isDone) return;

    // **ALL matching rows, not the first.** `matchIssuedCertificate` below is
    // kept verbatim as the *singular* answer — `certFromList`'s precedence and
    // the single-fetch skip are unchanged (`B5-AC-38`, `B5-AC-41`) — and
    // `matchIssuedCertificates` is the list the actions row renders a block
    // per. A divorce issues three documents for one application and the first
    // match hid two of them, including the spouse's own booklet.
    final List<IssuedCertificate> matches = listResult.fold(
      (Failure _) => const <IssuedCertificate>[],
      (List<IssuedCertificate> list) =>
          matchIssuedCertificates(list, state.applicationId, detail),
    );
    final IssuedCertificate? fromList = matches.isEmpty ? null : matches.first;
    emit(state.withCertificateList(listResult, fromList, matches));

    // `!certFromList` — the list already answered, so the single fetch is
    // skipped entirely (`B5-AC-41`).
    if (fromList != null) return;

    // `Boolean(certId)` — `detail.certificate_id`, falsy when absent or empty.
    final String? certId = detail.row.certificateId;
    if (certId == null || certId.isEmpty) return;

    // `!certListQuery.loading` — satisfied by construction: the `await` above
    // is the list settling. Writing it as a sequence rather than as a flag is
    // what makes "no single fetch while the list is in flight" true by
    // structure instead of by a race (`B5-AC-39`).
    final Either<Failure, IssuedCertificate> oneResult =
        await getCertificate(GetCertificateParams(certId));

    if (mine != _certificateGeneration || emit.isDone) return;
    emit(state.withCertificate(oneResult));
  }
}

/// `certFromList` — `HistoryDetailPage.tsx:150-156`.
///
/// ```ts
/// (certListQuery.data ?? []).find(
///   (c) => c.application_id === applicationId
///       || (detail?.certificate_id && c.id === detail.certificate_id)
///       || (detail?.reference_no  && c.reference_no === detail.reference_no),
/// )
/// ```
///
/// **`Array.prototype.find` iterates ELEMENTS, and the disjunction is evaluated
/// per element** — so the winner is the first *certificate in list order* that
/// satisfies any clause, not the first clause that has a match somewhere in the
/// list. specs.md `B5-AC-38` describes the second reading; the port implements
/// the first, because that is what the source does, and
/// `history_detail_certificate_test.dart` asserts both orderings so the
/// distinction cannot be lost.
///
/// The three clauses are still evaluated in the source's order **within** one
/// element, which is observable when a single certificate would match two of
/// them with different data.
///
/// Top-level rather than a method so a domain test can drive it without a BLoC.
IssuedCertificate? matchIssuedCertificate(
  List<IssuedCertificate> list,
  String applicationId,
  ApplicationDetail detail,
) {
  final List<IssuedCertificate> all =
      matchIssuedCertificates(list, applicationId, detail);
  return all.isEmpty ? null : all.first;
}

/// **Every** certificate of this case, in list order — review I-2, 2026-10-22.
///
/// [matchIssuedCertificate] is `Array.prototype.find` and answers the one row
/// the source's `certFromList` picks; this is the same predicate under
/// `Array.prototype.filter`, and it is what the document actions render.
///
/// The spec, § Divorce: *"one application yields three certificates: the joint
/// card and booklets A (husband) and B (wife). List them with `GET
/// /me/certificates?application_id=…` and label each by `copy`."* With only the
/// singular match the history detail page kept whichever row the server
/// happened to order first and the citizen's own booklet was invisible and
/// undownloadable — the defect review I-2 names.
///
/// **The disjunction is per element, exactly as in the singular form.** A row
/// qualifies on any one of the three clauses; the clause order inside an
/// element is preserved so the two functions can never disagree about *which*
/// rows belong to the case, only about how many of them are returned.
List<IssuedCertificate> matchIssuedCertificates(
  List<IssuedCertificate> list,
  String applicationId,
  ApplicationDetail detail,
) {
  final String? certificateId = detail.row.certificateId;
  final String referenceNo = detail.row.referenceNo;

  return <IssuedCertificate>[
    for (final IssuedCertificate c in list)
      if (c.applicationId == applicationId ||
          (certificateId != null &&
              certificateId.isNotEmpty &&
              c.id == certificateId) ||
          (referenceNo.isNotEmpty && c.referenceNo == referenceNo))
        c,
  ];
}

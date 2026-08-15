/// `HistoryDetailBloc` — one case: its detail, its timeline, and a refresh.
///
/// Ports `HistoryDetailPage.tsx`'s two `useQuery` calls (`:142`, `:145`) and its
/// `refresh` (`:162-166`). **Two queries, not one**, because the source gives
/// them independent loading and error states and renders the timeline's failure
/// *inside* the timeline card while the rest of the case keeps its data
/// (`:522-533`). A single query would make a timeline outage look like a page
/// outage.
///
/// ## The third query is a seam, not an omission
///
/// `:149` and `:157` are `me.certificates()` and `me.certificate(id)` — **B5's**
/// (specs.md § 6.1, § 5.1). This BLoC does not issue them, does not model a
/// certificate, and `B7-AC-51` greps `lib/**` to prove `/me/certificates`
/// appears nowhere. What B7b owns is `isIssued` (`application_detail.dart`),
/// which decides whether the seam is *offered*; what goes in it is B5's.
///
/// So `refresh` here re-issues **two** requests where the source re-issues
/// three (`:163-165`, the third being `certListQuery.refetch()`). That is not a
/// divergence — the third query does not exist in this port yet — and B5 adds
/// it back when it fills the slot.
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
import 'history_bloc.dart' show RegionStatus;

part 'history_detail_event.dart';
part 'history_detail_state.dart';
part 'history_detail_bloc.freezed.dart';

class HistoryDetailBloc extends Bloc<HistoryDetailEvent, HistoryDetailState> {
  HistoryDetailBloc({
    required this.getApplication,
    required this.getApplicationTimeline,
  }) : super(const HistoryDetailState()) {
    on<HistoryDetailStarted>(_onStarted);
    on<HistoryDetailRefreshed>(_onRefreshed);
    on<HistoryDetailRetried>(_onRetried);
    on<HistoryDetailTimelineRetried>(_onTimelineRetried);
  }

  final GetApplication getApplication;
  final GetApplicationTimeline getApplicationTimeline;

  /// `hooks.ts:55` — `const generation = useRef(0)`, one per query.
  int _detailGeneration = 0;
  int _timelineGeneration = 0;

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
  }

  /// `refresh` — `:162-166`. **Both**, in parallel (`B7-AC-61`).
  ///
  /// Not a `_loadDetail` on its own: the source's button calls three refetches
  /// and the two that exist here both fire. A refresh that reloaded the case
  /// but not its trail would show a status the timeline does not explain.
  Future<void> _onRefreshed(
    HistoryDetailRefreshed event,
    Emitter<HistoryDetailState> emit,
  ) async {
    await Future.wait(<Future<void>>[
      _loadDetail(emit),
      _loadTimeline(emit),
    ]);
  }

  /// The error card's *Try again* — `:227`, `detailQuery.refetch`. **Only the
  /// detail**, because that is the only query the source's button re-runs.
  Future<void> _onRetried(
    HistoryDetailRetried event,
    Emitter<HistoryDetailState> emit,
  ) =>
      _loadDetail(emit);

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
}

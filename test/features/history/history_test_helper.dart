/// Shared fakes and row builders for B7a's `/history` tests.
///
/// ## Why a hand-written fake and not a mock
///
/// Most of B7a's behavioural criteria are **invocation-count** claims —
/// "exactly one request is issued" (`B7-AC-19`), "a cold load issues exactly 5"
/// (`B7-AC-38`), "the tiles do not refetch when the filter changes"
/// (`B7-AC-37`). None of those is visible in a widget tree or in a state
/// object; they are statements about how many times the use case ran and with
/// what. [FakeApplicationRepository] therefore records **every** call in
/// [calls], in order, so a test can assert the shape of the traffic rather than
/// the shape of the answer.
///
/// The deferral hooks ([gate], [releaseGate]) exist for `B7-AC-21` only: the
/// generation guard cannot be observed unless a slow request can be made to
/// resolve *after* a fast one, which needs the fake to hold a completer open.
library;

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_detail.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_page.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_row.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/attachment.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_event.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_status.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_timeline.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/jurisdiction.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/status_pipeline.dart';
import 'package:lcc_mobile_app/features/application/domain/repositories/application_repository.dart';
import 'package:lcc_mobile_app/features/application/domain/usecases/application_usecases.dart';
import 'package:lcc_mobile_app/features/history/presentation/bloc/history_bloc.dart';
import 'package:lcc_mobile_app/features/history/presentation/bloc/history_detail_bloc.dart';
import 'package:lcc_mobile_app/features/history/presentation/pages/history_detail_page.dart';
import 'package:lcc_mobile_app/features/history/presentation/pages/history_page.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';

import '../../helpers/app_test_harness.dart';

/// One recorded `listApplications` invocation.
class ListCall {
  const ListCall({
    required this.page,
    required this.perPage,
    required this.statuses,
    required this.search,
  });

  final int page;
  final int perPage;
  final List<CaseStatus>? statuses;
  final String? search;

  /// The count queries are the ones asking for a single row
  /// (`kApplicationsCountPerPage`); the list query asks for ten.
  bool get isCountQuery => perPage == kApplicationsCountPerPage;

  @override
  String toString() =>
      'ListCall(page: $page, perPage: $perPage, statuses: $statuses, '
      'search: $search)';
}

class FakeApplicationRepository implements ApplicationRepository {
  /// Every `listApplications` call, in the order it was made.
  final List<ListCall> calls = <ListCall>[];

  /// How many times the catalogue was fetched — `usePipeline` runs once.
  int pipelineCalls = 0;

  /// What the next list answer will be. Replaced per-test.
  Either<Failure, ApplicationPage> listAnswer =
      Right<Failure, ApplicationPage>(ApplicationPage.empty);

  /// Per-page overrides, keyed by the requested `page`. Lets `B7-AC-21` give
  /// page 1 and page 2 different bodies without racing on a single field.
  final Map<int, Either<Failure, ApplicationPage>> listAnswerByPage =
      <int, Either<Failure, ApplicationPage>>{};

  /// `meta.total` each count query reports, in `[all, approved, pending,
  /// rejected]` filter order. Keyed by the status set the filter maps to.
  Map<String, int> countTotals = <String, int>{};

  Either<Failure, StatusPipeline> pipelineAnswer =
      Right<Failure, StatusPipeline>(StatusPipeline.seeded);

  /// Delay applied to every answer. Set it when a test needs to observe a
  /// loading state — the skeleton rows and the tiles' `"—"` exist only while a
  /// request is in flight.
  Duration latency = Duration.zero;

  /// Delay applied to `getApplicationTimeline` **only**, overriding [latency].
  /// Zero means "use [latency]".
  Duration timelineLatency = Duration.zero;

  /// Pages whose answer is held open until [releaseGate] is called.
  final Set<int> gate = <int>{};
  final Map<int, Completer<void>> _gates = <int, Completer<void>>{};

  /// Lets the held answer for [page] resolve.
  void releaseGate(int page) {
    _gates[page]?.complete();
  }

  @override
  Future<Either<Failure, ApplicationPage>> listApplications({
    required int page,
    required int perPage,
    List<CaseStatus>? statuses,
    String? search,
  }) async {
    calls.add(ListCall(
      page: page,
      perPage: perPage,
      statuses: statuses,
      search: search,
    ));

    if (latency > Duration.zero) await Future<void>.delayed(latency);

    if (perPage == kApplicationsCountPerPage) {
      final String key = _filterKeyFor(statuses);
      final int total = countTotals[key] ?? 0;
      // The count fixture deliberately carries ONE row and a much larger
      // `meta.total`, so `B7-AC-24` fails if anything reads `data.length`.
      return Right<Failure, ApplicationPage>(ApplicationPage(
        rows: <ApplicationRow>[rowFixture(id: 'count-$key')],
        page: 1,
        totalPages: 1,
        total: total,
        hasNext: false,
        hasPrev: false,
      ));
    }

    if (gate.contains(page)) {
      final Completer<void> c =
          _gates.putIfAbsent(page, () => Completer<void>());
      await c.future;
    }

    return listAnswerByPage[page] ?? listAnswer;
  }

  // ── The detail half — B7b ──────────────────────────────────────────────────
  //
  // Same instrument, same reason: most of B7b's criteria are claims about the
  // *traffic* (`B7-AC-61`: refresh re-issues **both**; `B7-AC-76`: returning
  // from the detail re-issues **both** the list and the counts), and traffic is
  // not visible in a widget tree.

  /// Every `getApplication` call, in order — the ids, so a test can assert
  /// *which* case was asked for and not merely how many times.
  final List<String> detailCalls = <String>[];

  /// Every `getApplicationTimeline` call, in order.
  final List<String> timelineCalls = <String>[];

  Either<Failure, ApplicationDetail> detailAnswer =
      Right<Failure, ApplicationDetail>(detailFixture());

  Either<Failure, CaseTimeline> timelineAnswer =
      Right<Failure, CaseTimeline>(timelineFixture());

  /// Held open until [releaseDetailGate]. `B7-AC-53` needs the loading state to
  /// stay on screen, and the generation-guard case needs a slow first answer to
  /// resolve after a fast second one.
  bool gateDetail = false;
  Completer<void>? _detailGate;

  void releaseDetailGate() {
    _detailGate?.complete();
    _detailGate = null;
  }

  bool gateTimeline = false;
  Completer<void>? _timelineGate;

  void releaseTimelineGate() {
    _timelineGate?.complete();
    _timelineGate = null;
  }

  @override
  Future<Either<Failure, ApplicationDetail>> getApplication(String id) async {
    detailCalls.add(id);
    // **Captured at entry, before the gate.** A real request's answer is
    // decided when it is issued, not when it resolves; reading the field after
    // the await made a held call return whatever the *next* test line assigned,
    // so both calls answered identically and the generation-guard test passed
    // with the guard deleted. Measured — it did. Capability Rule: a test that
    // would pass with its subject inert is evidence for nothing.
    final Either<Failure, ApplicationDetail> answer = detailAnswer;
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (gateDetail) {
      final Completer<void> c = _detailGate ??= Completer<void>();
      await c.future;
    }
    return answer;
  }

  @override
  Future<Either<Failure, CaseTimeline>> getApplicationTimeline(
    String id,
  ) async {
    timelineCalls.add(id);
    final Either<Failure, CaseTimeline> answer = timelineAnswer;
    // [timelineLatency] overrides [latency] for this query alone, so a test can
    // let the detail land while the trail is still in flight — the only
    // arrangement in which the timeline card's loading branch is reachable at
    // all (`:510`, and `HistoryDetailState.timelineLoading`).
    final Duration delay =
        timelineLatency > Duration.zero ? timelineLatency : latency;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (gateTimeline) {
      final Completer<void> c = _timelineGate ??= Completer<void>();
      await c.future;
    }
    return answer;
  }

  @override
  Future<Either<Failure, StatusPipeline>> getStatusPipeline() async {
    pipelineCalls++;
    return pipelineAnswer;
  }

  // ── F1's write half — stubs, and deliberately unusable ────────────────────
  //
  // NOT B7's. F1 added `createApplication`, `updateApplication`,
  // `addAttachment` and `submitApplication` to `ApplicationRepository` while
  // B7b was in flight, which made this fake abstract and took B7's whole test
  // tree out of compilation
  // (`non_abstract_class_inherits_abstract_member`, measured). These four
  // satisfy the interface so B7's suite builds again.
  //
  // They throw rather than answering. B7 performs **no write** — § 8.5 records
  // that as the reason B7 was not flagged for a security review — so a B7 test
  // that reached one of these would be exercising a path the batch does not
  // have, and a silent `Right(...)` would let it do so unnoticed. If F1 needs
  // these to answer, F1 owns that change; B7 will not pre-empt it with a
  // guessed return value.
  @override
  Future<Either<Failure, ApplicationDetail>> createApplication(
    Map<String, Object?> envelope,
  ) =>
      throw UnimplementedError('B7 performs no write — see history_test_helper');

  @override
  Future<Either<Failure, ApplicationDetail>> updateApplication(
    String id,
    Map<String, Object?> envelope,
  ) =>
      throw UnimplementedError('B7 performs no write — see history_test_helper');

  @override
  Future<Either<Failure, Unit>> addAttachment(
    String id, {
    required PickedAttachment file,
    required String slot,
    required String kind,
    String? label,
  }) =>
      throw UnimplementedError('B7 performs no write — see history_test_helper');

  @override
  Future<Either<Failure, ApplicationDetail>> submitApplication(String id) =>
      throw UnimplementedError('B7 performs no write — see history_test_helper');

  /// Which of the four chips a status set came from — the inverse of
  /// `kFilterStatuses`, so a test can name a count by its chip.
  static String _filterKeyFor(List<CaseStatus>? statuses) {
    if (statuses == null) return kFilterAll;
    for (final MapEntry<String, List<CaseStatus>?> e
        in kFilterStatuses.entries) {
      final List<CaseStatus>? v = e.value;
      if (v != null &&
          v.length == statuses.length &&
          v.every(statuses.contains)) {
        return e.key;
      }
    }
    return 'unmapped';
  }
}

/// A `HistoryBloc` over [repository], wired exactly as `HistoryUsecaseInjection`
/// wires the real one.
HistoryBloc historyBlocOver(FakeApplicationRepository repository) => HistoryBloc(
      listApplications: ListApplications(repository: repository),
      getStatusPipeline: GetStatusPipeline(repository: repository),
    );

/// A complete [ApplicationRow]. Every field has a value so a widget test can
/// render the row without a null blowing up somewhere unrelated to its claim;
/// each test overrides only the fields its criterion is about.
ApplicationRow rowFixture({
  String id = 'app-1',
  String referenceNo = 'LCC-2026-000123',
  String serviceEn = 'Birth Certificate',
  String serviceLo = 'ໃບຢັ້ງຢືນການເກີດ',
  CaseStatus status = CaseStatus.submitted,
  String statusEn = 'Submitted',
  String statusLo = 'ຍື່ນແລ້ວ',
  PaymentState paymentState = PaymentState.pending,
  int feeLak = 50000,
  int slaDays = 7,
  int daysWaiting = 3,
  int daysOverdue = 0,
  bool isOverdue = false,
  String? submittedAt = '2026-03-14T09:30:00Z',
  String createdAt = '2026-03-10T08:00:00Z',
  String? assignedOfficer,
}) =>
    ApplicationRow(
      id: id,
      referenceNo: referenceNo,
      serviceCode: 'birth-cert',
      serviceName: Bilingual(en: serviceEn, lo: serviceLo),
      applicant: 'Somchai',
      subjectName: 'Somchai Jr',
      status: status,
      statusLabel: Bilingual(en: statusEn, lo: statusLo),
      paymentState: paymentState,
      feeLak: feeLak,
      channel: 'online',
      jurisdiction: const Jurisdiction(
        provinceId: 'VTE',
        provinceName: 'Vientiane',
        districtId: 'CHA',
        districtName: 'Chanthabouly',
      ),
      assignedOfficer: assignedOfficer,
      slaDays: slaDays,
      daysWaiting: daysWaiting,
      daysOverdue: daysOverdue,
      isOverdue: isOverdue,
      submittedAt: submittedAt,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Standing `HistoryPage` up

/// Pumps [HistoryPage] under [bloc], in [locale].
///
/// **Does not settle.** Three of B7a's rendering criteria are about states the
/// page holds only while a request is in flight — the 3 skeleton rows
/// (`B7-AC-34`) and the `"—"` on the tiles (`B7-AC-36`) — so a caller has to be
/// able to stop the clock before the future resolves. `pumpAndSettle` here
/// would make those two criteria untestable.
///
/// The surface is tall on purpose: `HistoryPage` is a `SingleChildScrollView`
/// and a 390x844 phone viewport pushes the pager off-screen, where
/// `findsOneWidget` still matches but `tap` does not.
Future<void> pumpHistoryPage(
  WidgetTester tester,
  HistoryBloc bloc, {
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 4000),
  HistoryDetailBloc Function()? detailBlocFactory,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = surface;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(wrapWithLocalization(
    startLocale: locale,
    Builder(
      builder: (BuildContext context) => MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: BlocProvider<HistoryBloc>.value(
          value: bloc,
          child: HistoryPage(
            // A B7a test that never opens a detail must still supply this. It
            // throws rather than returning a stub so a test that DOES open one
            // without meaning to fails loudly instead of rendering an inert
            // page — the B7b navigation tests pass a real factory.
            detailBlocFactory: detailBlocFactory ??
                () => throw StateError(
                      'This test did not supply a detailBlocFactory. Pass one '
                      'if the case under test opens the detail.',
                    ),
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail builders — B7b
//
// **Everything these build is DECLARED SYNTHETIC** (specs.md § 6.12). No
// `/applications/:id` payload has ever been recorded: the endpoint needs a
// bearer token and an application to exist, and the only test citizen returns
// `total 0, rows 0`. A criterion discharged against one of these is evidence
// that the **port** is correct given a payload — never that the payload is what
// staging sends (§ 6.4, `B7-AC-81`). FU-1 re-derives them when B4 lands.

/// A complete [ApplicationDetail]. Every field populated for the same reason
/// [rowFixture] populates every field: a null blowing up somewhere unrelated to
/// the criterion under test is a wasted debugging hour.
ApplicationDetail detailFixture({
  ApplicationRow? row,
  CaseStatus status = CaseStatus.submitted,
  PaymentState paymentState = PaymentState.pending,
  int feeLak = 50000,
  String? reasonNote,
  String? assignedOfficer,
  String? dueAt,
  bool isOverdue = false,
  List<Attachment> attachments = const <Attachment>[],
  List<CaseEvent>? timeline,
}) =>
    ApplicationDetail(
      row: row ??
          rowFixture(
            status: status,
            paymentState: paymentState,
            feeLak: feeLak,
            assignedOfficer: assignedOfficer,
            isOverdue: isOverdue,
          ).copyWith(reasonNote: reasonNote, dueAt: dueAt),
      attachments: attachments,
      timeline: timeline,
    );

/// One [Attachment]. The 100-byte default is deliberate: it is the input
/// `B7-AC-70`'s `max(1, round(size_bytes / 1024))` clamp turns into **`1 KB`**
/// rather than `0 KB`.
Attachment attachmentFixture({
  String id = 'att-1',
  String slot = 'national_id',
  String label = 'National ID',
  String fileName = 'id-front.jpg',
  int sizeBytes = 100,
  String uploadedAt = '2026-03-12T04:15:00Z',
}) =>
    Attachment(
      id: id,
      kind: 'document',
      slot: slot,
      label: label,
      fileName: fileName,
      fileUrl: 'https://staging.example/files/$id.jpg',
      sizeBytes: sizeBytes,
      uploadedAt: uploadedAt,
    );

/// One [CaseEvent].
CaseEvent eventFixture({
  String id = 'ev-1',
  CaseStatus toStatus = CaseStatus.submitted,
  String? labelEn = 'Submitted',
  String? labelLo = 'ຍື່ນແລ້ວ',
  String? actorName,
  String? note,
  String occurredAt = '2026-03-14T09:30:00Z',
}) =>
    CaseEvent(
      id: id,
      action: 'submit',
      toStatus: toStatus,
      statusLabel: labelEn == null && labelLo == null
          ? null
          : Bilingual(en: labelEn ?? '', lo: labelLo ?? ''),
      actorName: actorName,
      note: note,
      occurredAt: occurredAt,
    );

/// A [CaseTimeline] over [events].
CaseTimeline timelineFixture({List<CaseEvent>? events}) => CaseTimeline(
      applicationId: 'app-1',
      referenceNo: 'LCC-2026-000123',
      status: CaseStatus.submitted,
      events: events ?? <CaseEvent>[eventFixture()],
    );

/// Pumps [HistoryDetailPage] alone, with [bloc] provided and no seams filled.
///
/// **Not** through `HistoryPage`: the criteria in `§ 7.7`/`§ 7.8` are about the
/// detail's own rendering, and reaching it by tapping a row would make every
/// one of them depend on the list rendering correctly first. The navigation
/// criteria (`B7-AC-74`…`B7-AC-76`) go the other way and are pumped through
/// `pumpHistoryPage`, which is the point of keeping the two helpers separate.
///
/// [seams] fills the four § 6.1 slots. B7b passes null for all four, so the
/// default is null and a test that wants to prove a slot *works* opts in.
Future<void> pumpHistoryDetailPage(
  WidgetTester tester,
  HistoryDetailBloc bloc, {
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 4000),
  StatusPipeline? pipeline,
  VoidCallback? onBack,
  Widget? documentActions,
  Widget? paymentAction,
  Widget? paymentPanel,
  Widget? certificatePanel,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = surface;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(wrapWithLocalization(
    startLocale: locale,
    Builder(
      builder: (BuildContext context) => MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: BlocProvider<HistoryDetailBloc>.value(
          value: bloc,
          child: HistoryDetailPage(
            pipeline: pipeline ?? StatusPipeline.seeded,
            onBack: onBack ?? () {},
            documentActions: documentActions,
            paymentAction: paymentAction,
            paymentPanel: paymentPanel,
            certificatePanel: certificatePanel,
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
}

/// A [HistoryDetailBloc] over [repository], already `Started` on [id].
///
/// Returns before the first answer resolves when the repository is gated, so a
/// test can observe the loading state.
HistoryDetailBloc detailBloc(
  FakeApplicationRepository repository, {
  String id = 'app-1',
  bool start = true,
}) {
  final HistoryDetailBloc bloc = HistoryDetailBloc(
    getApplication: GetApplication(repository: repository),
    getApplicationTimeline: GetApplicationTimeline(repository: repository),
  );
  if (start) bloc.add(HistoryDetailStarted(id));
  return bloc;
}

/// An [ApplicationPage] over [rows] with an explicit pagination block.
ApplicationPage pageFixture({
  List<ApplicationRow>? rows,
  int page = 1,
  int totalPages = 1,
  int? total,
  bool? hasNext,
  bool? hasPrev,
}) {
  final List<ApplicationRow> r = rows ?? <ApplicationRow>[rowFixture()];
  return ApplicationPage(
    rows: r,
    page: page,
    totalPages: totalPages,
    total: total ?? r.length,
    hasNext: hasNext ?? page < totalPages,
    hasPrev: hasPrev ?? page > 1,
  );
}

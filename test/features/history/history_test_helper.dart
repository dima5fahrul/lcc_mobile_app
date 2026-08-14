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
import 'package:lcc_mobile_app/features/application/domain/entities/application_page.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_row.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_status.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/jurisdiction.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/status_pipeline.dart';
import 'package:lcc_mobile_app/features/application/domain/repositories/application_repository.dart';
import 'package:lcc_mobile_app/features/application/domain/usecases/application_usecases.dart';
import 'package:lcc_mobile_app/features/history/presentation/bloc/history_bloc.dart';
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

  @override
  Future<Either<Failure, StatusPipeline>> getStatusPipeline() async {
    pipelineCalls++;
    return pipelineAnswer;
  }

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
        home: BlocProvider<HistoryBloc>.value(value: bloc, child: const HistoryPage()),
      ),
    ),
  ));
  await tester.pump();
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

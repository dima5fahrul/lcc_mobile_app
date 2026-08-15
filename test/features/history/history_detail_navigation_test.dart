/// In-page navigation — **B7-AC-74**, **B7-AC-75**, **B7-AC-76**.
///
/// § 6.6 rules the detail in-page state rather than a route, so these three
/// criteria are the ones that prove it: the location does not change, hardware
/// back returns to the list instead of leaving the tab, and coming back
/// refetches both the list and the counts.
///
/// These go **through `HistoryPage`** — the opposite of
/// `history_detail_page_test.dart`, which mounts the detail alone. A navigation
/// criterion asserted on the detail in isolation would be asserting nothing:
/// there would be no list to return to.
library;

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_page.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_row.dart';
import 'package:lcc_mobile_app/features/application/domain/usecases/application_usecases.dart';
import 'package:lcc_mobile_app/features/history/presentation/bloc/history_bloc.dart';
import 'package:lcc_mobile_app/features/history/presentation/bloc/history_detail_bloc.dart';
import 'package:lcc_mobile_app/features/history/presentation/pages/history_detail_page.dart';
import 'package:lcc_mobile_app/features/history/presentation/pages/history_page.dart';
import 'package:lcc_mobile_app/features/history/presentation/widgets/history_row_card.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';

import '../../helpers/app_test_harness.dart';
import 'history_test_helper.dart';

void main() {
  late FakeApplicationRepository repo;
  late HistoryBloc bloc;

  setUp(() => repo = FakeApplicationRepository());

  tearDown(() async {
    await bloc.close();
  });

  /// The factory the route supplies in production (`app_routes.dart`), over the
  /// fake repository.
  ///
  /// A **new BLoC per call**, matching `registerFactory`: reusing one instance
  /// would make `B7-AC-74`'s second open inherit the first case's state, and
  /// the test would pass for the wrong reason.
  HistoryDetailBloc detailFactory() => HistoryDetailBloc(
        getApplication: GetApplication(repository: repo),
        getApplicationTimeline: GetApplicationTimeline(repository: repo),
      );

  /// Mounts `/history` inside a real `GoRouter`, so the location is observable.
  Future<GoRouter> pumpRouted(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 4000);
    addTearDown(tester.view.reset);

    repo.listAnswer = Right<Failure, ApplicationPage>(
      pageFixture(rows: <ApplicationRow>[
        rowFixture(id: 'app-42', referenceNo: 'LCC-2026-000042'),
      ]),
    );

    bloc = historyBlocOver(repo);
    bloc.add(const HistoryStarted());

    final GoRouter router = GoRouter(
      initialLocation: '/history',
      routes: <RouteBase>[
        GoRoute(
          path: '/history',
          builder: (_, __) => BlocProvider<HistoryBloc>.value(
            value: bloc,
            child: HistoryPage(detailBlocFactory: detailFactory),
          ),
        ),
      ],
    );

    await tester.pumpWidget(wrapWithLocalization(
      Builder(
        builder: (BuildContext context) => MaterialApp.router(
          theme: AppTheme.light(),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          routerConfig: router,
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    return router;
  }

  String locationOf(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  Future<void> openDetail(WidgetTester tester) async {
    await tester.tap(find.byType(HistoryRowCard).first);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('B7-AC-74 — opening the detail does NOT change the location',
      (WidgetTester tester) async {
    final GoRouter router = await pumpRouted(tester);
    expect(locationOf(router), '/history');
    expect(find.byType(HistoryDetailPage), findsNothing);

    await openDetail(tester);

    expect(find.byType(HistoryDetailPage), findsOneWidget,
        reason: 'the body swapped');
    expect(find.byType(HistoryRowCard), findsNothing,
        reason: 'the list is replaced, not stacked under it');
    expect(locationOf(router), '/history',
        reason: 'in-page state, not a route (§ 6.6)');
  });

  testWidgets('B7-AC-76 — returning re-issues BOTH the list and the counts',
      (WidgetTester tester) async {
    await pumpRouted(tester);
    await openDetail(tester);

    // A cold load is 1 list + 4 counts (§ 6.8). Measure from here rather than
    // asserting an absolute, so this does not restate `B7-AC-38`.
    final int listBefore = repo.calls.where((ListCall c) => !c.isCountQuery).length;
    final int countsBefore = repo.calls.where((ListCall c) => c.isCountQuery).length;

    await tester.tap(find.text('Back to history'));
    await tester.pump();
    await tester.pump();

    final int listAfter = repo.calls.where((ListCall c) => !c.isCountQuery).length;
    final int countsAfter = repo.calls.where((ListCall c) => c.isCountQuery).length;

    expect(listAfter, listBefore + 1, reason: '`list.refetch()` — `:121`');
    expect(countsAfter, countsBefore + 4,
        reason: '`counts.refetch()` — `:122`, four separate requests (§ 6.8)');
    expect(find.byType(HistoryRowCard), findsWidgets,
        reason: 'and the list is back');
  });

  group('B7-AC-75 — hardware back', () {
    /// Delivers a real Android system back, the way the platform does.
    Future<bool> systemBack(WidgetTester tester) async {
      final ByteData? result = await tester
          .binding.defaultBinaryMessenger
          .handlePlatformMessage(
        'flutter/navigation',
        const JSONMethodCodec()
            .encodeMethodCall(const MethodCall('popRoute')),
        (ByteData? _) {},
      );
      await tester.pump();
      await tester.pump();
      return result != null;
    }

    testWidgets('with a detail open, it returns to the LIST', (tester) async {
      final GoRouter router = await pumpRouted(tester);
      await openDetail(tester);
      expect(find.byType(HistoryDetailPage), findsOneWidget);

      await systemBack(tester);

      expect(find.byType(HistoryDetailPage), findsNothing,
          reason: 'PopScope intercepted and closed the detail');
      expect(find.byType(HistoryRowCard), findsWidgets);
      expect(locationOf(router), '/history',
          reason: 'and it did NOT leave the tab');
    });

    testWidgets('it also refetches, exactly as the back link does',
        (WidgetTester tester) async {
      await pumpRouted(tester);
      await openDetail(tester);

      final int listBefore =
          repo.calls.where((ListCall c) => !c.isCountQuery).length;

      await systemBack(tester);

      expect(
        repo.calls.where((ListCall c) => !c.isCountQuery).length,
        listBefore + 1,
        reason: 'both exits run `_closeDetail`, so neither can drift',
      );
    });

    // `find.byType(PopScope<Object?>)` matches nothing — the generic argument
    // Dart infers for the widget is not what the finder asks for, and
    // `byType` compares the instantiated type exactly. A predicate matches any
    // `PopScope<T>`, and scoping it under `HistoryPage` keeps it off any that
    // GoRouter or Navigator insert of their own.
    bool canPopOf(WidgetTester tester) => tester
        .widget<PopScope<dynamic>>(
          find
              .descendant(
                of: find.byType(HistoryPage),
                matching:
                    find.byWidgetPredicate((Widget w) => w is PopScope),
              )
              .first,
        )
        .canPop;

    testWidgets('with the LIST showing, PopScope does not intercept',
        (WidgetTester tester) async {
      await pumpRouted(tester);
      expect(find.byType(HistoryRowCard), findsWidgets);

      expect(canPopOf(tester), isTrue,
          reason: 'the tab behaves exactly as it did before B7b');
    });

    testWidgets('with a DETAIL open, canPop flips to false',
        (WidgetTester tester) async {
      await pumpRouted(tester);
      await openDetail(tester);

      expect(canPopOf(tester), isFalse);
    });
  });

  testWidgets('the detail is told WHICH case — the row id, not the reference',
      (WidgetTester tester) async {
    await pumpRouted(tester);
    await openDetail(tester);

    expect(repo.detailCalls, <String>['app-42']);
    expect(repo.timelineCalls, <String>['app-42']);
  });
}

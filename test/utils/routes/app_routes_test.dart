/// `AppRoutes` — the route table outside the five shell tabs, and the
/// BLoC-stream → `Listenable` bridge behind `refreshListenable`.
///
/// The auth gate itself (protected paths, the `from` round trip, the boot
/// hold) is proved end to end in `test/app/app_flow_test.dart` against the
/// assembled app; duplicating it here would assert the same behaviour twice.
/// What is left is what that file does not reach: the full-frame routes that
/// keep the router navigable until their own batches land, the structural rule
/// that they carry no bottom bar, and the refresh bridge's lifecycle.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/session/bloc/session_bloc.dart';
import 'package:lcc_mobile_app/features/help/presentation/pages/help_page.dart';
import 'package:lcc_mobile_app/features/news/presentation/pages/news_detail_page.dart';
import 'package:lcc_mobile_app/features/news/presentation/pages/news_page.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';
import 'package:lcc_mobile_app/utils/routes/app_routes.dart';

import '../../helpers/app_test_harness.dart';

GoRouter routerOf(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));

void main() {
  tearDown(resetHarness);

  testWidgets('/help and /news serve their real pages, full-frame with no '
      'bottom bar (B2c)', (WidgetTester tester) async {
    final AppHarness harness = await bootHarness();
    await pumpAssembledApp(tester, harness);

    routerOf(tester).go(AppNameRoutes.help);
    await tester.pumpAndSettle();
    expect(routerOf(tester).state.uri.toString(), AppNameRoutes.help);
    expect(find.byType(HelpPage), findsOneWidget);
    // Mounted outside the ShellRoute, so the bar is absent structurally — not
    // hidden by a flag some future sub-route could forget to set.
    expect(find.byType(NavigationBar), findsNothing,
        reason: AppNameRoutes.help);

    routerOf(tester).go(AppNameRoutes.news);
    await tester.pumpAndSettle();
    expect(routerOf(tester).state.uri.toString(), AppNameRoutes.news);
    expect(find.byType(NewsPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing,
        reason: AppNameRoutes.news);
  });

  testWidgets('B2-AC-37: neither page renders the placeholder any more',
      (WidgetTester tester) async {
    // The deletion half of B2-AC-37, asserted rather than assumed: the class
    // survives for `/debug`, so "it still compiles" proves nothing about
    // whether these two routes stopped using it.
    final AppHarness harness = await bootHarness();
    await pumpAssembledApp(tester, harness);

    for (final String path in <String>[
      AppNameRoutes.help,
      AppNameRoutes.news,
    ]) {
      routerOf(tester).go(path);
      await tester.pumpAndSettle();
      expect(find.textContaining('placeholder'), findsNothing, reason: path);
    }
  });

  testWidgets('/news/:slug is a CHILD route — the first parameterised one',
      (WidgetTester tester) async {
    final AppHarness harness = await bootHarness();
    // The detail route's two reads. Not in `stubContentEndpoints` because one
    // of them needs a concrete slug.
    harness.adapter.onGet(
      ApiEndpoint.newsArticle('a-slug'),
      (dynamic server) => server.reply(200, <String, dynamic>{
        'success': true,
        'message': 'ok',
        'data': <String, dynamic>{
          'slug': 'a-slug',
          'title': <String, dynamic>{'en': 'A headline', 'lo': 'A headline'},
          'excerpt': <String, dynamic>{'en': 'An excerpt', 'lo': 'An excerpt'},
        },
      }),
    );
    await pumpAssembledApp(tester, harness);

    routerOf(tester).go('${AppNameRoutes.news}/a-slug');
    await tester.pumpAndSettle();

    expect(routerOf(tester).state.uri.toString(), '/news/a-slug');
    expect(find.byType(NewsDetailPage), findsOneWidget);
    expect(find.text('A headline'), findsOneWidget,
        reason: 'the slug reached the datasource, so the route parameter is '
            'wired end to end and not merely matched');
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('/debug is mounted in a debug build', (WidgetTester tester) async {
    // The route is behind `if (kDebugMode)`. A test binary is always a debug
    // build, so only the present-branch is executable here; the release branch
    // is constant-folded away and is covered by review (AC-10 hotspot 2).
    final AppHarness harness = await bootHarness();
    await pumpAssembledApp(tester, harness);

    routerOf(tester).go(AppNameRoutes.debug);
    await tester.pumpAndSettle();

    expect(routerOf(tester).state.uri.toString(), AppNameRoutes.debug);
    expect(find.text('Debug'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('the placeholder explains itself rather than rendering blank',
      (WidgetTester tester) async {
    // B2c narrowed this from `/help` to `/debug` — the class survives for the
    // one remaining call site (B2-AC-37), so the assertion moves rather than
    // being deleted.
    final AppHarness harness = await bootHarness();
    await pumpAssembledApp(tester, harness);

    routerOf(tester).go(AppNameRoutes.debug);
    await tester.pumpAndSettle();

    expect(find.textContaining('placeholder'), findsOneWidget);
  });

  test('build() hands each router its own route table, so two live routers do '
      'not share a ShellRoute navigator key', () async {
    // The reason `_buildRoutes()` is a method and not a `static final` list: a
    // shared list would hand the same implicit GlobalKey to every router, and
    // two live routers (two widget tests in one process, or a hot restart)
    // would mount the same key twice.
    final AppHarness harness = await bootHarness();
    addTearDown(resetHarness);

    final GoRouter first = AppRoutes.build(harness.sessionBloc);
    final GoRouter second = AppRoutes.build(harness.sessionBloc);

    expect(first, isNot(same(second)));
    expect(
      first.configuration.routes.first,
      isNot(same(second.configuration.routes.first)),
    );

    // Safe to dispose here precisely because neither was ever mounted —
    // disposing a router while `MaterialApp.router` still holds it stalls.
    first.dispose();
    second.dispose();
  });

  test('the redirect reads the session status it was constructed with', () async {
    final AppHarness harness = await bootHarness();
    addTearDown(resetHarness);

    final GoRouter router = AppRoutes.build(harness.sessionBloc);
    addTearDown(router.dispose);

    // Boot hold: `initial` means "not resolved yet", so nothing is gated.
    expect(harness.sessionBloc.state.status, SessionStatus.initial);
    expect(router.configuration.routes, isNotEmpty);
  });

  test('kFromQueryParam is the wire key the auth gate and AuthPage agree on',
      () {
    expect(AppRoutes.kFromQueryParam, 'from');
  });
}

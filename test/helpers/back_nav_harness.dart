/// The signed-in assembled-app rig GOR-269's back-navigation suites share.
///
/// Kept here rather than copied between the three suites because it is not two
/// one-liners: it is a stub set covering every read the twelve authenticated
/// routes fire, and a copy that drifted would make one suite's rows quietly
/// measure an error state while the other's measured a page.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/session/bloc/session_bloc.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';
import 'package:lcc_mobile_app/utils/routes/app_back_policy.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';
import 'package:lcc_mobile_app/utils/routes/app_routes.dart';

import 'app_test_harness.dart';
import 'core_test_helper.dart';
import 'session_test_helper.dart';

/// The slug the `/news/:slug` rows drive.
const String kBackProbeSlug = 'a-slug';

/// `/news/a-slug` — the article location.
const String kBackProbeArticle = '${AppNameRoutes.news}/$kBackProbeSlug';

/// The five `MAIN_TABS`, in `Layout.tsx:46-52` order.
const List<String> kTabRoutes = <String>[
  AppNameRoutes.home,
  AppNameRoutes.service,
  AppNameRoutes.history,
  AppNameRoutes.wallet,
  AppNameRoutes.account,
];

/// The nine routes B12 mounted **outside** the `ShellRoute`, which is what
/// hides the bottom bar on them (`ssd.md` § 9.1, `app_routes.dart:697-702`,
/// `:795-808`).
const List<String> kFullFrameRoutes = <String>[
  AppNameRoutes.signin,
  AppNameRoutes.help,
  AppNameRoutes.news,
  AppNameRoutes.residentCertificate,
  AppNameRoutes.birthDeclaration,
  AppNameRoutes.deathDeclaration,
  AppNameRoutes.marriageCertificate,
  AppNameRoutes.divorceCertificate,
  AppNameRoutes.familyBook,
];

/// The router the pumped app is running.
///
/// Reached through the tree rather than through `MaterialApp.routerConfig`,
/// which GOR-269's four-field expansion leaves null (`FC-5`), and never by
/// building a second `AppRoutes.build` — two live routers is what
/// `app_routes_test.dart:130-152` exists to prevent.
GoRouter routerOf(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));

String locationOf(WidgetTester tester) => routerOf(tester).state.uri.toString();

/// Navigates exactly as the 36 production call sites do.
Future<void> goTo(WidgetTester tester, String path) async {
  routerOf(tester).go(path);
  await tester.pumpAndSettle();
}

/// `main.dart`'s own composition, stood up directly so a test can hold the
/// [AppBackPolicy] the assembled `App` keeps private.
///
/// `_AppState.initState` builds the router, constructs the policy against it,
/// wraps that in [AppBackButtonDispatcher], and `build` hands
/// `MaterialApp.router` the four-field expansion below `EasyLocalization`
/// (`main.dart:242-251`, `:317-323`). This reproduces exactly that, with
/// nothing in `lib/` stubbed or modified to achieve it — which is what lets a
/// test assert against [AppBackPolicy.journey] without measuring a different
/// app from the one `pumpAssembledApp` pumps.
///
/// [policySession] is the bloc the **policy** observes; the router always
/// watches `harness.sessionBloc`. It defaults to the same instance, which is
/// what `main.dart` wires. Passing a *different* bloc is a deliberate fault
/// injection that severs `I-6` — see `back_policy_authorization_test.dart`,
/// which is the one caller that does so and documents why.
Future<({GoRouter router, AppBackPolicy policy})> pumpMainComposition(
  WidgetTester tester,
  AppHarness harness, {
  SessionBloc? policySession,
}) async {
  final GoRouter router = AppRoutes.build(harness.sessionBloc);
  final AppBackPolicy policy = AppBackPolicy(
    router: router,
    sessionBloc: policySession ?? harness.sessionBloc,
  );
  final AppBackButtonDispatcher dispatcher = AppBackButtonDispatcher(policy);
  addTearDown(policy.dispose);

  // `App.initState` does this; this composition stands in for `App`, so it has
  // to as well or the session would hang in `initial` forever.
  harness.sessionBloc.add(const SessionEvent.started());

  await tester.pumpWidget(
    wrapWithLocalization(
      BlocProvider<SessionBloc>.value(
        value: harness.sessionBloc,
        child: Builder(
          // Below `EasyLocalization`, exactly as `_routedApp(context)` is.
          builder: (BuildContext context) => MaterialApp.router(
            title: 'Lao Citizen Center',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            themeMode: ThemeMode.light,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            routeInformationProvider: router.routeInformationProvider,
            routeInformationParser: router.routeInformationParser,
            routerDelegate: router.routerDelegate,
            backButtonDispatcher: dispatcher,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (router: router, policy: policy);
}

/// The location [pumpMainComposition]'s router has resolved.
///
/// [locationOf] cannot serve here: it reaches the router through the widget
/// tree, and these suites hold the instance directly.
String locationOfRouter(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.toString();

/// `/history`'s reads. Not in `app_test_harness.dart` because no assembled test
/// before GOR-269 ever reached the tab with a citizen behind it, and a stub set
/// invented here should not be mistaken for a measurement of what staging
/// sends — the list is deliberately empty.
void stubHistoryEndpoints(DioAdapter adapter) {
  adapter.onGet(
    ApiEndpoint.applications,
    (dynamic server) => server.reply(200, <String, dynamic>{
      'success': true,
      'message': 'ok',
      'data': const <dynamic>[],
      'meta': const <String, dynamic>{
        'page': 1,
        'per_page': 20,
        'total': 0,
        'total_pages': 1,
        'has_next': false,
        'has_prev': false,
      },
    }),
  );
  adapter.onGet(
    ApiEndpoint.statusCatalogue,
    (dynamic server) => server.reply(200, okEnvelope(const <dynamic>[])),
  );
}

/// Answers `/news/:slug`'s read so the detail renders its article rather than
/// an error state — Stage 2 drove this row against the recorded fidelity
/// article for the same reason.
void stubArticle(AppHarness harness) {
  harness.adapter.onGet(
    ApiEndpoint.newsArticle(kBackProbeSlug),
    (dynamic server) => server.reply(200, <String, dynamic>{
      'success': true,
      'message': 'ok',
      'data': <String, dynamic>{
        'slug': kBackProbeSlug,
        'title': <String, dynamic>{'en': 'A headline', 'lo': 'A headline'},
        'excerpt': <String, dynamic>{'en': 'An excerpt', 'lo': 'An excerpt'},
      },
    }),
  );
}

/// A citizen who is signed in by the time the app settles, with every read the
/// twelve reachable routes fire answered.
///
/// `stubCertificateEndpoints` is registered **last** so its recorded 43-row
/// `/services` wins over `stubHomeEndpoints`' deliberate empty list — the
/// ordering `certificate_routes_test.dart:131-133` records.
Future<AppHarness> bootSignedIn() async {
  final AppHarness harness = await bootHarness(
    seed: <String, String>{StorageKeys.accessToken: 'access-abc'},
  );
  harness.adapter.onGet(
    ApiEndpoint.meProfile,
    (dynamic server) => server.reply(200, okEnvelope(tCitizenProfileJson())),
  );
  harness.adapter.onPost(
    ApiEndpoint.authLogout,
    (dynamic server) => server.reply(200, okEnvelope(null)),
  );
  stubHomeEndpoints(harness.adapter);
  stubContentEndpoints(harness.adapter);
  stubWalletEndpoints(harness.adapter);
  stubAccountEndpoints(harness.adapter);
  stubHistoryEndpoints(harness.adapter);
  stubCertificateEndpoints(harness.adapter);
  stubArticle(harness);
  return harness;
}

/// A signed-out citizen, with the reads the routes reachable while signed out
/// fire answered.
Future<AppHarness> bootSignedOut() async {
  final AppHarness harness = await bootHarness();
  stubHomeEndpoints(harness.adapter);
  stubContentEndpoints(harness.adapter);
  stubWalletEndpoints(harness.adapter);
  return harness;
}

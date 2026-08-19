/// **B12** — the six certificate routes, driven through the assembled app.
///
/// Six pages landed across four batches, all green under their own widget
/// tests, and **not one of them openable by a citizen**. This file is the
/// batch's primary evidence that they are now.
///
/// ## What "reachable" has to mean here, and why AC-15 is only half of it
///
/// `F4-AC-13` reads *"…and the page is reachable from the app's route table."*
/// Taken literally that is satisfied by a `GoRoute` whose builder returns a red
/// error screen forever. Three measured facts make that not hypothetical:
///
/// 1. **Marriage and Divorce render an empty, error-free, inert form if nobody
///    calls `load()`.** Their cubits' `load()` had no caller in `lib/` at all
///    before B12 (specs.md § 2.2 Finding E) — the pages are `StatelessWidget`s
///    — and `_loadRef` folds a failure into an EMPTY list with `loading: false`
///    (`marriage_form_cubit.dart:391-393`), so there is no error branch either.
/// 2. **Resident, Birth and Death gate on the service read**, so an unstubbed or
///    failing `/services` renders `_ServiceError` permanently while
///    `find.byType(ResidentCertificatePage)` still finds exactly one widget.
/// 3. **The DI container has never been resolved in production.**
///    `certificates_feature_injection.dart:21-22`: *"it would fail at the first
///    resolution, i.e. the first time a citizen opens the form."* Nobody has
///    ever opened the form. These tests are that first resolution.
///
/// So every reachability criterion below is paired with a capability clause:
/// the route resolves, **and** the page is past its own loading and error
/// gates, **and** at least one value that could only have arrived through the
/// DI graph and the network layer is on screen.
///
/// ## Every object below the transport is production's
///
/// `bootHarness` mirrors `DependencyInjection.init()` against a stubbed `Dio`,
/// and B12 extended it to compose `ReferenceFeatureInjection`,
/// `CertificatesFeatureInjection` and `FamilyBookFeatureInjection` — production's
/// own, not hand-written doubles. A route builder that resolved the wrong
/// container, or a `GetIt` ordering fault in another batch's file, fails here.
library;

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/session/bloc/session_bloc.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/features/auth/presentation/pages/auth_page.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/birth/birth_certificate_page.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/birth/birth_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/death/death_certificate_page.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/death/death_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_certificate_page.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_certificate_page.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_certificate_page.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_fields.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_form_cubit.dart';
import 'package:lcc_mobile_app/features/chat/presentation/widgets/chat_launcher.dart';
import 'package:lcc_mobile_app/features/family_book/presentation/bloc/family_book_cubit.dart';
import 'package:lcc_mobile_app/features/family_book/presentation/pages/family_book_page.dart';
import 'package:lcc_mobile_app/features/family_book/presentation/widgets/family_book_chrome.dart';
import 'package:lcc_mobile_app/features/home/presentation/pages/home_page.dart';
import 'package:lcc_mobile_app/features/home/presentation/widgets/action_banner.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';
import 'package:lcc_mobile_app/features/service/domain/service_availability.dart';
import 'package:lcc_mobile_app/features/service/presentation/pages/service_page.dart';
import 'package:lcc_mobile_app/i18n/i18n.dart';
import 'package:lcc_mobile_app/presentation/icons/lucide_icon.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';
import 'package:lcc_mobile_app/utils/routes/app_routes.dart';

import '../../helpers/app_test_harness.dart';
import '../../helpers/auth_mock_data.dart';
import '../../helpers/core_test_helper.dart';
import '../../helpers/service_test_helper.dart';
import '../../helpers/session_test_helper.dart';

// ── The six, as one table every per-row criterion iterates ───────────────────
/// Path → the page class that route must build.
///
/// **Per-row, always** (specs.md § 7.0 P-5): five of six passing is not a
/// whole-criterion PASS, so every loop below carries `reason:` with the path and
/// names the failing row rather than reporting a bare `false`.
const Map<String, Type> kCertificateRoutes = <String, Type>{
  AppNameRoutes.residentCertificate: ResidentCertificatePage,
  AppNameRoutes.birthDeclaration: BirthDeclarationPage,
  AppNameRoutes.deathDeclaration: DeathDeclarationPage,
  AppNameRoutes.marriageCertificate: MarriageCertificatePage,
  AppNameRoutes.divorceCertificate: DivorceCertificatePage,
  AppNameRoutes.familyBook: FamilyBookPage,
};

/// The two sentences Resident, Birth and Death render instead of a form when the
/// `/services` read has not landed or has failed.
///
/// Measured byte-identical across all three
/// (`resident_certificate_page.dart:38-46`, `birth_fields.dart:60-65`,
/// `death_fields.dart:53-57`), which is why one pair covers the three pages.
const String kServiceLoadingText = 'Loading the service…';
const String kServiceFailedText =
    'We could not load this service right now.';

/// The router driving the pumped app.
///
/// Anchored on the root `Navigator`, **not** on `find.byType(Scaffold).first`
/// the way `app_flow_test.dart` and `app_routes_test.dart` do. Measured:
/// `ResidentCertificatePage` and `FamilyBookPage` render **no `Scaffold` at
/// all` — the source's sub-page chrome is a plain column, and the two ported it
/// faithfully — so the shared idiom throws `Bad state: No element` on two of the
/// six routes. The `Navigator` is below `InheritedGoRouter` on every route this
/// build mounts, so it is the anchor that holds for all six.
GoRouter routerOf(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Navigator).first));

String locationOf(WidgetTester tester) => routerOf(tester).state.uri.toString();

Future<void> goTo(WidgetTester tester, String path) async {
  routerOf(tester).go(path);
  await tester.pumpAndSettle();
}

/// A harness whose citizen is signed in by the time the app settles.
///
/// A seeded access token plus a `/me/profile` answer is what takes
/// `SessionBloc` from `initial` to `authenticated` during boot — the same shape
/// `app_flow_test.dart` scenario 2 uses. `stubCertificateEndpoints` is called
/// **here, after `bootHarness`**, which is what makes its recorded 43-row
/// `/services` win over `stubHomeEndpoints`' deliberate empty list.
Future<AppHarness> signedIn({List<String>? requestLog}) async {
  final AppHarness harness = await bootHarness(
    seed: <String, String>{StorageKeys.accessToken: 'access-abc'},
  );
  harness.adapter.onGet(
    ApiEndpoint.meProfile,
    (dynamic server) => server.reply(200, okEnvelope(tCitizenProfileJson())),
  );
  stubCertificateEndpoints(harness.adapter);
  if (requestLog != null) {
    harness.dio.interceptors.insert(
      0,
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          requestLog.add(options.path);
          handler.next(options);
        },
      ),
    );
  }
  return harness;
}

/// The page's own Back control — the header chevron, on any of the six.
///
/// **The six do not agree on how they build it, and this is measured, not
/// assumed.** Four of them — Resident (`:559-570`), Marriage (`:305-315`),
/// Divorce (`:265-275`) and FamilyBook (`family_book_chrome.dart:127-143`) —
/// wrap `LucideIcon(name: 'ChevronLeft')` in a `GestureDetector` inside a
/// `Semantics(button: true)`. F2's two — Birth (`:194-197`) and Death
/// (`:187-190`) — use an `IconButton` and spell the glyph
/// **`'chevron-left'` in kebab case**.
///
/// So the finder matches the glyph by normalised name and taps the icon itself,
/// letting the hit test propagate to whichever tappable ancestor that page
/// chose. Matching only the four would have silently skipped Birth and Death —
/// the finder would return empty and `.first` would throw, which is how this
/// difference was found rather than assumed away.
///
/// Recorded as an observation for the hand-back, **not fixed**: both page files
/// are out of B12's scope (§ 4.1, every file under
/// `lib/features/certificates/**`), and normalising them would be exactly the
/// "obviously better" edit the L-10(b) rule forbids a routing batch.
Finder backChevron() => find
    .byWidgetPredicate(
      (Widget w) =>
          w is LucideIcon &&
          w.name.toLowerCase().replaceAll('-', '') == 'chevronleft',
    )
    .first;

/// Drives the real `LoginForm` — phone, password and the math captcha.
///
/// A copy of `app_flow_test.dart`'s own `_submitLogin` rather than an import,
/// because that one is library-private there. Hand-dispatching
/// `AuthEvent.loginStarted` instead would skip `AuthPage`'s `BlocListener`,
/// which is the half of the round trip `B12-AC-22` most needs exercised: the
/// `from` intent survives the sign-in only if the page the citizen actually used
/// hands the session to the BLoC the router is watching.
Future<void> submitLoginForm(WidgetTester tester) async {
  final String question = tester
      .widgetList<Text>(find.textContaining(' + '))
      .map((Text t) => t.data ?? '')
      .firstWhere(
        (String s) => RegExp(r'^\d+ \+ \d+ = \?$').hasMatch(s),
        orElse: () => throw StateError('captcha not on screen'),
      );
  final List<int> operands = RegExp(r'\d+')
      .allMatches(question)
      .map((Match m) => int.parse(m.group(0)!))
      .toList();

  final Finder fields = find.byType(TextField);
  expect(fields, findsNWidgets(3), reason: 'login id, password, captcha');

  await tester.enterText(fields.at(0), '+8562012345');
  await tester.enterText(fields.at(1), 'password123');
  await tester.enterText(fields.at(2), '${operands[0] + operands[1]}');
  await tester.pumpAndSettle();

  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();
}

/// The live cubit a mounted route built, read off the page widget it was handed
/// to. This is the only way to observe the **builder's** decisions — the `Lang`
/// it computed, the namespace closure it passed, the instance it owns.
T cubitOf<T>(WidgetTester tester, Type pageType) {
  final Widget page = tester.widget(find.byType(pageType));
  return switch (page) {
    ResidentCertificatePage(:final ResidentFormCubit cubit) => cubit as T,
    BirthDeclarationPage(:final BirthFormCubit cubit) => cubit as T,
    DeathDeclarationPage(:final DeathFormCubit cubit) => cubit as T,
    MarriageCertificatePage(:final MarriageFormCubit cubit) => cubit as T,
    DivorceCertificatePage(:final DivorceFormCubit cubit) => cubit as T,
    FamilyBookPage(:final FamilyBookCubit cubit) => cubit as T,
    _ => throw ArgumentError('not a B12 page: $pageType'),
  };
}

void main() {
  tearDown(resetHarness);

  // ══ § 7.3 — reachability, to § 6.1's standard ═════════════════════════════

  group('B12-AC-15 / AC-16 / AC-17 — the six resolve AND render past their '
      'gates', () {
    testWidgets('AC-15 every one of the six resolves and builds its page',
        (WidgetTester tester) async {
      final AppHarness harness = await signedIn();
      await pumpAssembledApp(tester, harness);
      expect(harness.sessionBloc.state.status, SessionStatus.authenticated);

      for (final MapEntry<String, Type> row in kCertificateRoutes.entries) {
        await goTo(tester, row.key);

        expect(locationOf(tester), row.key, reason: row.key);
        expect(find.byType(row.value), findsOneWidget, reason: row.key);
      }
    });

    testWidgets(
        'AC-16 Resident, Birth and Death are past the loading AND error gates',
        (WidgetTester tester) async {
      // AC-15 alone passes against a page showing `_ServiceError` forever. This
      // is the half that does not: the step indicator is the form's own chrome,
      // which only renders once the service read has landed.
      final AppHarness harness = await signedIn();
      await pumpAssembledApp(tester, harness);

      final Map<String, Type> gated = <String, Type>{
        AppNameRoutes.residentCertificate: ResidentStepIndicator,
        AppNameRoutes.birthDeclaration: BirthStepIndicator,
        AppNameRoutes.deathDeclaration: DeathStepIndicator,
      };

      for (final MapEntry<String, Type> row in gated.entries) {
        await goTo(tester, row.key);

        expect(find.byType(row.value), findsOneWidget,
            reason: '${row.key}: the step indicator is the form itself');
        expect(find.textContaining(kServiceLoadingText), findsNothing,
            reason: '${row.key}: still loading');
        expect(find.textContaining(kServiceFailedText), findsNothing,
            reason: '${row.key}: rendering _ServiceError');
      }
    });

    testWidgets(
        'AC-17 Marriage and Divorce render their OWN recorded fee_lak, '
        'formatted by the shared formatter', (WidgetTester tester) async {
      // The capability clause for the two routes whose `load()` the builder
      // owns. A builder that omitted `..load()` renders neither fee, and renders
      // no error either (Finding E) — so this is the criterion that catches it.
      //
      // The fee is rendered on the CTA at the LAST step
      // (`marriage_certificate_page.dart:171-177`, `divorce:151-157`), which is
      // a measured difference from specs.md § 7.5's assumption that a mount
      // shows it. The step is driven with `cubit.emit`, exactly as F3's own
      // page tests do (`marriage_page_widget_test.dart:192`), so the value under
      // assertion is still the one `..load()` fetched over the wire.
      final AppHarness harness = await signedIn();
      await pumpAssembledApp(tester, harness);

      await goTo(tester, AppNameRoutes.marriageCertificate);
      final MarriageFormCubit marriage =
          cubitOf<MarriageFormCubit>(tester, MarriageCertificatePage);
      expect(marriage.state.quote.data?.feeLak, 100000,
          reason: 'the recorded `marriage` row — services.json');
      marriage.emit(marriage.state.copyWith(step: kMarriageStepCount));
      await tester.pumpAndSettle();
      // The CTA, matched exactly. At `kMarriageStepCount` the review card's
      // total renders the same figure, so a `textContaining` would find two —
      // and `find.text` on the composed `marriage.pay` string is the tighter
      // claim anyway: it pins the formatter's output *inside* the sentence the
      // citizen taps.
      expect(find.text('Pay 100,000 LAK'), findsOneWidget,
          reason: 'grouped thousands + the LAK unit is the SHARED formatter, '
              'not a lambda the route invented');

      await goTo(tester, AppNameRoutes.divorceCertificate);
      final DivorceFormCubit divorce =
          cubitOf<DivorceFormCubit>(tester, DivorceCertificatePage);
      expect(divorce.state.quote.data?.feeLak, 10000,
          reason: 'the recorded `divorce` row — services.json');
      divorce.emit(divorce.state.copyWith(step: kDivorceStepCount));
      await tester.pumpAndSettle();
      expect(find.text('Pay 10,000 LAK'), findsOneWidget);
    });

    testWidgets('AC-17 FamilyBook renders the EMPTY state, not an error',
        (WidgetTester tester) async {
      // **The empty state, and the reason is part of the criterion.** `F4-NV-2`
      // records four of eight states as *permanently* NOT EVALUATED pending a
      // seeded staging account, so the populated household has never been
      // observed against real data and asserting one could only be closed
      // against invented data. The empty state is the one `page_pairs.yaml:336`
      // names and the one F4's Tier 1 oracle covers.
      //
      // `showsError` excludes `NotFoundFailure`, so the stubbed 404 is the empty
      // state and **not** an error — exactly the distinction a naive criterion
      // would collapse.
      final AppHarness harness = await signedIn();
      await pumpAssembledApp(tester, harness);

      await goTo(tester, AppNameRoutes.familyBook);

      final FamilyBookCubit cubit =
          cubitOf<FamilyBookCubit>(tester, FamilyBookPage);
      expect(cubit.state.showsEmpty, isTrue,
          reason: 'a 404 must route past the error card into the empty card');
      expect(cubit.state.showsLoading, isFalse);
      expect(cubit.state.showsError, isFalse,
          reason: 'NotFoundFailure is excluded from showsError');
      expect(cubit.state.showsSignedOut, isFalse);

      expect(find.text('familyBookPage.emptyTitle'.tr()), findsOneWidget);
      expect(find.text('familyBookPage.emptyBody'.tr()), findsOneWidget);
    });
  });

  // **B12-AC-18** — one `testWidgets` per route rather than one loop, because
  // each row needs its own boot: the request log has to start empty at the
  // moment the certificate route mounts, and re-booting a second harness inside
  // a single pumped test leaves the previous `App` mounted over containers
  // `resetHarness` has already emptied.
  for (final MapEntry<String, Type> row in kCertificateRoutes.entries) {
    testWidgets(
        'B12-AC-18 mounting ${row.key} issues EXACTLY ONE GET /services',
        (WidgetTester tester) async {
      // Fails both ways: against a missing `..load()` (zero for Marriage and
      // Divorce, whose only `/services` read is the quote port) and against a
      // duplicated one (two for Resident, Birth, Death and FamilyBook, whose
      // pages already fetch from `initState`). It is the criterion RULING 3's
      // asymmetry is answerable to.
      final List<String> log = <String>[];
      final AppHarness harness = await signedIn(requestLog: log);
      await pumpAssembledApp(tester, harness);

      log.clear(); // Home's own boot reads are not this criterion's subject.
      await goTo(tester, row.key);

      final int calls =
          log.where((String p) => p == ApiEndpoint.services).length;
      expect(calls, 1,
          reason: '${row.key} issued $calls — the whole log was $log');
    });
  }

  testWidgets('B12-AC-19 none of the six renders a bottom bar or a chat '
      'launcher', (WidgetTester tester) async {
    // The port of `Layout.tsx:300,385-386`: none of the six certificate tabs is
    // in `MAIN_TABS`, so every one is a sub-page with the bar translated off
    // screen and `<CustomerServiceChat/>` suppressed.
    final AppHarness harness = await signedIn();
    await pumpAssembledApp(tester, harness);
    expect(find.byType(NavigationBar), findsOneWidget,
        reason: 'the control: Home is a MAIN_TAB and does have the bar');

    for (final String path in kCertificateRoutes.keys) {
      await goTo(tester, path);

      expect(find.byType(NavigationBar), findsNothing, reason: path);
      expect(find.byType(ChatLauncher), findsNothing, reason: path);
      expect(find.byType(FloatingActionButton), findsNothing, reason: path);
    }
  });

  test('B12-AC-20 all six are TOP-LEVEL GoRoutes, outside every shell', () async {
    // **Structural, not visual.** AC-19 could in principle be satisfied by a
    // shell that hid its own bar; this asserts the structure
    // `app_routes.dart:572-577` relies on — *"it is a structural property of
    // the route table, not a flag `AppShell` has to be told about."*
    final AppHarness harness = await bootHarness();
    addTearDown(resetHarness);
    final GoRouter router = AppRoutes.build(harness.sessionBloc);
    addTearDown(router.dispose);

    final List<RouteBase> top = router.configuration.routes;

    // 1. Each of the six is a top-level `GoRoute` with that literal path.
    for (final String path in kCertificateRoutes.keys) {
      expect(
        top.whereType<GoRoute>().where((GoRoute r) => r.path == path),
        hasLength(1),
        reason: '$path is not a top-level GoRoute',
      );
    }

    // 2. None is a descendant of any ShellRouteBase, at any depth.
    final Set<String> underAShell = <String>{};
    void walk(List<RouteBase> routes, {required bool inShell}) {
      for (final RouteBase r in routes) {
        final bool nowInShell = inShell || r is ShellRouteBase;
        if (r is GoRoute && inShell) underAShell.add(r.path);
        walk(r.routes, inShell: nowInShell);
      }
    }

    walk(top, inShell: false);
    for (final String path in kCertificateRoutes.keys) {
      expect(underAShell, isNot(contains(path)), reason: path);
    }
    expect(underAShell, containsAll(<String>[AppNameRoutes.home, AppNameRoutes.service]),
        reason: 'the walk is not vacuous — the five MAIN_TABS really are '
            'inside the shell, so "not in underAShell" means something');

    // 3. None is among the `/service` GoRoute's own children.
    final GoRoute service = top
        .expand((RouteBase r) => <RouteBase>[r, ...r.routes])
        .whereType<GoRoute>()
        .firstWhere((GoRoute r) => r.path == AppNameRoutes.service);
    expect(service.routes, isEmpty,
        reason: 'the six are siblings of /service, not children of it — which '
            'is also what makes a top-level `/service/x` match at all '
            '(go_router match.dart:275-278)');
  });

  // ══ § 7.4 — the auth gate ═════════════════════════════════════════════════

  group('B12-AC-21 / AC-22 / AC-23 — protected, round trip, negative control',
      () {
    testWidgets(
        'AC-21 exactly eight paths are gated: /history, /account and the six',
        (WidgetTester tester) async {
      // `_protectedPaths` is private, so this measures the **behaviour** the set
      // configures rather than the set — which is the stronger instrument
      // anyway, and the one § 10's security waiver was granted on. Every path
      // this build mounts is visited signed out and classified.
      final AppHarness harness = await signedIn();
      // Signed OUT: no token seeded, so the boot resolves unauthenticated.
      await resetHarness();
      final AppHarness out = await bootHarness();
      stubCertificateEndpoints(out.adapter);
      await pumpAssembledApp(tester, out);
      expect(out.sessionBloc.state.status, SessionStatus.unauthenticated);
      expect(harness.sessionBloc, isNotNull); // keeps the analyzer honest

      final Set<String> gated = <String>{};
      for (final String path in AppNameRoutes.registered) {
        if (path == AppNameRoutes.signin) continue; // its own redirect branch
        await goTo(tester, path);
        if (locationOf(tester).startsWith(AppNameRoutes.signin)) {
          gated.add(path);
        }
        await goTo(tester, AppNameRoutes.home);
      }

      expect(gated, <String>{
        AppNameRoutes.history,
        AppNameRoutes.account,
        AppNameRoutes.residentCertificate,
        AppNameRoutes.birthDeclaration,
        AppNameRoutes.deathDeclaration,
        AppNameRoutes.marriageCertificate,
        AppNameRoutes.divorceCertificate,
        AppNameRoutes.familyBook,
      });
    });

    for (final MapEntry<String, Type> row in kCertificateRoutes.entries) {
      testWidgets(
          'AC-22 ${row.key} — signed out it gates, and the round trip returns '
          'the citizen to it', (WidgetTester tester) async {
        // **All six, not a sample.** This is one of the two conditions § 10's
        // security-audit waiver was granted on: the criterion asserts the round
        // trip — sign out, `go(path)`, land on `/signin?from=…`, sign in, land
        // back and render past the page's gates — rather than set membership.
        final AppHarness harness = await bootHarness();
        stubCertificateEndpoints(harness.adapter);
        harness.adapter.onPost(
          ApiEndpoint.authLogin,
          (dynamic server) => server.reply(200, okEnvelope(tCitizenSessionJson())),
        );
        harness.adapter.onGet(
          ApiEndpoint.meProfile,
          (dynamic server) =>
              server.reply(200, okEnvelope(tCitizenProfileJson())),
        );

        await pumpAssembledApp(tester, harness);
        expect(harness.sessionBloc.state.status, SessionStatus.unauthenticated);

        await goTo(tester, row.key);
        expect(
          locationOf(tester),
          '/signin?from=${Uri.encodeComponent(row.key)}',
          reason: row.key,
        );
        expect(find.byType(AuthPage), findsOneWidget, reason: row.key);
        expect(tester.widget<AuthPage>(find.byType(AuthPage)).from, row.key,
            reason: 'one encode on the wire, one decode into the page');
        expect(find.byType(row.value), findsNothing, reason: row.key);

        await submitLoginForm(tester);

        expect(harness.sessionBloc.state.status, SessionStatus.authenticated);
        expect(locationOf(tester), row.key,
            reason: '${row.key}: the `from` intent must survive the sign-in');
        expect(find.byType(row.value), findsOneWidget, reason: row.key);
        expect(find.byType(AuthPage), findsNothing, reason: row.key);

        // AC-16's standard on the way back in: reaching the page is not the
        // same as the page working.
        expect(find.textContaining(kServiceFailedText), findsNothing,
            reason: row.key);
      });
    }

    testWidgets('AC-23 NEGATIVE CONTROL — /service stays public signed out',
        (WidgetTester tester) async {
      // `/service` is not in `PROTECTED_TABS` (`App.tsx:29-38`), and the
      // predicate is `location == p || location.startsWith('$p/')`. A
      // `startsWith`-shaped answer to "gate the certificate routes" would add
      // `/service` and gate the whole catalogue **and all six children in one
      // line** — invisibly, because every criterion above would still pass while
      // a signed-out citizen lost the one certificate-adjacent surface with a
      // real Tier 3 baseline.
      final AppHarness harness = await bootHarness();
      stubCertificateEndpoints(harness.adapter);
      await pumpAssembledApp(tester, harness);
      expect(harness.sessionBloc.state.status, SessionStatus.unauthenticated);

      await goTo(tester, AppNameRoutes.service);

      expect(locationOf(tester), AppNameRoutes.service);
      expect(find.byType(ServicePage), findsOneWidget);
      expect(find.byType(AuthPage), findsNothing);
    });
  });

  // ══ § 7.5 — constructor parameters ════════════════════════════════════════

  group('B12-AC-24 / AC-25 / AC-26 / AC-27 / AC-39 — what the builder passes',
      () {
    for (final String code in <String>['en', 'lo']) {
      testWidgets('AC-24 in `$code` every certificate cubit gets the Lang the '
          "page's own build computes", (WidgetTester tester) async {
        // The five certificate routes only — `/service/family-book`'s `param1`
        // is a `bool authenticated` and its language arrives at submit through
        // `requestCopy(Lang)`. AC-39 is its equivalent.
        //
        // **Evaluability note, part of the criterion:** under the app's two
        // supported locales this cannot distinguish the pages' expression from
        // `Lang.fromCode`, whose fallback differs (`FU-B12-2`). It distinguishes
        // both from a hardcoded constant and from an inverted mapping, which are
        // the failures actually available here.
        final Lang expected = code == 'lo' ? Lang.lo : Lang.en;
        final AppHarness harness = await signedIn();
        await pumpAssembledApp(tester, harness, startLocale: Locale(code));

        await goTo(tester, AppNameRoutes.residentCertificate);
        expect(cubitOf<ResidentFormCubit>(tester, ResidentCertificatePage).lang,
            expected);

        await goTo(tester, AppNameRoutes.birthDeclaration);
        expect(cubitOf<BirthFormCubit>(tester, BirthDeclarationPage).lang,
            expected);

        await goTo(tester, AppNameRoutes.deathDeclaration);
        expect(cubitOf<DeathFormCubit>(tester, DeathDeclarationPage).lang,
            expected);

        await goTo(tester, AppNameRoutes.marriageCertificate);
        expect(cubitOf<MarriageFormCubit>(tester, MarriageCertificatePage).lang,
            expected);

        await goTo(tester, AppNameRoutes.divorceCertificate);
        expect(cubitOf<DivorceFormCubit>(tester, DivorceCertificatePage).lang,
            expected);
      });
    }

    testWidgets('AC-25 in LAO, Birth gets the BIRTH namespace and Death the '
        'DEATH one', (WidgetTester tester) async {
      // **Written only in Lao, and that is the criterion, not an omission.**
      // `en.birth.legalBasisText` and `en.death.legalBasisText` are
      // byte-identical (specs.md § 2.1 item 8), so the English form of this
      // assertion passes against a builder that swapped the two namespaces.
      // `B12-AC-36` runs exactly that mutant and records the English pass as the
      // evidence for this note rather than as a claim about it.
      final AppHarness harness = await signedIn();
      await pumpAssembledApp(tester, harness, startLocale: const Locale('lo'));

      await goTo(tester, AppNameRoutes.birthDeclaration);
      final String birth =
          cubitOf<BirthFormCubit>(tester, BirthDeclarationPage)
              .readLegalBasisText();

      await goTo(tester, AppNameRoutes.deathDeclaration);
      final String death =
          cubitOf<DeathFormCubit>(tester, DeathDeclarationPage)
              .readLegalBasisText();

      expect(birth, 'birth.legalBasisText'.tr());
      expect(death, 'death.legalBasisText'.tr());
      expect(birth, isNot(death),
          reason: 'the Lao strings differ; this is the only falsifying locale');
    });

    testWidgets('AC-26 formatLak is the app\'s shared formatter, proved by '
        'behaviour', (WidgetTester tester) async {
      // By behaviour rather than by identity: a lambda the route invented would
      // satisfy `is Function`, and the two branches below are the ones a naive
      // `'$n LAK'` gets wrong.
      final AppHarness harness = await signedIn();
      await pumpAssembledApp(tester, harness);

      await goTo(tester, AppNameRoutes.marriageCertificate);
      final MarriageLakFormatter en = tester
          .widget<MarriageCertificatePage>(find.byType(MarriageCertificatePage))
          .formatLak;
      expect(en(0), 'Free', reason: 'not "0 LAK"');
      expect(en(null), '—', reason: 'an em dash: not configured, not free');
      expect(en(100000), '100,000 LAK');

      await goTo(tester, AppNameRoutes.divorceCertificate);
      final DivorceLakFormatter div = tester
          .widget<DivorceCertificatePage>(find.byType(DivorceCertificatePage))
          .formatLak;
      expect(div(0), 'Free');
      expect(div(null), '—');
    });

    testWidgets('AC-26 and it follows the LOCALE, which a captured constant '
        'would not', (WidgetTester tester) async {
      // Its own boot rather than a second `pumpAssembledApp` in the case above:
      // `EasyLocalization`'s `startLocale` is read once when the widget is
      // first mounted, so re-pumping inside one test keeps the first locale and
      // the assertion would pass or fail for a reason that has nothing to do
      // with the route builder.
      final AppHarness harness = await signedIn();
      await pumpAssembledApp(tester, harness, startLocale: const Locale('lo'));

      await goTo(tester, AppNameRoutes.marriageCertificate);
      final MarriageLakFormatter lo = tester
          .widget<MarriageCertificatePage>(find.byType(MarriageCertificatePage))
          .formatLak;
      expect(lo(0), 'ຟຣີ', reason: 'the Lao "Free"');
      expect(lo(100000), '100,000 ກີບ', reason: 'the Lao unit');
      expect(lo(null), '—', reason: 'the em dash is locale-independent');
    });

    testWidgets('AC-27 one construction and one close() per visit, all six',
        (WidgetTester tester) async {
      // The criterion the naive `cubit: certificatesInjection<T>(param1: lang)`
      // hand-off fails. None of the six pages closes the cubit it is handed, so
      // the route builder's `BlocProvider(create:)` is the only place a
      // `close()` can happen — and each cubit holds one citizen's answers, a
      // created draft `case id` and an `uploaded` slot set.
      //
      // **All six, unconditionally**: every registration involved is a
      // `registerFactoryParam`, including `FamilyBookCubit`'s. F4's own reason
      // is the one worth asserting against — *"a singleton would open the page
      // on step 3 for the next citizen, with the previous citizen's success card
      // already rendered."*
      final AppHarness harness = await signedIn();
      await pumpAssembledApp(tester, harness);

      for (final MapEntry<String, Type> row in kCertificateRoutes.entries) {
        await goTo(tester, row.key);
        final BlocBase<Object?> first =
            cubitOf<BlocBase<Object?>>(tester, row.value);
        expect(first.isClosed, isFalse, reason: row.key);

        await goTo(tester, AppNameRoutes.home);
        expect(first.isClosed, isTrue,
            reason: '${row.key}: navigating away must close it');

        await goTo(tester, row.key);
        final BlocBase<Object?> second =
            cubitOf<BlocBase<Object?>>(tester, row.value);
        expect(second, isNot(same(first)),
            reason: '${row.key}: a second visit must get a fresh instance');
        expect(second.isClosed, isFalse, reason: row.key);

        await goTo(tester, AppNameRoutes.home);
      }
    });

    testWidgets('AC-39 clause 1 — resolved and authenticated builds the cubit '
        'with authenticated: true', (WidgetTester tester) async {
      final AppHarness harness = await signedIn();
      await pumpAssembledApp(tester, harness);

      await goTo(tester, AppNameRoutes.familyBook);

      final FamilyBookCubit cubit =
          cubitOf<FamilyBookCubit>(tester, FamilyBookPage);
      expect(cubit.state.authenticated, isTrue);
      expect(cubit.state.showsEmpty, isTrue, reason: "AC-17's standard");
      expect(cubit.state.showsSignedOut, isFalse);
    });

    testWidgets('AC-39 clause 2 — resolved and unauthenticated, the builder '
        'never runs at all', (WidgetTester tester) async {
      // If the builder DID run here, RULING 6 is not the problem —
      // `_protectedPaths` is.
      final AppHarness harness = await bootHarness();
      stubCertificateEndpoints(harness.adapter);
      await pumpAssembledApp(tester, harness);
      expect(harness.sessionBloc.state.status, SessionStatus.unauthenticated);

      await goTo(tester, AppNameRoutes.familyBook);

      expect(find.byType(FamilyBookPage), findsNothing);
      expect(find.byType(AuthPage), findsOneWidget);
      expect(locationOf(tester),
          '/signin?from=${Uri.encodeComponent(AppNameRoutes.familyBook)}');
    });

    testWidgets(
        'AC-39 clause 3 — a COLD deep link with a valid stored token '
        'constructs nothing during the hold and lands authenticated',
        (WidgetTester tester) async {
      // **This is RULING 6, and it is the clause that catches the bug.** The
      // session is driven through `initial`/`loading` → `authenticated` inside
      // the test: a test that booted authenticated and then navigated would
      // exercise neither failure mode.
      //
      // A builder that hardcoded `param1: true` fires `load()` tokenless during
      // the hold. A builder that read the session once, non-reactively, at build
      // time constructs signed-out and **stays** signed-out after the session
      // resolves, because `refreshListenable` re-runs `_redirect` and no
      // redirect fires for an authenticated citizen on a protected route. Both
      // pass clauses 1 and 2. `B12-AC-40` runs both as controls.
      final AppHarness harness = await bootHarness(
        seed: <String, String>{StorageKeys.accessToken: 'access-abc'},
      );
      stubCertificateEndpoints(harness.adapter);
      // A slow profile call widens the boot window so the hold is observable
      // rather than raced away by an instant in-memory reply.
      harness.adapter.onGet(
        ApiEndpoint.meProfile,
        (dynamic server) => server.reply(
          200,
          okEnvelope(tCitizenProfileJson()),
          delay: const Duration(milliseconds: 300),
        ),
      );

      await mountAssembledApp(tester, harness);
      await tester.pump();

      // Mid-boot, the deep link arrives.
      expect(
        harness.sessionBloc.state.status,
        anyOf(SessionStatus.initial, SessionStatus.loading),
      );
      routerOf(tester).go(AppNameRoutes.familyBook);
      // **Two pumps, the second advancing time inside the 300 ms window.** One
      // frame is not enough: the route transition has not finished building, so
      // `findsNothing` would pass against ANY builder — including the two
      // defective ones — for a reason that has nothing to do with RULING 6.
      // `B12-AC-40` caught exactly that: an earlier revision of this clause
      // passed with `param1: true` in place. Pumping 100 ms lands the
      // transition while the profile call is still in flight.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Still unresolved — the premise of the whole clause.
      expect(
        harness.sessionBloc.state.status,
        anyOf(SessionStatus.initial, SessionStatus.loading),
        reason: 'the hold window closed before it could be observed',
      );
      // And we really are on the route: without this, `findsNothing` below is
      // vacuous — it would also pass if the navigation had never happened.
      expect(locationOf(tester), AppNameRoutes.familyBook);
      expect(find.byType(FamilyBookFrame), findsOneWidget,
          reason: "the route renders the page's own loading chrome, so the "
              'citizen sees one continuous loading state across the transition');

      // The property: **no cubit is constructed during the hold.**
      // `FamilyBookPage` is the only thing that takes one, so its absence is the
      // assertion — and the citizen is not bounced to /signin either, which is
      // the boot hold `_redirect` already provides.
      expect(find.byType(FamilyBookPage), findsNothing,
          reason: 'no cubit may be constructed while the session is unresolved');
      expect(find.byType(AuthPage), findsNothing,
          reason: 'a warm boot must not flash the signed-out screen');

      await tester.pumpAndSettle();

      // Resolved: constructed once, with the resolved value.
      expect(harness.sessionBloc.state.status, SessionStatus.authenticated);
      expect(locationOf(tester), AppNameRoutes.familyBook);
      expect(find.byType(FamilyBookPage), findsOneWidget);

      final FamilyBookCubit cubit =
          cubitOf<FamilyBookCubit>(tester, FamilyBookPage);
      expect(cubit.state.authenticated, isTrue,
          reason: 'a stale `false` read during the hold would strand a '
              'signed-in citizen on the signed-out view');
      expect(cubit.state.showsSignedOut, isFalse);
      expect(cubit.state.showsEmpty, isTrue, reason: "AC-17's standard");
    });
  });

  // ══ § 7.6 — back and the back stack ═══════════════════════════════════════

  group('B12-AC-28 / AC-29 — onBack', () {
    testWidgets('AC-28 at step 1, the page\'s own Back control goes HOME',
        (WidgetTester tester) async {
      // Not `/service`, where the citizen almost certainly came from, and not
      // `context.pop()`, which throws on the single-entry match list every `go`
      // and every deep link produces. `App.tsx:147-158` calls all six with
      // `onBack={() => navigateTo("home")}`.
      final AppHarness harness = await signedIn();
      await pumpAssembledApp(tester, harness);

      for (final String path in kCertificateRoutes.keys) {
        await goTo(tester, AppNameRoutes.service);
        await goTo(tester, path);

        await tester.tap(backChevron());
        await tester.pumpAndSettle();

        expect(locationOf(tester), AppNameRoutes.home,
            reason: '$path: home, not /service and not an exception');
        expect(find.byType(HomePage), findsOneWidget, reason: path);
      }
    });

    testWidgets('AC-29 at step > 1 the same control decrements the step and '
        'stays on the path', (WidgetTester tester) async {
      // `onBack` is **not** "the back button was pressed" — every page guards
      // it (`resident:230-232`, `birth:117-118`, `marriage:122-128`). A builder
      // wired to fire `onBack` unconditionally passes AC-28 and fails this.
      final AppHarness harness = await signedIn();
      await pumpAssembledApp(tester, harness);

      await goTo(tester, AppNameRoutes.marriageCertificate);
      final MarriageFormCubit marriage =
          cubitOf<MarriageFormCubit>(tester, MarriageCertificatePage);
      marriage.emit(marriage.state.copyWith(step: 3));
      await tester.pumpAndSettle();

      await tester.tap(backChevron());
      await tester.pumpAndSettle();

      expect(locationOf(tester), AppNameRoutes.marriageCertificate);
      expect(marriage.state.step, 2);

      await goTo(tester, AppNameRoutes.divorceCertificate);
      final DivorceFormCubit divorce =
          cubitOf<DivorceFormCubit>(tester, DivorceCertificatePage);
      divorce.emit(divorce.state.copyWith(step: 3));
      await tester.pumpAndSettle();

      await tester.tap(backChevron());
      await tester.pumpAndSettle();

      expect(locationOf(tester), AppNameRoutes.divorceCertificate);
      expect(divorce.state.step, 2);
    });
  });

  // ══ § 7.7 — the ServiceAvailability coupling ══════════════════════════════

  group('B12-AC-31 / AC-32 / AC-33 — the catalogue and the banner', () {
    testWidgets('AC-31 END TO END — tapping the resident card on /service '
        'reaches a rendered form', (WidgetTester tester) async {
      // Proves the registry, the predicate, the tap handler, the route, the
      // builder and the DI graph are one working chain rather than six green
      // units. Nothing here is stubbed above the transport.
      final AppHarness harness = await signedIn();
      await pumpAssembledApp(tester, harness);

      await goTo(tester, AppNameRoutes.service);
      expect(find.byType(ServicePage), findsOneWidget);

      // `/service` opens on the eight recorded **categories**, not on cards —
      // the source's own shape. The `resident` row lives under `civil`, so the
      // tap a citizen makes is two taps, and both are made here.
      await tester.tap(find.text('Civil & Population').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Residence Certificate').first);
      await tester.pumpAndSettle();

      expect(locationOf(tester), AppNameRoutes.residentCertificate);
      expect(find.byType(ResidentCertificatePage), findsOneWidget);
      // AC-16's standard, because reaching it is not the same as it working.
      expect(find.byType(ResidentStepIndicator), findsOneWidget);
      expect(find.textContaining(kServiceFailedText), findsNothing);
    });

    testWidgets('AC-32 C-4\'s SURVIVING BRANCH — in the SAME list, a row with '
        'no route_path does nothing while its neighbour navigates',
        (WidgetTester tester) async {
      // Without this control, AC-30 and AC-31 would together be satisfied by a
      // build that navigated on *every* tap.
      //
      // **Both taps are made in one list, on one screen, with one gesture.**
      // `civil` holds all six routed rows and seven unrouted ones, so
      // `national-id` sits directly beneath `resident`. That matters: a control
      // that only tapped an unrouted card would also pass if the tap **missed**
      // — which is exactly what happened to an earlier version of this test,
      // where `Passport` was below the fold and `tap()` warned it had hit
      // nothing. Tapping a routed neighbour first proves the gesture lands.
      final Service nationalId =
          recordedServices().firstWhere((Service s) => s.code == 'national-id');
      expect(nationalId.routePath, isEmpty);
      expect(ServiceAvailability.forApp.destinationFor(nationalId), isNull);

      final AppHarness harness = await signedIn();
      await pumpAssembledApp(tester, harness);
      await goTo(tester, AppNameRoutes.service);
      await tester.tap(find.text('Civil & Population').first);
      await tester.pumpAndSettle();

      // (a) The gesture lands and navigates, on a row that has a destination.
      await tester.ensureVisible(find.text('Residence Certificate').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Residence Certificate').first);
      await tester.pumpAndSettle();
      expect(locationOf(tester), AppNameRoutes.residentCertificate);

      // Back to the same list.
      await goTo(tester, AppNameRoutes.service);
      await tester.tap(find.text('Civil & Population').first);
      await tester.pumpAndSettle();

      // (b) The identical gesture, on the row directly beneath it, does
      // nothing: no navigation, no exception, no toast, no `comingSoon` —
      // `ServicePage.tsx:502-505`, note the absent `else`.
      await tester.ensureVisible(find.text('National ID Card').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('National ID Card').first);
      await tester.pumpAndSettle();

      expect(locationOf(tester), AppNameRoutes.service,
          reason: 'no navigation');
      expect(find.byType(ServicePage), findsOneWidget,
          reason: 'no error, no toast, no comingSoon — the absent `else`');
      expect(tester.takeException(), isNull);
    });

    testWidgets('AC-33 _pathForTab answers every one of TAB_TO_PATH\'s '
        'fourteen tab ids with the path this build mounts',
        (WidgetTester tester) async {
      // **A pure-function test**, reached through its only call site.
      // `_pathForTab` is private, and `ActionBanner.onFollow` is the closure
      // that consumes it — `home_page.dart:328`,
      // `onFollow: (String tab) => context.go(_pathForTab(tab))`. Invoking that
      // closure with each of the fourteen tab strings asserts the mapping
      // without making any claim about what `next_action.tab` contains in
      // production.
      //
      // **Evaluability note, part of the criterion:** no end-to-end banner
      // criterion is written, because there is no recorded authenticated oracle
      // — `oracle/api/` holds ten anonymous content endpoints and no
      // `/me/summary` — so whether the API ever emits a certificate tab is
      // unmeasured. The *need* is proven from the two maps
      // (`routes.ts:12-26` has 14 entries, `_pathForTab` had 7 branches) and
      // does not depend on the frequency.
      final AppHarness harness = await signedIn();
      harness.adapter.onGet(
        ApiEndpoint.meHomeSummary,
        (dynamic server) => server.reply(200, <String, dynamic>{
          'success': true,
          'message': 'ok',
          'data': <String, dynamic>{
            'name': '',
            'verified': false,
            'eid_verified': false,
            'active_applications': 1,
            'ready_documents': 0,
            'unread_notifications': 0,
            'wallet_balance_lak': 0,
            'next_action': <String, dynamic>{
              'action': 'upload_document',
              'tab': 'history',
            },
            'generated_at': '',
          },
        }),
      );
      await pumpAssembledApp(tester, harness);

      // `skipOffstage: false`: measured, Home builds the banner below the fold
      // and the default finder does not see it. The widget is what carries the
      // closure, and the closure is the subject — not whether the banner is
      // scrolled into view, which is Home's own tests' business.
      //
      // Re-read on **every** iteration, never captured once: the closure holds
      // Home's own `BuildContext`, and calling a stale one after the element has
      // been deactivated throws *"Looking up a deactivated widget's ancestor is
      // unsafe"* rather than navigating.
      ValueChanged<String> follow() => tester
          .widget<ActionBanner>(find.byType(ActionBanner, skipOffstage: false))
          .onFollow;

      // `routes.ts:12-26`, all fourteen, in the source's order.
      const Map<String, String> tabToPath = <String, String>{
        'home': AppNameRoutes.home,
        'service': AppNameRoutes.service,
        'history': AppNameRoutes.history,
        'wallet': AppNameRoutes.wallet,
        'account': AppNameRoutes.account,
        'help': AppNameRoutes.help,
        'news': AppNameRoutes.news,
        'auth': AppNameRoutes.signin,
        'resident-certificate': AppNameRoutes.residentCertificate,
        'birth-declaration': AppNameRoutes.birthDeclaration,
        'death-declaration': AppNameRoutes.deathDeclaration,
        'marriage-certificate': AppNameRoutes.marriageCertificate,
        'divorce-certificate': AppNameRoutes.divorceCertificate,
        'family-book': AppNameRoutes.familyBook,
      };
      expect(tabToPath, hasLength(14));

      for (final MapEntry<String, String> row in tabToPath.entries) {
        if (row.key == 'auth') continue; // asserted separately, below
        follow()(row.key);
        await tester.pumpAndSettle();
        expect(routerOf(tester).state.uri.path, row.value,
            reason: 'tab `${row.key}` must map to ${row.value}');
        await goTo(tester, AppNameRoutes.home);
      }

      // ── `auth`, and the limit on how far this can be asserted ─────────────
      //
      // `routes.ts:20` maps `auth` to `/signin`, and this build mounts
      // `/signin`, so the property requires the case. But the citizen driving
      // this banner is **authenticated by construction** — the banner does not
      // render otherwise (`home_state.dart:137-138`) — and `_redirect` bounces
      // an authenticated citizen off `/signin` to `from ?? home` in the same
      // navigation. So the observable end state is `/`, not `/signin`.
      //
      // **Evaluability note, part of the criterion:** this cannot distinguish
      // `_pathForTab('auth') == '/signin'` from `== '/'`. It *does* falsify the
      // failure actually available here — a missing `auth` case, which drops to
      // the default and lands on `/history` — which is the same failure every
      // other row in this test is checking for.
      await goTo(tester, AppNameRoutes.wallet);
      await goTo(tester, AppNameRoutes.home);
      follow()('auth');
      await tester.pumpAndSettle();
      expect(routerOf(tester).state.uri.path, AppNameRoutes.home,
          reason: '`auth` must not fall through to /history');
      expect(routerOf(tester).state.uri.path, isNot(AppNameRoutes.history));

      // The fallback is now unreachable from `TAB_TO_PATH` and must stay: the
      // default exists for a tab the *API* names that the *source* does not map
      // (`HomePage.tsx:409`). Deleting a default because today's inputs never
      // reach it is how a `switch` starts throwing in production.
      await goTo(tester, AppNameRoutes.home);
      follow()('a-tab-no-build-mounts');
      await tester.pumpAndSettle();
      expect(routerOf(tester).state.uri.path, AppNameRoutes.history);
    });
  });
}

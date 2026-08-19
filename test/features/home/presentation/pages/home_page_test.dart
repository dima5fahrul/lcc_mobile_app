/// `HomePage` — what a citizen actually sees.
///
/// The BLoC tests assert the state machine; these assert that each state is
/// **rendered distinguishably**, which is what § 6.6 and B2-AC-16 require and
/// what a state-level test cannot show.
///
/// Also here:
/// * **B2-AC-33** — the two auth-gated regions, absent signed out and present
///   signed in, with Tier 3 recorded NOT EVALUATED for them by name.
/// * **B2-AC-15** — Lao glyphs on API text, zero tofu, against the resolved
///   font chain rather than a family name.
/// * **C-2 / C-4** — Home's "Apply now", and its silent no-op.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/home/domain/entities/home_summary.dart';
import 'package:lcc_mobile_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:lcc_mobile_app/features/home/presentation/widgets/action_banner.dart';
import 'package:lcc_mobile_app/features/home/presentation/widgets/category_slider.dart';
import 'package:lcc_mobile_app/features/home/presentation/widgets/faq_accordion.dart';
import 'package:lcc_mobile_app/features/home/presentation/widgets/home_panels.dart';
import 'package:lcc_mobile_app/features/home/presentation/widgets/home_service_card.dart';
import 'package:lcc_mobile_app/features/home/presentation/widgets/lao_id_card.dart';
import 'package:lcc_mobile_app/features/home/presentation/widgets/news_slider.dart';
import 'package:lcc_mobile_app/features/home/presentation/widgets/summary_tiles.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';
import 'package:lcc_mobile_app/features/service/domain/service_availability.dart';

import '../../../../helpers/home_test_helper.dart';
import '../../../../helpers/service_test_helper.dart';

void main() {
  late FakeHomeRepository repository;
  late HomeBloc bloc;

  setUp(() => repository = FakeHomeRepository());

  /// Builds the BLoC **inside the test body**, never in `setUp`.
  ///
  /// `app_test_harness.dart`'s hazard 3: a `Bloc` constructed in `setUp` lives
  /// outside `testWidgets`' `FakeAsync` zone, so no amount of pumping flushes
  /// its microtasks — the event is accepted and never handled, every region
  /// sits on `loading`, and every assertion fails while the framework reports
  /// no error.
  HomeBloc build() {
    bloc = homeBlocOver(repository);
    addTearDown(bloc.close);
    return bloc;
  }

  group('B2-AC-16 — four distinguishable states, per region', () {
    testWidgets('loading is a skeleton, not an empty grid',
        (WidgetTester tester) async {
      repository.latency = kHomeStubLatency;
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b);

      expect(find.byType(HomeSkeleton), findsWidgets);
      expect(find.byType(HomeServiceCard), findsNothing);
      expect(find.byType(HomeErrorNotice), findsNothing);
      expect(find.byType(HomeEmptyNotice), findsNothing);

      await tester.pump(kHomeStubLatency);
      await tester.pump();
    });

    testWidgets('data is six quick actions plus the More tile',
        (WidgetTester tester) async {
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b);
      await settleHome(tester);

      expect(find.byType(HomeServiceCard), findsNWidgets(6));
      expect(find.byType(MoreServicesTile), findsOneWidget);
      expect(find.byType(HomeSkeleton), findsNothing);
    });

    testWidgets('empty is its own panel — stubbed, because staging is not',
        (WidgetTester tester) async {
      // "empty states will not occur against staging by accident, so they must
      // be tested with a stubbed empty response, not left to be discovered in
      // production" (§ 6.6).
      repository.emptyEverything();
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b);
      await settleHome(tester);

      expect(find.byType(HomeServiceCard), findsNothing);
      expect(find.byType(HomeErrorNotice), findsNothing);
      expect(
        find.text('No services are open for online requests yet.'),
        findsOneWidget,
      );
      expect(find.text('There are no announcements right now.'), findsOneWidget);
      expect(find.text('No questions have been published yet.'), findsOneWidget);
    });

    testWidgets('error carries a retry, and the retry refetches',
        (WidgetTester tester) async {
      repository.failEverything();
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b);
      await settleHome(tester);

      // Three independent error panels — services, news, FAQ — each with its
      // own "Try again". Four would mean the summary's rendered while signed
      // out, which it must not be.
      expect(find.byType(HomeErrorNotice), findsNWidgets(3));
      expect(find.text('We could not load the service list.'), findsOneWidget);
      expect(find.text('We could not load the news.'), findsOneWidget);
      expect(find.text('We could not load the questions.'), findsOneWidget);
      expect(find.text('Try again'), findsNWidgets(3));

      expect(repository.phase1Calls, 1);
      await tester.tap(find.text('Try again').first);
      await settleHome(tester);
      expect(repository.phase1Calls, 2);
    });

    testWidgets('the error panel never prints the backend sentence',
        (WidgetTester tester) async {
      // `home_repository_impl.dart`'s reason: a server message on a page that
      // also renders a citizen's UIN is backend detail on an authenticated
      // surface. The `Failure` carries it for logs; the screen shows the fixed
      // bilingual copy.
      repository.failEverything();
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b);
      await settleHome(tester);

      expect(find.textContaining('stubbed failure'), findsNothing);
    });

    testWidgets('a failed search shows the error, not "No services found"',
        (WidgetTester tester) async {
      // B2-AC-16: "An empty list or dropdown is never an acceptable rendering
      // of a failed fetch."
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b);
      await settleHome(tester);

      repository.failEverything();
      await tester.enterText(find.byType(TextField), 'zzzz');
      await settleHome(tester);

      expect(find.text('No services found'), findsNothing);
      expect(find.text('We could not load the service list.'), findsOneWidget);
    });

    testWidgets('an empty SEARCH says "No services found", not the catalogue '
        'sentence', (WidgetTester tester) async {
      // Two different empties, and folding them would tell a citizen who
      // mistyped that the government has no services.
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b);
      await settleHome(tester);

      repository.search = const Right<Failure, List<Service>>(<Service>[]);
      await tester.enterText(find.byType(TextField), 'zzzz');
      await settleHome(tester);

      expect(find.text('No services found'), findsOneWidget);
      expect(
        find.text('No services are open for online requests yet.'),
        findsNothing,
      );
    });
  });

  group('B2-AC-33 — the two auth-gated regions', () {
    testWidgets('signed out: absent, not a spinner and not an error',
        (WidgetTester tester) async {
      // § 6.6 / manifest F-4: "a signed-out home shows the masked-identity
      // block and 'Sign in to activate', not a spinner and not an error."
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b);
      await settleHome(tester);

      expect(find.byType(SummaryTiles), findsNothing);
      expect(find.byType(ActionBanner), findsNothing);
      expect(find.text('Active applications'), findsNothing);
      expect(find.text('We could not load your summary.'), findsNothing);

      // …and the card is the masked specimen with the CTA.
      expect(find.byType(LaoIdCard), findsOneWidget);
      expect(find.text('B••••• •••••••h'), findsOneWidget);
      expect(find.text('1-••••-•••••-•5'), findsOneWidget);
      expect(find.text('Sign in to activate'), findsOneWidget);
    });

    testWidgets('signed in: four tiles, the citizen name, the issued UIN',
        (WidgetTester tester) async {
      final FakeSessionBloc session = FakeSessionBloc(authenticated: true);
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b, session: session);
      await settleHome(tester);

      expect(find.byType(SummaryTiles), findsOneWidget);
      expect(find.text('Active applications'), findsOneWidget);
      expect(find.text('Documents ready'), findsOneWidget);
      expect(find.text('Wallet balance'), findsOneWidget);
      expect(find.text('Unread notices'), findsOneWidget);
      // `formatLak(145000, 'en')` — the one tile whose value is formatted.
      expect(find.text('145,000 LAK'), findsOneWidget);
      // The signed-in card shows the name outright and masks only the UIN.
      expect(find.text('Bounmy Sisavath'), findsWidgets);
      expect(find.text('1-••••-•••••-•9'), findsOneWidget);
      expect(find.text('Sign in to activate'), findsNothing);
    });

    testWidgets('signing in mid-visit fills them without a navigation',
        (WidgetTester tester) async {
      // `enabled: isAuthenticated` re-evaluates when the flag changes; a mount
      // event carrying the value would not.
      final FakeSessionBloc session = FakeSessionBloc();
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b, session: session);
      await settleHome(tester);
      expect(find.byType(SummaryTiles), findsNothing);

      session.signIn();
      await settleHome(tester);

      expect(find.byType(SummaryTiles), findsOneWidget);
      expect(repository.summaryCalls, 1);
    });

    testWidgets('signing out removes them and the citizen data with them',
        (WidgetTester tester) async {
      final FakeSessionBloc session = FakeSessionBloc(authenticated: true);
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b, session: session);
      await settleHome(tester);
      expect(find.text('145,000 LAK'), findsOneWidget);

      session.signOut();
      await settleHome(tester);

      expect(find.byType(SummaryTiles), findsNothing);
      expect(find.text('145,000 LAK'), findsNothing);
      expect(find.text('Bounmy Sisavath'), findsNothing);
      expect(find.text('Sign in to activate'), findsOneWidget);
    });

    testWidgets('the summary has its own loading and error, signed in',
        (WidgetTester tester) async {
      repository.summary = const Left<Failure, HomeSummary>(Failure('403'));
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b, session: FakeSessionBloc(authenticated: true));
      await settleHome(tester);

      expect(find.text('We could not load your summary.'), findsOneWidget);
      expect(find.byType(SummaryTiles), findsNothing);
    });

    testWidgets('the action banner renders only with a next_action',
        (WidgetTester tester) async {
      repository.summary = Right<Failure, HomeSummary>(
        tHomeSummary(nextAction: tNextAction),
      );
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b, session: FakeSessionBloc(authenticated: true));
      await settleHome(tester);

      expect(find.byType(ActionBanner), findsOneWidget);
      // No label on the wire, so the translated title is the fallback.
      expect(
        find.text('Action required — Residence Certificate'),
        findsOneWidget,
      );
      expect(find.text('RC-2026-004821'), findsOneWidget);
      expect(find.text('Update document'), findsOneWidget);
    });

    testWidgets('dismissing the banner asks first, and "Keep it" keeps it',
        (WidgetTester tester) async {
      repository.summary = Right<Failure, HomeSummary>(
        tHomeSummary(nextAction: tNextAction),
      );
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b, session: FakeSessionBloc(authenticated: true));
      await settleHome(tester);

      await tester.tap(find.descendant(
        of: find.byType(ActionBanner),
        matching: find.byType(IconButton),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Dismiss notification?'), findsWidgets);
      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();

      expect(find.byType(ActionBanner), findsOneWidget);

      // …and "Yes, dismiss" does dismiss it.
      await tester.tap(find.descendant(
        of: find.byType(ActionBanner),
        matching: find.byType(IconButton),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, dismiss'));
      await tester.pumpAndSettle();

      expect(find.byType(ActionBanner), findsNothing);
    });
  });

  group('C-2 / C-4 — Home\'s "Apply now"', () {
    test('the predicate is the one B2a built, not a second copy', () {
      // SSD § 13 C-2: "one availability predicate, one place… exactly two call
      // sites: the catalogue card's tap handler and — in B2b — Home's
      // 'Apply now'." This is the second.
      expect(ServiceAvailability.forApp, isA<ServiceAvailability>());
    });

    test('C-4 after B12: the 37 rows WITHOUT a route_path are still no-ops', () {
      // Before B12 this asserted all 43 were no-ops, because `AppNameRoutes`
      // mounted none of the six certificate paths. B12 mounted all six, so the
      // assertion is **rewritten to the surviving branch of the same rule**
      // rather than deleted: C-4 now governs the 37 rows with no `route_path`,
      // and it governs them exactly as before — the card renders, Apply Now
      // closes the sheet, and nothing else happens
      // (`HomePage.tsx:908-912`, note the absent `else`).
      //
      // This is the control that keeps AC-30 and AC-31 honest. Without it, a
      // build that navigated on *every* tap would satisfy both.
      final List<Service> unrouted = recordedServices()
          .where((Service s) => s.routePath.isEmpty)
          .toList(growable: false);

      expect(unrouted, hasLength(37),
          reason: '43 recorded rows, 6 with a route_path');
      for (final Service s in unrouted) {
        expect(
          ServiceAvailability.forApp.destinationFor(s),
          isNull,
          reason: '${s.code} became navigable without a route being mounted',
        );
      }
    });

    test('C-3: Home gates on the registry, never on route_path', () {
      // Six of 43 carry a `route_path`, and after B12 this build mounts a page
      // for all six — so all six resolve. **The rewrite is the value, not the
      // rule**: the answer still comes from `AppNameRoutes.registered` and
      // never from the `route_path` field itself, which is what C-3 forbids.
      //
      // The falsification of C-3 lives in `service_domain_test.dart`'s
      // "the answer flips on the CLIENT registry" case, which holds the same
      // rows against a registry mounting only one of them and watches five go
      // dark. Here the point is narrower and still worth pinning: reading
      // `route_path` as "tappable" happens to agree with the registry today,
      // and would stop agreeing the moment the API added a seventh.
      final List<Service> withRoutePath = recordedServices()
          .where((Service s) => s.routePath.isNotEmpty)
          .toList(growable: false);

      expect(withRoutePath, hasLength(6));
      for (final Service s in withRoutePath) {
        expect(ServiceAvailability.forApp.isAvailable(s), isTrue,
            reason: s.code);
        expect(ServiceAvailability.forApp.destinationFor(s), s.routePath,
            reason: '${s.code} must resolve to its OWN route_path');
      }
    });

    testWidgets('tapping a card opens the sheet with the row\'s own fee',
        (WidgetTester tester) async {
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b);
      await settleHome(tester);

      await tester.tap(find.text('Residence Certificate').first);
      await tester.pumpAndSettle();

      expect(find.text('Processing time'), findsOneWidget);
      expect(find.text('Same day (target)'), findsOneWidget);
      expect(find.text('Required documents'), findsOneWidget);
      expect(find.text('Family book'), findsOneWidget);
      expect(find.text('Service fee'), findsOneWidget);
      // From the recorded row, not from a seeded price table.
      expect(find.text('20,000 LAK'), findsWidgets);
    });

    testWidgets('a fee RANGE renders with an en dash — the `marriage` row',
        (WidgetTester tester) async {
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b);
      await settleHome(tester);

      expect(find.text('100,000–250,000 LAK'), findsWidgets);
    });

    testWidgets('a free service reads Free — the `family-book` row',
        (WidgetTester tester) async {
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b);
      await settleHome(tester);

      expect(find.text('Free'), findsWidgets);
    });

    testWidgets(
        'Apply Now on a row with NO route_path closes the sheet and navigates '
        'nowhere (C-4)', (WidgetTester tester) async {
      // ── Rewritten by B12, and the subject had to move ────────────────────
      //
      // This tapped `Residence Certificate` before B12, when `AppNameRoutes`
      // mounted no certificate path and every one of the 43 rows was a dead
      // tap. B12 mounts all six, and **Home's six quick-action cards are
      // exactly those six** (`recordedPhase1Services()` — codes `resident`,
      // `birth`, `death`, `marriage`, `divorce`, `family-book`), so no unrouted
      // row is on the default grid at all: `resident` now navigates, and this
      // rig has a plain `MaterialApp` with no router to navigate in.
      //
      // The **rule is unchanged and is not weakened** — C-4 still governs every
      // row with no `route_path`, and there are 37 of them. What changed is
      // which row demonstrates it, so the test reaches one through the search
      // path. `passport` is the same row `B12-AC-32` uses as its control.
      //
      // The other half — Apply Now on a row that DOES resolve actually
      // navigating — is `B12-AC-31` in `test/utils/routes/certificate_routes_test.dart`,
      // driven end to end through the real router against `/service`. That is a
      // stronger instrument than this rig could be, which is why the half is
      // there rather than duplicated here.
      final Service passport = recordedCatalogue()
          .firstWhere((Service s) => s.code == 'passport');
      expect(passport.routePath, isEmpty,
          reason: 'the control is only a control if the row really has no '
              'destination for this build to mount');

      repository.search =
          Right<Failure, List<Service>>(<Service>[passport]);

      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b);
      await settleHome(tester);

      await tester.enterText(find.byType(TextField), 'passport');
      await settleHome(tester);
      expect(find.byType(HomeServiceCard), findsOneWidget);

      await tester.tap(find.text('Passport').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Apply Now'));
      await tester.pumpAndSettle();

      // The sheet is gone and the page is still Home. No exception, no route
      // change, no "coming soon" — the source's dead tap, ported
      // (`HomePage.tsx:908-912`, note the absent `else`).
      expect(find.text('Processing time'), findsNothing);
      expect(find.byType(HomeServiceCard), findsOneWidget);
    });
  });

  group('the page in Lao — B2-AC-15, zero tofu on API text', () {
    testWidgets('every code point the page renders is in the font chain',
        (WidgetTester tester) async {
      // The AC-24 lesson: a family name reaching `ThemeData` proves nothing.
      // This reads the resolved chain's `cmap` off disk and asserts the Lao
      // catalogue text is covered — the capability, not the configuration.
      await loadAppFonts();

      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b, locale: const Locale('lo'));
      await settleHome(tester);

      final Set<int> covered = appFontChainCoverage();

      final Set<int> rendered = <int>{};
      for (final Text text in tester.widgetList<Text>(find.byType(Text))) {
        rendered.addAll((text.data ?? '').runes);
      }
      expect(rendered, isNotEmpty, reason: 'the page rendered no text at all');

      final Set<int> missing = rendered.difference(covered);
      expect(
        missing,
        isEmpty,
        reason: 'these code points would draw as tofu: '
            '${missing.map(String.fromCharCode).join()}',
      );
    });

    testWidgets('the catalogue names render in Lao, not through an en fallback',
        (WidgetTester tester) async {
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b, locale: const Locale('lo'));
      await settleHome(tester);

      // The recorded `resident` row's `name.lo`. If the locale loop silently
      // rendered English — the second defect behind AC-24 — this is what
      // catches it.
      expect(find.text('ໃບຢັ້ງຢືນທີ່ຢູ່'), findsWidgets);
      expect(find.text('Residence Certificate'), findsNothing);
      // …and the chrome too: the section headings and the specimen card's
      // labels come from `lo.json`, not from an English fallback.
      expect(find.text('ທ່ານຕ້ອງການຫຍັງ?'), findsOneWidget);
      expect(find.text('What do you need?'), findsNothing);
      expect(find.text('ເຂົ້າສູ່ລະບົບເພື່ອເປີດໃຊ້'), findsOneWidget);
      expect(find.text('Sign in to activate'), findsNothing);
      // Nothing failed, so no retry string should be on screen — a cheap
      // guard against asserting Lao copy while looking at an error page.
      expect(find.text('ລອງໃໝ່'), findsNothing);
    });

    testWidgets('the ASCII numerals in a Lao fee are covered by the fallback',
        (WidgetTester tester) async {
      // The exact gap that made a Lao-only subset pass AC-24: the fee amounts
      // and counts are ASCII digits in BOTH locales, and `NotoSansLao` maps
      // 0/10 of them.
      await loadAppFonts();
      final Set<int> covered = appFontChainCoverage();

      for (final int digit in '0123456789,'.runes) {
        expect(covered, contains(digit));
      }
    });
  });

  group('the rest of the page renders', () {
    testWidgets('the category slider draws all eight slides',
        (WidgetTester tester) async {
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b);
      await settleHome(tester);

      expect(find.byType(CategorySlider), findsOneWidget);
      expect(find.text('Civil & Population'), findsWidgets);
      expect(kCategorySlides, hasLength(8));
    });

    testWidgets('the slider is hidden while searching — HomePage.tsx:541',
        (WidgetTester tester) async {
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b);
      await settleHome(tester);
      expect(find.byType(CategorySlider), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'cert');
      await settleHome(tester);

      expect(find.byType(CategorySlider), findsNothing);
      expect(find.byType(MoreServicesTile), findsNothing,
          reason: 'no "More" tile while searching either');
    });

    testWidgets('the news slider prints the formatted date and the category',
        (WidgetTester tester) async {
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b);
      await settleHome(tester);

      expect(find.byType(NewsSlider), findsOneWidget);
      expect(find.text('06 Aug 2026'), findsOneWidget);
      expect(find.text('Announcement'), findsOneWidget);

      // The strip is a lazy horizontal `ListView`, so cards 2 and 3 are not
      // built until they are scrolled to. Dragging is the assertion that they
      // exist at all — `skipOffstage: false` would not help, because an
      // unbuilt element has no widget to find.
      await tester.drag(find.byType(NewsSlider), const Offset(-700, 0));
      await settleHome(tester);

      // The plain-string row: `category_name: 'Notice'` with no `{en,lo}`.
      expect(find.text('Notice'), findsOneWidget);

      await tester.drag(find.byType(NewsSlider), const Offset(-700, 0));
      await settleHome(tester);

      // The unparseable date is printed verbatim rather than blanked.
      expect(find.text('not-a-date'), findsOneWidget);
    });

    testWidgets('the FAQ opens the first question and moves on a tap',
        (WidgetTester tester) async {
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b);
      await settleHome(tester);

      expect(find.byType(FaqAccordion), findsOneWidget);
      expect(find.text('Question 1?'), findsOneWidget);
      expect(find.text('Answer 1.'), findsOneWidget,
          reason: 'the first question is open on arrival');
      expect(find.text('Answer 2.'), findsNothing);

      await tester.tap(find.text('Question 2?'));
      await tester.pumpAndSettle();

      expect(find.text('Answer 2.'), findsOneWidget);
      expect(find.text('Answer 1.'), findsNothing);
    });

    testWidgets('the search field clears and returns to the quick actions',
        (WidgetTester tester) async {
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b);
      await settleHome(tester);

      await tester.enterText(find.byType(TextField), 'cert');
      await settleHome(tester);
      expect(find.byType(MoreServicesTile), findsNothing);

      await tester.tap(find.byTooltip('Clear search'));
      await settleHome(tester);

      expect(find.byType(MoreServicesTile), findsOneWidget);
      expect(find.byType(HomeServiceCard), findsNWidgets(6));
    });

    testWidgets('the QR button opens the verification dialog',
        (WidgetTester tester) async {
      final FakeSessionBloc session = FakeSessionBloc(authenticated: true);
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b, session: session);
      await settleHome(tester);

      await tester.tap(find.bySemanticsLabel('Tap to verify in person'));
      await tester.pumpAndSettle();

      expect(find.text('In-person verification'), findsWidgets);
      // The card's payload, printed as text — "because the card's payload is a
      // URL or code, not an image the API renders for us".
      expect(find.text('https://verify.example/la/abc123'), findsOneWidget);
    });

    testWidgets('the UIN toggle reveals and re-hides, signed in only',
        (WidgetTester tester) async {
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b, session: FakeSessionBloc(authenticated: true));
      await settleHome(tester);

      expect(find.text('1-••••-•••••-•9'), findsOneWidget);
      await tester.tap(find.byTooltip('Show'));
      await tester.pumpAndSettle();

      expect(find.text('1-2540-08842-99'), findsOneWidget);
      await tester.tap(find.byTooltip('Hide'));
      await tester.pumpAndSettle();
      expect(find.text('1-••••-•••••-•9'), findsOneWidget);
    });

    testWidgets('signed out there is no toggle at all',
        (WidgetTester tester) async {
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b);
      await settleHome(tester);

      expect(find.byTooltip('Show'), findsNothing);
      expect(find.byTooltip('Hide'), findsNothing);
    });

    testWidgets('the Customize and How-it-works chips render and are inert',
        (WidgetTester tester) async {
      // The scope decision recorded in `home_page.dart`'s library doc: the
      // Customize modal is not ported (its whole effect is `localStorage`,
      // which SSD § 12.4 forbids) and `TutorialOverlay` is not in B2b's
      // 1,516-line port list. Tier 1 compares the text the web presents, so
      // both chips render; neither does anything, and this test is the record
      // that the inertness is intended rather than a missing wire.
      final HomeBloc b = build()..add(const HomeStarted());
      await pumpHomePage(tester, b);
      await settleHome(tester);

      expect(find.text('Customize'), findsOneWidget);
      expect(find.text('How it works'), findsOneWidget);

      await tester.tap(find.text('Customize'));
      await tester.pumpAndSettle();
      expect(find.text('Customize home menu'), findsNothing);
    });
  });
}

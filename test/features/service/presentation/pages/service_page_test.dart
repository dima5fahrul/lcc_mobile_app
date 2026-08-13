/// The catalogue page's behaviour — the criteria Tier 1 cannot express.
///
/// Tier 1 (`test/fidelity/tier1_structural_parity_test.dart`) already proves
/// every string is right, in the right order, in both locales, in all nine
/// states. What it cannot see is *behaviour*: what a tap does, what the page
/// asked the API for, and whether the four states are distinguishable as
/// widgets rather than as text. That is this file.
///
/// | Group | Criterion |
/// |---|---|
/// | four states | **B2-AC-16** — loading · data · empty (stubbed) · error-with-retry |
/// | C-1 / C-3 / C-4 | **B2-AC-34** — 43 render, no `route_path` gating, dead tap |
/// | server order | **B2-AC-35** — no client re-sort, no `active` filter |
/// | Lao at scale | **B2-AC-15** — 43 names + 8 categories, zero tofu, taller |
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service_category.dart';
import 'package:lcc_mobile_app/features/service/domain/service_availability.dart';
import 'package:lcc_mobile_app/features/service/presentation/bloc/service_bloc.dart';
import 'package:lcc_mobile_app/features/service/presentation/pages/service_page.dart';
import 'package:lcc_mobile_app/features/service/presentation/widgets/catalogue_grid.dart';
import 'package:lcc_mobile_app/features/service/presentation/widgets/catalogue_panels.dart';
import 'package:lcc_mobile_app/features/service/presentation/widgets/category_card.dart';
import 'package:lcc_mobile_app/features/service/presentation/widgets/service_card.dart';

import '../../../../helpers/service_test_helper.dart';

/// Builds the double and its BLoC **inside the test body** — see the same note
/// in `tier1_structural_parity_test.dart`. A `Bloc` made in `setUp` lives
/// outside the `FakeAsync` zone and never handles a single event.
({FakeServiceRepository repository, ServiceBloc bloc}) build() {
  final FakeServiceRepository repository = FakeServiceRepository();
  final ServiceBloc bloc = serviceBlocOver(repository);
  addTearDown(bloc.close);
  return (repository: repository, bloc: bloc);
}

void main() {
  group('B2-AC-16 — four distinguishable states, category view', () {
    testWidgets('loading is a skeleton, not an empty grid',
        (WidgetTester tester) async {
      final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
      repository.latency = kStubLatency;
      bloc.add(const ServiceStarted());
      await pumpServicePage(tester, bloc);

      expect(find.byType(SkeletonGrid), findsOneWidget);
      expect(find.byType(CategoryCard), findsNothing);
      expect(find.byType(CatalogueEmptyPanel), findsNothing);
      expect(find.byType(CatalogueErrorPanel), findsNothing);

      await tester.pump(kStubLatency);
    });

    testWidgets('data is 8 cards', (WidgetTester tester) async {
      final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
      bloc.add(const ServiceStarted());
      await pumpServicePage(tester, bloc);
      await settleCatalogue(tester);

      expect(find.byType(CategoryCard), findsNWidgets(8));
      expect(find.byType(SkeletonGrid), findsNothing);
    });

    testWidgets('empty is its own panel — stubbed, because staging is never '
        'empty', (WidgetTester tester) async {
      // § 6.6: `/services` returns 43 and `/service-categories` returns 8, so
      // "empty states will not occur against staging by accident, so they must
      // be tested with a stubbed empty response, not left to be discovered in
      // production."
      final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
      repository.succeed(categories: const <ServiceCategory>[]);
      bloc.add(const ServiceStarted());
      await pumpServicePage(tester, bloc);
      await settleCatalogue(tester);

      expect(find.byType(CatalogueEmptyPanel), findsOneWidget);
      expect(find.byType(CatalogueErrorPanel), findsNothing);
      expect(find.byType(CategoryCard), findsNothing);
      // B2-AC-16's own words: an empty list is never an acceptable rendering
      // of a failure, and the converse holds too — this must not look like one.
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('error offers a retry, and the retry re-fetches BOTH queries',
        (WidgetTester tester) async {
      final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
      repository.failCategories();
      bloc.add(const ServiceStarted());
      await pumpServicePage(tester, bloc);
      await settleCatalogue(tester);

      expect(find.byType(CatalogueErrorPanel), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(repository.categoryCalls, 1);

      repository.succeed();
      await tester.tap(find.text('Retry'));
      await settleCatalogue(tester);

      // `retryCatalogue()` refetches categories AND the unfiltered services —
      // the per-category counts come from the second one, so retrying only the
      // first would recover the chips and leave every count at zero.
      expect(repository.categoryCalls, 2);
      expect(repository.serviceCalls, hasLength(2));
      expect(find.byType(CategoryCard), findsNWidgets(8));
    });
  });

  group('B2-AC-16 — four distinguishable states, list view', () {
    testWidgets('loading · data · empty · error, each distinct',
        (WidgetTester tester) async {
      final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
      bloc.add(const ServiceStarted());
      await pumpServicePage(tester, bloc);
      await settleCatalogue(tester);

      // loading
      repository.latency = kStubLatency;
      repository.nextServices = recordedServicesIn('civil');
      bloc.add(const ServiceCategorySelected('civil'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(SkeletonGrid), findsOneWidget);
      expect(find.byType(ServiceCard), findsNothing);

      // data
      repository.latency = Duration.zero;
      await settleCatalogue(tester);
      expect(find.byType(ServiceCard), findsNWidgets(13));
      expect(find.byType(SkeletonGrid), findsNothing);

      // empty
      repository.nextServices = const <Service>[];
      bloc.add(const ServiceListRetried());
      await settleCatalogue(tester);
      expect(find.byType(CatalogueEmptyPanel), findsOneWidget);
      expect(find.byType(ServiceCard), findsNothing);
      // A category IS active, so the way back out is offered.
      expect(find.text('Browse other categories'), findsOneWidget);

      // error
      repository.failServices();
      bloc.add(const ServiceListRetried());
      await settleCatalogue(tester);
      expect(find.byType(CatalogueErrorPanel), findsOneWidget);
      expect(find.byType(CatalogueEmptyPanel), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('the list retry refetches ONLY the list',
        (WidgetTester tester) async {
      final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
      bloc.add(const ServiceStarted());
      await pumpServicePage(tester, bloc);
      await settleCatalogue(tester);

      repository.failServices();
      bloc.add(const ServiceCategorySelected('civil'));
      await settleCatalogue(tester);

      final int categoriesBefore = repository.categoryCalls;
      repository.succeed(services: recordedServicesIn('civil'));
      await tester.tap(find.text('Retry'));
      await settleCatalogue(tester);

      // `listQuery.refetch`, not `retryCatalogue()` — the chips are fine, only
      // the grid failed.
      expect(repository.categoryCalls, categoriesBefore);
      expect(find.byType(ServiceCard), findsNWidgets(13));
    });
  });

  group('B2-AC-34 — C-1, C-3 and C-4', () {
    testWidgets('C-1: all 43 services render, not the static table s 6',
        (WidgetTester tester) async {
      // "Rendering 6 is a Tier 1 structural-parity failure." The static
      // `SERVICES` table in the port source has 43 rows but the six *phase-1*
      // ones are the ones with routes, and a port that read the seed table
      // instead of the API is the mistake this pins.
      final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
      bloc.add(const ServiceStarted());
      await pumpServicePage(tester, bloc);
      await settleCatalogue(tester);

      bloc.add(const ServiceCategorySelected(null));
      await tester.enterText(find.byType(TextField), 'a');
      await settleCatalogue(tester);

      expect(find.byType(ServiceCard), findsNWidgets(43));
    });

    testWidgets('C-4: tapping a service with no client route is a NO-OP',
        (WidgetTester tester) async {
      final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
      repository.nextServices = recordedServicesIn('civil');
      bloc.add(const ServiceStarted());
      await pumpServicePage(tester, bloc);
      await settleCatalogue(tester);
      bloc.add(const ServiceCategorySelected('civil'));
      await settleCatalogue(tester);

      // `resident` DOES carry `route_path: /service/resident-certificate`, and
      // it is still a no-op, because this build mounts no such route. That is
      // the whole of C-3: the API's `route_path` is not the authority.
      expect(
        recordedServicesIn('civil').first.routePath,
        '/service/resident-certificate',
      );

      await tester.tap(find.byType(ServiceCard).first);
      await tester.pump();

      // No navigation, no exception, no visible change. `tester.takeException`
      // is the assertion that matters: `GoRouter.of(context)` would throw here
      // (there is no router in this tree), so a tap that tried to navigate
      // would be loud rather than silent.
      expect(tester.takeException(), isNull);
      expect(find.byType(ServiceCard), findsNWidgets(13));
    });

    testWidgets('C-4: it navigates once the client mounts the route',
        (WidgetTester tester) async {
      // The other half. Without this the no-op above is indistinguishable from
      // a tap handler that was never wired up.
      final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
      repository.nextServices = recordedServicesIn('civil');
      bloc.add(const ServiceStarted());

      String? navigatedTo;
      await pumpServicePage(
        tester,
        bloc,
        page: ServicePage(
          availability: const ServiceAvailability(
            registeredRoutes: <String>{'/service/resident-certificate'},
          ),
        ),
      );
      await settleCatalogue(tester);
      bloc.add(const ServiceCategorySelected('civil'));
      await settleCatalogue(tester);

      // The page calls `GoRouter.of(context).go(...)`; with no router that
      // throws, and the throw IS the observation that the destination resolved.
      await tester.tap(find.byType(ServiceCard).first);
      await tester.pump();
      final Object? thrown = tester.takeException();

      navigatedTo = thrown?.toString();
      expect(navigatedTo, isNotNull,
          reason: 'with a destination resolved, the page must attempt to '
              'navigate — a silent tap here would mean C-4 is unreachable '
              'forever and F1 would have to rediscover the wiring');
    });

    testWidgets('C-3: nothing in the feature gates on route_path',
        (WidgetTester tester) async {
      // A service with route_path stripped renders identically. If anything
      // branched on it, the card would change or vanish.
      final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
      final List<Service> stripped = recordedServicesIn('civil')
          .map((Service s) => s.copyWith(routePath: ''))
          .toList(growable: false);
      repository.nextServices = stripped;
      bloc.add(const ServiceStarted());
      await pumpServicePage(tester, bloc);
      await settleCatalogue(tester);
      bloc.add(const ServiceCategorySelected('civil'));
      await settleCatalogue(tester);

      expect(find.byType(ServiceCard), findsNWidgets(13));
      expect(find.text('Residence Certificate'), findsOneWidget);
    });
  });

  group('B2-AC-35 — server order, no client re-sort, no active filter', () {
    testWidgets('cards render in the order the API returned them',
        (WidgetTester tester) async {
      final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
      // Reversed on the way in. A client-side sort would put them back.
      final List<Service> reversed =
          recordedServicesIn('civil').reversed.toList(growable: false);
      repository.nextServices = reversed;
      bloc.add(const ServiceStarted());
      await pumpServicePage(tester, bloc);
      await settleCatalogue(tester);
      bloc.add(const ServiceCategorySelected('civil'));
      await settleCatalogue(tester);

      final List<String> rendered = tester
          .widgetList<ServiceCard>(find.byType(ServiceCard))
          .map((ServiceCard c) => c.service.code)
          .toList(growable: false);

      expect(rendered, reversed.map((Service s) => s.code).toList());
      expect(rendered.first, 'village',
          reason: 'sort_order 42 first — the server said so');
    });

    testWidgets('an inactive row is still rendered', (WidgetTester tester) async {
      // SSD § 11.2 L-4 generalises: the web applies no `active` filter, so
      // neither does this. Every staging row is active today, which is exactly
      // why the rule needs a synthetic row to be testable at all.
      final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
      final List<Service> rows = <Service>[
        recordedServicesIn('civil').first.copyWith(active: false),
      ];
      repository.nextServices = rows;
      bloc.add(const ServiceStarted());
      await pumpServicePage(tester, bloc);
      await settleCatalogue(tester);
      bloc.add(const ServiceCategorySelected('civil'));
      await settleCatalogue(tester);

      expect(find.byType(ServiceCard), findsOneWidget);
    });

    testWidgets('the filters go to the API, not to a client-side where()',
        (WidgetTester tester) async {
      final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
      bloc.add(const ServiceStarted());
      await pumpServicePage(tester, bloc);
      await settleCatalogue(tester);

      bloc.add(const ServiceCategorySelected('civil'));
      await settleCatalogue(tester);
      await tester.enterText(find.byType(TextField), 'cert');
      await settleCatalogue(tester);

      // The mount call carries neither filter; the drill-down carries the
      // category; the search carries both.
      expect(repository.serviceCalls.first,
          (search: null, category: null));
      expect(repository.serviceCalls, contains((search: null, category: 'civil')));
      expect(repository.serviceCalls.last,
          (search: 'cert', category: 'civil'));
    });

    testWidgets('the search is debounced, not fired per keystroke',
        (WidgetTester tester) async {
      final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
      bloc.add(const ServiceStarted());
      await pumpServicePage(tester, bloc);
      await settleCatalogue(tester);
      bloc.add(const ServiceCategorySelected('civil'));
      await settleCatalogue(tester);

      final int before = repository.serviceCalls.length;

      // Four keystrokes inside one 300 ms window.
      for (final String q in <String>['c', 'ce', 'cer', 'cert']) {
        await tester.enterText(find.byType(TextField), q);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await settleCatalogue(tester);

      expect(repository.serviceCalls.length - before, 1,
          reason: 'useDebounced(query, 300) — one request per settled query, '
              'not one per keypress. Four here would be four round trips on '
              'every word a citizen types.');
      expect(repository.serviceCalls.last.search, 'cert');
    });
  });

  group('B2-AC-15 — Lao at list scale', () {
    testWidgets('43 service names and 8 category names render Lao, zero tofu',
        (WidgetTester tester) async {
      final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
      bloc.add(const ServiceStarted());
      await pumpServicePage(tester, bloc, locale: const Locale('lo'));
      await settleCatalogue(tester);

      // Every category name is the Lao side, and every one contains Lao
      // script. "Zero tofu" in a headless test is not a pixel claim — the
      // renderer substitutes rather than drawing boxes — so what is asserted is
      // the two things that CAN be false here: that Lao text reached the
      // widget at all (rather than the English fallback), and that the family
      // the theme resolves is the one with Lao coverage. The glyph rendering
      // itself is Tier 3's, against the Lao baseline PNG.
      final RegExp lao = RegExp(r'[຀-໿]');
      for (final ServiceCategory c in recordedCategories()) {
        expect(c.name.lo, matches(lao));
        expect(find.text(c.name.lo), findsOneWidget);
      }

      bloc.add(const ServiceCategorySelected(null));
      await tester.enterText(find.byType(TextField), 'a');
      await settleCatalogue(tester);

      for (final Service s in recordedServices()) {
        expect(s.name.lo, matches(lao),
            reason: '${s.code} has no Lao name in the recorded catalogue');
        expect(find.text(s.name.lo), findsWidgets);
      }
    });

    testWidgets('neither locale clips or overflows, and Lao is not truncated',
        (WidgetTester tester) async {
      // ## What this test can and cannot say, stated rather than implied
      //
      // B2-AC-15 has two halves: (a) Lao renders with zero tofu and is not
      // clipped, and (b) the Lao page is *taller* than the English one. The
      // criterion itself says the evidence is "widget tests **plus the Tier 3
      // pair**", and this is why the split exists.
      //
      // (a) is testable here and is tested below: an overflow is a thrown
      //     `FlutterError` in a widget test, so "neither clips" is a real
      //     assertion with teeth.
      //
      // (b) is NOT testable here. Measured during this batch: the catalogue
      //     grid lays out to **820.0 px in both locales**, header 181.0 in
      //     both, whole column 1094.0 in both — with the real `NotoSansLao`
      //     faces loaded via `FontLoader`. Headless layout is not reproducing
      //     the per-locale wrap difference the browser shows (baseline: 1491
      //     lo vs 1404 en). Asserting `lo > en` here would therefore fail for a
      //     reason that has nothing to do with the port, and *weakening* it to
      //     `lo >= en` would be a green tick over an unmeasured claim — which
      //     is the failure mode CLAUDE.md § Gate Status Reporting exists to
      //     prevent. The height relation is carried to Tier 3 against the
      //     locale-matching baseline PNG and reported there.
      await loadNotoSansLao();

      for (final Locale locale in <Locale>[Locale('en'), Locale('lo')]) {
        final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
        bloc.add(const ServiceStarted());
        await pumpServicePage(tester, bloc, locale: locale);
        await settleCatalogue(tester);

        expect(tester.takeException(), isNull,
            reason: 'a RenderFlex overflow in ${locale.languageCode} is an '
                'exception, and it is the exact failure mode a taller locale '
                'produces against a layout built for the shorter one');

        // Not clipped: the scrollable content is taller than the viewport and
        // is reachable, rather than being cut to fit.
        final Size column = tester.getSize(
          find
              .descendant(
                of: find.byType(SingleChildScrollView),
                matching: find.byType(Column),
              )
              .first,
        );
        expect(column.height, greaterThan(600),
            reason: 'an 8-card grid that fits in one viewport has been '
                'collapsed, not laid out');

        // Every card is present rather than dropped by an overflow.
        expect(find.byType(CategoryCard), findsNWidgets(8));
      }
    });
  });
}

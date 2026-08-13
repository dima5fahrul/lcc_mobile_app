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
/// | font chain | **GOR-246 AC-24** — coverage at the `cmap`, with a negative control |
/// | four states | **B2-AC-16** — loading · data · empty (stubbed) · error-with-retry |
/// | C-1 / C-3 / C-4 | **B2-AC-34** — 43 render, no `route_path` gating, dead tap |
/// | server order | **B2-AC-35** — no client re-sort, no `active` filter |
/// | Lao at scale | **B2-AC-15** — 43 names + 8 categories, zero tofu, taller |
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service_category.dart';
import 'package:lcc_mobile_app/features/service/domain/service_availability.dart';
import 'package:lcc_mobile_app/features/service/presentation/bloc/service_bloc.dart';
import 'package:lcc_mobile_app/features/service/presentation/pages/service_page.dart';
import 'package:lcc_mobile_app/features/service/presentation/widgets/catalogue_grid.dart';
import 'package:lcc_mobile_app/features/service/presentation/widgets/bilingual_text.dart';
import 'package:lcc_mobile_app/features/service/presentation/widgets/catalogue_panels.dart';
import 'package:lcc_mobile_app/features/service/presentation/widgets/category_card.dart';
import 'package:lcc_mobile_app/features/service/presentation/widgets/service_card.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';
import 'package:lcc_mobile_app/presentation/theme/app_typography.dart';

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

bool _isAsciiLetter(int c) =>
    (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A);

void main() {
  // ── AC-24, re-asserted against the chain ──────────────────────────────────
  //
  // **This group must stay first in the file.** `FontLoader` registrations are
  // process-global and cannot be undone, so the "before" half of the negative
  // control below can only be taken before any test in this file has loaded a
  // face. Moving this group down turns its `before` measurement into an
  // `after` one and the control stops controlling for anything.
  group('GOR-246 AC-24 — the resolved font chain, at the cmap and by '
      'measurement', () {
    // The three classes the page draws. Kept separate rather than merged
    // because the whole defect was that one class passed while two did not,
    // and a merged assertion would have reported that as a pass.
    const String kLatin = 'All Services';
    const String kDigits = '1234567890';
    const String kLao = 'ບໍລິການທັງໝົດ';
    const double kSize = 24;

    double widthOf(String text) {
      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: kSize,
            fontFamily: AppTypography.fontFamily,
            fontFamilyFallback: AppTypography.fontFamilyFallback,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      return painter.width;
    }

    testWidgets('negative control — every class measures differently once the '
        'chain is loaded', (WidgetTester tester) async {
      // ## Why this test exists, and why it is required evidence
      //
      // § 6 of the B2a architecture review, ruling on this criterion: *"A
      // criterion is not discharged by proving that a configuration value was
      // propagated. It must assert the capability that value was configured to
      // obtain. If the test would still pass with the underlying resource
      // empty, absent, or inert, it is not evidence for the criterion — it is
      // evidence for the wiring."*
      //
      // This is the instrument that satisfies that for a font. Before any face
      // is registered, `flutter_test` lays everything out in a placeholder
      // whose every glyph is exactly one em square — so a string of N
      // characters measures exactly `N * fontSize`, whatever the characters
      // are. That equality is a *fingerprint of absence*: it is what a missing
      // face looks like, and it is precisely what `bda76a1` shipped for Latin
      // and for ASCII digits without anyone noticing.
      //
      // Asserting the width *changes*, per class, is therefore the one
      // measurement that cannot pass against an empty, absent or inert face.

      // ── before ──
      expect(widthOf(kLatin), kLatin.length * kSize,
          reason: 'precondition: no face is registered yet, so Latin must be '
              'the placeholder font. If this fails, the group has been '
              'reordered and the control below is measuring nothing.');
      expect(widthOf(kDigits), kDigits.length * kSize,
          reason: 'precondition: digits are the placeholder font too');
      final double laoBefore = widthOf(kLao);
      expect(laoBefore, kLao.length * kSize,
          reason: 'precondition: Lao is the placeholder font too');

      await loadAppFonts();

      // ── after ──
      // Each class must move. One moving was the old state of the world:
      // loading NotoSansLao alone changed Lao and left Latin and the digits at
      // the placeholder's `N * 24`, which is how a Lao-only subset passed a
      // criterion about the font being "actually applied".
      expect(widthOf(kLatin), isNot(kLatin.length * kSize),
          reason: 'Latin still measures at the placeholder font: the chain is '
              'not resolving Roboto, and AC-24 is FAIL exactly as it was at '
              'bda76a1');
      expect(widthOf(kDigits), isNot(kDigits.length * kSize),
          reason: 'ASCII digits still measure at the placeholder font. This is '
              'the class that hid the defect, because it appears in BOTH '
              'locales — the fee amounts and the `13 ບໍລິການ` counts');
      expect(widthOf(kLao), isNot(laoBefore),
          reason: 'Lao still measures at the placeholder font: the bundled '
              'face is not loading at all');
    });

    test('cmap — the chain covers every code point the page renders, digits '
        'included', () {
      // Coverage is read out of the files' `cmap` tables, never inferred from
      // a filename: `NotoSansLao-Regular.ttf` is named for a family whose
      // Google Fonts release *does* carry Latin, and the AOSP subset bundled
      // here does not. The name told us nothing.
      final Set<int> chain = appFontChainCoverage();

      // What the page actually draws, both locales, all nine states, taken
      // from the Tier 1 oracle. Plus the full ASCII digit class: the oracle
      // holds only the digits the recorded catalogue happens to produce, and a
      // catalogue that grows past 43 rows must not be able to introduce an
      // undrawable numeral.
      final Set<int> required = <int>{
        ...renderedCodePoints(),
        for (int c = 0x30; c <= 0x39; c++) c,
      };

      String describe(Iterable<int> cps) => (cps.toList()..sort())
          .map((int c) => 'U+${c.toRadixString(16).toUpperCase().padLeft(4, '0')}'
              ' ${String.fromCharCode(c)}')
          .join(', ');

      final Set<int> missing =
          required.where((int c) => !chain.contains(c)).toSet();
      expect(missing, isEmpty,
          reason: 'the resolved chain '
              '(${AppTypography.fontFamily} → '
              '${AppTypography.fontFamilyFallback.join(' → ')}) cannot draw '
              '${missing.length} code point(s) the page renders: '
              '${describe(missing)}');

      // Per class, so a future failure names what broke rather than dumping a
      // list. These are the classes § 6 enumerates.
      void classCovered(String name, Iterable<int> cps) {
        final Set<int> gap = cps.where((int c) => !chain.contains(c)).toSet();
        expect(gap, isEmpty, reason: '$name: ${describe(gap)}');
      }

      classCovered('ASCII uppercase', <int>[for (int c = 0x41; c <= 0x5A; c++) c]);
      classCovered('ASCII lowercase', <int>[for (int c = 0x61; c <= 0x7A; c++) c]);
      classCovered('ASCII digits', <int>[for (int c = 0x30; c <= 0x39; c++) c]);
      classCovered(
        'Lao (as rendered)',
        renderedCodePoints().where((int c) => c >= 0x0E80 && c <= 0x0EFF),
      );
      classCovered(
        'punctuation and marks (as rendered)',
        renderedCodePoints().where((int c) =>
            c < 0x0E80 && !(c >= 0x30 && c <= 0x39) && !_isAsciiLetter(c)),
      );
    });

    test('the assertion above is not vacuous — neither family alone suffices',
        () {
      // The reflexive application of the same rule. Without this, the coverage
      // test could be passing because the *union* happens to be large, and
      // would keep passing if `fontFamilyFallback` were deleted tomorrow —
      // which is the regression this whole finding is about.
      final Set<int> required = <int>{
        ...renderedCodePoints(),
        for (int c = 0x30; c <= 0x39; c++) c,
      };

      Set<int> coverageOf(List<File> faces) => faces
          .map(cmapCodePoints)
          .reduce((Set<int> a, Set<int> b) => a..addAll(b));

      final Set<int> laoOnly =
          coverageOf(kNotoSansLaoFaces.map(File.new).toList());
      final Set<int> robotoOnly = coverageOf(robotoFaceFiles());

      expect(required.where((int c) => !laoOnly.contains(c)), isNotEmpty,
          reason: 'NotoSansLao alone would cover the page, so the fallback is '
              'not load-bearing and this suite proves nothing about it');
      expect(required.where((int c) => !robotoOnly.contains(c)), isNotEmpty,
          reason: 'Roboto alone would cover the page, so the bundled Lao face '
              'is not load-bearing');
    });

    test('the chain reaches ThemeData — necessary, and NOT sufficient', () {
      // Recorded deliberately as the *weak* half. This is the assertion that
      // was AC-24's sole evidence at `bda76a1`, and on its own it passes
      // against an empty `.ttf`. It is kept because a chain that covers
      // everything and never reaches the theme is equally broken — but it is
      // named here so nobody re-promotes it to being the proof.
      final ThemeData theme = AppTheme.light();
      expect(theme.textTheme.bodyMedium?.fontFamily, AppTypography.fontFamily);
      expect(
        theme.textTheme.bodyMedium?.fontFamilyFallback,
        AppTypography.fontFamilyFallback,
      );
    });
  });

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
      // (b) is NOT asserted here — but **not** for the reason this comment
      //     used to give, and the correction matters more than the verdict.
      //
      //     The withdrawn text recorded grid 820.0 / header 181.0 / column
      //     1094.0, *identical in both locales*, and read that equality as
      //     "headless layout does not reproduce the per-locale wrap
      //     difference" — i.e. as an inherent limit of `flutter_test`. It is
      //     not. Those three numbers are **void as evidence**; do not cite
      //     them in either direction (ruled: B2a architecture review § 4).
      //     They were the product of two independent defects stacked:
      //
      //       1. only `NotoSansLao` was registered, so English laid out in the
      //          placeholder font and `en` was never a measurement of English
      //          typography at all; and
      //       2. **the `lo` iteration of this very loop was rendering English.**
      //          `pumpWidget` reuses the root element when the widget type is
      //          unchanged, so the second `EasyLocalization` never ran
      //          `initState` and never applied its `startLocale`. The loop
      //          compared `en` with `en` and reported the tie as a finding.
      //
      //     (2) is why the equality was *exact on all three metrics* — the
      //     anomaly § 4 flagged, since English in the placeholder font is
      //     ~1.0 em/glyph against real Lao at ~0.62 em and should have made
      //     `en` taller, not equal. Both are fixed below: the chain is loaded,
      //     and the tree is torn down between locales with an assertion that
      //     the switch actually happened. Re-derived with both fixed, the
      //     locales are **not** equal — column 1196.0 `en` vs 1238.0 `lo`.
      //
      //     The disposition nevertheless stands, for the reason § 2.4 of the
      //     ruling gives: the two locales resolve through *different faces*
      //     with different metrics, so "which render is taller" is a
      //     typography question settled against the locale-matching baseline
      //     PNG, never on a headless layout number. Asserting `lo > en` here
      //     would be a green tick on the right answer obtained from the wrong
      //     oracle — and this test has now been wrong once for exactly that
      //     shape of reason. Carried to Tier 3; B2-AC-15's height clause is
      //     released by B2-AC-27, not by this file.
      await loadAppFonts();

      for (final Locale locale in <Locale>[Locale('en'), Locale('lo')]) {
        // **Tear the tree down first.** Without this the second iteration
        // silently reuses the first locale — see (2) above. This one line is
        // the difference between testing two locales and testing one twice.
        await tester.pumpWidget(const SizedBox.shrink());

        final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
        bloc.add(const ServiceStarted());
        await pumpServicePage(tester, bloc, locale: locale);
        await settleCatalogue(tester);

        // And prove it took. A structural assertion is not enough on its own
        // here: every check below this point passes just as happily against
        // the wrong locale, which is precisely how the defect survived. This
        // is the § 6 rule turned on this test — assert the capability, not the
        // configuration.
        final ServiceCategory first = recordedCategories().first;
        expect(
          find.text(first.name.forLanguage(locale.languageCode)),
          findsOneWidget,
          reason: 'the tree is not rendering ${locale.languageCode}; the '
              'locale switch did not take and everything below is measuring '
              'the previous locale',
        );

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

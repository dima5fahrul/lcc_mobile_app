/// **Tier 1 — structural parity for `/`. B2-AC-8.**
///
/// § 6.5.1: *"APPLICABLE, blocking, 100 %. This is B2's principal gate. Per
/// page per locale: every element the web presents … exists in the Flutter page
/// with the same text in both locales."*
///
/// Runs the same way B2a's does — a Dart test against a versioned oracle, no
/// browser in the loop — using `text_dump.dart` and `oracle.dart` unchanged.
/// Two things differ, both forced by the page rather than chosen:
///
/// ## 1. It compares REGIONS, not one whole-page dump
///
/// `/service` is one non-lazy column, so B2a could dump the whole page.
/// `/` is a `ListView` containing two **horizontal** `ListView`s, and a lazy
/// viewport does not *build* the elements outside it — there is no widget to
/// find, and `skipOffstage: false` does not help because nothing is offstage
/// either. A whole-page dump would silently omit six of eight category slides
/// and report 100 % parity over the third of the page that happened to be in
/// frame, which is the shape of a gate that measures nothing.
///
/// So each region is dumped from its own subtree, scrolled into view where the
/// viewport requires it, and compared against its own oracle view. The union of
/// the regions is the page.
///
/// ## 2. Four regions are NOT EVALUATED, named, with reasons
///
/// Per CLAUDE.md § Gate Status Reporting — never omitted, never rounded up:
///
/// | Region | Why |
/// |---|---|
/// | `news.data` | `/news?per_page=3&featured=true` was never recorded (B2a captured `/services` and `/service-categories` only), and the card prints `formatDate(...)` — `test/fidelity/README.md`'s known limit 3 |
/// | `faq.data` | `/help/faqs?per_page=5` was never recorded |
/// | `summary.tiles` | `enabled: isAuthenticated`; the 2026-08-13 baseline is signed out and recording it needs a test citizen identity (F0, § 6.5.2(b)) |
/// | `digitalId.card` | same |
///
/// The last two are **B2-AC-33's** regions. Note the asymmetry the AC requires
/// and this file honours: Tier 3 is NOT EVALUATED for them because it needs an
/// image, while Tiers 1 and 2 *do* bind — and the parts of them that read
/// source rather than a payload (the card's labels, the masked specimen) are
/// gated below in `hero.signedOut`.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/home/domain/entities/home_faq_item.dart';
import 'package:lcc_mobile_app/features/home/domain/entities/home_news_item.dart';
import 'package:lcc_mobile_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:lcc_mobile_app/features/home/presentation/widgets/category_slider.dart';
import 'package:lcc_mobile_app/features/home/presentation/widgets/faq_accordion.dart';
import 'package:lcc_mobile_app/features/home/presentation/widgets/hero_header.dart';
import 'package:lcc_mobile_app/features/home/presentation/widgets/home_panels.dart';
import 'package:lcc_mobile_app/features/home/presentation/widgets/news_slider.dart';
import 'package:lcc_mobile_app/features/home/presentation/widgets/section_header.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';

import '../../../fidelity/oracle.dart';
import '../../../fidelity/text_dump.dart';
import '../../../helpers/home_test_helper.dart';

const List<Locale> kLocales = <Locale>[Locale('en'), Locale('lo')];

/// The four regions this instrument cannot reach, and the reason each is out
/// of reach. Asserted against the oracle's own `not_evaluated` block so the
/// list cannot quietly shrink on one side only.
const Set<String> kNotEvaluatedRegions = <String>{
  'news.data',
  'faq.data',
  'summary.tiles',
  'digitalId.card',
};

/// Compares [actual] against the oracle's [view], node for node, in order.
///
/// Lifted from `tier1_structural_parity_test.dart` so the two routes are judged
/// by the same comparison — including that **order is the point**: a set
/// comparison would pass a page that renders every right string in the wrong
/// place.
void expectParity(
  Map<String, dynamic> oracle,
  String view,
  List<DumpNode> actual, {
  required String locale,
}) {
  final List<OracleNode> expected = tier1View(oracle, view);
  final List<String> problems = <String>[];

  for (int i = 0; i < expected.length; i++) {
    final OracleNode want = expected[i];

    if (i >= actual.length) {
      problems.add(
        '[$i] MISSING "${want.text}" (${want.role}, from ${want.source})',
      );
      continue;
    }

    final DumpNode got = actual[i];

    if (got.text != want.text) {
      problems.add(
        '[$i] TEXT  web "${want.text}" vs flutter "${got.text}"'
        '  <- ${want.source}',
      );
      continue;
    }
    if (!rolesAreComparable(want.role, got.role)) {
      problems.add(
        '[$i] ROLE  "${want.text}" is ${want.role} on the web but '
        '${got.role} here  <- ${want.source}',
      );
      continue;
    }
    if (want.role == 'heading' && !got.heading) {
      problems.add(
        '[$i] HEADING "${want.text}" is an <h${want.level}> on the web and '
        'carries no Semantics(header: true) here  <- ${want.source}',
      );
    }
  }

  for (int i = expected.length; i < actual.length; i++) {
    problems.add('[$i] EXTRA "${actual[i].text}" (${actual[i].role}) — the '
        'web presents nothing here');
  }

  expect(
    problems,
    isEmpty,
    reason: 'Tier 1 is blocking at 100 % (B2-AC-8). Route /, locale '
        '$locale, view `$view`.\n'
        '  web     (${expected.length}): '
        '${expected.map((OracleNode n) => n.text).toList()}\n'
        '  flutter (${actual.length}): '
        '${actual.map((DumpNode n) => n.text).toList()}\n'
        'Problems:\n  ${problems.join('\n  ')}',
  );
}

void main() {
  late FakeHomeRepository repository;

  setUp(() => repository = FakeHomeRepository());

  HomeBloc build() {
    // Inside the test body, never `setUp` — `app_test_harness.dart`'s hazard 3.
    final HomeBloc bloc = homeBlocOver(repository);
    addTearDown(bloc.close);
    return bloc;
  }

  group('the oracle is the versioned one (B2-AC-29)', () {
    test('both locales exist and are pinned to the baseline commit', () {
      for (final Locale locale in kLocales) {
        final Map<String, dynamic> oracle =
            loadTier1('home', locale.languageCode);
        final Map<String, dynamic> provenance =
            oracle['provenance'] as Map<String, dynamic>;

        expect(oracle['route'], '/');
        expect(oracle['locale'], locale.languageCode);
        expect(provenance['web_commit'], kWebCommit,
            reason: '§ 8.3: an oracle derived from a different web commit is '
                'a re-baseline, and B2b may not perform one.');
        expect(provenance['derived_by'],
            'test/fidelity/derive_home_oracle.py');
      }
    });

    test('the NOT EVALUATED regions are named in the oracle itself', () {
      // Excluding something from a blocking gate is the move that should be
      // hardest to do quietly, so the exclusion carries assertions rather than
      // being an absence — the same discipline `tier2_token_parity_test.dart`
      // applies to its one excluded token.
      final Map<String, dynamic> notEvaluated =
          ((loadTier1('home', 'en')['provenance'] as Map<String, dynamic>)[
              'not_evaluated'] as Map<String, dynamic>);

      expect(notEvaluated.keys.toSet(), kNotEvaluatedRegions);
      for (final MapEntry<String, dynamic> e in notEvaluated.entries) {
        expect(e.value, isA<String>());
        expect((e.value as String).length, greaterThan(40),
            reason: '${e.key} needs a reason, not a label');
      }
    });

    test('and the oracle carries no view for them — it does not guess', () {
      final Map<String, dynamic> views =
          loadTier1('home', 'en')['views'] as Map<String, dynamic>;
      for (final String region in kNotEvaluatedRegions) {
        expect(views.containsKey(region), isFalse,
            reason: 'an oracle for $region could only have been invented, and '
                'comparing the page against a fixture its own author wrote is '
                'worse than the gap');
      }
    });

    test('the api snapshot behind it is the measured catalogue', () {
      expect(recordedPhase1Services(), hasLength(6));
      expect(recordedCatalogue(), hasLength(43));
    });
  });

  for (final Locale locale in kLocales) {
    final String code = locale.languageCode;

    group('Tier 1 — / — $code', () {
      late Map<String, dynamic> oracle;

      setUp(() => oracle = loadTier1('home', code));

      testWidgets('hero.signedOut — the masked specimen card', (
        WidgetTester tester,
      ) async {
        final HomeBloc bloc = build()..add(const HomeStarted());
        await pumpHomePage(tester, bloc, locale: locale);
        await settleHome(tester);

        expectParity(
          oracle,
          'hero.signedOut',
          dumpText(tester, find.byType(HeroHeader)),
          locale: code,
        );
      });

      testWidgets('services.header — the title, the blurb and both chips', (
        WidgetTester tester,
      ) async {
        final HomeBloc bloc = build()..add(const HomeStarted());
        await pumpHomePage(tester, bloc, locale: locale);
        await settleHome(tester);

        // The header is not its own widget — it is the first four text nodes
        // of the services column — so it is sliced out of the page dump at the
        // search placeholder, which is the last node the hero contributes.
        // Slicing rather than adding a wrapper widget: the wrapper would exist
        // only to be found by a test, which is a shape the page does not
        // otherwise need.
        expectParity(
          oracle,
          'services.header',
          _servicesHeaderNodes(tester),
          locale: code,
        );
      });

      testWidgets('services.data — six recorded cards plus the More tile', (
        WidgetTester tester,
      ) async {
        final HomeBloc bloc = build()..add(const HomeStarted());
        await pumpHomePage(tester, bloc, locale: locale);
        await settleHome(tester);

        expectParity(
          oracle,
          'services.data',
          _servicesGridNodes(tester),
          locale: code,
        );
      });

      testWidgets('services.empty — stubbed, because staging never is', (
        WidgetTester tester,
      ) async {
        repository.emptyEverything();
        final HomeBloc bloc = build()..add(const HomeStarted());
        await pumpHomePage(tester, bloc, locale: locale);
        await settleHome(tester);

        expectParity(
          oracle,
          'services.empty',
          _panelNodes(tester, 0),
          locale: code,
        );
      });

      testWidgets('services.error — with its retry', (
        WidgetTester tester,
      ) async {
        repository.failEverything();
        final HomeBloc bloc = build()..add(const HomeStarted());
        await pumpHomePage(tester, bloc, locale: locale);
        await settleHome(tester);

        expectParity(
          oracle,
          'services.error',
          dumpText(tester, find.byType(HomeErrorNotice).first),
          locale: code,
        );
      });

      testWidgets('search.empty — echoes nothing, offers no way back', (
        WidgetTester tester,
      ) async {
        final HomeBloc bloc = build()..add(const HomeStarted());
        await pumpHomePage(tester, bloc, locale: locale);
        await settleHome(tester);

        repository.search = const Right<Failure, List<Service>>(<Service>[]);
        await tester.enterText(find.byType(TextField), 'zzzz');
        await settleHome(tester);

        expectParity(
          oracle,
          'search.empty',
          _panelNodes(tester, 0),
          locale: code,
        );
      });

      testWidgets('the three section headers', (WidgetTester tester) async {
        final HomeBloc bloc = build()..add(const HomeStarted());
        await pumpHomePage(tester, bloc, locale: locale);
        await settleHome(tester);

        final Finder headers = find.byType(SectionHeader);
        expect(headers, findsNWidgets(3),
            reason: 'categories, news, FAQ — in that order down the page');

        expectParity(oracle, 'categories.header',
            dumpText(tester, headers.at(0)), locale: code);
        expectParity(oracle, 'news.header', dumpText(tester, headers.at(1)),
            locale: code);
        expectParity(oracle, 'faq.header', dumpText(tester, headers.at(2)),
            locale: code);
      });

      testWidgets('all eight category slides — scrolled, not sampled', (
        WidgetTester tester,
      ) async {
        // The lazy-viewport problem this file's doc describes. Each slide is
        // dragged into view and dumped; a test that read only what was in
        // frame would gate one slide and report eight.
        final HomeBloc bloc = build()..add(const HomeStarted());
        await pumpHomePage(tester, bloc, locale: locale);
        await settleHome(tester);

        final Finder strip = find.descendant(
          of: find.byType(CategorySlider),
          matching: find.byType(Scrollable),
        );

        for (final CategorySlide slide in kCategorySlides) {
          // `scrollUntilVisible` rather than a fixed drag per slide: the strip
          // uses `PageScrollPhysics`, so a drag of the slide *width* does not
          // advance exactly one slide once snapping is taken into account, and
          // a fixed-step loop silently desynchronises around the fifth card.
          await tester.scrollUntilVisible(
            find.text(slide.label(code)),
            280,
            scrollable: strip,
          );
          await settleHome(tester);

          final Finder card = find.text(slide.label(code));
          expect(card, findsWidgets,
              reason: 'slide ${slide.code} never came into view');

          expectParity(
            oracle,
            'categories.slide.${slide.code}',
            _slideNodes(tester, slide.label(code)),
            locale: code,
          );
        }
      });

      testWidgets('news.empty and news.error', (WidgetTester tester) async {
        repository.news = const Right<Failure, List<HomeNewsItem>>(
          <HomeNewsItem>[],
        );
        HomeBloc bloc = build()..add(const HomeStarted());
        await pumpHomePage(tester, bloc, locale: locale);
        await settleHome(tester);

        expectParity(oracle, 'news.empty', _panelNodes(tester, 0),
            locale: code);

        // Torn down between the two, per README known limit 2's warning about
        // reusing a root element.
        await tester.pumpWidget(const SizedBox());
        repository = FakeHomeRepository()
          ..news = const Left<Failure, List<HomeNewsItem>>(Failure('down'));
        bloc = homeBlocOver(repository);
        addTearDown(bloc.close);
        bloc.add(const HomeStarted());
        await pumpHomePage(tester, bloc, locale: locale);
        await settleHome(tester);

        expectParity(
          oracle,
          'news.error',
          dumpText(tester, find.byType(HomeErrorNotice).first),
          locale: code,
        );
      });

      testWidgets('faq.empty and faq.error', (WidgetTester tester) async {
        repository.faqs =
            const Right<Failure, List<HomeFaqItem>>(<HomeFaqItem>[]);
        HomeBloc bloc = build()..add(const HomeStarted());
        await pumpHomePage(tester, bloc, locale: locale);
        await settleHome(tester);

        expectParity(oracle, 'faq.empty', _panelNodes(tester, 0), locale: code);

        await tester.pumpWidget(const SizedBox());
        repository = FakeHomeRepository()
          ..faqs = const Left<Failure, List<HomeFaqItem>>(Failure('down'));
        bloc = homeBlocOver(repository);
        addTearDown(bloc.close);
        bloc.add(const HomeStarted());
        await pumpHomePage(tester, bloc, locale: locale);
        await settleHome(tester);

        expectParity(
          oracle,
          'faq.error',
          dumpText(tester, find.byType(HomeErrorNotice).first),
          locale: code,
        );
      });
    });
  }

  group('Tier 1 — the regions this instrument cannot reach', () {
    testWidgets('news.data and faq.data render, and are NOT EVALUATED', (
      WidgetTester tester,
    ) async {
      // The honest half of a NOT EVALUATED: prove the region exists and draws
      // its rows, so the verdict is "no oracle" rather than "no feature".
      final HomeBloc bloc = build()..add(const HomeStarted());
      await pumpHomePage(tester, bloc);
      await settleHome(tester);

      expect(find.byType(NewsSlider), findsOneWidget);
      expect(find.byType(FaqAccordion), findsOneWidget);
      expect(dumpText(tester, find.byType(NewsSlider)), isNotEmpty);
      expect(dumpText(tester, find.byType(FaqAccordion)), isNotEmpty);
    });

    testWidgets('summary.tiles and digitalId.card likewise', (
      WidgetTester tester,
    ) async {
      final HomeBloc bloc = build()..add(const HomeStarted());
      await pumpHomePage(
        tester,
        bloc,
        session: FakeSessionBloc(authenticated: true),
      );
      await settleHome(tester);

      // They render — B2-AC-33's "Tiers 1 and 2 still PASS for them" is
      // discharged for the parts that read source (the card's labels, gated in
      // `hero.signedOut`); the parts that read an unrecorded payload are what
      // is NOT EVALUATED.
      expect(find.text('Active applications'), findsOneWidget);
      expect(find.text('145,000 LAK'), findsOneWidget);
    });
  });
}

/// The services section's header, sliced out of the page.
List<DumpNode> _servicesHeaderNodes(WidgetTester tester) {
  final List<DumpNode> all = dumpText(tester, find.byType(Scaffold));
  final int start =
      all.indexWhere((DumpNode n) => n.role == 'placeholder') + 1;
  return all.sublist(start, start + 4);
}

/// The quick-actions grid: everything between the chips and the first section
/// header.
List<DumpNode> _servicesGridNodes(WidgetTester tester) {
  final List<DumpNode> all = dumpText(tester, find.byType(Scaffold));
  final int start =
      all.indexWhere((DumpNode n) => n.role == 'placeholder') + 5;
  final int end = all.indexWhere(
    (DumpNode n) => n.heading && n.role == 'text',
    start,
  );
  return all.sublist(start, end == -1 ? all.length : end);
}

/// One empty/error panel by index.
List<DumpNode> _panelNodes(WidgetTester tester, int index) {
  final Finder empties = find.byType(HomeEmptyNotice);
  if (empties.evaluate().isNotEmpty) {
    return dumpText(tester, empties.at(index));
  }
  return dumpText(tester, find.byType(HomeErrorNotice).at(index));
}

/// One category slide, found by its heading and dumped from its card.
List<DumpNode> _slideNodes(WidgetTester tester, String label) {
  return dumpText(
    tester,
    find
        .ancestor(of: find.text(label).first, matching: find.byType(Stack))
        .first,
  );
}

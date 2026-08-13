/// **Tier 1 — structural parity for `/news` and `/news/:slug`. B2-AC-8.**
///
/// § 6.5.1: *"APPLICABLE, blocking, 100 %. This is B2's principal gate. Per
/// page per locale: every element the web presents … exists in the Flutter page
/// with the same text in both locales."*
///
/// A Dart test against a versioned oracle, no browser in the loop, using
/// `test/fidelity/{oracle,text_dump}.dart` unchanged.
///
/// ## It compares REGIONS, for B2b's reason
///
/// Both pages are `ListView`s, and a lazy viewport does not *build* the
/// elements outside it — a whole-page dump would silently omit the cards below
/// the fold and report 100 % parity over the third of the page that happened to
/// be in frame. So each region is dumped from its own subtree and compared
/// against its own oracle view; the union of the regions is the page.
///
/// ## `list.data` is dumped card by card, and that is not a shortcut
///
/// The oracle builds it by concatenating five nodes per article in the source's
/// order, so the test concatenates per-card dumps the same way. A single dump
/// of the enclosing column would additionally depend on which cards the
/// viewport chose to build — the exact non-determinism this file exists to
/// avoid.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/news/domain/entities/news_article.dart';
import 'package:lcc_mobile_app/features/news/domain/repositories/news_page_result.dart';
import 'package:lcc_mobile_app/features/news/presentation/bloc/news_bloc.dart';
import 'package:lcc_mobile_app/features/news/presentation/bloc/news_detail_bloc.dart';
import 'package:lcc_mobile_app/features/news/presentation/widgets/more_news_card.dart';
import 'package:lcc_mobile_app/features/news/presentation/widgets/news_article_card.dart';
import 'package:lcc_mobile_app/features/news/presentation/widgets/news_category_chips.dart';
import 'package:lcc_mobile_app/features/news/presentation/widgets/news_header.dart';
import 'package:lcc_mobile_app/features/news/presentation/widgets/news_sub_header.dart';

import '../../../fidelity/oracle.dart';
import '../../../fidelity/text_dump.dart';
import '../../../helpers/news_test_helper.dart';

const List<Locale> kLocales = <Locale>[Locale('en'), Locale('lo')];

/// Compares [actual] against the oracle's [view], node for node, in order.
///
/// Lifted from `tier1_structural_parity_test.dart` so every route is judged by
/// the same comparison — including that **order is the point**: a set
/// comparison would pass a page that renders every right string in the wrong
/// place.
void expectParity(
  Map<String, dynamic> oracle,
  String view,
  List<DumpNode> actual, {
  required String route,
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
    reason: 'Tier 1 is blocking at 100 % (B2-AC-8). Route $route, locale '
        '$locale, view `$view`.\n'
        '  web     (${expected.length}): '
        '${expected.map((OracleNode n) => n.text).toList()}\n'
        '  flutter (${actual.length}): '
        '${actual.map((DumpNode n) => n.text).toList()}\n'
        'Problems:\n  ${problems.join('\n  ')}',
  );
}

/// Concatenates a per-instance dump of every widget of type [T], in tree order.
List<DumpNode> dumpEach<T extends Widget>(WidgetTester tester) {
  final Finder finder = find.byType(T);
  final List<DumpNode> nodes = <DumpNode>[];
  for (int i = 0; i < finder.evaluate().length; i++) {
    nodes.addAll(dumpText(tester, finder.at(i)));
  }
  return nodes;
}

void main() {
  group('the oracles are the versioned artefacts, pinned to 62f8a529', () {
    for (final String route in <String>['news', 'news-detail']) {
      for (final Locale locale in kLocales) {
        test('$route.${locale.languageCode} carries the commit', () {
          final Map<String, dynamic> oracle =
              loadTier1(route, locale.languageCode);
          final Map<String, dynamic> provenance =
              oracle['provenance'] as Map<String, dynamic>;

          expect(provenance['web_commit'], kWebCommit);
          expect(provenance['dates_from'], contains('Intl'),
              reason: 'the dates must come from ICU, not from a month table '
                  'copied out of news_formatting.dart — otherwise Tier 1 '
                  'compares the port against a transcription of itself');
        });
      }
    }
  });

  // ── /news ──────────────────────────────────────────────────────────────────

  for (final Locale locale in kLocales) {
    final String lang = locale.languageCode;

    group('Tier 1 — /news — $lang', () {
      late Map<String, dynamic> oracle;

      setUp(() => oracle = loadTier1('news', lang));

      /// The subject, built **inside the test body**.
      ///
      /// Not in `setUp`, and that is load-bearing rather than stylistic:
      /// `setUp` runs outside `testWidgets`' `FakeAsync` zone, so a BLoC
      /// constructed there owns an event queue whose microtasks `tester.pump()`
      /// never drains. The page then sits on `RegionStatus.initial` forever and
      /// every dump below finds a skeleton — which is exactly how this file
      /// failed on its first run. `app_test_harness.dart` records the same
      /// hazard for `bootHarness`.
      ({FakeNewsRepository repository, NewsBloc bloc}) subject() {
        final FakeNewsRepository repository = FakeNewsRepository();
        final NewsBloc bloc = newsBlocOver(repository);
        addTearDown(bloc.close);
        return (repository: repository, bloc: bloc);
      }

      testWidgets('header', (WidgetTester tester) async {
        final (:FakeNewsRepository repository, :NewsBloc bloc) = subject();
        await pumpNewsPage(tester, bloc, locale: locale);
        bloc.add(const NewsStarted());
        await settleNews(tester);

        expectParity(oracle, 'header', dumpText(tester, find.byType(NewsHeader)),
            route: '/news', locale: lang);
      });

      testWidgets('chips.data — All plus the four recorded categories',
          (WidgetTester tester) async {
        final (:FakeNewsRepository repository, :NewsBloc bloc) = subject();
        await pumpNewsPage(tester, bloc, locale: locale);
        bloc.add(const NewsStarted());
        await settleNews(tester);

        expectParity(
          oracle,
          'chips.data',
          dumpText(tester, find.byType(NewsCategoryChips)),
          route: '/news',
          locale: lang,
        );
      });

      testWidgets('chips.empty — All alone', (WidgetTester tester) async {
        final (:FakeNewsRepository repository, :NewsBloc bloc) = subject();
        repository.emptyEverything();
        await pumpNewsPage(tester, bloc, locale: locale);
        bloc.add(const NewsStarted());
        await settleNews(tester);

        expectParity(
          oracle,
          'chips.empty',
          dumpText(tester, find.byType(NewsCategoryChips)),
          route: '/news',
          locale: lang,
        );
      });

      testWidgets('chips.error — the § 6.6 addition, recorded as one',
          (WidgetTester tester) async {
        final (:FakeNewsRepository repository, :NewsBloc bloc) = subject();
        repository.failEverything();
        await pumpNewsPage(tester, bloc, locale: locale);
        bloc.add(const NewsStarted());
        await settleNews(tester);

        // Presence rather than an ordered dump: the retry sits in a sibling of
        // the chips row, so there is no single subtree whose dump is the view.
        // Order is still gated where it can be — `chips.data` above.
        for (final OracleNode n in tier1View(oracle, 'chips.error')) {
          expect(find.text(n.text), findsWidgets,
              reason: '"${n.text}" (${n.role}) <- ${n.source}');
        }
      });

      testWidgets('list.data — six recorded articles, card by card',
          (WidgetTester tester) async {
        final (:FakeNewsRepository repository, :NewsBloc bloc) = subject();
        await pumpNewsPage(tester, bloc, locale: locale);
        bloc.add(const NewsStarted());
        await settleNews(tester);

        expect(find.byType(NewsArticleCard), findsNWidgets(6),
            reason: 'the recorded page has six rows; a lazy viewport that '
                'built fewer would make the dump below measure nothing');

        expectParity(oracle, 'list.data', dumpEach<NewsArticleCard>(tester),
            route: '/news', locale: lang);
      });

      testWidgets('list.empty', (WidgetTester tester) async {
        final (:FakeNewsRepository repository, :NewsBloc bloc) = subject();
        repository.emptyEverything();
        await pumpNewsPage(tester, bloc, locale: locale);
        bloc.add(const NewsStarted());
        await settleNews(tester);

        final List<OracleNode> want = tier1View(oracle, 'list.empty');
        expect(find.text(want.single.text), findsOneWidget);
      });

      testWidgets('list.error — message plus Try again',
          (WidgetTester tester) async {
        final (:FakeNewsRepository repository, :NewsBloc bloc) = subject();
        // Only the LIST fails. `failEverything()` would fail the chips too, and
        // both error blocks render a "Try again" — so the assertion below would
        // find two and say nothing about which one belongs to the list. The two
        // regions failing independently is itself the behaviour under test.
        repository.articles = const Left<Failure, NewsPageResult>(
          Failure('stubbed list failure'),
        );
        await pumpNewsPage(tester, bloc, locale: locale);
        bloc.add(const NewsStarted());
        await settleNews(tester);

        // The chips survived their sibling's failure.
        expect(find.byType(NewsCategoryChips), findsOneWidget);

        for (final OracleNode n in tier1View(oracle, 'list.error')) {
          expect(find.text(n.text), findsOneWidget,
              reason: '"${n.text}" (${n.role}) <- ${n.source}');
        }
      });
    });
  }

  // ── /news/:slug ────────────────────────────────────────────────────────────

  for (final Locale locale in kLocales) {
    final String lang = locale.languageCode;

    group('Tier 1 — /news/:slug — $lang', () {
      late Map<String, dynamic> oracle;

      setUp(() => oracle = loadTier1('news-detail', lang));

      /// Built inside the test body — see the `/news` group's note on why
      /// `setUp` would leave the BLoC outside the `FakeAsync` zone.
      ({FakeNewsRepository repository, NewsDetailBloc bloc}) subject({
        Either<Failure, NewsArticle>? article,
      }) {
        final FakeNewsRepository repository = FakeNewsRepository();
        if (article != null) repository.article = article;
        final NewsDetailBloc bloc = newsDetailBlocOver(repository);
        addTearDown(bloc.close);
        return (repository: repository, bloc: bloc);
      }

      testWidgets('detail.data — the recorded article and its More news strip',
          (WidgetTester tester) async {
        final (repository: _, :NewsDetailBloc bloc) = subject();
        // One whole-page dump, not a set of regions: this page is a single
        // non-lazy column of prose and the reading order IS the assertion —
        // a title below its own body, or a "More news" heading above the
        // article, would pass every region-wise check.
        //
        // The surface is deliberately taller than the content so the `ListView`
        // builds every child; `findsNWidgets(3)` below is the tripwire that
        // says so rather than assuming it.
        await pumpNewsDetailPage(
          tester,
          bloc,
          locale: locale,
          surface: const Size(390, 6000),
        );
        bloc.add(const NewsDetailStarted());
        await settleNews(tester);

        expect(find.byType(MoreNewsCard), findsNWidgets(3),
            reason: '`.slice(0, 3)` over a 6-row catalogue minus this article');

        expectParity(
          oracle,
          'detail.data',
          dumpText(tester, find.byType(ListView).first),
          route: '/news/:slug',
          locale: lang,
        );
      });

      testWidgets('detail.missing — a 404 is the EMPTY render, with no retry',
          (WidgetTester tester) async {
        final (repository: _, :NewsDetailBloc bloc) =
            subject(article: notFound());
        await pumpNewsDetailPage(tester, bloc, locale: locale);
        bloc.add(const NewsDetailStarted());
        await settleNews(tester);

        for (final OracleNode n in tier1View(oracle, 'detail.missing')) {
          expect(find.text(n.text), findsOneWidget,
              reason: '"${n.text}" <- ${n.source}');
        }
        // The distinction the whole `NewsArticleNotFound` subtype exists for:
        // retrying a 404 cannot succeed, so there must be no Try again.
        final String retry =
            tier1View(oracle, 'detail.error')[1].text;
        expect(find.text(retry), findsNothing,
            reason: 'a missing article must not offer a retry (:117 vs :141)');
      });

      testWidgets('detail.error — message, Try again AND a way back',
          (WidgetTester tester) async {
        final (:FakeNewsRepository repository, :NewsDetailBloc bloc) =
            subject();
        repository.failEverything();
        await pumpNewsDetailPage(tester, bloc, locale: locale);
        bloc.add(const NewsDetailStarted());
        await settleNews(tester);

        for (final OracleNode n in tier1View(oracle, 'detail.error')) {
          expect(find.text(n.text), findsOneWidget,
              reason: '"${n.text}" <- ${n.source}');
        }
      });

      testWidgets('detail.loading — the chrome is up before the article is',
          (WidgetTester tester) async {
        final (:FakeNewsRepository repository, :NewsDetailBloc bloc) =
            subject();
        repository.latency = kNewsStubLatency;
        await pumpNewsDetailPage(tester, bloc, locale: locale);
        bloc.add(const NewsDetailStarted());
        await tester.pump();

        expectParity(
          oracle,
          'detail.loading',
          dumpText(tester, find.byType(NewsSubHeader)),
          route: '/news/:slug',
          locale: lang,
        );

        await settleNews(tester);
      });
    });
  }
}

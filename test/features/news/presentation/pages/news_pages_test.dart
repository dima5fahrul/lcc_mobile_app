/// `NewsPage` and `NewsDetailPage` as rendered surfaces.
///
/// Tier 1 already gates **what text** each state shows, against a versioned
/// oracle. This file gates the things a text dump cannot see:
///
/// * the four states are **distinguishable** — B2-AC-16 asks for that, not just
///   for four code paths;
/// * the controls do what they say (a chip filters, a card navigates, a retry
///   re-asks);
/// * B2-AC-15's Lao render — glyphs, no tofu, no overflow;
/// * no locator read from inside a widget (G-L5's premise, asserted rather than
///   assumed).
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
import 'package:lcc_mobile_app/features/news/presentation/widgets/news_pager.dart';
import 'package:lcc_mobile_app/features/news/presentation/widgets/news_panels.dart';

import '../../../../helpers/news_test_helper.dart';

void main() {
  group('/news — the four states are DISTINGUISHABLE (B2-AC-16)', () {
    testWidgets('loading is a skeleton, and not an empty list',
        (WidgetTester tester) async {
      final FakeNewsRepository repository = FakeNewsRepository()
        ..latency = kNewsStubLatency;
      final NewsBloc bloc = newsBlocOver(repository);
      addTearDown(bloc.close);

      await pumpNewsPage(tester, bloc);
      bloc.add(const NewsStarted());
      await tester.pump();

      expect(find.byType(NewsSkeleton), findsWidgets);
      expect(find.byType(NewsArticleCard), findsNothing);
      expect(find.byType(NewsEmptyBlock), findsNothing);
      expect(find.byType(NewsErrorBlock), findsNothing);

      await settleNews(tester);
    });

    testWidgets('data is six cards and no skeleton',
        (WidgetTester tester) async {
      final NewsBloc bloc = newsBlocOver(FakeNewsRepository());
      addTearDown(bloc.close);

      await pumpNewsPage(tester, bloc);
      bloc.add(const NewsStarted());
      await settleNews(tester);

      expect(find.byType(NewsArticleCard), findsNWidgets(6));
      expect(find.byType(NewsSkeleton), findsNothing);
      expect(find.byType(NewsEmptyBlock), findsNothing);
      expect(find.byType(NewsErrorBlock), findsNothing);
    });

    testWidgets('empty (stubbed) is the empty block, NOT an error',
        (WidgetTester tester) async {
      // § 6.6: `/news` returns 6 rows against staging, so the empty state will
      // not occur by accident and must be tested with a stubbed empty response.
      final FakeNewsRepository repository = FakeNewsRepository()
        ..emptyEverything();
      final NewsBloc bloc = newsBlocOver(repository);
      addTearDown(bloc.close);

      await pumpNewsPage(tester, bloc);
      bloc.add(const NewsStarted());
      await settleNews(tester);

      expect(find.byType(NewsEmptyBlock), findsOneWidget);
      expect(find.byType(NewsErrorBlock), findsNothing);
      expect(find.byType(NewsArticleCard), findsNothing);
    });

    testWidgets('error is the error block WITH a working retry',
        (WidgetTester tester) async {
      final FakeNewsRepository repository = FakeNewsRepository()
        ..articles = const Left<Failure, NewsPageResult>(Failure('boom'));
      final NewsBloc bloc = newsBlocOver(repository);
      addTearDown(bloc.close);

      await pumpNewsPage(tester, bloc);
      bloc.add(const NewsStarted());
      await settleNews(tester);

      expect(find.byType(NewsErrorBlock), findsOneWidget);
      expect(find.byType(NewsEmptyBlock), findsNothing);

      // B2-AC-16: "an empty list is never an acceptable rendering of a failed
      // fetch" — and a retry that does not re-ask is the same defect wearing a
      // button.
      final int before = repository.listCalls.length;
      repository.articles = Right<Failure, NewsPageResult>(recordedPage());
      await tester.tap(find.text('Try again'));
      await settleNews(tester);

      expect(repository.listCalls.length, before + 1);
      expect(find.byType(NewsArticleCard), findsNWidgets(6));
      expect(find.byType(NewsErrorBlock), findsNothing);
    });
  });

  group('/news — the controls', () {
    testWidgets('tapping a chip asks the server for that category',
        (WidgetTester tester) async {
      final FakeNewsRepository repository = FakeNewsRepository();
      final NewsBloc bloc = newsBlocOver(repository);
      addTearDown(bloc.close);

      await pumpNewsPage(tester, bloc);
      bloc.add(const NewsStarted());
      await settleNews(tester);

      // Scoped to the chip row: "Policy & law" is also the category badge on
      // two of the six cards, and an unscoped finder taps whichever the tree
      // happens to yield first.
      await tester.tap(find.descendant(
        of: find.byType(NewsCategoryChips),
        matching: find.text('Policy & law'),
      ));
      await settleNews(tester);

      expect(repository.listCalls.last.category, 'policy');
    });

    testWidgets('the pager is hidden on a single-page result',
        (WidgetTester tester) async {
      // 6 rows at per_page 6 — the state staging is actually in.
      final NewsBloc bloc = newsBlocOver(FakeNewsRepository());
      addTearDown(bloc.close);

      await pumpNewsPage(tester, bloc);
      bloc.add(const NewsStarted());
      await settleNews(tester);

      expect(find.byType(NewsPager), findsNothing);
    });

    testWidgets('the pager appears on a multi-page result and moves the query',
        (WidgetTester tester) async {
      final FakeNewsRepository repository = FakeNewsRepository()
        ..articles = Right<Failure, NewsPageResult>(
          pagedResult(page: 1, totalPages: 3),
        );
      final NewsBloc bloc = newsBlocOver(repository);
      addTearDown(bloc.close);

      await pumpNewsPage(tester, bloc, surface: const Size(390, 4000));
      bloc.add(const NewsStarted());
      await settleNews(tester);

      expect(find.byType(NewsPager), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Next page'));
      await settleNews(tester);

      expect(repository.listCalls.last.page, 2);
    });

    testWidgets('the previous control is DIMMED, not absent, on page 1',
        (WidgetTester tester) async {
      // `disabled:opacity-40` — the pager must not reflow when the citizen
      // reaches an end.
      final FakeNewsRepository repository = FakeNewsRepository()
        ..articles = Right<Failure, NewsPageResult>(
          pagedResult(page: 1, totalPages: 3),
        );
      final NewsBloc bloc = newsBlocOver(repository);
      addTearDown(bloc.close);

      await pumpNewsPage(tester, bloc, surface: const Size(390, 4000));
      bloc.add(const NewsStarted());
      await settleNews(tester);

      expect(find.bySemanticsLabel('Previous page'), findsOneWidget);

      final int before = repository.listCalls.length;
      await tester.tap(find.bySemanticsLabel('Previous page'));
      await settleNews(tester);

      expect(repository.listCalls.length, before,
          reason: 'the control is visible and inert, not visible and live');
    });
  });

  group('/news/:slug — the four states', () {
    testWidgets('loading shows the chrome and a skeleton hero',
        (WidgetTester tester) async {
      final FakeNewsRepository repository = FakeNewsRepository()
        ..latency = kNewsStubLatency;
      final NewsDetailBloc bloc = newsDetailBlocOver(repository);
      addTearDown(bloc.close);

      await pumpNewsDetailPage(tester, bloc);
      bloc.add(const NewsDetailStarted());
      await tester.pump();

      expect(find.byType(NewsSkeleton), findsWidgets);
      expect(find.byType(MoreNewsCard), findsNothing);

      await settleNews(tester);
    });

    testWidgets('data shows the article and three More cards',
        (WidgetTester tester) async {
      final NewsDetailBloc bloc = newsDetailBlocOver(FakeNewsRepository());
      addTearDown(bloc.close);

      await pumpNewsDetailPage(tester, bloc, surface: const Size(390, 6000));
      bloc.add(const NewsDetailStarted());
      await settleNews(tester);

      expect(find.text(recordedDetail().title.en), findsOneWidget);
      expect(find.byType(MoreNewsCard), findsNWidgets(3));
      expect(find.byType(NewsSkeleton), findsNothing);
    });

    testWidgets('a 404 offers a way back and NO retry',
        (WidgetTester tester) async {
      final FakeNewsRepository repository = FakeNewsRepository()
        ..article = notFound();
      final NewsDetailBloc bloc = newsDetailBlocOver(repository);
      addTearDown(bloc.close);

      await pumpNewsDetailPage(tester, bloc);
      bloc.add(const NewsDetailStarted());
      await settleNews(tester);

      expect(find.text('Back to news'), findsOneWidget);
      expect(find.text('Try again'), findsNothing,
          reason: 'retrying a 404 cannot succeed — NewsDetailPage.tsx:117');
    });

    testWidgets('any other failure offers BOTH a retry and a way back',
        (WidgetTester tester) async {
      final FakeNewsRepository repository = FakeNewsRepository()
        ..article = const Left<Failure, NewsArticle>(Failure('offline'));
      final NewsDetailBloc bloc = newsDetailBlocOver(repository);
      addTearDown(bloc.close);

      await pumpNewsDetailPage(tester, bloc);
      bloc.add(const NewsDetailStarted());
      await settleNews(tester);

      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Back to news'), findsOneWidget);

      repository.article = Right<Failure, NewsArticle>(recordedDetail());
      await tester.tap(find.text('Try again'));
      await settleNews(tester);

      expect(find.text(recordedDetail().title.en), findsOneWidget);
    });

    testWidgets('a failed catalogue costs the More strip and nothing else',
        (WidgetTester tester) async {
      final FakeNewsRepository repository = FakeNewsRepository()
        ..catalogue = const Left<Failure, List<NewsArticle>>(Failure('boom'));
      final NewsDetailBloc bloc = newsDetailBlocOver(repository);
      addTearDown(bloc.close);

      await pumpNewsDetailPage(tester, bloc, surface: const Size(390, 6000));
      bloc.add(const NewsDetailStarted());
      await settleNews(tester);

      expect(find.text(recordedDetail().title.en), findsOneWidget);
      expect(find.byType(MoreNewsCard), findsNothing);
      expect(find.text('More news'), findsNothing);
    });

    testWidgets('the paragraphs fall back to the excerpt when there is no body',
        (WidgetTester tester) async {
      // `paragraphs.length > 0 ? paragraphs : [excerpt]` — :228. Reachable
      // whenever the detail endpoint answers without a body.
      final NewsArticle bodiless = recordedArticles().first;
      final FakeNewsRepository repository = FakeNewsRepository()
        ..article = Right<Failure, NewsArticle>(bodiless);
      final NewsDetailBloc bloc = newsDetailBlocOver(repository);
      addTearDown(bloc.close);

      await pumpNewsDetailPage(tester, bloc, surface: const Size(390, 6000));
      bloc.add(const NewsDetailStarted());
      await settleNews(tester);

      expect(find.text(bodiless.excerpt.en), findsOneWidget);
    });
  });

  group('B2-AC-15 — the Lao render', () {
    testWidgets('/news renders Lao glyphs with no overflow',
        (WidgetTester tester) async {
      final NewsBloc bloc = newsBlocOver(FakeNewsRepository());
      addTearDown(bloc.close);

      await pumpNewsPage(tester, bloc, locale: const Locale('lo'));
      bloc.add(const NewsStarted());
      await settleNews(tester);

      // Lao copy on screen, from the dictionary AND from the API.
      expect(find.text('ທັງໝົດ'), findsOneWidget);
      expect(find.text(recordedArticles().first.title.lo), findsOneWidget);
      // A RenderFlex overflow raises during layout and `takeException` would
      // surface it; reaching here with none is the assertion. This is the check
      // that caught the help chips' 14 px overflow.
      expect(tester.takeException(), isNull);
    });

    testWidgets('/news/:slug renders Lao glyphs with no overflow',
        (WidgetTester tester) async {
      final NewsDetailBloc bloc = newsDetailBlocOver(FakeNewsRepository());
      addTearDown(bloc.close);

      await pumpNewsDetailPage(
        tester,
        bloc,
        locale: const Locale('lo'),
        surface: const Size(390, 6000),
      );
      bloc.add(const NewsDetailStarted());
      await settleNews(tester);

      expect(find.text(recordedDetail().title.lo), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the two locales lay out DIFFERENTLY, and neither clips',
        (WidgetTester tester) async {
      // § 6.5.6 rules that there is **no canonical page height per route** —
      // the baseline measures Lao taller on most routes and *shorter* on home.
      // Measured here: the first news card is 227 px in English and 211 px in
      // Lao, because the Lao excerpt wraps to fewer lines at 390 px.
      //
      // So this test does NOT assert a direction. `test/fidelity/README.md`
      // limit 2 says why: the two locales resolve through different faces with
      // different metrics, and "locale X is taller" is a typography question
      // settled against the locale-matching PNG, not a layout number a widget
      // test should assert.
      //
      // What it DOES assert is the pair that matters and that a direction
      // assertion would have masked: the two renders really are different (so
      // the second pump is not silently re-rendering the first locale — the
      // trap limit 2 documents), and neither overflows.
      final NewsBloc en = newsBlocOver(FakeNewsRepository());
      addTearDown(en.close);
      await pumpNewsPage(tester, en, surface: const Size(390, 6000));
      en.add(const NewsStarted());
      await settleNews(tester);
      final double enHeight =
          tester.getSize(find.byType(NewsArticleCard).first).height;

      // Tear the tree down between locales. `pumpWidget` reuses the root
      // element when the widget type is unchanged, so `EasyLocalization`'s
      // `initState` never re-runs and `startLocale` is silently ignored — the
      // trap `test/fidelity/README.md` limit 2 documents.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      final NewsBloc lo = newsBlocOver(FakeNewsRepository());
      addTearDown(lo.close);
      await pumpNewsPage(tester, lo,
          locale: const Locale('lo'), surface: const Size(390, 6000));
      lo.add(const NewsStarted());
      await settleNews(tester);

      // Assert the expected locale is actually on screen before measuring —
      // every other assertion in a locale loop passes just as happily against
      // the wrong one.
      expect(find.text('ທັງໝົດ'), findsOneWidget);
      final double loHeight =
          tester.getSize(find.byType(NewsArticleCard).first).height;

      expect(loHeight, isNot(enHeight),
          reason: 'identical heights would mean the Lao pump re-rendered the '
              'English tree — `pumpWidget` reuses the root element when the '
              'widget type is unchanged, so `EasyLocalization.initState` never '
              're-runs and `startLocale` is silently ignored');
      expect(tester.takeException(), isNull);
    });
  });

  group('G-L5 — the pages read no locator', () {
    testWidgets('both render under a BlocProvider alone, with no container',
        (WidgetTester tester) async {
      // The guard scans imports statically; this is the runtime counterpart.
      // These pumps never call `DependencyInjection.init()`, so a widget that
      // reached for `newsInjection` would throw rather than quietly work.
      final NewsBloc list = newsBlocOver(FakeNewsRepository());
      addTearDown(list.close);
      await pumpNewsPage(tester, list);
      list.add(const NewsStarted());
      await settleNews(tester);
      expect(find.byType(NewsCategoryChips), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      final NewsDetailBloc detail =
          newsDetailBlocOver(FakeNewsRepository());
      addTearDown(detail.close);
      await pumpNewsDetailPage(tester, detail);
      detail.add(const NewsDetailStarted());
      await settleNews(tester);
      expect(find.text(recordedDetail().title.en), findsOneWidget);
    });
  });
}

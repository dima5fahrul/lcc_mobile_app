/// `NewsBloc` and `NewsDetailBloc`.
///
/// The four states § 6.6 mandates are asserted as **state**, and the widget
/// tests assert them as pixels; both are needed, because a BLoC that reaches
/// `RegionStatus.success` with an empty list and a page that renders a spinner
/// for it are two different defects.
///
/// Every BLoC here is constructed **inside the test body**. `setUp` runs
/// outside `bloc_test`'s zone in the same way it runs outside `testWidgets`',
/// and the Tier 1 suite's first run is the record of what that costs.
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/news/domain/entities/news_article.dart';
import 'package:lcc_mobile_app/features/news/domain/entities/news_category.dart';
import 'package:lcc_mobile_app/features/news/domain/repositories/news_page_result.dart';
import 'package:lcc_mobile_app/features/news/domain/usecases/news_usecases.dart';
import 'package:lcc_mobile_app/features/news/presentation/bloc/news_bloc.dart';
import 'package:lcc_mobile_app/features/news/presentation/bloc/news_detail_bloc.dart';

import '../../../../helpers/news_test_helper.dart';

void main() {
  group('NewsBloc — mount', () {
    test('the initial state is INITIAL, which reads as loading', () async {
      final NewsBloc bloc = newsBlocOver(FakeNewsRepository());
      addTearDown(bloc.close);

      // `initial` is distinct from `loading` in the enum and equal to it in
      // the getter: the frame between `create:` and the handler running must
      // show a skeleton, not the empty state.
      expect(bloc.state.categoriesStatus, RegionStatus.initial);
      expect(bloc.state.listLoading, isTrue);
      expect(bloc.state.listEmpty, isFalse);
      expect(bloc.state.filter, kNewsAllCategories);
      expect(bloc.state.page, 1);
    });

    blocTest<NewsBloc, NewsState>(
      'NewsStarted fires BOTH reads and lands both regions on success',
      build: () => newsBlocOver(FakeNewsRepository()),
      act: (NewsBloc bloc) => bloc.add(const NewsStarted()),
      verify: (NewsBloc bloc) {
        expect(bloc.state.categoriesStatus, RegionStatus.success);
        expect(bloc.state.listStatus, RegionStatus.success);
        expect(bloc.state.categories, hasLength(4));
        expect(bloc.state.articles, hasLength(6));
      },
    );

    blocTest<NewsBloc, NewsState>(
      'the two regions fail independently — a failed chip row leaves the list',
      build: () {
        final FakeNewsRepository repository = FakeNewsRepository()
          ..categories = const Left<Failure, List<NewsCategory>>(
            Failure('stubbed categories failure'),
          );
        return newsBlocOver(repository);
      },
      act: (NewsBloc bloc) => bloc.add(const NewsStarted()),
      verify: (NewsBloc bloc) {
        expect(bloc.state.categoriesFailed, isTrue);
        expect(bloc.state.listStatus, RegionStatus.success);
      },
    );

    blocTest<NewsBloc, NewsState>(
      'an empty list is the EMPTY state, not a failure (B2-AC-16)',
      build: () {
        final FakeNewsRepository repository = FakeNewsRepository()
          ..emptyEverything();
        return newsBlocOver(repository);
      },
      act: (NewsBloc bloc) => bloc.add(const NewsStarted()),
      verify: (NewsBloc bloc) {
        expect(bloc.state.listEmpty, isTrue);
        expect(bloc.state.listFailed, isFalse);
        expect(bloc.state.listLoading, isFalse);
      },
    );
  });

  group('NewsBloc — the filter', () {
    test('picking a category sends its code and RESETS to page 1', () async {
      final FakeNewsRepository repository = FakeNewsRepository();
      final NewsBloc bloc = newsBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const NewsStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NewsNextPage());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NewsCategoryPicked('policy'));
      await Future<void>.delayed(Duration.zero);

      // `pick(c) { setFilter(c); setPage(1); }` — NewsPage.tsx:56-59. Keeping
      // the page would ask for page 2 of a one-page filter and render an empty
      // list that is not empty.
      expect(repository.listCalls.last.category, 'policy');
      expect(repository.listCalls.last.page, 1);
      expect(bloc.state.filter, 'policy');
    });

    test('"All" sends NULL, not the string "all"', () async {
      final FakeNewsRepository repository = FakeNewsRepository();
      final NewsBloc bloc = newsBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const NewsStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NewsCategoryPicked('policy'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NewsCategoryPicked(kNewsAllCategories));
      await Future<void>.delayed(Duration.zero);

      expect(repository.listCalls.first.category, isNull);
      expect(repository.listCalls.last.category, isNull,
          reason: '`?category=all` would filter to a category that does not '
              'exist and return an empty list that looks like a real one');
    });

    test('the chip looks selected before its list arrives', () async {
      final FakeNewsRepository repository = FakeNewsRepository()
        ..latency = const Duration(milliseconds: 50);
      final NewsBloc bloc = newsBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const NewsCategoryPicked('service'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.filter, 'service');
      expect(bloc.state.listLoading, isTrue);
    });
  });

  group('NewsBloc — the pager', () {
    test('next steps forward from the page the SERVER reported', () async {
      // The stub always answers "page 2 of 3", so the mount lands on 2 and
      // `NewsNextPage` asks for 3 — not for 2. That is the interesting
      // behaviour: the increment is applied to the server's number, not to a
      // client-side counter that could have drifted from it.
      final FakeNewsRepository repository = FakeNewsRepository()
        ..articles = Right<Failure, NewsPageResult>(
          pagedResult(page: 2, totalPages: 3),
        );
      final NewsBloc bloc = newsBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const NewsStarted());
      await Future<void>.delayed(Duration.zero);
      expect(repository.listCalls.first.page, 1);
      expect(bloc.state.page, 2);

      bloc.add(const NewsNextPage());
      await Future<void>.delayed(Duration.zero);

      expect(repository.listCalls.last.page, 3);
    });

    test('previous clamps at 1 — `Math.max(1, p - 1)`', () async {
      final FakeNewsRepository repository = FakeNewsRepository();
      final NewsBloc bloc = newsBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const NewsStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NewsPreviousPage());
      await Future<void>.delayed(Duration.zero);

      expect(repository.listCalls.last.page, 1);
      expect(repository.listCalls.last.page, isNot(0));
    });

    test('the SERVER is the authority on which page was served', () async {
      // A client increment past the end comes back clamped; taking the
      // response's number keeps the `2 / 2` readout honest.
      final FakeNewsRepository repository = FakeNewsRepository()
        ..articles = Right<Failure, NewsPageResult>(
          pagedResult(page: 2, totalPages: 2),
        );
      final NewsBloc bloc = newsBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const NewsStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NewsNextPage());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NewsNextPage());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.page, 2);
    });

    test('the pager is hidden while loading and while failed', () async {
      final FakeNewsRepository repository = FakeNewsRepository()
        ..articles = Right<Failure, NewsPageResult>(
          pagedResult(page: 1, totalPages: 3),
        );
      final NewsBloc bloc = newsBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const NewsStarted());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.showPager, isTrue);

      repository.articles =
          const Left<Failure, NewsPageResult>(Failure('boom'));
      bloc.add(const NewsListRetried());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.showPager, isFalse,
          reason: '`meta && total_pages > 1 && !loading && !error` — all four '
              'conditions, NewsPage.tsx:205');
    });
  });

  group('NewsBloc — retries', () {
    test('a chip retry re-asks for the categories and nothing else', () async {
      final FakeNewsRepository repository = FakeNewsRepository();
      final NewsBloc bloc = newsBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const NewsStarted());
      await Future<void>.delayed(Duration.zero);
      final int listCalls = repository.listCalls.length;

      bloc.add(const NewsCategoriesRetried());
      await Future<void>.delayed(Duration.zero);

      expect(repository.categoryCalls, 2);
      expect(repository.listCalls, hasLength(listCalls));
    });

    test('a list retry keeps the current filter and page', () async {
      final FakeNewsRepository repository = FakeNewsRepository()
        ..articles = Right<Failure, NewsPageResult>(
          pagedResult(page: 2, totalPages: 3),
        );
      final NewsBloc bloc = newsBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const NewsCategoryPicked('policy'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NewsListRetried());
      await Future<void>.delayed(Duration.zero);

      expect(repository.listCalls.last.category, 'policy');
      expect(repository.listCalls.last.page, 2,
          reason: 'the server said page 2; a retry that reset to 1 would move '
              'the citizen without being asked');
    });
  });

  group('NewsDetailBloc', () {
    test('it asks for the slug the ROUTE gave it', () async {
      final FakeNewsRepository repository = FakeNewsRepository();
      final NewsDetailBloc bloc =
          newsDetailBlocOver(repository, slug: 'some-other-slug');
      addTearDown(bloc.close);

      bloc.add(const NewsDetailStarted());
      await Future<void>.delayed(Duration.zero);

      expect(repository.articleSlugs, <String>['some-other-slug']);
    });

    test('the article and the catalogue are fetched CONCURRENTLY', () async {
      // The web waits on the catalogue to resolve the slug; the Flutter route
      // carries it, so the catalogue only fills "More news" and must not gate
      // the article. Both calls landing before either resolves is the check.
      final FakeNewsRepository repository = FakeNewsRepository()
        ..latency = const Duration(milliseconds: 50);
      final NewsDetailBloc bloc = newsDetailBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const NewsDetailStarted());
      await Future<void>.delayed(Duration.zero);

      expect(repository.articleSlugs, hasLength(1));
      expect(repository.catalogueCalls, 1);
    });

    test('More news excludes THIS article and takes at most three', () async {
      final FakeNewsRepository repository = FakeNewsRepository();
      final NewsDetailBloc bloc = newsDetailBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const NewsDetailStarted());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.more, hasLength(kNewsMoreCount));
      expect(
        bloc.state.more.map((NewsArticle a) => a.slug),
        isNot(contains(kRecordedSlug)),
      );
    });

    test('a 404 is the MISSING state, not the failed one', () async {
      final FakeNewsRepository repository = FakeNewsRepository()
        ..article = notFound();
      final NewsDetailBloc bloc = newsDetailBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const NewsDetailStarted());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.notFound, isTrue);
      expect(bloc.state.missing, isTrue);
      expect(bloc.state.failed, isFalse,
          reason: 'NewsDetailPage.tsx:117 — `loadError && !loadError.isNotFound`');
    });

    test('any other failure is the FAILED state', () async {
      final FakeNewsRepository repository = FakeNewsRepository()
        ..article = const Left<Failure, NewsArticle>(Failure('offline'));
      final NewsDetailBloc bloc = newsDetailBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const NewsDetailStarted());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.failed, isTrue);
      expect(bloc.state.missing, isFalse);
    });

    test('a failed catalogue costs the More strip and nothing else', () async {
      final FakeNewsRepository repository = FakeNewsRepository()
        ..catalogue = const Left<Failure, List<NewsArticle>>(Failure('boom'));
      final NewsDetailBloc bloc = newsDetailBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const NewsDetailStarted());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.status, RegionStatus.success);
      expect(bloc.state.article, isNotNull);
      expect(bloc.state.showMore, isFalse);
    });

    test('an empty slug never reaches the wire', () async {
      // `GET /news/` is `GET /news`, which answers 200 with the LIST envelope
      // and would parse into a blank article.
      final FakeNewsRepository repository = FakeNewsRepository();
      final NewsDetailBloc bloc = newsDetailBlocOver(repository, slug: '');
      addTearDown(bloc.close);

      bloc.add(const NewsDetailStarted());
      await Future<void>.delayed(Duration.zero);

      expect(repository.articleSlugs, isEmpty);
      expect(bloc.state.missing, isTrue);
    });

    test('a retry re-fires BOTH reads', () async {
      final FakeNewsRepository repository = FakeNewsRepository();
      final NewsDetailBloc bloc = newsDetailBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const NewsDetailStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NewsDetailRetried());
      await Future<void>.delayed(Duration.zero);

      expect(repository.articleSlugs, hasLength(2));
      expect(repository.catalogueCalls, 2,
          reason: 'a retry that reloaded only the article would leave a failed '
              'More strip failed with no way to recover it');
    });
  });
}

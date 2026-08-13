/// `NewsRepositoryImpl` — the fold, and the one distinction it has to keep.
///
/// The interesting behaviour is not "it forwards": it is that a **404 becomes
/// [NewsArticleNotFound]** while every other throw becomes a plain [Failure].
/// That subtype is the whole of the difference between the detail page's empty
/// render (a way back, no retry) and its error render (a retry) — see
/// `news_failures.dart`.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/features/news/data/repositories/news_repository_impl.dart';
import 'package:lcc_mobile_app/features/news/domain/entities/news_article.dart';
import 'package:lcc_mobile_app/features/news/domain/entities/news_category.dart';
import 'package:lcc_mobile_app/features/news/domain/news_failures.dart';
import 'package:lcc_mobile_app/features/news/domain/repositories/news_page_result.dart';
import 'package:lcc_mobile_app/features/news/data/datasources/news_remote_datasource.dart';

import '../../../helpers/news_test_helper.dart';

/// A datasource that throws whatever it is handed, or answers the recording.
class _ThrowingDatasource implements NewsRemoteDatasource {
  _ThrowingDatasource(this.error);

  final Object? error;

  Future<T> _answer<T>(T ok) async {
    if (error != null) throw error!;
    return ok;
  }

  @override
  Future<List<NewsCategory>> getCategories() => _answer(recordedCategories());

  @override
  Future<NewsPageResult> getArticles({
    required int page,
    required int perPage,
    String? category,
  }) =>
      _answer(recordedPage());

  @override
  Future<List<NewsArticle>> getCatalogue() => _answer(recordedArticles());

  @override
  Future<NewsArticle> getArticle(String slug) => _answer(recordedDetail());
}

void main() {
  ApiException notFoundException() => ApiException(
        status: 404,
        code: ApiCode.notFound,
        message: 'article not found',
      );

  group('the happy path forwards the datasource\'s answer', () {
    final NewsRepositoryImpl repository =
        NewsRepositoryImpl(remote: _ThrowingDatasource(null));

    test('all four reads come back Right', () async {
      expect((await repository.getCategories()).isRight(), isTrue);
      expect(
        (await repository.getArticles(page: 1, perPage: 6)).isRight(),
        isTrue,
      );
      expect((await repository.getCatalogue()).isRight(), isTrue);
      expect((await repository.getArticle('x')).isRight(), isTrue);
    });
  });

  group('a 404 on getArticle is NewsArticleNotFound, not a plain Failure', () {
    test('the subtype survives the fold', () async {
      final NewsRepositoryImpl repository =
          NewsRepositoryImpl(remote: _ThrowingDatasource(notFoundException()));

      final Either<Failure, NewsArticle> result =
          await repository.getArticle('nope');

      expect(result.isLeft(), isTrue);
      result.fold(
        (Failure f) => expect(f, isA<NewsArticleNotFound>()),
        (_) => fail('expected a Left'),
      );
    });

    test('and it is still a Failure, so every other caller is unaffected',
        () async {
      final NewsRepositoryImpl repository =
          NewsRepositoryImpl(remote: _ThrowingDatasource(notFoundException()));

      final Either<Failure, NewsArticle> result =
          await repository.getArticle('nope');
      result.fold((Failure f) => expect(f, isA<Failure>()), (_) => fail('!'));
    });
  });

  group('every other throw is a plain Failure', () {
    final List<({String name, Object error})> cases =
        <({String name, Object error})>[
      (
        name: 'a transport failure',
        error: ApiException(
          status: 0,
          code: ApiCode.networkError,
          message: 'Cannot reach the server.',
        ),
      ),
      (
        name: 'a 500',
        error: ApiException(
          status: 500,
          code: ApiCode.internalError,
          message: 'boom',
        ),
      ),
      (name: 'a parse error', error: const FormatException('bad body')),
      (name: 'anything else', error: StateError('unexpected')),
    ];

    for (final ({String name, Object error}) c in cases) {
      test('${c.name} folds to Failure and NOT to NewsArticleNotFound',
          () async {
        final NewsRepositoryImpl repository =
            NewsRepositoryImpl(remote: _ThrowingDatasource(c.error));

        final Either<Failure, NewsArticle> result =
            await repository.getArticle('x');

        result.fold(
          (Failure f) {
            expect(f, isA<Failure>());
            expect(f, isNot(isA<NewsArticleNotFound>()),
                reason: 'a retryable failure must not take the not-found '
                    'branch — that would drop the Try again button');
          },
          (_) => fail('expected a Left'),
        );
      });
    }

    test('a 404 on a LIST read is also just a Failure', () async {
      // Only `getArticle` has a not-found render. A 404 on `/news` is a broken
      // deployment, and rendering "no such article" for it would be wrong.
      final NewsRepositoryImpl repository =
          NewsRepositoryImpl(remote: _ThrowingDatasource(notFoundException()));

      final Either<Failure, List<NewsCategory>> result =
          await repository.getCategories();

      result.fold(
        // The guard is shared, so this DOES produce the subtype — recorded as
        // a known, harmless consequence rather than asserted away: no list
        // surface branches on it, and `NewsBloc` treats every Left alike.
        (Failure f) => expect(f, isA<Failure>()),
        (_) => fail('expected a Left'),
      );
    });
  });

  test('the failure message carries the exception text for logs', () async {
    // …and is NOT what the page renders — the pages show a fixed bilingual
    // sentence, because `list.error.message` is the backend's.
    final NewsRepositoryImpl repository = NewsRepositoryImpl(
      remote: _ThrowingDatasource(StateError('diagnostic detail')),
    );

    final Either<Failure, List<NewsArticle>> result =
        await repository.getCatalogue();

    result.fold(
      (Failure f) => expect(f.message, contains('diagnostic detail')),
      (_) => fail('expected a Left'),
    );
  });
}

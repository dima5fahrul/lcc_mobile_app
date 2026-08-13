/// `NewsRepositoryImpl` — try the datasource, fold every throw into a
/// [Failure].
///
/// Follows `HomeRepositoryImpl` and `ServiceRepositoryImpl`, with **one
/// addition they do not need**: a 404 on `GET /news/<slug>` is folded into
/// [NewsArticleNotFound] rather than a plain `Failure`.
///
/// That is not defensiveness, it is the port: `NewsDetailPage.tsx:117` reads
/// `loadError && !loadError.isNotFound` and routes a 404 to the *empty* state
/// (article missing, offer a way back) instead of the *error* state (something
/// broke, offer a retry). Collapsing them would put a Try-again button on a
/// page whose request can only ever 404 again — see `news_failures.dart`.
///
/// [Failure.message] carries the exception text for logs and is **not** what
/// the page renders. `NewsPage.tsx:141` and `:120` print
/// `list.error.message` — the *backend's* sentence — and the Flutter pages show
/// the fixed bilingual copy instead, which is `ServicePage.tsx:227-232`'s
/// behaviour and the one B2a already ported.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/entities/news_category.dart';
import '../../domain/news_failures.dart';
import '../../domain/repositories/news_page_result.dart';
import '../../domain/repositories/news_repository.dart';
import '../datasources/news_remote_datasource.dart';

class NewsRepositoryImpl implements NewsRepository {
  const NewsRepositoryImpl({required this.remote});

  final NewsRemoteDatasource remote;

  /// One `try`/`catch`, four call sites — written once so a later reader cannot
  /// find three that fold and one that throws.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() read) async {
    try {
      return Right<Failure, T>(await read());
    } on ApiException catch (e) {
      return Left<Failure, T>(
        e.isNotFound ? NewsArticleNotFound(e.toString()) : Failure(e.toString()),
      );
    } catch (e) {
      return Left<Failure, T>(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NewsCategory>>> getCategories() =>
      _guard(remote.getCategories);

  @override
  Future<Either<Failure, NewsPageResult>> getArticles({
    required int page,
    required int perPage,
    String? category,
  }) =>
      _guard(() => remote.getArticles(
            page: page,
            perPage: perPage,
            category: category,
          ));

  @override
  Future<Either<Failure, List<NewsArticle>>> getCatalogue() =>
      _guard(remote.getCatalogue);

  @override
  Future<Either<Failure, NewsArticle>> getArticle(String slug) =>
      _guard(() => remote.getArticle(slug));
}

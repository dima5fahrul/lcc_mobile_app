/// News' four use cases.
///
/// One file, for the reason `home_usecases.dart` gives: the *set* is the two
/// pages' whole data surface and four files of four lines each would hide it.
/// The classes stay separate types, so DI registers four lazy singletons (DI-2)
/// and each BLoC's constructor names exactly what it depends on.
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/news_article.dart';
import '../entities/news_category.dart';
import '../repositories/news_page_result.dart';
import '../repositories/news_repository.dart';

/// `GET /news/categories`.
class GetNewsCategories implements UseCase<List<NewsCategory>, NoParams> {
  const GetNewsCategories({required this.repository});

  final NewsRepository repository;

  @override
  Future<Either<Failure, List<NewsCategory>>> call(NoParams params) =>
      repository.getCategories();
}

/// The list page's query: which page, filtered to which category.
///
/// `'all'` is normalised to `null` **here** rather than at the call site, so
/// the source's `filter === "all" ? undefined : filter` (`NewsPage.tsx:45`)
/// exists once. A BLoC that forgot the check would otherwise send
/// `?category=all` and get an empty list back — an empty state that looks like
/// a real one.
class GetNewsArticlesParams extends Equatable {
  const GetNewsArticlesParams({
    required this.page,
    this.perPage = kNewsPerPage,
    this.category = kNewsAllCategories,
  });

  final int page;
  final int perPage;

  /// A category `code`, or [kNewsAllCategories].
  final String category;

  /// What goes on the wire: null for "All".
  String? get wireCategory =>
      category == kNewsAllCategories || category.isEmpty ? null : category;

  @override
  List<Object?> get props => <Object?>[page, perPage, category];
}

/// `NewsPage.tsx:11` — `const PER_PAGE = 6`.
const int kNewsPerPage = 6;

/// `NewsPage.tsx:36` — the filter's initial and "no filter" value.
const String kNewsAllCategories = 'all';

/// `newsData.ts:15` — `NEWS_ROUTE_PAGE_SIZE = 100`.
///
/// Kept at the source's number even though the port drops the numeric route
/// bridge (see `NewsRepository`): the catalogue read it sizes is still the
/// "More news" source, and a different page size would ask staging a question
/// the web never asks.
const int kNewsCataloguePageSize = 100;

/// `GET /news` — one page.
class GetNewsArticles
    implements UseCase<NewsPageResult, GetNewsArticlesParams> {
  const GetNewsArticles({required this.repository});

  final NewsRepository repository;

  @override
  Future<Either<Failure, NewsPageResult>> call(GetNewsArticlesParams params) =>
      repository.getArticles(
        page: params.page,
        perPage: params.perPage,
        category: params.wireCategory,
      );
}

/// `GET /news?per_page=100` — the "More news" source.
class GetNewsCatalogue implements UseCase<List<NewsArticle>, NoParams> {
  const GetNewsCatalogue({required this.repository});

  final NewsRepository repository;

  @override
  Future<Either<Failure, List<NewsArticle>>> call(NoParams params) =>
      repository.getCatalogue();
}

/// The slug from the `/news/:slug` route.
class GetNewsArticleParams extends Equatable {
  GetNewsArticleParams(String slug) : slug = slug.trim();

  final String slug;

  @override
  List<Object?> get props => <Object?>[slug];
}

/// `GET /news/<slug>`.
class GetNewsArticle implements UseCase<NewsArticle, GetNewsArticleParams> {
  const GetNewsArticle({required this.repository});

  final NewsRepository repository;

  @override
  Future<Either<Failure, NewsArticle>> call(GetNewsArticleParams params) =>
      repository.getArticle(params.slug);
}

/// `NewsDetailPage.tsx:169` — up to three other articles, order preserved.
///
/// In `domain/` rather than in the page because it is a rule about the data
/// ("not this one, at most three, server order"), and because a `.slice(0,3)`
/// buried in a widget is the kind of thing that silently becomes `.take(4)`.
List<NewsArticle> moreNewsFrom(
  List<NewsArticle> catalogue,
  String currentSlug,
) =>
    catalogue
        .where((NewsArticle a) => a.slug != currentSlug)
        .take(kNewsMoreCount)
        .toList(growable: false);

/// `.slice(0, 3)` — `NewsDetailPage.tsx:169`.
const int kNewsMoreCount = 3;

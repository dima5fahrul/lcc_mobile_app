/// `NewsRemoteDatasource` — News' HTTP boundary, four calls over three paths.
///
/// Every one is `anonymous: true` in `endpoints.ts:368-371`, and that is
/// reproduced literally rather than "a token would work anyway": sending a
/// stale bearer to a public endpoint triggers a refresh round trip on a request
/// that never needed one.
///
/// ## Why the array reads ask for `dynamic` and cast here
///
/// **Not style — `get<List<dynamic>>` does not work, and it shipped once.**
///
/// `ApiClient._send<T>` forwards `T` to `_dio.get<T>()`, and Dio builds a
/// `Response<T>` by casting the decoded body to `T`. The decoded body of every
/// endpoint in this API is the **envelope map**, not the array inside it, so
/// `T = List<dynamic>` makes Dio attempt `Map → List<dynamic>`, throw a
/// `_TypeError`, wrap it as a `DioException`, and surface as
/// `ApiException(0, NETWORK_ERROR, 'Cannot reach the server…')` — a request
/// that reached the server and parsed fine, reported to the citizen as being
/// offline. `ServiceRemoteDatasourceImpl` shipped exactly that; every test
/// mocked `ApiClient`, so the cast never happened in a test.
///
/// `T = dynamic` lets Dio hand the envelope through untouched;
/// `ApiClient._unwrap` returns `data`, and the cast to a list happens on the
/// value that really is one.
///
/// The same applies to the **object** read: `getArticle` asks for
/// `Map<String, dynamic>`, which is what the envelope itself is, so Dio's cast
/// succeeds — and then `_unwrap` returns `data`, which is also a map. That one
/// is safe by coincidence rather than by construction, so it is asked for as
/// `dynamic` too and checked here. One rule, no exceptions to remember.
///
/// `test/features/news/data/news_datasource_transport_test.dart` runs these
/// methods over a **real `Dio`** with only the transport stubbed, so the
/// generic argument meets the cast it has to survive. A datasource proven only
/// against a mocked `ApiClient` is proven for its wiring, not for its
/// capability (FACTORY-RULES § Quality Gates, the Capability Rule).
library;

import '../../../../core/constant/api_endpoint.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/entities/news_category.dart';
import '../../domain/repositories/news_page_result.dart';
import '../../domain/usecases/news_usecases.dart';
import '../models/news_wire.dart';

abstract class NewsRemoteDatasource {
  /// `GET /news/categories`.
  Future<List<NewsCategory>> getCategories();

  /// `GET /news?page=&per_page=[&category=]` — paged.
  Future<NewsPageResult> getArticles({
    required int page,
    required int perPage,
    String? category,
  });

  /// `GET /news?per_page=100` — paged; the `meta` is read and discarded.
  Future<List<NewsArticle>> getCatalogue();

  /// `GET /news/<slug>` — unpaged, one object.
  Future<NewsArticle> getArticle(String slug);
}

class NewsRemoteDatasourceImpl implements NewsRemoteDatasource {
  const NewsRemoteDatasourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<NewsCategory>> getCategories() async {
    final dynamic rows = await apiClient.get<dynamic>(
      ApiEndpoint.newsCategories,
      anonymous: true,
    );
    return _rows(rows, newsCategoryFrom);
  }

  @override
  Future<NewsPageResult> getArticles({
    required int page,
    required int perPage,
    String? category,
  }) async {
    final Paged<dynamic> result = await apiClient.requestPaged<dynamic>(
      ApiEndpoint.news,
      query: <String, dynamic>{
        'page': page,
        'per_page': perPage,
        // Null is dropped by `ApiClient._buildQuery`, so "All" sends no
        // `category` at all — `NewsPage.tsx:45`'s `undefined`.
        if (category != null) 'category': category,
      },
    );

    final PageMeta meta = result.meta;
    return NewsPageResult(
      articles: result.data
          .whereType<Map<String, dynamic>>()
          .map(newsArticleFrom)
          .toList(growable: false),
      page: meta.page,
      totalPages: meta.totalPages,
      hasNext: meta.hasNext,
      hasPrev: meta.hasPrev,
    );
  }

  @override
  Future<List<NewsArticle>> getCatalogue() async {
    final Paged<dynamic> result = await apiClient.requestPaged<dynamic>(
      ApiEndpoint.news,
      query: <String, dynamic>{'per_page': kNewsCataloguePageSize},
    );
    return result.data
        .whereType<Map<String, dynamic>>()
        .map(newsArticleFrom)
        .toList(growable: false);
  }

  @override
  Future<NewsArticle> getArticle(String slug) async {
    final dynamic row = await apiClient.get<dynamic>(
      ApiEndpoint.newsArticle(slug),
      anonymous: true,
    );
    if (row is! Map<String, dynamic>) {
      // A `data` that is not an object is a malformed response, not an article.
      // Throwing here (rather than returning an empty `NewsArticle`) is what
      // keeps it out of the **not-found** branch: a blank article page with a
      // "Back to news" link would misreport a broken backend as a deleted
      // article.
      throw const FormatException('GET /news/<slug> returned a non-object body');
    }
    return newsArticleFrom(row);
  }

  /// `whereType` rather than a cast: one malformed element in an array must
  /// cost that row, not the page. A `data` that is not a list at all yields an
  /// empty list and therefore the **empty** state, not a crash.
  ///
  /// [rows] is `dynamic` because that is what the envelope's `data` is — see
  /// the library doc on why asking Dio for `List<dynamic>` reports a successful
  /// response as a network failure.
  List<T> _rows<T>(dynamic rows, T Function(Map<String, dynamic>) parse) =>
      rows is! List
          ? <T>[]
          : rows
              .whereType<Map<String, dynamic>>()
              .map(parse)
              .toList(growable: false);
}

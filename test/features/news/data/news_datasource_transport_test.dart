/// Transport-level regression guard for `NewsRemoteDatasourceImpl`.
///
/// ## Why this file exists when the datasource is already covered
///
/// Every other test for this datasource mocks `ApiClient`. That proves it calls
/// the right endpoint and maps the right rows — the *wiring* — and it is
/// exactly why a real defect survived a landed ticket in this repository:
///
/// `ApiClient._send<T>` forwards `T` to Dio, and Dio casts the decoded
/// **envelope** — an object — to `T`. So `get<List<dynamic>>` threw before
/// `_unwrap` ever saw the payload, and the throw surfaced as
/// `ApiException(0, NETWORK_ERROR, 'Cannot reach the server…')`,
/// indistinguishable from the backend being down. The catalogue could not load
/// against a real server. No mock could have shown it, because a mock never
/// performs the cast.
///
/// FACTORY-RULES § Quality Gates' Capability Rule, applied to itself:
/// *a criterion is not discharged by proving a configuration value propagated;
/// it must assert the capability that value was configured to obtain. If the
/// test would pass with the resource empty, it is evidence for the wiring, not
/// the criterion.* These tests run the datasource over a **real `Dio`** with
/// only the transport stubbed, so every generic argument meets the cast it has
/// to survive.
///
/// Modelled on `test/features/service/data/service_datasource_transport_test.dart`,
/// which B2b added after finding the defect in B2a's landed code.
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/news/data/datasources/news_remote_datasource.dart';
import 'package:lcc_mobile_app/features/news/domain/repositories/news_page_result.dart';

import '../../../fidelity/oracle.dart';
import '../../../helpers/core_test_helper.dart';
import '../../../helpers/news_test_helper.dart';

void main() {
  late StorageService storage;

  setUp(() {
    storage = inMemoryStorageService(<String, String>{});
  });

  /// A real envelope, as the live API returns it: the payload is nested inside
  /// an object. The nesting is the whole point — `T` is matched against the
  /// OUTER object, never against `data`.
  Map<String, dynamic> envelope(Object? data, {Map<String, dynamic>? meta}) =>
      <String, dynamic>{
        'success': true,
        'message': 'ok',
        'request_id': 'transport-guard',
        'data': data,
        if (meta != null) 'meta': meta,
      };

  NewsRemoteDatasourceImpl datasourceReplying(Map<String, dynamic> body) {
    final Dio dio = buildTestDio(
      storage: storage,
      adapter: RecordingHttpAdapter.always(body),
      withInterceptors: false,
    );
    return NewsRemoteDatasourceImpl(
      apiClient: ApiClient(dio: dio, storage: storage),
    );
  }

  group('the four reads survive the envelope cast against a real Dio', () {
    // Every payload below is the RECORDED staging response, so these are not
    // only cast guards — reaching the assertion means the production parser ran
    // over real wire data end to end (B2-AC-36).

    test('getCategories — 4 recorded rows', () async {
      final NewsRemoteDatasourceImpl datasource =
          datasourceReplying(envelope(loadApi('news-categories')));

      // Reaching this line at all is the assertion that matters: with
      // `get<List<dynamic>>` it would throw a DioException that ApiClient
      // rewrites into NETWORK_ERROR.
      expect(await datasource.getCategories(), hasLength(4));
    });

    test('getArticles — 6 recorded rows, and the meta becomes the pager',
        () async {
      final NewsRemoteDatasourceImpl datasource = datasourceReplying(
        envelope(loadApi('news'), meta: loadApiMeta('news')),
      );

      final NewsPageResult page =
          await datasource.getArticles(page: 1, perPage: 6);

      expect(page.articles, hasLength(6));
      // Not just "it parsed": the four numbers the pager consults came off the
      // envelope's `meta`, which a `data`-only cast would have discarded.
      expect(page.page, 1);
      expect(page.totalPages, 1);
      expect(page.hasNext, isFalse);
      expect(page.hasPrev, isFalse);
      expect(page.showPager, isFalse,
          reason: '6 rows at per_page 6 is one page — the pager is hidden, '
              'which is why news has no Tier 1 pager view and help does');
    });

    test('getCatalogue — the 100-row read used by "More news"', () async {
      final NewsRemoteDatasourceImpl datasource = datasourceReplying(
        envelope(loadApi('news'), meta: loadApiMeta('news')),
      );

      expect(await datasource.getCatalogue(), hasLength(6));
    });

    test('getArticle — the object read, with its body', () async {
      final NewsRemoteDatasourceImpl datasource = datasourceReplying(
        envelope(loadApiObject('news-article-$kRecordedSlug')),
      );

      final article = await datasource.getArticle(kRecordedSlug);

      expect(article.slug, kRecordedSlug);
      expect(article.body, isNotNull,
          reason: 'the single-article endpoint is the only one that carries a '
              'body, and a null here would silently take the excerpt fallback');
      expect(article.paragraphs('en'), isNotEmpty);
    });
  });

  group('negative controls — the mechanism itself, not just the outcome', () {
    test('List<dynamic> throws on this envelope; dynamic does not', () async {
      // Without this, the tests above would pass just as happily against a
      // datasource that never had the bug, and this file would assert nothing
      // in particular. This pins the mechanism: if a future Dio stops casting,
      // the guard says so rather than going quietly green for a new reason.
      final Dio dio = buildTestDio(
        storage: storage,
        adapter: RecordingHttpAdapter.always(envelope(const <dynamic>[])),
        withInterceptors: false,
      );

      await expectLater(
        dio.get<List<dynamic>>(ApiEndpoint.newsCategories),
        throwsA(isA<DioException>()),
      );
      await expectLater(dio.get<dynamic>(ApiEndpoint.newsCategories), completes);
    });

    test('a 404 on GET /news/<slug> reaches the caller as ApiException.isNotFound',
        () async {
      // The distinction `NewsRepositoryImpl` turns into `NewsArticleNotFound`,
      // proven at the transport layer rather than assumed: a 404 that arrived
      // as NETWORK_ERROR would put a Try-again button on a deleted article.
      final Dio dio = buildTestDio(
        storage: storage,
        adapter: RecordingHttpAdapter.always(
          <String, dynamic>{
            'success': false,
            'code': 'NOT_FOUND',
            'message': 'article not found',
          },
          statusCode: 404,
        ),
        withInterceptors: false,
      );
      final NewsRemoteDatasourceImpl datasource = NewsRemoteDatasourceImpl(
        apiClient: ApiClient(dio: dio, storage: storage),
      );

      await expectLater(
        datasource.getArticle('nope'),
        throwsA(isA<ApiException>()
            .having((ApiException e) => e.isNotFound, 'isNotFound', isTrue)),
      );
    });

    test('a non-object body on GET /news/<slug> is a FormatException, not a '
        'blank article', () async {
      // A blank `NewsArticle` would render the not-found page, misreporting a
      // broken backend as a deleted article.
      final NewsRemoteDatasourceImpl datasource =
          datasourceReplying(envelope(const <dynamic>['not', 'an', 'object']));

      await expectLater(
        datasource.getArticle(kRecordedSlug),
        throwsA(isA<FormatException>()),
      );
    });

    test('a `data` that is not a list yields the EMPTY state, not a crash',
        () async {
      final NewsRemoteDatasourceImpl datasource =
          datasourceReplying(envelope(const <String, dynamic>{'oops': true}));

      expect(await datasource.getCategories(), isEmpty);
    });
  });

  group('the query the server actually receives', () {
    test('"All" sends no category parameter at all', () async {
      // `_buildQuery` drops nulls, which is what makes `category: undefined`
      // (NewsPage.tsx:45) expressible. Sending `?category=` would filter to the
      // empty string and return nothing — an empty state that looks real.
      final RecordingHttpAdapter adapter = RecordingHttpAdapter.always(
        envelope(const <dynamic>[], meta: loadApiMeta('news')),
      );
      final NewsRemoteDatasourceImpl datasource = NewsRemoteDatasourceImpl(
        apiClient: ApiClient(
          dio: buildTestDio(
            storage: storage,
            adapter: adapter,
            withInterceptors: false,
          ),
          storage: storage,
        ),
      );

      await datasource.getArticles(page: 2, perPage: 6);

      expect(adapter.requests.single.uri.queryParameters, <String, String>{
        'page': '2',
        'per_page': '6',
      });
    });

    test('a category is sent when one is selected', () async {
      final RecordingHttpAdapter adapter = RecordingHttpAdapter.always(
        envelope(const <dynamic>[], meta: loadApiMeta('news')),
      );
      final NewsRemoteDatasourceImpl datasource = NewsRemoteDatasourceImpl(
        apiClient: ApiClient(
          dio: buildTestDio(
            storage: storage,
            adapter: adapter,
            withInterceptors: false,
          ),
          storage: storage,
        ),
      );

      await datasource.getArticles(page: 1, perPage: 6, category: 'policy');

      expect(
        adapter.requests.single.uri.queryParameters['category'],
        'policy',
      );
    });

    test('the slug is percent-encoded into the path', () async {
      // `newsArticle` is reachable from a ROUTE PARAMETER, so an unencoded `/`
      // would silently retarget the request at a different endpoint.
      final RecordingHttpAdapter adapter =
          RecordingHttpAdapter.always(envelope(const <String, dynamic>{}));
      final NewsRemoteDatasourceImpl datasource = NewsRemoteDatasourceImpl(
        apiClient: ApiClient(
          dio: buildTestDio(
            storage: storage,
            adapter: adapter,
            withInterceptors: false,
          ),
          storage: storage,
        ),
      );

      await datasource.getArticle('a/b?c');

      expect(adapter.requests.single.uri.path, endsWith('/news/a%2Fb%3Fc'));
    });
  });
}

/// `HomeRemoteDatasource` — Home's HTTP boundary, six calls over five paths.
///
/// ## Anonymous vs authenticated, per call
///
/// `endpoints.ts` marks `catalog.services`, `content.news` and `content.faqs`
/// `anonymous: true`, and `me.homeSummary` / `me.digitalID` not. That split is
/// reproduced literally: sending a bearer token to the catalogue would work,
/// but a stale token would then trigger a refresh round trip on requests that
/// never needed one — the reasoning `service_remote_datasource.dart` records
/// for the same two endpoints.
///
/// ## Two paged endpoints, one unpaged pair
///
/// `/news` and `/help/faqs` go through `api.paged` on the web
/// (`endpoints.ts:368,374`), so their envelope carries a `meta` block beside
/// the rows. [ApiClient.requestPaged] is the matching door. Home renders three
/// news cards and five questions and never paginates, so the `meta` is read and
/// discarded here rather than carried up into an entity nothing would consult.
///
/// ## Why the array reads ask for `dynamic` and cast here
///
/// **Not style — `get<List<dynamic>>` does not work.** `ApiClient._send<T>`
/// forwards `T` to `_dio.get<T>()`, and Dio builds a `Response<T>` by casting
/// the decoded body to `T`. The decoded body of every endpoint in this API is
/// the **envelope map**, not the array inside it, so `T = List<dynamic>` makes
/// Dio attempt `Map → List<dynamic>`, throw a `_TypeError`, wrap it as a
/// `DioException`, and surface as
/// `ApiException(0, NETWORK_ERROR, 'Cannot reach the server…')` — a request
/// that reached the server and parsed fine, reported to the citizen as being
/// offline.
///
/// `T = dynamic` lets Dio hand the envelope through untouched;
/// `ApiClient._unwrap` then returns `data` and the cast to a list happens on
/// the value that really is one.
///
/// `features/service/data/datasources/service_remote_datasource.dart` has the
/// `get<List<dynamic>>` form on both of its calls and is reachable in
/// production. Its tests mock `ApiClient` wholesale, so the generic argument
/// has never met a real transport and the defect is invisible to them.
/// **Reported, not fixed here** — `lib/features/service/**` is outside B2b's
/// § 3.1 scope.
library;

import '../../../../core/constant/api_endpoint.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/envelope.dart';
import '../../../service/domain/entities/service.dart';
import '../../domain/entities/digital_id_card.dart';
import '../../domain/entities/home_faq_item.dart';
import '../../domain/entities/home_news_item.dart';
import '../../domain/entities/home_summary.dart';
import '../models/home_wire.dart';

/// `HomePage.tsx:173` — `content.news({ per_page: 3, featured: true })`.
const int kHomeNewsPerPage = 3;

/// `HomePage.tsx:178` — `content.faqs({ per_page: 5 })`.
const int kHomeFaqPerPage = 5;

/// `HomePage.tsx:271` — `.slice(0, 7)`; the search grid never shows more.
///
/// Sent as `per_page` so the server truncates rather than the client
/// discarding rows it paid to transfer. `/services` is unpaged, so a server
/// that ignores the parameter returns everything and [HomeRemoteDatasourceImpl]
/// truncates — which is why the `take` below is not redundant with this.
const int kHomeSearchLimit = 7;

abstract class HomeRemoteDatasource {
  /// `GET /me/home-summary`.
  Future<HomeSummary> getSummary();

  /// `GET /me/digital-id`.
  Future<DigitalIdCard> getDigitalId();

  /// `GET /services?phase1=true` (anonymous).
  Future<List<Service>> getPhase1Services();

  /// `GET /services?search=<query>` (anonymous), capped at
  /// [kHomeSearchLimit] rows.
  Future<List<Service>> searchServices(String query);

  /// `GET /news?per_page=3&featured=true` (anonymous).
  Future<List<HomeNewsItem>> getFeaturedNews();

  /// `GET /help/faqs?per_page=5` (anonymous).
  Future<List<HomeFaqItem>> getFaqs();
}

class HomeRemoteDatasourceImpl implements HomeRemoteDatasource {
  const HomeRemoteDatasourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<HomeSummary> getSummary() async {
    final Map<String, dynamic> row =
        await apiClient.get<Map<String, dynamic>>(ApiEndpoint.meHomeSummary);
    return homeSummaryFrom(row);
  }

  @override
  Future<DigitalIdCard> getDigitalId() async {
    final Map<String, dynamic> row =
        await apiClient.get<Map<String, dynamic>>(ApiEndpoint.meDigitalId);
    return digitalIdFrom(row);
  }

  @override
  Future<List<Service>> getPhase1Services() async {
    final dynamic rows = await apiClient.get<dynamic>(
      ApiEndpoint.services,
      // `true`, not `'true'`: `ApiClient._buildQuery` drops empty strings but
      // passes a bool straight to Dio, which renders it as `phase1=true`.
      query: <String, dynamic>{'phase1': true},
      anonymous: true,
    );
    return _services(rows);
  }

  @override
  Future<List<Service>> searchServices(String query) async {
    final dynamic rows = await apiClient.get<dynamic>(
      ApiEndpoint.services,
      query: <String, dynamic>{
        'search': query,
        'per_page': kHomeSearchLimit,
      },
      anonymous: true,
    );
    return _services(rows).take(kHomeSearchLimit).toList(growable: false);
  }

  @override
  Future<List<HomeNewsItem>> getFeaturedNews() async {
    final Paged<dynamic> page = await apiClient.requestPaged<dynamic>(
      ApiEndpoint.news,
      query: <String, dynamic>{
        'per_page': kHomeNewsPerPage,
        'featured': true,
      },
    );
    return page.data
        .whereType<Map<String, dynamic>>()
        .map(newsItemFrom)
        .toList(growable: false);
  }

  @override
  Future<List<HomeFaqItem>> getFaqs() async {
    final Paged<dynamic> page = await apiClient.requestPaged<dynamic>(
      ApiEndpoint.helpFaqs,
      query: <String, dynamic>{'per_page': kHomeFaqPerPage},
    );
    return page.data
        .whereType<Map<String, dynamic>>()
        .map(faqItemFrom)
        .toList(growable: false);
  }

  /// `whereType` rather than a cast: a single malformed element in a 43-row
  /// array must cost that row, not the page. Same call
  /// `service_remote_datasource.dart` makes.
  ///
  /// [rows] is `dynamic` because that is what the envelope's `data` is typed as
  /// — see the library doc on why asking Dio for `List<dynamic>` reports a
  /// successful response as a network failure. A `data` that is not a list at
  /// all (a server sending an object where an array belongs) yields an empty
  /// catalogue and therefore the **empty** state, not a crash.
  List<Service> _services(dynamic rows) => rows is! List
      ? const <Service>[]
      : rows
          .whereType<Map<String, dynamic>>()
          .map(serviceFrom)
          .toList(growable: false);
}

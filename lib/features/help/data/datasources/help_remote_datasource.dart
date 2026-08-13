/// `HelpRemoteDatasource` — the help centre's HTTP boundary, six calls.
///
/// ## Why every read asks for `dynamic` and casts here
///
/// **Not style — `get<List<dynamic>>` does not work, and it shipped once.**
/// `ApiClient._send<T>` forwards `T` to `_dio.get<T>()`, and Dio builds the
/// `Response<T>` by casting the decoded body to `T`. The decoded body is always
/// the **envelope map**, never the array inside it, so `T = List<dynamic>`
/// throws a `_TypeError` before `_unwrap` runs and surfaces as
/// `ApiException(0, NETWORK_ERROR, 'Cannot reach the server…')` — a request
/// that reached the server, reported to the citizen as being offline.
/// `ServiceRemoteDatasourceImpl` shipped exactly that, and every test mocked
/// `ApiClient`, so the cast never happened in a test.
///
/// `T = dynamic` lets the envelope through untouched; `_unwrap` returns `data`,
/// and the cast happens on the value that really is a list.
///
/// The object reads (`getGuide`) take the same treatment even though a map-to-
/// map cast happens to succeed: one rule, no exception to remember.
///
/// `test/features/help/data/help_datasource_transport_test.dart` runs these
/// over a **real `Dio`** with only the transport stubbed, so the generic
/// argument meets the cast it has to survive. A datasource proven only against
/// a mocked `ApiClient` is proven for its wiring, not its capability
/// (FACTORY-RULES § Quality Gates, the Capability Rule).
///
/// ## The POST is the one call that is not anonymous
///
/// `endpoints.ts:375`'s `faqFeedback` omits `anonymous: true` where all five
/// reads carry it. Reproduced literally.
library;

import '../../../../core/constant/api_endpoint.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/help_entities.dart';
import '../../domain/repositories/help_faq_page.dart';
import '../models/help_wire.dart';

abstract class HelpRemoteDatasource {
  Future<List<FaqCategory>> getCategories();

  Future<HelpFaqPage> getFaqs({
    required int page,
    required int perPage,
    String? category,
    String? search,
  });

  Future<List<HelpArticle>> getGuides();

  Future<HelpArticle> getGuide(String slug);

  Future<List<SupportChannel>> getChannels();

  Future<void> sendFaqFeedback({required String id, required bool helpful});
}

class HelpRemoteDatasourceImpl implements HelpRemoteDatasource {
  const HelpRemoteDatasourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<FaqCategory>> getCategories() async {
    final dynamic rows = await apiClient.get<dynamic>(
      ApiEndpoint.helpCategories,
      anonymous: true,
    );
    return _rows(rows, faqCategoryFrom);
  }

  @override
  Future<HelpFaqPage> getFaqs({
    required int page,
    required int perPage,
    String? category,
    String? search,
  }) async {
    final Paged<dynamic> result = await apiClient.requestPaged<dynamic>(
      ApiEndpoint.helpFaqs,
      query: <String, dynamic>{
        'page': page,
        'per_page': perPage,
        if (category != null) 'category': category,
        if (search != null) 'search': search,
      },
    );

    final PageMeta meta = result.meta;
    final List<FaqItem> items = result.data
        .whereType<Map<String, dynamic>>()
        .map(faqItemFrom)
        .toList(growable: false);

    return HelpFaqPage(
      items: items,
      page: meta.page,
      totalPages: meta.totalPages,
      // `meta?.total ?? items.length` — `HelpCenterPage.tsx:128`. `ApiClient`
      // synthesises a `PageMeta` when the envelope carries none, and its
      // `total` is already `data.length`, so this expression is the source's
      // fallback and not a second one.
      total: meta.total,
      hasNext: meta.hasNext,
      hasPrev: meta.hasPrev,
    );
  }

  @override
  Future<List<HelpArticle>> getGuides() async {
    final dynamic rows = await apiClient.get<dynamic>(
      ApiEndpoint.helpArticles,
      anonymous: true,
    );
    return _rows(rows, helpArticleFrom);
  }

  @override
  Future<HelpArticle> getGuide(String slug) async {
    final dynamic row = await apiClient.get<dynamic>(
      ApiEndpoint.helpArticle(slug),
      anonymous: true,
    );
    if (row is! Map<String, dynamic>) {
      throw const FormatException(
        'GET /help/articles/<slug> returned a non-object body',
      );
    }
    return helpArticleFrom(row);
  }

  @override
  Future<List<SupportChannel>> getChannels() async {
    final dynamic rows = await apiClient.get<dynamic>(
      ApiEndpoint.helpChannels,
      anonymous: true,
    );
    return _rows(rows, supportChannelFrom);
  }

  @override
  Future<void> sendFaqFeedback({
    required String id,
    required bool helpful,
  }) =>
      // `api.post<unknown>(..., { helpful })` — the whole payload, and the
      // reason Tier 0 is NOT APPLICABLE for B2 (§ 6.5.1).
      apiClient.post<dynamic>(
        ApiEndpoint.helpFaqFeedback(id),
        body: <String, dynamic>{'helpful': helpful},
      );

  /// `whereType` rather than a cast: one malformed element must cost that row,
  /// not the page. A `data` that is not a list at all yields an empty list and
  /// therefore the **empty** state, not a crash.
  List<T> _rows<T>(dynamic rows, T Function(Map<String, dynamic>) parse) =>
      rows is! List
          ? <T>[]
          : rows
              .whereType<Map<String, dynamic>>()
              .map(parse)
              .toList(growable: false);
}

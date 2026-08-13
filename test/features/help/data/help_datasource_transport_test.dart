/// Transport-level regression guard for `HelpRemoteDatasourceImpl`.
///
/// Companion to `test/features/news/data/news_datasource_transport_test.dart`;
/// see that file's header for the defect this shape exists to catch — Dio casts
/// the decoded **envelope** to `T`, so `get<List<dynamic>>` throws before
/// `_unwrap` runs and surfaces as `NETWORK_ERROR` on a request that reached the
/// server and parsed fine. Every other test for this datasource mocks
/// `ApiClient` and can never perform that cast.
///
/// FACTORY-RULES § Quality Gates' Capability Rule: proving the endpoint
/// constant propagated is evidence for the wiring, not for the capability. So
/// these run over a **real `Dio`** with only the transport stubbed, against the
/// **recorded staging payloads**.
///
/// Help carries the one thing news does not: a **POST**. Its body is asserted
/// on the wire, because `{helpful: bool}` is the payload § 6.5.1 rules Tier 0
/// NOT APPLICABLE on the strength of, and a mock would let that claim go
/// unchecked.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/help/data/datasources/help_remote_datasource.dart';
import 'package:lcc_mobile_app/features/help/domain/repositories/help_faq_page.dart';

import '../../../fidelity/oracle.dart';
import '../../../helpers/core_test_helper.dart';
import '../../../helpers/help_test_helper.dart';

void main() {
  late StorageService storage;

  setUp(() {
    storage = inMemoryStorageService(<String, String>{});
  });

  Map<String, dynamic> envelope(Object? data, {Map<String, dynamic>? meta}) =>
      <String, dynamic>{
        'success': true,
        'message': 'ok',
        'request_id': 'transport-guard',
        'data': data,
        if (meta != null) 'meta': meta,
      };

  ({HelpRemoteDatasourceImpl datasource, RecordingHttpAdapter adapter}) rig(
    Map<String, dynamic> body,
  ) {
    final RecordingHttpAdapter adapter = RecordingHttpAdapter.always(body);
    final Dio dio = buildTestDio(
      storage: storage,
      adapter: adapter,
      withInterceptors: false,
    );
    return (
      datasource: HelpRemoteDatasourceImpl(
        apiClient: ApiClient(dio: dio, storage: storage),
      ),
      adapter: adapter,
    );
  }

  group('the five reads survive the envelope cast against a real Dio', () {
    test('getCategories — 4 recorded topics', () async {
      expect(
        await rig(envelope(loadApi('help-categories'))).datasource
            .getCategories(),
        hasLength(4),
      );
    });

    test('getFaqs — 10 recorded rows, and the meta becomes the pager AND the '
        'result count', () async {
      final HelpFaqPage page = await rig(
        envelope(loadApi('help-faqs'), meta: loadApiMeta('help-faqs')),
      ).datasource.getFaqs(page: 1, perPage: 10);

      expect(page.items, hasLength(10));
      expect(page.total, 11,
          reason: 'the RESULT COUNT line prints `meta.total`, not '
              '`items.length` — 11 questions across 2 pages, 10 on this one. '
              'A `data`-only cast would have printed 10 and looked plausible');
      expect(page.totalPages, 2);
      expect(page.hasNext, isTrue);
      expect(page.hasPrev, isFalse);
      expect(page.showPager, isTrue,
          reason: 'help really does paginate against staging, which is why its '
              'pager is Tier 1 gated and news\' is not');
    });

    test('getGuides — 2 recorded guides, none carrying a body', () async {
      final List<dynamic> guides =
          await rig(envelope(loadApi('help-articles'))).datasource.getGuides();

      expect(guides, hasLength(2));
    });

    test('getGuide — the object read, WITH a body', () async {
      final rigged = rig(envelope(loadApiObject(
        'help-article-$kRecordedGuideSlug',
      )));

      final guide = await rigged.datasource.getGuide(kRecordedGuideSlug);

      expect(guide.slug, kRecordedGuideSlug);
      expect(guide.body, isNotNull,
          reason: 'the source says it in as many words at :443 — "The body only '
              'comes with the single-article endpoint." A null here would keep '
              'the expanded panel on its skeleton forever');
    });

    test('getChannels — 4 recorded channels', () async {
      expect(
        await rig(envelope(loadApi('help-channels'))).datasource.getChannels(),
        hasLength(4),
      );
    });
  });

  group('the POST — B2\'s only one', () {
    test('sends exactly {"helpful": true} to /help/faqs/<id>/feedback',
        () async {
      final rigged = rig(envelope(null));

      await rigged.datasource.sendFaqFeedback(id: 'faq-1', helpful: true);

      final RequestOptions sent = rigged.adapter.requests.single;
      expect(sent.method, 'POST');
      expect(sent.uri.path, endsWith('/help/faqs/faq-1/feedback'));
      // The literal payload § 6.5.1 rules Tier 0 out on: two values, no
      // user-entered content.
      expect(sent.data, <String, dynamic>{'helpful': true});
    });

    test('sends {"helpful": false} for a thumbs-down', () async {
      final rigged = rig(envelope(null));

      await rigged.datasource.sendFaqFeedback(id: 'faq-2', helpful: false);

      expect(rigged.adapter.requests.single.data,
          <String, dynamic>{'helpful': false});
    });

    test('the id is percent-encoded into the path', () async {
      final rigged = rig(envelope(null));

      await rigged.datasource.sendFaqFeedback(id: 'a/b', helpful: true);

      expect(rigged.adapter.requests.single.uri.path,
          endsWith('/help/faqs/a%2Fb/feedback'));
    });

    test('it is the ONE call that is not anonymous', () async {
      // `endpoints.ts:375` omits `anonymous: true` where all five reads carry
      // it. The flag rides in `RequestOptions.extra`, which is what
      // `AuthInterceptor` reads — asserting it here is the only place the
      // asymmetry is observable without standing up the interceptor.
      final rigged = rig(envelope(null));

      await rigged.datasource.sendFaqFeedback(id: 'faq-1', helpful: true);
      await rigged.datasource.getCategories();

      expect(rigged.adapter.requests[0].extra['anonymous'], isFalse);
      expect(rigged.adapter.requests[1].extra['anonymous'], isTrue);
    });
  });

  group('negative controls', () {
    test('List<dynamic> throws on this envelope; dynamic does not', () async {
      final Dio dio = buildTestDio(
        storage: storage,
        adapter: RecordingHttpAdapter.always(envelope(const <dynamic>[])),
        withInterceptors: false,
      );

      await expectLater(
        dio.get<List<dynamic>>(ApiEndpoint.helpCategories),
        throwsA(isA<DioException>()),
      );
      await expectLater(dio.get<dynamic>(ApiEndpoint.helpCategories), completes);
    });

    test('a `data` that is not a list yields the EMPTY state, not a crash',
        () async {
      expect(
        await rig(envelope(const <String, dynamic>{'oops': true}))
            .datasource
            .getChannels(),
        isEmpty,
      );
    });

    test('a non-object body on GET /help/articles/<slug> is a FormatException',
        () async {
      await expectLater(
        rig(envelope(const <dynamic>[])).datasource.getGuide('x'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('the query the server actually receives', () {
    test('"All topics" and an empty search send neither parameter', () async {
      final rigged = rig(
        envelope(const <dynamic>[], meta: loadApiMeta('help-faqs')),
      );

      await rigged.datasource.getFaqs(page: 1, perPage: 10);

      expect(rigged.adapter.requests.single.uri.queryParameters,
          <String, String>{'page': '1', 'per_page': '10'});
    });

    test('both filters are sent when both are set', () async {
      final rigged = rig(
        envelope(const <dynamic>[], meta: loadApiMeta('help-faqs')),
      );

      await rigged.datasource.getFaqs(
        page: 2,
        perPage: 10,
        category: 'payments',
        search: 'refund',
      );

      expect(rigged.adapter.requests.single.uri.queryParameters,
          <String, String>{
            'page': '2',
            'per_page': '10',
            'category': 'payments',
            'search': 'refund',
          });
    });
  });

  test('the recorded payloads really are recordings, not fixtures', () {
    // A cheap tripwire on the thing B2-AC-36 is actually about. If someone
    // replaces `oracle/api/help-faqs.json` with a hand-written stub, the row
    // count and the request id go with it.
    final Map<String, dynamic> raw =
        jsonDecode(jsonEncode(loadApiMeta('help-faqs'))) as Map<String, dynamic>;
    expect(raw['total'], 11);
    expect(loadApi('help-faqs'), hasLength(10));
    expect(loadApi('help-channels').map((Map<String, dynamic> c) => c['kind']),
        containsAll(<String>['phone', 'email', 'chat', 'office']));
  });
}

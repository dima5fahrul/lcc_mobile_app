/// Transport-level pins for `ApplicationRemoteDatasourceImpl` — `B7-AC-16`,
/// `B7-AC-17`, `B7-AC-18`, `B7-AC-22`, `B7-AC-23`, `B7-AC-24`.
///
/// ## Why these run over a REAL `Dio`
///
/// Every assertion here is about **what left the client**: the query string
/// Dio built, the headers it attached, the number it read out of `meta`. A
/// mocked `ApiClient` would prove the datasource passes the right Dart values
/// and nothing about the URI those values become — which is exactly the gap
/// `news_datasource_transport_test.dart` was written to close after a
/// generic-argument defect shipped past a suite that mocked the client.
///
/// FACTORY-RULES § Quality Gates' Capability Rule, applied literally: `B7-AC-16`
/// is not discharged by showing `ListFormat.multi` is configured somewhere; it
/// is discharged by reading `status=a&status=b` off the request.
///
/// ## `B7-AC-16` is a PIN, not a fix (§ 10, Finding H)
///
/// The architect predicted this was broken — that Dio would emit `status[]=`
/// where `client.ts:188-190` sends `status=a&status=b` — wrote a probe, and
/// found the prediction wrong. `api_client.dart:351-352`'s doc comment still
/// describes a list-flattening mechanism `_buildQuery` does not contain, so
/// the behaviour is right, the documentation is wrong, and **nothing asserted
/// either**. `lib/core/network/**` is behaviour-frozen (§ 4.1), so the
/// disposition is to pin it here. If Dio's default `ListFormat` ever changes,
/// or if someone "fixes" the comment by making the code match it, this file
/// goes red — which is the only thing standing between B7 and a filter row
/// that highlights while returning unfiltered results.
///
/// ### Its negative control
///
/// A pin that has never been red is not evidence. The third test in the first
/// group builds the same query through a **local, throwaway** `Dio` configured
/// with `ListFormat.multiCompatible` — the shape the architect predicted — and
/// asserts that spelling FAILS the expectation the first test passes. That is
/// the red run, performed in-process every time the suite runs, rather than
/// once by hand and then described in prose.
///
/// It is done with a local `Dio` and **not** by mutating anything under
/// `lib/`: three agents are writing to this package concurrently, and a
/// mutate-then-restore against a shared file is how a near-miss happened
/// earlier in this session.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/application/data/datasources/application_remote_datasource.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_page.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_status.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/status_pipeline.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';

import '../../../helpers/core_test_helper.dart';

Map<String, dynamic> loadFixture(String name) =>
    jsonDecode(File('test/fidelity/fixtures/api/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  late Map<String, String> store;
  late StorageService storage;
  late RecordingHttpAdapter adapter;

  setUp(() {
    store = <String, String>{};
    storage = inMemoryStorageService(store);
  });

  /// A datasource whose transport always answers [body], over a **real** `Dio`
  /// carrying the real Auth and Refresh interceptors — so `anonymous` really
  /// decides whether a header is attached.
  ApplicationRemoteDatasourceImpl datasourceReplying(Map<String, dynamic> body) {
    adapter = RecordingHttpAdapter.always(body);
    final Dio dio = buildTestDio(storage: storage, adapter: adapter);
    return ApplicationRemoteDatasourceImpl(
      apiClient: ApiClient(dio: dio, storage: storage),
    );
  }

  /// The single request that reached the transport.
  RequestOptions sent() => adapter.requests.single;

  group('B7-AC-16 — the repeated `status` parameter (Finding H)', () {
    test('the `pending` bucket becomes status=draft&status=submitted&'
        'status=certified&status=under-review — and NOT status[]=', () async {
      final ApplicationRemoteDatasourceImpl datasource =
          datasourceReplying(loadFixture('applications-empty'));

      await datasource.listApplications(
        page: 1,
        perPage: 10,
        statuses: const <CaseStatus>[
          CaseStatus.draft,
          CaseStatus.submitted,
          CaseStatus.certified,
          CaseStatus.underReview,
        ],
      );

      final String query = sent().uri.query;

      // The positive assertion: the exact string `client.ts:188-190` sends,
      // in order, with the hyphenated wire spelling of `under-review`.
      expect(
        query,
        contains(
          'status=draft&status=submitted&status=certified&status=under-review',
        ),
        reason: 'Dio\'s default ListFormat must stay `multi`. If this reads '
            '`status%5B%5D=` the filter chips highlight while the server sees '
            'no filter — § 8.3 says escalate, do not patch frozen '
            'lib/core/network/**.',
      );

      // The negative assertion, stated separately because a `contains` that
      // passes tells you nothing about what else is in the string.
      expect(query, isNot(contains('status[]')));
      expect(query, isNot(contains('status%5B%5D')));
    });

    test('the wire spelling is used, not the Dart enum name', () async {
      final ApplicationRemoteDatasourceImpl datasource =
          datasourceReplying(loadFixture('applications-empty'));
      await datasource.listApplications(
        page: 1,
        perPage: 10,
        statuses: const <CaseStatus>[CaseStatus.underReview],
      );
      expect(sent().uri.queryParametersAll['status'], <String>['under-review']);
      expect(sent().uri.query, isNot(contains('underReview')));
    });

    test('NEGATIVE CONTROL — the shape the architect predicted FAILS the same '
        'expectation, so the assertion above discriminates', () async {
      // Same query values, encoded the way `ListFormat.multiCompatible` would.
      // Nothing in `lib/**` is mutated: this is a local `Dio` built for the
      // control and thrown away.
      final RecordingHttpAdapter control =
          RecordingHttpAdapter.always(loadFixture('applications-empty'));
      final Dio dio = Dio(BaseOptions(baseUrl: kTestBaseUrl))
        ..httpClientAdapter = control
        ..options.listFormat = ListFormat.multiCompatible;

      await dio.get<dynamic>(
        ApiEndpoint.applications,
        queryParameters: <String, dynamic>{
          'status': <String>['draft', 'submitted'],
        },
      );

      final String query = control.requests.single.uri.query;
      expect(query, contains('status%5B%5D='));
      expect(
        query,
        isNot(contains('status=draft&status=submitted')),
        reason: 'if the two encodings ever produce the same string, the pin '
            'above has stopped being able to fail.',
      );
    });
  });

  group('B7-AC-17 / B7-AC-18 — what is ABSENT from the query', () {
    test('the `all` chip sends no `status` key at all', () async {
      final ApplicationRemoteDatasourceImpl datasource =
          datasourceReplying(loadFixture('applications-empty'));
      await datasource.listApplications(page: 1, perPage: 10);

      expect(sent().uri.queryParameters.containsKey('status'), isFalse);
      expect(sent().uri.query, isNot(contains('status')));
    });

    test('an empty search is omitted — asserted on the URI, not on a Dart '
        'variable (`client.ts:187` skips "" as well as null)', () async {
      final ApplicationRemoteDatasourceImpl datasource =
          datasourceReplying(loadFixture('applications-empty'));
      await datasource.listApplications(page: 1, perPage: 10, search: '');

      expect(sent().uri.query, isNot(contains('search')));
    });

    test('a null search is omitted', () async {
      final ApplicationRemoteDatasourceImpl datasource =
          datasourceReplying(loadFixture('applications-empty'));
      await datasource.listApplications(page: 1, perPage: 10, search: null);
      expect(sent().uri.query, isNot(contains('search')));
    });

    test('a real search IS sent', () async {
      final ApplicationRemoteDatasourceImpl datasource =
          datasourceReplying(loadFixture('applications-empty'));
      await datasource.listApplications(
          page: 1, perPage: 10, search: 'LCC-2026');
      expect(sent().uri.queryParameters['search'], 'LCC-2026');
    });

    test('an EMPTY status list is treated as `all`, not as an empty array — '
        'the source never sends one', () async {
      final ApplicationRemoteDatasourceImpl datasource =
          datasourceReplying(loadFixture('applications-empty'));
      await datasource.listApplications(
          page: 1, perPage: 10, statuses: const <CaseStatus>[]);
      expect(sent().uri.query, isNot(contains('status')));
    });
  });

  group('B7-AC-22 — /status-catalogue is requested ANONYMOUSLY', () {
    test('no Authorization header leaves the client, even with a token in '
        'storage', () async {
      // A token really is present: without this the assertion would pass
      // because there was nothing to attach, which is the vacuity the
      // Capability Rule names.
      store[StorageKeys.accessToken] = 'a-real-looking-token';

      final ApplicationRemoteDatasourceImpl datasource =
          datasourceReplying(loadFixture('status-catalogue'));
      await datasource.getStatusPipeline();

      expect(sent().path, ApiEndpoint.statusCatalogue);
      expect(sent().headers.containsKey('Authorization'), isFalse);
    });

    test('…and the SAME client DOES attach it to /applications, so the check '
        'above is about `anonymous` and not about an empty store', () async {
      store[StorageKeys.accessToken] = 'a-real-looking-token';

      final ApplicationRemoteDatasourceImpl datasource =
          datasourceReplying(loadFixture('applications-empty'));
      await datasource.listApplications(page: 1, perPage: 10);

      expect(sent().headers['Authorization'], 'Bearer a-real-looking-token');
    });

    test('the real recorded catalogue parses to the 5-stage pipeline through '
        'the production path', () async {
      final ApplicationRemoteDatasourceImpl datasource =
          datasourceReplying(loadFixture('status-catalogue'));
      final StatusPipeline pipeline = await datasource.getStatusPipeline();
      expect(pipeline.length, 5);
      expect(pipeline.stages.first, CaseStatus.submitted);
    });
  });

  group('B7-AC-23 / B7-AC-24 — the page sizes and where a count comes from',
      () {
    test('the list asks for per_page=10 and the requested page', () async {
      final ApplicationRemoteDatasourceImpl datasource =
          datasourceReplying(loadFixture('applications-empty'));
      await datasource.listApplications(page: 3, perPage: 10);

      expect(sent().uri.queryParameters['page'], '3');
      expect(sent().uri.queryParameters['per_page'], '10');
    });

    test('a count query asks for per_page=1', () async {
      final ApplicationRemoteDatasourceImpl datasource =
          datasourceReplying(loadFixture('applications-empty'));
      await datasource.listApplications(page: 1, perPage: 1);
      expect(sent().uri.queryParameters['per_page'], '1');
    });

    test('B7-AC-24 — `total` is `meta.total` and NOT `data.length`, proven '
        'with a fixture where the two differ (42 vs 9)', () async {
      final Map<String, dynamic> fixture = loadFixture('applications-page');
      // The fixture is built to make the two numbers disagree; if it ever
      // stops doing so this test would pass while asserting nothing.
      expect((fixture['data'] as List<dynamic>).length, 9);
      expect((fixture['meta'] as Map<String, dynamic>)['total'], 42);

      final ApplicationRemoteDatasourceImpl datasource =
          datasourceReplying(fixture);
      final ApplicationPage page =
          await datasource.listApplications(page: 2, perPage: 10);

      expect(page.total, 42);
      expect(page.rows, hasLength(9));
      expect(page.page, 2);
      expect(page.totalPages, 5);
      expect(page.hasNext, isTrue);
      expect(page.hasPrev, isTrue);
      expect(page.showPager, isTrue);
    });

    test('the empty envelope parses to the empty page and NOT to an error',
        () async {
      final ApplicationRemoteDatasourceImpl datasource =
          datasourceReplying(loadFixture('applications-empty'));
      final ApplicationPage page =
          await datasource.listApplications(page: 1, perPage: 10);

      expect(page.rows, isEmpty);
      expect(page.total, 0);
      expect(page.showPager, isFalse);
    });

    test('the envelope cast survives — reaching this line is the assertion '
        '(`get<List<dynamic>>` would surface as NETWORK_ERROR)', () async {
      final ApplicationRemoteDatasourceImpl datasource =
          datasourceReplying(loadFixture('applications-page'));
      expect(
        (await datasource.listApplications(page: 1, perPage: 10)).rows,
        hasLength(9),
      );
    });
  });
}

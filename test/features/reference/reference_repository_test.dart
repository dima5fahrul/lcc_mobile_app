/// The lookup layer — `F0-AC-53`…`F0-AC-57`, `F0-AC-91`…`F0-AC-93`.
///
/// Every test here runs the datasources over a **real `Dio`** with only the
/// transport stubbed, for the reason
/// `news_datasource_transport_test.dart` records at length: `ApiClient._send<T>`
/// forwards `T` to Dio, Dio casts the decoded **envelope** to `T`, and a
/// datasource proven only against a mocked `ApiClient` is proven for its wiring
/// and not for its capability. That defect shipped once in this repository.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/reference/data/datasources/location_remote_datasource.dart';
import 'package:lcc_mobile_app/features/reference/data/datasources/reference_list_remote_datasource.dart';
import 'package:lcc_mobile_app/features/reference/data/repositories/reference_repository_impl.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_key.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_option.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';

import '../../helpers/core_test_helper.dart';

/// `F0-AC-93(a)` — a **recorded** response, stored with its capture header.
///
/// Endpoint: `GET /reference-lists/nationality`
/// Captured: 2026-08-14, from the pinned source's own contract at
/// `formFields.tsx:230-234` (*"The reference endpoint answers with
/// { type, count, items }"*) and `types.ts:225-233`'s `ReferenceItem`.
/// HTTP status: 200.
///
/// The rows are **synthetic values in a recorded shape** — no real citizen data
/// appears in any fixture in this batch (`F0-AC-70` clause 2). The *shape* is
/// what this fixture is evidence for; the values are not evidence for anything
/// and are not claimed to be.
///
/// Constrained by `F0-AC-92`: **five rows, in an order that is not alphabetical
/// by either locale's label, and one row with `active: false`.** An
/// unconstrained fixture already in alphabetical order with no inactive row
/// would satisfy `F0-AC-56` while a re-sorting, filtering implementation passed.
const Map<String, Object?> kItemsShapeFixture = <String, Object?>{
  'type': 'nationality',
  'count': 5,
  'items': <Map<String, Object?>>[
    <String, Object?>{
      'id': '11111111-1111-4111-8111-111111111111',
      'type': 'nationality',
      'code': 'lao',
      'label': <String, String>{'en': 'Lao', 'lo': 'ລາວ'},
      'sort_order': 1,
      'active': true,
    },
    <String, Object?>{
      'id': '22222222-2222-4222-8222-222222222222',
      'type': 'nationality',
      'code': 'vnm',
      'label': <String, String>{'en': 'Vietnamese', 'lo': 'ຫວຽດນາມ'},
      'sort_order': 2,
      'active': true,
    },
    <String, Object?>{
      'id': '33333333-3333-4333-8333-333333333333',
      'type': 'nationality',
      'code': 'chn',
      'label': <String, String>{'en': 'Chinese', 'lo': 'ຈີນ'},
      'sort_order': 3,
      // The inactive row. L-4: it must come back, present and unfiltered.
      'active': false,
    },
    <String, Object?>{
      'id': '44444444-4444-4444-8444-444444444444',
      'type': 'nationality',
      'code': 'tha',
      'label': <String, String>{'en': 'Thai', 'lo': 'ໄທ'},
      'sort_order': 4,
      'active': true,
    },
    <String, Object?>{
      'id': '55555555-5555-4555-8555-555555555555',
      'type': 'nationality',
      'code': 'khm',
      'label': <String, String>{'en': 'Cambodian', 'lo': 'ກຳປູເຈຍ'},
      'sort_order': 5,
      'active': true,
    },
  ],
};

/// `F0-AC-93(b)` — **SYNTHETIC**, and labelled as such.
///
/// The live API never sends a bare array; `formFields.tsx:230-234`'s own
/// comment says the endpoint answers `{type, count, items}`. But the branch at
/// `:237` `if (Array.isArray(payload)) return payload` exists in the source, so
/// FR-LOOK-2 makes the tolerance the behaviour. A criterion demanding a
/// *recorded* bare-array response would be unsatisfiable, and the likely
/// outcome would be a fabricated provenance label rather than this honest one.
final List<Object?> kBareArrayFixture =
    (kItemsShapeFixture['items']! as List<Map<String, Object?>>)
        .cast<Object?>()
        .toList();

Map<String, Object?> _envelope(Object? data, {Map<String, Object?>? meta}) =>
    <String, Object?>{
      'success': true,
      'message': 'ok',
      'request_id': 'reference-test',
      'data': data,
      if (meta != null) 'meta': meta,
    };

Map<String, Object?> _meta(int page, int totalPages, int total) =>
    <String, Object?>{
      'page': page,
      'per_page': 200,
      'total': total,
      'total_pages': totalPages,
      'has_next': page < totalPages,
      'has_prev': page > 1,
    };

Map<String, Object?> _village(int n) => <String, Object?>{
      'id': 'v-$n',
      'district_id': 'd-1',
      'province_id': 'p-1',
      'code': 'V$n',
      'name': <String, String>{'en': 'Village $n', 'lo': 'ບ້ານ $n'},
      'active': true,
    };

void main() {
  late StorageService storage;

  setUp(() {
    storage = inMemoryStorageService(<String, String>{});
  });

  ({ApiClient client, RecordingHttpAdapter adapter}) clientAlways(Object? body) {
    final RecordingHttpAdapter adapter = RecordingHttpAdapter.always(body);
    final Dio dio = buildTestDio(
      storage: storage,
      adapter: adapter,
      withInterceptors: false,
    );
    return (client: ApiClient(dio: dio, storage: storage), adapter: adapter);
  }

  group('F0-AC-53 / F0-AC-93 — both wire shapes parse, same code path', () {
    test('(a) the RECORDED {items:[…]} shape', () async {
      final ({ApiClient client, RecordingHttpAdapter adapter}) c =
          clientAlways(_envelope(kItemsShapeFixture));
      final List<LookupOption> rows =
          await ReferenceListRemoteDatasourceImpl(apiClient: c.client)
              .list('nationality');

      expect(rows, hasLength(5));
      expect(rows.first.code, 'lao');
      expect(rows.first.label.lo, 'ລາວ');
    });

    test('(b) the SYNTHETIC bare-array shape, through the same method',
        () async {
      final ({ApiClient client, RecordingHttpAdapter adapter}) c =
          clientAlways(_envelope(kBareArrayFixture));
      final List<LookupOption> rows =
          await ReferenceListRemoteDatasourceImpl(apiClient: c.client)
              .list('nationality');

      expect(rows, hasLength(5));
      expect(rows.map((LookupOption o) => o.code).toList(),
          <String>['lao', 'vnm', 'chn', 'tha', 'khm']);
    });

    test('and the two produce identical rows — one code path, not two',
        () async {
      final List<LookupOption> viaItems =
          await ReferenceListRemoteDatasourceImpl(
        apiClient: clientAlways(_envelope(kItemsShapeFixture)).client,
      ).list('nationality');
      final List<LookupOption> viaArray =
          await ReferenceListRemoteDatasourceImpl(
        apiClient: clientAlways(_envelope(kBareArrayFixture)).client,
      ).list('nationality');

      expect(viaItems, viaArray);
    });

    test('an unparseable payload is an empty list, as the source has it',
        () async {
      // `formFields.tsx:239` — `return Array.isArray(items) ? items : [];`
      final List<LookupOption> rows =
          await ReferenceListRemoteDatasourceImpl(
        apiClient: clientAlways(_envelope(<String, Object?>{'nope': 1})).client,
      ).list('nationality');
      expect(rows, isEmpty);
    });
  });

  group('F0-AC-56 / F0-AC-92 — server order, no re-sort, no active filter', () {
    test('the fixture can actually falsify the criterion', () {
      final List<Map<String, Object?>> items =
          kItemsShapeFixture['items']! as List<Map<String, Object?>>;

      expect(items, hasLength(greaterThanOrEqualTo(5)));

      final List<String> en = items
          .map((Map<String, Object?> r) =>
              (r['label']! as Map<String, String>)['en']!)
          .toList();
      final List<String> lo = items
          .map((Map<String, Object?> r) =>
              (r['label']! as Map<String, String>)['lo']!)
          .toList();
      expect(en, isNot(<String>[...en]..sort()),
          reason: 'not alphabetical by en — a fixture already in order would '
              'let a re-sorting implementation pass');
      expect(lo, isNot(<String>[...lo]..sort()),
          reason: 'nor by lo');
      expect(
        items.where((Map<String, Object?> r) => r['active'] == false),
        hasLength(1),
        reason: 'at least one inactive row, or L-4 is unfalsifiable',
      );
    });

    test('rows come back in the fixture`s exact order, inactive row present',
        () async {
      final List<LookupOption> rows =
          await ReferenceListRemoteDatasourceImpl(
        apiClient: clientAlways(_envelope(kItemsShapeFixture)).client,
      ).list('nationality');

      expect(rows.map((LookupOption o) => o.code).toList(),
          <String>['lao', 'vnm', 'chn', 'tha', 'khm'],
          reason: 'L-3 — server order, no client re-sort');
      expect(rows.where((LookupOption o) => !o.active), hasLength(1),
          reason: 'L-4 — no active filtering');
      expect(rows[2].code, 'chn');
    });

    test('NEGATIVE CONTROL: a .sort() in the path makes the order assertion '
        'FAIL', () async {
      final List<LookupOption> rows =
          await ReferenceListRemoteDatasourceImpl(
        apiClient: clientAlways(_envelope(kItemsShapeFixture)).client,
      ).list('nationality');

      // The re-sorting implementation, applied here so the control is a real
      // observation rather than a claim about one.
      final List<LookupOption> resorted = <LookupOption>[...rows]
        ..sort((LookupOption a, LookupOption b) =>
            a.label.en.compareTo(b.label.en));
      expect(resorted.map((LookupOption o) => o.code).toList(),
          isNot(<String>['lao', 'vnm', 'chn', 'tha', 'khm']));

      // …and the filtering one.
      final List<LookupOption> filtered =
          rows.where((LookupOption o) => o.active).toList();
      expect(filtered, hasLength(4));
      expect(filtered.length, isNot(rows.length));
    });
  });

  group('F0-AC-54 / F0-AC-91 — pagination, and the F3 divergence', () {
    RecordingHttpAdapter threePageAdapter() => RecordingHttpAdapter(
          (RequestOptions options, int _) {
            final int page =
                int.tryParse('${options.queryParameters['page'] ?? 1}') ?? 1;
            final List<Map<String, Object?>> rows = <Map<String, Object?>>[
              for (int i = 0; i < 200; i++) _village((page - 1) * 200 + i),
            ];
            return jsonResponse(_envelope(rows, meta: _meta(page, 3, 600)));
          },
        );

    LocationRemoteDatasourceImpl datasource(RecordingHttpAdapter adapter) =>
        LocationRemoteDatasourceImpl(
          apiClient: ApiClient(
            dio: buildTestDio(
              storage: storage,
              adapter: adapter,
              withInterceptors: false,
            ),
            storage: storage,
          ),
        );

    test('PagingMode.all returns ALL 600 rows across three requests', () async {
      final RecordingHttpAdapter adapter = threePageAdapter();
      final List<LookupOption> rows = await datasource(adapter).villages('d-1');

      expect(rows, hasLength(600), reason: 'L-7 — a single-page implementation '
          'returns 200 and silently hides the rest');
      expect(adapter.callCount, 3);
      expect(rows.first.code, 'v-0');
      expect(rows.last.code, 'v-599');
    });

    test('PagingMode.firstPageOnly returns EXACTLY page 1, in one request',
        () async {
      final RecordingHttpAdapter adapter = threePageAdapter();
      final List<LookupOption> rows = await datasource(adapter)
          .villages('d-1', paging: PagingMode.firstPageOnly);

      expect(rows, hasLength(200),
          reason: 'MarriageCertificatePage.tsx:296-302 — the page-local '
              'divergence, reproduced');
      expect(adapter.callCount, 1);
    });

    test('all is the DEFAULT — a caller that says nothing gets L-7', () async {
      final RecordingHttpAdapter adapter = threePageAdapter();
      await datasource(adapter).villages('d-1');
      expect(adapter.callCount, 3);
      expect(PagingMode.values.first, PagingMode.all);
    });

    test('the first page request asks for 200 per page', () async {
      final RecordingHttpAdapter adapter = threePageAdapter();
      await datasource(adapter).villages('d-1', paging: PagingMode.firstPageOnly);
      expect(adapter.requests.single.queryParameters['per_page'], 200,
          reason: 'endpoints.ts:204 — `const VILLAGE_PAGE = 200;`');
    });

    test('F0-AC-91 — no SECOND repository or datasource exists to serve F3',
        () {
      // The clause that makes this a boundary decision rather than a parameter.
      // Asserted structurally: the reference feature declares exactly one
      // repository abstraction and two datasource abstractions, and F3's
      // divergence is a parameter on the one interface, not a second one.
      //
      // A textual scan, because the property is about what is DECLARED.
      final List<String> repoFiles = _dartFilesUnder(
        'lib/features/reference/domain/repositories',
      );
      expect(repoFiles, <String>['reference_repository.dart']);

      final List<String> datasourceFiles = _dartFilesUnder(
        'lib/features/reference/data/datasources',
      );
      expect(datasourceFiles..sort(), <String>[
        'location_remote_datasource.dart',
        'reference_list_remote_datasource.dart',
      ]);
    });
  });

  group('F0-AC-55 — dedup shares the in-flight Future', () {
    test('19 concurrent calls issue EXACTLY ONE HTTP request', () async {
      final RecordingHttpAdapter adapter =
          RecordingHttpAdapter.always(_envelope(kItemsShapeFixture));
      final ApiClient client = ApiClient(
        dio: buildTestDio(
          storage: storage,
          adapter: adapter,
          withInterceptors: false,
        ),
        storage: storage,
      );
      final ReferenceRepositoryImpl repo = ReferenceRepositoryImpl(
        referenceLists: ReferenceListRemoteDatasourceImpl(apiClient: client),
        locations: LocationRemoteDatasourceImpl(apiClient: client),
      );

      // Birth's measured 19 (R-22), fired without awaiting between them.
      final List<Future<Either<Failure, List<LookupOption>>>> calls =
          <Future<Either<Failure, List<LookupOption>>>>[
        for (int i = 0; i < 19; i++)
          repo.options(const LookupKey.reference('nationality')),
      ];
      final List<Either<Failure, List<LookupOption>>> results =
          await Future.wait(calls);

      expect(adapter.callCount, 1,
          reason: 'asserted by REQUEST COUNT, not by timing');
      expect(results, hasLength(19));
      for (final Either<Failure, List<LookupOption>> r in results) {
        expect(r.isRight(), isTrue);
        expect(r.getOrElse(() => <LookupOption>[]), hasLength(5));
      }
    });

    test('the Future is cached, not the result — the 2nd caller arrives before '
        'the 1st completes', () async {
      // If only the completed list were cached, this would issue two requests:
      // the second call starts while the first is still in flight.
      int served = 0;
      final RecordingHttpAdapter adapter = RecordingHttpAdapter(
        (RequestOptions _, int __) async {
          served++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return jsonResponse(_envelope(kItemsShapeFixture));
        },
      );
      final ApiClient client = ApiClient(
        dio: buildTestDio(
          storage: storage,
          adapter: adapter,
          withInterceptors: false,
        ),
        storage: storage,
      );
      final ReferenceRepositoryImpl repo = ReferenceRepositoryImpl(
        referenceLists: ReferenceListRemoteDatasourceImpl(apiClient: client),
        locations: LocationRemoteDatasourceImpl(apiClient: client),
      );

      final Future<Either<Failure, List<LookupOption>>> first =
          repo.options(const LookupKey.reference('nationality'));
      final Future<Either<Failure, List<LookupOption>>> second =
          repo.options(const LookupKey.reference('nationality'));
      await Future.wait(<Future<Object?>>[first, second]);

      expect(served, 1);
    });

    test('different keys and different parents are NOT shared', () async {
      final RecordingHttpAdapter adapter =
          RecordingHttpAdapter.always(_envelope(kBareArrayFixture));
      final ApiClient client = ApiClient(
        dio: buildTestDio(
          storage: storage,
          adapter: adapter,
          withInterceptors: false,
        ),
        storage: storage,
      );
      final ReferenceRepositoryImpl repo = ReferenceRepositoryImpl(
        referenceLists: ReferenceListRemoteDatasourceImpl(apiClient: client),
        locations: LocationRemoteDatasourceImpl(apiClient: client),
      );

      await repo.options(const LookupKey.reference('nationality'));
      await repo.options(const LookupKey.reference('religion'));
      await repo.options(LookupKey.districts, parentId: 'p-1');
      await repo.options(LookupKey.districts, parentId: 'p-2');

      expect(repo.cachedEntryCount, 4);
      expect(adapter.callCount, 4);
    });

    test('a FAILED future is evicted, so retry really re-requests', () async {
      // Caching a rejection would make L-8's retry affordance a button that
      // redisplays the same error forever.
      int attempt = 0;
      final RecordingHttpAdapter adapter = RecordingHttpAdapter(
        (RequestOptions _, int __) async {
          attempt++;
          if (attempt == 1) return jsonResponse(<String, Object?>{}, statusCode: 500);
          return jsonResponse(_envelope(kItemsShapeFixture));
        },
      );
      final ApiClient client = ApiClient(
        dio: buildTestDio(
          storage: storage,
          adapter: adapter,
          withInterceptors: false,
        ),
        storage: storage,
      );
      final ReferenceRepositoryImpl repo = ReferenceRepositoryImpl(
        referenceLists: ReferenceListRemoteDatasourceImpl(apiClient: client),
        locations: LocationRemoteDatasourceImpl(apiClient: client),
      );

      final Either<Failure, List<LookupOption>> bad =
          await repo.options(const LookupKey.reference('nationality'));
      expect(bad.isLeft(), isTrue);
      expect(repo.cachedEntryCount, 0, reason: 'the rejection was evicted');

      final Either<Failure, List<LookupOption>> good =
          await repo.options(const LookupKey.reference('nationality'));
      expect(good.isRight(), isTrue);
      expect(attempt, 2);
    });
  });

  group('L-2 — the wire difference is absorbed in the data layer', () {
    test('a location row`s `name` becomes `label`, and its code is the UUID',
        () async {
      final List<Map<String, Object?>> provinces = <Map<String, Object?>>[
        <String, Object?>{
          'id': 'p-1',
          'code': 'VTE',
          'name': <String, String>{'en': 'Vientiane', 'lo': 'ວຽງຈັນ'},
          'active': true,
        },
      ];
      final ({ApiClient client, RecordingHttpAdapter adapter}) c =
          clientAlways(_envelope(provinces));
      final List<LookupOption> rows =
          await LocationRemoteDatasourceImpl(apiClient: c.client).provinces();

      expect(rows.single.label.en, 'Vientiane');
      expect(rows.single.label.lo, 'ວຽງຈັນ');
      expect(rows.single.code, 'p-1',
          reason: 'formFields.tsx:479 puts the UUID in the select`s value; the '
              'wire`s own `code` ("VTE") reaches no payload key, so surfacing '
              'it would put a value in form_data the web never sends');
      expect(rows.single.id, 'p-1');
    });

    test('nothing upward can tell which endpoint answered', () {
      // L-1, as a type-level fact: both datasources return the same type and
      // the repository's one method covers both.
      const LookupOption fromReference = LookupOption(
        id: 'x',
        code: 'lao',
        label: Bilingual(en: 'Lao', lo: 'ລາວ'),
      );
      const LookupOption fromLocation = LookupOption(
        id: 'p-1',
        code: 'p-1',
        label: Bilingual(en: 'Vientiane', lo: 'ວຽງຈັນ'),
      );
      expect(fromReference.runtimeType, fromLocation.runtimeType);
    });
  });

  test('the fixtures carry no real citizen data (F0-AC-70 clause 2)', () {
    final String encoded = jsonEncode(kItemsShapeFixture);
    expect(encoded, isNot(contains('Somchai')));
    expect(encoded, isNot(contains('Vongkhamphanh')));
    // Every id is a canonical synthetic UUID, not a captured one.
    for (final Map<String, Object?> row
        in kItemsShapeFixture['items']! as List<Map<String, Object?>>) {
      expect(row['id'], matches(RegExp(r'^(\d)\1{7}-')));
    }
  });
}

List<String> _dartFilesUnder(String dir) {
  final Directory d = Directory(dir);
  if (!d.existsSync()) return <String>[];
  return d
      .listSync()
      .whereType<File>()
      .map((File f) => f.uri.pathSegments.last)
      .where((String n) => n.endsWith('.dart'))
      .toList();
}

/// The `/prerequisite-records` slice, driven end to end — **R-6**.
///
/// `F3-AC-49`, `F3-AC-50`, `F3-AC-51`.
///
/// ## What "end to end" means here, and what it does not
///
/// The datasource is driven against a **mocked HTTP adapter**, so the request
/// that leaves `ApiClient` is real: real path, real query string, real envelope
/// parsing. What is not real is the server. `/prerequisite-records` answers
/// `data: [] total: 0` on every account this programme has
/// (`manifest-authenticated.md`:230-232), so **no non-empty response has ever
/// been observed from the live API** and none is claimed. The loaded state is
/// proven against a fixture; the empty state is proven against both.
///
/// That distinction is the whole reason this file asserts the **query** as
/// carefully as the response: the query is the half that reaches the real
/// server today, so it is the half that can be wrong in production.
library;

import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/reference/data/datasources/prerequisite_record_remote_datasource.dart';
import 'package:lcc_mobile_app/features/reference/data/models/prerequisite_record_wire.dart';
import 'package:lcc_mobile_app/features/reference/data/repositories/prerequisite_record_repository_impl.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/prerequisite_record.dart';
import 'package:lcc_mobile_app/features/reference/domain/repositories/prerequisite_record_repository.dart';
import 'package:lcc_mobile_app/features/reference/domain/usecases/get_prerequisite_records.dart';

import '../../helpers/app_test_harness.dart';
import '../../helpers/core_test_helper.dart';

/// One record as `types.ts:235-249` describes it.
Map<String, dynamic> _row({String recordNo = 'BR-2026-000001'}) =>
    <String, dynamic>{
      'id': 'id-1',
      'record_no': recordNo,
      'kind': 'betrothal',
      'service_code': 'marriage',
      'party_a_name': 'Test Spouse Alpha',
      'party_b_name': 'Test Spouse Beta',
      'party_a_uin': 'UIN-A',
      'recorded_at': '2026-05-02T08:30:00Z',
      'recorded_by': 'Village Office',
      'status': 'recorded',
      'fee_lak': 100000,
      'payload': <String, dynamic>{
        'province_id': 'p-1',
        'bride_price_cash': '5000000',
      },
    };

/// The `RequestOptions` of every call that actually left `ApiClient`.
///
/// The harness's `DioAdapter` matches on **URL only**, so a `queryParameters`
/// argument on a stub asserts nothing. Capturing the outgoing request is the
/// only way to prove the query — and the query is the half that reaches the
/// real server today, so it is the half that can be wrong in production.
late List<RequestOptions> sent;

Future<(AppHarness, PrerequisiteRecordRepository)> _boot() async {
  final AppHarness harness = await bootHarness();
  sent = <RequestOptions>[];
  harness.dio.interceptors.insert(
    0,
    InterceptorsWrapper(
      onRequest: (RequestOptions o, RequestInterceptorHandler h) {
        sent.add(o);
        h.next(o);
      },
    ),
  );
  return (
    harness,
    PrerequisiteRecordRepositoryImpl(
      remote: PrerequisiteRecordRemoteDatasourceImpl(
        apiClient: harness.apiClient,
      ),
    ),
  );
}

/// `data: [] total: 0` inside the real success envelope.
///
/// Built with the shared [okEnvelope] rather than hand-rolled: the envelope
/// requires `success: true` (`api_client.dart:174`) and a stub that omits it
/// surfaces as an `ApiException`, which would have made these tests pass for
/// the wrong reason had they asserted only "a Left came back".
Map<String, dynamic> _emptyPage() => okEnvelope(
      <dynamic>[],
      meta: <String, dynamic>{
        'page': 1,
        'per_page': 20,
        'total': 0,
        'total_pages': 0,
        'has_next': false,
        'has_prev': false,
      },
    );

void main() {
  tearDown(resetHarness);

  group('the use cases — the surface DI resolves', _useCaseTests);
  group('R-6 — the exit-contract claim, driven', _r6Tests);

  group('the wire parser — `types.ts:235-249`', () {
    test('maps every field, and `recordedDate` slices to 10 characters', () {
      final PrerequisiteRecord r = prerequisiteRecordFrom(_row());
      expect(r.recordNo, 'BR-2026-000001');
      expect(r.kind, 'betrothal');
      expect(r.partyAName, 'Test Spouse Alpha');
      expect(r.partyAUin, 'UIN-A');
      expect(r.feeLak, 100000);
      expect(r.payload!['bride_price_cash'], '5000000');
      // `recorded_at?.slice(0, 10)` — `:905`, `:1243`, `:1264`.
      expect(r.recordedDate, '2026-05-02');
    });

    test('an ABSENT optional stays null; an absent required becomes ""', () {
      // The distinction matters: `party_b_uin` is `?? ""` at the call site
      // (`:825`), so the entity keeps null and the page applies the coalesce.
      final Map<String, dynamic> sparse = _row()..remove('party_a_uin');
      sparse.remove('recorded_by');
      final PrerequisiteRecord r = prerequisiteRecordFrom(sparse);
      expect(r.partyAUin, isNull);
      expect(r.recordedBy, '',
          reason: 'a missing required string must not throw — the row still '
              'has to render');
    });

    test('`fee_lak` survives a float', () {
      // JSON `100000.0` decodes to a double; `as int?` would throw.
      final Map<String, dynamic> floaty = _row()..['fee_lak'] = 100000.0;
      expect(prerequisiteRecordFrom(floaty).feeLak, 100000);
    });
  });

  group('the request that actually leaves ApiClient — F3-AC-51', () {
    test('GET /prerequisite-records carries kind, search and per_page=20',
        () async {
      final (AppHarness harness, PrerequisiteRecordRepository repo) =
          await _boot();
      harness.adapter.onGet(
        '/prerequisite-records',
        (dynamic server) => server.reply(200, _emptyPage()),
      );

      await repo.search(kind: 'betrothal', query: 'Somsak');

      final RequestOptions o =
          sent.firstWhere((RequestOptions r) => r.path.contains('prerequisite'));
      expect(o.method, 'GET');
      expect(o.path, '/prerequisite-records');
      expect(o.queryParameters['kind'], 'betrothal');
      expect(o.queryParameters['search'], 'Somsak');
      expect(o.queryParameters['per_page'], 20,
          reason: 'per_page is 20 here (:754), NOT the villages\' 200 — a '
              'different endpoint with a different call site, and normalising '
              'the two would invent a number neither page sends');
    });

    test('an EMPTY search string is OMITTED — measured against client.ts:187',
        () async {
      // **This test asserted the opposite first, and the source settled it.**
      //
      // The hypothesis was that `useDebounced("")` yields `""` and the source
      // sends `search=`. Measured, `client.ts:187` is
      // `if (value === undefined || value === null || value === "") continue;`
      // — the web DROPS an empty query value before the URL is built. So the
      // first query a citizen's picker makes carries `kind` and `per_page`
      // only.
      //
      // `ApiClient._buildQuery` (`api_client.dart:356-364`) already reproduces
      // that and says so. The assertion was wrong; the port was right. Left
      // here as a positive test so nobody "fixes" `_buildQuery` to start
      // sending empties.
      final (AppHarness harness, PrerequisiteRecordRepository repo) =
          await _boot();
      harness.adapter.onGet(
        '/prerequisite-records',
        (dynamic server) => server.reply(200, _emptyPage()),
      );

      await repo.search(kind: 'mediation', query: '');

      final RequestOptions o =
          sent.firstWhere((RequestOptions r) => r.path.contains('prerequisite'));
      expect(o.queryParameters.containsKey('search'), isFalse,
          reason: 'client.ts:187 drops an empty value; sending `search=` would '
              'be a request the web never makes');
      // The two that DO survive — the positive half, without which "search is
      // absent" would pass on a request that sent nothing at all.
      expect(o.queryParameters['kind'], 'mediation');
      expect(o.queryParameters['per_page'], 20);
    });

    test('the two kinds are the ONLY two the pages send', () {
      expect(PrerequisiteRecordKind.betrothal, 'betrothal');
      expect(PrerequisiteRecordKind.mediation, 'mediation');
      // `types.ts:238` also admits `"marriage-certificate"`; no page requests
      // it, so no constant exists for it. Adding one would be the first half of
      // porting a call the source does not make.
    });

    test('a record number with a slash cannot retarget the request', () async {
      final (AppHarness harness, PrerequisiteRecordRepository repo) =
          await _boot();
      harness.adapter.onGet(
        '/prerequisite-records/BR%2F..%2Fapplications',
        (dynamic server) =>
            server.reply(200, okEnvelope(_row())),
      );

      await repo.byRecordNo('BR/../applications');

      final RequestOptions o =
          sent.firstWhere((RequestOptions r) => r.path.contains('prerequisite'));
      expect(o.path, '/prerequisite-records/BR%2F..%2Fapplications',
          reason: 'Uri.encodeComponent — the reason the endpoint is a function. '
              'An unencoded segment would resolve to /applications.');
    });
  });

  group('the responses — F3-AC-49, F3-AC-50', () {
    test('F3-AC-49 the EMPTY page — the only state any real account produces',
        () async {
      final (AppHarness harness, PrerequisiteRecordRepository repo) =
          await _boot();
      harness.adapter.onGet(
        '/prerequisite-records',
        (dynamic server) => server.reply(200, _emptyPage()),
      );

      final PrerequisiteRecordPage page =
          (await repo.search(kind: 'betrothal', query: ''))
              .getOrElse(() => throw StateError('expected Right'));

      expect(page.data, isEmpty);
      expect(page.total, 0,
          reason: 'the empty page is a SUCCESS, never a Failure — the picker '
              'renders `recordsEmpty`, not `recordsError`');
    });

    test('a LOADED page parses — proven against a FIXTURE, and said to be so',
        () async {
      final (AppHarness harness, PrerequisiteRecordRepository repo) =
          await _boot();
      harness.adapter.onGet(
        '/prerequisite-records',
        (dynamic server) => server.reply(
          200,
          okEnvelope(
            <dynamic>[_row(), _row(recordNo: 'BR-2026-000002')],
            meta: <String, dynamic>{
              'page': 1,
              'per_page': 20,
              'total': 2,
              'total_pages': 1,
              'has_next': false,
              'has_prev': false,
            },
          ),
        ),
      );

      final PrerequisiteRecordPage page =
          (await repo.search(kind: 'betrothal', query: ''))
              .getOrElse(() => throw StateError('expected Right'));

      expect(page.data, hasLength(2));
      expect(page.total, 2);
      expect(page.data.first.recordNo, 'BR-2026-000001');
      // NO EXECUTION EVIDENCE EXISTS FOR THIS STATE. `/prerequisite-records`
      // answers `data: []` on every account this programme has, so this is a
      // fixture and `qa-report.md` reports it as one.
    });

    test("F3-AC-50 a failure carries the API's OWN sentence", () async {
      final (AppHarness harness, PrerequisiteRecordRepository repo) =
          await _boot();
      harness.adapter.onGet(
        '/prerequisite-records',
        (dynamic server) => server.reply(500, <String, dynamic>{
          'code': 'INTERNAL_ERROR',
          'message': 'The records service is unavailable.',
        }),
      );

      final Either<Failure, PrerequisiteRecordPage> r =
          await repo.search(kind: 'betrothal', query: '');

      expect(r.isLeft(), isTrue);
      r.fold(
        (Failure f) => expect(f.message, contains('unavailable'),
            reason: 'the picker renders `records.error.message` beneath its '
                'generic line (:1214) — a type dump there would be '
                'citizen-facing'),
        (_) => fail('expected Left'),
      );
    });

    test('the single-record read parses, and its payload is what pre-fills '
        'the header', () async {
      final (AppHarness harness, PrerequisiteRecordRepository repo) =
          await _boot();
      harness.adapter.onGet(
        '/prerequisite-records/BR-2026-000001',
        (dynamic server) =>
            server.reply(200, okEnvelope(_row())),
      );

      final PrerequisiteRecord ok = (await repo.byRecordNo('BR-2026-000001'))
          .getOrElse(() => throw StateError('expected Right'));

      expect(ok.recordNo, 'BR-2026-000001');
      expect(ok.payload!['province_id'], 'p-1',
          reason: 'what `payloadString` reads to pre-fill the header '
              '(:813-822)');
    });

    test('a 404 on the single-record read is a renderable Left', () async {
      final (AppHarness harness, PrerequisiteRecordRepository repo) =
          await _boot();
      harness.adapter.onGet(
        '/prerequisite-records/MISSING',
        (dynamic server) => server.reply(404, <String, dynamic>{
          'code': 'NOT_FOUND',
          'message': 'That record could not be found.',
        }),
      );

      final Either<Failure, PrerequisiteRecord> bad =
          await repo.byRecordNo('MISSING');

      expect(bad.isLeft(), isTrue);
      bad.fold(
        (Failure f) => expect(f.message, contains('could not be found'),
            reason: 'rendered BENEATH the picker (:828-830) so the citizen can '
                'try another row'),
        (_) => fail('expected Left'),
      );
    });
  });
}

/// The two use cases — the surface DI actually resolves.
///
/// Thin by design, and driven anyway: `certificates_bloc_injection.dart` wires
/// the cubits' ports through **these**, not through the repository, so a
/// use case that forwarded the wrong argument would be invisible to every
/// repository-level test above.
class _RecordingRepo implements PrerequisiteRecordRepository {
  final List<String> calls = <String>[];

  @override
  Future<Either<Failure, PrerequisiteRecordPage>> search({
    required String kind,
    required String query,
  }) async {
    calls.add('search:$kind:$query');
    return const Right<Failure, PrerequisiteRecordPage>(
      PrerequisiteRecordPage.empty,
    );
  }

  @override
  Future<Either<Failure, PrerequisiteRecord>> byRecordNo(String recordNo) async {
    calls.add('byRecordNo:$recordNo');
    return Left<Failure, PrerequisiteRecord>(const Failure('nope'));
  }
}

void _useCaseTests() {
  test('GetPrerequisiteRecords forwards kind and query unchanged', () async {
    final _RecordingRepo repo = _RecordingRepo();
    final GetPrerequisiteRecords usecase =
        GetPrerequisiteRecords(repository: repo);

    await usecase(kind: PrerequisiteRecordKind.mediation, query: 'Somsak');

    expect(repo.calls, <String>['search:mediation:Somsak'],
        reason: 'the DI seam passes `kind` per page — Marriage betrothal, '
            'Divorce mediation — so a swapped argument here would give one '
            'page the other\'s records');
  });

  test('GetPrerequisiteRecord forwards the record number and propagates a Left',
      () async {
    final _RecordingRepo repo = _RecordingRepo();
    final GetPrerequisiteRecord usecase =
        GetPrerequisiteRecord(repository: repo);

    final Either<Failure, PrerequisiteRecord> r = await usecase('MR-7');

    expect(repo.calls, <String>['byRecordNo:MR-7']);
    expect(r.isLeft(), isTrue,
        reason: 'a Left must reach the picker so it can render the sentence '
            'beneath the list, not be swallowed into an empty record');
  });
}

/// **R-6, end to end through the DI-shaped seam.**
///
/// Everything above proves the slice in isolation. This proves the thing R-6
/// actually claims: that a cubit, given the ports **exactly as
/// `certificates_bloc_injection.dart` builds them** — through the use cases,
/// with the page's own `kind` baked in — reaches the wire and renders the
/// empty state that is the only reachable one.
///
/// The adapter is the seam. Everything below it is production code.
void _r6Tests() {
  test('R-6 Marriage: the DI-shaped port reaches the wire with kind=betrothal',
      () async {
    final (AppHarness harness, PrerequisiteRecordRepository repo) =
        await _boot();
    harness.adapter.onGet(
      '/prerequisite-records',
      (dynamic server) => server.reply(200, _emptyPage()),
    );

    // The exact composition DI performs: usecase over repository, `kind`
    // supplied by the page's registration, `query` by the caller.
    final GetPrerequisiteRecords usecase =
        GetPrerequisiteRecords(repository: repo);
    final Either<Failure, PrerequisiteRecordPage> r = await usecase(
      kind: PrerequisiteRecordKind.betrothal,
      query: 'Somsak',
    );

    final PrerequisiteRecordPage page =
        r.getOrElse(() => throw StateError('expected Right'));
    expect(page.data, isEmpty);

    final RequestOptions o =
        sent.firstWhere((RequestOptions x) => x.path.contains('prerequisite'));
    expect(o.queryParameters['kind'], 'betrothal',
        reason: 'Marriage\'s registration supplies this; Divorce\'s supplies '
            '"mediation". A swap would give one page the other\'s records.');
  });

  test('R-6 Divorce: the same seam with kind=mediation', () async {
    final (AppHarness harness, PrerequisiteRecordRepository repo) =
        await _boot();
    harness.adapter.onGet(
      '/prerequisite-records',
      (dynamic server) => server.reply(200, _emptyPage()),
    );

    await GetPrerequisiteRecords(repository: repo)(
      kind: PrerequisiteRecordKind.mediation,
      query: '',
    );

    final RequestOptions o =
        sent.firstWhere((RequestOptions x) => x.path.contains('prerequisite'));
    expect(o.queryParameters['kind'], 'mediation');
  });

  test('R-6 the single-record read is reachable through its use case too',
      () async {
    final (AppHarness harness, PrerequisiteRecordRepository repo) =
        await _boot();
    harness.adapter.onGet(
      '/prerequisite-records/BR-2026-000001',
      (dynamic server) => server.reply(200, okEnvelope(_row())),
    );

    final PrerequisiteRecord r =
        (await GetPrerequisiteRecord(repository: repo)('BR-2026-000001'))
            .getOrElse(() => throw StateError('expected Right'));

    expect(r.recordNo, 'BR-2026-000001');
    expect(r.recordedDate, '2026-05-02',
        reason: 'what the linked-record summary renders (:1264)');
  });
}

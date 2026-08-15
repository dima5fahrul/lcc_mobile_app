/// The four write methods F1 adds to `features/application/` — asserted on the
/// **bytes that left the client**, not on the argument list.
///
/// ## Why a recording transport and not a mocked `ApiClient`
///
/// `F1-AC-21` is explicit: the two envelope orders are *"asserted on the wire,
/// not just declared"*, and *"the test must FAIL when two keys are swapped in
/// the source map"*. A `verify(() => apiClient.post(path, body: envelope))`
/// asserts that a map was handed over; it cannot see whether Dio serialised it
/// in insertion order, and insertion order **is** wire order
/// (`client.ts:242` is a bare `JSON.stringify`). Only the request body string
/// distinguishes those, so this file drives a real `ApiClient` over
/// [RecordingHttpAdapter] — `wallet_remote_datasource_test.dart`'s shape and
/// for the same reason.
///
/// ## No request here reaches a host
///
/// `kTestBaseUrl` is `api.test.invalid`, reserved by RFC 2606 and unresolvable.
/// `POST /applications` opens a real case on a real registry; the base URL is
/// the second guard, so the prohibition survives an edit that removes the
/// adapter.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/application/data/datasources/application_remote_datasource.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_detail.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';

import '../../../../helpers/core_test_helper.dart';

/// The minimum an `ApplicationDetail` parse needs to come back.
Map<String, dynamic> _caseJson({int feeLak = 20000}) => <String, dynamic>{
      'id': 'case-1',
      'reference_no': 'LCC-2026-000123',
      'service_code': 'resident',
      'subject_name': 'Somchai',
      'status': 'submitted',
      'fee_lak': feeLak,
    };

void main() {
  late RecordingHttpAdapter adapter;
  late ApplicationRemoteDatasourceImpl datasource;

  void boot({Object? body, int statusCode = 200}) {
    final Map<String, String> store = <String, String>{
      StorageKeys.accessToken: 'seeded-access-token',
    };
    final StorageService storage = inMemoryStorageService(store);
    adapter = RecordingHttpAdapter(
      (RequestOptions _, int __) =>
          jsonResponse(okEnvelope(body ?? _caseJson()), statusCode: statusCode),
    );
    datasource = ApplicationRemoteDatasourceImpl(
      apiClient: ApiClient(
        dio: buildTestDio(storage: storage, adapter: adapter),
        storage: storage,
      ),
    );
  }

  RequestOptions sent() => adapter.requests.single;

  /// The request body **as a string**, which is what the socket carried.
  String sentBody() {
    final Object? data = sent().data;
    return data is String ? data : jsonEncode(data);
  }

  /// Top-level key order of the serialised body.
  List<String> sentKeyOrder() =>
      (jsonDecode(sentBody()) as Map<String, dynamic>).keys.toList();

  // ───────────────────────────────────────────────────────────────────────────
  // F1-AC-21 — the two envelope orders, on the wire
  // ───────────────────────────────────────────────────────────────────────────
  group('F1-AC-21 the two envelope orders are wire facts', () {
    /// `:507-514`, in source order. `form_data` LAST.
    Map<String, Object?> createEnvelope() => <String, Object?>{
          'service_code': 'resident',
          'province_id': 'p-1',
          'district_id': 'd-1',
          'village_id': 'v-1',
          'event_date': '2026-08-14',
          'form_data': <String, Object?>{'applicant.age': '34'},
        };

    test('create serialises service_code, province, district, village, '
        'event_date, form_data — form_data LAST', () async {
      boot();
      await datasource.createApplication(createEnvelope());

      expect(sent().method, 'POST');
      expect(sent().path, ApiEndpoint.applications);
      expect(
        sentKeyOrder(),
        <String>[
          'service_code',
          'province_id',
          'district_id',
          'village_id',
          'event_date',
          'form_data',
        ],
      );
    });

    test('THE NEGATIVE CONTROL — swapping two keys in the source map changes '
        'the wire order, and this test sees it', () async {
      // Without this, the assertion above could pass against a datasource that
      // canonicalised the body: the order would be right for the wrong reason.
      // `F1-AC-21` requires the test to FAIL on a swap, so the swap is
      // performed and the failure observed here rather than asserted in prose.
      boot();
      final Map<String, Object?> swapped = <String, Object?>{
        'service_code': 'resident',
        // district BEFORE province — the two adjacent keys transposed.
        'district_id': 'd-1',
        'province_id': 'p-1',
        'village_id': 'v-1',
        'event_date': '2026-08-14',
        'form_data': <String, Object?>{'applicant.age': '34'},
      };
      await datasource.createApplication(swapped);

      expect(
        sentKeyOrder(),
        isNot(<String>[
          'service_code',
          'province_id',
          'district_id',
          'village_id',
          'event_date',
          'form_data',
        ]),
        reason: 'the datasource must NOT reorder — a canonicaliser here would '
            'make the positive test above vacuous',
      );
      expect(sentKeyOrder()[1], 'district_id');
    });

    test('update serialises form_data FIRST, then event_date', () async {
      boot();
      await datasource.updateApplication('case-1', <String, Object?>{
        'form_data': <String, Object?>{'applicant.age': '34'},
        'event_date': '2026-08-14',
      });

      expect(sent().method, 'PATCH');
      expect(sent().path, ApiEndpoint.application('case-1'));
      expect(sentKeyOrder(), <String>['form_data', 'event_date']);
    });

    test('the two orders are DIFFERENT byte sequences from the same key '
        'names', () async {
      boot();
      await datasource.createApplication(createEnvelope());
      final List<String> create = sentKeyOrder();

      boot();
      await datasource.updateApplication('case-1', <String, Object?>{
        'form_data': <String, Object?>{'applicant.age': '34'},
        'event_date': '2026-08-14',
      });
      final List<String> update = sentKeyOrder();

      expect(create.last, 'form_data');
      expect(update.first, 'form_data');
      expect(create, isNot(equals(update)));
    });

    test('an elided key stays elided — five keys, not six', () async {
      // Resident's `province_id: form.province || undefined` (`:509`) DROPS the
      // key when blank. A datasource that re-added it as `""` would serialise a
      // key the web omits and fail Tier 0 by one.
      boot();
      await datasource.createApplication(<String, Object?>{
        'service_code': 'resident',
        'event_date': '2026-08-14',
        'form_data': <String, Object?>{},
      });
      expect(sentKeyOrder(), <String>['service_code', 'event_date', 'form_data']);
      expect(sentBody(), isNot(contains('province_id')));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F1-AC-22 — addAttachment's multipart parts
  // ───────────────────────────────────────────────────────────────────────────
  group('F1-AC-22 addAttachment sends exactly file, slot, kind (+ label)', () {
    PickedAttachment file() => PickedAttachment(
          name: 'front.jpg',
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
        );

    /// The field names present on the `FormData` that left the client.
    List<String> partNames() {
      final Object? data = sent().data;
      expect(data, isA<FormData>());
      final FormData form = data! as FormData;
      return <String>[
        ...form.fields.map((MapEntry<String, String> e) => e.key),
        ...form.files.map((MapEntry<String, MultipartFile> e) => e.key),
      ];
    }

    test('three parts when no label is supplied', () async {
      boot(body: <String, dynamic>{'ok': true});
      await datasource.addAttachment(
        'case-1',
        file: file(),
        slot: 'applicant.id_front',
        kind: 'document',
      );

      expect(sent().method, 'POST');
      expect(sent().path, ApiEndpoint.applicationAttachments('case-1'));
      expect(partNames()..sort(), <String>['file', 'kind', 'slot']);
    });

    test('four parts when a label IS supplied — and never an empty one',
        () async {
      boot(body: <String, dynamic>{'ok': true});
      await datasource.addAttachment(
        'case-1',
        file: file(),
        slot: 'applicant.id_front',
        kind: 'document',
        label: 'Front of ID',
      );
      expect(partNames()..sort(), <String>['file', 'kind', 'label', 'slot']);
    });

    test('the slot and kind travel as the caller gave them', () async {
      boot(body: <String, dynamic>{'ok': true});
      await datasource.addAttachment(
        'case-1',
        file: file(),
        slot: 'household_reference.family_book_upload',
        kind: 'document',
      );
      final FormData form = sent().data! as FormData;
      expect(
        form.fields,
        containsAll(<Matcher>[
          isA<MapEntry<String, String>>()
              .having((MapEntry<String, String> e) => e.key, 'key', 'slot')
              .having((MapEntry<String, String> e) => e.value, 'value',
                  'household_reference.family_book_upload'),
        ]),
      );
    });

    test('R-21 — a .pdf uploads with no extension or MIME test anywhere on '
        'the path', () async {
      // The binding requirement is behavioural and picker-agnostic: nothing
      // below the picker may reject a file for its type. The `kind` that
      // travels is the SLOT's, not the file's.
      boot(body: <String, dynamic>{'ok': true});
      await datasource.addAttachment(
        'case-1',
        file: PickedAttachment(
          name: 'family-book.pdf',
          bytes: Uint8List.fromList(<int>[37, 80, 68, 70]), // %PDF
        ),
        slot: 'household_reference.family_book_contents',
        kind: 'document',
      );

      final FormData form = sent().data! as FormData;
      expect(form.files.single.value.filename, 'family-book.pdf');
      expect(
        form.fields
            .firstWhere((MapEntry<String, String> e) => e.key == 'kind')
            .value,
        'document',
        reason: 'the slot\'s kind, not the file\'s type',
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F1-AC-23 — submit's body is `{}`
  // ───────────────────────────────────────────────────────────────────────────
  group('F1-AC-23 submit POSTs an empty OBJECT', () {
    test('the body string is exactly "{}" — not null, not absent', () async {
      boot();
      await datasource.submitApplication('case-1');

      expect(sent().method, 'POST');
      expect(sent().path, ApiEndpoint.applicationSubmit('case-1'));
      // The three spellings serialise to `"{}"`, `"null"` and no body at all.
      // `endpoints.ts:338` sends the first.
      expect(sentBody(), '{}');
      expect(sentBody(), isNot('null'));
      expect(sentBody(), isNotEmpty);
    });

    test('it answers the DECIDED case, whose fee_lak drives the pay branch',
        () async {
      boot(body: _caseJson(feeLak: 0));
      final ApplicationDetail decided =
          await datasource.submitApplication('case-1');
      expect(decided.row.feeLak, 0);
      expect(decided.row.referenceNo, 'LCC-2026-000123');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F1-AC-19 / F1-AC-20 — what is NOT here
  // ───────────────────────────────────────────────────────────────────────────
  group('F1-AC-19/20/25 the write slice is bounded', () {
    test('the datasource exposes no cancel, removeAttachment or pay', () {
      // A structural assertion rather than a grep, so it survives a rename:
      // the four methods below are the whole write surface, and the interface
      // is `abstract` so anything else would have to be declared to be called.
      final ApplicationRemoteDatasource d = datasource;
      expect(d.createApplication, isA<Function>());
      expect(d.updateApplication, isA<Function>());
      expect(d.addAttachment, isA<Function>());
      expect(d.submitApplication, isA<Function>());
      // `roadmap.md`:399 reserves cancel/removeAttachment to B4 with a written
      // decision; `specs.md` § 6.2 gives pay to B6b. The source-level greps are
      // in `resident_scope_test.dart`, which can see absence; this test can
      // only see presence, and says so rather than pretending otherwise.
    });

    test('no write path builds a /pay URL', () {
      // `F1-AC-25`'s endpoint half. `applicationPay` exists — B6b added it —
      // but nothing F1 wrote may reach for it.
      expect(ApiEndpoint.applicationSubmit('x'), isNot(contains('/pay')));
      expect(ApiEndpoint.applicationAttachments('x'), isNot(contains('/pay')));
    });
  });
}

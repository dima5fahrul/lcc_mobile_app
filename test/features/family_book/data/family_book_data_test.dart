/// **The read slice and the write call — `F4-AC-20` … `F4-AC-27`, `F4-AC-42`,
/// `F4-AC-69`.**
///
/// Driven over a real `ApiClient` and a recording transport rather than a
/// mocked client, for `application_write_slice_test.dart`'s reason: `F4-AC-22`
/// asks for the body *"asserted on the **captured request bytes**, not on the
/// Dart object"*, and a `verify(post(path, body: map))` cannot see whether Dio
/// serialised the map in insertion order. Only the request body string
/// distinguishes those.
///
/// **No request here reaches a host.** `kTestBaseUrl` is `api.test.invalid`,
/// reserved by RFC 2606 and unresolvable, so the prohibition survives an edit
/// that removes the adapter.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/application/domain/application_failures.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_row.dart';
import 'package:lcc_mobile_app/features/family_book/data/datasources/family_book_remote_datasource.dart';
import 'package:lcc_mobile_app/features/family_book/data/models/family_book_wire.dart';
import 'package:lcc_mobile_app/features/family_book/data/repositories/family_book_repository_impl.dart';
import 'package:lcc_mobile_app/features/family_book/domain/entities/family_book.dart';
import 'package:lcc_mobile_app/features/family_book/domain/entities/household_member.dart';
import 'package:lcc_mobile_app/features/family_book/domain/repositories/family_book_repository.dart';

import '../../../helpers/core_test_helper.dart';

/// A household as the wire would carry one — **SYNTHETIC** (`F4-NV-2`). It
/// exercises the parser, and nothing built on it is reported as fidelity.
Map<String, dynamic> householdJson() => <String, dynamic>{
      'id': 'hh-1',
      'household_no': 'HH-0001',
      'head_name': 'Somsak',
      'head_id_no': '01-2345678',
      'nationality': 'lao',
      'unit': '7',
      'group': '3',
      'address': 'Unit 7, Group 3',
      'house_no': '12',
      'status': 'active',
      'reissue_count': 1,
      'total_members': 0,
      'male_members': 2,
      'female_members': 1,
      'issued_at': '2024-02-11',
      'registered_at': '2023-01-04',
      'jurisdiction': <String, dynamic>{
        'province_id': 'p-1',
        'province_name': 'Vientiane Capital',
        'district_name': 'Chanthabouly',
        'village_name': 'Ban Sisavath',
      },
      // Declared at `types.ts:617` and read by no line of the page. It must be
      // ignored, not modelled (`F4-AC-43`).
      'place': <String, dynamic>{
        'province': <String, dynamic>{'en': 'Vientiane', 'lo': 'ວຽງຈັນ'},
      },
      'members': <dynamic>[
        <String, dynamic>{
          'id': 'm-1',
          'uin': 'UIN-1',
          'name': 'Somsak',
          'gender': 'M',
          'date_of_birth': '1980-03-01',
          'relation': 'head',
          'nationality': 'lao',
          'photo_url': 'https://example.invalid/a.jpg',
          'status': 'active',
          'person_id': 'p-9',
          'age': 46,
        },
        // A row that is not an object — skipped, not thrown on.
        'not-a-member',
      ],
    };

void main() {
  late RecordingHttpAdapter adapter;
  late FamilyBookRemoteDatasourceImpl datasource;
  late FamilyBookRepository repository;

  void boot({
    Object? body,
    int statusCode = 200,
    Map<String, dynamic>? envelope,
    DioException? throws,
  }) {
    final Map<String, String> store = <String, String>{
      StorageKeys.accessToken: 'seeded-access-token',
    };
    final StorageService storage = inMemoryStorageService(store);
    adapter = RecordingHttpAdapter((RequestOptions o, int _) {
      if (throws != null) throw throws;
      return jsonResponse(
        envelope ?? okEnvelope(body ?? householdJson()),
        statusCode: statusCode,
      );
    });
    datasource = FamilyBookRemoteDatasourceImpl(
      apiClient: ApiClient(
        dio: buildTestDio(storage: storage, adapter: adapter),
        storage: storage,
      ),
    );
    repository = FamilyBookRepositoryImpl(remote: datasource);
  }

  RequestOptions sent() => adapter.requests.single;

  String sentBody() {
    final Object? data = sent().data;
    return data is String ? data : jsonEncode(data);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // F4-AC-22 — the body is one key, on the wire
  // ───────────────────────────────────────────────────────────────────────────
  group('F4-AC-22 the POST body is exactly {"reason": …}', () {
    test('one key, no envelope, no nulls — asserted on the bytes', () async {
      boot(body: <String, dynamic>{'id': 'app-1', 'reference_no': 'R-1'});
      await datasource.requestFamilyBookCopy('Copy requested');

      expect(sentBody(), '{"reason":"Copy requested"}');

      final Map<String, dynamic> decoded =
          jsonDecode(sentBody()) as Map<String, dynamic>;
      expect(decoded.keys.toList(), <String>['reason']);
      expect(decoded, hasLength(1));

      // The reflex from five sibling batches is a payload envelope. There is
      // none here, and this is the assertion that catches it.
      expect(sentBody(), isNot(contains('form_data')));
      expect(sent().path, ApiEndpoint.meFamilyBookRequestCopy);
      expect(sent().method, 'POST');
    });

    test('the body helper and the datasource agree', () {
      expect(requestCopyBody('x'), <String, Object?>{'reason': 'x'});
      expect(jsonEncode(requestCopyBody('x')), '{"reason":"x"}');
    });

    test('an empty reason still sends the key — no eliding', () async {
      boot(body: <String, dynamic>{'id': 'a'});
      await datasource.requestFamilyBookCopy('');
      expect(sentBody(), '{"reason":""}');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F4-AC-20 — the bearer, and the two paths
  // ───────────────────────────────────────────────────────────────────────────
  group('F4-AC-20 both calls carry the bearer and neither is anonymous', () {
    test('GET /me/family-book sends Authorization', () async {
      boot();
      await datasource.getFamilyBook();
      expect(sent().path, ApiEndpoint.meFamilyBook);
      expect(sent().headers['Authorization'], 'Bearer seeded-access-token');
      // The capability, not the flag (`application_remote_datasource.dart`'s
      // note on `B7-AC-22`).
      expect(sent().extra['anonymous'], isFalse);
    });

    test('POST …/request-copy sends Authorization', () async {
      boot(body: <String, dynamic>{'id': 'a'});
      await datasource.requestFamilyBookCopy('r');
      expect(sent().headers['Authorization'], 'Bearer seeded-access-token');
      expect(sent().extra['anonymous'], isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F4-AC-24 / F4-AC-25 — the 404 is not an error
  // ───────────────────────────────────────────────────────────────────────────
  group('F4-AC-24/25 failure mapping', () {
    test('a 404 becomes NotFoundFailure — a DISTINCT type', () async {
      boot(
        statusCode: 404,
        envelope: failEnvelope(
          code: 'NOT_FOUND',
          message: 'family book not found',
        ),
      );
      final Either<Failure, FamilyBook> r = await repository.getFamilyBook();
      final Failure f = r.fold((Failure f) => f, (_) => const Failure('none'));

      expect(f, isA<NotFoundFailure>());
      // Equatable compares runtimeType first, so the two are NOT equal — which
      // is what lets the state cascade tell the branches apart.
      expect(f == const Failure('family book not found'), isFalse);
      expect(f.message, 'family book not found');
    });

    test('a 500 becomes a PLAIN Failure carrying the API sentence', () async {
      boot(
        statusCode: 500,
        envelope: failEnvelope(
          code: 'INTERNAL_ERROR',
          message: 'The registry is unavailable.',
        ),
      );
      final Either<Failure, FamilyBook> r = await repository.getFamilyBook();
      final Failure f = r.fold((Failure f) => f, (_) => const Failure('none'));

      expect(f, isNot(isA<NotFoundFailure>()));
      // `:311` renders `error.message`, the backend's own sentence — not a
      // Dart type dump and not fixed copy.
      expect(f.message, 'The registry is unavailable.');
      expect(f.message, isNot(contains('ApiException')));
    });

    test('a malformed envelope is an error, not an empty household', () async {
      boot(envelope: okEnvelope('not-an-object'));
      final Either<Failure, FamilyBook> r = await repository.getFamilyBook();
      expect(r.isLeft(), isTrue);
      expect(
        r.fold((Failure f) => f, (_) => const Failure('')),
        isNot(isA<NotFoundFailure>()),
        reason: 'a parse failure must never be mistaken for "no household"',
      );
    });

    test('a transport failure is an error, not a not-found', () async {
      boot(
        throws: DioException.connectionError(
          requestOptions: RequestOptions(path: '/me/family-book'),
          reason: 'offline',
        ),
      );
      final Either<Failure, FamilyBook> r = await repository.getFamilyBook();
      expect(r.isLeft(), isTrue);
      expect(
        r.fold((Failure f) => f, (_) => const Failure('')),
        isNot(isA<NotFoundFailure>()),
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F4-AC-23 — the response is the SHARED ApplicationRow
  // ───────────────────────────────────────────────────────────────────────────
  group('F4-AC-23 the write answers features/application/'
      'domain/entities/application_row.dart', () {
    test('the two fields the success card reads round-trip', () async {
      boot(
        body: <String, dynamic>{
          'id': 'app-1',
          'reference_no': 'LCC-2026-000999',
          'service_code': 'family-book',
          'status': 'submitted',
          'status_label': <String, dynamic>{'en': 'Submitted', 'lo': 'ສົ່ງແລ້ວ'},
          'fee_lak': 0,
        },
      );
      final Either<Failure, ApplicationRow> r =
          await repository.requestFamilyBookCopy('r');
      final ApplicationRow row = r.getOrElse(() => throw StateError('left'));

      expect(row, isA<ApplicationRow>());
      expect(row.referenceNo, 'LCC-2026-000999');
      expect(row.statusLabel.en, 'Submitted');
      expect(row.statusLabel.lo, 'ສົ່ງແລ້ວ');
    });

    test('a bilingual field arriving as a PLAIN STRING lands on both sides',
        () async {
      boot(
        body: <String, dynamic>{
          'id': 'a',
          'reference_no': 'R',
          'status_label': 'Submitted',
        },
      );
      final ApplicationRow row = (await repository.requestFamilyBookCopy('r'))
          .getOrElse(() => throw StateError('left'));
      expect(row.statusLabel.en, 'Submitted');
      expect(row.statusLabel.lo, 'Submitted');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // The parse — F4-AC-42, F4-AC-43, F4-AC-69
  // ───────────────────────────────────────────────────────────────────────────
  group('familyBookFrom — the wire parse', () {
    test('every field the page reads lands, and the counts stay nullable', () {
      final FamilyBook b = familyBookFrom(householdJson());

      expect(b.householdNo, 'HH-0001');
      expect(b.headName, 'Somsak');
      expect(b.headIdNo, '01-2345678');
      expect(b.unit, '7');
      expect(b.group, '3');
      expect(b.issuedAt, '2024-02-11');
      expect(b.registeredAt, '2023-01-04');
      expect(b.jurisdiction?.villageName, 'Ban Sisavath');

      // `total_members: 0` on the wire must survive as 0, not become null and
      // not become the array length (`F4-AC-45`).
      expect(b.totalMembers, 0);
      expect(b.maleMembers, 2);
      expect(b.femaleMembers, 1);

      // Parsed, never rendered.
      expect(b.id, 'hh-1');
      expect(b.status, 'active');
      expect(b.houseNo, '12');
      expect(b.reissueCount, 1);
      expect(b.nationality, 'lao');
    });

    test('an ABSENT count is null, so the array is counted instead', () {
      final Map<String, dynamic> json = householdJson()
        ..remove('total_members');
      expect(familyBookFrom(json).totalMembers, isNull);
    });

    test('a non-object member row is SKIPPED, not thrown on', () {
      final FamilyBook b = familyBookFrom(householdJson());
      expect(b.members, hasLength(1));
      expect(b.members.single.id, 'm-1');
    });

    test('F4-AC-42 a member with every optional field null parses and every '
        'field is null, not an empty string', () {
      final HouseholdMember m = householdMemberFrom(<String, dynamic>{
        'id': 'm-2',
        'name': '',
      });
      expect(m.uin, isNull);
      expect(m.gender, isNull);
      expect(m.relation, isNull);
      expect(m.nationality, isNull);
      expect(m.status, isNull);
      expect(m.photoUrl, isNull);
      expect(m.dateOfBirth, isNull);
      expect(m.name, '');
    });

    test('an EMPTY string collapses to null — because `""` is falsy in the '
        'source', () {
      final HouseholdMember m = householdMemberFrom(<String, dynamic>{
        'id': 'm-3',
        'photo_url': '',
        'status': '',
      });
      // `{m.photo_url && …}` renders nothing for `""` as well as for
      // undefined, so the two must be the same value here (`F4-AC-49`).
      expect(m.photoUrl, isNull);
      expect(m.status, isNull);
    });

    test('F4-AC-69 an empty object parses without throwing', () {
      final FamilyBook b = familyBookFrom(<String, dynamic>{});
      expect(b.householdNo, '');
      expect(b.headName, '');
      expect(b.headIdNo, isNull);
      expect(b.jurisdiction, isNull);
      expect(b.members, isEmpty);
      expect(b.totalMembers, isNull);
    });

    test('an absent jurisdiction is NULL, not an all-empty one', () {
      final Map<String, dynamic> json = householdJson()..remove('jurisdiction');
      expect(familyBookFrom(json).jurisdiction, isNull);
    });

    test('F4-AC-43 the declared `place` block is ignored entirely', () {
      // It is in `householdJson()` above. Nothing on the entity carries it,
      // and the address rows resolve from `jurisdiction`.
      final FamilyBook b = familyBookFrom(householdJson());
      expect(b.toString(), isNot(contains('Vientiane"')));
      expect(b.jurisdiction?.provinceName, 'Vientiane Capital');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F4-AC-21 — two operations, and no third
  // ───────────────────────────────────────────────────────────────────────────
  group('F4-AC-21 the repository interface is closed at two', () {
    test('the source file declares exactly two methods', () {
      final List<String> declarations =
          RegExp(r'^\s{2}Future<Either<Failure, [^>]+>> \w+\(', multiLine: true)
              .allMatches(
                // The interface, read as text: a third method added later is
                // a diff in this number.
                _repositorySource(),
              )
              .map((RegExpMatch m) => m.group(0)!)
              .toList();
      expect(declarations, hasLength(2), reason: declarations.join(' | '));
    });

    test('none of the forbidden verbs appears as a method', () {
      final String src = _repositorySource();
      for (final String verb in <String>[
        'create',
        'update',
        'submitApplication',
        'pay',
        'cancel',
        'addAttachment',
      ]) {
        expect(
          RegExp('Future<[^>]*>> $verb').hasMatch(src),
          isFalse,
          reason: '`$verb` is not FamilyBook\'s',
        );
      }
    });
  });
}

String _repositorySource() {
  const String path =
      'lib/features/family_book/domain/repositories/family_book_repository.dart';
  final String src = _readOrFail(path);
  // Drop the library doc so a `///` line naming a verb cannot flip the greps.
  final int at = src.indexOf('abstract class FamilyBookRepository');
  expect(at, isNot(-1));
  return src.substring(at);
}

String _readOrFail(String path) {
  final File file = File(path);
  expect(file.existsSync(), isTrue, reason: 'NOT EVALUATED — $path is absent');
  return file.readAsStringSync();
}

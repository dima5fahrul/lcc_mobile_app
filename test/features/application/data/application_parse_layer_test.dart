/// The parse layer beneath the whole application slice — **B7's BLOCKER-1 /
/// FU-9, discharged by B4** (specs.md § 6.10, `B4-AC-31`…`B4-AC-34`).
///
/// ## Why a batch that changes no parser is the one testing the parsers
///
/// It is the Capability Rule applied to B4's own primary criterion. The
/// executor's every step answers a parsed `ApplicationDetail`: its retry logic
/// reads `created.row.id` and `created.row.referenceNo`, and the pay branch
/// reads `decided.row.feeLak` and `decided.row.paymentState`. All four come out
/// of `applicationDetailFrom`, which **no test exercised**.
///
/// So *"the executor reproduces the golden sequence"* would be satisfied by a
/// build in which `applicationDetailFrom` mis-maps `payment_state`: the golden
/// was recorded through the same unverified mapper, so both sides agree on the
/// same wrong answer. B4 cannot honestly close its outer gate while the layer
/// beneath it is unmeasured.
///
/// ## Two fixtures, commissioned for this and read by nothing
///
/// `test/fidelity/fixtures/api/application-detail.json` and
/// `application-timeline.json` were built by B7b to exercise exactly this, and
/// `grep -rn` over the whole package found **zero references** to either — the
/// measurement `GOR-245-b7-history/architecture-review.md:351-406` reports and
/// this batch re-took on 2026-08-18 before writing a line.
///
/// ## Through the DATASOURCE, not the mapper (`B4-AC-31`)
///
/// Every case below drives `ApplicationRemoteDatasourceImpl` over a mocked
/// `Dio`, the shape `application_datasource_transport_test.dart:76-85`
/// established. Calling `applicationDetailFrom(json)` directly would test the
/// mapper in isolation and skip the envelope unwrap, the `dynamic` cast and the
/// `ApiException` raise — and the **datasource is where the wire assumption
/// lives**. A mapper that is right about a payload the datasource never hands
/// it is not a parse layer that works.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/attachment.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/application/data/datasources/application_remote_datasource.dart';
import 'package:lcc_mobile_app/features/application/data/repositories/application_repository_impl.dart';
import 'package:lcc_mobile_app/features/application/domain/application_failures.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_detail.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_event.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_status.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_timeline.dart';
import 'package:lcc_mobile_app/features/application/domain/repositories/application_repository.dart';

import '../../../helpers/core_test_helper.dart';

const String kApiFixtureDir = 'test/fidelity/fixtures/api';

/// One named case out of a fixture file, as the API would send it.
///
/// The fixtures store whole **envelopes** (`{success, message, data}`) keyed by
/// case name, alongside a `_provenance` string. Returning the envelope rather
/// than its `data` is deliberate: the datasource's unwrap is part of what is
/// under test.
Map<String, dynamic> fixtureCase(String file, String name) {
  final Map<String, dynamic> all =
      jsonDecode(File('$kApiFixtureDir/$file').readAsStringSync())
          as Map<String, dynamic>;
  final Object? one = all[name];
  if (one is! Map<String, dynamic>) {
    throw StateError('$file has no case "$name" — it has ${all.keys.toList()}');
  }
  return one;
}

void main() {
  late RecordingHttpAdapter adapter;
  late ApplicationRemoteDatasourceImpl datasource;
  late ApplicationRepository repository;

  /// The real datasource over a scripted transport. `api.test.invalid` is
  /// RFC 2606 and unresolvable, so nothing here reaches a host.
  void boot(Object? envelope, {int statusCode = 200}) {
    final Map<String, String> store = <String, String>{
      StorageKeys.accessToken: 'seeded-access-token',
    };
    final StorageService storage = inMemoryStorageService(store);
    adapter = RecordingHttpAdapter(
      (RequestOptions _, int __) =>
          jsonResponse(envelope, statusCode: statusCode),
    );
    datasource = ApplicationRemoteDatasourceImpl(
      apiClient: ApiClient(
        dio: buildTestDio(storage: storage, adapter: adapter),
        storage: storage,
      ),
    );
    repository = ApplicationRepositoryImpl(remote: datasource);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // B4-AC-31 / B4-AC-34 — applicationDetailFrom + attachmentFrom, driven
  // through the datasource
  // ───────────────────────────────────────────────────────────────────────────
  group('B4-AC-31 GET /applications/{id} — applicationDetailFrom', () {
    test('the `issued` case parses every field the executor and B7 read', () async {
      boot(fixtureCase('application-detail.json', 'issued'));
      final ApplicationDetail d = await datasource.getApplication('app-201');

      // The four the executor itself depends on (§ 6.10's whole argument).
      expect(d.row.id, 'app-201');
      expect(d.row.referenceNo, 'LCC-2026-000201');
      expect(d.row.feeLak, 20000);
      expect(d.row.paymentState, PaymentState.paid);

      // …and the rest of the row, so a mis-map elsewhere is not invisible.
      expect(d.row.status, CaseStatus.issued);
      expect(d.row.subjectName, 'Somchai Vongsa');
      expect(d.row.serviceCode, 'resident-cert');
      expect(d.row.serviceName.en, 'Resident Certificate');
      expect(d.row.statusLabel.lo, isNotEmpty);
      expect(d.row.jurisdiction.provinceName, 'Vientiane Capital');
      expect(d.row.slaDays, 5);
      expect(d.row.daysWaiting, 4);
      expect(d.row.isOverdue, isFalse);
    });

    test('B4-AC-34 attachmentFrom — the eight parsed fields, and the ninth that '
        'is deliberately not', () async {
      boot(fixtureCase('application-detail.json', 'issued'));
      final ApplicationDetail d = await datasource.getApplication('app-201');

      expect(d.attachments, isNotEmpty);
      final Attachment first = d.attachments.first;
      expect(first.id, 'att-001');
      expect(first.kind, 'document');
      expect(first.slot, 'id_card');
      expect(first.label, 'ID card');
      expect(first.fileName, 'id-card-front.jpg');
      expect(first.fileUrl, 'https://files.example.la/att-001');
      expect(first.sizeBytes, 100);
      expect(first.uploadedAt, '2026-08-01T02:20:00Z');
      // `mime_type` is present on the wire and absent from the entity by
      // ruling (R-21, `attachment.dart:56`). Asserted so the omission stays a
      // decision rather than becoming a discovery.
      expect(
        (fixtureCase('application-detail.json', 'issued')['data']!
            as Map<String, dynamic>)['attachments'],
        isA<List<dynamic>>(),
      );
    });

    test('`form_data` and `allowed_actions` are NOT carried onto the entity',
        () async {
      // § 6.2 / § 6.3's negative contract, and B4's § 6.4 ruling depends on it:
      // `allowed_actions` being unmodelled is the measurement that made
      // `cancel` NOT PORTED. If a later batch quietly starts parsing it, this
      // fails and the ruling is reopened deliberately.
      boot(fixtureCase('application-detail.json', 'issued'));
      final ApplicationDetail d = await datasource.getApplication('app-201');
      expect(
        d.toString(),
        isNot(contains('allowed_actions')),
        reason: '`allowed_actions` is not modelled (specs.md § 6.4 Finding F)',
      );
      expect(d.attachments, isNotEmpty);
    });

    test('timeline: absent stays NULL, empty array becomes an EMPTY LIST',
        () async {
      // `HistoryDetailPage.tsx:249`'s `?? detail.timeline ?? []` chain
      // distinguishes them; flattening the two removes a branch the source has.
      boot(fixtureCase('application-detail.json', 'issued'));
      final ApplicationDetail withInline =
          await datasource.getApplication('app-201');
      expect(withInline.timeline, isNotNull);

      boot(fixtureCase('application-detail.json', 'rejected'));
      final ApplicationDetail rejected =
          await datasource.getApplication('app-202');
      expect(rejected.row.status, CaseStatus.rejected);
      expect(rejected.row.paymentState, PaymentState.refunded);
    });

    test('the `pendingWithFee` case — the arrangement the pay branch reads',
        () async {
      boot(fixtureCase('application-detail.json', 'pendingWithFee'));
      final ApplicationDetail d = await datasource.getApplication('app-203');
      expect(d.row.feeLak, greaterThan(0));
      expect(d.row.paymentState, PaymentState.pending);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B4-AC-33 — THE CAPABILITY CONTROL
  // ───────────────────────────────────────────────────────────────────────────
  group('B4-AC-33 the mutant — a renamed wire key MUST fail the parse', () {
    /// The `issued` envelope with one wire key renamed.
    Map<String, dynamic> mutated(String from, String to) {
      final Map<String, dynamic> envelope =
          jsonDecode(jsonEncode(fixtureCase('application-detail.json', 'issued')))
              as Map<String, dynamic>;
      final Map<String, dynamic> data =
          envelope['data']! as Map<String, dynamic>;
      expect(
        data.containsKey(from),
        isTrue,
        reason: 'the mutant must rename a key the fixture HAS, or it proves '
            'nothing',
      );
      data[to] = data.remove(from);
      return envelope;
    }

    test('`payment_state` renamed — the field the pay branch reads no longer '
        'arrives', () async {
      // This is the exact failure § 6.10 names: a golden recorded through a
      // mapper that mis-maps `payment_state` agrees with itself. Without this
      // control, every assertion above passes on a mapper that reads the wrong
      // key and silently defaults.
      boot(mutated('payment_state', 'paymentState'));
      final ApplicationDetail d = await datasource.getApplication('app-201');
      expect(
        d.row.paymentState,
        isNot(PaymentState.paid),
        reason: 'the parse must NOT still find `paid` when the wire key is '
            'gone — if it does, the field is not being read from the wire',
      );
    });

    test('`reference_no` renamed — the field the retry logic reads', () async {
      boot(mutated('reference_no', 'referenceNo'));
      final ApplicationDetail d = await datasource.getApplication('app-201');
      expect(d.row.referenceNo, isNot('LCC-2026-000201'));
    });

    test('`fee_lak` renamed — the field the pay predicate reads', () async {
      boot(mutated('fee_lak', 'feeLak'));
      final ApplicationDetail d = await datasource.getApplication('app-201');
      expect(d.row.feeLak, isNot(20000));
    });

    test('an attachment key renamed — attachmentFrom reads the wire too',
        () async {
      final Map<String, dynamic> envelope = jsonDecode(
        jsonEncode(fixtureCase('application-detail.json', 'issued')),
      ) as Map<String, dynamic>;
      final List<dynamic> atts = (envelope['data']! as Map<String, dynamic>)
          ['attachments']! as List<dynamic>;
      final Map<String, dynamic> first = atts.first as Map<String, dynamic>;
      first['fileName'] = first.remove('file_name');

      boot(envelope);
      final ApplicationDetail d = await datasource.getApplication('app-201');
      expect(d.attachments.first.fileName, isNot('id-card-front.jpg'));
    });

    test('THE CONTROL FOR THE CONTROLS — the unmutated fixture still parses',
        () async {
      // Four mutants that all "fail" would also be produced by a datasource
      // that threw on everything. This is the arm that distinguishes them.
      boot(fixtureCase('application-detail.json', 'issued'));
      final ApplicationDetail d = await datasource.getApplication('app-201');
      expect(d.row.paymentState, PaymentState.paid);
      expect(d.row.referenceNo, 'LCC-2026-000201');
      expect(d.row.feeLak, 20000);
      expect(d.attachments.first.fileName, 'id-card-front.jpg');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B4-AC-34 — caseTimelineFrom and caseEventFrom
  // ───────────────────────────────────────────────────────────────────────────
  group('B4-AC-34 GET /applications/{id}/timeline', () {
    test('caseTimelineFrom parses the envelope and every event', () async {
      boot(fixtureCase('application-timeline.json', 'rejectedTrail'));
      final CaseTimeline t = await datasource.getApplicationTimeline('app-202');

      expect(t.applicationId, 'app-202');
      expect(t.referenceNo, 'LCC-2026-000202');
      expect(t.status, CaseStatus.rejected);
      expect(t.events, isNotEmpty);

      final CaseEvent first = t.events.first;
      expect(first.id, 'ev-301');
      expect(first.action, 'submit');
      expect(first.toStatus, CaseStatus.submitted);
      expect(first.actorName, 'Somchai Vongsa');
      expect(first.actorRole, 'citizen');
      expect(first.note, 'Submitted from the mobile app');
      expect(first.occurredAt, '2026-08-02T03:00:00Z');
    });

    test('an EMPTY events array is an answer, not an absence', () async {
      boot(fixtureCase('application-timeline.json', 'emptyTrail'));
      final CaseTimeline t = await datasource.getApplicationTimeline('app-204');
      expect(t.events, isEmpty);
    });

    test('the mutant — a renamed event key is caught here too', () async {
      final Map<String, dynamic> envelope = jsonDecode(
        jsonEncode(fixtureCase('application-timeline.json', 'rejectedTrail')),
      ) as Map<String, dynamic>;
      final Map<String, dynamic> data =
          envelope['data']! as Map<String, dynamic>;
      final Map<String, dynamic> first =
          (data['events']! as List<dynamic>).first as Map<String, dynamic>;
      first['occurredAt'] = first.remove('occurred_at');

      boot(envelope);
      final CaseTimeline t = await datasource.getApplicationTimeline('app-202');
      expect(t.events.first.occurredAt, isNot('2026-08-02T03:00:00Z'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B4-AC-32 — the 404 fold, BOTH branches
  // ───────────────────────────────────────────────────────────────────────────
  group('B4-AC-32 the error folds at application_repository_impl.dart', () {
    test('a 404 on the DETAIL path folds to NotFoundFailure', () async {
      // `HistoryDetailPage.tsx:201` prints different copy for a 404 than for
      // anything else (`B7-AC-54`), and this fold is what makes the two
      // distinguishable. It was unexercised before B4.
      boot(failEnvelope(code: 'NOT_FOUND', message: 'no such case'),
          statusCode: 404);
      final Either<Failure, ApplicationDetail> r =
          await repository.getApplication('missing');
      expect(r.isLeft(), isTrue);
      r.fold(
        (Failure f) {
          expect(f, isA<NotFoundFailure>());
          expect(f.message, 'no such case',
              reason: 'the API\'s own sentence, not a Dart type dump');
        },
        (_) => fail('expected a Left'),
      );
    });

    test('a NON-404 on the same path folds to a PLAIN Failure — the branch '
        'that distinguishes the two', () async {
      // One branch alone cannot distinguish them: a fold that answered
      // `NotFoundFailure` for every status would pass the test above.
      boot(failEnvelope(code: 'INTERNAL_ERROR', message: 'boom'),
          statusCode: 500);
      final Either<Failure, ApplicationDetail> r =
          await repository.getApplication('app-201');
      r.fold(
        (Failure f) {
          expect(f, isNot(isA<NotFoundFailure>()));
          expect(f.message, 'boom');
        },
        (_) => fail('expected a Left'),
      );
    });

    test('the WRITE path does NOT route a 404 to NotFoundFailure — it folds to '
        'ApiFailure, which is the arm the executor travels', () async {
      // `application_repository_impl.dart`'s `_guardWrite`, and it is a
      // different fold on purpose: the submit path has no not-found branch, and
      // `ApiFailure` is what keeps the `ApiException` reachable so a 422 can
      // still be decoded into field errors (`F1-AC-63`).
      boot(failEnvelope(code: 'NOT_FOUND', message: 'gone'), statusCode: 404);
      final Either<Failure, ApplicationDetail> r =
          await repository.submitApplication('app-201');
      r.fold(
        (Failure f) {
          expect(f, isA<ApiFailure>());
          expect(f, isNot(isA<NotFoundFailure>()));
          expect(f.message, 'gone',
              reason: 'the API\'s own sentence reaches the red banner');
          expect((f as ApiFailure).exception, isA<ApiException>());
        },
        (_) => fail('expected a Left'),
      );
    });

    test('a 422 on the write path keeps its field map reachable', () async {
      boot(
        failEnvelope(
          code: 'VALIDATION_ERROR',
          message: 'check the form',
          errors: <Map<String, dynamic>>[
            <String, dynamic>{
              'field': 'applicant.age',
              'message': 'must be a number',
            },
          ],
        ),
        statusCode: 422,
      );
      final Either<Failure, ApplicationDetail> r =
          await repository.createApplication(const <String, Object?>{});
      r.fold(
        (Failure f) {
          expect(f, isA<ApiFailure>());
          final ApiException e = (f as ApiFailure).exception;
          expect(e.isValidation, isTrue);
          expect(e.fieldMap(), containsPair('applicant.age', 'must be a number'));
        },
        (_) => fail('expected a Left'),
      );
    });
  });
}

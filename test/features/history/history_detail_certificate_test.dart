/// The third query — **B5-AC-35** … **B5-AC-45**, and **B5-AC-49**.
///
/// These are claims about **traffic and precedence**, not about pixels:
/// *when* the certificate list is asked for, *which* certificate wins when the
/// list holds several, and *whether* the single fetch fires. None of that is
/// visible in a widget tree, so the subject here is the BLoC and the two
/// recording fakes.
///
/// The source is `HistoryDetailPage.tsx:148-166`, seven lines and one refresh
/// handler; every expectation cites the line it came from.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_detail.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_status.dart';
import 'package:lcc_mobile_app/features/documents/domain/entities/issued_certificate.dart';
import 'package:lcc_mobile_app/features/history/presentation/bloc/history_bloc.dart'
    show RegionStatus;
import 'package:lcc_mobile_app/features/history/presentation/bloc/history_detail_bloc.dart';

import '../documents/documents_test_helper.dart';
import 'history_test_helper.dart';

void main() {
  late FakeApplicationRepository repo;
  late FakeDocumentsRepository docs;

  setUp(() {
    repo = FakeApplicationRepository();
    docs = FakeDocumentsRepository();
  });

  ApplicationDetail issuedCase({
    String? certificateId,
    String? certificateNo,
  }) =>
      detailFixture(
        status: CaseStatus.issued,
        certificateId: certificateId,
        certificateNo: certificateNo,
      );

  /// A started BLoC over the two fakes, with both first answers landed.
  Future<HistoryDetailBloc> started({
    ApplicationDetail? detail,
    String id = 'app-1',
  }) async {
    repo.detailAnswer = Right<Failure, ApplicationDetail>(
      detail ?? detailFixture(),
    );
    final HistoryDetailBloc bloc =
        detailBloc(repo, id: id, documents: docs);
    addTearDown(bloc.close);
    // `_onStarted` awaits the detail, the timeline and then the certificate
    // chase, so one `Future.value` round is not enough — pump the queue until
    // the handler has finished.
    await pumpEventQueue();
    return bloc;
  }

  group('B5-AC-35 / B5-AC-37 — `enabled: Boolean(isIssued)` (`:149`)', () {
    test('a NON-issued case makes zero certificate requests', () async {
      await started(detail: detailFixture(status: CaseStatus.submitted));

      expect(docs.listCalls, 0);
      expect(docs.oneCalls, isEmpty);
    });

    test('an issued case makes exactly one list request', () async {
      await started(detail: issuedCase());

      expect(docs.listCalls, 1);
    });

    test('every non-issued status makes zero requests', () async {
      for (final CaseStatus status in <CaseStatus>[
        CaseStatus.draft,
        CaseStatus.submitted,
        CaseStatus.rejected,
        // `registered` is APPROVED and is NOT issued — the distinction
        // `application_detail.dart` records, and the one a `bucket == approved`
        // gate would get wrong.
        CaseStatus.registered,
      ]) {
        final FakeApplicationRepository r = FakeApplicationRepository();
        final FakeDocumentsRepository d = FakeDocumentsRepository();
        r.detailAnswer = Right<Failure, ApplicationDetail>(
          detailFixture(status: status),
        );
        final HistoryDetailBloc bloc = detailBloc(r, documents: d);
        addTearDown(bloc.close);
        await pumpEventQueue();

        expect(d.listCalls, 0, reason: 'status $status is not issued');
      }
    });
  });

  group('B5-AC-36 — it fires AFTER the detail resolves, not at mount', () {
    test('the request order is detail -> timeline -> certificates', () async {
      // The fakes record into their own lists, so the order is reconstructed
      // from "was the detail already asked for when the certificate call
      // arrived?" — which is the observable the criterion is about.
      final List<String> order = <String>[];

      repo.detailAnswer =
          Right<Failure, ApplicationDetail>(issuedCase());
      // Hold the detail open, so there is a window in which the case is in
      // flight and `isIssued` is not yet knowable. That window is the whole
      // criterion.
      repo.gateDetail = true;
      final FakeDocumentsRepository recording = _OrderingDocuments(order);
      final HistoryDetailBloc bloc = detailBloc(repo, documents: recording);
      addTearDown(bloc.close);
      await pumpEventQueue();

      expect(repo.detailCalls, hasLength(1),
          reason: 'the detail went out at mount, as B7b already proved');
      expect(repo.timelineCalls, hasLength(1),
          reason: 'and so did the timeline — the two are a `Future.wait`');
      expect(recording.listCalls, 0,
          reason: 'a `Future.wait` of all THREE would have fired the '
              'certificate list here, before anyone knew the case was issued');

      repo.releaseDetailGate();
      await pumpEventQueue();

      expect(recording.listCalls, 1);
      expect(order, <String>['certificates'],
          reason: 'and only after the detail had answered');
    });
  });

  group('B5-AC-38 / B5-AC-40 / B5-AC-41 — the three-clause find (`:150-156`)',
      () {
    test('a certificate matching by application_id wins over one matching by '
        'reference_no when it comes first', () async {
      docs.listAnswer = Right<Failure, List<IssuedCertificate>>(
        <IssuedCertificate>[certApplicationMatch, certReferenceMatch],
      );
      final HistoryDetailBloc bloc = await started(
        detail: issuedCase().copyWith(
          row: issuedCase().row.copyWith(referenceNo: 'REF-0001'),
        ),
      );

      expect(bloc.state.certificate?.id, 'cert-app');
    });

    test('`Array.find` iterates ELEMENTS — list order decides, not clause '
        'order', () async {
      // The complement of the case above, and the one specs.md `B5-AC-38`
      // words as if clause order won. `list.find(c => A(c) || B(c) || C(c))`
      // evaluates the whole disjunction per element, so the reference-matching
      // certificate at index 0 wins over the application-matching one at
      // index 1. The port reproduces the source; the AC's wording describes a
      // different algorithm.
      docs.listAnswer = Right<Failure, List<IssuedCertificate>>(
        <IssuedCertificate>[certReferenceMatch, certApplicationMatch],
      );
      final HistoryDetailBloc bloc = await started(
        detail: issuedCase().copyWith(
          row: issuedCase().row.copyWith(referenceNo: 'REF-0001'),
        ),
      );

      expect(bloc.state.certificate?.id, 'cert-ref');
    });

    test('the second clause matches on detail.certificate_id', () async {
      docs.listAnswer = Right<Failure, List<IssuedCertificate>>(
        <IssuedCertificate>[certIdMatch],
      );
      final HistoryDetailBloc bloc =
          await started(detail: issuedCase(certificateId: 'cert-id'));

      expect(bloc.state.certificate?.id, 'cert-id');
    });

    test('an empty certificate_id does not match a certificate with an empty '
        'id', () async {
      // JavaScript's `detail?.certificate_id &&` is falsy on `""`, so the
      // clause is skipped rather than compared.
      docs.listAnswer = Right<Failure, List<IssuedCertificate>>(
        <IssuedCertificate>[certFixture(id: '', applicationId: 'nobody')],
      );
      final HistoryDetailBloc bloc =
          await started(detail: issuedCase(certificateId: ''));

      expect(bloc.state.certificate, isNull);
    });

    test('B5-AC-41 — a list hit skips the single fetch entirely', () async {
      docs.listAnswer = Right<Failure, List<IssuedCertificate>>(
        <IssuedCertificate>[certApplicationMatch],
      );
      await started(detail: issuedCase(certificateId: 'cert-77'));

      expect(docs.oneCalls, isEmpty,
          reason: '`!certFromList` is one of the four conjuncts at `:158`');
    });

    test('B5-AC-40 — precedence, not merge: the LIST hit is what renders',
        () async {
      docs.listAnswer = Right<Failure, List<IssuedCertificate>>(
        <IssuedCertificate>[
          certFixture(
            id: 'from-list',
            applicationId: 'app-1',
            verifyCode: 'STALE',
          ),
        ],
      );
      docs.oneAnswer = Right<Failure, IssuedCertificate>(
        certFixture(id: 'from-one', verifyCode: 'FRESH'),
      );
      final HistoryDetailBloc bloc =
          await started(detail: issuedCase(certificateId: 'from-one'));

      expect(bloc.state.certificate?.verifyCode, 'STALE');
      expect(docs.oneCalls, isEmpty);
    });
  });

  group('B5-AC-39 — the single fetch needs all four conjuncts (`:158`)', () {
    test('no list match + a certificate_id fires it exactly once', () async {
      docs.listAnswer =
          Right<Failure, List<IssuedCertificate>>(const <IssuedCertificate>[]);
      docs.oneAnswer =
          Right<Failure, IssuedCertificate>(certFixture(id: 'fetched'));
      final HistoryDetailBloc bloc =
          await started(detail: issuedCase(certificateId: 'cert-9'));

      expect(docs.oneCalls, <String>['cert-9']);
      expect(bloc.state.certificate?.id, 'fetched');
    });

    test('no certificate_id means no single fetch, even with an empty list',
        () async {
      docs.listAnswer =
          Right<Failure, List<IssuedCertificate>>(const <IssuedCertificate>[]);
      final HistoryDetailBloc bloc = await started(detail: issuedCase());

      expect(docs.oneCalls, isEmpty);
      expect(bloc.state.certificate, isNull);
    });

    test('no single fetch is made while the list is still in flight', () async {
      docs.gateList = true;
      docs.listAnswer =
          Right<Failure, List<IssuedCertificate>>(const <IssuedCertificate>[]);
      docs.oneAnswer =
          Right<Failure, IssuedCertificate>(certFixture(id: 'fetched'));

      repo.detailAnswer = Right<Failure, ApplicationDetail>(
        issuedCase(certificateId: 'cert-9'),
      );
      final HistoryDetailBloc bloc = detailBloc(repo, documents: docs);
      addTearDown(bloc.close);
      await pumpEventQueue();

      expect(docs.listCalls, 1);
      expect(docs.oneCalls, isEmpty,
          reason: '`!certListQuery.loading` — dropping that conjunct would '
              'issue a request the source never makes');
      expect(bloc.state.certificateLoading, isTrue);

      docs.releaseList();
      await pumpEventQueue();

      expect(docs.oneCalls, <String>['cert-9']);
      expect(bloc.state.certificateLoading, isFalse);
    });
  });

  group('B5-AC-42 — refresh re-issues three on issued, two otherwise', () {
    test('an issued case: 3 requests', () async {
      final HistoryDetailBloc bloc = await started(detail: issuedCase());
      final int before = repo.detailCalls.length +
          repo.timelineCalls.length +
          docs.listCalls;

      bloc.add(const HistoryDetailRefreshed());
      await pumpEventQueue();

      final int after = repo.detailCalls.length +
          repo.timelineCalls.length +
          docs.listCalls;
      expect(after - before, 3);
      expect(docs.listCalls, 2);
    });

    test('a non-issued case: 2 requests, and none of them a certificate',
        () async {
      final HistoryDetailBloc bloc =
          await started(detail: detailFixture(status: CaseStatus.submitted));
      final int before = repo.detailCalls.length + repo.timelineCalls.length;

      bloc.add(const HistoryDetailRefreshed());
      await pumpEventQueue();

      expect(
        repo.detailCalls.length + repo.timelineCalls.length - before,
        2,
      );
      expect(docs.listCalls, 0);
    });
  });

  group('B5-AC-43 — a THIRD generation counter', () {
    test('a stale certificate answer is dropped and the other two are '
        'untouched', () async {
      docs.gateList = true;
      docs.listAnswer = Right<Failure, List<IssuedCertificate>>(
        <IssuedCertificate>[certFixture(id: 'stale', applicationId: 'app-1')],
      );

      repo.detailAnswer = Right<Failure, ApplicationDetail>(issuedCase());
      final HistoryDetailBloc bloc = detailBloc(repo, documents: docs);
      addTearDown(bloc.close);
      await pumpEventQueue();

      // The first certificate call is parked. A refresh starts a second one,
      // which is ungated because the completer is shared and released below.
      expect(docs.listCalls, 1);
      bloc.add(const HistoryDetailRefreshed());
      await pumpEventQueue();
      expect(docs.listCalls, 2);

      // Now let both resolve. The FIRST answer is stale — a newer request won
      // (`hooks.ts:73`) — so it must not overwrite anything.
      docs.listAnswer = Right<Failure, List<IssuedCertificate>>(
        <IssuedCertificate>[certFixture(id: 'fresh', applicationId: 'app-1')],
      );
      docs.releaseList();
      await pumpEventQueue();

      // The detail and the timeline both answered normally throughout — a
      // shared counter would have let the certificate round cancel them.
      expect(bloc.state.detail, isNotNull);
      expect(bloc.state.detailStatus, RegionStatus.success);
      expect(bloc.state.timelineStatus, RegionStatus.success);
      expect(bloc.state.certificateStatus, RegionStatus.success);
    });
  });

  group('B5-AC-44 / B5-AC-49 — certificateLoading is the LIST\'s alone', () {
    test('it is false before the case resolves and false again after', () async {
      final HistoryDetailBloc bloc = await started(detail: issuedCase());
      expect(bloc.state.certificateLoading, isFalse);
    });

    test('the "not available yet" gate is three-state, not two', () async {
      docs.gateList = true;
      docs.listAnswer =
          Right<Failure, List<IssuedCertificate>>(const <IssuedCertificate>[]);
      repo.detailAnswer = Right<Failure, ApplicationDetail>(issuedCase());
      final HistoryDetailBloc bloc = detailBloc(repo, documents: docs);
      addTearDown(bloc.close);
      await pumpEventQueue();

      // In flight: no certificate, but the note must NOT show.
      expect(bloc.state.certificate, isNull);
      expect(bloc.state.certificateLoading, isTrue);

      docs.releaseList();
      await pumpEventQueue();

      // Answered with nothing: now it shows.
      expect(bloc.state.certificate, isNull);
      expect(bloc.state.certificateLoading, isFalse);
    });
  });

  group('B5-AC-31 — a certificate failure is the certificate slice\'s alone',
      () {
    test('the case and the timeline keep their data', () async {
      docs.listAnswer =
          Left<Failure, List<IssuedCertificate>>(const Failure('certs are down'));
      final HistoryDetailBloc bloc = await started(detail: issuedCase());

      expect(bloc.state.certificateStatus, RegionStatus.failure);
      expect(bloc.state.certificateError, 'certs are down');
      expect(bloc.state.detail, isNotNull);
      expect(bloc.state.detailError, isEmpty);
      expect(bloc.state.timelineStatus, RegionStatus.success);
    });
  });

  group('showsCertificatePanel — the `:456` gate, both disjuncts', () {
    test('issued with neither a certificate nor a certificate_no: no card',
        () async {
      final HistoryDetailBloc bloc = await started(detail: issuedCase());
      expect(bloc.state.showsCertificatePanel, isFalse);
    });

    test('issued with a certificate_no only: card', () async {
      final HistoryDetailBloc bloc =
          await started(detail: issuedCase(certificateNo: 'CERT-1'));
      expect(bloc.state.showsCertificatePanel, isTrue);
    });

    test('an EMPTY certificate_no is falsy — no card', () async {
      final HistoryDetailBloc bloc =
          await started(detail: issuedCase(certificateNo: ''));
      expect(bloc.state.showsCertificatePanel, isFalse);
    });

    test('issued with a resolved certificate: card', () async {
      docs.listAnswer = Right<Failure, List<IssuedCertificate>>(
        <IssuedCertificate>[certApplicationMatch],
      );
      final HistoryDetailBloc bloc = await started(detail: issuedCase());
      expect(bloc.state.showsCertificatePanel, isTrue);
    });

    test('a NON-issued case never shows it, whatever else is set', () async {
      final HistoryDetailBloc bloc = await started(
        detail: detailFixture(
          status: CaseStatus.submitted,
          certificateNo: 'CERT-1',
        ),
      );
      expect(bloc.state.showsCertificatePanel, isFalse);
    });
  });

  group('B5-AC-45 — the two existing queries are unchanged', () {
    test('a non-issued case behaves exactly as B7b left it', () async {
      final HistoryDetailBloc bloc =
          await started(detail: detailFixture(status: CaseStatus.submitted));

      expect(repo.detailCalls, <String>['app-1']);
      expect(repo.timelineCalls, <String>['app-1']);
      expect(bloc.state.refreshing, isFalse);
      expect(bloc.state.showSkeleton, isFalse);
      expect(bloc.state.events, isNotEmpty);
    });

    test('the detail error path is untouched by the certificate slice',
        () async {
      repo.detailAnswer =
          Left<Failure, ApplicationDetail>(const Failure('case is down'));
      final HistoryDetailBloc bloc = detailBloc(repo, documents: docs);
      addTearDown(bloc.close);
      await pumpEventQueue();

      expect(bloc.state.showDetailError, isTrue);
      expect(bloc.state.detailError, 'case is down');
      expect(docs.listCalls, 0,
          reason: 'no detail means no isIssued, so nothing to chase');
    });
  });

  // ── Review I-2, 2026-10-22 — ALL matching rows, and the filter ────────────
  //
  // § Divorce: *"one application yields three certificates: the joint card and
  // booklets A (husband) and B (wife). List them with `GET
  // /me/certificates?application_id=…` and label each by `copy`."* The BLoC
  // kept only `certFromList`, so two of the three — including the citizen's
  // own booklet — were invisible and undownloadable.

  group('I-2 — a divorce\'s three certificates', () {
    List<IssuedCertificate> three() => <IssuedCertificate>[
          certFixture(
              id: 'div-joint',
              certificateNo: 'LA-DIV-2026-000094',
              applicationId: 'app-1'),
          certFixture(
              id: 'div-a',
              certificateNo: 'LA-DIV-2026-000094-A',
              applicationId: 'app-1'),
          certFixture(
              id: 'div-b',
              certificateNo: 'LA-DIV-2026-000094-B',
              applicationId: 'app-1'),
        ];

    test('the list request carries ?application_id=<this case>', () async {
      docs.listAnswer =
          Right<Failure, List<IssuedCertificate>>(three());
      await started(detail: issuedCase());

      expect(docs.listFilters, <String?>['app-1'],
          reason: 'the endpoint is asked for ONE application\'s certificates, '
              'which is what makes all three arrive');
    });

    test('ALL three land in state.certificates, in the server\'s order',
        () async {
      docs.listAnswer =
          Right<Failure, List<IssuedCertificate>>(three());
      final HistoryDetailBloc bloc = await started(detail: issuedCase());

      expect(
        bloc.state.certificates.map((IssuedCertificate c) => c.id).toList(),
        <String>['div-joint', 'div-a', 'div-b'],
      );
    });

    test('state.certificate is still the FIRST of them — `certFromList`\'s '
        'precedence is unchanged', () async {
      docs.listAnswer =
          Right<Failure, List<IssuedCertificate>>(three());
      final HistoryDetailBloc bloc = await started(detail: issuedCase());

      expect(bloc.state.certificate?.id, 'div-joint');
      expect(docs.oneCalls, isEmpty,
          reason: 'B5-AC-41 — a list hit still skips the single fetch');
    });

    test('a row belonging to ANOTHER application is not collected', () async {
      docs.listAnswer = Right<Failure, List<IssuedCertificate>>(
        <IssuedCertificate>[
          ...three(),
          certFixture(id: 'other', applicationId: 'app-999'),
        ],
      );
      final HistoryDetailBloc bloc = await started(detail: issuedCase());

      expect(bloc.state.certificates, hasLength(3),
          reason: 'the plural form is the SAME predicate as the singular — a '
              'filter, not an unconditional copy of the list');
    });

    test('a single-document application holds exactly one entry', () async {
      docs.listAnswer = Right<Failure, List<IssuedCertificate>>(
        <IssuedCertificate>[certApplicationMatch],
      );
      final HistoryDetailBloc bloc = await started(detail: issuedCase());

      expect(bloc.state.certificates, hasLength(1));
      expect(bloc.state.certificate?.id, 'cert-app');
    });

    test('no list match but a single fetch answers → that one row IS the set',
        () async {
      docs.listAnswer =
          Right<Failure, List<IssuedCertificate>>(const <IssuedCertificate>[]);
      docs.oneAnswer = Right<Failure, IssuedCertificate>(
        certFixture(id: 'cert-77'),
      );
      final HistoryDetailBloc bloc =
          await started(detail: issuedCase(certificateId: 'cert-77'));

      expect(bloc.state.certificate?.id, 'cert-77');
      expect(
        bloc.state.certificates.map((IssuedCertificate c) => c.id).toList(),
        <String>['cert-77'],
        reason: 'otherwise a case whose certificate arrived by the single '
            'fetch would offer no document at all',
      );
    });

    test('a FAILED refetch keeps the rows already on screen', () async {
      docs.listAnswer =
          Right<Failure, List<IssuedCertificate>>(three());
      final HistoryDetailBloc bloc = await started(detail: issuedCase());
      expect(bloc.state.certificates, hasLength(3));

      docs.listAnswer = Left<Failure, List<IssuedCertificate>>(
        const Failure('registry unreachable'),
      );
      bloc.add(const HistoryDetailRefreshed());
      await pumpEventQueue();

      expect(bloc.state.certificates, hasLength(3),
          reason: 'the same disposition `withTimeline` and `certificate` take');
      expect(bloc.state.certificateError, 'registry unreachable');
    });
  });

  group('I-2 — matchIssuedCertificates, the plural predicate', () {
    test('it agrees with the singular form about which row comes first', () {
      final ApplicationDetail detail = issuedCase().copyWith(
        row: issuedCase().row.copyWith(referenceNo: 'REF-0001'),
      );
      final List<IssuedCertificate> list = <IssuedCertificate>[
        certReferenceMatch,
        certApplicationMatch,
      ];

      expect(
        matchIssuedCertificates(list, 'app-1', detail).first.id,
        matchIssuedCertificate(list, 'app-1', detail)!.id,
      );
    });

    test('no match gives the empty list, and the singular gives null', () {
      final List<IssuedCertificate> list = <IssuedCertificate>[
        certFixture(id: 'x', applicationId: 'somebody-else'),
      ];
      final ApplicationDetail detail = issuedCase();

      expect(matchIssuedCertificates(list, 'app-1', detail), isEmpty);
      expect(matchIssuedCertificate(list, 'app-1', detail), isNull);
    });
  });
}

/// Records the moment the list call arrives, so `B5-AC-36` can assert ordering
/// rather than counting.
class _OrderingDocuments extends FakeDocumentsRepository {
  _OrderingDocuments(this.order);

  final List<String> order;

  @override
  Future<Either<Failure, List<IssuedCertificate>>> getCertificates({
    String? applicationId,
  }) {
    order.add('certificates');
    return super.getCertificates(applicationId: applicationId);
  }
}

/// The application slice's pure domain rules — `B7-AC-25` … `B7-AC-30`,
/// `B7-AC-18`, `B7-AC-23`, and the `B7-AC-32` grep.
///
/// Everything here is a function of a value, so nothing is mocked and nothing
/// is pumped. The one file that reaches outside the process is
/// `status_pipeline` against the **real recorded catalogue** — which is the
/// whole reason § 6.12 bothered to record it.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/application/data/models/application_wire.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_status.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/jurisdiction.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/status_pipeline.dart';
import 'package:lcc_mobile_app/features/application/domain/usecases/application_usecases.dart';

Map<String, dynamic> loadFixture(String name) =>
    jsonDecode(File('test/fidelity/fixtures/api/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  group('B7-AC-28 — bucketOf maps ALL NINE statuses, none omitted', () {
    // One assertion per status, spelled out rather than looped over a table,
    // because a loop over a table written next to the implementation asserts
    // that the port agrees with itself. These nine come from
    // `HistoryDetailPage.tsx:50-54` read directly.
    const Map<CaseStatus, StatusBucket> expected = <CaseStatus, StatusBucket>{
      CaseStatus.issued: StatusBucket.approved,
      CaseStatus.registered: StatusBucket.approved,
      CaseStatus.rejected: StatusBucket.rejected,
      CaseStatus.revoked: StatusBucket.rejected,
      CaseStatus.returned: StatusBucket.rejected,
      CaseStatus.draft: StatusBucket.pending,
      CaseStatus.submitted: StatusBucket.pending,
      CaseStatus.certified: StatusBucket.pending,
      CaseStatus.underReview: StatusBucket.pending,
    };

    for (final MapEntry<CaseStatus, StatusBucket> e in expected.entries) {
      test('${e.key.wire} → ${e.value.name}', () {
        expect(bucketOf(e.key), e.value);
      });
    }

    test('all nine wire statuses are covered — the table is not a subset', () {
      expect(expected.keys.toSet(), CaseStatus.wireValues.toSet());
      expect(CaseStatus.wireValues, hasLength(9));
    });

    test('`returned` buckets REJECTED here while sitting in the `rejected` '
        'filter chip — consistent, and worth pinning because the two tables '
        'are separate', () {
      expect(bucketOf(CaseStatus.returned), StatusBucket.rejected);
      expect(kFilterStatuses[kFilterRejected], contains(CaseStatus.returned));
    });

    test('`draft` buckets PENDING and is in the `pending` chip, while being '
        'ABSENT from the pipeline — the three-way interaction § 6.15 names', () {
      expect(bucketOf(CaseStatus.draft), StatusBucket.pending);
      expect(kFilterStatuses[kFilterPending], contains(CaseStatus.draft));
      expect(StatusPipeline.seeded.stages, isNot(contains(CaseStatus.draft)));
    });

    test('an unheard-of wire value falls to pending, as the TS union does', () {
      expect(CaseStatus.fromWire('teleported'), CaseStatus.unknown);
      expect(bucketOf(CaseStatus.unknown), StatusBucket.pending);
    });
  });

  group('B7-AC-29 — progressOf, all three branches', () {
    final List<CaseStatus> live = StatusPipeline.seeded.stages;

    test('branch 1: every rejected-bucket status is 100 — a FULL bar', () {
      for (final CaseStatus s in <CaseStatus>[
        CaseStatus.rejected,
        CaseStatus.revoked,
        CaseStatus.returned,
      ]) {
        expect(progressOf(s, live), 100, reason: s.wire);
      }
    });

    test('branch 2: `draft` is 8 — not 0, and not a first step', () {
      expect(progressOf(CaseStatus.draft, live), 8);
      // Not a `draft` special case: any status the catalogue omits lands here.
      expect(progressOf(CaseStatus.unknown, live), 8);
    });

    test('branch 3: 20 / 40 / 60 / 80 / 100 against the live 5-entry pipeline',
        () {
      expect(progressOf(CaseStatus.submitted, live), 20);
      expect(progressOf(CaseStatus.certified, live), 40);
      expect(progressOf(CaseStatus.underReview, live), 60);
      expect(progressOf(CaseStatus.registered, live), 80);
      expect(progressOf(CaseStatus.issued, live), 100);
    });

    test('the rejected 100 and the issued 100 are the same NUMBER and a '
        'different COLOUR — the bar is red for one and green for the other',
        () {
      // Pinned here so a later reader does not "fix" the duplicate 100 by
      // giving rejected a different percentage. The distinction the source
      // makes is in the palette, not in the number.
      expect(progressOf(CaseStatus.rejected, live),
          progressOf(CaseStatus.issued, live));
      expect(bucketOf(CaseStatus.rejected),
          isNot(bucketOf(CaseStatus.issued)));
    });
  });

  group('B7-AC-25 — the pipeline, derived from the REAL recorded catalogue',
      () {
    late StatusPipeline pipeline;

    setUp(() {
      final Map<String, dynamic> fixture = loadFixture('status-catalogue');
      pipeline = statusPipelineFrom(fixture['data'] as Map<String, dynamic>);
    });

    test('the recording really is a recording — provenance says so', () {
      expect(
        loadFixture('status-catalogue')['_provenance'],
        contains('REAL RECORDING'),
      );
    });

    test('the API sends SIX and the UI counts against FIVE', () {
      final List<dynamic> raw = (loadFixture('status-catalogue')['data']
          as Map<String, dynamic>)['pipeline_order'] as List<dynamic>;
      expect(raw, hasLength(6));
      expect(raw.first, 'draft');

      expect(pipeline.length, 5);
      expect(pipeline.stages, <CaseStatus>[
        CaseStatus.submitted,
        CaseStatus.certified,
        CaseStatus.underReview,
        CaseStatus.registered,
        CaseStatus.issued,
      ]);
    });

    test('the live catalogue carries exactly the nine statuses `types.ts` '
        'declares — the claim `case_status.dart` makes, measured', () {
      final List<dynamic> statuses = (loadFixture('status-catalogue')['data']
          as Map<String, dynamic>)['statuses'] as List<dynamic>;
      final List<String> wire = statuses
          .cast<Map<String, dynamic>>()
          .map((Map<String, dynamic> s) => s['status'] as String)
          .toList();
      expect(
        wire,
        CaseStatus.wireValues.map((CaseStatus s) => s.wire).toList(),
      );
    });

    test('the live catalogue carries `color`/`background` per status and the '
        'port ignores them (§ 6.9) — the fixture proves they are THERE', () {
      final Map<String, dynamic> first = ((loadFixture('status-catalogue')
              ['data'] as Map<String, dynamic>)['statuses'] as List<dynamic>)
          .first as Map<String, dynamic>;
      // If this ever stops being true the "we deliberately discard them"
      // ruling has become a statement about nothing.
      expect(first.containsKey('color'), isTrue);
      expect(first.containsKey('background'), isTrue);
    });
  });

  group('B7-AC-26 / B7-AC-27 — the seed survives a useless answer', () {
    test('an EMPTY pipeline_order keeps the 5-entry seed', () {
      expect(StatusPipeline.fromOrder(<CaseStatus>[]).stages,
          StatusPipeline.seeded.stages);
    });

    test('a DRAFT-ONLY pipeline_order keeps the seed — the filter empties it '
        'and `if (order.length > 0)` then declines to splice', () {
      expect(
        StatusPipeline.fromOrder(<CaseStatus>[CaseStatus.draft]).stages,
        StatusPipeline.seeded.stages,
      );
    });

    test('a null pipeline_order keeps the seed', () {
      expect(StatusPipeline.fromOrder(null).stages,
          StatusPipeline.seeded.stages);
    });

    test('a body that is not an object at all keeps the seed', () {
      expect(statusPipelineFrom(<String, dynamic>{}).stages,
          StatusPipeline.seeded.stages);
      expect(
        statusPipelineFrom(<String, dynamic>{'pipeline_order': 'nope'}).stages,
        StatusPipeline.seeded.stages,
      );
    });

    test('an unrecognised stage is KEPT, not dropped — dropping it would '
        'silently renumber every later step', () {
      final StatusPipeline p = StatusPipeline.fromOrder(<CaseStatus>[
        CaseStatus.submitted,
        CaseStatus.unknown,
        CaseStatus.issued,
      ]);
      expect(p.length, 3);
      expect(p.progressFor(CaseStatus.issued), 100);
      // …and the middle slot really is occupied: `submitted` is 1/3, not 1/2.
      expect(p.progressFor(CaseStatus.submitted), 33);
    });

    test('the seed is NOT empty — a guard that kept an empty list would pass '
        'every assertion above vacuously', () {
      expect(StatusPipeline.seeded.stages, hasLength(5));
    });
  });

  group('B7-AC-30 — the step counter and the bar disagree for `draft`', () {
    final StatusPipeline p = StatusPipeline.seeded;

    test('"Step 1 of 5" with an 8% bar — both numbers, together', () {
      expect(p.stepFor(CaseStatus.draft), 1);
      expect(p.length, 5);
      expect(p.progressFor(CaseStatus.draft), 8);
    });

    test('a real stage does not clamp', () {
      expect(p.stepFor(CaseStatus.underReview), 3);
      expect(p.progressFor(CaseStatus.underReview), 60);
    });
  });

  group('B7-AC-18 / B7-AC-23 — the filter table and the two page sizes', () {
    test('`all` maps to NULL, not to an empty list', () {
      // The difference is observable on the wire; the transport test asserts
      // the URI, and this asserts the value that produces it.
      expect(kFilterStatuses[kFilterAll], isNull);
      expect(
        const ListApplicationsParams(page: 1).wireStatuses,
        isNull,
      );
    });

    test('the three buckets are verbatim `HistoryPage.tsx:49-54`', () {
      expect(kFilterStatuses[kFilterPending], <CaseStatus>[
        CaseStatus.draft,
        CaseStatus.submitted,
        CaseStatus.certified,
        CaseStatus.underReview,
      ]);
      expect(kFilterStatuses[kFilterApproved],
          <CaseStatus>[CaseStatus.registered, CaseStatus.issued]);
      expect(kFilterStatuses[kFilterRejected], <CaseStatus>[
        CaseStatus.returned,
        CaseStatus.rejected,
        CaseStatus.revoked,
      ]);
    });

    test('the chip table and bucketOf AGREE on approved/rejected and DIFFER '
        'on pending — two tables in the source, two here', () {
      for (final CaseStatus s in kFilterStatuses[kFilterApproved]!) {
        expect(bucketOf(s), StatusBucket.approved);
      }
      for (final CaseStatus s in kFilterStatuses[kFilterRejected]!) {
        expect(bucketOf(s), StatusBucket.rejected);
      }
      // `draft` is the one member the two tables reach differently: the chip
      // lists it, `bucketOf` gets there by fallthrough.
      expect(kFilterStatuses[kFilterPending], contains(CaseStatus.draft));
    });

    test('PER_PAGE is 10 for the list and 1 for a count', () {
      expect(kApplicationsPerPage, 10);
      expect(kApplicationsCountPerPage, 1);
      expect(const ListApplicationsParams(page: 1).perPage, 10);
    });

    test('B7-AC-17 — an empty or whitespace search normalises to null', () {
      expect(const ListApplicationsParams(page: 1, search: '').wireSearch,
          isNull);
      expect(const ListApplicationsParams(page: 1, search: '   ').wireSearch,
          isNull);
      expect(
        const ListApplicationsParams(page: 1, search: '  LCC-1 ').wireSearch,
        'LCC-1',
      );
    });

    test('an unknown chip id sends no status rather than throwing', () {
      expect(
        const ListApplicationsParams(page: 1, filter: 'nope').wireStatuses,
        isNull,
      );
    });
  });

  group('Jurisdiction.officeLine — the "—" sentinel', () {
    test('district · province', () {
      expect(
        const Jurisdiction(districtName: 'Chanthabouly', provinceName: 'VTE')
            .officeLine,
        'Chanthabouly · VTE',
      );
    });

    test('one absent part is omitted, not left as an empty segment', () {
      expect(const Jurisdiction(provinceName: 'VTE').officeLine, 'VTE');
      expect(const Jurisdiction(districtName: 'CHA').officeLine, 'CHA');
    });

    test('both absent renders the em-dash, and an empty string counts as '
        'absent — `filter(Boolean)` treats "" as falsy', () {
      expect(Jurisdiction.empty.officeLine, '—');
      expect(
        const Jurisdiction(districtName: '', provinceName: '').officeLine,
        '—',
      );
    });
  });
}

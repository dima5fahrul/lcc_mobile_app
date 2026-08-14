/// The submission contract, asserted as behaviour — `F0-AC-14`…`F0-AC-20`,
/// `F0-AC-32`, `F0-AC-39`, `F0-AC-80`.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/attachment_accept_policy.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/attachment_guard.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/case_reference_binding.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/certificate_form.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/envelope_shape.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/gender_values.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/method_code_source.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_plan.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_step.dart';

void main() {
  group('F0-AC-18 — FamilyBook is excluded, mechanically', () {
    test('there are exactly five plans', () {
      expect(SubmissionPlan.all.length, 5);
    });

    test('no key names a family book', () {
      expect(
        SubmissionPlan.all.keys
            .where((String k) => k.toLowerCase().contains('family')),
        isEmpty,
      );
    });

    test('and the enum itself has no sixth member to add one from', () {
      // The exclusion is structural, not a filter applied to a longer list:
      // `all` is built from `CertificateForm.values`, so a FamilyBook plan
      // could only exist by someone adding a member — which would also break
      // `methodCodeSourceFor`'s exhaustive switch and `_of`'s.
      expect(CertificateForm.values.length, 5);
    });
  });

  group('F0-AC-14 — CaseReferenceBinding has exactly two inhabitants, and '
      'they differ in TWO ways', () {
    const CaseReferenceBinding flat =
        CaseReferenceBinding.flatAppended('header.ref_no');
    const CaseReferenceBinding nested =
        CaseReferenceBinding.nestedParameter(<String>['header', 'document_no']);

    test('(a) flatAppended turns a 3-key map into 4, with the new key LAST',
        () {
      final Map<String, Object?> body = <String, Object?>{
        'a': '1',
        'b': '2',
        'c': '3',
      };
      final Map<String, Object?> out =
          (flat as FlatAppendedReference).appendTo(body, 'REF-9');

      expect(out.keys.toList(), <String>['a', 'b', 'c', 'header.ref_no']);
      expect(out.length, 4);
      expect(out['header.ref_no'], 'REF-9');
      // The input is not mutated — the source spreads rather than assigns.
      expect(body.length, 3);
    });

    test('(a) nestedParameter yields 3 keys in the SAME order, one value '
        'changed', () {
      final Map<String, Object?> body = <String, Object?>{
        'header': <String, Object?>{'document_no': '', 'dated': '2026-08-14'},
        'b': '2',
        'c': '3',
      };
      final Map<String, Object?> out =
          (nested as NestedParameterReference).writeInto(body, 'REF-9');

      expect(out.keys.toList(), <String>['header', 'b', 'c']);
      expect(out.length, 3);
      final Map<String, Object?> header = out['header']! as Map<String, Object?>;
      // Key count AND order unchanged at the nested level too.
      expect(header.keys.toList(), <String>['document_no', 'dated']);
      expect(header['document_no'], 'REF-9');
    });

    test('(a) and a missing nested leaf THROWS rather than appending one', () {
      // Creating the leaf would silently convert a nested binding into a flat
      // one — the exact distinction Tier 0 compares bytes to catch.
      expect(
        () => (nested as NestedParameterReference)
            .writeInto(<String, Object?>{'b': '2'}, 'REF-9'),
        throwsArgumentError,
      );
      expect(
        () => (nested as NestedParameterReference).writeInto(
          <String, Object?>{'header': <String, Object?>{'dated': 'x'}},
          'REF-9',
        ),
        throwsArgumentError,
      );
    });

    test('(b) nested invokes its builder TWICE, flat ONCE', () {
      int flatCalls = 0;
      int nestedCalls = 0;

      final SubmissionBodies flatBodies = flat.bodies((String ref) {
        flatCalls++;
        return <String, Object?>{'x': '1'};
      }, 'REF-9');

      final SubmissionBodies nestedBodies = nested.bodies((String ref) {
        nestedCalls++;
        return <String, Object?>{
          'header': <String, Object?>{'document_no': ref},
        };
      }, 'REF-9');

      expect(flatCalls, 1, reason: 'ResidentCertificatePage.tsx:501 — one '
          '`buildFormData()`, spread into the update body at :522');
      expect(nestedCalls, 2, reason: 'MarriageCertificatePage.tsx:964 and :981 '
          '— two invocations, each re-evaluating today() at :900');

      // …and the two invocations really did produce two different bodies.
      expect(
        (nestedBodies.create['header']! as Map<String, Object?>)['document_no'],
        '',
      );
      expect(
        (nestedBodies.update['header']! as Map<String, Object?>)['document_no'],
        'REF-9',
      );
      expect(flatBodies.update['header.ref_no'], 'REF-9');
    });

    test('(b) is what makes a midnight boundary observable', () {
      // The reason the invocation count is contract and not trivia: a builder
      // that reads a clock produces two DIFFERENT dates across midnight on the
      // nested family and one date on the flat family. Modelled with a counter
      // standing in for the clock.
      int tick = 0;
      String clock() => tick++ == 0 ? '2026-08-13' : '2026-08-14';

      final SubmissionBodies flatB = flat.bodies(
        (String _) => <String, Object?>{'dated': clock()},
        'R',
      );
      expect(flatB.create['dated'], flatB.update['dated'],
          reason: 'one invocation — the two bodies cannot disagree');

      tick = 0;
      final SubmissionBodies nestedB = nested.bodies(
        (String ref) => <String, Object?>{
          'dated': clock(),
          'header': <String, Object?>{'document_no': ref},
        },
        'R',
      );
      expect(nestedB.create['dated'], isNot(nestedB.update['dated']),
          reason: 'two invocations — and that is the source behaviour, not a '
              'defect to tidy away');
    });

    test('pointer distinguishes the flat literal key from the nested path', () {
      // Marriage flattens to the byte-identical string Birth emits as a
      // literal flat key. Mutant M5 is exactly this.
      expect(flat.pointer, '/header.ref_no');
      expect(
        const CaseReferenceBinding.flatAppended('header.document_no').pointer,
        '/header.document_no',
      );
      expect(nested.pointer, '/header/document_no');
    });
  });

  group('F0-AC-15 — key order survives serialisation', () {
    /// A 20-key map, transcribed in a deliberate non-alphabetical order.
    Map<String, Object?> twentyKeys() => <String, Object?>{
          'service_code': 'resident',
          'header.ref_no': 'R-1',
          'header.dated': '2026-08-14',
          'applicant.citizen_name': 'A',
          'applicant.age': '34',
          'applicant.nationality': 'lao',
          'applicant.gender': 'female',
          'applicant.uin': 'U-1',
          'purpose.purpose': 'travel',
          'purpose.issue_date': '2026-08-14',
          'address.province': 'P',
          'address.district': 'D',
          'address.village': 'V',
          'contact.phone': '2000',
          'contact.email': 'a@b.c',
          'office.status': 'OFFICE_DEFERRED',
          'office.signature': 'captured-at-office',
          'meta.a': '1',
          'meta.b': '2',
          'meta.c': '3',
        };

    List<String> keySequenceOf(String json) =>
        RegExp(r'"([^"]+)":').allMatches(json).map((Match m) => m.group(1)!).toList();

    test('the emitted key sequence equals the declared path list exactly', () {
      final Map<String, Object?> map = twentyKeys();
      expect(keySequenceOf(jsonEncode(map)), map.keys.toList());
      expect(map.keys, hasLength(20));
    });

    test('and it FAILS when two keys are swapped in the source map', () {
      final List<String> declared = twentyKeys().keys.toList();

      final Map<String, Object?> swapped = <String, Object?>{};
      final Map<String, Object?> original = twentyKeys();
      final List<String> order = original.keys.toList();
      final String tmp = order[3];
      order[3] = order[4];
      order[4] = tmp;
      for (final String k in order) {
        swapped[k] = original[k];
      }

      expect(keySequenceOf(jsonEncode(swapped)), isNot(declared));
      // …while a decoded-map comparison would NOT catch it, which is why Tier 0
      // compares the serialised string.
      expect(jsonDecode(jsonEncode(swapped)), jsonDecode(jsonEncode(original)));
    });
  });

  group('F0-AC-19 / F0-AC-80 — the ten envelopes', () {
    test('all ten inhabitants exist', () {
      expect(SubmissionPlan.all.values.map((SubmissionPlan p) => p.createEnvelope),
          hasLength(5));
      expect(SubmissionPlan.all.values.map((SubmissionPlan p) => p.updateEnvelope),
          hasLength(5));
    });

    test('F0-AC-80 — every update envelope is [form_data, event_date], '
        'form_data FIRST', () {
      for (final SubmissionPlan p in SubmissionPlan.all.values) {
        expect(p.updateEnvelope.names, <String>['form_data', 'event_date'],
            reason: '${p.form.serviceCode} update envelope');
      }
    });

    test('F0-AC-80 — while every create envelope puts form_data LAST, and the '
        'two orders are NOT equal', () {
      for (final SubmissionPlan p in SubmissionPlan.all.values) {
        expect(p.createEnvelope.names.last, 'form_data',
            reason: '${p.form.serviceCode} create envelope');
        expect(p.createEnvelope.names, isNot(p.updateEnvelope.names));
      }
    });

    test('F0-AC-19 — the optional set is FIVE key names, not three', () {
      final Set<String> optional = <String>{
        for (final SubmissionPlan p in SubmissionPlan.all.values) ...<String>[
          ...p.createEnvelope.optionalKeys.map((EnvelopeKey k) => k.name),
          ...p.updateEnvelope.optionalKeys.map((EnvelopeKey k) => k.name),
        ],
      };
      expect(optional, <String>{
        'province_id',
        'district_id',
        'village_id',
        'event_date',
        'linked_reference_no',
      });
    });

    test("F0-AC-19 — absent is not '' : Marriage's province_id is "
        "present-and-empty where Resident's is elided", () {
      final EnvelopeShape resident =
          SubmissionPlan.all['resident']!.createEnvelope;
      final EnvelopeShape marriage =
          SubmissionPlan.all['marriage']!.createEnvelope;

      expect(resident['province_id'].optional, isTrue);
      expect(resident['province_id'].whenEmpty, WhenEmpty.elided,
          reason: 'ResidentCertificatePage.tsx:509 `form.province || undefined`');

      expect(marriage['province_id'].optional, isFalse,
          reason: 'MarriageCertificatePage.tsx:959 `header.provinceId` — a raw '
              'value, so a blank province is present-and-empty');

      // Same key name, two different bodies. A `Map<String, bool>` over key
      // names could not hold both answers at once.
      expect(resident['province_id'].optional,
          isNot(marriage['province_id'].optional));
    });

    test("F0-AC-19 — event_date is elidable on the nested family only", () {
      for (final String flat in <String>['resident', 'birth', 'death']) {
        expect(SubmissionPlan.all[flat]!.createEnvelope['event_date'].optional,
            isFalse,
            reason: '$flat writes `x.dob || today()` — always present');
      }
      for (final String nested in <String>['marriage', 'divorce']) {
        expect(SubmissionPlan.all[nested]!.createEnvelope['event_date'].optional,
            isTrue);
        expect(SubmissionPlan.all[nested]!.updateEnvelope['event_date'].optional,
            isTrue);
      }
    });

    test('F0-AC-79 — linked_reference_no sits BETWEEN event_date and '
        'form_data, on the nested family only', () {
      for (final String nested in <String>['marriage', 'divorce']) {
        final List<String> keys =
            SubmissionPlan.all[nested]!.createEnvelope.names;
        final int event = keys.indexOf('event_date');
        final int linked = keys.indexOf('linked_reference_no');
        final int form = keys.indexOf('form_data');
        expect(linked, event + 1, reason: '$nested: immediately after event_date');
        expect(form, linked + 1, reason: '$nested: immediately before form_data');
        expect(
          SubmissionPlan.all[nested]!.createEnvelope['linked_reference_no']
              .whenEmpty,
          WhenEmpty.elided,
        );
      }
      for (final String other in <String>['resident', 'birth', 'death']) {
        expect(
          SubmissionPlan.all[other]!.createEnvelope.contains(
            'linked_reference_no',
          ),
          isFalse,
        );
        expect(
          SubmissionPlan.all[other]!.updateEnvelope.contains(
            'linked_reference_no',
          ),
          isFalse,
        );
      }
    });

    test('appending linked_reference_no AFTER form_data is a different byte '
        'sequence with the same decoded map', () {
      // `F0-AC-79`'s "must FAIL" clause, expressed on the shape rather than on
      // the oracle: the two serialise differently and decode identically.
      final List<String> correct =
          SubmissionPlan.all['marriage']!.createEnvelope.names;
      final List<String> moved = <String>[
        ...correct.where((String k) => k != 'linked_reference_no'),
        'linked_reference_no',
      ];

      Map<String, Object?> bodyOf(List<String> keys) => <String, Object?>{
            for (final String k in keys) k: k == 'form_data' ? <String, Object?>{} : k,
          };

      expect(jsonEncode(bodyOf(correct)), isNot(jsonEncode(bodyOf(moved))));
      expect(jsonDecode(jsonEncode(bodyOf(correct))),
          jsonDecode(jsonEncode(bodyOf(moved))));
    });
  });

  group('F0-AC-32 — MethodCodeSource cannot be defaulted wrong', () {
    test('the registry has five entries, split 3 liveList / 2 staticMap', () {
      final Map<CertificateForm, MethodCodeSource> registry =
          <CertificateForm, MethodCodeSource>{
        for (final CertificateForm f in CertificateForm.values)
          f: methodCodeSourceFor(f),
      };

      expect(registry.length, 5);
      expect(
        registry.values.where((MethodCodeSource s) => s == MethodCodeSource.liveList),
        hasLength(3),
      );
      expect(
        registry.values.where((MethodCodeSource s) => s == MethodCodeSource.staticMap),
        hasLength(2),
      );
      expect(registry[CertificateForm.marriage], MethodCodeSource.staticMap);
      expect(registry[CertificateForm.divorce], MethodCodeSource.staticMap);
    });

    test('every decision carries a file:line', () {
      expect(kMethodCodeSourceSrc.keys.toSet(), CertificateForm.values.toSet());
      for (final String src in kMethodCodeSourceSrc.values) {
        expect(src, matches(RegExp(r'^[A-Za-z]+\.tsx:\d+(-\d+)?$')));
      }
    });

    test('the enum has no default value', () {
      // `MethodCodeSource` is a bare enum with two members and no `unknown` /
      // `none` / first-is-default escape. A page with no entry in the registry
      // is a compile error in `methodCodeSourceFor`, not a silent fallback.
      expect(MethodCodeSource.values,
          <MethodCodeSource>[MethodCodeSource.liveList, MethodCodeSource.staticMap]);
    });

    test('and the plan agrees with the registry', () {
      for (final CertificateForm f in CertificateForm.values) {
        expect(SubmissionPlan.forForm(f).methodCode, methodCodeSourceFor(f));
      }
    });
  });

  group('the five plans, as measured', () {
    test('steps: the flat family updates before it attaches, the nested family '
        'attaches before it updates', () {
      expect(SubmissionPlan.all['resident']!.steps, <SubmissionStep>[
        SubmissionStep.create,
        SubmissionStep.update,
        SubmissionStep.attach,
        SubmissionStep.submit,
        SubmissionStep.pay,
      ]);
      expect(SubmissionPlan.all['marriage']!.steps, <SubmissionStep>[
        SubmissionStep.create,
        SubmissionStep.attach,
        SubmissionStep.update,
        SubmissionStep.submit,
        SubmissionStep.pay,
      ]);
    });

    test('Birth and Death END AT SUBMIT — payment is a separate mutation', () {
      for (final String flat in <String>['birth', 'death']) {
        expect(SubmissionPlan.all[flat]!.steps.contains(SubmissionStep.pay),
            isFalse,
            reason: '$flat: `payCase` is triggered by the review step, not by '
                '`submitCase`');
      }
      for (final String pays in <String>['resident', 'marriage', 'divorce']) {
        expect(SubmissionPlan.all[pays]!.steps.last, SubmissionStep.pay);
      }
    });

    test('attachment guards: three slotKeyed, two singleFlag', () {
      expect(
        SubmissionPlan.all.values
            .where((SubmissionPlan p) => p.attachmentGuard == AttachmentGuard.slotKeyed),
        hasLength(3),
      );
      expect(
        SubmissionPlan.all.values
            .where((SubmissionPlan p) => p.attachmentGuard == AttachmentGuard.singleFlag),
        hasLength(2),
      );
      // `none` has no inhabitant — no page in the plan is attachment-free.
      expect(
        SubmissionPlan.all.values
            .where((SubmissionPlan p) => p.attachmentGuard == AttachmentGuard.none),
        isEmpty,
      );
    });

    test('reference bindings: three flat, two nested — and Resident is the '
        'only ref_no', () {
      expect(
        SubmissionPlan.all.values
            .where((SubmissionPlan p) => p.reference is FlatAppendedReference),
        hasLength(3),
      );
      expect(
        SubmissionPlan.all.values
            .where((SubmissionPlan p) => p.reference is NestedParameterReference),
        hasLength(2),
      );
      expect(
        (SubmissionPlan.all['resident']!.reference as FlatAppendedReference).key,
        'header.ref_no',
      );
      for (final String doc in <String>['birth', 'death']) {
        expect(
          (SubmissionPlan.all[doc]!.reference as FlatAppendedReference).key,
          'header.document_no',
        );
      }
    });

    test('every plan records its retry citation', () {
      for (final SubmissionPlan p in SubmissionPlan.all.values) {
        expect(p.stepsSrc, contains('retry skips create at'));
        expect(p.stepsSrc, contains('builder invocation'));
      }
    });
  });

  group('F0-AC-39 — AttachmentAcceptPolicy', () {
    test('holds the five verbatim strings, and no sixth normalised value', () {
      expect(AttachmentAcceptPolicy.byForm.length, 5);
      expect(AttachmentAcceptPolicy.byForm.values.toSet(), <String>{
        'image/*',
        'image/*,application/pdf',
        'image/*,.pdf',
      });
      // Three spellings, five pages — deliberately not collapsed.
      expect(AttachmentAcceptPolicy.resident, 'image/*');
      expect(AttachmentAcceptPolicy.birth, 'image/*,application/pdf');
      expect(AttachmentAcceptPolicy.death, 'image/*,application/pdf');
      expect(AttachmentAcceptPolicy.marriage, 'image/*,.pdf');
      expect(AttachmentAcceptPolicy.divorce, 'image/*,.pdf');
    });

    test('every value carries a file:line', () {
      expect(AttachmentAcceptPolicy.srcByForm.keys.toSet(),
          AttachmentAcceptPolicy.byForm.keys.toSet());
      for (final String src in AttachmentAcceptPolicy.srcByForm.values) {
        expect(src, matches(RegExp(r'^[A-Za-z]+\.tsx:\d+$')));
      }
    });
  });

  test('D-S — the two gender WIRE VALUES and their order are shared; the '
      'labels are not', () {
    expect(kGenderWireValues, <String>['female', 'male']);
    expect(kGenderWireValuesSrc, hasLength(3),
        reason: 'three option lists — FamilyBook`s GENDER_KEY is a four-key '
            'reverse display map, not an option list, so it is not a member');
  });
}

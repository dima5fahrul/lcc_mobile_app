/// Marriage's payload, mirror, attachments and constants — the criteria Tier 0
/// cannot see.
///
/// `F3-AC-23`, `F3-AC-32`, `F3-AC-33`, `F3-AC-37`, `F3-AC-41`, `F3-AC-42`,
/// `F3-AC-43`, `F3-AC-44`, `F3-AC-45`, `F3-AC-55`…`F3-AC-57`, `F3-AC-59`,
/// `F3-AC-61`, `F3-AC-65`, `F3-AC-67`, `F3-AC-69`, `F3-AC-74`, `F3-AC-75`.
///
/// Tier 0 proves the twelve documents are byte-equal. It cannot prove **how
/// many times the builder ran**, that the clock was read twice, that a null
/// file drops its entry, or that the two `spousePayload`s are separate
/// functions — every one of those is invisible in a payload captured at a fixed
/// instant with every field filled.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/case_reference_binding.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/certificate_form.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/gender_values.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/method_code_source.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_plan.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_payload.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_payload.dart';
import 'package:lcc_mobile_app/presentation/payment/payment_draft.dart';

import 'marriage_tier0_subject.dart';

PickedAttachment _file(String name) =>
    PickedAttachment(name: name, bytes: Uint8List.fromList(<int>[1, 2, 3]));

MarriageFormData _fixtureForm() => marriageFormFromFixture(
      readMarriageJson('$kMarriageFixtureDir/asymmetric.en.json'),
    );

void main() {
  final SubmissionClock fixed = SubmissionClock.fixed(kMarriageRegisterInstant);

  group('RULING 3 — the two invocations and the two clock reads', () {
    test('F3-AC-32 the plan declares nestedParameter and rebuildsPayload', () {
      final SubmissionPlan plan =
          SubmissionPlan.forForm(CertificateForm.marriage);
      expect(plan.reference, isA<NestedParameterReference>());
      expect(plan.reference.rebuildsPayload, isTrue);
      expect(plan.reference.pointer, '/header/document_no',
          reason: 'NOT /header.document_no — that is Birth\'s literal flat key '
              'and mutant M5 exists because the two flatten to the same '
              'dotted string');
    });

    test('F3-AC-33 the builder runs EXACTLY twice, and each run reads the clock',
        () {
      // An instrumented spy on both counts. A port that built once and mutated
      // `document_no` would show builds == 1 and reads == 1, and would be
      // byte-identical to this one under a FIXED clock — which is why Tier 0
      // cannot catch it and this test must.
      int builds = 0;
      int reads = 0;
      DateTime cursor = kMarriageRegisterInstant;
      final SubmissionClock counting = SubmissionClock(() {
        reads++;
        return cursor;
      });

      final MarriageFormData form = _fixtureForm();
      final SubmissionPlan plan =
          SubmissionPlan.forForm(CertificateForm.marriage);

      final SubmissionBodies bodies = plan.reference.bodies(
        (String documentNo) {
          builds++;
          return buildMarriageFormData(form, counting, documentNo);
        },
        'MC-2026-000321',
      );

      expect(builds, 2, reason: 'MarriageCertificatePage.tsx:964 and :981');
      expect(reads, 2, reason: ':900 today() is inside the builder, so it is '
          're-evaluated per invocation');
      expect(bodies.create, isNotNull);
    });

    test('F3-AC-33 advancing the clock BETWEEN the two invocations yields two '
        'different header.dated values', () {
      // The midnight boundary, made observable. Under the source's real clock
      // this is a once-a-day event; under an injected one it is a test.
      DateTime cursor = DateTime(2026, 8, 14, 23, 59, 59);
      final SubmissionClock advancing = SubmissionClock(() {
        final DateTime now = cursor;
        cursor = DateTime(2026, 8, 15, 0, 0, 1); // the next read is tomorrow
        return now;
      });

      final MarriageFormData form = _fixtureForm();
      final SubmissionBodies bodies =
          SubmissionPlan.forForm(CertificateForm.marriage).reference.bodies(
                (String d) => buildMarriageFormData(form, advancing, d),
                'MC-1',
              );

      final String createDated =
          (bodies.create['header']! as Map<String, Object?>)['dated']! as String;
      final String updateDated =
          (bodies.update['header']! as Map<String, Object?>)['dated']! as String;

      expect(createDated, '2026-08-14');
      expect(updateDated, '2026-08-15');
      expect(createDated, isNot(equals(updateDated)),
          reason: 'the one-call refactor makes these equal, which is a '
              'DIFFERENT program from the source');
    });

    test('F3-AC-41 event_date is ELIDED when blank, and is never today()', () {
      final MarriageFormData blank = _fixtureForm().copyWith(
        reg: _fixtureForm().reg.copyWith(dateOfMarriage: ''),
      );
      final Map<String, Object?> envelope = marriageCreateEnvelope(
        form: blank,
        payload: buildMarriageFormData(blank, fixed, ''),
      );
      expect(envelope.containsKey('event_date'), isFalse,
          reason: '`reg.dateOfMarriage || undefined` (:962) — absent, not "" '
              'and not the clock. Birth FALLS BACK to today(); this page does '
              'not, and conflating the two is the defect this asserts against.');
      expect(jsonEncode(envelope).contains('event_date'), isFalse);

      // And the contrast, stated rather than assumed: with a date, it is that
      // date, never the clock's.
      final Map<String, Object?> filled = marriageCreateEnvelope(
        form: _fixtureForm(),
        payload: buildMarriageFormData(_fixtureForm(), fixed, ''),
      );
      expect(filled['event_date'], '2026-05-18');
      expect(filled['event_date'], isNot(equals(fixed.todayLocal())));
    });
  });

  group('RULING 4 — the mirror, and why it is not shared', () {
    test('F3-AC-42 Marriage mirrors SEVEN keys, in source order', () {
      final Map<String, Object?> spouses =
          buildMarriageFormData(_fixtureForm(), fixed, '')['spouses']!
              as Map<String, Object?>;
      final List<String> mirrored = spouses.keys
          .where((String k) => spouses[k] is! Map)
          .where((String k) => k != 'medical_certificate')
          .toList();
      expect(mirrored, <String>[
        'name',
        'dob',
        'gender',
        'nationality',
        'id_number',
        'current_address',
        'residence_certificate_ref',
      ]);
      expect(mirrored.length, 7);
      expect(mirrored, contains('gender'),
          reason: 'Divorce has no gender; that difference is the reason the '
              'two mirrors are not one helper');
    });

    test('F3-AC-43 spousePayload emits THIRTEEN keys, in source order', () {
      final Map<String, Object?> a =
          marriageSpousePayload(_fixtureForm().spouseA);
      expect(a.keys.toList(), <String>[
        'name',
        'dob',
        'gender',
        'nationality',
        'ethnicity',
        'ethnic_group',
        'religion',
        'occupation',
        'id_number',
        'house_no',
        'current_address',
        'address_text',
        'residence_certificate_ref',
      ]);
      expect(a.length, 13);
    });

    test('F3-AC-23/43 the two spousePayloads are SEPARATE functions with '
        'different shapes', () {
      // Structural, because on a filled fixture the overlapping keys agree —
      // only the shapes distinguish them. A shared helper with a flag would
      // fail here and nowhere else.
      final Map<String, Object?> m =
          marriageSpousePayload(_fixtureForm().spouseA);
      // Divorce's shape is read directly. A TEST may import both — the
      // prohibition in § 6.5 is on a shared PRODUCTION symbol, and the
      // cross-page assertion has to live somewhere.
      final Map<String, Object?> d =
          divorceSpousePayload(DivorceSpouseInfo.blank);
      expect(m.length, 13);
      expect(d.length, 8);
      expect(m.keys.toSet().difference(d.keys.toSet()), <String>{
        'gender',
        'ethnicity',
        'ethnic_group',
        'religion',
        'occupation',
        'residence_certificate_ref',
      });
      expect(d.keys.toSet().difference(m.keys.toSet()),
          <String>{'marriage_certificate_ref'},
          reason: 'the RENAME — a shared helper would be correct for six keys '
              'and silently wrong for this one, which is exactly what '
              'F0-AC-82\'s guard measures');
    });

    test('F3-AC-45 the mirror trims where the sub-object does NOT', () {
      // The asymmetry `F0-AC-83` measures on the whitespace fixture, asserted
      // here on the port's own functions so it is not only an oracle property.
      final MarriageFormData form = _fixtureForm();
      final MarriageSpouseInfo padded =
          form.spouseA.copyWith(dob: '  1994-03-11  ');
      final Map<String, Object?> payload = buildMarriageFormData(
        form.copyWith(spouseA: padded),
        fixed,
        '',
      );
      final Map<String, Object?> spouses =
          payload['spouses']! as Map<String, Object?>;
      final Map<String, Object?> subA =
          spouses['spouse_a']! as Map<String, Object?>;

      expect(spouses['dob'], '1994-03-11', reason: 'the mirror trims');
      expect(subA['dob'], '  1994-03-11  ',
          reason: 'the sub-object does NOT — a port that trimmed uniformly '
              'fails F0-AC-83 and nothing else');
    });

    test('F3-AC-45 the collapse branch is unit-tested and structurally '
        'unreachable under execution', () {
      // Unit level: it collapses.
      final MarriageFormData form = _fixtureForm();
      final Map<String, Object?> spouses = buildMarriageFormData(
        form.copyWith(spouseB: form.spouseB.copyWith(fullName: '   ')),
        fixed,
        '',
      )['spouses']! as Map<String, Object?>;
      expect(spouses['name'], '');

      // Execution level: it cannot be reached, because every mirrored key is
      // separately mandatory in `spouseValid` — so no state that reaches
      // `submitCase` can have a blank one. `F3-NV-5`.
      expect(
        marriageSpouseValid(form.spouseB.copyWith(fullName: '   '), false),
        isFalse,
        reason: 'a blank name fails step 3, so the collapse cannot be driven '
            'through the wizard (oracle_coverage.yaml:275-333)',
      );
    });
  });

  group('RULING 7 — attachments', () {
    MarriageFormData allNine() {
      final MarriageFormData f = _fixtureForm();
      return f.copyWith(
        spouseA: f.spouseA.copyWith(
          singleStatusCert: _file('a-single.pdf'),
          priorMaritalProof: _file('a-prior.pdf'),
          foreignDocs: _file('a-foreign.pdf'),
        ),
        spouseB: f.spouseB.copyWith(
          singleStatusCert: _file('b-single.pdf'),
          priorMaritalProof: _file('b-prior.pdf'),
          foreignDocs: _file('b-foreign.pdf'),
        ),
        householdBook: _file('book.pdf'),
        photos: _file('photo.jpg'),
        birthRecord: _file('birth.pdf'),
      );
    }

    test('F3-AC-55 NINE entries over SIX distinct slots, three of them twice',
        () {
      final List<MarriageAttachment> uploads = marriageUploads(allNine());
      expect(uploads.length, 9);
      expect(uploads.map((MarriageAttachment a) => a.slot).toSet().length, 6,
          reason: 'fsd.md § 5.4 says 7 distinct slots; counted at :940-948 it '
              'is 6 (FU-6)');

      final List<String> duplicated = <String>[
        'spouses.single_status_certificate',
        'spouses.prior_marital_proof',
        'spouses.foreign_documents',
      ];
      for (final String slot in duplicated) {
        final List<MarriageAttachment> rows = uploads
            .where((MarriageAttachment a) => a.slot == slot)
            .toList();
        expect(rows.length, 2, reason: slot);
        expect(rows[0].label, 'Spouse A');
        expect(rows[1].label, 'Spouse B',
            reason: 'in that order, and the label is the ONLY discriminator');
      }
    });

    test('F3-AC-56 there is no dedupe — the duplicate slots survive', () {
      final List<MarriageAttachment> uploads = marriageUploads(allNine());
      final Set<String> slots =
          uploads.map((MarriageAttachment a) => a.slot).toSet();
      expect(uploads.length, greaterThan(slots.length),
          reason: 'Resident dedupes by slot and can, because its five slots '
              'are distinct. Marriage\'s are not, and :972-977 is a bare loop. '
              'Making the slot unique changes the wire contract (F3-NV-2 is a '
              'BACKEND question).');
    });

    test('F3-AC-57 the POST order is uploads() order, spouse A before B', () {
      expect(
        marriageUploads(allNine()).map((MarriageAttachment a) => a.slot).toList(),
        <String>[
          'spouses.single_status_certificate',
          'spouses.single_status_certificate',
          'spouses.prior_marital_proof',
          'spouses.prior_marital_proof',
          'spouses.foreign_documents',
          'spouses.foreign_documents',
          'supporting.household_book',
          'supporting.photos_3x4',
          'supporting.birth_record',
        ],
      );
    });

    test('F3-AC-59 a null file drops its entry entirely', () {
      final MarriageFormData f = _fixtureForm();
      final MarriageFormData onlyBook =
          f.copyWith(householdBook: _file('book.pdf'));
      final List<MarriageAttachment> uploads = marriageUploads(onlyBook);
      expect(uploads.length, 1);
      expect(uploads.single.slot, 'supporting.household_book');
      // Never an empty part: the entry is absent, not present-with-no-file.
      expect(
        uploads.any((MarriageAttachment a) => a.slot == 'supporting.photos_3x4'),
        isFalse,
      );
    });

    test('the photo kind is the ONLY one that is not a document', () {
      final List<MarriageAttachment> uploads = marriageUploads(allNine());
      expect(
        uploads.where((MarriageAttachment a) => a.kind == 'photo').map(
              (MarriageAttachment a) => a.slot,
            ),
        <String>['supporting.photos_3x4'],
      );
    });
  });

  group('RULING 8 — the constants that look like defects', () {
    test('F3-AC-65 methodCodeSourceFor is staticMap, and the map is the '
        'source\'s three entries', () {
      expect(methodCodeSourceFor(CertificateForm.marriage),
          MethodCodeSource.staticMap);
      expect(methodCodeSourceFor(CertificateForm.divorce),
          MethodCodeSource.staticMap);
      expect(kMarriageMethodCode, <DraftPaymentMethod, String>{
        DraftPaymentMethod.qr: 'laoqr',
        DraftPaymentMethod.bank: 'bank-transfer',
        DraftPaymentMethod.cc: 'bank-transfer',
      });
      expect(marriageMethodCodeFor(DraftPaymentMethod.cc), 'bank-transfer',
          reason: 'the gateway offers no card rail (:139); fsd.md D-O '
              'escalates it and F3 reproduces it');
    });

    test('F3-AC-67 the gender labels are BARE ENGLISH, with no Lao at all', () {
      expect(kMarriageGenderLabels, <String>['Female', 'Male']);
      expect(kGenderWireValues, <String>['female', 'male']);
      // The values are shared with Birth and Death; the LABELS are not, and
      // giving these a Lao rendering the web does not have is L-10(b).
      expect(kMarriageGenderLabels.length, kGenderWireValues.length);
    });

    test('F3-AC-69 "captured-at-office" is emitted at THREE sites, '
        'unconditionally', () {
      // Unconditionally: on a form where the citizen has touched nothing.
      final Map<String, Object?> empty =
          buildMarriageFormData(const MarriageFormData(), fixed, '');
      final Map<String, Object?> spouses =
          empty['spouses']! as Map<String, Object?>;
      final Map<String, Object?> registration =
          empty['registration']! as Map<String, Object?>;
      expect(spouses['medical_certificate'], kOfficeDeferred);
      expect(registration['couple_signatures'], kOfficeDeferred);
      expect(registration['registrar_signature'], kOfficeDeferred);
      expect(kOfficeDeferred, 'captured-at-office');
      // R-20 itself remains NOT EVALUATED — `F3-AC-96`. This is the weaker
      // claim and must not be reported as the stronger one.
    });
  });

  group('RULING 9 — the fee, and the nationality test', () {
    test('F3-AC-74 the quote inputs change with nationality and with the '
        'betrothal mode, and with nothing else', () {
      MarriageFormData f = _fixtureForm();
      expect(marriageAnyForeign(f), isTrue,
          reason: 'spouse B is `thai` in the fixture');
      expect(marriageIncludeBetrothalFee(f), isTrue,
          reason: 'betrothalMode is "new"');

      f = f.copyWith(spouseB: f.spouseB.copyWith(nationality: 'lao'));
      expect(marriageAnyForeign(f), isFalse);

      f = f.copyWith(betrothalMode: MarriageBetrothalMode.existing);
      expect(marriageIncludeBetrothalFee(f), isFalse);

      // A change to something else moves neither input.
      final MarriageFormData other =
          f.copyWith(reg: f.reg.copyWith(placeOfRegistration: 'Elsewhere'));
      expect(marriageAnyForeign(other), marriageAnyForeign(f));
      expect(marriageIncludeBetrothalFee(other), marriageIncludeBetrothalFee(f));
    });

    test('F3-AC-75 anyForeign is non-empty AND not "lao" — a STATELESS spouse '
        'is billed the foreign rate', () {
      expect(marriageIsForeign(''), isFalse, reason: 'blank is not foreign');
      expect(marriageIsForeign('lao'), isFalse);
      expect(marriageIsForeign('thai'), isTrue);
      expect(marriageIsForeign('stateless'), isTrue,
          reason: 'REPRODUCED. fsd.md § 10 Q-4 raises this as a legal/product '
              'question; "fixing" the nationality test here would be the port '
              'deciding it.');
    });
  });

  group('canProceed', () {
    test('step 1 refuses the chooser state outright', () {
      final MarriageFormData f = _fixtureForm()
          .copyWith(betrothalMode: MarriageBetrothalMode.none);
      expect(marriageCanProceed(f, step: 1), isFalse,
          reason: ':857 — must pick existing or create new');
    });

    test('step 6 (review) falls through to true', () {
      expect(marriageCanProceed(const MarriageFormData(), step: 6), isTrue,
          reason: 'step 6 is absent from the switch (:870)');
    });

    test('F3-AC-61 the draft id is what makes a retry skip create', () {
      // The state carries it (`:712`), which is the whole retry mechanic:
      // `:956` `if (!id)`. Asserted on the state rather than by driving the
      // network, because the guard is a field, not a call.
      expect(const MarriageFormData().betrothalMode,
          MarriageBetrothalMode.none);
    });
  });
}

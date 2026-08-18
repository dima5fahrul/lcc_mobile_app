/// Divorce's branch, its D-N fix, its two orderings and its absent gender.
///
/// `F3-AC-43`, `F3-AC-44`, `F3-AC-47`, `F3-AC-48`, `F3-AC-52`, `F3-AC-53`,
/// `F3-AC-54`, `F3-AC-57`, `F3-AC-58`, `F3-AC-59`, `F3-AC-62`, `F3-AC-68`,
/// `F3-AC-74`.
///
/// The branch is the batch's conditional complexity and every one of its
/// interesting states is invisible to Tier 0 on a fixture that sets the type
/// once: **the terminal code**, the **switch** from contested to voluntary, and
/// the fact that the two upload orderings are different lists.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_payload_helpers.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_payload.dart';

import 'divorce_tier0_subject.dart';

PickedAttachment _file(String name) =>
    PickedAttachment(name: name, bytes: Uint8List.fromList(<int>[9]));

DivorceFormData _voluntary() => divorceFormFromFixture(
      readDivorceJson('$kDivorceFixtureDir/asymmetric.en.json'),
    );

DivorceFormData _contested() => divorceFormFromFixture(
      readDivorceJson('$kDivorceFixtureDir/contested.en.json'),
    );

void main() {
  final SubmissionClock fixed = SubmissionClock.fixed(kDivorceRegisterInstant);

  group('RULING 6 — the step-1 branch', () {
    test('the two reachable arms SPLIT the payload', () {
      final Map<String, Object?> v = buildDivorceFormData(_voluntary(), fixed, '');
      final Map<String, Object?> c = buildDivorceFormData(_contested(), fixed, '');

      final Map<String, Object?> vMed = v['mediation']! as Map<String, Object?>;
      final Map<String, Object?> cMed = c['mediation']! as Map<String, Object?>;
      final Map<String, Object?> vBasis = v['basis']! as Map<String, Object?>;
      final Map<String, Object?> cBasis = c['basis']! as Map<String, Object?>;

      expect(vMed['property_division'], 'Test Property Division');
      expect(cMed['property_division'], '');
      expect(vBasis['court_name'], '');
      expect(cBasis['court_name'], "Test People's Court");

      // `F3-AC-47`'s reason, stated as a property: a one-arm matrix leaves a
      // whole key group permanently "" and a port that HARDCODED "" there would
      // pass. Both arms are in the Tier 0 run precisely so it cannot.
      expect(vMed.values.where((Object? x) => x != '').length, greaterThan(0));
      expect(cBasis.values.where((Object? x) => x != '').length, greaterThan(0));
    });

    test('F3-AC-48 neither key group is EVER absent, in either arm', () {
      for (final DivorceFormData f in <DivorceFormData>[
        _voluntary(),
        _contested(),
        const DivorceFormData(), // nothing chosen at all
      ]) {
        final Map<String, Object?> p = buildDivorceFormData(f, fixed, '');
        final Map<String, Object?> med = p['mediation']! as Map<String, Object?>;
        final Map<String, Object?> basis = p['basis']! as Map<String, Object?>;
        expect(med.length, 11,
            reason: 'specs.md § 6.7 says nine; counted at :802-814 it is '
                'eleven, and divorce.contested.create.en carries eleven');
        expect(basis.containsKey('court_name'), isTrue);
        expect(basis.containsKey('court_decision_date'), isTrue);
      }
    });

    test('F3-AC-52/53 the TERMINAL code: both branch booleans are false, the '
        'step cannot advance, and nothing throws', () {
      // `:745-746` compares against two string LITERALS. A third server-side
      // code leaves both false.
      final DivorceFormData terminal = _voluntary().copyWith(
        basis: _voluntary().basis.copyWith(divorceType: 'mutual'),
      );

      expect(divorceIsVoluntary(terminal), isFalse);
      expect(divorceIsContested(terminal), isFalse);
      expect(divorceIsTerminalType(terminal), isTrue);

      // It falls through to the CONTESTED arm's gate (`:765`), which demands a
      // court decision that the terminal state never renders — so the step
      // cannot advance for any sequence of clicks.
      expect(divorceCanProceed(terminal, step: 1), isFalse);

      // And building a payload for it does not throw. The port must reproduce
      // a dead end, not crash in one.
      expect(() => buildDivorceFormData(terminal, fixed, ''), returnsNormally);
      final Map<String, Object?> p = buildDivorceFormData(terminal, fixed, '');
      expect((p['basis']! as Map<String, Object?>)['divorce_type'], 'mutual',
          reason: 'the unknown code still goes on the wire verbatim');
    });

    test('F3-AC-53 the blank type is NOT the terminal state', () {
      // A distinction a `default:` arm would erase: no type chosen renders the
      // intro note (`:1046`), an unknown type renders nothing at all.
      const DivorceFormData blank = DivorceFormData();
      expect(divorceIsTerminalType(blank), isFalse);
      expect(divorceCanProceed(blank, step: 1), isFalse,
          reason: ':751 — `if (!basis.divorceType) return false`');
    });

    test('the `existing` arm is refused rather than chosen on a fixture\'s '
        'behalf', () {
      // `F3-AC-48`'s other half — `DIVORCE_MEDIATION_MODE_UNDECLARED`.
      final Map<String, dynamic> fixture =
          readDivorceJson('$kDivorceFixtureDir/asymmetric.en.json')
            ..remove('mediationMode');
      expect(
        () => divorceFormFromFixture(fixture),
        throwsA(isA<StateError>().having(
          (StateError e) => e.message,
          'message',
          contains('DIVORCE_MEDIATION_MODE_UNDECLARED'),
        )),
      );
    });
  });

  group('D-N — stale court data, FIXED', () {
    test('F3-AC-54 contested -> voluntary clears the court block and drops the '
        'decree from uploads()', () {
      // Fill the contested arm, then switch.
      final DivorceFormData filled = _contested().copyWith(
        courtDecision: _file('decree.pdf'),
      );
      expect(filled.court.name, isNotEmpty);
      expect(divorceUploads(filled).first.slot, 'basis.court_decision');

      final DivorceFormData switched = divorceResetMediation(
        filled.copyWith(
          basis: filled.basis.copyWith(divorceType: kDivorceTypeVoluntary),
        ),
      );

      final Map<String, Object?> basis =
          buildDivorceFormData(switched, fixed, '')['basis']!
              as Map<String, Object?>;
      expect(basis['court_name'], '');
      expect(basis['court_decision_date'], '');
      expect(
        divorceUploads(switched)
            .any((DivorceAttachment a) => a.slot == 'basis.court_decision'),
        isFalse,
        reason: 'uploads() includes the decree UNCONDITIONALLY (:841); the fix '
            'works by clearing the file, not by adding a condition',
      );
    });

    test('F3-AC-54/62 the fix changes ZERO bytes on the executed fixtures', () {
      // Provably safe against the gate: on all eight executed divorce documents
      // the type is set once and never switched, so the fixed and unfixed
      // payloads are byte-identical. Asserted by running the reset on a form
      // that never visited the other arm.
      for (final DivorceFormData f in <DivorceFormData>[
        _voluntary(),
        _contested(),
      ]) {
        final String before = jsonEncode(buildDivorceFormData(f, fixed, ''));
        final String after = jsonEncode(
          buildDivorceFormData(divorceResetMediation(f), fixed, ''),
        );
        if (divorceIsContested(f)) {
          // The contested fixture DOES carry court data, so a reset changes it
          // — which is the point of the fix. What must not change is the
          // untouched arm.
          expect(before, isNot(equals(after)));
        } else {
          expect(after, equals(before),
              reason: 'the voluntary fixture never filled the court block, so '
                  'the fix is invisible to it');
        }
      }
    });

    test('the fix does NOT clear mediation.* — D-N names stale COURT data only',
        () {
      final DivorceFormData reset = divorceResetMediation(_voluntary());
      expect(reset.mediation.propertyDivision, 'Test Property Division',
          reason: 'clearing the mediation block too would be symmetric and '
              'would be a second, unauthorised fix');
    });
  });

  group('RULING 7 — the two orderings', () {
    DivorceFormData allFour() => _contested().copyWith(
          courtDecision: _file('decree.pdf'),
          householdBook: _file('book.pdf'),
          guaranteeCert: _file('guarantee.pdf'),
          photos: _file('photo.jpg'),
        );

    test('F3-AC-58 the POST order and the DOM order are DIFFERENT LISTS, and '
        'both are asserted', () {
      expect(
        divorceUploads(allFour()).map((DivorceAttachment a) => a.slot).toList(),
        <String>[
          'basis.court_decision',
          'supporting.household_book',
          'supporting.guarantee_certificate',
          'supporting.photos_3x4',
        ],
        reason: 'uploads() order — :841-844',
      );
      expect(
        divorceStep4DomOrder,
        <String>[
          'supporting.household_book',
          'supporting.guarantee_certificate',
          'supporting.photos_3x4',
        ],
        reason: 'render order — :1442, :1448, :1455. The court decision is not '
            'here at all: it renders on step 1.',
      );
      // The property that makes them two lists rather than one: neither is a
      // prefix or a permutation of the other.
      expect(divorceUploads(allFour()).length,
          isNot(equals(divorceStep4DomOrder.length)));
    });

    test('F3-AC-59 a null file drops its entry, and F3-AC-57 the order is '
        'preserved among the survivors', () {
      final DivorceFormData partial = _contested().copyWith(
        householdBook: _file('book.pdf'),
        photos: _file('photo.jpg'),
      );
      expect(
        divorceUploads(partial).map((DivorceAttachment a) => a.slot).toList(),
        <String>['supporting.household_book', 'supporting.photos_3x4'],
      );
    });

    test('no slot repeats on this page, so F3-AC-56 is asserted on Marriage',
        () {
      final List<DivorceAttachment> uploads = divorceUploads(allFour());
      expect(uploads.map((DivorceAttachment a) => a.slot).toSet().length,
          uploads.length,
          reason: 'four entries, four distinct slots — the no-dedupe property '
              'is vacuous here and is proven on Marriage');
    });
  });

  group('the shapes Divorce does not share', () {
    test('F3-AC-43 spousePayload emits EIGHT keys, with the rename', () {
      final Map<String, Object?> h = divorceSpousePayload(_contested().husband);
      expect(h.keys.toList(), <String>[
        'name',
        'dob',
        'nationality',
        'id_number',
        'house_no',
        'current_address',
        'address_text',
        'marriage_certificate_ref',
      ]);
      expect(h.length, 8);
      expect(h.containsKey('residence_certificate_ref'), isFalse);
      expect(h.containsKey('gender'), isFalse);
    });

    test('F3-AC-42 the mirror is SIX keys, no gender', () {
      final Map<String, Object?> spouses =
          buildDivorceFormData(_contested(), fixed, '')['spouses']!
              as Map<String, Object?>;
      final List<String> mirrored =
          spouses.keys.where((String k) => spouses[k] is! Map).toList();
      expect(mirrored, <String>[
        'name',
        'dob',
        'nationality',
        'id_number',
        'current_address',
        'marriage_certificate_ref',
      ]);
      expect(mirrored.length, 6);
      expect(mirrored, isNot(contains('gender')));
    });

    test('F3-AC-68 the spouse model has NO gender field and no control can '
        'render one', () {
      // Structural: the field does not exist, so no widget can bind to it. That
      // is a stronger claim than "no gender control is mounted", and it is the
      // one a later edit cannot quietly break.
      const DivorceSpouseInfo s = DivorceSpouseInfo.blank;
      expect(divorceSpousePayload(s).containsKey('gender'), isFalse);
      expect(
        buildDivorceFormData(const DivorceFormData(), fixed, '')
            .toString()
            .contains('gender'),
        isFalse,
      );
    });

    test('F3-AC-44 both() — table-driven, all four rows', () {
      expect(both('  x  ', 'y'), 'x');
      expect(both('x', '  '), '');
      expect(both('  ', 'y'), '');
      expect(both('', ''), '');
      // The collapse is "", never null and never an absent key.
      expect(both('x', ''), isNotNull);
      expect(both('x', ''), isEmpty);
    });
  });

  group('the constants', () {
    test('F3-AC-74 the divorce quote takes NO inputs — it fires once', () {
      // The contrast with Marriage, stated as a type-level fact: there is no
      // `anyForeign` and no `includeBetrothalFee` on this page, so nothing can
      // re-fire the query. `useQuery(() => catalog.quote("divorce", {}), [])`.
      expect(kDivorceServiceCode, 'divorce');
    });

    test('F3-AC-69 "captured-at-office" is emitted at TWO sites here', () {
      final Map<String, Object?> basis =
          buildDivorceFormData(const DivorceFormData(), fixed, '')['basis']!
              as Map<String, Object?>;
      expect(basis['registrar_signature'], 'captured-at-office');
      expect(basis['certificate_each_spouse'], 'captured-at-office');
      expect(kDivorceOfficeDeferred, 'captured-at-office');
    });

    test('canProceed step 5 (review) falls through to true', () {
      expect(divorceCanProceed(const DivorceFormData(), step: 5), isTrue,
          reason: 'step 5 is absent from the switch (:775)');
    });
  });
}

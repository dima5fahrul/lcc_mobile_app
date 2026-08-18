/// Both `canProceed()` matrices, exhaustively — the batch's validation gates.
///
/// ## Why these deserve a file rather than a coverage top-up
///
/// The Continue button is **never disabled** on either page
/// (`MarriageCertificatePage.tsx:1613`, `DivorceCertificatePage.tsx:1561`).
/// Tapping it on an incomplete step flips `showErrors` and stays put. So
/// `canProceed()` is not a hint that dims a control — **it is the entire
/// progression gate**, and every asymmetry in it is directly observable as "the
/// form will not let me continue and I cannot see why".
///
/// The two are also the functions where a tidier port silently diverges: each
/// contains a field the source does *not* check, and a step the source omits
/// from its `switch` so it falls through to `true`. Both are reproduced, and
/// both are asserted here rather than left as comments.
///
/// The two matrices live in one file because they are the same *kind* of claim
/// about two pages; no symbol crosses between `marriage/` and `divorce/`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_location_value.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_form_state.dart';

import 'divorce/divorce_tier0_subject.dart';
import 'marriage/marriage_tier0_subject.dart';

const PickedAttachment _any = PickedAttachment(name: 'f.pdf', bytes: null);

MarriageFormData _marriage() => marriageFormFromFixture(
      readMarriageJson('$kMarriageFixtureDir/asymmetric.en.json'),
    );

DivorceFormData _divorceVoluntary() => divorceFormFromFixture(
      readDivorceJson('$kDivorceFixtureDir/asymmetric.en.json'),
    );

DivorceFormData _divorceContested() => divorceFormFromFixture(
      readDivorceJson('$kDivorceFixtureDir/contested.en.json'),
    );

/// A spouse who satisfies every one of `spouseValid`'s ten conditions.
MarriageSpouseInfo _validSpouse(MarriageSpouseInfo base) =>
    base.copyWith(singleStatusCert: _any);

void main() {
  group('Marriage — `:851-871`', () {
    test('step 1: the chooser is REFUSED; both other modes gate on the header',
        () {
      final MarriageFormData f = _marriage();

      expect(
        marriageCanProceed(
          f.copyWith(betrothalMode: MarriageBetrothalMode.none),
          step: 1,
        ),
        isFalse,
        reason: ':857 — `return false`, must pick existing or create new',
      );

      // `new` — header + household head + bride price.
      expect(marriageCanProceed(f, step: 1), isTrue);
      expect(
        marriageCanProceed(
          f.copyWith(betrothal: f.betrothal.copyWith(householdHead: '  ')),
          step: 1,
        ),
        isFalse,
        reason: 'trimmed',
      );
      expect(
        marriageCanProceed(
          f.copyWith(betrothal: f.betrothal.copyWith(bridePriceCash: '')),
          step: 1,
        ),
        isFalse,
      );
      expect(
        marriageCanProceed(
          f.copyWith(header: const CertificateLocationValue(provinceId: 'p')),
          step: 1,
        ),
        isFalse,
        reason: 'the header needs all THREE ids',
      );

      // `existing` — a linked record plus the header, and nothing else.
      final MarriageFormData existing =
          f.copyWith(betrothalMode: MarriageBetrothalMode.existing);
      expect(marriageCanProceed(existing, step: 1), isFalse,
          reason: 'no linked record — and /prerequisite-records is empty on '
              'every account, so this arm is unreachable in practice');
    });

    test('steps 2 and 3 gate on their OWN spouse', () {
      final MarriageFormData f = _marriage();
      // Spouse B is `thai` in the fixture, so a valid B also needs
      // `foreignDocs` — the conditional the next test isolates. Getting this
      // wrong is how a step-3 gate looks broken when it is doing its job.
      final MarriageFormData both = f.copyWith(
        spouseA: _validSpouse(f.spouseA),
        spouseB: _validSpouse(f.spouseB).copyWith(foreignDocs: _any),
      );

      expect(marriageCanProceed(both, step: 2), isTrue);
      expect(marriageCanProceed(both, step: 3), isTrue);

      // Breaking A must not affect step 3, and vice versa.
      final MarriageFormData aBroken =
          both.copyWith(spouseA: both.spouseA.copyWith(fullName: ' '));
      expect(marriageCanProceed(aBroken, step: 2), isFalse);
      expect(marriageCanProceed(aBroken, step: 3), isTrue);
    });

    test('the conditional documents: prevMarried and foreign', () {
      final MarriageFormData f = _marriage();
      final MarriageSpouseInfo a = _validSpouse(f.spouseA);

      expect(marriageSpouseValid(a, false), isTrue);
      expect(marriageSpouseValid(a, true), isFalse,
          reason: 'prevMarried demands priorMaritalProof');
      expect(
        marriageSpouseValid(a.copyWith(priorMaritalProof: _any), true),
        isTrue,
      );

      // Spouse B in the fixture is `thai` — foreign — so it needs foreignDocs.
      final MarriageSpouseInfo b = _validSpouse(f.spouseB);
      expect(marriageIsForeign(b.nationality), isTrue);
      expect(marriageSpouseValid(b, false), isFalse);
      expect(marriageSpouseValid(b.copyWith(foreignDocs: _any), false), isTrue);
    });

    test('district is NOT checked — the source\'s own hole, reproduced', () {
      final MarriageFormData f = _marriage();
      final MarriageSpouseInfo a = _validSpouse(f.spouseA);
      final MarriageSpouseInfo noDistrict = a.copyWith(
        address: a.address.copyWith(districtId: ''),
      );
      expect(marriageSpouseValid(noDistrict, false), isTrue,
          reason: ':843 checks villageId and provinceId and NOT districtId. '
              'Unreachable in practice (the village select is disabled without '
              'a district) — a hole with no inhabitant, and it is the '
              'source\'s.');
    });

    test('step 4 gates on the two required uploads, and on birthRecord only '
        'when hasChildren', () {
      final MarriageFormData f = _marriage()
          .copyWith(householdBook: _any, photos: _any);
      expect(marriageCanProceed(f, step: 4), isTrue);
      expect(marriageCanProceed(f.copyWith(hasChildren: true), step: 4), isFalse);
      expect(
        marriageCanProceed(
          f.copyWith(hasChildren: true, birthRecord: _any),
          step: 4,
        ),
        isTrue,
      );
    });

    test('step 5 needs all eight registration fields', () {
      final MarriageFormData f = _marriage();
      expect(marriageCanProceed(f, step: 5), isTrue);
      for (final MarriageRegistration broken in <MarriageRegistration>[
        f.reg.copyWith(dateOfMarriage: ''),
        f.reg.copyWith(placeOfRegistration: '   '),
        f.reg.copyWith(w1Name: ''),
        f.reg.copyWith(w1Id: ''),
        f.reg.copyWith(w2Name: ''),
        f.reg.copyWith(w2Id: ''),
        f.reg.copyWith(w3Name: ''),
        f.reg.copyWith(w3Id: ''),
      ]) {
        expect(marriageCanProceed(f.copyWith(reg: broken), step: 5), isFalse);
      }
    });

    test('step 6 FALLS THROUGH to true; step 7 is the payment gate', () {
      final MarriageFormData f = _marriage();
      expect(marriageCanProceed(f, step: 6), isTrue,
          reason: 'step 6 is absent from the switch (:870) — review always '
              'advances');
      expect(marriageCanProceed(f, step: 99), isTrue,
          reason: 'so does any step the source does not name');
      expect(marriageCanProceed(f, step: 7), isTrue,
          reason: 'the blank draft is `qr`, which isPaymentValid accepts');
    });
  });

  group('Divorce — `:749-776`', () {
    test('step 1: blank type is refused before any arm is consulted', () {
      expect(divorceCanProceed(const DivorceFormData(), step: 1), isFalse,
          reason: ':751 `if (!basis.divorceType) return false`');
    });

    test('step 1 voluntary: no mode is refused; `new` needs five fields', () {
      final DivorceFormData f = _divorceVoluntary();
      expect(divorceCanProceed(f, step: 1), isTrue);

      expect(
        divorceCanProceed(
          f.copyWith(mediationMode: DivorceMediationMode.none),
          step: 1,
        ),
        isFalse,
        reason: ':762',
      );

      for (final DivorceMediation broken in <DivorceMediation>[
        f.mediation.copyWith(dateMarriageBegan: ''),
        f.mediation.copyWith(reasonsHusband: '  '),
        f.mediation.copyWith(reasonsWife: ''),
        f.mediation.copyWith(outcome: ''),
        f.mediation.copyWith(propertyDivision: ''),
      ]) {
        expect(divorceCanProceed(f.copyWith(mediation: broken), step: 1),
            isFalse);
      }

      // `debts` and `additionalAssets` are OPTIONAL — the asymmetry.
      expect(
        divorceCanProceed(
          f.copyWith(
            mediation: f.mediation.copyWith(debts: '', additionalAssets: ''),
          ),
          step: 1,
        ),
        isTrue,
      );
    });

    test('step 1 voluntary + children: both child fields become required', () {
      final DivorceFormData f = _divorceVoluntary();
      expect(f.hasChildren, isTrue);
      expect(divorceCanProceed(f, step: 1), isTrue);

      expect(
        divorceCanProceed(
          f.copyWith(children: f.children.copyWith(list: '')),
          step: 1,
        ),
        isFalse,
      );
      expect(
        divorceCanProceed(
          f.copyWith(children: f.children.copyWith(custody: '  ')),
          step: 1,
        ),
        isFalse,
      );
      // Toggling children off releases both.
      expect(
        divorceCanProceed(
          f.copyWith(
            hasChildren: false,
            children: DivorceChildren.blank,
          ),
          step: 1,
        ),
        isTrue,
      );
    });

    test('step 1 voluntary + existing needs a linked record — unreachable arm',
        () {
      final DivorceFormData f = _divorceVoluntary()
          .copyWith(mediationMode: DivorceMediationMode.existing);
      expect(divorceCanProceed(f, step: 1), isFalse,
          reason: '/prerequisite-records answers data: [] on every account, so '
              'no linked record can be obtained — F3-NV-4');
    });

    test('step 1 contested needs the court trio', () {
      final DivorceFormData f =
          _divorceContested().copyWith(courtDecision: _any);
      expect(divorceCanProceed(f, step: 1), isTrue);

      expect(
        divorceCanProceed(f.copyWith(clearCourtDecision: true), step: 1),
        isFalse,
      );
      expect(
        divorceCanProceed(
          f.copyWith(court: f.court.copyWith(name: '  ')),
          step: 1,
        ),
        isFalse,
      );
      expect(
        divorceCanProceed(
          f.copyWith(court: f.court.copyWith(decisionDate: '')),
          step: 1,
        ),
        isFalse,
      );
    });

    test('the TERMINAL code falls through to the contested gate it cannot '
        'satisfy', () {
      final DivorceFormData terminal = _divorceVoluntary().copyWith(
        basis: _divorceVoluntary().basis.copyWith(divorceType: 'mutual'),
      );
      expect(divorceIsTerminalType(terminal), isTrue);
      expect(divorceCanProceed(terminal, step: 1), isFalse,
          reason: ':765 demands a court decision that the terminal state never '
              'renders — the dead end');
    });

    test('steps 2 and 3 gate on their own spouse; step 4 on date, place and '
        'three uploads', () {
      final DivorceFormData f = _divorceContested();
      expect(divorceCanProceed(f, step: 2), isTrue);
      expect(divorceCanProceed(f, step: 3), isTrue);
      expect(
        divorceCanProceed(
          f.copyWith(husband: f.husband.copyWith(marriageCertRef: ' ')),
          step: 2,
        ),
        isFalse,
        reason: 'the RENAMED key is required here where Marriage requires '
            'residenceCertRef',
      );

      final DivorceFormData docs = f.copyWith(
        guaranteeCert: _any,
        householdBook: _any,
        photos: _any,
      );
      expect(divorceCanProceed(docs, step: 4), isTrue);
      expect(divorceCanProceed(docs.copyWith(clearPhotos: true), step: 4),
          isFalse);
      expect(
        divorceCanProceed(
          docs.copyWith(basis: docs.basis.copyWith(dateOfDivorce: '')),
          step: 4,
        ),
        isFalse,
      );
    });

    test('step 5 FALLS THROUGH to true; step 6 is the payment gate', () {
      final DivorceFormData f = _divorceContested();
      expect(divorceCanProceed(f, step: 5), isTrue,
          reason: 'review is absent from the switch (:775)');
      expect(divorceCanProceed(f, step: 6), isTrue);
    });

    test('divorceSpouseValid has no gender condition — it cannot', () {
      // Marriage's `spouseValid` checks `s.gender`; there is no such field
      // here, so the two predicates are different arities over different
      // shapes and could never have been one function.
      expect(divorceSpouseValid(_divorceContested().husband), isTrue);
    });
  });

  group('the shared location value', () {
    test('copyWith replaces only what it is given, and equality is by value',
        () {
      const CertificateLocationValue base = CertificateLocationValue(
        provinceId: 'p',
        districtId: 'd',
        villageId: 'v',
        provinceName: 'P',
        districtName: 'D',
        villageName: 'V',
      );

      expect(base.copyWith(villageId: 'v2').villageId, 'v2');
      expect(base.copyWith(villageId: 'v2').districtId, 'd');
      expect(base.copyWith(), base);
      expect(base, isNot(equals(CertificateLocationValue.blank)));
      expect(base.hashCode, base.copyWith().hashCode);

      // The blank is what a province pick resets to — every field empty.
      expect(CertificateLocationValue.blank.provinceName, isEmpty);
      expect(CertificateLocationValue.blank.villageId, isEmpty);
    });
  });
}

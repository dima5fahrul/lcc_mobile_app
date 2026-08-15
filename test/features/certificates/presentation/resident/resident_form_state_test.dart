/// `ResidentCertificatePage.tsx:109-160`, `:429-451`, `:484-498` — the page's
/// pure logic, each asymmetry of the source asserted as an asymmetry.
///
/// Every test here is written against a property that would survive a
/// *plausible tidier port*. `canProceed` returning true on a full form proves
/// almost nothing — a function that returned `true` unconditionally would pass
/// it. What is asserted instead is the shape of each **refusal**, and the four
/// places the source is deliberately inconsistent.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_payload.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/payment_method.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';
import 'package:lcc_mobile_app/presentation/forms/validation/step_of_first_error.dart';
import 'package:lcc_mobile_app/presentation/payment/payment_draft.dart';

const PickedAttachment _file = PickedAttachment(name: 'scan.jpg', bytes: null);

/// A form that satisfies every step, so each test can knock exactly one prop
/// out and watch the answer change.
ResidentFormData _complete() => const ResidentFormData(
      frontId: _file,
      backId: _file,
      familyBookCover: _file,
      familyBookContents: _file,
      picture: _file,
      citizenName: 'Test Citizen',
      age: '34',
      nationality: 'lao',
      province: 'p',
      district: 'd',
      villageName: 'v',
      certifyingJurisdiction: 'cj',
      currentVillage: 'cv',
      houseNo: '123',
      censusBookNo: 'CB-1',
      purpose: 'school-enrolment',
    );

void main() {
  group('ageFrom — ResidentCertificatePage.tsx:151-160', () {
    // 2026-08-14 local, the register's instant.
    final SubmissionClock clock =
        SubmissionClock.fixed(DateTime(2026, 8, 14, 2));

    test('whole years, with the month/day decrement applied', () {
      expect(ageFrom('1992-08-13', clock), '34'); // birthday passed
      expect(ageFrom('1992-08-14', clock), '34'); // birthday today
      expect(ageFrom('1992-08-15', clock), '33'); // birthday tomorrow
      expect(ageFrom('1992-09-01', clock), '33'); // later month
    });

    test('empty and unparseable input yield "" — never "0", never a throw', () {
      expect(ageFrom(null, clock), '');
      expect(ageFrom('', clock), '');
      expect(ageFrom('not-a-date', clock), '');
    });

    test('a future date of birth yields "" rather than a negative age', () {
      // `years >= 0` — the source is silent about it and the field simply
      // stays blank. A port that emitted "-1" would POST "-1" as
      // `applicant.age`, because this value is on the wire (`:466`).
      expect(ageFrom('2030-01-01', clock), '');
    });

    test('the 150 bound is EXCLUSIVE at the top and inclusive at the bottom',
        () {
      expect(ageFrom('1877-01-01', clock), '149');
      expect(ageFrom('1876-01-01', clock), '', reason: 'exactly 150 → ""');
      expect(ageFrom('2026-08-14', clock), '0', reason: 'born today → "0"');
    });

    test('it reads the INJECTED clock, so the same input can age', () {
      // The property that makes `applicant.age` a Tier 0 value at all: two
      // clocks, one date of birth, two answers. A port that called
      // DateTime.now() here would return the same string for both and the
      // payload would be undrivable.
      expect(ageFrom('1992-08-14', SubmissionClock.fixed(DateTime(2026, 8, 14))),
          '34');
      expect(ageFrom('1992-08-14', SubmissionClock.fixed(DateTime(2027, 8, 14))),
          '35');
    });
  });

  group('canProceed — ResidentCertificatePage.tsx:429-451', () {
    test('a complete form clears every step', () {
      for (int step = 1; step <= 6; step++) {
        expect(
          residentCanProceed(_complete(), step: step, detecting: false),
          isTrue,
          reason: 'step $step',
        );
      }
    });

    test('step 1 is blocked while the ID read is in flight — `&& !detecting`',
        () {
      expect(
        residentCanProceed(_complete(), step: 1, detecting: true),
        isFalse,
        reason: 'The only step whose validity depends on something other than '
            'the form. Four files chosen and it still refuses.',
      );
      // …and it is the ONLY step that cares.
      for (int step = 2; step <= 6; step++) {
        expect(
          residentCanProceed(_complete(), step: step, detecting: true),
          isTrue,
          reason: 'step $step must ignore `detecting`',
        );
      }
    });

    test('each step 1 file is individually required', () {
      expect(
          residentCanProceed(_complete().copyWith(clearFrontId: true),
              step: 1, detecting: false),
          isFalse);
      expect(
          residentCanProceed(_complete().copyWith(clearBackId: true),
              step: 1, detecting: false),
          isFalse);
      expect(
          residentCanProceed(_complete().copyWith(clearFamilyBookCover: true),
              step: 1, detecting: false),
          isFalse);
      expect(
          residentCanProceed(
              _complete().copyWith(clearFamilyBookContents: true),
              step: 1,
              detecting: false),
          isFalse);
    });

    test('step 2 trims name and age but NOT nationality', () {
      expect(
          residentCanProceed(_complete().copyWith(citizenName: '   '),
              step: 2, detecting: false),
          isFalse);
      expect(
          residentCanProceed(_complete().copyWith(age: '  '),
              step: 2, detecting: false),
          isFalse);
      expect(
          residentCanProceed(_complete().copyWith(nationality: ''),
              step: 2, detecting: false),
          isFalse);
      expect(
          residentCanProceed(_complete().copyWith(clearPicture: true),
              step: 2, detecting: false),
          isFalse);

      // `:434` is `form.nationality`, not `form.nationality.trim()`. A blank
      // string passes. It cannot be produced by the select, and the source
      // says what it says.
      expect(
        residentCanProceed(_complete().copyWith(nationality: ' '),
            step: 2, detecting: false),
        isTrue,
        reason: 'nationality is truthiness-checked while its two neighbours '
            'are trimmed (:434). Reproduced, not repaired.',
      );
    });

    test('step 3 does NOT require the village chief, though step 3 renders it',
        () {
      // `:436-441` lists province, district, villageName and
      // certifyingJurisdiction — and omits villageChiefName, which `:877-883`
      // renders on the same step and `FIELD_STEP` maps to it. The API may
      // still 422 on it; the wizard will not stop you.
      expect(
        residentCanProceed(_complete().copyWith(villageChiefName: ''),
            step: 3, detecting: false),
        isTrue,
      );
      expect(
          residentCanProceed(_complete().copyWith(certifyingJurisdiction: ' '),
              step: 3, detecting: false),
          isFalse);
    });

    test('step 5 requires purposeOther only when purpose is exactly "other"',
        () {
      final ResidentFormData other =
          _complete().copyWith(purpose: 'other', purposeOther: '');
      expect(residentCanProceed(other, step: 5, detecting: false), isFalse);
      expect(
          residentCanProceed(other.copyWith(purposeOther: 'x'),
              step: 5, detecting: false),
          isTrue);
      // Any other code, and the free-text box is irrelevant even when blank.
      expect(
          residentCanProceed(_complete().copyWith(purposeOther: ''),
              step: 5, detecting: false),
          isTrue);
    });

    test('step 6 is the payment predicate, and qr is valid out of the box', () {
      expect(
        residentCanProceed(_complete(), step: 6, detecting: false),
        isTrue,
        reason: 'blankPayment.method is `qr` and isPaymentValid returns true '
            'for qr unconditionally (PaymentSection.tsx:109).',
      );
      expect(
        residentCanProceed(
          _complete().copyWith(
            payment: kBlankPayment.copyWith(method: DraftPaymentMethod.bank),
          ),
          step: 6,
          detecting: false,
        ),
        isFalse,
      );
    });

    test('an out-of-range step returns true — the `return true` at :450', () {
      expect(residentCanProceed(const ResidentFormData(), step: 7,
          detecting: false),
          isTrue);
    });
  });

  group('FIELD_STEP — ResidentCertificatePage.tsx:109-134', () {
    test('24 entries, and every value is a real step', () {
      expect(kResidentFieldStep.length, 24);
      for (final MapEntry<String, int> e in kResidentFieldStep.entries) {
        expect(kResidentStepIds, contains(e.value), reason: e.key);
      }
    });

    test('routing picks the EARLIEST offending step, not the first named', () {
      expect(
        stepOfFirstError(
          <String>['purpose.purpose', 'applicant.age', 'applicant.house_no'],
          kResidentFieldStep,
        ),
        2,
      );
    });

    test('the map\'s gaps are the source\'s, and they route NOWHERE', () {
      // `stepOfFirstError` SKIPS an unknown path rather than treating it as
      // step 0 (`formValidation.tsx:179`). These four are POSTed or uploaded
      // and have no row, so a 422 naming only one of them silently fails to
      // route — which is the behaviour, not a defect to patch here.
      for (final String orphan in <String>[
        'applicant.id_front',
        'applicant.id_back',
        'household_reference.family_book_contents',
        'purpose.purpose_other',
      ]) {
        expect(kResidentFieldStep.containsKey(orphan), isFalse, reason: orphan);
        expect(stepOfFirstError(<String>[orphan], kResidentFieldStep), isNull);
      }
    });

    test('header.ref_no maps to step 2 even though it is read-only there', () {
      expect(kResidentFieldStep['header.ref_no'], 2);
    });
  });

  group('attachmentsToSend — ResidentCertificatePage.tsx:484-491', () {
    test('the photo goes FIRST, before step 1\'s four documents', () {
      final List<CertificateAttachment> a =
          residentAttachmentsToSend(_complete());
      expect(a.map((CertificateAttachment x) => x.slot).toList(), <String>[
        'applicant.photo',
        'applicant.id_front',
        'applicant.id_back',
        'household_reference.family_book_upload',
        'household_reference.family_book_contents',
      ]);
      expect(a.first.kind, 'photo');
      expect(
        a.skip(1).every((CertificateAttachment x) => x.kind == 'document'),
        isTrue,
      );
    });

    test('null slots are filtered out and the rest keep their order', () {
      final List<CertificateAttachment> a = residentAttachmentsToSend(
        _complete().copyWith(clearPicture: true, clearBackId: true),
      );
      expect(a.map((CertificateAttachment x) => x.slot).toList(), <String>[
        'applicant.id_front',
        'household_reference.family_book_upload',
        'household_reference.family_book_contents',
      ]);
    });

    test('the five slots are DISTINCT — which is what makes the dedupe safe',
        () {
      final List<String> slots = residentAttachmentsToSend(_complete())
          .map((CertificateAttachment x) => x.slot)
          .toList();
      expect(slots.toSet().length, slots.length,
          reason: 'attachment_guard.dart:24-28 — D-I is a collision hazard on '
              'Marriage, not on Resident, precisely because of this.');
    });

    test('an empty form sends nothing at all', () {
      expect(residentAttachmentsToSend(const ResidentFormData()), isEmpty);
    });
  });

  group('methodCodeFor — ResidentCertificatePage.tsx:494-498', () {
    PaymentMethod m(String code, PaymentMethodKind kind, {bool enabled = true}) =>
        PaymentMethod(
          id: code,
          code: code,
          label: const Bilingual(en: 'x', lo: 'x'),
          kind: kind,
          enabled: enabled,
        );

    test('qr picks the first enabled qr row', () {
      expect(
        residentMethodCodeFor(DraftPaymentMethod.qr, <PaymentMethod>[
          m('wallet-1', PaymentMethodKind.wallet),
          m('laoqr-live', PaymentMethodKind.qr),
        ]),
        'laoqr-live',
      );
    });

    test('bank AND cc both resolve to the bank kind — the D-O discard', () {
      final List<PaymentMethod> rows = <PaymentMethod>[
        m('bank-live', PaymentMethodKind.bank),
      ];
      expect(residentMethodCodeFor(DraftPaymentMethod.bank, rows), 'bank-live');
      expect(
        residentMethodCodeFor(DraftPaymentMethod.cc, rows),
        'bank-live',
        reason: 'A card payment settles as a bank transfer and the `cc` '
            'distinction never reaches the API (fsd.md D-O).',
      );
    });

    test('a DISABLED row is skipped, and the fallback differs per branch', () {
      final List<PaymentMethod> rows = <PaymentMethod>[
        m('laoqr-live', PaymentMethodKind.qr, enabled: false),
        m('bank-live', PaymentMethodKind.bank, enabled: false),
      ];
      expect(residentMethodCodeFor(DraftPaymentMethod.qr, rows), 'laoqr');
      expect(residentMethodCodeFor(DraftPaymentMethod.bank, rows),
          'bank-transfer');
    });

    test('an empty list falls back without throwing', () {
      expect(residentMethodCodeFor(DraftPaymentMethod.qr, <PaymentMethod>[]),
          'laoqr');
      expect(residentMethodCodeFor(DraftPaymentMethod.cc, <PaymentMethod>[]),
          'bank-transfer');
    });

    test('it does NOT use Birth\'s algorithm — no any-enabled-row fallback',
        () {
      // Birth prefers an enabled `qr`, then ANY enabled row, then "laoqr"
      // (`BirthDeclarationPage.tsx:809-813`). Resident does not: with only an
      // enabled wallet row present it falls back to the literal rather than
      // picking the wallet. Two `liveList` pages, two algorithms.
      expect(
        residentMethodCodeFor(DraftPaymentMethod.qr, <PaymentMethod>[
          m('wallet-1', PaymentMethodKind.wallet),
        ]),
        'laoqr',
      );
    });
  });

  group('the draft payment functions — PaymentSection.tsx:100-118', () {
    test('formatCard groups in fours and trims the trailing space', () {
      expect(formatCard('4111111111111111'), '4111 1111 1111 1111');
      expect(formatCard('411'), '411');
      expect(formatCard('41111'), '4111 1');
      expect(formatCard('4111-1111-abc'), '4111 1111');
      expect(
        formatCard('41111111111111119999'),
        '4111 1111 1111 1111',
        reason: 'capped at 16 digits before grouping',
      );
    });

    test('formatExpiry inserts the slash at the THIRD digit, not the second',
        () {
      expect(formatExpiry('1'), '1');
      expect(formatExpiry('12'), '12');
      expect(formatExpiry('123'), '12/3');
      expect(formatExpiry('1234'), '12/34');
      expect(formatExpiry('123456'), '12/34');
    });

    test('isPaymentValid — qr always, bank on any name, cc on four lengths',
        () {
      expect(isPaymentValid(kBlankPayment), isTrue);

      final PaymentDraft bank =
          kBlankPayment.copyWith(method: DraftPaymentMethod.bank);
      expect(isPaymentValid(bank), isFalse);
      expect(isPaymentValid(bank.copyWith(bankName: kLaoBanks.first)), isTrue);

      final PaymentDraft cc = kBlankPayment.copyWith(
        method: DraftPaymentMethod.cc,
        cardNumber: formatCard('4111111111111111'),
        cardName: 'A Citizen',
        cardExpiry: '12/34',
        cardCvv: '123',
      );
      expect(isPaymentValid(cc), isTrue);
      expect(isPaymentValid(cc.copyWith(cardNumber: '4111 1111')), isFalse);
      expect(isPaymentValid(cc.copyWith(cardName: '   ')), isFalse);
      expect(isPaymentValid(cc.copyWith(cardExpiry: '1234')), isFalse);
      expect(isPaymentValid(cc.copyWith(cardCvv: '12')), isFalse);
    });

    test('the card checks are LENGTHS — 99/99 and 000 pass, as on the web', () {
      final PaymentDraft cc = kBlankPayment.copyWith(
        method: DraftPaymentMethod.cc,
        cardNumber: '0000 0000 0000 0000',
        cardName: 'x',
        cardExpiry: '99/99',
        cardCvv: '000',
      );
      expect(
        isPaymentValid(cc),
        isTrue,
        reason: 'No month range, no Luhn, no CVV rule anywhere in the source. '
            'Adding one would be a port stricter than the web.',
      );
    });

    test('LAO_BANKS is twelve entries in source order, not sorted', () {
      expect(kLaoBanks.length, 12);
      expect(kLaoBanks.first, 'BCEL — Banque pour le Commerce Extérieur Lao');
      expect(kLaoBanks.last, 'ACLEDA Bank Lao');
      expect(kLaoBanks, isNot(List<String>.of(kLaoBanks)..sort()));
    });
  });
}

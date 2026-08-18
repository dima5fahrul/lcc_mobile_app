/// `BirthFormCubit` — the page's whole state machine, driven.
///
/// Every criterion here is **behavioural**: the cubit is driven and its state
/// read, never its internals inspected. Hand-written fakes, **no DI container
/// initialised anywhere in this file**.
///
/// ## Why this file exists
///
/// `qa-report.md` reported twelve criteria as "implemented and reviewable but
/// not driven", and under the Capability Rule that is NOT EVALUATED, not PASS.
/// This file converts the cubit-level half of that list into evidence. The
/// widget-level half is `birth_page_widget_test.dart`.
///
/// ## The pay seam is asserted in both directions
///
/// With a fake port: the call is made, its receipt read, and `unpaid` flips.
/// With no port: the case still submits, no receipt is fabricated, and the
/// failure is visible. Neither is reported as an end-to-end charge
/// (`F2-NV-2`).
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/core/network/envelope.dart';
import 'package:lcc_mobile_app/features/application/domain/application_failures.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/application/domain/usecases/application_usecases.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/birth/birth_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/birth/birth_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/birth/birth_payload.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_key.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_option.dart';
import 'package:lcc_mobile_app/features/reference/domain/repositories/reference_repository.dart';
import 'package:lcc_mobile_app/features/reference/domain/usecases/get_lookup_options.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/payment_method.dart';

import '../../../application/application_write_fakes.dart';

final DateTime kInstant = DateTime.parse('2026-08-14T02:00:00+07:00')
    .toUtc()
    .add(const Duration(hours: 7));

PickedAttachment file(String name) => PickedAttachment(name: name, bytes: null);

/// A parent that satisfies all eight fields of `birthParentValid`.
BirthParentInfo validParent(String tag) => BirthParentInfo(
      fullName: 'Name $tag',
      dob: '1968-02-14',
      ethnicity: 'lao-loum',
      nationality: 'lao',
      maritalStatus: 'married',
      addrVillage: 'v-$tag',
      addrProvince: 'p-$tag',
      censusOrId: 'CB-$tag',
    );

/// A form filled enough that `canProceed` is true on every step.
BirthFormData filledForm() => BirthFormData(
      province: 'p-1',
      district: 'd-1',
      village: 'v-1',
      child: const BirthChildInfo(
        fullName: 'Test Child',
        gender: 'female',
        dob: '2026-06-01',
        weight: '3.2',
        height: '49',
        birthType: 'single',
        birthOrder: '2',
        ethnicity: 'lao-loum',
        nationality: 'lao',
        religion: 'buddhist',
        pobProvince: 'p-1',
        pobVillage: 'v-1',
        addrProvince: 'p-2',
        addrVillage: 'v-2',
      ),
      hospitalNotice: file('notice.pdf'),
      mother: validParent('mother'),
      father: validParent('father'),
      informant: const BirthInformantInfo(
        fullName: 'Test Informant',
        dob: '1990-07-04',
        addrVillage: 'v-3',
        addrProvince: 'p-3',
        censusOrId: 'CB-INF',
        relationship: 'uncle',
        phone: '02055500101',
      ),
    );

void main() {
  late FakeApplicationRepository repo;

  BirthFormCubit build({
    BirthPayPort? pay,
    List<PaymentMethod> methods = const <PaymentMethod>[],
  }) {
    repo = FakeApplicationRepository();
    return BirthFormCubit(
      clock: SubmissionClock.fixed(kInstant),
      getLookupOptions: GetLookupOptions(repository: _FakeReferenceRepo()),
      createApplication: CreateApplication(repository: repo),
      updateApplication: UpdateApplication(repository: repo),
      addAttachment: AddAttachment(repository: repo),
      submitApplication: SubmitApplication(repository: repo),
      loadService: () async => Right<Failure, Service>(serviceFixture()),
      loadPaymentMethods: () async =>
          Right<Failure, List<PaymentMethod>>(methods),
      // The `birth` namespace, spelled by the caller. Never `death`'s.
      readLegalBasisText: () => 'BIRTH LEGAL BASIS',
      pay: pay,
    );
  }

  /// A cubit sitting on the last step with a submittable form.
  BirthFormCubit ready({
    BirthPayPort? pay,
    List<PaymentMethod> methods = const <PaymentMethod>[],
  }) {
    final BirthFormCubit c = build(pay: pay, methods: methods);
    c
      ..setField((BirthFormData _) => filledForm())
      ..emit(c.state.copyWith(step: kBirthStepCount));
    return c;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-59 — canProceed, all six arms, passing AND failing
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-59 canProceed, all six arms', () {
    void arm(int step, String what, BirthFormData Function(BirthFormData) break_) {
      test('step $step passes when complete and fails on $what', () {
        expect(birthCanProceed(filledForm(), step), isTrue,
            reason: 'step $step should pass on a complete form');
        expect(birthCanProceed(break_(filledForm()), step), isFalse,
            reason: 'step $step should fail when $what');
      });
    }

    arm(1, 'the header village is blank',
        (BirthFormData f) => f.copyWith(village: ''));
    arm(
      2,
      'the child religion is blank',
      (BirthFormData f) =>
          f.copyWith(child: f.child.copyWith(religion: '')),
    );
    arm(3, 'the mother is incomplete',
        (BirthFormData f) => f.copyWith(mother: const BirthParentInfo()));
    arm(4, 'the father is incomplete and not declared unknown',
        (BirthFormData f) => f.copyWith(father: const BirthParentInfo()));
    arm(
      5,
      'the informant phone is blank',
      (BirthFormData f) =>
          f.copyWith(informant: f.informant.copyWith(phone: '')),
    );

    test('step 6 is unconditionally true — it is Review', () {
      expect(birthCanProceed(const BirthFormData(), 6), isTrue);
    });

    test('F2-AC-61 step 2 blocks on `child.religion` specifically', () {
      // A client-side over-requirement, reproduced. NOTE the measured
      // correction: `child.child_religion` IS in Birth's FIELD_STEP (`:213`),
      // so unlike Death's two this one is not schema-absent — the BEHAVIOUR is
      // ported either way (`architecture-review.md` § 3).
      final BirthFormData f = filledForm();
      expect(birthCanProceed(f, 2), isTrue);
      expect(
          birthCanProceed(
              f.copyWith(child: f.child.copyWith(religion: '')), 2),
          isFalse);
      expect(kBirthFieldStep.containsKey('child.child_religion'), isTrue);
    });

    test('F2-AC-67 the twin conditional', () {
      final BirthFormData f = filledForm();
      // Not twins: `twinName` is irrelevant.
      expect(
          birthCanProceed(
              f.copyWith(child: f.child.copyWith(birthType: 'single', twinName: '')),
              2),
          isTrue);
      // Twins with no twin name: blocked.
      expect(
          birthCanProceed(
              f.copyWith(child: f.child.copyWith(birthType: 'twins', twinName: '')),
              2),
          isFalse);
      // Twins with a twin name: allowed, and `twinGender` is NOT required.
      expect(
          birthCanProceed(
              f.copyWith(
                  child: f.child
                      .copyWith(birthType: 'twins', twinName: 'T', twinGender: '')),
              2),
          isTrue);
    });

    test('F2-AC-24 step 4 short-circuits on the father-unknown toggle', () {
      final BirthFormData blank =
          filledForm().copyWith(father: const BirthParentInfo());
      expect(birthCanProceed(blank, 4), isFalse);
      expect(birthCanProceed(blank.copyWith(fatherUnknown: true), 4), isTrue,
          reason: 'fatherUnknown || parentValid(father) — `:724`');
    });

    test('F2-AC-24 birthParentValid checks EIGHT fields', () {
      // Death has no analogue: its steps 3/4 are `skip || fullName.trim()`.
      const List<String> eight = <String>[
        'fullName', 'dob', 'ethnicity', 'nationality',
        'maritalStatus', 'addrVillage', 'addrProvince', 'censusOrId',
      ];
      final Map<String, BirthParentInfo Function(BirthParentInfo)> blank =
          <String, BirthParentInfo Function(BirthParentInfo)>{
        'fullName': (BirthParentInfo p) => p.copyWith(fullName: ''),
        'dob': (BirthParentInfo p) => p.copyWith(dob: ''),
        'ethnicity': (BirthParentInfo p) => p.copyWith(ethnicity: ''),
        'nationality': (BirthParentInfo p) => p.copyWith(nationality: ''),
        'maritalStatus': (BirthParentInfo p) => p.copyWith(maritalStatus: ''),
        'addrVillage': (BirthParentInfo p) => p.copyWith(addrVillage: ''),
        'addrProvince': (BirthParentInfo p) => p.copyWith(addrProvince: ''),
        'censusOrId': (BirthParentInfo p) => p.copyWith(censusOrId: ''),
      };
      expect(birthParentValid(validParent('m')), isTrue);
      for (final String field in eight) {
        expect(birthParentValid(blank[field]!(validParent('m'))), isFalse,
            reason: 'blanking $field must block — it is one of the eight');
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-69 — the toggle does not clear the record
  // ───────────────────────────────────────────────────────────────────────────
  test('F2-AC-69 toggling fatherUnknown twice restores every typed value',
      () {
    final BirthFormCubit c = build();
    c.setField((BirthFormData _) => filledForm());
    final BirthParentInfo before = c.state.form.father;
    expect(before.fullName, 'Name father');

    c.toggleFatherUnknown();
    expect(c.state.form.fatherUnknown, isTrue);
    expect(c.state.form.father.fullName, 'Name father',
        reason: 'the record is NOT cleared while hidden');

    c.toggleFatherUnknown();
    expect(c.state.form.fatherUnknown, isFalse);
    expect(c.state.form.father.censusOrId, before.censusOrId);
    expect(c.state.form.father.maritalStatus, before.maritalStatus);
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-48 — methodCode(), four cases
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-48 methodCode is no-arg and prefers an enabled qr row', () {
    PaymentMethod m(String code, PaymentMethodKind kind, {bool enabled = true}) =>
        PaymentMethod(
          id: code,
          code: code,
          label: Bilingual(en: code, lo: code),
          kind: kind,
          enabled: enabled,
        );

    test('qr found → that row', () {
      expect(
        birthMethodCode(<PaymentMethod>[
          m('bank-x', PaymentMethodKind.bank),
          m('qr-x', PaymentMethodKind.qr),
        ]),
        'qr-x',
        reason: 'first enabled qr wins even when a bank row precedes it',
      );
    });

    test('qr absent, another enabled → the first enabled of any kind', () {
      expect(
        birthMethodCode(<PaymentMethod>[
          m('bank-x', PaymentMethodKind.bank),
          m('bank-y', PaymentMethodKind.bank),
        ]),
        'bank-x',
      );
    });

    test('a DISABLED qr row is skipped, not preferred', () {
      expect(
        birthMethodCode(<PaymentMethod>[
          m('qr-off', PaymentMethodKind.qr, enabled: false),
          m('bank-x', PaymentMethodKind.bank),
        ]),
        'bank-x',
      );
    });

    test('none enabled → "laoqr"', () {
      expect(
        birthMethodCode(<PaymentMethod>[
          m('qr-off', PaymentMethodKind.qr, enabled: false),
          m('bank-off', PaymentMethodKind.bank, enabled: false),
        ]),
        'laoqr',
      );
    });

    test('empty list → "laoqr"', () {
      expect(birthMethodCode(const <PaymentMethod>[]), 'laoqr');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-49 / 50 / 52 — pay is a SEPARATE mutation
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-49/50/52 the pay seam', () {
    test('F2-AC-49 a submit issues NO pay call', () async {
      int payCalls = 0;
      final BirthFormCubit c = ready(
        pay: (String id, {required String methodCode}) async {
          payCalls++;
          return const Right<Failure, Object?>(<String, Object?>{});
        },
      );

      await c.next();

      expect(c.state.submitted, isNotNull);
      expect(repo.log, <String>['create', 'update', 'attach:child.hospital_notice', 'submit'],
          reason: 'submitCase ends at submit — Resident pays inside it, Birth '
              'does not (`:815-845`)');
      expect(payCalls, 0,
          reason: 'pay is fired from the success screen, never by submit');
    });

    test('F2-AC-50/52 payNow charges, reads the receipt, and flips unpaid',
        () async {
      String? seenMethod;
      final BirthFormCubit c = ready(
        methods: <PaymentMethod>[
          PaymentMethod(
            id: 'q', code: 'laoqr-live',
            label: const Bilingual(en: 'QR', lo: 'QR'),
            kind: PaymentMethodKind.qr, enabled: true,
          ),
        ],
        pay: (String id, {required String methodCode}) async {
          seenMethod = methodCode;
          return const Right<Failure, Object?>(
            <String, Object?>{'receipt_no': 'RC-1'},
          );
        },
      );

      // The page fetches the methods on mount; `methodCode()` reads that
      // list. Without this the cubit correctly falls back to "laoqr" — which
      // is the right behaviour and the wrong test.
      await c.loadMethods();
      await c.next();
      expect(c.state.unpaid, isTrue, reason: 'fee 20000 > 0 and no receipt');

      await c.payNow();

      expect(seenMethod, 'laoqr-live', reason: 'methodCode() fed the call');
      expect(c.state.receiptNo, 'RC-1');
      expect(c.state.unpaid, isFalse, reason: 'the button stops rendering');
      expect(c.state.payPending, isFalse);
      expect(c.state.payError, isNull);
    });

    test('F2-AC-52 the receipt resolves flat first, then nested, then null',
        () async {
      expect(birthReceiptOf(<String, Object?>{'receipt_no': 'FLAT'}), 'FLAT');
      expect(
        birthReceiptOf(<String, Object?>{
          'transaction': <String, Object?>{'receipt_no': 'NESTED'},
        }),
        'NESTED',
      );
      expect(
        birthReceiptOf(<String, Object?>{
          'receipt_no': 'FLAT',
          'transaction': <String, Object?>{'receipt_no': 'NESTED'},
        }),
        'FLAT',
        reason: '`receipt_no ?? transaction?.receipt_no` — flat wins',
      );
      expect(birthReceiptOf(<String, Object?>{}), isNull);
      expect(birthReceiptOf(null), isNull);
    });

    test('F2-AC-50 a zero-fee case is NOT unpaid, so no button renders',
        () async {
      final BirthFormCubit c = ready();
      repo.submitFeeLak = 0;
      await c.next();
      expect(c.state.submitted, isNotNull);
      expect(c.state.unpaid, isFalse, reason: 'fee_lak == 0');
    });

    test('F2-AC-52 a pay FAILURE clears nothing and leaves the button live',
        () async {
      final BirthFormCubit c = ready(
        pay: (String id, {required String methodCode}) async =>
            const Left<Failure, Object?>(Failure('INSUFFICIENT_FUNDS')),
      );
      await c.next();
      final int stepBefore = c.state.step;

      await c.payNow();

      expect(c.state.payError, 'INSUFFICIENT_FUNDS');
      expect(c.state.submitted, isNotNull, reason: 'submitted is NOT cleared');
      expect(c.state.receiptNo, isNull);
      expect(c.state.unpaid, isTrue, reason: 'still unpaid — button stays');
      expect(c.state.step, stepBefore, reason: 'no navigation');
    });

    test('payNow guards re-entry and a missing submission', () async {
      final BirthFormCubit c = build();
      await c.payNow();
      expect(c.state.payPending, isFalse,
          reason: '`if (!submitted || payCase.pending) return` — `:894`');
      expect(c.state.payError, isNull);
    });

    test('no port wired: the case still submits and NO receipt is fabricated',
        () async {
      final BirthFormCubit c = ready();
      await c.next();
      expect(c.state.submitted, isNotNull);
      await c.payNow();
      expect(c.state.receiptNo, isNull,
          reason: 'an absent capability is never reported as a charge');
      expect(c.state.payError, isNotNull, reason: 'and it fails visibly');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-54 — the retry semantics
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-54 retry semantics', () {
    test('the draft is created ONCE; update runs on EVERY attempt', () async {
      final BirthFormCubit c = ready();
      repo.failSubmit = true;

      await c.next();
      expect(repo.log, <String>[
        'create', 'update', 'attach:child.hospital_notice', 'submit',
      ]);
      expect(c.state.draft, isNotNull);

      repo.failSubmit = false;
      await c.next();

      expect(repo.log.where((String e) => e == 'create').length, 1,
          reason: '`if (!current)` — a retry reuses {id, reference_no}');
      expect(repo.log.where((String e) => e == 'update').length, 2,
          reason: 'update runs every attempt — it writes header.document_no');
      expect(
          repo.log.where((String e) => e.startsWith('attach:')).length, 1,
          reason: 'the uploaded set skips an already-sent slot');
      expect(c.state.submitted, isNotNull);
    });

    test('exactly ONE attachment slot, kind "document"', () async {
      final BirthFormCubit c = ready();
      await c.next();
      final List<String> attaches =
          repo.log.where((String e) => e.startsWith('attach:')).toList();
      expect(attaches, <String>['attach:child.hospital_notice']);
      expect(kBirthAttachmentSlot, 'child.hospital_notice');
      expect(kBirthAttachmentKind, 'document');
      expect(c.uploadedSlots, <String>{'child.hospital_notice'});
    });

    test('no attachment picked → no upload call at all', () async {
      final BirthFormCubit c = build();
      c
        ..setField((BirthFormData _) =>
            filledForm().copyWith(clearHospitalNotice: true))
        ..emit(c.state.copyWith(step: kBirthStepCount));
      // Step 2 would block, but `next()` is driven from step 6 where
      // `canProceed` is unconditionally true — the guard under test is the
      // upload's null check, not the wizard's.
      await c.next();
      expect(repo.log.where((String e) => e.startsWith('attach:')), isEmpty);
    });

    test('the update envelope carries form_data FIRST and the create LAST',
        () async {
      final BirthFormCubit c = ready();
      await c.next();
      expect(repo.lastCreateEnvelope!.keys.last, 'form_data');
      expect(repo.lastUpdateEnvelope!.keys.first, 'form_data');
      final Map<String, Object?> updatePayload =
          repo.lastUpdateEnvelope!['form_data']! as Map<String, Object?>;
      expect(updatePayload.keys.last, 'header.document_no');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-63 / 64 / 65 / 66 — the 422 path and its two absences
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-63/64/65 the 422 path', () {
    ApiFailure validation(List<String> fields) => ApiFailure(
          ApiException(
            status: 422,
            code: ApiCode.validationError,
            message: 'Some fields are missing.',
            fields: <FieldError>[
              for (final String f in fields)
                FieldError(field: f, message: 'required'),
            ],
          ),
          'Some fields are missing.',
        );

    test('F2-AC-65 a 422 naming a step-5 and a step-2 field lands on STEP 2',
        () async {
      final BirthFormCubit c = ready();
      repo.submitFailure = validation(
        <String>['informant.informant_phone', 'child.child_name'],
      );

      await c.next();

      expect(c.state.step, 2, reason: 'the EARLIEST offending step');
      expect(c.state.serverErrors.keys.toSet(),
          <String>{'informant.informant_phone', 'child.child_name'});
      expect(c.state.scrollToErrorTick, greaterThan(0));
    });

    test('F2-AC-63 a 422 naming ONLY father fields does NOT navigate',
        () async {
      // The defect this batch ports rather than repairs: no `parents.father.*`
      // key is in `FIELD_STEP`, `stepOfFirstError` skips unmapped keys and
      // returns null, and the call site is `if (target) setStep(target)`. The
      // citizen stays on step 6 with errors bound to step-4 controls.
      final BirthFormCubit c = ready();
      final int stepBefore = c.state.step;
      expect(stepBefore, 6);
      repo.submitFailure = validation(
        <String>['parents.father.name', 'parents.father.dob'],
      );

      await c.next();

      expect(c.state.step, stepBefore,
          reason: 'unmapped keys route nowhere — `formValidation.tsx:172-183`');
      expect(c.state.serverErrors.keys.toSet(),
          <String>{'parents.father.name', 'parents.father.dob'},
          reason: 'the errors ARE set, and the scroll DOES run');
      expect(c.state.scrollToErrorTick, greaterThan(0));
      // And the mapping really is absent — the behaviour above is not an
      // accident of the fixture.
      expect(
          kBirthFieldStep.keys.where((String k) => k.startsWith('parents.father')),
          isEmpty);
    });

    test('F2-AC-64 a NON-validation error does not navigate and clears nothing',
        () async {
      final BirthFormCubit c = ready();
      final int stepBefore = c.state.step;
      repo.submitFailure = ApiFailure(
        const ApiException(
          status: 500,
          code: ApiCode.internalError,
          message: 'Something went wrong.',
        ),
        'Something went wrong.',
      );

      await c.next();

      expect(c.state.step, stepBefore, reason: 'the catch has no else branch');
      expect(c.state.serverErrors, isEmpty);
      expect(c.state.form.child.fullName, 'Test Child',
          reason: 'the form is untouched');
      expect(c.state.submitError, 'Something went wrong.');
      expect(c.state.submitted, isNull);
    });

    test('F2-AC-66 the double-tap guard is in the CUBIT', () async {
      final BirthFormCubit c = ready();
      // Two concurrent taps; the second must be ignored by `submitPending`.
      final Future<void> first = c.next();
      final Future<void> second = c.next();
      await Future.wait<void>(<Future<void>>[first, second]);
      expect(repo.log.where((String e) => e == 'create').length, 1,
          reason: 'the second tap returned early — `:864`');
    });

    test('serverErrors are cleared BEFORE the attempt, not after', () async {
      final BirthFormCubit c = ready();
      repo.submitFailure = validation(<String>['child.child_name']);
      await c.next();
      expect(c.state.serverErrors, isNotEmpty);

      // The 422 routed to step 2, so a bare `next()` from there only
      // advances. `setServerErrors({})` lives in the submit branch (`:877`),
      // so the wizard has to be back on the last step to reach it.
      expect(c.state.step, 2);
      repo.submitFailure = null;
      c.emit(c.state.copyWith(step: kBirthStepCount));
      await c.next();
      expect(c.state.serverErrors, isEmpty, reason: '`:877`');
      expect(c.state.submitted, isNotNull);
    });

    test('editing a field clears just that server error', () {
      final BirthFormCubit c = build();
      c.emit(c.state.copyWith(serverErrors: const <String, String>{
        'child.child_name': 'required',
        'child.child_dob': 'required',
      }));
      c.patchChild((BirthChildInfo x) => x.copyWith(fullName: 'A'),
          path: 'child.child_name');
      expect(c.state.serverErrors.keys, <String>['child.child_dob']);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Navigation
  // ───────────────────────────────────────────────────────────────────────────
  group('navigation', () {
    test('next() advances and goBack() retreats; step 1 back leaves the page',
        () async {
      final BirthFormCubit c = build();
      c.setField((BirthFormData _) => filledForm());

      await c.next();
      expect(c.state.step, 2);
      expect(c.goBack(), isFalse);
      expect(c.state.step, 1);
      expect(c.goBack(), isTrue, reason: 'the caller should call onBack()');
    });

    test('an incomplete step reveals errors instead of advancing', () async {
      final BirthFormCubit c = build();
      await c.next();
      expect(c.state.step, 1, reason: 'blank header cannot advance');
      expect(c.state.showErrors, isTrue);
      expect(c.state.scrollToErrorTick, greaterThan(0));
    });

    test('F2-AC-68 birthOrder strips non-digits and truncates to two', () {
      final BirthFormCubit c = build();
      c.setBirthOrder('a1b2c3');
      expect(c.state.form.child.birthOrder, '12');
      c.setBirthOrder('');
      expect(c.state.form.child.birthOrder, '');
      c.setBirthOrder('7');
      expect(c.state.form.child.birthOrder, '7');
    });
  });
}

class _FakeReferenceRepo implements ReferenceRepository {
  @override
  Future<Either<Failure, List<LookupOption>>> options(
    LookupKey key, {
    String? parentId,
    PagingMode paging = PagingMode.all,
  }) async =>
      Right<Failure, List<LookupOption>>(<LookupOption>[
        const LookupOption(
          id: 'lao',
          code: 'lao',
          label: Bilingual(en: 'Lao', lo: 'ລາວ'),
        ),
      ]);
}

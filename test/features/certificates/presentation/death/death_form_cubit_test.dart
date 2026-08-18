/// `DeathFormCubit` — the page's whole state machine, driven.
///
/// Parallel in shape to `birth_form_cubit_test.dart` and sharing nothing with
/// it. The arms differ where the pages differ: **two** independent skip
/// toggles, a `canProceed` whose steps 3 and 4 are `skip || fullName.trim()`
/// rather than an eight-field `parentValid`, and two client-side
/// over-requirements (`ethnicGroup`, `religion`) for keys that are **not in
/// Death's 41-entry schema table at all**.
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
import 'package:lcc_mobile_app/features/certificates/presentation/death/death_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/death/death_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/death/death_payload.dart';
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

DeathFormData filledForm() => DeathFormData(
      province: 'p-1',
      district: 'd-1',
      village: 'v-1',
      deceased: const DeathDeceasedInfo(
        fullName: 'Test Deceased',
        gender: 'female',
        dob: '1950-01-01',
        ethnicity: 'lao-loum',
        nationality: 'lao',
        ethnicGroup: 'lao-tai',
        religion: 'buddhist',
        maritalStatus: 'married',
        addrVillage: 'v-2',
        addrProvince: 'p-2',
        censusOrId: 'CB-DEC',
        podVillage: 'v-3',
        podProvince: 'p-3',
        dateOfDeath: '2026-07-21',
        cause: 'illness',
      ),
      deathNotice: file('notice.pdf'),
      // Only `fullName` is mandatory on a Death parent.
      mother: const DeathParentInfo(fullName: 'Test Mother'),
      father: const DeathParentInfo(fullName: 'Test Father'),
      informant: const DeathInformantInfo(
        fullName: 'Test Informant',
        dob: '1990-07-04',
        addrVillage: 'v-4',
        addrProvince: 'p-4',
        censusOrId: 'CB-INF',
        relationship: 'uncle',
        phone: '02055500101',
      ),
    );

void main() {
  late FakeApplicationRepository repo;

  DeathFormCubit build({
    DeathPayPort? pay,
    List<PaymentMethod> methods = const <PaymentMethod>[],
  }) {
    repo = FakeApplicationRepository();
    return DeathFormCubit(
      clock: SubmissionClock.fixed(kInstant),
      getLookupOptions: GetLookupOptions(repository: _FakeReferenceRepo()),
      createApplication: CreateApplication(repository: repo),
      updateApplication: UpdateApplication(repository: repo),
      addAttachment: AddAttachment(repository: repo),
      submitApplication: SubmitApplication(repository: repo),
      loadService: () async => Right<Failure, Service>(serviceFixture()),
      loadPaymentMethods: () async =>
          Right<Failure, List<PaymentMethod>>(methods),
      // The `death` namespace. Never `birth`'s — their Lao differs.
      readLegalBasisText: () => 'DEATH LEGAL BASIS',
      pay: pay,
    );
  }

  DeathFormCubit ready({
    DeathPayPort? pay,
    List<PaymentMethod> methods = const <PaymentMethod>[],
  }) {
    final DeathFormCubit c = build(pay: pay, methods: methods);
    c
      ..setField((DeathFormData _) => filledForm())
      ..emit(c.state.copyWith(step: kDeathStepCount));
    return c;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-59 — canProceed, all six arms
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-59 canProceed, all six arms', () {
    void arm(int step, String what, DeathFormData Function(DeathFormData) break_) {
      test('step $step passes when complete and fails on $what', () {
        expect(deathCanProceed(filledForm(), step), isTrue);
        expect(deathCanProceed(break_(filledForm()), step), isFalse,
            reason: 'step $step should fail when $what');
      });
    }

    arm(1, 'the header village is blank',
        (DeathFormData f) => f.copyWith(village: ''));
    arm(
      2,
      'the date of death is blank',
      (DeathFormData f) =>
          f.copyWith(deceased: f.deceased.copyWith(dateOfDeath: '')),
    );
    arm(
      3,
      'the mother name is blank and she is not skipped',
      (DeathFormData f) => f.copyWith(mother: const DeathParentInfo()),
    );
    arm(
      4,
      'the father name is blank and he is not skipped',
      (DeathFormData f) => f.copyWith(father: const DeathParentInfo()),
    );
    arm(
      5,
      'the informant phone is blank',
      (DeathFormData f) =>
          f.copyWith(informant: f.informant.copyWith(phone: '')),
    );

    test('step 6 is unconditionally true — it is Review', () {
      expect(deathCanProceed(const DeathFormData(), 6), isTrue);
    });

    test('F2-AC-61 step 2 blocks on ethnicGroup AND religion — neither of '
        'which is in Death\'s schema table', () {
      final DeathFormData f = filledForm();
      expect(deathCanProceed(f, 2), isTrue);
      expect(
          deathCanProceed(
              f.copyWith(deceased: f.deceased.copyWith(ethnicGroup: '')), 2),
          isFalse);
      expect(
          deathCanProceed(
              f.copyWith(deceased: f.deceased.copyWith(religion: '')), 2),
          isFalse);
      // The half that makes these genuine over-requirements, unlike Birth's.
      expect(kDeathFieldStep.containsKey('deceased.deceased_ethnic_group'),
          isFalse);
      expect(kDeathFieldStep.containsKey('deceased.deceased_religion'), isFalse);
    });

    test('F2-AC-62 step 2 carries the cause conditional', () {
      final DeathFormData f = filledForm();
      expect(
          deathCanProceed(
              f.copyWith(
                  deceased: f.deceased.copyWith(cause: 'other', causeOther: '')),
              2),
          isFalse);
      expect(
          deathCanProceed(
              f.copyWith(
                  deceased:
                      f.deceased.copyWith(cause: 'other', causeOther: 'x')),
              2),
          isTrue);
      // Not "other": causeOther is irrelevant to progression.
      expect(
          deathCanProceed(
              f.copyWith(
                  deceased:
                      f.deceased.copyWith(cause: 'illness', causeOther: '')),
              2),
          isTrue);
    });

    test('F2-AC-24 steps 3/4 require ONLY fullName — no parentValid analogue',
        () {
      // Birth's equivalent checks eight fields. Death's checks one, and every
      // other field on the record may be blank.
      final DeathFormData f = filledForm().copyWith(
        mother: const DeathParentInfo(fullName: 'M'),
        father: const DeathParentInfo(fullName: 'F'),
      );
      expect(deathCanProceed(f, 3), isTrue,
          reason: 'no dob, no ethnicity, no address, no id — still valid');
      expect(deathCanProceed(f, 4), isTrue);
    });

    test('F2-AC-24 either skip short-circuits its own step, independently', () {
      final DeathFormData blank = filledForm().copyWith(
        mother: const DeathParentInfo(),
        father: const DeathParentInfo(),
      );
      expect(deathCanProceed(blank, 3), isFalse);
      expect(deathCanProceed(blank, 4), isFalse);
      expect(deathCanProceed(blank.copyWith(motherSkip: true), 3), isTrue);
      expect(deathCanProceed(blank.copyWith(motherSkip: true), 4), isFalse,
          reason: 'the mother skip does NOT unlock the father step');
      expect(deathCanProceed(blank.copyWith(fatherSkip: true), 4), isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-69 — two independent toggles, neither clearing its record
  // ───────────────────────────────────────────────────────────────────────────
  test('F2-AC-69 the two toggles are independent and clear nothing', () {
    final DeathFormCubit c = build();
    c.setField((DeathFormData _) => filledForm());

    c.toggleMotherSkip();
    expect(c.state.form.motherSkip, isTrue);
    expect(c.state.form.fatherSkip, isFalse, reason: 'independent');
    expect(c.state.form.mother.fullName, 'Test Mother',
        reason: 'the record survives being hidden');

    c.toggleFatherSkip();
    expect(c.state.form.motherSkip, isTrue);
    expect(c.state.form.fatherSkip, isTrue);

    c
      ..toggleMotherSkip()
      ..toggleFatherSkip();
    expect(c.state.form.motherSkip, isFalse);
    expect(c.state.form.fatherSkip, isFalse);
    expect(c.state.form.mother.fullName, 'Test Mother');
    expect(c.state.form.father.fullName, 'Test Father');
  });

  test('F2-AC-31 motherSkip collapses TWO prefixes through the real cubit path',
      () async {
    // The property `specs.md` § 11 item 7 tells a reviewer to check, driven
    // rather than computed: 54 keys, not 67.
    final DeathFormCubit c = ready();
    c.toggleMotherSkip();
    await c.next();

    final Map<String, Object?> payload =
        repo.lastUpdateEnvelope!['form_data']! as Map<String, Object?>;
    // 54 create keys + `header.document_no`.
    expect(payload.length, 55);
    expect(payload['parents.status'], 'deceased-or-unknown');
    expect(payload['parents.mother.status'], 'deceased-or-unknown');
    expect(
        payload.keys.where((String k) => k.startsWith('parents.father.')).length,
        14,
        reason: 'the father block is untouched by the mother skip');
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
        deathMethodCode(<PaymentMethod>[
          m('bank-x', PaymentMethodKind.bank),
          m('qr-x', PaymentMethodKind.qr),
        ]),
        'qr-x',
      );
    });

    test('qr absent, another enabled → the first enabled of any kind', () {
      expect(
        deathMethodCode(<PaymentMethod>[
          m('bank-x', PaymentMethodKind.bank),
          m('bank-y', PaymentMethodKind.bank),
        ]),
        'bank-x',
      );
    });

    test('a DISABLED qr row is skipped', () {
      expect(
        deathMethodCode(<PaymentMethod>[
          m('qr-off', PaymentMethodKind.qr, enabled: false),
          m('bank-x', PaymentMethodKind.bank),
        ]),
        'bank-x',
      );
    });

    test('none enabled → "laoqr"; empty list → "laoqr"', () {
      expect(
        deathMethodCode(<PaymentMethod>[
          m('bank-off', PaymentMethodKind.bank, enabled: false),
        ]),
        'laoqr',
      );
      expect(deathMethodCode(const <PaymentMethod>[]), 'laoqr');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-49 / 50 / 52 — the pay seam
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-49/50/52 the pay seam', () {
    test('F2-AC-49 a submit issues NO pay call', () async {
      int payCalls = 0;
      final DeathFormCubit c = ready(
        pay: (String id, {required String methodCode}) async {
          payCalls++;
          return const Right<Failure, Object?>(<String, Object?>{});
        },
      );

      await c.next();

      expect(repo.log, <String>[
        'create', 'update', 'attach:deceased.death_notice', 'submit',
      ]);
      expect(payCalls, 0);
    });

    test('F2-AC-50/52 payNow charges and flips unpaid', () async {
      final DeathFormCubit c = ready(
        pay: (String id, {required String methodCode}) async =>
            const Right<Failure, Object?>(<String, Object?>{
          'transaction': <String, Object?>{'receipt_no': 'RC-NESTED'},
        }),
      );
      await c.next();
      expect(c.state.unpaid, isTrue);

      await c.payNow();

      expect(c.state.receiptNo, 'RC-NESTED',
          reason: 'the nested shape resolves when the flat one is absent');
      expect(c.state.unpaid, isFalse);
    });

    test('F2-AC-52 receipt precedence: flat, then nested, then null', () {
      expect(deathReceiptOf(<String, Object?>{'receipt_no': 'FLAT'}), 'FLAT');
      expect(
        deathReceiptOf(<String, Object?>{
          'receipt_no': 'FLAT',
          'transaction': <String, Object?>{'receipt_no': 'NESTED'},
        }),
        'FLAT',
      );
      expect(deathReceiptOf(<String, Object?>{}), isNull);
      expect(deathReceiptOf(null), isNull);
    });

    test('F2-AC-50 a zero-fee case is not unpaid', () async {
      final DeathFormCubit c = ready();
      repo.submitFeeLak = 0;
      await c.next();
      expect(c.state.unpaid, isFalse);
    });

    test('F2-AC-52 a pay failure clears nothing', () async {
      final DeathFormCubit c = ready(
        pay: (String id, {required String methodCode}) async =>
            const Left<Failure, Object?>(Failure('DECLINED')),
      );
      await c.next();
      await c.payNow();
      expect(c.state.payError, 'DECLINED');
      expect(c.state.submitted, isNotNull);
      expect(c.state.unpaid, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-54 — retry semantics
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-54 retry semantics', () {
    test('draft created once, update every attempt, slot uploaded once',
        () async {
      final DeathFormCubit c = ready();
      repo.failSubmit = true;
      await c.next();

      repo.failSubmit = false;
      await c.next();

      expect(repo.log.where((String e) => e == 'create').length, 1);
      expect(repo.log.where((String e) => e == 'update').length, 2);
      expect(repo.log.where((String e) => e.startsWith('attach:')).length, 1);
      expect(c.uploadedSlots, <String>{'deceased.death_notice'});
    });

    test('exactly ONE attachment slot, kind "document"', () async {
      final DeathFormCubit c = ready();
      await c.next();
      expect(
        repo.log.where((String e) => e.startsWith('attach:')).toList(),
        <String>['attach:deceased.death_notice'],
      );
      expect(kDeathAttachmentSlot, 'deceased.death_notice');
      expect(kDeathAttachmentKind, 'document');
    });

    test('create puts form_data LAST, update puts it FIRST', () async {
      final DeathFormCubit c = ready();
      await c.next();
      expect(repo.lastCreateEnvelope!.keys.last, 'form_data');
      expect(repo.lastUpdateEnvelope!.keys.first, 'form_data');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-63 / 64 / 65 — the 422 path
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

    test('F2-AC-65 a step-5 and a step-2 field land on STEP 2', () async {
      final DeathFormCubit c = ready();
      repo.submitFailure = validation(
        <String>['informant.informant_phone', 'deceased.deceased_name'],
      );
      await c.next();
      expect(c.state.step, 2);
      expect(c.state.scrollToErrorTick, greaterThan(0));
    });

    test('F2-AC-63 a 422 naming ONLY father fields does NOT navigate',
        () async {
      final DeathFormCubit c = ready();
      expect(c.state.step, 6);
      repo.submitFailure = validation(
        <String>['parents.father.name', 'parents.father.workplace'],
      );

      await c.next();

      expect(c.state.step, 6, reason: 'all 14 father keys are unroutable');
      expect(c.state.serverErrors.keys.length, 2);
      expect(c.state.scrollToErrorTick, greaterThan(0));
      expect(
          kDeathFieldStep.keys.where((String k) => k.startsWith('parents.father')),
          isEmpty);
    });

    test('F2-AC-63 informant.informant_ethnicity routes to step 5 even though '
        'nothing on step 5 can satisfy it', () async {
      // The latent source defect § 6.13 records: the key is routable, and
      // Death's informant block emits no ethnicity. Ported as measured.
      expect(kDeathFieldStep['informant.informant_ethnicity'], 5);
      final DeathFormCubit c = ready();
      repo.submitFailure = validation(<String>['informant.informant_ethnicity']);
      await c.next();
      expect(c.state.step, 5, reason: 'it routes — and the citizen can do '
          'nothing about it, which is the source\'s behaviour');
    });

    test('F2-AC-64 a NON-validation error does not navigate or clear',
        () async {
      final DeathFormCubit c = ready();
      repo.submitFailure = ApiFailure(
        const ApiException(
          status: 500,
          code: ApiCode.internalError,
          message: 'Something went wrong.',
        ),
        'Something went wrong.',
      );
      await c.next();
      expect(c.state.step, 6);
      expect(c.state.serverErrors, isEmpty);
      expect(c.state.form.deceased.fullName, 'Test Deceased');
      expect(c.state.submitError, 'Something went wrong.');
    });

    test('F2-AC-66 the double-tap guard is in the CUBIT', () async {
      final DeathFormCubit c = ready();
      await Future.wait<void>(<Future<void>>[c.next(), c.next()]);
      expect(repo.log.where((String e) => e == 'create').length, 1);
    });
  });

  test('navigation: advance, retreat, and leave from step 1', () async {
    final DeathFormCubit c = build();
    c.setField((DeathFormData _) => filledForm());
    await c.next();
    expect(c.state.step, 2);
    expect(c.goBack(), isFalse);
    expect(c.goBack(), isTrue);
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

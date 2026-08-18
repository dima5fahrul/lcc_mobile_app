/// Birth's recorded request log — `B4-AC-25`…`B4-AC-28`, specs.md § 6.8.
///
/// See `resident_golden_test.dart`'s header for how the golden was produced and
/// why recording it **before** the migration is the whole instrument.
///
/// ## What makes Birth's log different, and why that is the point
///
/// **There is no `/pay` entry.** `submission_plan.dart:198-203` omits
/// `SubmissionStep.pay` from Birth's `steps`, because payment is a separate
/// mutation the review step fires (`BirthDeclarationPage.tsx:847-853`), not a
/// step inside `submitCase`. `B4-AC-19` reads that absence off this log: a
/// migration that routed pay through the executor for every form would show up
/// here as a thirteenth entry.
///
/// **There is exactly one attachment.** Birth sends `child.hospital_notice`
/// and nothing else, where Resident sends five — so this log also pins that the
/// executor does not invent an upload loop shape the page has not got.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/application/domain/usecases/application_usecases.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/certificate_form.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/birth/birth_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/birth/birth_form_state.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_key.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_option.dart';
import 'package:lcc_mobile_app/features/reference/domain/repositories/reference_repository.dart';
import 'package:lcc_mobile_app/features/reference/domain/usecases/get_lookup_options.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/payment_method.dart';

import 'submission_golden_harness.dart';

PickedAttachment _file(String name) =>
    PickedAttachment(name: name, bytes: null);

/// `birth_form_cubit_test.dart:51-61` — all eight fields of `birthParentValid`.
BirthParentInfo _validParent(String tag) => BirthParentInfo(
      fullName: 'Name $tag',
      dob: '1968-02-14',
      ethnicity: 'lao-loum',
      nationality: 'lao',
      maritalStatus: 'married',
      addrVillage: 'v-$tag',
      addrProvince: 'p-$tag',
      censusOrId: 'CB-$tag',
    );

/// `birth_form_cubit_test.dart:63-95`, transcribed — that file declares a
/// `main()` and cannot be imported.
BirthFormData filledBirthForm() => BirthFormData(
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
      hospitalNotice: _file('notice.pdf'),
      mother: _validParent('mother'),
      father: _validParent('father'),
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

Future<List<WireEntry>> _driveBirth() async {
  final SubmissionWireHarness harness =
      SubmissionWireHarness.build(responder: goldenResponder);

  final BirthFormCubit cubit = BirthFormCubit(
    clock: SubmissionClock.fixed(kGoldenInstant),
    getLookupOptions: GetLookupOptions(repository: _InertReferenceRepo()),
    createApplication: CreateApplication(repository: harness.applications),
    updateApplication: UpdateApplication(repository: harness.applications),
    addAttachment: AddAttachment(repository: harness.applications),
    submitApplication: SubmitApplication(repository: harness.applications),
    loadService: () async =>
        const Left<Failure, Service>(Failure('not read by the submit path')),
    loadPaymentMethods: () async =>
        const Right<Failure, List<PaymentMethod>>(<PaymentMethod>[]),
    readLegalBasisText: () => 'BIRTH LEGAL BASIS',
    // `pay` is deliberately absent: Birth's `submitCase` has no pay step, so a
    // port here would be a capability the recorded path never reaches.
  );

  cubit.setField((BirthFormData _) => filledBirthForm());
  // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
  cubit.emit(cubit.state.copyWith(step: kBirthStepCount));

  await cubit.next();
  expect(
    cubit.state.submitError,
    isNull,
    reason: 'the first attempt must succeed, or this is a failure log',
  );
  expect(cubit.state.submitted, isNotNull);

  // The retry — the draft is held and the one slot is already in `_uploaded`.
  await cubit.next();
  expect(cubit.state.submitError, isNull);

  await cubit.close();
  return harness.entries;
}

void main() {
  goldenSuite(
    form: CertificateForm.birth,
    drive: _driveBirth,
    expectedSequence: <String>[
      'POST /applications',
      'PATCH /applications/case-1',
      'POST /applications/case-1/attachments',
      'POST /applications/case-1/submit',
      // The retry — no create, no attachment. And **no `/pay` anywhere**.
      'PATCH /applications/case-1',
      'POST /applications/case-1/submit',
    ],
  );
}

class _InertReferenceRepo implements ReferenceRepository {
  @override
  Future<Either<Failure, List<LookupOption>>> options(
    LookupKey key, {
    String? parentId,
    PagingMode paging = PagingMode.all,
  }) async =>
      const Right<Failure, List<LookupOption>>(<LookupOption>[]);
}

/// Death's recorded request log — `B4-AC-25`…`B4-AC-28`, specs.md § 6.8.
///
/// See `resident_golden_test.dart`'s header for how the golden was produced and
/// why recording it **before** the migration is the whole instrument.
///
/// Death is Birth's shape: `submission_plan.dart:225-230` omits
/// `SubmissionStep.pay` (`DeathDeclarationPage.tsx:871-877` fires `payCase`
/// from the review step instead), and one attachment slot rather than five.
/// Both facts are read off this log by `B4-AC-19` and `B4-AC-21`.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/application/domain/usecases/application_usecases.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/certificate_form.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/death/death_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/death/death_form_state.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_key.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_option.dart';
import 'package:lcc_mobile_app/features/reference/domain/repositories/reference_repository.dart';
import 'package:lcc_mobile_app/features/reference/domain/usecases/get_lookup_options.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/payment_method.dart';

import 'submission_golden_harness.dart';

PickedAttachment _file(String name) =>
    PickedAttachment(name: name, bytes: null);

/// `death_form_cubit_test.dart`'s `filledForm()`, transcribed — that file
/// declares a `main()` and cannot be imported.
DeathFormData filledDeathForm() => DeathFormData(
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
      deathNotice: _file('notice.pdf'),
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

Future<List<WireEntry>> _driveDeath() async {
  final SubmissionWireHarness harness =
      SubmissionWireHarness.build(responder: goldenResponder);

  final DeathFormCubit cubit = DeathFormCubit(
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
    readLegalBasisText: () => 'DEATH LEGAL BASIS',
  );

  cubit.setField((DeathFormData _) => filledDeathForm());
  // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
  cubit.emit(cubit.state.copyWith(step: kDeathStepCount));

  await cubit.next();
  expect(
    cubit.state.submitError,
    isNull,
    reason: 'the first attempt must succeed, or this is a failure log',
  );
  expect(cubit.state.submitted, isNotNull);

  await cubit.next();
  expect(cubit.state.submitError, isNull);

  await cubit.close();
  return harness.entries;
}

void main() {
  goldenSuite(
    form: CertificateForm.death,
    drive: _driveDeath,
    expectedSequence: <String>[
      'POST /applications',
      'PATCH /applications/case-1',
      'POST /applications/case-1/attachments',
      'POST /applications/case-1/submit',
      // The retry — and **no `/pay` anywhere**.
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

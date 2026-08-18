/// Resident's recorded request log — `B4-AC-25`…`B4-AC-28`, specs.md § 6.8.
///
/// ## How the golden was produced, and why the order of those two events IS the
/// instrument
///
/// `resident.golden.json` was recorded from the **pre-migration** cubit, before
/// `submission_executor.dart` existed, by running:
///
/// ```
/// flutter test --dart-define=RECORD_GOLDEN=true \
///   test/features/certificates/submission_golden/
/// ```
///
/// A golden recorded *after* the migration measures the migration against
/// itself — the executor compared with a file the executor wrote. The recording
/// step lives in the same code path as the comparison (see
/// `submission_golden_harness.dart`'s `goldenSuite`) so a recorder that
/// differed from the comparator by one field cannot produce a golden that
/// always matches.
///
/// **Re-running the record step after the migration must leave the file
/// byte-identical.** That is `B4-AC-26` stated as an operation rather than as a
/// claim, and `git diff` over this directory is how a reviewer checks it.
///
/// ## What is recorded — twelve entries
///
/// | # | | |
/// |---|---|---|
/// | 1 | `POST /applications` | create |
/// | 2 | `PATCH /applications/{id}` | update — every attempt (`F1-AC-57`) |
/// | 3-7 | `POST …/attachments` | five slots, **sequential**, in `attachmentsToSend()`'s order (`F1-AC-58`) |
/// | 8 | `POST …/submit` | body `"{}"` |
/// | 9 | `POST …/pay` | B6b's, `{"method_code":…}` |
/// | 10 | `PATCH /applications/{id}` | the retry's update — **no second create** (`F1-AC-56`) |
/// | 11 | `POST …/submit` | |
/// | 12 | `POST …/pay` | |
///
/// The **absence** of entries between 9 and 10 is as much of the assertion as
/// the entries: a retry that re-created the case, or re-sent a slot already
/// sent, appears here as extra entries and fails the comparison.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/application/domain/usecases/application_usecases.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/certificate_form.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_form_state.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_key.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_option.dart';
import 'package:lcc_mobile_app/features/reference/domain/repositories/reference_repository.dart';
import 'package:lcc_mobile_app/features/reference/domain/usecases/get_lookup_options.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/payment_method.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/payment_result.dart';
import 'package:lcc_mobile_app/features/wallet/domain/usecases/pay_application.dart';

import 'submission_golden_harness.dart';

PickedAttachment _file(String name) =>
    PickedAttachment(name: name, bytes: null);

/// A form filled enough to submit — `resident_form_cubit_test.dart:46-63`,
/// transcribed rather than imported because that file declares a `main()`.
ResidentFormData filledResidentForm() => ResidentFormData(
      frontId: _file('front.jpg'),
      backId: _file('back.jpg'),
      familyBookCover: _file('cover.jpg'),
      familyBookContents: _file('contents.pdf'),
      picture: _file('photo.jpg'),
      citizenName: 'Somchai',
      age: '34',
      nationality: 'lao',
      province: 'p-1',
      district: 'd-1',
      villageName: 'v-1',
      certifyingJurisdiction: 'Chanthabouly',
      currentVillage: 'Ban Dong',
      houseNo: '12',
      censusBookNo: 'CB-7',
      purpose: 'school',
    );

Future<List<WireEntry>> _driveResident() async {
  final SubmissionWireHarness harness =
      SubmissionWireHarness.build(responder: goldenResponder);

  final ResidentFormCubit cubit = ResidentFormCubit(
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
    // B6b's real use case over the same adapter, adapted exactly as
    // `certificates_bloc_injection.dart:124-141` adapts it — so the recorded
    // `/pay` entry is the one production sends.
    pay: (String id, {required String methodCode}) async {
      final Either<Failure, PaymentResult> r = await harness.payApplication(
        PayApplicationParams(applicationId: id, methodCode: methodCode),
      );
      return r.map<Object?>((PaymentResult p) => <String, Object?>{
            'receipt_no': p.receiptNo,
            'transaction': <String, Object?>{
              'receipt_no': p.transaction?.receiptNo,
            },
          });
    },
  );

  // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
  cubit.emit(cubit.state.copyWith(step: 6, form: filledResidentForm()));

  await cubit.next();
  expect(
    cubit.state.submitError,
    isNull,
    reason: 'the first attempt must succeed, or this is a failure log',
  );
  expect(cubit.state.submitted, isNotNull);

  // The retry. `state.draft` is held, so `if (!current)` is false and create is
  // skipped; `_uploaded` holds all five slots, so every attachment is skipped.
  await cubit.next();
  expect(cubit.state.submitError, isNull);

  await cubit.close();
  return harness.entries;
}

void main() {
  goldenSuite(
    form: CertificateForm.resident,
    drive: _driveResident,
    expectedSequence: <String>[
      'POST /applications',
      'PATCH /applications/case-1',
      'POST /applications/case-1/attachments',
      'POST /applications/case-1/attachments',
      'POST /applications/case-1/attachments',
      'POST /applications/case-1/attachments',
      'POST /applications/case-1/attachments',
      'POST /applications/case-1/submit',
      'POST /applications/case-1/pay',
      // The retry — no create, no attachment.
      'PATCH /applications/case-1',
      'POST /applications/case-1/submit',
      'POST /applications/case-1/pay',
    ],
  );
}

/// The submit path reads no lookup. Answering with rows would be a capability
/// the subject under test does not exercise.
class _InertReferenceRepo implements ReferenceRepository {
  @override
  Future<Either<Failure, List<LookupOption>>> options(
    LookupKey key, {
    String? parentId,
    PagingMode paging = PagingMode.all,
  }) async =>
      const Right<Failure, List<LookupOption>>(<LookupOption>[]);
}

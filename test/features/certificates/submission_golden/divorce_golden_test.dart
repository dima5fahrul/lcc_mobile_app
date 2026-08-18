/// Divorce's recorded request log — `B4-AC-25`…`B4-AC-28`, specs.md § 6.8.
///
/// See `resident_golden_test.dart`'s header for how the golden was produced and
/// why recording it **before** the migration is the whole instrument, and
/// `marriage_golden_test.dart`'s for what the nested family's log shows that
/// the flat family's does not.
///
/// Divorce is Marriage's shape — create → **attach → update** → submit → pay,
/// one `attachmentsSent` boolean for the whole loop
/// (`DivorceCertificatePage.tsx:868-873`), and a `label` on every upload.
library;

import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/certificate_form.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_form_state.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_key.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_option.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/payment_result.dart';
import 'package:lcc_mobile_app/features/wallet/domain/usecases/pay_application.dart';
import 'package:lcc_mobile_app/i18n/i18n.dart';

import '../presentation/divorce/divorce_tier0_subject.dart';
import 'submission_golden_harness.dart';

PickedAttachment _file(String name, int size) =>
    PickedAttachment(name: name, bytes: Uint8List(size));

/// `divorce_submit_path_test.dart:163-172`.
DivorceFormData filledDivorceForm() {
  final DivorceFormData f = divorceFormFromFixture(
    readDivorceJson('$kDivorceFixtureDir/contested.en.json'),
  );
  return f.copyWith(
    courtDecision: _file('decree.pdf', 10),
    householdBook: _file('book.pdf', 11),
    guaranteeCert: _file('guarantee.pdf', 12),
    photos: _file('photo.jpg', 13),
  );
}

Future<List<WireEntry>> _driveDivorce() async {
  final SubmissionWireHarness harness =
      SubmissionWireHarness.build(responder: goldenResponder);

  final DivorceFormCubit cubit = DivorceFormCubit(
    clock: SubmissionClock.fixed(kDivorceRegisterInstant),
    getLookupOptions: (
      LookupKey key, {
      String? parentId,
      PagingMode paging = PagingMode.all,
    }) async =>
        const Right<Failure, List<LookupOption>>(<LookupOption>[]),
    createApplication: (Map<String, Object?> body) =>
        harness.applications.createApplication(body),
    updateApplication: (String id, Map<String, Object?> body) =>
        harness.applications.updateApplication(id, body),
    addAttachment: (
      String id,
      PickedAttachment file, {
      required String slot,
      required String kind,
      required String label,
    }) =>
        harness.applications.addAttachment(
      id,
      file: file,
      slot: slot,
      kind: kind,
      label: label,
    ),
    submitApplication: (String id) =>
        harness.applications.submitApplication(id),
    pay: (String id, {required String methodCode}) async {
      final Either<Failure, PaymentResult> r = await harness.payApplication(
        PayApplicationParams(applicationId: id, methodCode: methodCode),
      );
      return r.map<Object?>((PaymentResult p) => <String, Object?>{
            'receipt_no': p.receiptNo,
          });
    },
    lang: Lang.en,
  );

  // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
  cubit.emit(cubit.state.copyWith(form: filledDivorceForm()));

  await cubit.submit();
  expect(
    cubit.state.submitError,
    isNull,
    reason: 'the first attempt must succeed, or this is a failure log',
  );
  expect(cubit.state.submitted, isNotNull);

  await cubit.submit();
  expect(cubit.state.submitError, isNull);

  await cubit.close();
  return harness.entries;
}

void main() {
  goldenSuite(
    form: CertificateForm.divorce,
    drive: _driveDivorce,
    expectedSequence: <String>[
      'POST /applications',
      // ATTACH BEFORE UPDATE — the nested family's order.
      'POST /applications/case-1/attachments',
      'POST /applications/case-1/attachments',
      'POST /applications/case-1/attachments',
      'POST /applications/case-1/attachments',
      'PATCH /applications/case-1',
      'POST /applications/case-1/submit',
      'POST /applications/case-1/pay',
      // The retry — no create, and the whole attach block skipped.
      'PATCH /applications/case-1',
      'POST /applications/case-1/submit',
      'POST /applications/case-1/pay',
    ],
  );
}

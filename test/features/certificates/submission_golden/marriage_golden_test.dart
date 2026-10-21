/// Marriage's recorded request log — `B4-AC-25`…`B4-AC-28`, specs.md § 6.8.
///
/// See `resident_golden_test.dart`'s header for how the golden was produced and
/// why recording it **before** the migration is the whole instrument.
///
/// ## Marriage is the nested family, and its log says so in two places
///
/// 1. **The order is create → attach → update → submit → pay.** The flat family
///    updates before it attaches (`submission_plan.dart:250-256`). A migration
///    that normalised the five forms onto one order would show up here as a
///    transposition on exactly two of the five logs, which is the failure
///    `B4-AC-28`'s mutant proves this comparison can see.
/// 2. **The attachment guard is one boolean for the whole loop**, not a
///    per-slot set: `MarriageCertificatePage.tsx:972-977` wraps the loop in
///    `if (!attachmentsSent)` and sets the flag **after** it. On the retry
///    recorded here, the whole attach block is skipped — four entries absent,
///    not four entries deduplicated.
///
/// Marriage's uploads also carry a fourth multipart part, `label`, which
/// Resident's do not (`endpoints.ts:349-350`). The recorded `parts` lists carry
/// it, so a migration that dropped the optional part fails the byte comparison
/// rather than passing a part-count assertion nobody wrote for this form.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/certificate_form.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_form_state.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_key.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_option.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/payment_result.dart';
import 'package:lcc_mobile_app/features/wallet/domain/usecases/pay_application.dart';
import 'package:lcc_mobile_app/i18n/i18n.dart';

import '../presentation/marriage/marriage_tier0_subject.dart';
import 'submission_golden_harness.dart';

/// A file whose **identity** is its name plus its byte length — the two things
/// `marriageAttachmentIdentity` keys on, per
/// `marriage_submit_path_test.dart:37-40`.
PickedAttachment _file(String name, int size) =>
    PickedAttachment(name: name, bytes: Uint8List(size));

/// `marriage_submit_path_test.dart:142-152`.
MarriageFormData filledMarriageForm() {
  final MarriageFormData f = marriageFormFromFixture(
    readMarriageJson('$kMarriageFixtureDir/asymmetric.en.json'),
  );
  return f.copyWith(
    spouseA: f.spouseA.copyWith(
      singleStatusCert: _file('a-single.pdf', 10),
      // Forms v2 — the per-spouse 3×4 photos ("Photos (3×4)"): recorded so the
      // golden proves they reach the wire through the real cubit path, into
      // `spouses.spouse_a.photo` / `spouses.spouse_b.photo` with kind=photo.
      photo: _file('a-3x4.jpg', 14),
    ),
    spouseB: f.spouseB.copyWith(
      singleStatusCert: _file('b-single.pdf', 11),
      photo: _file('b-3x4.jpg', 15),
    ),
    householdBook: _file('book.pdf', 12),
    photos: _file('photo.jpg', 13),
  );
}

Future<List<WireEntry>> _driveMarriage() async {
  final SubmissionWireHarness harness =
      SubmissionWireHarness.build(responder: goldenResponder);

  final MarriageFormCubit cubit = MarriageFormCubit(
    clock: SubmissionClock.fixed(kMarriageRegisterInstant),
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
  cubit.emit(cubit.state.copyWith(form: filledMarriageForm()));

  await cubit.submit();
  expect(
    cubit.state.submitError,
    isNull,
    reason: 'the first attempt must succeed, or this is a failure log',
  );
  final MarriageSubmitted? first = cubit.state.submitted;
  expect(first, isNotNull);

  // The retry. `state.draftId` is held so create is skipped, and
  // `attachmentsSent` is true over an unchanged identity set so the whole
  // attach block is skipped — not four deduplicated uploads, four absent ones.
  await cubit.submit();
  expect(cubit.state.submitError, isNull);

  await cubit.close();
  return harness.entries;
}

void main() {
  goldenSuite(
    form: CertificateForm.marriage,
    drive: _driveMarriage,
    expectedSequence: <String>[
      'POST /applications',
      // ATTACH BEFORE UPDATE — the nested family's order. SIX uploads since
      // forms v2's task 9: the four fixture files plus the two per-spouse
      // 3×4 photos.
      'POST /applications/case-1/attachments',
      'POST /applications/case-1/attachments',
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

  test('the recorded uploads carry the fourth `label` part Resident omits', () {
    // Read off the recorded file rather than off the live run, so this is an
    // assertion about the pinned golden and survives a harness change.
    final GoldenLog log = GoldenLog.decode(
      _readGolden('${CertificateForm.marriage.serviceCode}.golden.json'),
    );
    final List<WireEntry> uploads = log.entries
        .where((WireEntry e) => e.parts != null)
        .toList(growable: false);
    expect(uploads, hasLength(6),
        reason: 'the four source files plus the two forms-v2 spouse photos');
    for (final WireEntry e in uploads) {
      expect(
        e.parts!.where((String p) => p.startsWith('field:label=')),
        hasLength(1),
        reason: '`endpoints.ts:349-350` sends label for this form: ${e.parts}',
      );
    }
  });
}

String _readGolden(String name) => File('$kGoldenDir/$name').readAsStringSync();

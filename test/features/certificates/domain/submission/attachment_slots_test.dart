/// Forms v2, task 9 — the per-spouse 3×4 photo slots and the `office_use`
/// guard (`MOBILE-API-E-CERTIFICATES.md` § "Application forms v2" —
/// "Photos (3×4)" and "Officer-only fields").
///
/// ## The three claims
///
/// 1. **Marriage and Divorce grow two photo uploads each** —
///    `spouses.spouse_a.photo` / `spouses.spouse_b.photo` and
///    `spouses.husband.photo` / `spouses.wife.photo` — sent through the
///    existing `POST /applications/{id}/attachments` with `kind=photo`, one
///    per spouse, OPTIONAL like every v2 field: a form without the photo
///    sends nothing for that slot, never an empty part.
/// 2. **Residence's `applicant.photo` is untouched** — the guide lists it as
///    already existing.
/// 3. **No `office_use` key reaches the wire.** The section is officer-only;
///    the server drops anything a citizen sends, so the executor strips any
///    `office_use` key — flat dotted (`office_use.family_book`, Birth's
///    shape) or nested section (`office_use: {…}`, Marriage/Divorce's
///    shape) — from `form_data` before create/update are called, without
///    mutating the page's own payload map.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_detail.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/attachment_guard.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/case_reference_binding.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/certificate_form.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/envelope_shape.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/method_code_source.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_executor.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_plan.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_step.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_payload.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_payload.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_payload.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_location_fields.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_location_value.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_ref_list.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_fields.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_form_cubit.dart';

import '../../../application/application_write_fakes.dart';
import '../../../../helpers/app_test_harness.dart';

PickedAttachment _file(String name) => PickedAttachment(
      name: name,
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
    );

/// Records the envelopes create/update were actually handed.
class _Spy {
  final List<Map<String, Object?>> createEnvelopes = <Map<String, Object?>>[];
  final List<Map<String, Object?>> updateEnvelopes = <Map<String, Object?>>[];

  Future<Either<Failure, ApplicationDetail>> create(
    Map<String, Object?> envelope,
  ) async {
    createEnvelopes.add(envelope);
    return Right<Failure, ApplicationDetail>(applicationDetailFixture());
  }

  Future<Either<Failure, ApplicationDetail>> update(
    String id,
    Map<String, Object?> envelope,
  ) async {
    updateEnvelopes.add(envelope);
    return Right<Failure, ApplicationDetail>(applicationDetailFixture(id: id));
  }

  Future<Either<Failure, ApplicationDetail>> submit(String id) async =>
      Right<Failure, ApplicationDetail>(applicationDetailFixture(id: id));

  Future<Either<Failure, Object?>> attach(String id, Object attachment) async =>
      const Right<Failure, Object?>(null);
}

/// A flat-family plan with no attachments — the smallest walk that puts
/// `form_data` on the wire twice (create AND update).
SubmissionPlan _plan(CertificateForm form) => SubmissionPlan(
      form: form,
      steps: const <SubmissionStep>[
        SubmissionStep.create,
        SubmissionStep.update,
        SubmissionStep.submit,
      ],
      reference: const CaseReferenceBinding.flatAppended('header.ref_no'),
      attachmentGuard: AttachmentGuard.none,
      createEnvelope: const EnvelopeShape(<EnvelopeKey>[
        EnvelopeKey('service_code'),
        EnvelopeKey('form_data'),
      ]),
      updateEnvelope: const EnvelopeShape(<EnvelopeKey>[
        EnvelopeKey('form_data'),
      ]),
      methodCode: methodCodeSourceFor(form),
      stepsSrc: 'built by attachment_slots_test.dart',
    );

void main() {
  group('marriage — the two spouse photo slots', () {
    MarriageFormData formWithPhotos() {
      const MarriageFormData base = MarriageFormData(
        spouseA: MarriageSpouseInfo(fullName: 'ຍິງ ກຽວວິໄລ'),
        spouseB: MarriageSpouseInfo(fullName: 'ຊາຍ ວົງສະຫວັນ'),
      );
      return base.copyWith(
        photos: _file('photo.jpg'),
        birthRecord: _file('birth.pdf'),
        spouseA: base.spouseA.copyWith(photo: _file('a-3x4.jpg')),
        spouseB: base.spouseB.copyWith(photo: _file('b-3x4.jpg')),
      );
    }

    test('populated → one upload per spouse, kind photo, in POST order',
        () {
      final List<MarriageAttachment> uploads = marriageUploads(formWithPhotos());
      expect(
        uploads
            .where((MarriageAttachment a) => a.kind == 'photo')
            .map((MarriageAttachment a) => a.slot)
            .toList(),
        <String>[
          'supporting.photos_3x4',
          'spouses.spouse_a.photo',
          'spouses.spouse_b.photo',
        ],
        reason: 'the guide: upload into spouses.spouse_a.photo and '
            'spouses.spouse_b.photo with kind=photo, via the existing '
            'attachments endpoint',
      );
      final MarriageAttachment a = uploads
          .firstWhere((MarriageAttachment u) => u.slot == 'spouses.spouse_a.photo');
      final MarriageAttachment b = uploads
          .firstWhere((MarriageAttachment u) => u.slot == 'spouses.spouse_b.photo');
      expect(a.label, 'Spouse A', reason: 'the fourth multipart part');
      expect(b.label, 'Spouse B');
      expect(a.file.name, 'a-3x4.jpg');
      expect(b.file.name, 'b-3x4.jpg');
    });

    test('unset → the slots are ABSENT, never an empty part', () {
      const MarriageFormData base = MarriageFormData(
        spouseA: MarriageSpouseInfo(fullName: 'ຍິງ ກຽວວິໄລ'),
        spouseB: MarriageSpouseInfo(fullName: 'ຊາຍ ວົງສະຫວັນ'),
      );
      final List<MarriageAttachment> uploads = marriageUploads(base.copyWith(
        photos: _file('photo.jpg'),
      ));
      expect(
        uploads.any((MarriageAttachment a) =>
            a.slot == 'spouses.spouse_a.photo' ||
            a.slot == 'spouses.spouse_b.photo'),
        isFalse,
        reason: 'optional v2 field — absent key when empty; the attachments '
            'list is the same shape as before task 9',
      );
    });

    test('the new entries are APPENDED — the existing POST order is a prefix',
        () {
      final List<String> slots = marriageUploads(formWithPhotos())
          .map((MarriageAttachment a) => a.slot)
          .toList();
      expect(
        slots.sublist(0, slots.length - 2),
        <String>[
          'supporting.photos_3x4',
          'supporting.birth_record',
        ],
        reason: 'the pre-task-9 tail is untouched; the photo slots ride after '
            'it so no recorded order moves',
      );
      expect(slots.last, 'spouses.spouse_b.photo');
    });
  });

  group('divorce — the two spouse photo slots', () {
    DivorceFormData formWithPhotos() {
      const DivorceFormData base = DivorceFormData(
        husband: DivorceSpouseInfo(fullName: 'ຊາຍ'),
        wife: DivorceSpouseInfo(fullName: 'ຍິງ'),
      );
      return base.copyWith(
        courtDecision: _file('decree.pdf'),
        photos: _file('photo.jpg'),
        husband: base.husband.copyWith(photo: _file('h-3x4.jpg')),
        wife: base.wife.copyWith(photo: _file('w-3x4.jpg')),
      );
    }

    test('populated → one upload per spouse, kind photo, in POST order',
        () {
      final List<DivorceAttachment> uploads = divorceUploads(formWithPhotos());
      expect(
        uploads
            .where((DivorceAttachment a) => a.kind == 'photo')
            .map((DivorceAttachment a) => a.slot)
            .toList(),
        <String>[
          'supporting.photos_3x4',
          'spouses.husband.photo',
          'spouses.wife.photo',
        ],
        reason: 'the guide: spouses.husband.photo and spouses.wife.photo',
      );
      expect(
        uploads
            .firstWhere((DivorceAttachment u) =>
                u.slot == 'spouses.husband.photo')
            .label,
        'Husband',
      );
      expect(
        uploads
            .firstWhere(
                (DivorceAttachment u) => u.slot == 'spouses.wife.photo')
            .label,
        'Wife',
      );
    });

    test('unset → the slots are ABSENT, never an empty part', () {
      final List<DivorceAttachment> uploads =
          divorceUploads(formWithPhotos().copyWith(
        husband: const DivorceSpouseInfo(fullName: 'ຊາຍ'),
        wife: const DivorceSpouseInfo(fullName: 'ຍິງ'),
      ));
      expect(
        uploads.any((DivorceAttachment a) =>
            a.slot == 'spouses.husband.photo' ||
            a.slot == 'spouses.wife.photo'),
        isFalse,
      );
    });
  });

  group('residence — applicant.photo is untouched', () {
    test('the picture still uploads into applicant.photo with kind photo',
        () {
      final List<CertificateAttachment> uploads = residentAttachmentsToSend(
        ResidentFormData(picture: _file('me.jpg')),
      );
      expect(
        uploads.map((CertificateAttachment a) => a.slot).toList(),
        <String>['applicant.photo'],
      );
      expect(uploads.single.kind, 'photo');
    });
  });

  group('office_use — never sent', () {
    test('flat dotted key AND nested section are stripped from both envelopes, '
        'everything else survives in order', () async {
      // One payload carrying BOTH shapes: `office_use.family_book` is the
      // flat dotted spelling Birth would produce; the nested `office_use`
      // object is the section spelling Marriage/Divorce would produce.
      final Map<String, Object?> payload = <String, Object?>{
        'child.child_name': 'ນ້ອງສົມສະໜັກ',
        'office_use.family_book': 'FAM-1',
        'office_use': <String, Object?>{
          'icd10': 'J45',
          'manner_of_death': 'natural',
        },
        'applicant.age': '34',
      };

      final _Spy spy = _Spy();
      await SubmissionExecutor(
        createCase: spy.create,
        updateCase: spy.update,
        attachToCase: spy.attach,
        submitCase: spy.submit,
      ).run(
        plan: _plan(CertificateForm.birth),
        buildFormData: (String reference) => payload,
        createEnvelope: (Map<String, Object?> p) => <String, Object?>{
          'service_code': 'birth',
          'form_data': p,
        },
        updateEnvelope: (Map<String, Object?> p) => <String, Object?>{
          'form_data': p,
        },
        attachments: const <SubmissionAttachment>[],
        ledger: AttachmentLedger(),
      );

      for (final Map<String, Object?> envelope in <Map<String, Object?>>[
        ...spy.createEnvelopes,
        ...spy.updateEnvelopes,
      ]) {
        final Map<String, Object?> fd =
            envelope['form_data']! as Map<String, Object?>;
        expect(
          fd.keys.where((String k) =>
              k == 'office_use' || k.startsWith('office_use.')),
          isEmpty,
          reason: 'the officer-only section never reaches the wire — '
              'jsonEncode: ${jsonEncode(envelope)}',
        );
        expect(jsonEncode(envelope).contains('office_use'), isFalse);
        // Everything else, in the original order (the flat update appends
        // `header.ref_no` LAST — the binding's own contract).
        expect(
          fd.keys.where((String k) => k != 'header.ref_no').toList(),
          <String>['child.child_name', 'applicant.age'],
        );
      }
    });

    test('the page\'s own payload map is NOT mutated by the strip', () async {
      final Map<String, Object?> payload = <String, Object?>{
        'applicant.age': '34',
        'office_use.icd10': 'J45',
      };
      final _Spy spy = _Spy();
      await SubmissionExecutor(
        createCase: spy.create,
        updateCase: spy.update,
        attachToCase: spy.attach,
        submitCase: spy.submit,
      ).run(
        plan: _plan(CertificateForm.birth),
        buildFormData: (String reference) => payload,
        createEnvelope: (Map<String, Object?> p) => <String, Object?>{
          'service_code': 'birth',
          'form_data': p,
        },
        updateEnvelope: (Map<String, Object?> p) => <String, Object?>{
          'form_data': p,
        },
        attachments: const <SubmissionAttachment>[],
        ledger: AttachmentLedger(),
      );

      expect(payload.containsKey('office_use.icd10'), isTrue,
          reason: 'the flat family re-spreads its create payload into the '
              'update — a mutating strip would eat the key out from under '
              'the page');
    });

    test('a clean form_data passes through byte-identical', () async {
      final Map<String, Object?> payload = <String, Object?>{
        'applicant.age': '34',
        'applicant.citizen_name': 'ສົມສະໜັກ',
      };
      final _Spy spy = _Spy();
      await SubmissionExecutor(
        createCase: spy.create,
        updateCase: spy.update,
        attachToCase: spy.attach,
        submitCase: spy.submit,
      ).run(
        plan: _plan(CertificateForm.birth),
        buildFormData: (String reference) => payload,
        createEnvelope: (Map<String, Object?> p) => <String, Object?>{
          'service_code': 'birth',
          'form_data': p,
        },
        updateEnvelope: (Map<String, Object?> p) => <String, Object?>{
          'form_data': p,
        },
        attachments: const <SubmissionAttachment>[],
        ledger: AttachmentLedger(),
      );

      expect(jsonEncode(spy.createEnvelopes.single['form_data']),
          jsonEncode(payload),
          reason: 'no office_use on the form means no bytes move — the guard '
              'is invisible on every fixture captured before it existed');
    });
  });

  group('labels — the spouse photo renders real text, not a raw key', () {
    // easy_localization echoes the KEY on a miss, so a label wired to the
    // wrong namespace renders as literal `forms.spousePhotoLabel`. Pumped
    // with the real bundle (the `forms_v2_keys_test.dart` pattern). The
    // divorce spouse section is the lighter of the two constructors; the
    // marriage section shares the same `forms.*` key.
    Future<void> pumpSection(WidgetTester tester, Widget section) async {
      await tester.pumpWidget(
        wrapWithLocalization(
          Builder(
            builder: (BuildContext context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Scaffold(body: SingleChildScrollView(child: section)),
            ),
          ),
        ),
      );
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('divorce spouse section renders the 3×4 label and never a '
        'raw key', (WidgetTester tester) async {
      await pumpSection(
        tester,
        DivorceSpouseSection(
          value: DivorceSpouseInfo.blank,
          onChanged: (DivorceSpouseInfo _) {},
          nationalities: const CertificateRefList(),
          serverErrors: const <String, String>{},
          provinces: CertificateLocationLevel.empty,
          cascade: const DivorceCascadeState(),
          onAddressChanged: (CertificateLocationValue _) {},
          pickFile: () async => null,
        ),
      );

      expect(find.text('PHOTO (3×4)'), findsOneWidget,
          reason: 'the v2 label must come from the `forms` namespace — a raw '
              '`forms.spousePhotoLabel` here means the field hit a missing '
              'key');
      expect(
        find.textContaining(RegExp(r'\b(divorce|forms)\.[a-zA-Z]')),
        findsNothing,
        reason: 'a rendered raw i18n key means a label missed its namespace',
      );
    });
  });
}

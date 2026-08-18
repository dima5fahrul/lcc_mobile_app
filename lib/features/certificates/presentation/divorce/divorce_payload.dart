/// `DivorceCertificatePage.tsx:781-886` — everything Divorce puts on the wire,
/// transcribed as literal Dart maps.
///
/// ## This file is the Tier 0 gate, and it is judged on EIGHT documents
///
/// `divorce.{create,update}.{en,lo}` (voluntary + new mediation record) **and**
/// `divorce.contested.{create,update}.{en,lo}`. The two arms **split the
/// payload** — `mediation.*` is non-empty only under the first, `basis.court_*`
/// only under the second — so a one-arm matrix leaves a whole key group
/// permanently `""` and a port that hardcoded `""` there would pass. `F3-AC-47`
/// requires both arms in the run; four documents is a FAIL, not a partial.
///
/// **Measured leaf count: 46 per document**, eight documents. `specs.md`
/// § 6.11 states 92 per document; that is exactly 2× the measured value. See
/// `marriage_payload.dart`'s library comment for the same discrepancy on
/// Marriage and what is asserted instead.
library;

import '../../../../presentation/payment/payment_draft.dart';
import '../../../application/domain/entities/picked_attachment.dart';
import '../../domain/submission/case_reference_binding.dart';
import '../../domain/submission/certificate_form.dart';
import '../../domain/submission/submission_clock.dart';
import '../../domain/submission/submission_plan.dart';
import '../certificate_forms/certificate_payload_helpers.dart';
import 'divorce_form_state.dart';

/// `:781-792` — `spousePayload(s)`. **EIGHT keys, in this order.**
///
/// Marriage's has thirteen. The five it does not have are `gender`,
/// `ethnicity`, `ethnic_group`, `religion` and `occupation`; the one it renames
/// is `residence_certificate_ref` → **`marriage_certificate_ref`**.
///
/// **A shared helper is FORBIDDEN** (§ 6.5). It would be correct for six keys,
/// wrong for the rename, and would make `F0-AC-82`'s guard
/// (`tier0_payload_equality_test.dart:538-569`) vacuous — the guard asserts the
/// two mirrors differ by exactly `{marriage_certificate_ref}`, and F3 must not
/// let that pass by construction (`F3-AC-23`, `F3-AC-46`).
///
/// Same trim asymmetry as Marriage: `name`, `id_number` and
/// `marriage_certificate_ref` are trimmed; `dob`, `nationality`, `house_no`
/// and `current_address` are not.
Map<String, Object?> divorceSpousePayload(DivorceSpouseInfo s) {
  return <String, Object?>{
    'name': s.fullName.trim(),
    'dob': s.dob,
    'nationality': s.nationality,
    'id_number': s.idOrPassport.trim(),
    'house_no': s.addrHouseNo,
    'current_address': s.address.villageId,
    'address_text': <String>[
      s.addrHouseNo,
      s.address.villageName,
      s.address.districtName,
      s.address.provinceName,
    ].where((String v) => v.isNotEmpty).join(', '),
    'marriage_certificate_ref': s.marriageCertRef.trim(),
  };
}

/// `:794-837` — `buildFormData(documentNo)`. **46 leaves, four sections.**
///
/// ## Both key groups are written UNCONDITIONALLY
///
/// `mediation.*` (eleven keys, `:802-814`) and `basis.court_name` /
/// `basis.court_decision_date` (`:831-832`) are emitted whichever arm is
/// active. Under `contested` all eleven mediation keys are `""`; under
/// `voluntary` both court keys are `""`. **Neither group is ever absent**
/// (`F3-AC-48`).
///
/// `specs.md` § 6.7 and `F3-AC-48` say "`mediation.*`'s **nine** keys";
/// counted at `:802-814` it is **eleven** — `mediation_record_no`,
/// `property_division`, `custody_arrangement`, `debt_division`,
/// `date_marriage_began`, `reasons_husband`, `reasons_wife`, `outcome`,
/// `additional_assets`, `children`, `witnesses`. The executed oracle
/// `divorce.contested.create.en` carries all eleven as `""`. Recorded rather
/// than reconciled silently.
///
/// ## Three keys are gated on `hasChildren`, and two of them are the same value
///
/// `mediation.custody_arrangement` (`:805`), `mediation.children` (`:812`) and
/// `basis.custody_reference` (`:830`). The first and third are both
/// `hasChildren ? children.custody : ""` — the **same string written to two
/// different sections**, which is not a mistake to normalise: the server reads
/// them separately.
///
/// ## The clock, and the two invocations
///
/// `:800` `today()` — one textual site, two register rows, because `:860`
/// `buildFormData("")` and `:877` `buildFormData(reference)` each re-evaluate
/// it. Pointer `/header/dated`, nested (`F3-AC-32`…`F3-AC-34`, `F3-AC-39`).
Map<String, Object?> buildDivorceFormData(
  DivorceFormData form,
  SubmissionClock clock,
  String documentNo,
) {
  final String custody = form.hasChildren ? form.children.custody : '';

  return <String, Object?>{
    // `:795-801`
    'header': <String, Object?>{
      'province_id': form.header.provinceId,
      'district_id': form.header.districtId,
      'village_id': form.header.villageId,
      'document_no': documentNo,
      'dated': clock.todayLocal(),
    },
    // `:802-814` — eleven keys, unconditional.
    'mediation': <String, Object?>{
      'mediation_record_no': form.linkedRecord?.recordNo ?? '',
      'property_division': form.mediation.propertyDivision,
      'custody_arrangement': custody,
      'debt_division': form.mediation.debts,
      'date_marriage_began': form.mediation.dateMarriageBegan,
      'reasons_husband': form.mediation.reasonsHusband,
      'reasons_wife': form.mediation.reasonsWife,
      'outcome': form.mediation.outcome,
      'additional_assets': form.mediation.additionalAssets,
      'children': form.hasChildren ? form.children.list : '',
      'witnesses': <String>[form.mediation.w1Name, form.mediation.w2Name]
          .where((String v) => v.isNotEmpty)
          .join(', '),
    },
    // `:815-825` — SIX mirrored keys, no `gender`.
    'spouses': <String, Object?>{
      'name': both(form.husband.fullName, form.wife.fullName),
      'dob': both(form.husband.dob, form.wife.dob),
      'nationality': both(form.husband.nationality, form.wife.nationality),
      'id_number': both(form.husband.idOrPassport, form.wife.idOrPassport),
      'current_address':
          both(form.husband.address.villageId, form.wife.address.villageId),
      'marriage_certificate_ref':
          both(form.husband.marriageCertRef, form.wife.marriageCertRef),
      'husband': divorceSpousePayload(form.husband),
      'wife': divorceSpousePayload(form.wife),
    },
    // `:826-836`
    'basis': <String, Object?>{
      'divorce_type': form.basis.divorceType,
      'divorce_date': form.basis.dateOfDivorce,
      'registration_place': form.basis.placeOfRegistration.trim(),
      'custody_reference': custody,
      'court_name': form.court.name,
      'court_decision_date': form.court.decisionDate,
      // Signed in front of the registrar (PRD §9.5) — not captured in the app.
      'registrar_signature': kDivorceOfficeDeferred,
      'certificate_each_spouse': kDivorceOfficeDeferred,
    },
  };
}

/// The two bodies, through the kernel binding — two invocations, two clock
/// reads. See `marriage_payload.dart`'s counterpart.
SubmissionBodies divorceSubmissionBodies(
  DivorceFormData form,
  SubmissionClock clock,
  String referenceNo,
) {
  final SubmissionPlan plan = SubmissionPlan.forForm(CertificateForm.divorce);
  return plan.reference.bodies(
    (String documentNo) => buildDivorceFormData(form, clock, documentNo),
    referenceNo,
  );
}

/// One row of `uploads()` — `:839-845`.
class DivorceAttachment {
  const DivorceAttachment({
    required this.file,
    required this.slot,
    required this.kind,
    required this.label,
  });

  final PickedAttachment file;
  final String slot;
  final String kind;
  final String label;
}

/// `:839-845` — `uploads()`. **Four entries, four distinct slots**, in
/// **POST order**.
///
/// ## The POST order is NOT the DOM order, and both are asserted
///
/// Step 4 renders household book (`:1442`), guarantee certificate (`:1448`),
/// photos (`:1455`). This list is court decision, household book, guarantee
/// certificate, photos. Tier 1 reads render order; Tier 0 and the attachment
/// sequence read this order. They are **different lists and the port needs
/// both** — a single list is a FAIL (`F3-AC-58`). `divorceStep4DomOrder` below
/// is the other one.
///
/// `basis.court_decision` is listed **first and unconditionally**, even though
/// it is captured on step 1's contested arm; when the arm was never visited the
/// file is null and `.filter` drops the entry (`F3-AC-59`). This unconditional
/// inclusion is one half of D-N — see `divorceResetMediation`.
///
/// Unlike Marriage, no slot repeats here, so `F3-AC-56`'s no-dedupe property is
/// vacuous on this page and is asserted on Marriage.
List<DivorceAttachment> divorceUploads(DivorceFormData form) {
  final List<DivorceAttachment> out = <DivorceAttachment>[];

  void add(PickedAttachment? file, String slot, String kind, String label) {
    if (file == null) return; // `:845`
    out.add(DivorceAttachment(file: file, slot: slot, kind: kind, label: label));
  }

  add(form.courtDecision, 'basis.court_decision', 'document', 'Court decision');
  add(form.householdBook, 'supporting.household_book', 'document',
      'Household book');
  add(form.guaranteeCert, 'supporting.guarantee_certificate', 'document',
      'Guarantee certificate');
  add(form.photos, 'supporting.photos_3x4', 'photo', '3x4 photographs');

  return out;
}

/// The **render** order of step 4's three upload controls — `:1442`, `:1448`,
/// `:1455`.
///
/// Declared as data so `F3-AC-58` can assert it **separately** from
/// [divorceUploads]'s order rather than inferring one from the other. The
/// court-decision upload is absent because it renders on step 1, not step 4.
const List<String> divorceStep4DomOrder = <String>[
  'supporting.household_book',
  'supporting.guarantee_certificate',
  'supporting.photos_3x4',
];

/// `:853-861` — the `POST /applications` envelope. Same shape as Marriage's:
/// raw location trio, elided `event_date`, elided `linked_reference_no`
/// between it and `form_data`, `form_data` last.
Map<String, Object?> divorceCreateEnvelope({
  required DivorceFormData form,
  required Map<String, Object?> payload,
}) {
  return <String, Object?>{
    'service_code': kDivorceServiceCode,
    'province_id': form.header.provinceId,
    'district_id': form.header.districtId,
    'village_id': form.header.villageId,
    if (form.basis.dateOfDivorce.isNotEmpty)
      'event_date': form.basis.dateOfDivorce,
    if ((form.linkedRecord?.recordNo ?? '').isNotEmpty)
      'linked_reference_no': form.linkedRecord!.recordNo,
    'form_data': payload,
  };
}

/// `:876-879` — the `PATCH /applications/{id}` envelope. `form_data` **first**.
Map<String, Object?> divorceUpdateEnvelope({
  required DivorceFormData form,
  required Map<String, Object?> updatePayload,
}) {
  return <String, Object?>{
    'form_data': updatePayload,
    if (form.basis.dateOfDivorce.isNotEmpty)
      'event_date': form.basis.dateOfDivorce,
  };
}

/// `:884` — `METHOD_CODE[payment.method]`. Static map, no `/payment-methods`
/// request (`F3-AC-65`, `F3-AC-66`).
String divorceMethodCodeFor(DraftPaymentMethod method) =>
    kDivorceMethodCode[method]!;

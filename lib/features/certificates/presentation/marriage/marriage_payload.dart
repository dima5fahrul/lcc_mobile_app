/// `MarriageCertificatePage.tsx:876-990` — everything Marriage puts on the
/// wire, transcribed as literal Dart maps.
///
/// ## This file is the Tier 0 gate
///
/// `ssd.md` § 14 F-6: Tier 0 payload equality is blocking and takes precedence
/// over Tier 3 disagreement. Four executed documents
/// (`marriage.{create,update}.{en,lo}.json`) were captured off the running
/// pinned app; `tier0_payload_equality_test.dart` compares `jsonEncode` of what
/// this file returns against them **byte for byte**.
///
/// **Measured leaf count: 54 per document.** `specs.md` § 6.11 states 108 per
/// document and 1,168 in total; both are exactly 2× the measured values
/// (`len(paths)` is 54 for each of the four marriage documents and 46 for each
/// of the eight divorce ones — 584, not 1,168). The spec appears to have
/// counted a create/update *pair* as one document while also counting 4 and 8
/// documents. Recorded here and in `qa-report.md` rather than reconciled
/// silently; the numbers this port asserts are the measured ones.
///
/// ## Why literal maps and not a builder
///
/// `submission_plan.dart:17-19` — a literal Dart map transcribed from a literal
/// TS object is diffable against the source by eye and against the oracle by
/// test; a strategy that computes the same map is diffable against neither.
/// [buildMarriageFormData]'s body sits in the same order as `:894-936`.
///
/// ## Key order is wire order
///
/// `client.ts:242` is a bare `JSON.stringify(options.body)`. Dart map literals
/// are insertion-ordered `LinkedHashMap`s and `jsonEncode` walks insertion
/// order, so a faithful transcription serialises identically — a property
/// nobody maintains, which is why the test asserts the serialised string.
library;

import '../../../../presentation/payment/payment_draft.dart';
import '../../../application/domain/entities/picked_attachment.dart';
import '../../domain/submission/case_reference_binding.dart';
import '../../domain/submission/certificate_form.dart';
import '../../domain/submission/submission_clock.dart';
import '../../domain/submission/submission_plan.dart';
import '../certificate_forms/certificate_payload_helpers.dart';
import 'marriage_form_state.dart';

/// `:876-892` — `spousePayload(s)`. **THIRTEEN keys, in this order.**
///
/// ## This helper is FORBIDDEN from being shared with Divorce
///
/// § 6.5, and it is the Birth/Death `parentData` prohibition one family over.
/// Divorce's has **eight** keys, drops `gender`, `ethnicity`, `ethnic_group`,
/// `religion` and `occupation`, and **renames** `residence_certificate_ref` to
/// `marriage_certificate_ref`. `tier0_payload_equality_test.dart:538-569`
/// (`F0-AC-82`) already asserts the two differ by exactly that rename; a shared
/// helper would be correct for most keys and silently wrong for the rest, and
/// would make F0a's guard vacuous (`F3-AC-23`, `F3-AC-46`).
///
/// ## Three trims and ten non-trims, and the asymmetry is observable
///
/// `name`, `id_number` and `residence_certificate_ref` are `.trim()`ed
/// (`:877`, `:885`, `:891`). **`dob`, `gender`, `nationality`, `house_no` and
/// `current_address` are not** — so on the `whitespace` fixture the sub-object
/// emits `"  1990-01-01  "` where the section-level mirror above it emits the
/// trimmed value. That is `F0-AC-83`, and a port that trimmed uniformly — the
/// natural Dart instinct — fails there and nowhere else.
///
/// ## `address_text` is resolved at PICK time
///
/// `[house_no, villageName, districtName, provinceName].filter(Boolean).join(", ")`
/// (`:888-890`). The three names were resolved by `nameOf` = `text(row.name,
/// lang)` inside the select's `onChange`, so a citizen who picks under `en` and
/// switches to `lo` still sends English. That is Guard B
/// (`tier0_payload_equality_test.dart:1116-1141`) and it is deliberately an
/// assertion about the *resolution path*, not an inequality — an inequality
/// would fail a faithful port and pass one that re-resolved at submit.
///
/// `filter(Boolean)` drops empties **before** joining, so a blank house number
/// yields `"Village, District, Province"` and not `", Village, …"`.
Map<String, Object?> marriageSpousePayload(MarriageSpouseInfo s) {
  return <String, Object?>{
    'name': s.fullName.trim(),

    // Forms v2 — the optional Latin split names and the optional place of
    // birth. **Absent key when empty, never `""`**: the Tier 0 oracles, the
    // F0-AC-82 spouse-shape guard and the golden logs predate these keys and
    // populate none of them, so emitting them unconditionally would move
    // bytes on all four documents for no input.
    if (s.surname.isNotEmpty) 'surname': s.surname,
    if (s.givenName.isNotEmpty) 'given_name': s.givenName,
    if (s.placeOfBirth.isNotEmpty) 'place_of_birth': s.placeOfBirth,

    'dob': s.dob,
    'gender': s.gender,
    'nationality': s.nationality,
    'ethnicity': s.ethnicity,
    'ethnic_group': s.ethnicGroup,
    'religion': s.religion,
    'occupation': s.occupation,
    'id_number': s.idOrPassport.trim(),
    'house_no': s.addrHouseNo,
    'current_address': s.address.villageId,
    'address_text': <String>[
      s.addrHouseNo,
      s.address.villageName,
      s.address.districtName,
      s.address.provinceName,
    ].where((String v) => v.isNotEmpty).join(', '),
    'residence_certificate_ref': s.residenceCertRef.trim(),
  };
}

/// `:894-936` — `buildFormData(documentNo)`. **54 leaves, four sections.**
///
/// ## It takes the document number as a PARAMETER, and is invoked TWICE
///
/// `:964` `buildFormData("")` and `:981` `buildFormData(reference)`. Each
/// invocation independently re-evaluates `today()` at `:900`. Building once and
/// mutating `document_no` is what the flat pages do, it is the obvious
/// refactor, and it **changes behaviour at a midnight boundary** —
/// `CaseReferenceBinding.nestedParameter`'s `rebuildsPayload` is `true` and
/// [marriageSubmissionBodies] honours it (`F3-AC-32`, `F3-AC-33`).
///
/// ## `header` is a real object, not four dotted keys
///
/// `/header/document_no`, **not** `/header.document_no`. Birth emits the
/// literal flat key; the two flatten to the same dotted string and are
/// different wire bytes. Mutant M5
/// (`tier0_payload_equality_test.dart:842-863`) exists to catch a port that
/// flattens (`F3-AC-34`).
///
/// ## `creates_betrothal_record` is the product's only non-string primitive
///
/// `:904` — `betrothalMode === "new"`, a **bare JSON boolean**. In Dart a
/// `Map<String, Object?>` holding `true` serialises as `true`; holding
/// `'true'` serialises as `"true"`. Different bytes, and Tier 0 compares bytes
/// (`F3-AC-63`).
///
/// ## The mirror is SEVEN keys and it discards spouse B
///
/// `:914-920` — `both(a, b)` keeps A's trimmed value and collapses to `""` if
/// either is blank. Divorce's mirror is six keys with no `gender` and
/// `marriage_certificate_ref` in place of `residence_certificate_ref`
/// (`F3-AC-42`).
///
/// ## Three `OFFICE_DEFERRED` sites, all unconditional
///
/// `:922` `medical_certificate`, `:933` `couple_signatures`, `:934`
/// `registrar_signature` — emitted regardless of user input, so they are
/// present in every one of the four documents. `ADR-0003` mis-types
/// `medical_certificate` as a signature field; `fsd.md` § 12 `FU-C` records it
/// as `document` and the ADR is still unamended at HEAD (`FU-10`). Reproduced
/// and recorded, **not waived** — and emitting them does not discharge R-20
/// (`F3-AC-96` vs `F3-AC-97`).
Map<String, Object?> buildMarriageFormData(
  MarriageFormData form,
  SubmissionClock clock,
  String documentNo,
) {
  return <String, Object?>{
    // `:895-901`
    'header': <String, Object?>{
      'province_id': form.header.provinceId,
      'district_id': form.header.districtId,
      'village_id': form.header.villageId,
      'document_no': documentNo,
      // `:900` `today()` — the ONE registered divergence on this page.
      // The web's is UTC; ADR-0005 rules the port reads LOCAL. Two register
      // rows (create + update), pointer `/header/dated`, and no others.
      'dated': clock.todayLocal(),
    },
    // `:902-911`
    'betrothal': <String, Object?>{
      'betrothal_record_no': form.linkedRecord?.recordNo ?? '',
      'creates_betrothal_record': marriageIncludeBetrothalFee(form),
      'proposal_date': form.linkedRecord?.recordedDate ?? '',
      'household_head': form.betrothal.householdHead,
      'bride_price': form.betrothal.bridePriceCash,
      'bride_price_gold': form.betrothal.bridePriceGold,
      'housing': form.betrothal.housing,
      'attendees': <String>[form.betrothal.w1Name, form.betrothal.w2Name]
          .where((String v) => v.isNotEmpty)
          .join(', '),
    },
    // `:912-925`
    'spouses': <String, Object?>{
      // Section-level mirror the API validates against.
      'name': both(form.spouseA.fullName, form.spouseB.fullName),
      'dob': both(form.spouseA.dob, form.spouseB.dob),
      'gender': both(form.spouseA.gender, form.spouseB.gender),
      'nationality': both(form.spouseA.nationality, form.spouseB.nationality),
      'id_number': both(form.spouseA.idOrPassport, form.spouseB.idOrPassport),
      'current_address':
          both(form.spouseA.address.villageId, form.spouseB.address.villageId),
      'residence_certificate_ref':
          both(form.spouseA.residenceCertRef, form.spouseB.residenceCertRef),
      // Captured by the district office at the appointment.
      'medical_certificate': kOfficeDeferred,
      'spouse_a': marriageSpousePayload(form.spouseA),
      'spouse_b': marriageSpousePayload(form.spouseB),
    },
    // `:926-935`
    'registration': <String, Object?>{
      'marriage_date': form.reg.dateOfMarriage,
      'registration_place': form.reg.placeOfRegistration.trim(),
      'witness_1': <String>[form.reg.w1Name, form.reg.w1Id]
          .where((String v) => v.isNotEmpty)
          .join(' · '),
      'witness_2': <String>[form.reg.w2Name, form.reg.w2Id]
          .where((String v) => v.isNotEmpty)
          .join(' · '),
      'witness_3': <String>[form.reg.w3Name, form.reg.w3Id]
          .where((String v) => v.isNotEmpty)
          .join(' · '),
      // Signed in front of the registrar (PRD §8.5) — not captured in the app.
      'couple_signatures': kOfficeDeferred,
      'registrar_signature': kOfficeDeferred,
    },
  };
}

/// The `create` and `update` `form_data` trees of one submission, produced the
/// way `:952-983` produces them — **through the kernel binding**, so the
/// two-invocation mechanic lives in exactly one place.
///
/// `NestedParameterReference.bodies` calls the builder twice. Passing a
/// pre-built payload here, as Resident's `residentBodiesFrom` does, would be
/// the one-invocation refactor wearing this function's name.
SubmissionBodies marriageSubmissionBodies(
  MarriageFormData form,
  SubmissionClock clock,
  String referenceNo,
) {
  final SubmissionPlan plan = SubmissionPlan.forForm(CertificateForm.marriage);
  return plan.reference.bodies(
    (String documentNo) => buildMarriageFormData(form, clock, documentNo),
    referenceNo,
  );
}

/// One row of `uploads()` — `:938-949`.
class MarriageAttachment {
  const MarriageAttachment({
    required this.file,
    required this.slot,
    required this.kind,
    required this.label,
  });

  final PickedAttachment file;

  /// The schema key. **Three of Marriage's six slots appear twice** — see
  /// [marriageUploads].
  final String slot;

  /// `"document"` or `"photo"`. Only `supporting.photos_3x4` is a photo.
  final String kind;

  /// The ONLY thing distinguishing the two rows of a duplicated slot:
  /// `"Spouse A"` / `"Spouse B"`. Hardcoded English in the source — not an
  /// i18n key, not localised.
  final String label;
}

/// `:938-949` — `uploads()`. **NINE entries over SIX distinct slots.**
///
/// | slot | entries |
/// | --- | --- |
/// | `spouses.single_status_certificate` | **2** (Spouse A, Spouse B) |
/// | `spouses.prior_marital_proof` | **2** |
/// | `spouses.foreign_documents` | **2** |
/// | `supporting.household_book` | 1 |
/// | `supporting.photos_3x4` | 1 |
/// | `supporting.birth_record` | 1 |
///
/// `fsd.md` § 5.4 says "7 distinct slots"; counted at `:940-948` it is **6**
/// (`FU-6`).
///
/// ## No dedupe, and that is the wire contract
///
/// `:972-977` is a bare `for…of` over `uploads()` with no slot-keyed `Set` —
/// unlike Resident's (`ResidentCertificatePage.tsx:457`, `:526`), whose five
/// slots are all distinct so its dedupe cannot bite. Making Marriage's slots
/// unique (`…_a` / `…_b`) changes what the server receives and is forbidden
/// (`F3-AC-55`, `F3-AC-56`).
///
/// Whether the server overwrites spouse A's document with spouse B's is
/// `F3-NV-2` — `fsd.md` calls it *"the highest-priority item in this table"*.
/// It is a **backend** question. The port reproduces the duplication exactly
/// and does not fix it, because the fix is a wire-contract change.
///
/// ## `.filter(u => u.file !== null)` (`:949`)
///
/// A null file drops the entry **entirely**; it is never sent as an empty
/// multipart part (`F3-AC-59`).
///
/// ## This is the POST order, and it is NOT the DOM order
///
/// Tier 1 reads render order; Tier 0 and the attachment sequence read this
/// order. On Marriage the two happen to agree less than on Divorce, where they
/// visibly differ — see `divorce_payload.dart` (`F3-AC-58`).
List<MarriageAttachment> marriageUploads(MarriageFormData form) {
  final List<MarriageAttachment> out = <MarriageAttachment>[];

  void add(PickedAttachment? file, String slot, String kind, String label) {
    if (file == null) return; // `:949`
    out.add(
      MarriageAttachment(file: file, slot: slot, kind: kind, label: label),
    );
  }

  add(form.spouseA.singleStatusCert, 'spouses.single_status_certificate',
      'document', 'Spouse A');
  add(form.spouseB.singleStatusCert, 'spouses.single_status_certificate',
      'document', 'Spouse B');
  add(form.spouseA.priorMaritalProof, 'spouses.prior_marital_proof',
      'document', 'Spouse A');
  add(form.spouseB.priorMaritalProof, 'spouses.prior_marital_proof',
      'document', 'Spouse B');
  add(form.spouseA.foreignDocs, 'spouses.foreign_documents', 'document',
      'Spouse A');
  add(form.spouseB.foreignDocs, 'spouses.foreign_documents', 'document',
      'Spouse B');
  add(form.householdBook, 'supporting.household_book', 'document',
      'Household book');
  add(form.photos, 'supporting.photos_3x4', 'photo', '3x4 photographs');
  add(form.birthRecord, 'supporting.birth_record', 'document',
      'Children birth record');

  return out;
}

/// `:957-965` — the `POST /applications` envelope.
///
/// ```ts
/// service_code: "marriage",
/// province_id: header.provinceId,
/// district_id: header.districtId,
/// village_id: header.villageId,
/// event_date: reg.dateOfMarriage || undefined,
/// linked_reference_no: linkedRecord?.record_no,
/// form_data: buildFormData(""),
/// ```
///
/// Three things a tidier port gets wrong:
///
/// 1. **The location trio is written RAW.** Resident writes
///    `form.province || undefined` and the key is dropped when blank; Marriage
///    writes the value and sends `""`. Same three key names, two different
///    bodies (`envelope_shape.dart`, `F0-AC-19`).
/// 2. **`linked_reference_no` sits BETWEEN `event_date` and `form_data`** and
///    is **elided** when there is no linked record — `undefined`, which
///    `JSON.stringify` drops. Absent, not `""` and not `null` (`F3-AC-35`,
///    `F3-AC-36`).
/// 3. **`event_date` is `|| undefined`** — elided when the marriage date is
///    blank, and **never** `today()` (`F3-AC-41`).
Map<String, Object?> marriageCreateEnvelope({
  required MarriageFormData form,
  required Map<String, Object?> payload,
}) {
  return <String, Object?>{
    'service_code': kMarriageServiceCode,
    'province_id': form.header.provinceId,
    'district_id': form.header.districtId,
    'village_id': form.header.villageId,
    if (form.reg.dateOfMarriage.isNotEmpty)
      'event_date': form.reg.dateOfMarriage,
    if ((form.linkedRecord?.recordNo ?? '').isNotEmpty)
      'linked_reference_no': form.linkedRecord!.recordNo,
    'form_data': payload,
  };
}

/// `:980-983` — the `PATCH /applications/{id}` envelope.
///
/// **`form_data` is FIRST here and LAST on the create body.** Two different
/// byte sequences from the same key names; not a stylistic accident to be
/// normalised (`F3-AC-84`).
///
/// `event_date` is `|| undefined` here too, so it is elidable where the flat
/// family's is not (`submission_plan.dart:159-162`).
Map<String, Object?> marriageUpdateEnvelope({
  required MarriageFormData form,
  required Map<String, Object?> updatePayload,
}) {
  return <String, Object?>{
    'form_data': updatePayload,
    if (form.reg.dateOfMarriage.isNotEmpty)
      'event_date': form.reg.dateOfMarriage,
  };
}

/// `:988` — `METHOD_CODE[payment.method]`.
///
/// A **static map lookup with no network read**. `methodCodeSourceFor` is an
/// exhaustive `switch` with no `default` arm precisely so this cannot be got
/// wrong by defaulting (`method_code_source.dart:45-60`).
String marriageMethodCodeFor(DraftPaymentMethod method) =>
    kMarriageMethodCode[method]!;

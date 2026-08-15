/// `ResidentCertificatePage.tsx:459-541` — everything Resident puts on the
/// wire, transcribed as literal Dart maps.
///
/// ## This file is the Tier 0 gate
///
/// `ssd.md` § 14 F-6: *"Tier 0 payload equality is blocking and takes
/// precedence over Tier 3 disagreement."* The four oracle documents
/// `resident.{create,update}.{en,lo}.json` were derived by an **independent**
/// scan of the same source lines (`derive_forms_oracles.py`, Entry B) and
/// captured off the running pinned app (`execute_forms_oracle.mjs`, Entry A).
/// `test/features/certificates/presentation/resident/resident_tier0_test.dart`
/// compares `jsonEncode` of what this file returns against them **byte for
/// byte**. A mis-read here has to be made twice, in the same direction, by two
/// dispatches, to survive.
///
/// ## Why literal maps and not a builder
///
/// `submission_plan.dart:17-19`: *"A literal Dart map transcribed from a
/// literal TS object is diffable against the source by eye in review and
/// against the Tier 0 oracle by test. A strategy that computes the same map is
/// diffable against neither."* [buildResidentFormData]'s 22 lines sit in the
/// same order as `:460-481` so the two can be read side by side.
///
/// ## Key order is wire order
///
/// `client.ts:242` is a bare `JSON.stringify(options.body)` and
/// `endpoints.ts:325` passes the body straight through — no schema, no
/// allowlist, no canonicaliser between the object literal and the socket. Dart
/// map literals are insertion-ordered `LinkedHashMap`s and `jsonEncode` walks
/// insertion order, so a faithful transcription serialises identically with no
/// work. That is a property nobody maintains, so the test asserts the
/// serialised string rather than map equality — a `DeepCollectionEquality`
/// would pass a reordered transcription.
library;

import '../../../../presentation/payment/payment_draft.dart';
import '../../../wallet/domain/entities/payment_method.dart';
import '../../../application/domain/entities/picked_attachment.dart';
import '../../domain/submission/case_reference_binding.dart';
import '../../domain/submission/certificate_form.dart';
import '../../domain/submission/submission_clock.dart';
import '../../domain/submission/submission_plan.dart';
import 'resident_form_state.dart';

/// `:459-482` — `buildFormData()`.
///
/// **22 keys, in this order.** Every value is `form.<field>` verbatim except
/// the last, which is the clock.
///
/// Three facts the oracle checks that are easy to lose:
///
/// - **`purpose.purpose_other` is always present**, even when the purpose is
///   not `"other"` and the field never rendered (`:1008`). It goes out as `""`.
///   Eliding it would change the key count.
/// - **`purpose.issue_date` is the only computed leaf** and it is the one
///   registered divergence: the web's `today()` (`:148`) is
///   `new Date().toISOString().slice(0,10)` — **UTC** — and ADR-0005 rules the
///   port reads local instead. At the register's instant
///   `2026-08-14T02:00:00+07:00` this returns `2026-08-14` where the oracle
///   holds `2026-08-13`. Both halves are the assertion; see
///   `test/fidelity/tier0_divergences.yaml`, which exempts this pointer and
///   nothing else on this page's `form_data`.
/// - **Resident's builder takes no parameter.** Marriage's takes the case
///   reference (`MarriageCertificatePage.tsx:899`); Resident appends it
///   afterwards by spreading (`:522`). That is the whole
///   `FlatAppendedReference` / `NestedParameterReference` distinction, and it
///   is why [residentSubmissionBodies] wraps this in `(_) => …`.
Map<String, Object?> buildResidentFormData(
  ResidentFormData form,
  SubmissionClock clock,
) {
  return <String, Object?>{
    'header.province_id': form.province,
    'header.district_id': form.district,
    'header.village_id': form.villageName,
    'certifying_authority.village_chief_name': form.villageChiefName,
    'certifying_authority.certifying_district': form.certifyingJurisdiction,
    'applicant.citizen_name': form.citizenName,
    'applicant.age': form.age,
    'applicant.occupation': form.occupation,
    'applicant.nationality': form.nationality,
    'applicant.current_village_id': form.currentVillage,
    'applicant.group_khum': form.groupKhum,
    'applicant.unit_nuay': form.unitNuayBan,
    'applicant.house_no': form.houseNo,
    'household_reference.household_no': form.censusBookNo,
    'household_reference.household_issued_at': form.censusBookDate,
    'household_reference.household_district': form.censusDistrictProvince,
    'parentage.father_name': form.fatherName,
    'parentage.mother_name': form.motherName,
    'parentage.native_place': form.nativePlace,
    'purpose.purpose': form.purpose,
    'purpose.purpose_other': form.purposeOther,
    'purpose.issue_date': clock.todayLocal(),
  };
}

/// The `create` and `update` `form_data` trees of one submission, produced the
/// way `:500-524` produces them.
///
/// Routed through the kernel's [CaseReferenceBinding] rather than by appending
/// the key here, because the binding carries two things a local spread does
/// not: that Resident's builder runs **once** (`:501`), and that the reference
/// key goes on **last**, raising the key count by one. Both are wire facts.
/// `FlatAppendedReference.bodies` is the executable form of them.
SubmissionBodies residentSubmissionBodies(
  ResidentFormData form,
  SubmissionClock clock,
  String referenceNo,
) =>
    residentBodiesFrom(buildResidentFormData(form, clock), referenceNo);

/// The same two bodies, from a payload the caller has **already built**.
///
/// ## Why the submit orchestration needs this and not the function above
///
/// `:501` builds the payload **once** and `:522` spreads that same object into
/// the update. The reference number, though, does not exist until the create
/// has answered (`:515`) — so a submit that called
/// [residentSubmissionBodies] for the create and again for the update would
/// invoke [buildResidentFormData] **twice**, and the two calls read the clock
/// (`:481`). Under a fixed test clock they agree; under a real one, a
/// submission spanning local midnight would put two different
/// `purpose.issue_date` values on two bodies the source guarantees carry one.
///
/// So the payload is built once by the caller and handed here, and the
/// reference binding still does the appending — which is what keeps
/// `flat-appended-last` in exactly one place and keeps `F0-AC-14`'s
/// invoked-once property true of the real submit path and not only of the Tier
/// 0 fixture.
SubmissionBodies residentBodiesFrom(
  Map<String, Object?> payload,
  String referenceNo,
) {
  final SubmissionPlan plan = SubmissionPlan.forForm(CertificateForm.resident);
  return plan.reference.bodies((String _) => payload, referenceNo);
}

/// One row of `attachmentsToSend()` (`ResidentCertificatePage.tsx:484-491`) —
/// a picked file plus the two strings that go with it on the multipart POST.
class CertificateAttachment {
  const CertificateAttachment({
    required this.file,
    required this.slot,
    required this.kind,
  });

  final PickedAttachment file;

  /// The schema key this file answers — `"applicant.photo"`,
  /// `"applicant.id_front"`, … **Resident's five slots are all distinct**,
  /// which is what makes its slot-keyed dedupe `Set` safe; Marriage's are not
  /// (`attachment_guard.dart:24-28`).
  final String slot;

  /// `"photo"` or `"document"`. Only `applicant.photo` is a photo.
  final String kind;
}

/// `:507-514` — the `POST /applications` envelope.
///
/// ```ts
/// service_code: SERVICE_CODE,
/// province_id: form.province || undefined,
/// district_id: form.district || undefined,
/// village_id: form.villageName || undefined,
/// event_date: today(),
/// form_data: payload,
/// ```
///
/// **`|| undefined` is an elision, not an empty string.** `JSON.stringify`
/// drops a key whose value is `undefined`, so a Resident submission with no
/// province chosen puts five keys on the wire, not six. Marriage writes the raw
/// value at the same key name and sends `""` — same key, two different bodies
/// (`envelope_shape.dart:18-24`, `F0-AC-19`). A port that wrote `''` here would
/// serialise a key the web omits and fail Tier 0 by one key.
///
/// `event_date` is a **second** `today()` call (`:512`), distinct from the one
/// inside `buildFormData` at `:481`. Under a fixed clock they agree; the
/// register holds them as two separate rows for that reason
/// (`tier0_divergences.yaml`: resident/create/event_date and
/// resident/create/purpose.issue_date).
Map<String, Object?> residentCreateEnvelope({
  required ResidentFormData form,
  required Map<String, Object?> payload,
  required SubmissionClock clock,
}) {
  return <String, Object?>{
    'service_code': kResidentServiceCode,
    if (form.province.isNotEmpty) 'province_id': form.province,
    if (form.district.isNotEmpty) 'district_id': form.district,
    if (form.villageName.isNotEmpty) 'village_id': form.villageName,
    'event_date': clock.todayLocal(),
    'form_data': payload,
  };
}

/// `:521-524` — the `PATCH /applications/{id}` envelope.
///
/// ```ts
/// form_data: { ...payload, "header.ref_no": current.reference_no },
/// event_date: today(),
/// ```
///
/// **`form_data` is FIRST here and LAST on the create body.** Two different
/// byte sequences from the same two key names; not a stylistic accident to be
/// normalised (`submission_plan.dart:75-81`).
///
/// [updatePayload] is [SubmissionBodies.update] — already carrying
/// `header.ref_no` in last position. It is a parameter rather than something
/// this function appends, so the append mechanic stays in exactly one place.
Map<String, Object?> residentUpdateEnvelope({
  required Map<String, Object?> updatePayload,
  required SubmissionClock clock,
}) {
  return <String, Object?>{
    'form_data': updatePayload,
    'event_date': clock.todayLocal(),
  };
}

/// `:484-491` — `attachmentsToSend()`.
///
/// Order is the upload order, and it is **not** the order the citizen filled
/// the form in: the 3×4 photo from step 2 goes first, then step 1's four
/// documents. Reproduced as written.
///
/// The five slots are **all distinct**, which is what makes the `slotKeyed`
/// dedupe at `:527-529` safe on this page. Marriage's are not, and
/// `attachment_guard.dart:24-28` records that the guard's key is the defect
/// D-I names — but D-I cannot bite here, because no two Resident slots collide.
List<CertificateAttachment> residentAttachmentsToSend(ResidentFormData form) {
  final List<CertificateAttachment> out = <CertificateAttachment>[];

  void add(PickedAttachment? file, String slot, String kind) {
    if (file == null) return; // `.filter(a => a.file !== null)`
    out.add(CertificateAttachment(file: file, slot: slot, kind: kind));
  }

  add(form.picture, 'applicant.photo', 'photo');
  add(form.frontId, 'applicant.id_front', 'document');
  add(form.backId, 'applicant.id_back', 'document');
  add(
    form.familyBookCover,
    'household_reference.family_book_upload',
    'document',
  );
  add(
    form.familyBookContents,
    'household_reference.family_book_contents',
    'document',
  );

  return out;
}

/// `:494-498` — `methodCodeFor(method)`.
///
/// ```ts
/// const wantedKind = method === "qr" ? "qr" : "bank";
/// const found = (methodsQuery.data ?? []).find((m) => m.kind === wantedKind && m.enabled);
/// return found?.code ?? (method === "qr" ? "laoqr" : "bank-transfer");
/// ```
///
/// This is `MethodCodeSource.liveList` (`method_code_source.dart:19-21`), and
/// Resident's shape is **not** Birth's: Resident picks by *kind* and falls back
/// per-branch, where Birth and Death prefer an enabled `qr` row, then any
/// enabled row, then `"laoqr"`. Two `liveList` pages, two algorithms; F2
/// transcribes its own.
///
/// **`cc` resolves to the `bank` kind and to `"bank-transfer"`** — the card
/// distinction is discarded before it reaches the API. `fsd.md` D-O escalates
/// that separately; it is reproduced here, not repaired.
///
/// This value goes on the **`pay` body**, not on `form_data`, so no Tier 0
/// oracle covers it — which is exactly why `method_code_source.dart:4-7`
/// declares the mechanic instead of leaving it to the page.
String residentMethodCodeFor(
  DraftPaymentMethod method,
  List<PaymentMethod> methods,
) {
  final PaymentMethodKind wantedKind = method == DraftPaymentMethod.qr
      ? PaymentMethodKind.qr
      : PaymentMethodKind.bank;

  for (final PaymentMethod m in methods) {
    if (m.kind == wantedKind && m.enabled) return m.code;
  }

  return method == DraftPaymentMethod.qr ? 'laoqr' : 'bank-transfer';
}

/// `BirthDeclarationPage.tsx:740-853` — everything Birth puts on the wire,
/// transcribed as literal Dart maps.
///
/// ## This file is the Tier 0 gate for eight of F2's twenty documents
///
/// `birth.{create,update}.{en,lo}` and `birth.father-unknown.{create,update}.{en,lo}`
/// — **294 leaves per locale**. They were captured off the running pinned app
/// (`execute_forms_oracle.mjs`, Entry A) and independently re-transcribed
/// (`derive_forms_oracles.py`, Entry B), and the two already agree at this pin.
/// So unlike F1, a red leaf here is **the port**, not a possibly-bad oracle
/// (`specs.md` § 6.1).
///
/// ## Key order is wire order
///
/// `client.ts:242` is a bare `JSON.stringify(options.body)`. Dart map literals
/// are insertion-ordered `LinkedHashMap`s and `jsonEncode` walks insertion
/// order, so a faithful transcription serialises identically with no work. The
/// tests assert the serialised string, not map equality — a
/// `DeepCollectionEquality` would pass a reordered transcription.
///
/// ## The mother is emitted TWICE, and that is structural
///
/// `:786-787` spreads `parentData(mother, "parents")` and then
/// `parentData(mother, "parents.mother")` — twenty-six keys carrying thirteen
/// values. A port that emits the block once and aliases the second prefix at
/// serialisation time is byte-equal on every fixture that exists (the mother is
/// one object) and wrong on the first input where the two could differ.
/// [birthParentData] is therefore **invoked twice** and `F2-AC-45` asserts the
/// invocation count, not the output.
///
/// ## Nothing here is shared with `presentation/death/`
///
/// [birthParentData] takes **two** parameters and emits **13** keys; Death's
/// takes three and emits 14, with the skip branch *inside* the function and a
/// different literal (`"deceased-or-unknown"` against Birth's `"unknown"`).
/// [kBirthLegalBasisKey] is read from the `birth` namespace and nowhere else:
/// the two pages' English `legalBasisText` is byte-identical and their **Lao is
/// not** (`specs.md` § 2.2 Finding B), so one hoisted constant is byte-correct
/// in English and byte-wrong in Lao on all twenty documents.
library;

import '../../../application/domain/entities/picked_attachment.dart';
import '../../../wallet/domain/entities/payment_method.dart';
import '../../domain/submission/case_reference_binding.dart';
import '../../domain/submission/certificate_form.dart';
import '../../domain/submission/submission_clock.dart';
import '../../domain/submission/submission_plan.dart';
import 'birth_form_state.dart';

/// `:761` — the i18n key `buildFormData` reads for `header.legal_basis`.
///
/// **The value is a payload value, not a label.** It is looked up in the
/// `birth` namespace at build time and injected straight into `form_data`, so
/// the wire body's locale is whatever the reader's locale is at submit.
///
/// The key *name* is spelled here and the lookup happens at the call site, so
/// that no Dart file in this tree contains the sentence itself — `F2-AC-37`
/// greps `lib/` for the sentence's opening clause and requires zero hits —
/// which is why this comment names the criterion and not the sentence.
///
/// Note `birth.legalBasisTitle` (`birth.ts:42`) and `death.legalBasis`
/// (`death.ts:33`) are different key *names* for the adjacent heading. A port
/// that harmonises them breaks `F2-AC-78`'s 152/97 counts.
const String kBirthLegalBasisKey = 'legalBasisText';

/// `:740-754` — `parentData(p, prefix)`, **13 keys**.
///
/// ## Two parameters, and no skip branch
///
/// Birth handles father-unknown at the **call site** (`:788-790`); Death handles
/// it *inside* its own `parentData` with a third `skipped` parameter
/// (`DeathDeclarationPage.tsx:764-766`). `F2-AC-21` asserts the difference
/// structurally rather than by output, because both shapes produce the same
/// bytes on the fixtures that exist.
///
/// ## Thirteen keys, not fourteen
///
/// Death's adds `workplace` (`DeathDeclarationPage.tsx:781`). Parameterising one
/// helper to emit either set is the shared-symbol failure § 6.2 is organised
/// around: it is 80 saved lines against the property that makes this port
/// auditable, that each Dart page corresponds line-for-line to one TSX page.
Map<String, Object?> birthParentData(BirthParentInfo p, String prefix) {
  return <String, Object?>{
    '$prefix.name': p.fullName,
    '$prefix.fingerprint': p.fingerprint,
    '$prefix.dob': p.dob,
    '$prefix.ethnicity': p.ethnicity,
    '$prefix.nationality': p.nationality,
    '$prefix.ethnic_group': p.ethnicGroup,
    '$prefix.religion': p.religion,
    '$prefix.marital_status': p.maritalStatus,
    '$prefix.current_address': p.addrVillage,
    '$prefix.house_no': p.addrHouseNo,
    '$prefix.id_number': p.censusOrId,
    '$prefix.education': p.education,
    '$prefix.occupation': p.occupation,
  };
}

/// `:788-790` — the father-unknown branch, at the **call site**.
///
/// ```ts
/// ...(fatherUnknown
///   ? { "parents.father.status": "unknown" }
///   : parentData(father, "parents.father")),
/// ```
///
/// The literal is `"unknown"`. Death's is `"deceased-or-unknown"` and lives
/// inside its `parentData`. A shared constant for either FAILS `F2-AC-22`.
const String kBirthFatherUnknownStatus = 'unknown';

/// `:756-807` — `buildFormData()`, **79 keys** in this order.
///
/// ## The arithmetic, asserted rather than assumed (`F2-AC-31`)
///
/// `79 = 5 header + 20 child + 13 parents + 13 parents.mother + 13 parents.father
/// + 15 informant`. With `fatherUnknown` the father block collapses to one key,
/// so `67 = 79 − 13 + 1`.
///
/// ## `header.dated` is the clock, and it is a registered divergence
///
/// `today()` (`:164`) is `new Date().toISOString().slice(0,10)` — **UTC** —
/// and `ADR-0005` rules the port reads local. At the register's instant
/// `2026-08-14T02:00:00+07:00` this emits `2026-08-14` where the oracle holds
/// `2026-08-13`. `tier0_divergences.yaml` exempts the pointer; `F2-AC-38`
/// asserts the local value **positively**, because asserting only that the leaf
/// was skipped would also pass a port that reintroduced `toUtc()`.
///
/// ## `header.document_no` is NOT emitted here
///
/// It is appended to the update body only, through
/// `CaseReferenceBinding.flatAppended` — key count `n -> n+1`, order otherwise
/// unchanged (`:835`).
///
/// ## Every value is a `String`
///
/// No bare JSON number, boolean or null on either F2 page (`F2-AC-46`). The
/// programme's one bare `true` is Marriage's and is F3's.
Map<String, Object?> buildBirthFormData(
  BirthFormData form,
  SubmissionClock clock, {
  /// `t("legalBasisText")` resolved against the **`birth`** namespace by the
  /// caller.
  ///
  /// A parameter rather than a lookup inside this function for two reasons.
  /// First, it keeps this file pure, which is what lets Tier 0 drive it from a
  /// literal fixture. Second, it puts the namespace choice at the call site
  /// where the isolation guard can see it: there is exactly one caller in
  /// `presentation/birth/` and it reads `birth`.
  required String legalBasisText,
}) {
  final BirthChildInfo child = form.child;
  final BirthInformantInfo informant = form.informant;

  return <String, Object?>{
    'header.province_id': form.province,
    'header.district_id': form.district,
    'header.village_id': form.village,
    'header.dated': clock.todayLocal(),
    'header.legal_basis': legalBasisText,

    'child.child_name': child.fullName,

    // Forms v2 — the optional Latin split names. **Absent key when empty,
    // never `""`**: every oracle and the golden logs predate these keys and
    // populate none of them, so emitting them unconditionally would move
    // bytes on all twenty documents for no input.
    if (child.surname.isNotEmpty) 'child.child_surname': child.surname,
    if (child.givenName.isNotEmpty) 'child.child_given_name': child.givenName,

    'child.child_gender': child.gender,
    'child.child_dob': child.dob,
    // Forms v2 — optional time of birth, `HH:MM`, passed through verbatim.
    if (child.timeOfBirth.isNotEmpty)
      'child.child_time_of_birth': child.timeOfBirth,
    'child.child_weight_kg': child.weight,
    'child.child_height_cm': child.height,
    'child.child_fingerprint': child.fingerprint,
    'child.child_blood_type': child.bloodType,
    'child.delivery_mode': child.deliveryMode,
    'child.delivery_assisted_by': child.deliveryAssistedBy,
    'child.birth_type': child.birthType,
    'child.birth_order': child.birthOrder,
    'child.child_ethnicity': child.ethnicity,
    'child.child_nationality': child.nationality,
    'child.child_religion': child.religion,
    'child.place_of_birth': child.pobVillage,
    'child.place_of_birth_country': child.pobCountry,
    'child.current_address': child.addrVillage,
    'child.house_no': child.addrHouseNo,
    'child.twin_name': child.twinName,
    'child.twin_gender': child.twinGender,

    // `:784-785` — "The schema keeps one mandatory set for 'Parents'; the
    // mother carries it and each instance is also stored under its own key."
    //
    // TWO invocations, deliberately. See the library docstring and `F2-AC-45`.
    ...birthParentData(form.mother, 'parents'),
    // Forms v2 — the optional Latin split names go under the PERSON's own
    // prefix only (`parents.mother.*`, `parents.father.*`). The bare
    // `parents` mirror is the schema's mandatory set and the guide names no
    // split key there, so it stays exactly thirteen keys (`F2-AC-20`).
    if (form.mother.surname.isNotEmpty)
      'parents.mother.surname': form.mother.surname,
    if (form.mother.givenName.isNotEmpty)
      'parents.mother.given_name': form.mother.givenName,
    ...birthParentData(form.mother, 'parents.mother'),
    if (form.fatherUnknown)
      'parents.father.status': kBirthFatherUnknownStatus
    else ...<String, Object?>{
      ...birthParentData(form.father, 'parents.father'),
      if (form.father.surname.isNotEmpty)
        'parents.father.surname': form.father.surname,
      if (form.father.givenName.isNotEmpty)
        'parents.father.given_name': form.father.givenName,
    },

    'informant.informant_name': informant.fullName,
    'informant.informant_fingerprint': informant.fingerprint,
    'informant.informant_dob': informant.dob,
    'informant.informant_ethnicity': informant.ethnicity,
    'informant.informant_ethnic_group': informant.ethnicGroup,
    'informant.informant_religion': informant.religion,
    'informant.informant_nationality': informant.nationality,
    'informant.informant_marital': informant.maritalStatus,
    'informant.informant_address': informant.addrVillage,
    'informant.informant_house_no': informant.addrHouseNo,
    'informant.informant_id_number': informant.censusOrId,
    'informant.informant_education': informant.education,
    'informant.informant_relation': informant.relationship,
    'informant.informant_phone': informant.phone,
    'informant.informant_email': informant.email,
  };
}

/// The `create` and `update` `form_data` trees of one submission, from a
/// payload the caller has **already built**.
///
/// ## Why the payload is a parameter and not built here
///
/// `:816` builds it **once** and `:835` spreads that same object into the
/// update. A helper that called [buildBirthFormData] for each body would invoke
/// it twice, and the builder reads the clock (`:760`) — under a fixed test clock
/// the two agree, under a real one a submission spanning local midnight would
/// put two different `header.dated` values on two bodies the source guarantees
/// carry one.
///
/// Routing through the kernel's [CaseReferenceBinding] rather than appending the
/// key here keeps `flat-appended-last` in exactly one place, and keeps
/// `F0-AC-14`'s invoked-once property true of the real submit path rather than
/// only of the Tier 0 fixture.
SubmissionBodies birthBodiesFrom(
  Map<String, Object?> payload,
  String referenceNo,
) {
  final SubmissionPlan plan = SubmissionPlan.forForm(CertificateForm.birth);
  return plan.reference.bodies((String _) => payload, referenceNo);
}

/// `:820-827` — the `POST /applications` envelope.
///
/// ```ts
/// service_code: SERVICE_CODE,
/// province_id: header.province || undefined,
/// district_id: header.district || undefined,
/// village_id: header.village || undefined,
/// event_date: child.dob || today(),
/// form_data: payload,
/// ```
///
/// **`|| undefined` is an elision, not an empty string** — `JSON.stringify`
/// drops the key. Transcribed as written; no criterion asserts the elided
/// inhabitant, because `canProceed()` step 1 requires all three (`:711-712`) so
/// submission is unreachable without them (`specs.md` § 6.5, `F2-AC-29` note).
///
/// **`event_date` is `child.dob || today()`.** Every fixture on disk supplies
/// the dob, so in all twenty executed oracles this leaf is a deterministic
/// function of the fixture input — which is why its register exemption protects
/// a branch no oracle reaches (`specs.md` § 2.2 Finding D). `F2-AC-39` asserts
/// it positively against the fixture; `F2-AC-40` unit-tests the `|| today()`
/// fallback that has no oracle and cannot have one until `FU-1` lands.
Map<String, Object?> birthCreateEnvelope({
  required BirthFormData form,
  required Map<String, Object?> payload,
  required SubmissionClock clock,
}) {
  return <String, Object?>{
    'service_code': kBirthServiceCode,
    if (form.province.isNotEmpty) 'province_id': form.province,
    if (form.district.isNotEmpty) 'district_id': form.district,
    if (form.village.isNotEmpty) 'village_id': form.village,
    'event_date': birthEventDate(form, clock),
    'form_data': payload,
  };
}

/// `:825` / `:836` — `child.dob || today()`.
///
/// Spelled once and used by both envelopes because the source computes it twice
/// from the same two inputs. Under the register's fixed clock the two calls
/// agree; the register holds them as separate rows for the same reason
/// Resident's does.
String birthEventDate(BirthFormData form, SubmissionClock clock) =>
    form.child.dob.isNotEmpty ? form.child.dob : clock.todayLocal();

/// `:834-837` — the `PATCH /applications/{id}` envelope.
///
/// **`form_data` is FIRST here and LAST on the create body.** Two different
/// byte sequences from the same key names; not a stylistic accident to
/// normalise.
///
/// [updatePayload] is [SubmissionBodies.update] — already carrying
/// `header.document_no` in last position — so the append mechanic stays in one
/// place.
Map<String, Object?> birthUpdateEnvelope({
  required BirthFormData form,
  required Map<String, Object?> updatePayload,
  required SubmissionClock clock,
}) {
  return <String, Object?>{
    'form_data': updatePayload,
    'event_date': birthEventDate(form, clock),
  };
}

/// `:839-842` — the page's **one** attachment slot.
///
/// `child.hospital_notice`, kind `"document"`. One slot, so there is no
/// ordering question and no list pipeline: Resident had five and this page has
/// one (`specs.md` § 6.6 item 4).
const String kBirthAttachmentSlot = 'child.hospital_notice';
const String kBirthAttachmentKind = 'document';

/// The attachment to send, or null. Mirrors `:839`'s guard shape without the
/// `uploaded` set, which is the cubit's (it is a `useRef`, per-page-instance and
/// not persisted — `:738`).
PickedAttachment? birthAttachmentToSend(BirthFormData form) =>
    form.hospitalNotice;

/// `:809-813` — `methodCode()`.
///
/// ```ts
/// const found = (methodsQuery.data ?? []).find((m) => m.kind === "qr" && m.enabled)
///   ?? (methodsQuery.data ?? []).find((m) => m.enabled);
/// return found?.code ?? "laoqr";
/// ```
///
/// **No-arg**, unlike Resident's `methodCodeFor(method)`, which branches on the
/// citizen's selected payment method and falls back per branch (`:494-498`).
/// `method_code_source.dart:16-23` records that both are `liveList` and that the
/// two shapes differ; F2 transcribes its own rather than reusing Resident's.
///
/// Byte-identical to Death's (`DeathDeclarationPage.tsx:833-837`) — and § 6.2
/// still forbids sharing it, because it lives inside two separately-ported
/// pages.
///
/// This value goes on the **`pay` body**, not on `form_data`, so no Tier 0
/// oracle covers it. `F2-AC-48` tests all four cases.
String birthMethodCode(List<PaymentMethod> methods) {
  for (final PaymentMethod m in methods) {
    if (m.kind == PaymentMethodKind.qr && m.enabled) return m.code;
  }
  for (final PaymentMethod m in methods) {
    if (m.enabled) return m.code;
  }
  return 'laoqr';
}

/// `:852` — `result.receipt_no ?? result.transaction?.receipt_no`.
///
/// Flat first, nested second, null if neither. The pay call answers a two-key
/// map in the wire's own shape (see `certificates_bloc_injection.dart`'s
/// adapter), so this precedence is expressed against the wire vocabulary rather
/// than against B6b's entity.
String? birthReceiptOf(Object? result) {
  if (result is! Map<String, Object?>) return null;
  final Object? flat = result['receipt_no'];
  if (flat is String && flat.isNotEmpty) return flat;
  final Object? txn = result['transaction'];
  if (txn is Map<String, Object?>) {
    final Object? nested = txn['receipt_no'];
    if (nested is String && nested.isNotEmpty) return nested;
  }
  return null;
}

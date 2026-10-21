/// `DeathDeclarationPage.tsx:764-877` — everything Death puts on the wire,
/// transcribed as literal Dart maps.
///
/// ## This file is the Tier 0 gate for twelve of F2's twenty documents
///
/// `death.{create,update}.{en,lo}`, `death.father-skip.{create,update}.{en,lo}`
/// and `death.mother-skip.{create,update}.{en,lo}` — **405 leaves per locale**.
/// Entry A and Entry B already agree at this pin, so a red leaf here is **the
/// port** (`specs.md` § 6.1).
///
/// ## `motherSkip` collapses TWO prefixes, not one
///
/// The mother is emitted under both `parents` and `parents.mother` (`:815-816`),
/// so skipping her removes 14 keys twice and adds one key twice:
/// `54 = 80 − 14 − 14 + 1 + 1`. If a port reports 67 for `death.mother-skip` it
/// collapsed one prefix instead of two and the whole double-emission is wrong
/// (`specs.md` § 11 item 7, `F2-AC-31`).
///
/// ## Nothing here is shared with `presentation/birth/`
///
/// [deathParentData] takes **three** parameters and emits **14** keys with the
/// skip branch *inside* it; Birth's takes two, emits 13, and branches at the
/// call site. [kDeathParentSkipStatus] is `"deceased-or-unknown"`; Birth's is
/// `"unknown"`. `legalBasisText` is read from the **`death`** namespace: the two
/// pages' English is byte-identical and their Lao is not, so one shared
/// constant is byte-correct in English and byte-wrong in Lao on all twenty
/// documents (`specs.md` § 2.2 Finding B, `F2-AC-36`).
library;

import '../../../application/domain/entities/picked_attachment.dart';
import '../../../wallet/domain/entities/payment_method.dart';
import '../../domain/submission/case_reference_binding.dart';
import '../../domain/submission/certificate_form.dart';
import '../../domain/submission/submission_clock.dart';
import '../../domain/submission/submission_plan.dart';
import 'death_form_state.dart';

/// `:789` — the i18n key `buildFormData` reads for `header.legal_basis`.
///
/// Looked up in the **`death`** namespace at build time and injected straight
/// into `form_data`. The key *name* is spelled here and the lookup happens at
/// the call site, so no Dart file contains the sentence itself (`F2-AC-37`).
///
/// `death.legalBasis` (`death.ts:33`) is the adjacent **heading** and is a
/// different key from this one; Birth spells the same heading
/// `legalBasisTitle`. Harmonising the two names breaks `F2-AC-78`'s counts.
const String kDeathLegalBasisKey = 'legalBasisText';

/// `:766` — the skip literal.
///
/// Birth's is `"unknown"` and lives at its call site. A shared constant FAILS
/// `F2-AC-22`.
const String kDeathParentSkipStatus = 'deceased-or-unknown';

/// `:764-782` — `parentData(p, prefix, skipped)`.
///
/// ## Three parameters, and the skip branch is INSIDE
///
/// ```ts
/// skipped
///   ? { [`${prefix}.status`]: "deceased-or-unknown" }
///   : { …14 keys }
/// ```
///
/// Birth handles its one skip at the **call site** (`BirthDeclarationPage.tsx:788-790`)
/// and its helper has no skip branch at all. `F2-AC-21` asserts the difference
/// structurally, because both shapes emit the same bytes on the fixtures that
/// exist.
///
/// ## Fourteen keys, not thirteen
///
/// The extra is `workplace`. Parameterising one helper to emit either set is
/// the shared-symbol failure § 6.2 is organised around.
Map<String, Object?> deathParentData(
  DeathParentInfo p,
  String prefix,
  bool skipped,
) {
  if (skipped) {
    return <String, Object?>{'$prefix.status': kDeathParentSkipStatus};
  }
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
    '$prefix.workplace': p.workplace,
  };
}

/// `:784-831` — `buildFormData()`, **80 keys** in this order.
///
/// ## The arithmetic, asserted rather than assumed (`F2-AC-31`)
///
/// `80 = 5 header + 21 deceased + 14 parents + 14 parents.mother + 14
/// parents.father + 12 informant`.
/// `father-skip = 80 − 14 + 1 = 67`.
/// **`mother-skip = 80 − 14 − 14 + 1 + 1 = 54`** — the two-prefix collapse.
///
/// ## `deceased.cause_of_death_other` is emitted UNCONDITIONALLY
///
/// `:811`. The control renders only when `cause === "other"` (`:1245`), so on
/// every other path this goes out as `""`. Eliding it would change the key
/// count (`F2-AC-62`).
///
/// ## `deceased.place_of_death_country` has no writer
///
/// It comes from the blank record's `"Laos"` and nothing on the page can change
/// it. Compared, not exempted — F0 § 6.5.7 refused the exemption (`F2-AC-44`).
///
/// ## Every value is a `String`
///
/// `F2-AC-46`.
Map<String, Object?> buildDeathFormData(
  DeathFormData form,
  SubmissionClock clock, {
  /// `t("legalBasisText")` resolved against the **`death`** namespace by the
  /// caller. See [kDeathLegalBasisKey]; a parameter for the same two reasons
  /// Birth's is one — purity for Tier 0, and the namespace choice visible at a
  /// call site the isolation guard can see.
  required String legalBasisText,
}) {
  final DeathDeceasedInfo d = form.deceased;
  final DeathInformantInfo informant = form.informant;

  return <String, Object?>{
    'header.province_id': form.province,
    'header.district_id': form.district,
    'header.village_id': form.village,
    'header.dated': clock.todayLocal(),
    'header.legal_basis': legalBasisText,

    'deceased.deceased_name': d.fullName,

    // Forms v2 — the optional Latin split names. **Absent key when empty,
    // never `""`**: every oracle and the golden logs predate these keys and
    // populate none of them, so emitting them unconditionally would move
    // bytes on all twenty documents for no input. They sit with the other
    // deceased identity keys, in the guide's table order.
    if (d.surname.isNotEmpty) 'deceased.deceased_surname': d.surname,
    if (d.givenName.isNotEmpty) 'deceased.deceased_given_name': d.givenName,

    'deceased.deceased_fingerprint': d.fingerprint,
    'deceased.deceased_gender': d.gender,
    'deceased.deceased_dob': d.dob,
    'deceased.deceased_education': d.education,
    'deceased.deceased_occupation': d.occupation,
    'deceased.deceased_workplace': d.workplace,
    'deceased.deceased_ethnicity': d.ethnicity,
    'deceased.deceased_nationality': d.nationality,
    'deceased.deceased_ethnic_group': d.ethnicGroup,
    'deceased.deceased_religion': d.religion,
    'deceased.deceased_marital': d.maritalStatus,
    'deceased.deceased_address': d.addrVillage,
    'deceased.house_no': d.addrHouseNo,
    'deceased.deceased_id_number': d.censusOrId,
    'deceased.place_of_death': d.podVillage,
    'deceased.place_of_death_country': d.podCountry,
    'deceased.date_of_death': d.dateOfDeath,
    'deceased.time_of_death': d.timeOfDeath,
    'deceased.cause_of_death': d.cause,
    'deceased.cause_of_death_other': d.causeOther,

    // `:813-814` — "The schema keeps one mandatory set for 'Parents of the
    // deceased'; the mother carries it, and each instance is also stored under
    // its own key."
    //
    // TWO invocations for the mother, which is why `motherSkip` collapses two
    // prefixes. `F2-AC-45`.
    ...deathParentData(form.mother, 'parents', form.motherSkip),
    ...deathParentData(form.mother, 'parents.mother', form.motherSkip),
    ...deathParentData(form.father, 'parents.father', form.fatherSkip),

    'informant.informant_name': informant.fullName,
    'informant.informant_fingerprint': informant.fingerprint,
    'informant.informant_dob': informant.dob,
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
/// `:840` builds it once and `:859` spreads that same object into the update.
/// See `birth_payload.dart`'s note on why the payload is a parameter — the same
/// clock reasoning applies, against `:788`.
SubmissionBodies deathBodiesFrom(
  Map<String, Object?> payload,
  String referenceNo,
) {
  final SubmissionPlan plan = SubmissionPlan.forForm(CertificateForm.death);
  return plan.reference.bodies((String _) => payload, referenceNo);
}

/// `:849` / `:860` — `deceased.dateOfDeath || today()`.
///
/// Every fixture on disk supplies the date, so in all twelve executed death
/// oracles this leaf is a deterministic function of the fixture input and its
/// register exemption protects a branch no oracle reaches (`specs.md` § 2.2
/// Finding D). `F2-AC-39` asserts it positively; `F2-AC-40` unit-tests the
/// fallback.
String deathEventDate(DeathFormData form, SubmissionClock clock) =>
    form.deceased.dateOfDeath.isNotEmpty
        ? form.deceased.dateOfDeath
        : clock.todayLocal();

/// `:844-851` — the `POST /applications` envelope.
///
/// `|| undefined` is an elision, not an empty string. Transcribed as written;
/// no criterion asserts the elided inhabitant, because `canProceed()` step 1
/// requires all three (`:735-736`) so submission is unreachable without them.
Map<String, Object?> deathCreateEnvelope({
  required DeathFormData form,
  required Map<String, Object?> payload,
  required SubmissionClock clock,
}) {
  return <String, Object?>{
    'service_code': kDeathServiceCode,
    if (form.province.isNotEmpty) 'province_id': form.province,
    if (form.district.isNotEmpty) 'district_id': form.district,
    if (form.village.isNotEmpty) 'village_id': form.village,
    'event_date': deathEventDate(form, clock),
    'form_data': payload,
  };
}

/// `:858-861` — the `PATCH /applications/{id}` envelope.
///
/// **`form_data` FIRST**, against the create body's LAST.
Map<String, Object?> deathUpdateEnvelope({
  required DeathFormData form,
  required Map<String, Object?> updatePayload,
  required SubmissionClock clock,
}) {
  return <String, Object?>{
    'form_data': updatePayload,
    'event_date': deathEventDate(form, clock),
  };
}

/// `:863-866` — the page's **one** attachment slot.
const String kDeathAttachmentSlot = 'deceased.death_notice';
const String kDeathAttachmentKind = 'document';

PickedAttachment? deathAttachmentToSend(DeathFormData form) => form.deathNotice;

/// `:833-837` — `methodCode()`.
///
/// No-arg: first enabled `qr` row, else first enabled row of any kind, else
/// `"laoqr"`. **Byte-identical to Birth's** (`BirthDeclarationPage.tsx:809-813`)
/// and § 6.2 still forbids sharing it, because it lives inside two separately-
/// ported pages. Not Resident's `methodCodeFor`, which branches on the
/// citizen's chosen method and falls back per branch.
String deathMethodCode(List<PaymentMethod> methods) {
  for (final PaymentMethod m in methods) {
    if (m.kind == PaymentMethodKind.qr && m.enabled) return m.code;
  }
  for (final PaymentMethod m in methods) {
    if (m.enabled) return m.code;
  }
  return 'laoqr';
}

/// `:876` — `result.receipt_no ?? result.transaction?.receipt_no`.
String? deathReceiptOf(Object? result) {
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

/// `DeathDeclarationPage.tsx:52-239` and `:130-137` — the page's own state
/// records, its 422 routing table and its step list, transcribed.
///
/// ## Nothing here is shared with `presentation/birth/`
///
/// `specs.md` § 6.2 RULING 1, and `certificate_page_isolation_guard_test.dart`
/// enforces it. The measured Birth↔Death difference table lives in
/// `architecture-review.md` § 1 and was written **before this file existed**
/// (`F2-AC-15`, `F2-AC-84`); the short form is that these two pages agree on
/// their skeleton and disagree on almost every detail that reaches the wire,
/// including their requiredness model, which differs at the type level.
///
/// The four differences visible in *this* file specifically:
///
/// - [DeathParentInfo] carries **`workplace`**; Birth's does not.
/// - [DeathInformantInfo] has **no `ethnicity`, `ethnicGroup` or `religion`**;
///   Birth's has all three.
/// - [kDeathSteps] is a list of bare ids; Birth's `STEP_META` carries three i18n
///   keys per step and Death resolves its titles by interpolation instead.
/// - [kDeathGenders] are **hard-coded bilingual literals**; Birth's are
///   namespace keys.
library;

import '../../../../features/session/domain/entities/bilingual.dart';
import '../../../application/domain/entities/picked_attachment.dart';

/// `:52` — `const SERVICE_CODE = "death"`.
///
/// Deliberately **not** read from `CertificateForm.death.serviceCode`: two
/// independent transcriptions of one source line are worth more than the
/// deduplication.
const String kDeathServiceCode = 'death';

/// `:130-137` — `STEPS`, **an array of bare `{id}`**.
///
/// Birth's `STEP_META` (`BirthDeclarationPage.tsx:584-591`) carries
/// `{id, titleKey, subtitleKey, shortKey}` per step. Death has no key table at
/// all: `StepHeader` builds them by **string interpolation**,
/// `` t(`step${step}Title`) `` and `` t(`step${step}Subtitle`) `` (`:667-668`).
///
/// `F2-AC-58` forbids normalising Death onto Birth's shape. The interpolation
/// is reproduced by [deathStepTitleKey] / [deathStepSubtitleKey] rather than by
/// a lookup table, because a lookup table *is* Birth's shape.
const List<int> kDeathSteps = <int>[1, 2, 3, 4, 5, 6];

/// `:758` — `const lastStep = STEPS.length`.
const int kDeathStepCount = 6;

/// `:667` — `` t(`step${step}Title` as "step1Title") ``.
String deathStepTitleKey(int step) => 'step${step}Title';

/// `:668` — `` t(`step${step}Subtitle` as "step1Subtitle") ``.
String deathStepSubtitleKey(int step) => 'step${step}Subtitle';

/// `:140-143` — `GENDERS`.
///
/// **Hard-coded `Bilingual` literals, bypassing the `death` namespace
/// entirely.** Birth's are i18n keys into the `birth` namespace
/// (`BirthDeclarationPage.tsx:134-137`). `F2-AC-83` forbids harmonising them,
/// and these four strings are deliberately **not** `death` namespace keys —
/// promoting them would take the count from 97 to 99 and `F2-AC-78` would catch
/// it.
///
/// Rendered with `text(g.label, lang)` (`:729`), the frozen
/// `lib/i18n/i18n.dart:90` helper.
final List<DeathGenderOption> kDeathGenders = <DeathGenderOption>[
  const DeathGenderOption(
    value: 'female',
    label: Bilingual(en: 'Female', lo: 'ຍິງ'),
  ),
  const DeathGenderOption(
    value: 'male',
    label: Bilingual(en: 'Male', lo: 'ຊາຍ'),
  ),
];

class DeathGenderOption {
  const DeathGenderOption({required this.value, required this.label});
  final String value;
  final Bilingual label;
}

/// `:175-217` — `FIELD_STEP`, **41 entries**.
///
/// ## The schema field table, transcribed as measured
///
/// `specs.md` § 2.2 Finding E: 41 schema fields against 81 payload keys on the
/// update body, intersecting in 37. **Four are schema-only and three of them
/// the page cannot produce at all**:
///
/// - `deceased.death_notice` — an attachment slot, never a `form_data` key.
/// - `deceased.deceased_uin` (`:183`) — **no control, no state field, no
///   payload key.** A dead surface, kept here because this is the schema table
///   (§ 6.9); building a control for it is forbidden (§ 6.13).
/// - `deceased.found_body` (`:197`) — same.
/// - `informant.informant_ethnicity` (`:209`) — routable to step 5, but Death's
///   informant block emits no ethnicity, so nothing on step 5 can satisfy it.
///   A latent source defect, ported.
///
/// ## There is no step-4 entry, and that is the source's
///
/// `{1: 6, 2: 16, 3: 8, 5: 11}`. **All 14 `parents.father.*` keys are
/// unroutable**, so a 422 naming only father fields does not navigate
/// (`F2-AC-63`). Adding the missing mappings would be the "degrade better than
/// the source" half of L-10.
const Map<String, int> kDeathFieldStep = <String, int>{
  'header.province_id': 1,
  'header.district_id': 1,
  'header.village_id': 1,
  'header.document_no': 1,
  'header.dated': 1,
  'header.legal_basis': 1,
  'deceased.deceased_name': 2,
  'deceased.deceased_uin': 2,
  'deceased.deceased_fingerprint': 2,
  'deceased.deceased_gender': 2,
  'deceased.deceased_dob': 2,
  'deceased.deceased_education': 2,
  'deceased.deceased_ethnicity': 2,
  'deceased.deceased_marital': 2,
  'deceased.deceased_address': 2,
  'deceased.deceased_id_number': 2,
  'deceased.place_of_death': 2,
  'deceased.date_of_death': 2,
  'deceased.time_of_death': 2,
  'deceased.cause_of_death': 2,
  'deceased.death_notice': 2,
  'deceased.found_body': 2,
  'parents.name': 3,
  'parents.fingerprint': 3,
  'parents.dob': 3,
  'parents.ethnicity': 3,
  'parents.marital_status': 3,
  'parents.current_address': 3,
  'parents.id_number': 3,
  'parents.education': 3,
  'informant.informant_name': 5,
  'informant.informant_fingerprint': 5,
  'informant.informant_dob': 5,
  'informant.informant_ethnicity': 5,
  'informant.informant_marital': 5,
  'informant.informant_address': 5,
  'informant.informant_id_number': 5,
  'informant.informant_education': 5,
  'informant.informant_relation': 5,
  'informant.informant_phone': 5,
  'informant.informant_email': 5,
};

/// `:62-91` — `interface DeceasedInfo`, field for field and in source order.
///
/// **`nationality` defaults to `"lao"`** (`:222`) and `podCountry` to `"Laos"`
/// (`:224`).
///
/// `podCountry` reaches the wire as `deceased.place_of_death_country` (`:807`)
/// and **no writer exists**: the place-of-death `LocationFields` handler
/// (`:1210-1216`) enumerates province/district/village and stops, and there is
/// no country control on this page. `oracle_coverage.yaml` registers it as a
/// driver-inert constant, `"Laos"` in all 12 death documents. F0 § 6.5.7
/// **refused** to exempt it — an exempted leaf catches nothing forever while a
/// compared one still catches a pin that moves — so the port must emit the
/// literal from this blank record (`F2-AC-44`).
///
/// **`causeOther` has no length cap and no `path`** (`:1246-1252`), and
/// `deceased.cause_of_death_other` is emitted **unconditionally** (`:811`),
/// empty string when the cause is not `"other"`. Adding a 100-char cap by
/// analogy with Resident's `purposeOther` FAILS `F2-AC-62`.
class DeathDeceasedInfo {
  const DeathDeceasedInfo({
    this.fullName = '',
    this.fingerprint = '',
    this.gender = '',
    this.dob = '',
    this.education = '',
    this.occupation = '',
    this.workplace = '',
    this.ethnicity = '',
    this.nationality = 'lao',
    this.ethnicGroup = '',
    this.religion = '',
    this.maritalStatus = '',
    this.addrHouseNo = '',
    this.addrVillage = '',
    this.addrDistrict = '',
    this.addrProvince = '',
    this.censusOrId = '',
    this.podVillage = '',
    this.podDistrict = '',
    this.podProvince = '',
    this.podCountry = 'Laos',
    this.dateOfDeath = '',
    this.timeOfDeath = '',
    this.cause = '',
    this.causeOther = '',
  });

  final String fullName;
  final String fingerprint;
  final String gender;
  final String dob;
  final String education;
  final String occupation;
  final String workplace;
  final String ethnicity;
  final String nationality;
  final String ethnicGroup;
  final String religion;
  final String maritalStatus;

  // Current address — location UUIDs.
  final String addrHouseNo;
  final String addrVillage;
  final String addrDistrict;
  final String addrProvince;
  final String censusOrId;

  // Place of death — location UUIDs.
  final String podVillage;
  final String podDistrict;
  final String podProvince;
  final String podCountry;

  // Event.
  final String dateOfDeath;
  final String timeOfDeath;
  final String cause;
  final String causeOther;

  DeathDeceasedInfo copyWith({
    String? fullName,
    String? fingerprint,
    String? gender,
    String? dob,
    String? education,
    String? occupation,
    String? workplace,
    String? ethnicity,
    String? nationality,
    String? ethnicGroup,
    String? religion,
    String? maritalStatus,
    String? addrHouseNo,
    String? addrVillage,
    String? addrDistrict,
    String? addrProvince,
    String? censusOrId,
    String? podVillage,
    String? podDistrict,
    String? podProvince,
    String? podCountry,
    String? dateOfDeath,
    String? timeOfDeath,
    String? cause,
    String? causeOther,
  }) =>
      DeathDeceasedInfo(
        fullName: fullName ?? this.fullName,
        fingerprint: fingerprint ?? this.fingerprint,
        gender: gender ?? this.gender,
        dob: dob ?? this.dob,
        education: education ?? this.education,
        occupation: occupation ?? this.occupation,
        workplace: workplace ?? this.workplace,
        ethnicity: ethnicity ?? this.ethnicity,
        nationality: nationality ?? this.nationality,
        ethnicGroup: ethnicGroup ?? this.ethnicGroup,
        religion: religion ?? this.religion,
        maritalStatus: maritalStatus ?? this.maritalStatus,
        addrHouseNo: addrHouseNo ?? this.addrHouseNo,
        addrVillage: addrVillage ?? this.addrVillage,
        addrDistrict: addrDistrict ?? this.addrDistrict,
        addrProvince: addrProvince ?? this.addrProvince,
        censusOrId: censusOrId ?? this.censusOrId,
        podVillage: podVillage ?? this.podVillage,
        podDistrict: podDistrict ?? this.podDistrict,
        podProvince: podProvince ?? this.podProvince,
        podCountry: podCountry ?? this.podCountry,
        dateOfDeath: dateOfDeath ?? this.dateOfDeath,
        timeOfDeath: timeOfDeath ?? this.timeOfDeath,
        cause: cause ?? this.cause,
        causeOther: causeOther ?? this.causeOther,
      );
}

/// `:93-110` — `interface ParentInfo`, **16 fields**, emitting 14 wire keys.
///
/// ## `workplace` is the fifteenth field Birth's record does not have
///
/// It emits `<prefix>.workplace` (`:781`), a fourteenth wire key against
/// Birth's thirteen. A shared record with an optional `workplace` would
/// serialise Birth's parents with a key the web does not send, or would need a
/// flag — and a flag is the first of the three § 6.2 names as the road back to
/// the dynamic renderer `ADR-0003` cancelled.
///
/// ## Only `fullName` is mandatory
///
/// The source's comments mark `dob`, `ethnicity`, `nationality`, `ethnicGroup`,
/// `religion`, `maritalStatus`, `education`, `occupation` and `workplace` all
/// `O`, and `addrVillage`/`addrProvince`/`censusOrId` `C`. Death's
/// `ParentSection` takes **no `required` parameter at all** (`:450-457`), and
/// steps 3/4 are `skip || Boolean(p.fullName.trim())` (`:747-748`) — against
/// Birth's eight-field `parentValid`. `F2-AC-24`.
class DeathParentInfo {
  const DeathParentInfo({
    this.fullName = '',
    this.fingerprint = '',
    this.dob = '',
    this.ethnicity = '',
    this.nationality = 'lao',
    this.ethnicGroup = '',
    this.religion = '',
    this.maritalStatus = '',
    this.addrHouseNo = '',
    this.addrVillage = '',
    this.addrDistrict = '',
    this.addrProvince = '',
    this.censusOrId = '',
    this.education = '',
    this.occupation = '',
    this.workplace = '',
  });

  final String fullName;
  final String fingerprint;
  final String dob;
  final String ethnicity;
  final String nationality;
  final String ethnicGroup;
  final String religion;
  final String maritalStatus;
  final String addrHouseNo;
  final String addrVillage;
  final String addrDistrict;
  final String addrProvince;
  final String censusOrId;
  final String education;
  final String occupation;
  final String workplace;

  DeathParentInfo copyWith({
    String? fullName,
    String? fingerprint,
    String? dob,
    String? ethnicity,
    String? nationality,
    String? ethnicGroup,
    String? religion,
    String? maritalStatus,
    String? addrHouseNo,
    String? addrVillage,
    String? addrDistrict,
    String? addrProvince,
    String? censusOrId,
    String? education,
    String? occupation,
    String? workplace,
  }) =>
      DeathParentInfo(
        fullName: fullName ?? this.fullName,
        fingerprint: fingerprint ?? this.fingerprint,
        dob: dob ?? this.dob,
        ethnicity: ethnicity ?? this.ethnicity,
        nationality: nationality ?? this.nationality,
        ethnicGroup: ethnicGroup ?? this.ethnicGroup,
        religion: religion ?? this.religion,
        maritalStatus: maritalStatus ?? this.maritalStatus,
        addrHouseNo: addrHouseNo ?? this.addrHouseNo,
        addrVillage: addrVillage ?? this.addrVillage,
        addrDistrict: addrDistrict ?? this.addrDistrict,
        addrProvince: addrProvince ?? this.addrProvince,
        censusOrId: censusOrId ?? this.censusOrId,
        education: education ?? this.education,
        occupation: occupation ?? this.occupation,
        workplace: workplace ?? this.workplace,
      );
}

/// `:112-127` — `interface InformantInfo`, **15 fields**, emitting 12 wire keys.
///
/// **No `ethnicity`, no `ethnicGroup`, no `religion`.** Birth's informant has
/// all three and emits 15 keys (`BirthDeclarationPage.tsx:792-806`). The
/// difference is a *field-set* difference, not a value difference, so a shared
/// informant builder cannot be made correct with a flag — it would have to take
/// three (`F2-AC-23`).
///
/// Note the consequence recorded in [kDeathFieldStep]: `FIELD_STEP` routes
/// `informant.informant_ethnicity` to step 5 and nothing on step 5 can produce
/// it. Ported as measured.
class DeathInformantInfo {
  const DeathInformantInfo({
    this.fullName = '',
    this.fingerprint = '',
    this.dob = '',
    this.nationality = 'lao',
    this.maritalStatus = '',
    this.addrHouseNo = '',
    this.addrVillage = '',
    this.addrDistrict = '',
    this.addrProvince = '',
    this.censusOrId = '',
    this.education = '',
    this.relationship = '',
    this.phone = '',
    this.email = '',
  });

  final String fullName;
  final String fingerprint;
  final String dob;
  final String nationality;
  final String maritalStatus;
  final String addrHouseNo;
  final String addrVillage;
  final String addrDistrict;
  final String addrProvince;
  final String censusOrId;
  final String education;
  final String relationship;
  final String phone;
  final String email;

  DeathInformantInfo copyWith({
    String? fullName,
    String? fingerprint,
    String? dob,
    String? nationality,
    String? maritalStatus,
    String? addrHouseNo,
    String? addrVillage,
    String? addrDistrict,
    String? addrProvince,
    String? censusOrId,
    String? education,
    String? relationship,
    String? phone,
    String? email,
  }) =>
      DeathInformantInfo(
        fullName: fullName ?? this.fullName,
        fingerprint: fingerprint ?? this.fingerprint,
        dob: dob ?? this.dob,
        nationality: nationality ?? this.nationality,
        maritalStatus: maritalStatus ?? this.maritalStatus,
        addrHouseNo: addrHouseNo ?? this.addrHouseNo,
        addrVillage: addrVillage ?? this.addrVillage,
        addrDistrict: addrDistrict ?? this.addrDistrict,
        addrProvince: addrProvince ?? this.addrProvince,
        censusOrId: censusOrId ?? this.censusOrId,
        education: education ?? this.education,
        relationship: relationship ?? this.relationship,
        phone: phone ?? this.phone,
        email: email ?? this.email,
      );
}

/// `:702-711` — the header trio plus the records the page holds.
///
/// **Two independent skip flags**, against Birth's one. Either parent can be
/// declared deceased-or-unknown, and `motherSkip` collapses **two** payload
/// prefixes because the mother is emitted under both `parents` and
/// `parents.mother` (`:815-816`).
class DeathFormData {
  const DeathFormData({
    this.province = '',
    this.district = '',
    this.village = '',
    this.deceased = const DeathDeceasedInfo(),
    this.deathNotice,
    this.mother = const DeathParentInfo(),
    this.motherSkip = false,
    this.father = const DeathParentInfo(),
    this.fatherSkip = false,
    this.informant = const DeathInformantInfo(),
  });

  final String province;
  final String district;
  final String village;

  final DeathDeceasedInfo deceased;

  /// `:706` — the page's **one** attachment slot, `deceased.death_notice`.
  final PickedAttachment? deathNotice;

  final DeathParentInfo mother;

  /// `:708` — toggling hides the mother's whole section (`:618`) and collapses
  /// **two** payload prefixes. **The record is not cleared**, so toggling back
  /// restores what was typed (`F2-AC-69`).
  final bool motherSkip;

  final DeathParentInfo father;

  /// `:710` — independent of [motherSkip]. Birth has no analogue: only its
  /// father can be declared unknown.
  final bool fatherSkip;

  final DeathInformantInfo informant;

  DeathFormData copyWith({
    String? province,
    String? district,
    String? village,
    DeathDeceasedInfo? deceased,
    PickedAttachment? deathNotice,
    bool clearDeathNotice = false,
    DeathParentInfo? mother,
    bool? motherSkip,
    DeathParentInfo? father,
    bool? fatherSkip,
    DeathInformantInfo? informant,
  }) =>
      DeathFormData(
        province: province ?? this.province,
        district: district ?? this.district,
        village: village ?? this.village,
        deceased: deceased ?? this.deceased,
        deathNotice:
            clearDeathNotice ? null : (deathNotice ?? this.deathNotice),
        mother: mother ?? this.mother,
        motherSkip: motherSkip ?? this.motherSkip,
        father: father ?? this.father,
        fatherSkip: fatherSkip ?? this.fatherSkip,
        informant: informant ?? this.informant,
      );
}

/// `:734-756` — `canProceed()`, all six arms.
///
/// **Step 2 requires `ethnicGroup` and `religion`** (`:741`) — two client-side
/// over-requirements for keys that are **not in Death's 41-entry schema table
/// at all**. `fsd.md`:375-378 records them and `F2-AC-61` reproduces them. It
/// also carries the cause conditional: `cause !== "other" || causeOther.trim()`.
///
/// **Steps 3 and 4 are `skip || fullName.trim()`.** No `parentValid`, no
/// eight-field check — Birth's model does not exist here (`F2-AC-24`).
bool deathCanProceed(DeathFormData f, int step) {
  switch (step) {
    case 1:
      return f.province.isNotEmpty &&
          f.district.trim().isNotEmpty &&
          f.village.trim().isNotEmpty;
    case 2:
      final DeathDeceasedInfo d = f.deceased;
      return d.fullName.trim().isNotEmpty &&
          d.gender.isNotEmpty &&
          d.dob.trim().isNotEmpty &&
          d.ethnicity.isNotEmpty &&
          d.nationality.isNotEmpty &&
          d.ethnicGroup.isNotEmpty &&
          d.religion.isNotEmpty &&
          d.maritalStatus.isNotEmpty &&
          d.addrVillage.trim().isNotEmpty &&
          d.addrProvince.isNotEmpty &&
          d.censusOrId.trim().isNotEmpty &&
          d.podVillage.trim().isNotEmpty &&
          d.podProvince.isNotEmpty &&
          d.dateOfDeath.trim().isNotEmpty &&
          d.cause.isNotEmpty &&
          f.deathNotice != null &&
          (d.cause != 'other' || d.causeOther.trim().isNotEmpty);
    case 3:
      return f.motherSkip || f.mother.fullName.trim().isNotEmpty;
    case 4:
      return f.fatherSkip || f.father.fullName.trim().isNotEmpty;
    case 5:
      final DeathInformantInfo i = f.informant;
      return i.fullName.trim().isNotEmpty &&
          i.dob.trim().isNotEmpty &&
          i.addrVillage.trim().isNotEmpty &&
          i.addrProvince.isNotEmpty &&
          i.censusOrId.trim().isNotEmpty &&
          i.relationship.trim().isNotEmpty &&
          i.phone.trim().isNotEmpty;
    default:
      return true;
  }
}

/// `BirthDeclarationPage.tsx:51-241` and `:584-592` — the page's own state
/// records, its 422 routing table and its step meta, transcribed.
///
/// ## Nothing here is shared with `presentation/death/`
///
/// `GOR-245-f2-birth-death/specs.md` § 6.2 RULING 1 forbids **any** symbol
/// crossing between `presentation/{resident,birth,death}/`, and
/// `certificate_page_isolation_guard_test.dart` enforces it. The temptation is
/// real and specific: `ParentInfo` below and Death's `ParentInfo` differ by one
/// field (`workplace`), `InformantInfo` by three, and the two `parentData`
/// helpers by a parameter. Every one of those is a place where a shared type
/// would be byte-correct on every fixture that exists today and wrong on the
/// first input that distinguishes them.
///
/// The measured differences are in `architecture-review.md`'s § F2 difference
/// table, derived from the two sources rather than asserted here.
///
/// ## Everything here is pure
///
/// No widget, no locator, no clock of its own — the same discipline
/// `resident_form_state.dart` states, and what lets Tier 0 drive the payload
/// from a literal fixture and compare bytes.
library;

import '../../../application/domain/entities/picked_attachment.dart';

/// `:51` — `const SERVICE_CODE = "birth"`.
///
/// Deliberately **not** read from `CertificateForm.birth.serviceCode`: the
/// page's literal and the plan's key are two independent transcriptions of the
/// same source line, and the double-entry check is worth more than the
/// deduplication (the reasoning `resident_form_state.dart:15-21` gives).
const String kBirthServiceCode = 'birth';

/// `:584-592` — `STEP_META` and `STEP_COUNT`.
///
/// **An array of `{id, titleKey, subtitleKey, shortKey}`.** Death's `STEPS`
/// (`DeathDeclarationPage.tsx:130-137`) is an array of bare `{id}` and resolves
/// its titles by string interpolation at `:667-668`. Two different mechanisms
/// for the same six steps; `F2-AC-58` forbids normalising either onto the
/// other.
class BirthStepMeta {
  const BirthStepMeta({
    required this.id,
    required this.titleKey,
    required this.subtitleKey,
    required this.shortKey,
  });

  final int id;
  final String titleKey;
  final String subtitleKey;
  final String shortKey;
}

const List<BirthStepMeta> kBirthStepMeta = <BirthStepMeta>[
  BirthStepMeta(
    id: 1,
    titleKey: 'step1Title',
    subtitleKey: 'step1Subtitle',
    shortKey: 'stepHeader',
  ),
  BirthStepMeta(
    id: 2,
    titleKey: 'step2Title',
    subtitleKey: 'step2Subtitle',
    shortKey: 'stepChild',
  ),
  BirthStepMeta(
    id: 3,
    titleKey: 'step3Title',
    subtitleKey: 'step3Subtitle',
    shortKey: 'stepMother',
  ),
  BirthStepMeta(
    id: 4,
    titleKey: 'step4Title',
    subtitleKey: 'step4Subtitle',
    shortKey: 'stepFather',
  ),
  BirthStepMeta(
    id: 5,
    titleKey: 'step5Title',
    subtitleKey: 'step5Subtitle',
    shortKey: 'stepInformant',
  ),
  BirthStepMeta(
    id: 6,
    titleKey: 'step6Title',
    subtitleKey: 'step6Subtitle',
    shortKey: 'stepReview',
  ),
];

/// `:592` — `STEP_COUNT = STEP_META.length`.
const int kBirthStepCount = 6;

/// `:134-137` — `GENDERS`.
///
/// **i18n keys into the `birth` namespace**, resolved with `t(o.labelKey)` at
/// `:661`. Death's `GENDERS` (`DeathDeclarationPage.tsx:140-143`) are hard-coded
/// `Bilingual` literals that bypass the namespace entirely. `F2-AC-83` forbids
/// harmonising them.
class BirthGenderOption {
  const BirthGenderOption({required this.value, required this.labelKey});
  final String value;
  final String labelKey;
}

const List<BirthGenderOption> kBirthGenders = <BirthGenderOption>[
  BirthGenderOption(value: 'female', labelKey: 'optFemale'),
  BirthGenderOption(value: 'male', labelKey: 'optMale'),
];

/// `:194-241` — `FIELD_STEP`, **46 entries**.
///
/// ## This is the SCHEMA field table, not the payload key set
///
/// `specs.md` § 2.2 Finding E, measured: 46 schema fields against 80 payload
/// keys on the update body, intersecting in 45. `child.hospital_notice` is the
/// one schema-only entry — an attachment slot that is never a `form_data` key —
/// and 35 payload keys have no row at all.
///
/// ## There is no step-4 entry, and that is the source's
///
/// The steps present are `{1: 6, 2: 17, 3: 12, 5: 11}`. **Every one of the 13
/// `parents.father.*` keys is unroutable**, so a 422 naming only father fields
/// sets `serverErrors`, runs the scroll, and does **not** navigate —
/// `stepOfFirstError` skips unmapped keys and returns null, and the call site is
/// `if (target) setStep(target)` (`:886-887`,
/// `formValidation.tsx:172-183`).
///
/// That is a defect in the web. `specs.md` § 6.9 ports it unchanged: adding the
/// missing mappings would be the "degrade better than the source" half of
/// `ssd.md`:1185 L-10. `F2-AC-63` asserts the absence behaviourally and
/// `F2-AC-60` asserts this table has no step-4 row.
const Map<String, int> kBirthFieldStep = <String, int>{
  'header.province_id': 1,
  'header.district_id': 1,
  'header.village_id': 1,
  'header.document_no': 1,
  'header.dated': 1,
  'header.legal_basis': 1,
  'child.child_name': 2,
  'child.child_gender': 2,
  'child.child_dob': 2,
  'child.child_weight_kg': 2,
  'child.child_height_cm': 2,
  'child.child_fingerprint': 2,
  'child.child_blood_type': 2,
  'child.delivery_mode': 2,
  'child.birth_type': 2,
  'child.birth_order': 2,
  'child.child_ethnicity': 2,
  'child.child_nationality': 2,
  'child.child_religion': 2,
  'child.place_of_birth': 2,
  'child.current_address': 2,
  'child.twin_name': 2,
  'child.hospital_notice': 2,
  'parents.name': 3,
  'parents.fingerprint': 3,
  'parents.dob': 3,
  'parents.ethnicity': 3,
  'parents.nationality': 3,
  'parents.ethnic_group': 3,
  'parents.religion': 3,
  'parents.marital_status': 3,
  'parents.current_address': 3,
  'parents.id_number': 3,
  'parents.education': 3,
  'parents.occupation': 3,
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

/// `:61-89` — `interface ChildInfo`, field for field and in source order.
///
/// The field **names** are the source's, so `birth_payload.dart` reads
/// line-for-line against `:756-807` in review.
///
/// **`nationality` defaults to `"lao"`** (`:170`) and `pobCountry` to `"Laos"`
/// (`:171`). The first is one of the six preset reference values per page that
/// land on `ReferenceSelectView`'s unmatched-value path before
/// `/reference/nationality` resolves — F0c's RULING 14 fix, which F2 exercises
/// and does not re-implement (`specs.md` § 6.12).
///
/// **Four fields never reach the wire**: `pobProvince`, `pobDistrict`,
/// `addrDistrict` and `addrProvince` drive `LocationFields` and gate
/// `canProceed`, but `buildFormData` emits only the village of each pair
/// (`:777`, `:779`). They are kept because they are the source's state, not
/// because anything serialises them.
class BirthChildInfo {
  const BirthChildInfo({
    this.fullName = '',
    this.surname = '',
    this.givenName = '',
    this.gender = '',
    this.dob = '',
    this.timeOfBirth = '',
    this.weight = '',
    this.height = '',
    this.fingerprint = '',
    this.bloodType = '',
    this.deliveryMode = '',
    this.deliveryAssistedBy = '',
    this.birthType = '',
    this.birthOrder = '',
    this.ethnicity = '',
    this.nationality = 'lao',
    this.religion = '',
    this.pobProvince = '',
    this.pobDistrict = '',
    this.pobVillage = '',
    this.pobCountry = 'Laos',
    this.addrHouseNo = '',
    this.addrVillage = '',
    this.addrDistrict = '',
    this.addrProvince = '',
    this.twinName = '',
    this.twinGender = '',
  });

  final String fullName;

  /// Forms v2 — the optional Latin split names, passport/ID style. OPTIONAL:
  /// absent keys when empty (`child.child_surname` / `child.child_given_name`).
  final String surname;
  final String givenName;
  final String gender;
  final String dob;

  /// Forms v2 — optional time of birth, `HH:MM` (`child.child_time_of_birth`).
  /// A free-text input like Death's `timeOfDeath`; no transform is applied.
  final String timeOfBirth;
  final String weight;
  final String height;
  final String fingerprint;
  final String bloodType;
  final String deliveryMode;
  final String deliveryAssistedBy;
  final String birthType;
  final String birthOrder;
  final String ethnicity;
  final String nationality;
  final String religion;

  // Place of birth — location UUIDs.
  final String pobProvince;
  final String pobDistrict;
  final String pobVillage;
  final String pobCountry;

  // Current address — location UUIDs.
  final String addrHouseNo;
  final String addrVillage;
  final String addrDistrict;
  final String addrProvince;

  // Twin (conditional).
  final String twinName;
  final String twinGender;

  BirthChildInfo copyWith({
    String? fullName,
    String? surname,
    String? givenName,
    String? gender,
    String? dob,
    String? timeOfBirth,
    String? weight,
    String? height,
    String? fingerprint,
    String? bloodType,
    String? deliveryMode,
    String? deliveryAssistedBy,
    String? birthType,
    String? birthOrder,
    String? ethnicity,
    String? nationality,
    String? religion,
    String? pobProvince,
    String? pobDistrict,
    String? pobVillage,
    String? pobCountry,
    String? addrHouseNo,
    String? addrVillage,
    String? addrDistrict,
    String? addrProvince,
    String? twinName,
    String? twinGender,
  }) =>
      BirthChildInfo(
        fullName: fullName ?? this.fullName,
        surname: surname ?? this.surname,
        givenName: givenName ?? this.givenName,
        gender: gender ?? this.gender,
        dob: dob ?? this.dob,
        timeOfBirth: timeOfBirth ?? this.timeOfBirth,
        weight: weight ?? this.weight,
        height: height ?? this.height,
        fingerprint: fingerprint ?? this.fingerprint,
        bloodType: bloodType ?? this.bloodType,
        deliveryMode: deliveryMode ?? this.deliveryMode,
        deliveryAssistedBy: deliveryAssistedBy ?? this.deliveryAssistedBy,
        birthType: birthType ?? this.birthType,
        birthOrder: birthOrder ?? this.birthOrder,
        ethnicity: ethnicity ?? this.ethnicity,
        nationality: nationality ?? this.nationality,
        religion: religion ?? this.religion,
        pobProvince: pobProvince ?? this.pobProvince,
        pobDistrict: pobDistrict ?? this.pobDistrict,
        pobVillage: pobVillage ?? this.pobVillage,
        pobCountry: pobCountry ?? this.pobCountry,
        addrHouseNo: addrHouseNo ?? this.addrHouseNo,
        addrVillage: addrVillage ?? this.addrVillage,
        addrDistrict: addrDistrict ?? this.addrDistrict,
        addrProvince: addrProvince ?? this.addrProvince,
        twinName: twinName ?? this.twinName,
        twinGender: twinGender ?? this.twinGender,
      );
}

/// `:91-107` — `interface ParentInfo`, **14 fields**, mother and father alike.
///
/// ## Not Death's `ParentInfo`, and not a base class for it
///
/// Death's carries a fifteenth field, `workplace`
/// (`DeathDeclarationPage.tsx:109`), which its `parentData` emits as a
/// fourteenth wire key. Birth's `parentData` emits 13. A shared record with an
/// optional `workplace` would serialise Birth's parents with a key the web does
/// not send, or would need a flag — which is one of the three flags § 6.2 names
/// as the road back to the dynamic renderer `ADR-0003` cancelled.
///
/// The **requiredness** also differs at the type level, not just by value:
/// Birth's `ParentSection` threads a `required` prop (`:463`) and
/// `parentValid` (`:703-707`) checks **eight** fields; Death's `ParentSection`
/// has no `required` parameter at all and only `fullName` is mandatory
/// (`F2-AC-24`).
class BirthParentInfo {
  const BirthParentInfo({
    this.fullName = '',
    this.surname = '',
    this.givenName = '',
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
  });

  final String fullName;

  /// Forms v2 — the optional Latin split names. Emitted only under the
  /// person's own prefix (`parents.mother.*` / `parents.father.*`), never at
  /// the bare `parents` mirror — the guide names no such key there.
  final String surname;
  final String givenName;
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

  BirthParentInfo copyWith({
    String? fullName,
    String? surname,
    String? givenName,
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
  }) =>
      BirthParentInfo(
        fullName: fullName ?? this.fullName,
        surname: surname ?? this.surname,
        givenName: givenName ?? this.givenName,
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
      );
}

/// `:109-127` — `interface InformantInfo`, **18 fields**, emitting 15 wire keys.
///
/// Death's informant block emits **12** and drops `ethnicity`, `ethnic_group`
/// and `religion` entirely (`DeathDeclarationPage.tsx:819-830`). `F2-AC-23`.
class BirthInformantInfo {
  const BirthInformantInfo({
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
    this.relationship = '',
    this.phone = '',
    this.email = '',
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
  final String relationship;
  final String phone;
  final String email;

  BirthInformantInfo copyWith({
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
    String? relationship,
    String? phone,
    String? email,
  }) =>
      BirthInformantInfo(
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
        relationship: relationship ?? this.relationship,
        phone: phone ?? this.phone,
        email: email ?? this.email,
      );
}

/// `:677-685` — the header trio plus the five records the page holds.
///
/// One object rather than nine `useState` calls, because a Cubit emits one
/// state. The **contents** are the source's, name for name.
class BirthFormData {
  const BirthFormData({
    this.province = '',
    this.district = '',
    this.village = '',
    this.child = const BirthChildInfo(),
    this.hospitalNotice,
    this.mother = const BirthParentInfo(),
    this.father = const BirthParentInfo(),
    this.fatherUnknown = false,
    this.informant = const BirthInformantInfo(),
  });

  /// `:677` — `header`, three location UUIDs.
  final String province;
  final String district;
  final String village;

  final BirthChildInfo child;

  /// `:681` — the page's **one** attachment slot, `child.hospital_notice`.
  final PickedAttachment? hospitalNotice;

  final BirthParentInfo mother;
  final BirthParentInfo father;

  /// `:684` — the sole-parent declaration.
  ///
  /// Toggling it hides `ParentSection` (`:1359`) and switches the payload's
  /// father block to the single key `parents.father.status: "unknown"`
  /// (`:788-790`). **The `father` record is not cleared**, so toggling back
  /// restores what was typed (`F2-AC-69`).
  final bool fatherUnknown;

  final BirthInformantInfo informant;

  BirthFormData copyWith({
    String? province,
    String? district,
    String? village,
    BirthChildInfo? child,
    PickedAttachment? hospitalNotice,
    bool clearHospitalNotice = false,
    BirthParentInfo? mother,
    BirthParentInfo? father,
    bool? fatherUnknown,
    BirthInformantInfo? informant,
  }) =>
      BirthFormData(
        province: province ?? this.province,
        district: district ?? this.district,
        village: village ?? this.village,
        child: child ?? this.child,
        hospitalNotice:
            clearHospitalNotice ? null : (hospitalNotice ?? this.hospitalNotice),
        mother: mother ?? this.mother,
        father: father ?? this.father,
        fatherUnknown: fatherUnknown ?? this.fatherUnknown,
        informant: informant ?? this.informant,
      );
}

/// `:703-707` — `parentValid`, **eight** fields.
///
/// ```ts
/// p.fullName.trim() && p.dob.trim() && p.ethnicity && p.nationality &&
/// p.maritalStatus && p.addrVillage.trim() && p.addrProvince && p.censusOrId.trim()
/// ```
///
/// Death has **no analogue**: its steps 3 and 4 are
/// `skip || Boolean(p.fullName.trim())` (`DeathDeclarationPage.tsx:747-748`).
/// `F2-AC-24`.
bool birthParentValid(BirthParentInfo p) =>
    p.fullName.trim().isNotEmpty &&
    p.dob.trim().isNotEmpty &&
    p.ethnicity.isNotEmpty &&
    p.nationality.isNotEmpty &&
    p.maritalStatus.isNotEmpty &&
    p.addrVillage.trim().isNotEmpty &&
    p.addrProvince.isNotEmpty &&
    p.censusOrId.trim().isNotEmpty;

/// `:710-732` — `canProceed()`, all six arms.
///
/// **Step 2 requires `child.religion`** (`:716`) — a client-side
/// over-requirement `fsd.md`:375-378 records and `F2-AC-61` reproduces. It also
/// carries the twin conditional: `birthType !== "twins" || twinName.trim()`.
///
/// **Step 4 is `fatherUnknown || parentValid(father)`** — the toggle short-
/// circuits the whole eight-field check.
bool birthCanProceed(BirthFormData f, int step) {
  switch (step) {
    case 1:
      return f.province.isNotEmpty &&
          f.district.trim().isNotEmpty &&
          f.village.trim().isNotEmpty;
    case 2:
      final BirthChildInfo c = f.child;
      return c.fullName.trim().isNotEmpty &&
          c.gender.isNotEmpty &&
          c.dob.trim().isNotEmpty &&
          c.birthType.isNotEmpty &&
          c.birthOrder.trim().isNotEmpty &&
          c.ethnicity.isNotEmpty &&
          c.nationality.isNotEmpty &&
          c.religion.isNotEmpty &&
          c.weight.trim().isNotEmpty &&
          c.height.trim().isNotEmpty &&
          c.pobProvince.isNotEmpty &&
          c.pobVillage.trim().isNotEmpty &&
          c.addrProvince.isNotEmpty &&
          c.addrVillage.trim().isNotEmpty &&
          f.hospitalNotice != null &&
          (c.birthType != 'twins' || c.twinName.trim().isNotEmpty);
    case 3:
      return birthParentValid(f.mother);
    case 4:
      return f.fatherUnknown || birthParentValid(f.father);
    case 5:
      final BirthInformantInfo i = f.informant;
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

/// `:1152` — `v.replace(/\D/g, "").slice(0, 2)`.
///
/// The **only** numeric input transform on either F2 page. Weight and height
/// carry `inputMode="numeric"` (`:1257`, `:1266`) and no transform at all, so
/// `"3.2"` reaches the wire intact — which is why this one is a named function
/// rather than a rule applied to every numeric field (`F2-AC-68`).
String birthOrderTransform(String raw) {
  final StringBuffer digits = StringBuffer();
  for (final int unit in raw.codeUnits) {
    if (unit >= 0x30 && unit <= 0x39) digits.writeCharCode(unit);
  }
  final String out = digits.toString();
  return out.length <= 2 ? out : out.substring(0, 2);
}

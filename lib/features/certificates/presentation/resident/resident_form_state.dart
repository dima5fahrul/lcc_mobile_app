/// `ResidentCertificatePage.tsx:52-160` and `:429-451` — the page's own state
/// object, the two pure helpers that read it, and the 422 routing map.
///
/// Everything here is **pure**: no widget, no locator, no clock of its own.
/// That is what lets Tier 0 drive the payload from a literal fixture and
/// compare bytes (`specs.md` § 6.5.5), and it is why `ageFrom` takes a
/// [SubmissionClock] instead of reading `DateTime.now()` the way the source
/// reads `new Date()`.
library;

import '../../../../presentation/payment/payment_draft.dart';
import '../../../application/domain/entities/picked_attachment.dart';
import '../../domain/submission/submission_clock.dart';

/// `ResidentCertificatePage.tsx:98` — `const SERVICE_CODE = "resident"`.
///
/// Deliberately **not** read from `CertificateForm.resident.serviceCode`: the
/// page's literal and the plan's key are two independent transcriptions of the
/// same source line, and `submission_plan_oracle_test.dart`'s double-entry
/// check is worth more than the deduplication.
const String kResidentServiceCode = 'resident';

/// `:101-102` — `STEP_IDS = [1, 2, 3, 4, 5, 6]`, `STEP_COUNT = 6`.
const List<int> kResidentStepIds = <int>[1, 2, 3, 4, 5, 6];
const int kResidentStepCount = 6;

/// `:109-134` — `FIELD_STEP`, which step renders which schema field.
///
/// Read by `stepOfFirstError` (`presentation/forms/validation/`) after a 422,
/// so the wizard lands on the earliest step that owns an offending field.
///
/// **24 entries, and the gaps are the source's.** `applicant.id_front`,
/// `applicant.id_back`, `household_reference.family_book_contents` and
/// `purpose.purpose_other` have no row: a 422 naming only one of those routes
/// nowhere at all, because `stepOfFirstError` **skips** an unknown path rather
/// than treating it as step 0 (`step_of_first_error.dart:26-28`,
/// `formValidation.tsx:179`). `header.ref_no` is here and is mapped to step 2,
/// where the read-only Ref. No. card renders (`:787-797`) — the citizen cannot
/// act on it, and the source maps it anyway.
///
/// This is `fsd.md` D-G's surface. F0 declined to invent these maps for pages
/// it was not writing (`step_of_first_error.dart:9-19`); this one is measured
/// from the page it belongs to, key for key.
const Map<String, int> kResidentFieldStep = <String, int>{
  'household_reference.family_book_upload': 1,
  'applicant.photo': 2,
  'applicant.citizen_name': 2,
  'applicant.age': 2,
  'applicant.occupation': 2,
  'applicant.nationality': 2,
  'header.ref_no': 2,
  'header.province_id': 3,
  'header.district_id': 3,
  'header.village_id': 3,
  'certifying_authority.village_chief_name': 3,
  'certifying_authority.certifying_district': 3,
  'applicant.current_village_id': 4,
  'applicant.house_no': 4,
  'applicant.unit_nuay': 4,
  'applicant.group_khum': 4,
  'household_reference.household_no': 5,
  'household_reference.household_issued_at': 5,
  'household_reference.household_district': 5,
  'parentage.father_name': 5,
  'parentage.mother_name': 5,
  'parentage.native_place': 5,
  'purpose.purpose': 5,
  'purpose.issue_date': 5,
};

/// `:52-95` — `interface FormData`, field for field and in source order.
///
/// The field **names** are the source's (`villageName`, `unitNuayBan`,
/// `currentVillage`), not the wire keys they map to. Keeping them means the
/// transcription in `resident_payload.dart` reads line-for-line against
/// `ResidentCertificatePage.tsx:459-482` in review, which is the property
/// `submission_plan.dart:17-19` says a literal map has and a computed one does
/// not. Renaming `villageName` to `villageId` would be tidier and would break
/// that correspondence.
///
/// **`currentVillage` is free text.** It reaches the wire as
/// `applicant.current_village_id` (`:469`) and the `_id` suffix is a lie: `:904-911`
/// renders it with a plain `InputField`, not `LocationFields`, so it never
/// carries a location UUID. Contrast the header trio at `:856-867`, which are
/// `LocationFields valueMode="id"` and do.
class ResidentFormData {
  const ResidentFormData({
    this.frontId,
    this.backId,
    this.familyBookCover,
    this.familyBookContents,
    this.citizenName = '',
    this.age = '',
    this.occupation = '',
    this.nationality = '',
    this.picture,
    this.province = '',
    this.district = '',
    this.villageName = '',
    this.villageChiefName = '',
    this.certifyingJurisdiction = '',
    this.currentVillage = '',
    this.groupKhum = '',
    this.unitNuayBan = '',
    this.houseNo = '',
    this.censusBookNo = '',
    this.censusBookDate = '',
    this.censusDistrictProvince = '',
    this.fatherName = '',
    this.motherName = '',
    this.nativePlace = '',
    this.purpose = '',
    this.purposeOther = '',
    this.payment = kBlankPayment,
  });

  // Supporting documents (§5.1) — captured first.
  final PickedAttachment? frontId;
  final PickedAttachment? backId;
  final PickedAttachment? familyBookCover;
  final PickedAttachment? familyBookContents;

  // Applicant identity.
  final String citizenName;
  final String age;
  final String occupation;
  final String nationality;
  final PickedAttachment? picture;

  // Header / jurisdiction block — location UUIDs from the location service.
  final String province;
  final String district;
  final String villageName;
  final String villageChiefName;
  final String certifyingJurisdiction;

  // Current residence — free text, despite the wire key's `_id` suffix.
  final String currentVillage;
  final String groupKhum;
  final String unitNuayBan;
  final String houseNo;

  // Household reference (from the family book).
  final String censusBookNo;
  final String censusBookDate;
  final String censusDistrictProvince;

  // Parentage.
  final String fatherName;
  final String motherName;

  // Native place + purpose.
  final String nativePlace;
  final String purpose;
  final String purposeOther;

  // Payment.
  final PaymentDraft payment;

  /// `:378-379`'s `set(key, value)` and `:398`/`:403`/`:418`'s `setForm`
  /// spreads, as one call.
  ///
  /// The four attachment slots and nothing else take an explicit
  /// `clear…` flag: `copyWith(frontId: null)` cannot distinguish "leave it
  /// alone" from "the citizen removed the file", and `:418-424` needs the
  /// second — it is the whole `else` branch of `handleFrontId`.
  ResidentFormData copyWith({
    PickedAttachment? frontId,
    bool clearFrontId = false,
    PickedAttachment? backId,
    bool clearBackId = false,
    PickedAttachment? familyBookCover,
    bool clearFamilyBookCover = false,
    PickedAttachment? familyBookContents,
    bool clearFamilyBookContents = false,
    String? citizenName,
    String? age,
    String? occupation,
    String? nationality,
    PickedAttachment? picture,
    bool clearPicture = false,
    String? province,
    String? district,
    String? villageName,
    String? villageChiefName,
    String? certifyingJurisdiction,
    String? currentVillage,
    String? groupKhum,
    String? unitNuayBan,
    String? houseNo,
    String? censusBookNo,
    String? censusBookDate,
    String? censusDistrictProvince,
    String? fatherName,
    String? motherName,
    String? nativePlace,
    String? purpose,
    String? purposeOther,
    PaymentDraft? payment,
  }) =>
      ResidentFormData(
        frontId: clearFrontId ? null : (frontId ?? this.frontId),
        backId: clearBackId ? null : (backId ?? this.backId),
        familyBookCover:
            clearFamilyBookCover ? null : (familyBookCover ?? this.familyBookCover),
        familyBookContents: clearFamilyBookContents
            ? null
            : (familyBookContents ?? this.familyBookContents),
        citizenName: citizenName ?? this.citizenName,
        age: age ?? this.age,
        occupation: occupation ?? this.occupation,
        nationality: nationality ?? this.nationality,
        picture: clearPicture ? null : (picture ?? this.picture),
        province: province ?? this.province,
        district: district ?? this.district,
        villageName: villageName ?? this.villageName,
        villageChiefName: villageChiefName ?? this.villageChiefName,
        certifyingJurisdiction:
            certifyingJurisdiction ?? this.certifyingJurisdiction,
        currentVillage: currentVillage ?? this.currentVillage,
        groupKhum: groupKhum ?? this.groupKhum,
        unitNuayBan: unitNuayBan ?? this.unitNuayBan,
        houseNo: houseNo ?? this.houseNo,
        censusBookNo: censusBookNo ?? this.censusBookNo,
        censusBookDate: censusBookDate ?? this.censusBookDate,
        censusDistrictProvince:
            censusDistrictProvince ?? this.censusDistrictProvince,
        fatherName: fatherName ?? this.fatherName,
        motherName: motherName ?? this.motherName,
        nativePlace: nativePlace ?? this.nativePlace,
        purpose: purpose ?? this.purpose,
        purposeOther: purposeOther ?? this.purposeOther,
        payment: payment ?? this.payment,
      );
}

/// `:151-160` — `function ageFrom(dateOfBirth)`, whole years to today.
///
/// ```ts
/// if (!dateOfBirth) return "";
/// const born = new Date(dateOfBirth);
/// if (Number.isNaN(born.getTime())) return "";
/// const now = new Date();
/// let years = now.getFullYear() - born.getFullYear();
/// const monthDelta = now.getMonth() - born.getMonth();
/// if (monthDelta < 0 || (monthDelta === 0 && now.getDate() < born.getDate())) years--;
/// return years >= 0 && years < 150 ? String(years) : "";
/// ```
///
/// ## This is a Tier 0 value, not a display string
///
/// Its result lands in `form.age` (`:406`) and `form.age` is POSTed as
/// `applicant.age` (`:466`). So it reads the **injected** clock: the source's
/// bare `new Date()` at `:155` is a second wall-clock read that would make the
/// payload undrivable, which is the property `submission_clock.dart:28-37`
/// exists to protect. ADR-0005's fixed-clock rule reaches here for the same
/// reason it reaches `today()`.
///
/// ## Two things a tidier port gets wrong
///
/// 1. **The upper bound is exclusive and the lower is inclusive.** `>= 0` and
///    `< 150`. An age of exactly 150 yields `""`, not `"150"`.
/// 2. **A future date of birth yields `""`, not a negative number** — the
///    `years >= 0` half. Both halves are one expression in the source and both
///    are silent: the field simply stays blank and the citizen types over it.
///
/// ## Timezone
///
/// `new Date("2019-04-02")` parses as UTC midnight and `getFullYear()` reads it
/// back in **local** time; at UTC+7 that lands on the same calendar day, so the
/// year/month/day triple is unchanged. `DateTime.parse('2019-04-02')` yields a
/// local `DateTime` with the same triple directly. Equal for Laos, and it is
/// the reading ADR-0005 mandates — `toUtc()` is forbidden anywhere in `lib/**`.
String ageFrom(String? dateOfBirth, SubmissionClock clock) {
  if (dateOfBirth == null || dateOfBirth.isEmpty) return '';
  final DateTime? born = DateTime.tryParse(dateOfBirth);
  if (born == null) return '';

  final DateTime now = clock.now();
  int years = now.year - born.year;
  final int monthDelta = now.month - born.month;
  if (monthDelta < 0 || (monthDelta == 0 && now.day < born.day)) years--;

  return years >= 0 && years < 150 ? '$years' : '';
}

/// `:429-451` — `canProceed()`. **Only Mandatory fields block progression.**
///
/// The Continue button is never disabled (`:1037-1044`); tapping it on an
/// incomplete step flips `showErrors` and stays put (`:555-559`). So this
/// predicate is the whole gate, and every asymmetry in it is observable.
///
/// Four of them, all reproduced:
///
/// 1. **Step 1 depends on `detecting`.** `&& !detecting` (`:432`) — while the
///    `/me/digital-id` read is in flight the citizen cannot advance, even with
///    all four files chosen. That is the only step whose validity depends on
///    something other than [form].
/// 2. **`nationality` and `purpose` are truthiness-checked, not trimmed**
///    (`:434`, `:446`), while every neighbouring text field is trimmed. They
///    come from a `ReferenceSelectView`, so they are either a code or empty and
///    the distinction is unreachable — reproduced anyway.
/// 3. **`villageChiefName` is not checked at step 3** even though `:877-883`
///    renders it and `FIELD_STEP` maps it. It is the one
///    `certifying_authority.*` field the wizard lets you leave blank; the API
///    may still 422 on it, which is exactly the case the server-error path
///    handles.
/// 4. **Step 5's `purposeOther` is conditional on `purpose == "other"`**
///    (`:447`) — and that field is the one `InputField` on the page with **no
///    `path`** (`:1009-1016`), so a 422 about it can never land on it.
bool residentCanProceed(
  ResidentFormData form, {
  required int step,
  required bool detecting,
}) {
  if (step == 1) {
    return form.frontId != null &&
        form.backId != null &&
        form.familyBookCover != null &&
        form.familyBookContents != null &&
        !detecting;
  }
  if (step == 2) {
    return form.citizenName.trim().isNotEmpty &&
        form.age.trim().isNotEmpty &&
        form.nationality.isNotEmpty &&
        form.picture != null;
  }
  if (step == 3) {
    return form.province.trim().isNotEmpty &&
        form.district.trim().isNotEmpty &&
        form.villageName.trim().isNotEmpty &&
        form.certifyingJurisdiction.trim().isNotEmpty;
  }
  if (step == 4) {
    return form.currentVillage.trim().isNotEmpty &&
        form.houseNo.trim().isNotEmpty;
  }
  if (step == 5) {
    return form.censusBookNo.trim().isNotEmpty &&
        form.purpose.isNotEmpty &&
        (form.purpose != 'other' || form.purposeOther.trim().isNotEmpty);
  }
  if (step == 6) return isPaymentValid(form.payment);
  return true;
}

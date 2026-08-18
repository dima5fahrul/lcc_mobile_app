/// `MarriageCertificatePage.tsx`'s own state object, its constants, and the two
/// pure predicates that read it.
///
/// Everything here is **pure** — no widget, no locator, no clock of its own —
/// which is what lets Tier 0 drive the payload from a literal fixture and
/// compare bytes.
///
/// Field **names** are the source's (`fullName`, `idOrPassport`,
/// `residenceCertRef`), not the wire keys they map to, so
/// `marriage_payload.dart` reads line-for-line against `:894-936` in review.
library;

import '../../../../presentation/payment/payment_draft.dart';
import '../../../application/domain/entities/picked_attachment.dart';
import '../../../reference/domain/entities/prerequisite_record.dart';
import '../certificate_forms/certificate_location_value.dart';

/// `:958` — `service_code: "marriage"`.
///
/// Deliberately **not** read from `CertificateForm.marriage.serviceCode`: the
/// page's literal and the plan's key are two independent transcriptions of the
/// same source line, and the double-entry check is worth more than the
/// deduplication (the reason `resident_form_state.dart:15-20` gives).
const String kMarriageServiceCode = 'marriage';

/// `:123-131` — seven steps.
const List<int> kMarriageStepIds = <int>[1, 2, 3, 4, 5, 6, 7];
const int kMarriageStepCount = 7;

/// `:102` — `const OFFICE_DEFERRED = "captured-at-office"`.
///
/// **Three sites on this page** (`:922` `medical_certificate`, `:933`
/// `couple_signatures`, `:934` `registrar_signature`) and two on Divorce: five
/// in total, all emitted **unconditionally**, so a fixture that never visits
/// those steps still expects them present. `F3-AC-69`, `F3-AC-97`.
///
/// **R-20 is NOT EVALUATED and this constant does not discharge it.** Whether
/// the server still accepts this literal for the five `mandatory` fields needs
/// an authenticated write `ADR-0001` forbids (`F3-NV-1`, `F3-AC-96`). Emitting
/// it is a different and weaker claim.
const String kOfficeDeferred = 'captured-at-office';

/// `:140-144` — `METHOD_CODE`, a hardcoded `const` map.
///
/// `MethodCodeSource.staticMap`. Resident/Birth/Death resolve theirs from
/// `/payment-methods`; **this page never issues that request**, and making it
/// would be an observable network divergence (`F3-AC-65`, `F3-AC-66`).
///
/// `cc` collapses to `bank-transfer` — the gateway offers no card rail
/// (`:139`). `fsd.md` D-O escalates that; it is reproduced, not repaired.
const Map<DraftPaymentMethod, String> kMarriageMethodCode =
    <DraftPaymentMethod, String>{
  DraftPaymentMethod.qr: 'laoqr',
  DraftPaymentMethod.bank: 'bank-transfer',
  DraftPaymentMethod.cc: 'bank-transfer',
};

/// `:134-137` — `GENDERS`.
///
/// ```ts
/// [{ value: "female", label: "Female" }, { value: "male", label: "Male" }]
/// ```
///
/// **Bare English strings with no Lao label at all.** Under `lo` the dropdown
/// reads "Female" / "Male". That is a source defect (`gender_values.dart`
/// records it and refuses to unify the labels); giving Marriage a Lao
/// rendering the web does not have is `L-10`(b) and a Tier 1 failure.
/// `F3-AC-67`.
///
/// The **values and their order** are `kGenderWireValues`; only the labels are
/// this page's.
const List<String> kMarriageGenderLabels = <String>['Female', 'Male'];

/// `:106-118` — the page-local `COPY` table.
///
/// > *"Short bilingual sentences for the data states. The i18n namespaces are
/// > owned elsewhere, so these live here rather than as new dictionary keys."*
///
/// **Not promoted into an i18n namespace** (`F3-AC-95`): the source keeps them
/// out deliberately, and moving them changes what `F3-AC-94`'s byte-diff
/// measures. `say(key)` is `COPY[key][lang] ?? COPY[key].en` (`:709`).
const Map<String, Map<String, String>> kMarriageCopy =
    <String, Map<String, String>>{
  'retry': <String, String>{'en': 'Try again', 'lo': 'ລອງໃໝ່'},
  'searchRecord': <String, String>{
    'en': 'Search by record number or name…',
    'lo': 'ຄົ້ນຫາດ້ວຍເລກບົດບັນທຶກ ຫຼື ຊື່...',
  },
  'recordsLoading': <String, String>{
    'en': 'Looking for your betrothal records…',
    'lo': 'ກຳລັງຊອກຫາບົດບັນທຶກການໝັ້ນໝາຍ...',
  },
  'recordsError': <String, String>{
    'en': 'We could not load the betrothal records.',
    'lo': 'ບໍ່ສາມາດໂຫຼດບົດບັນທຶກການໝັ້ນໝາຍໄດ້.',
  },
  'recordsEmpty': <String, String>{
    'en': 'No betrothal record is linked to you yet. Create one first, or ask '
        'your village office to record it.',
    'lo': 'ຍັງບໍ່ມີບົດບັນທຶກການໝັ້ນໝາຍຜູກກັບທ່ານ. ກະລຸນາສ້າງໃໝ່ ຫຼື ຕິດຕໍ່ຫ້ອງການບ້ານ.',
  },
  'recordOpenError': <String, String>{
    'en': 'We could not open that record.',
    'lo': 'ບໍ່ສາມາດເປີດບົດບັນທຶກນັ້ນໄດ້.',
  },
  'quoteError': <String, String>{
    'en': 'The fee could not be calculated.',
    'lo': 'ບໍ່ສາມາດຄິດໄລ່ຄ່າທຳນຽມໄດ້.',
  },
  'fixTitle': <String, String>{
    'en': 'Please fix the following before submitting',
    'lo': 'ກະລຸນາແກ້ໄຂລາຍການລຸ່ມນີ້ກ່ອນສົ່ງ',
  },
};

/// `:717` — `useState<"" | "existing" | "new">`.
///
/// The empty inhabitant is the chooser state, and `canProceed()` returns
/// `false` for it (`:857`) — the citizen must pick one.
enum MarriageBetrothalMode { none, existing, newRecord }

/// `:82-98` — `interface SpouseInfo`, field for field and in source order.
class MarriageSpouseInfo {
  const MarriageSpouseInfo({
    this.fullName = '',
    this.dob = '',
    this.gender = '',
    this.nationality = '',
    this.ethnicity = '',
    this.ethnicGroup = '',
    this.religion = '',
    this.occupation = '',
    this.idOrPassport = '',
    this.addrHouseNo = '',
    this.address = CertificateLocationValue.blank,
    this.residenceCertRef = '',
    this.singleStatusCert,
    this.priorMaritalProof,
    this.foreignDocs,
  });

  final String fullName;
  final String dob;
  final String gender;

  /// Drives the foreign-spouse path — see [marriageIsForeign].
  final String nationality;

  final String ethnicity;
  final String ethnicGroup;
  final String religion;
  final String occupation;
  final String idOrPassport;
  final String addrHouseNo;
  final CertificateLocationValue address;
  final String residenceCertRef;

  final PickedAttachment? singleStatusCert;
  final PickedAttachment? priorMaritalProof;
  final PickedAttachment? foreignDocs;

  /// `blankSpouse` — `:147-152`.
  static const MarriageSpouseInfo blank = MarriageSpouseInfo();

  MarriageSpouseInfo copyWith({
    String? fullName,
    String? dob,
    String? gender,
    String? nationality,
    String? ethnicity,
    String? ethnicGroup,
    String? religion,
    String? occupation,
    String? idOrPassport,
    String? addrHouseNo,
    CertificateLocationValue? address,
    String? residenceCertRef,
    PickedAttachment? singleStatusCert,
    bool clearSingleStatusCert = false,
    PickedAttachment? priorMaritalProof,
    bool clearPriorMaritalProof = false,
    PickedAttachment? foreignDocs,
    bool clearForeignDocs = false,
  }) =>
      MarriageSpouseInfo(
        fullName: fullName ?? this.fullName,
        dob: dob ?? this.dob,
        gender: gender ?? this.gender,
        nationality: nationality ?? this.nationality,
        ethnicity: ethnicity ?? this.ethnicity,
        ethnicGroup: ethnicGroup ?? this.ethnicGroup,
        religion: religion ?? this.religion,
        occupation: occupation ?? this.occupation,
        idOrPassport: idOrPassport ?? this.idOrPassport,
        addrHouseNo: addrHouseNo ?? this.addrHouseNo,
        address: address ?? this.address,
        residenceCertRef: residenceCertRef ?? this.residenceCertRef,
        singleStatusCert: clearSingleStatusCert
            ? null
            : (singleStatusCert ?? this.singleStatusCert),
        priorMaritalProof: clearPriorMaritalProof
            ? null
            : (priorMaritalProof ?? this.priorMaritalProof),
        foreignDocs:
            clearForeignDocs ? null : (foreignDocs ?? this.foreignDocs),
      );
}

/// `:720-723` — the betrothal capture block.
class MarriageBetrothal {
  const MarriageBetrothal({
    this.householdHead = '',
    this.bridePriceCash = '',
    this.bridePriceGold = '',
    this.housing = '',
    this.w1Name = '',
    this.w2Name = '',
  });

  final String householdHead;

  /// Digits only — `v.replace(/\D/g, "")` at the call site (`:1334`), not in
  /// the field.
  final String bridePriceCash;

  final String bridePriceGold;
  final String housing;
  final String w1Name;
  final String w2Name;

  static const MarriageBetrothal blank = MarriageBetrothal();

  MarriageBetrothal copyWith({
    String? householdHead,
    String? bridePriceCash,
    String? bridePriceGold,
    String? housing,
    String? w1Name,
    String? w2Name,
  }) =>
      MarriageBetrothal(
        householdHead: householdHead ?? this.householdHead,
        bridePriceCash: bridePriceCash ?? this.bridePriceCash,
        bridePriceGold: bridePriceGold ?? this.bridePriceGold,
        housing: housing ?? this.housing,
        w1Name: w1Name ?? this.w1Name,
        w2Name: w2Name ?? this.w2Name,
      );
}

/// `:737-740` — the registration block.
class MarriageRegistration {
  const MarriageRegistration({
    this.dateOfMarriage = '',
    this.placeOfRegistration = '',
    this.w1Name = '',
    this.w1Id = '',
    this.w2Name = '',
    this.w2Id = '',
    this.w3Name = '',
    this.w3Id = '',
  });

  /// `event_date: reg.dateOfMarriage || undefined` (`:962`) — **elided when
  /// blank, never `today()`**. Birth and Death fall back; this page does not
  /// (`F3-AC-41`).
  final String dateOfMarriage;

  final String placeOfRegistration;
  final String w1Name;
  final String w1Id;
  final String w2Name;
  final String w2Id;
  final String w3Name;
  final String w3Id;

  static const MarriageRegistration blank = MarriageRegistration();

  MarriageRegistration copyWith({
    String? dateOfMarriage,
    String? placeOfRegistration,
    String? w1Name,
    String? w1Id,
    String? w2Name,
    String? w2Id,
    String? w3Name,
    String? w3Id,
  }) =>
      MarriageRegistration(
        dateOfMarriage: dateOfMarriage ?? this.dateOfMarriage,
        placeOfRegistration: placeOfRegistration ?? this.placeOfRegistration,
        w1Name: w1Name ?? this.w1Name,
        w1Id: w1Id ?? this.w1Id,
        w2Name: w2Name ?? this.w2Name,
        w2Id: w2Id ?? this.w2Id,
        w3Name: w3Name ?? this.w3Name,
        w3Id: w3Id ?? this.w3Id,
      );
}

/// Every `useState` on the page that reaches the wire, in one value.
class MarriageFormData {
  const MarriageFormData({
    this.betrothalMode = MarriageBetrothalMode.none,
    this.linkedRecord,
    this.betrothal = MarriageBetrothal.blank,
    this.header = CertificateLocationValue.blank,
    this.spouseA = MarriageSpouseInfo.blank,
    this.spouseB = MarriageSpouseInfo.blank,
    this.prevMarriedA = false,
    this.prevMarriedB = false,
    this.householdBook,
    this.photos,
    this.hasChildren = false,
    this.birthRecord,
    this.reg = MarriageRegistration.blank,
    this.payment = kBlankPayment,
  });

  final MarriageBetrothalMode betrothalMode;

  /// `:719`. Null on every account available to this programme —
  /// `/prerequisite-records` answers `data: []`
  /// (`manifest-authenticated.md`:230-232), which is why
  /// `linked_reference_no` is elided on all twelve Tier 0 documents and
  /// `creates_betrothal_record`'s `false` inhabitant is Entry-B-only
  /// (`F3-AC-64`).
  final PrerequisiteRecord? linkedRecord;

  final MarriageBetrothal betrothal;
  final CertificateLocationValue header;
  final MarriageSpouseInfo spouseA;
  final MarriageSpouseInfo spouseB;
  final bool prevMarriedA;
  final bool prevMarriedB;

  final PickedAttachment? householdBook;
  final PickedAttachment? photos;
  final bool hasChildren;
  final PickedAttachment? birthRecord;

  final MarriageRegistration reg;
  final PaymentDraft payment;

  MarriageFormData copyWith({
    MarriageBetrothalMode? betrothalMode,
    PrerequisiteRecord? linkedRecord,
    bool clearLinkedRecord = false,
    MarriageBetrothal? betrothal,
    CertificateLocationValue? header,
    MarriageSpouseInfo? spouseA,
    MarriageSpouseInfo? spouseB,
    bool? prevMarriedA,
    bool? prevMarriedB,
    PickedAttachment? householdBook,
    bool clearHouseholdBook = false,
    PickedAttachment? photos,
    bool clearPhotos = false,
    bool? hasChildren,
    PickedAttachment? birthRecord,
    bool clearBirthRecord = false,
    MarriageRegistration? reg,
    PaymentDraft? payment,
  }) =>
      MarriageFormData(
        betrothalMode: betrothalMode ?? this.betrothalMode,
        linkedRecord:
            clearLinkedRecord ? null : (linkedRecord ?? this.linkedRecord),
        betrothal: betrothal ?? this.betrothal,
        header: header ?? this.header,
        spouseA: spouseA ?? this.spouseA,
        spouseB: spouseB ?? this.spouseB,
        prevMarriedA: prevMarriedA ?? this.prevMarriedA,
        prevMarriedB: prevMarriedB ?? this.prevMarriedB,
        householdBook:
            clearHouseholdBook ? null : (householdBook ?? this.householdBook),
        photos: clearPhotos ? null : (photos ?? this.photos),
        hasChildren: hasChildren ?? this.hasChildren,
        birthRecord:
            clearBirthRecord ? null : (birthRecord ?? this.birthRecord),
        reg: reg ?? this.reg,
        payment: payment ?? this.payment,
      );
}

/// `:473` / `:761-763` — `Boolean(nationality) && nationality !== "lao"`.
///
/// **Non-empty AND not `"lao"`.** A *stateless* spouse — nationality set to a
/// code that is neither `lao` nor blank — is therefore treated as foreign:
/// billed the foreign rate and required to supply foreign documents.
/// `fsd.md` § 10 Q-4 raises that as a legal/product question. REPRODUCE; do not
/// "fix" the test (`F3-AC-75`).
bool marriageIsForeign(String nationality) =>
    nationality.isNotEmpty && nationality != 'lao';

/// `:761-763` — either spouse foreign. The source's `anyForeign`.
///
/// **It has no runtime consumer, and that is a recorded consequence rather
/// than an oversight.** On the web this is the first of the two inputs to
/// `catalog.quote("marriage", …)`; under `blocked.md` § 1 option (b) the fee is
/// read off the service catalogue and [MarriageQuotePort] takes no inputs, so
/// nothing in `lib/` calls this. It is kept because it is the pinned
/// transcription of `:761-763` — including the stateless-spouse rule
/// [marriageIsForeign] carries, which `fsd.md` § 10 Q-4 escalates as an open
/// legal/product question (`F3-AC-75`) — and `marriage_payload_test.dart`
/// asserts its semantics. Deleting it would delete the record of that question,
/// not just an unused function. It is also what a real `/services/marriage/
/// quote` slice would call on day one.
bool marriageAnyForeign(MarriageFormData form) =>
    marriageIsForeign(form.spouseA.nationality) ||
    marriageIsForeign(form.spouseB.nationality);

/// `:764` — `betrothalMode === "new"`.
///
/// The source's *other* conditional-quote input; here it survives only as the
/// value of `betrothal.creates_betrothal_record` (`:904`), which is a wire
/// field and unaffected by option (b). It no longer moves the fee — see
/// `MarriageFormCubit.setBetrothalMode`.
bool marriageIncludeBetrothalFee(MarriageFormData form) =>
    form.betrothalMode == MarriageBetrothalMode.newRecord;

/// `:839-848` — `spouseValid(s, prevMarried)`.
///
/// Ten conditions. Two asymmetries worth naming because a tidier port loses
/// them:
///
/// - `gender` and `nationality` are **truthiness-checked, not trimmed**, while
///   every neighbouring text field is trimmed. Both come from a select, so the
///   distinction is unreachable — reproduced anyway.
/// - `address.villageId` **and** `address.provinceId` are both required, but
///   `address.districtId` is **not**. The district is unreachable-blank in
///   practice (the village select is disabled without one), so this is a hole
///   with no inhabitant rather than a bug — and it is the source's hole.
///
/// Every mirrored key being separately mandatory here is *why* `both()`'s
/// collapse branch is structurally unreachable (`F3-NV-5`).
bool marriageSpouseValid(MarriageSpouseInfo s, bool prevMarried) {
  final bool foreign = marriageIsForeign(s.nationality);
  return s.fullName.trim().isNotEmpty &&
      s.dob.trim().isNotEmpty &&
      s.gender.isNotEmpty &&
      s.nationality.isNotEmpty &&
      s.idOrPassport.trim().isNotEmpty &&
      s.address.villageId.isNotEmpty &&
      s.address.provinceId.isNotEmpty &&
      s.residenceCertRef.trim().isNotEmpty &&
      s.singleStatusCert != null &&
      (!prevMarried || s.priorMaritalProof != null) &&
      (!foreign || s.foreignDocs != null);
}

/// `:851-871` — `canProceed()`.
///
/// **Step 6 is absent from the switch and falls through to `return true`**
/// (`:870`): the review step always advances. So does any step the source does
/// not name. Reproduced as written rather than made exhaustive.
bool marriageCanProceed(MarriageFormData form, {required int step}) {
  if (step == 1) {
    final bool headerOk = form.header.provinceId.isNotEmpty &&
        form.header.districtId.isNotEmpty &&
        form.header.villageId.isNotEmpty;
    switch (form.betrothalMode) {
      case MarriageBetrothalMode.existing:
        return form.linkedRecord != null && headerOk;
      case MarriageBetrothalMode.newRecord:
        return headerOk &&
            form.betrothal.householdHead.trim().isNotEmpty &&
            form.betrothal.bridePriceCash.trim().isNotEmpty;
      case MarriageBetrothalMode.none:
        // `:857` — must pick existing or create new.
        return false;
    }
  }
  if (step == 2) return marriageSpouseValid(form.spouseA, form.prevMarriedA);
  if (step == 3) return marriageSpouseValid(form.spouseB, form.prevMarriedB);
  if (step == 4) {
    return form.householdBook != null &&
        form.photos != null &&
        (!form.hasChildren || form.birthRecord != null);
  }
  if (step == 5) {
    final MarriageRegistration r = form.reg;
    return r.dateOfMarriage.trim().isNotEmpty &&
        r.placeOfRegistration.trim().isNotEmpty &&
        r.w1Name.trim().isNotEmpty &&
        r.w1Id.trim().isNotEmpty &&
        r.w2Name.trim().isNotEmpty &&
        r.w2Id.trim().isNotEmpty &&
        r.w3Name.trim().isNotEmpty &&
        r.w3Id.trim().isNotEmpty;
  }
  if (step == 7) return isPaymentValid(form.payment);
  return true;
}

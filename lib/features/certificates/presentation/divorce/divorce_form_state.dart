/// `DivorceCertificatePage.tsx`'s own state object, its constants, and the
/// pure predicates that read it.
///
/// Pure throughout — no widget, no locator, no clock.
///
/// **This page is Marriage's structural sibling and its state is NOT a subset.**
/// Its spouse carries seven fields to Marriage's fifteen, it has no `gender` at
/// all, and step 1 is a two-armed machine with a terminal third state. The
/// shapes are deliberately transcribed independently; § 6.5 forbids a shared
/// spouse helper and § 6.13 orders Marriage first so the smaller mirror cannot
/// be generalised upward.
library;

import '../../../../presentation/payment/payment_draft.dart';
import '../../../application/domain/entities/picked_attachment.dart';
import '../../../reference/domain/entities/prerequisite_record.dart';
import '../certificate_forms/certificate_location_value.dart';
import '../marriage/marriage_form_state.dart' show kOfficeDeferred;

/// `:854` — `service_code: "divorce"`.
const String kDivorceServiceCode = 'divorce';

/// `:116-117` — six steps.
const List<int> kDivorceStepIds = <int>[1, 2, 3, 4, 5, 6];
const int kDivorceStepCount = 6;

/// The two `divorce_type` literals `:745-746` compares against.
///
/// **These are string comparisons against a server-supplied list, not an
/// enum.** `divorceTypes` comes from `/reference-lists/divorce-type`, and any
/// code that is neither of these leaves both booleans false — see
/// [divorceIsTerminalType].
const String kDivorceTypeVoluntary = 'voluntary';
const String kDivorceTypeContested = 'contested';

/// `:125-129` — `METHOD_CODE`, byte-identical to Marriage's.
///
/// Two pages, two declarations, and they stay two: a shared constant would be
/// a shared symbol between two page directories that § 6.5's reasoning keeps
/// apart, and the map is three lines.
const Map<DraftPaymentMethod, String> kDivorceMethodCode =
    <DraftPaymentMethod, String>{
  DraftPaymentMethod.qr: 'laoqr',
  DraftPaymentMethod.bank: 'bank-transfer',
  DraftPaymentMethod.cc: 'bank-transfer',
};

/// `:99-111` — the page-local `COPY` table. Six of the eight sentences differ
/// from Marriage's (betrothal → mediation); `retry`, `searchRecord`,
/// `recordOpenError`, `quoteError` and `fixTitle` are identical strings in two
/// separate tables. Not promoted into i18n (`F3-AC-95`).
const Map<String, Map<String, String>> kDivorceCopy =
    <String, Map<String, String>>{
  'retry': <String, String>{'en': 'Try again', 'lo': 'ລອງໃໝ່'},
  'searchRecord': <String, String>{
    'en': 'Search by record number or name…',
    'lo': 'ຄົ້ນຫາດ້ວຍເລກບົດບັນທຶກ ຫຼື ຊື່...',
  },
  'recordsLoading': <String, String>{
    'en': 'Looking for your mediation records…',
    'lo': 'ກຳລັງຊອກຫາບົດບັນທຶກໄກ່ເກ່ຍ...',
  },
  'recordsError': <String, String>{
    'en': 'We could not load the mediation records.',
    'lo': 'ບໍ່ສາມາດໂຫຼດບົດບັນທຶກໄກ່ເກ່ຍໄດ້.',
  },
  'recordsEmpty': <String, String>{
    'en': 'No mediation record is linked to you yet. Create one first, or ask '
        'your village office to record it.',
    'lo': 'ຍັງບໍ່ມີບົດບັນທຶກໄກ່ເກ່ຍຜູກກັບທ່ານ. ກະລຸນາສ້າງໃໝ່ ຫຼື ຕິດຕໍ່ຫ້ອງການບ້ານ.',
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

/// `:631` — the voluntary arm's record chooser.
enum DivorceMediationMode { none, existing, newRecord }

/// `:84-91` — `interface SpouseInfo`. **Seven fields, and no `gender`.**
///
/// Marriage's has fifteen. The overlap is not an invitation to share:
/// `residenceCertRef` becomes `marriageCertRef`, which is the rename
/// `tier0_payload_equality_test.dart:563` measures.
class DivorceSpouseInfo {
  const DivorceSpouseInfo({
    this.fullName = '',
    this.dob = '',
    this.nationality = '',
    this.idOrPassport = '',
    this.addrHouseNo = '',
    this.address = CertificateLocationValue.blank,
    this.marriageCertRef = '',
  });

  final String fullName;
  final String dob;
  final String nationality;
  final String idOrPassport;
  final String addrHouseNo;
  final CertificateLocationValue address;

  /// M — the existing marriage certificate reference. Marriage's analogue is
  /// `residenceCertRef` and the wire key differs too.
  final String marriageCertRef;

  static const DivorceSpouseInfo blank = DivorceSpouseInfo();

  DivorceSpouseInfo copyWith({
    String? fullName,
    String? dob,
    String? nationality,
    String? idOrPassport,
    String? addrHouseNo,
    CertificateLocationValue? address,
    String? marriageCertRef,
  }) =>
      DivorceSpouseInfo(
        fullName: fullName ?? this.fullName,
        dob: dob ?? this.dob,
        nationality: nationality ?? this.nationality,
        idOrPassport: idOrPassport ?? this.idOrPassport,
        addrHouseNo: addrHouseNo ?? this.addrHouseNo,
        address: address ?? this.address,
        marriageCertRef: marriageCertRef ?? this.marriageCertRef,
      );
}

/// `:628` — the basis block.
class DivorceBasis {
  const DivorceBasis({
    this.divorceType = '',
    this.dateOfDivorce = '',
    this.placeOfRegistration = '',
  });

  final String divorceType;

  /// `event_date: basis.dateOfDivorce || undefined` (`:858`) — elided when
  /// blank, never `today()`.
  final String dateOfDivorce;

  final String placeOfRegistration;

  static const DivorceBasis blank = DivorceBasis();

  DivorceBasis copyWith({
    String? divorceType,
    String? dateOfDivorce,
    String? placeOfRegistration,
  }) =>
      DivorceBasis(
        divorceType: divorceType ?? this.divorceType,
        dateOfDivorce: dateOfDivorce ?? this.dateOfDivorce,
        placeOfRegistration: placeOfRegistration ?? this.placeOfRegistration,
      );
}

/// `:634-637` — the voluntary arm's mediation record.
class DivorceMediation {
  const DivorceMediation({
    this.dateMarriageBegan = '',
    this.reasonsHusband = '',
    this.reasonsWife = '',
    this.outcome = '',
    this.propertyDivision = '',
    this.debts = '',
    this.additionalAssets = '',
    this.w1Name = '',
    this.w2Name = '',
  });

  final String dateMarriageBegan;
  final String reasonsHusband;
  final String reasonsWife;
  final String outcome;
  final String propertyDivision;
  final String debts;
  final String additionalAssets;
  final String w1Name;
  final String w2Name;

  static const DivorceMediation blank = DivorceMediation();

  DivorceMediation copyWith({
    String? dateMarriageBegan,
    String? reasonsHusband,
    String? reasonsWife,
    String? outcome,
    String? propertyDivision,
    String? debts,
    String? additionalAssets,
    String? w1Name,
    String? w2Name,
  }) =>
      DivorceMediation(
        dateMarriageBegan: dateMarriageBegan ?? this.dateMarriageBegan,
        reasonsHusband: reasonsHusband ?? this.reasonsHusband,
        reasonsWife: reasonsWife ?? this.reasonsWife,
        outcome: outcome ?? this.outcome,
        propertyDivision: propertyDivision ?? this.propertyDivision,
        debts: debts ?? this.debts,
        additionalAssets: additionalAssets ?? this.additionalAssets,
        w1Name: w1Name ?? this.w1Name,
        w2Name: w2Name ?? this.w2Name,
      );
}

/// `:642` — the contested arm's People's Court decree.
class DivorceCourt {
  const DivorceCourt({this.name = '', this.decisionDate = ''});

  final String name;
  final String decisionDate;

  static const DivorceCourt blank = DivorceCourt();

  DivorceCourt copyWith({String? name, String? decisionDate}) => DivorceCourt(
        name: name ?? this.name,
        decisionDate: decisionDate ?? this.decisionDate,
      );
}

/// `:639` — the children block, gated on [DivorceFormData.hasChildren].
class DivorceChildren {
  const DivorceChildren({this.list = '', this.custody = ''});

  final String list;
  final String custody;

  static const DivorceChildren blank = DivorceChildren();

  DivorceChildren copyWith({String? list, String? custody}) => DivorceChildren(
        list: list ?? this.list,
        custody: custody ?? this.custody,
      );
}

/// Every `useState` on the page that reaches the wire.
class DivorceFormData {
  const DivorceFormData({
    this.header = CertificateLocationValue.blank,
    this.husband = DivorceSpouseInfo.blank,
    this.wife = DivorceSpouseInfo.blank,
    this.basis = DivorceBasis.blank,
    this.mediationMode = DivorceMediationMode.none,
    this.linkedRecord,
    this.mediation = DivorceMediation.blank,
    this.hasChildren = false,
    this.children = DivorceChildren.blank,
    this.court = DivorceCourt.blank,
    this.courtDecision,
    this.guaranteeCert,
    this.householdBook,
    this.photos,
    this.payment = kBlankPayment,
  });

  final CertificateLocationValue header;
  final DivorceSpouseInfo husband;
  final DivorceSpouseInfo wife;
  final DivorceBasis basis;

  final DivorceMediationMode mediationMode;
  final PrerequisiteRecord? linkedRecord;
  final DivorceMediation mediation;
  final bool hasChildren;
  final DivorceChildren children;

  final DivorceCourt court;
  final PickedAttachment? courtDecision;

  final PickedAttachment? guaranteeCert;
  final PickedAttachment? householdBook;
  final PickedAttachment? photos;

  final PaymentDraft payment;

  DivorceFormData copyWith({
    CertificateLocationValue? header,
    DivorceSpouseInfo? husband,
    DivorceSpouseInfo? wife,
    DivorceBasis? basis,
    DivorceMediationMode? mediationMode,
    PrerequisiteRecord? linkedRecord,
    bool clearLinkedRecord = false,
    DivorceMediation? mediation,
    bool? hasChildren,
    DivorceChildren? children,
    DivorceCourt? court,
    PickedAttachment? courtDecision,
    bool clearCourtDecision = false,
    PickedAttachment? guaranteeCert,
    bool clearGuaranteeCert = false,
    PickedAttachment? householdBook,
    bool clearHouseholdBook = false,
    PickedAttachment? photos,
    bool clearPhotos = false,
    PaymentDraft? payment,
  }) =>
      DivorceFormData(
        header: header ?? this.header,
        husband: husband ?? this.husband,
        wife: wife ?? this.wife,
        basis: basis ?? this.basis,
        mediationMode: mediationMode ?? this.mediationMode,
        linkedRecord:
            clearLinkedRecord ? null : (linkedRecord ?? this.linkedRecord),
        mediation: mediation ?? this.mediation,
        hasChildren: hasChildren ?? this.hasChildren,
        children: children ?? this.children,
        court: court ?? this.court,
        courtDecision:
            clearCourtDecision ? null : (courtDecision ?? this.courtDecision),
        guaranteeCert:
            clearGuaranteeCert ? null : (guaranteeCert ?? this.guaranteeCert),
        householdBook:
            clearHouseholdBook ? null : (householdBook ?? this.householdBook),
        photos: clearPhotos ? null : (photos ?? this.photos),
        payment: payment ?? this.payment,
      );
}

/// `:745` — `basis.divorceType === "voluntary"`.
bool divorceIsVoluntary(DivorceFormData f) =>
    f.basis.divorceType == kDivorceTypeVoluntary;

/// `:746` — `basis.divorceType === "contested"`.
bool divorceIsContested(DivorceFormData f) =>
    f.basis.divorceType == kDivorceTypeContested;

/// **The terminal code** — a `divorce_type` that is neither literal, and not
/// blank.
///
/// `:745-746` compares against two string literals, so a third server-side code
/// leaves both booleans false. Step 1 then renders **only the type select**
/// (`:1224` and `:1339` are inside the two branches), while `canProceed()`
/// falls through to the contested arm at `:765` and demands a header, a court
/// name, a decision date and an upload **that state never renders**. The step
/// cannot advance for any sequence of clicks.
///
/// `fsd.md` § 5.5 probed the live list on 2026-08-13 as exactly
/// `{voluntary, contested}`, so this is **not reachable in the running app
/// today** and is a latent hazard the moment a third code is added
/// server-side (`F3-NV-6`). It is therefore in scope as a **defined
/// behaviour** — the port must not throw, must not crash, and must not invent
/// an "unsupported type" panel (`F3-AC-52`, `F3-AC-53`) — and out of scope as a
/// fixture target.
bool divorceIsTerminalType(DivorceFormData f) =>
    f.basis.divorceType.isNotEmpty &&
    !divorceIsVoluntary(f) &&
    !divorceIsContested(f);

/// `:743` — `header.provinceId && header.districtId && header.villageId`.
bool divorceHeaderValid(DivorceFormData f) =>
    f.header.provinceId.isNotEmpty &&
    f.header.districtId.isNotEmpty &&
    f.header.villageId.isNotEmpty;

/// `:737-741` — `spouseValid(s)`. Seven conditions, no `gender`, and — as on
/// Marriage — `districtId` is not among them.
bool divorceSpouseValid(DivorceSpouseInfo s) =>
    s.fullName.trim().isNotEmpty &&
    s.dob.trim().isNotEmpty &&
    s.nationality.isNotEmpty &&
    s.idOrPassport.trim().isNotEmpty &&
    s.address.villageId.isNotEmpty &&
    s.address.provinceId.isNotEmpty &&
    s.marriageCertRef.trim().isNotEmpty;

/// `:749-776` — `canProceed()`.
///
/// **Step 1 has three outcomes over four states**, and the fall-through is the
/// hazard:
///
/// | state | result |
/// | --- | --- |
/// | no type chosen | `false` (`:751`) |
/// | `voluntary` + no mode | `false` (`:762`) |
/// | `voluntary` + `existing` | needs a linked record + header (`:753`) — **unreachable**, `/prerequisite-records` is empty |
/// | `voluntary` + `new` | header + five mediation fields + children when toggled (`:754-761`) |
/// | `contested` | header + court decision + name + date (`:765`) |
/// | **terminal code** | falls through to `:765` — the contested arm — while step 1 renders only the select |
///
/// Step 5 (review) is absent and falls through to `true` (`:775`).
bool divorceCanProceed(DivorceFormData f, {required int step}) {
  if (step == 1) {
    if (f.basis.divorceType.isEmpty) return false;
    if (divorceIsVoluntary(f)) {
      switch (f.mediationMode) {
        case DivorceMediationMode.existing:
          return f.linkedRecord != null && divorceHeaderValid(f);
        case DivorceMediationMode.newRecord:
          return divorceHeaderValid(f) &&
              f.mediation.dateMarriageBegan.trim().isNotEmpty &&
              f.mediation.reasonsHusband.trim().isNotEmpty &&
              f.mediation.reasonsWife.trim().isNotEmpty &&
              f.mediation.outcome.trim().isNotEmpty &&
              f.mediation.propertyDivision.trim().isNotEmpty &&
              (!f.hasChildren ||
                  (f.children.list.trim().isNotEmpty &&
                      f.children.custody.trim().isNotEmpty));
        case DivorceMediationMode.none:
          return false; // `:762`
      }
    }
    // `:765` — contested, AND the terminal code's fall-through.
    return divorceHeaderValid(f) &&
        f.courtDecision != null &&
        f.court.name.trim().isNotEmpty &&
        f.court.decisionDate.trim().isNotEmpty;
  }
  if (step == 2) return divorceSpouseValid(f.husband);
  if (step == 3) return divorceSpouseValid(f.wife);
  if (step == 4) {
    return f.basis.dateOfDivorce.trim().isNotEmpty &&
        f.basis.placeOfRegistration.trim().isNotEmpty &&
        f.guaranteeCert != null &&
        f.householdBook != null &&
        f.photos != null;
  }
  if (step == 6) return isPaymentValid(f.payment);
  return true;
}

/// `:731-735` — `resetMediation()`, **with D-N's missing half restored**.
///
/// ## What the source does, and the defect
///
/// ```ts
/// const resetMediation = () => {
///   setMediationMode(""); setLinkedRecord(null); openRecord.reset();
/// };
/// ```
///
/// It is invoked from the type `onChange` (`:1041`) and exists *precisely* to
/// clear the abandoned branch — but it clears only the **voluntary** branch's
/// state. `court.name`, `court.decisionDate` and `courtDecision` survive, and
/// `buildFormData` writes `basis.court_name` / `basis.court_decision_date`
/// **unconditionally** (`:831-832`) while `uploads()` includes
/// `basis.court_decision` unconditionally (`:841`). Contested → voluntary
/// therefore submits a voluntary divorce carrying a court decree.
///
/// ## Why the FIX is upheld
///
/// `fsd.md` § 9.2 dispositions D-N **FIX**, and § 6.7 upholds it on evidence
/// rather than deference: missing half of a function whose whole purpose is
/// "clear the abandoned branch" is an omission, not a design.
///
/// **It is provably safe against the gate.** On all eight executed divorce
/// documents the type is set once and never switched, so the fixed and unfixed
/// payloads are byte-identical — `F3-AC-54` asserts the fix *and* that all
/// twelve Tier 0 documents are unchanged by it.
///
/// **Scope.** D-N names *stale court data*, so this clears the court block and
/// nothing else. Clearing `mediation.*` as well would be symmetric and would be
/// a second, unauthorised fix.
DivorceFormData divorceResetMediation(DivorceFormData f) => f.copyWith(
      mediationMode: DivorceMediationMode.none,
      clearLinkedRecord: true,
      // D-N — the half the source omits.
      court: DivorceCourt.blank,
      clearCourtDecision: true,
    );

/// Re-exported so `divorce_payload.dart` reads the same literal Marriage does
/// — one constant, five sites, `:834-835` being two of them.
const String kDivorceOfficeDeferred = kOfficeDeferred;

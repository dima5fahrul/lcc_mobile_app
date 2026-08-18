/// The family-book feature's wire → entity parsing, hand-written.
///
/// ## Why hand-written, and why the primitives are duplicated
///
/// `application_wire.dart`'s three reasons carry across unchanged — an enum
/// that must tolerate an unknown wire value, a `Bilingual` that arrives in two
/// shapes, and nothing that round-trips — and `specs.md` § 3.1 row 2 asks this
/// feature to hold *"its own `@JsonKey` knowledge"*, which `ssd.md` § 4.3
/// glosses as **"wire-format duplication is the accepted cost"**.
///
/// The five primitives below are byte-identical to `application_wire.dart`'s
/// and are **local on purpose**: G-L3 forbids `features/A →
/// features/B/data/**`, so importing them would be the one edge the layering
/// guard exists to catch. `news_wire.dart`, `chat_wire.dart` and
/// `application_wire.dart` each declare their own for the same reason; this is
/// the fourth copy and the convention, not a slip.
///
/// ## `ApplicationRow` is parsed here, not imported from the application feature
///
/// `POST /me/family-book/request-copy` answers an `ApplicationRow`
/// (`endpoints.ts:129`), and `applicationRowFrom` already exists — in
/// `features/application/**data**/`, which is exactly the import G-L3 forbids
/// and `F4-AC-14` greps for. So the row is parsed again here, against the same
/// **entity**, which is imported and not redeclared (`F4-AC-23`).
///
/// The duplication is real and is the accepted cost of the rule. What it does
/// **not** duplicate is the entity, the enum vocabulary or the not-found
/// distinction — all three are the application feature's and are consumed.
///
/// ## What the read does NOT parse
///
/// The `place` block declared at `types.ts:617`. It is read by no line of
/// `FamilyBookPage.tsx` and its name collides with the page's own local
/// `place` variable, which is bound to `jurisdiction` — see
/// `family_book.dart`'s library doc and `F4-AC-43`.
library;

import '../../../../core/network/envelope.dart';
import '../../../application/domain/entities/application_row.dart';
import '../../../application/domain/entities/case_status.dart';
import '../../../application/domain/entities/jurisdiction.dart';
import '../../../session/domain/entities/bilingual.dart';
import '../../domain/entities/family_book.dart';
import '../../domain/entities/household_member.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Primitives — local, per G-L3. See the library doc.
// ─────────────────────────────────────────────────────────────────────────────

/// A string field, or `''`.
String stringAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  return raw is String ? raw : '';
}

/// A string field, or **null** when absent or empty.
///
/// The empty-string collapse is load-bearing on this page rather than merely
/// tidy: every optional string here is rendered through a JavaScript `||` or
/// `??` chain (`:413`, `:471`, `:489`, `:495`, `:529`), and `""` is falsy in
/// JavaScript. A Dart `''` surviving to the widget would render an empty
/// `ReadField` where the web renders `—`.
String? nullableStringAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is! String || raw.isEmpty) return null;
  return raw;
}

/// An integer field, or `null` when the key is absent or not a number.
///
/// **Nullable, and that is the whole point for the three member counts.**
/// `:213-215` is `??`, so the difference between "the server said `0`" and "the
/// server said nothing" decides whether the array is counted. A reader that
/// defaulted to `0` would erase it (`F4-AC-45`).
///
/// Accepts a `double` for `home_wire.dart`'s reason: JSON has one number type
/// and a backend that serialises `3.0` is sending an integer.
int? nullableIntAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is int) return raw;
  if (raw is double) return raw.round();
  if (raw is String) return int.tryParse(raw);
  return null;
}

/// An integer field, or [fallback].
int intAt(Map<String, dynamic> json, String key, {int fallback = 0}) =>
    nullableIntAt(json, key) ?? fallback;

/// A boolean field, or [fallback].
bool boolAt(Map<String, dynamic> json, String key, {bool fallback = false}) {
  final Object? raw = json[key];
  return raw is bool ? raw : fallback;
}

/// The mixed-shape bilingual reader — `{"en":…,"lo":…}`, a plain string on both
/// sides, or an empty pair. `types.ts:17-22`'s `text()` already falls back
/// `wanted || en || lo || ""`, so copying a lone string into both sides is what
/// the web renders.
Bilingual bilingualAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is String) return Bilingual(en: raw, lo: raw);
  if (raw is Map<String, dynamic>) {
    return Bilingual(
      en: raw['en'] is String ? raw['en'] as String : '',
      lo: raw['lo'] is String ? raw['lo'] as String : '',
    );
  }
  return const Bilingual(en: '', lo: '');
}

// ─────────────────────────────────────────────────────────────────────────────
// The read — GET /me/family-book
// ─────────────────────────────────────────────────────────────────────────────

/// `types.ts:96-103` — the `jurisdiction` block.
///
/// An absent or non-object block yields `null` rather than an all-empty
/// [Jurisdiction], because `:217` is `book?.jurisdiction` and "absent" is a
/// state the address line distinguishes (`F4-AC-69`).
Jurisdiction? jurisdictionFrom(Object? raw) {
  if (raw is! Map<String, dynamic>) return null;
  return Jurisdiction(
    provinceId: nullableStringAt(raw, 'province_id'),
    provinceName: nullableStringAt(raw, 'province_name'),
    districtId: nullableStringAt(raw, 'district_id'),
    districtName: nullableStringAt(raw, 'district_name'),
    villageId: nullableStringAt(raw, 'village_id'),
    villageName: nullableStringAt(raw, 'village_name'),
  );
}

/// One row of `members` — `types.ts:586-598`.
///
/// Every optional field stays optional. See `household_member.dart` for why the
/// TypeScript's `required` is not the contract here.
HouseholdMember householdMemberFrom(Map<String, dynamic> json) =>
    HouseholdMember(
      id: stringAt(json, 'id'),
      uin: nullableStringAt(json, 'uin'),
      name: stringAt(json, 'name'),
      gender: nullableStringAt(json, 'gender'),
      dateOfBirth: nullableStringAt(json, 'date_of_birth'),
      relation: nullableStringAt(json, 'relation'),
      nationality: nullableStringAt(json, 'nationality'),
      photoUrl: nullableStringAt(json, 'photo_url'),
      status: nullableStringAt(json, 'status'),
      personId: nullableStringAt(json, 'person_id'),
      age: nullableIntAt(json, 'age'),
    );

/// `GET /me/family-book` — `types.ts:598-621` plus the page's two local cover
/// fields (`:33-36`).
///
/// A `members` array carrying anything that is not an object is **skipped**
/// rather than thrown on: `whereType` for `application_wire.dart`'s reason —
/// one malformed row must not take the whole household down.
FamilyBook familyBookFrom(Map<String, dynamic> json) => FamilyBook(
      id: nullableStringAt(json, 'id'),
      householdNo: stringAt(json, 'household_no'),
      headName: stringAt(json, 'head_name'),
      headIdNo: nullableStringAt(json, 'head_id_no'),
      nationality: nullableStringAt(json, 'nationality'),
      unit: stringAt(json, 'unit'),
      group: stringAt(json, 'group'),
      address: nullableStringAt(json, 'address'),
      houseNo: nullableStringAt(json, 'house_no'),
      status: nullableStringAt(json, 'status'),
      reissueCount: nullableIntAt(json, 'reissue_count'),
      totalMembers: nullableIntAt(json, 'total_members'),
      maleMembers: nullableIntAt(json, 'male_members'),
      femaleMembers: nullableIntAt(json, 'female_members'),
      issuedAt: nullableStringAt(json, 'issued_at'),
      registeredAt: nullableStringAt(json, 'registered_at'),
      jurisdiction: jurisdictionFrom(json['jurisdiction']),
      members: (json['members'] is List<dynamic>
              ? json['members'] as List<dynamic>
              : const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(householdMemberFrom)
          .toList(growable: false),
    );

// ─────────────────────────────────────────────────────────────────────────────
// The write — POST /me/family-book/request-copy
// ─────────────────────────────────────────────────────────────────────────────

/// **The entire request body.** `FamilyBookPage.tsx:204`:
///
/// ```tsx
/// me.requestFamilyBookCopy({ reason })
/// ```
///
/// One key. No envelope key wrapping it, no nulls, nothing else — `client.ts:242`
/// is a bare `JSON.stringify(options.body)`, so what this map holds is what the
/// socket carries, in this order (`F4-AC-22`).
///
/// It is a function rather than a literal at the call site so the Tier 0 test
/// can compare the **built body** without standing up a datasource, and so
/// there is exactly one place in `lib/**` that knows this body's shape.
Map<String, Object?> requestCopyBody(String reason) => <String, Object?>{
      'reason': reason,
    };

/// One case, as `POST …/request-copy` returns it — `types.ts:421-449`.
///
/// A second transcription of the same 26 fields `application_wire.dart` parses,
/// against the same entity, for the G-L3 reason the library doc gives. Field
/// order follows `types.ts` so the two files diff against each other line for
/// line in review.
ApplicationRow applicationRowFrom(Map<String, dynamic> json) => ApplicationRow(
      id: stringAt(json, 'id'),
      referenceNo: stringAt(json, 'reference_no'),
      serviceCode: stringAt(json, 'service_code'),
      serviceName: bilingualAt(json, 'service_name'),
      applicant: stringAt(json, 'applicant'),
      subjectName: stringAt(json, 'subject_name'),
      status: CaseStatus.fromWire(json['status'] as String?),
      statusLabel: bilingualAt(json, 'status_label'),
      paymentState: PaymentState.fromWire(json['payment_state'] as String?),
      feeLak: intAt(json, 'fee_lak'),
      channel: stringAt(json, 'channel'),
      jurisdiction: jurisdictionFrom(json['jurisdiction']) ?? Jurisdiction.empty,
      assignedOfficer: nullableStringAt(json, 'assigned_officer'),
      slaDays: intAt(json, 'sla_days'),
      daysWaiting: intAt(json, 'days_waiting'),
      daysOverdue: intAt(json, 'days_overdue'),
      isOverdue: boolAt(json, 'is_overdue'),
      submittedAt: nullableStringAt(json, 'submitted_at'),
      dueAt: nullableStringAt(json, 'due_at'),
      issuedAt: nullableStringAt(json, 'issued_at'),
      closedAt: nullableStringAt(json, 'closed_at'),
      createdAt: stringAt(json, 'created_at'),
      updatedAt: stringAt(json, 'updated_at'),
      reasonNote: nullableStringAt(json, 'reason_note'),
      certificateId: nullableStringAt(json, 'certificate_id'),
      certificateNo: nullableStringAt(json, 'certificate_no'),
    );

/// The envelope's `data` object, or an empty map.
///
/// `ApiClient._unwrap` already returns `data`; this is the guard for a response
/// whose `data` is null or is not an object, which parses to an all-default
/// entity rather than throwing — `envelope.dart`'s own contract, and the
/// `bilingual_converter.dart` reasoning: a half-populated row is visible and
/// diagnosable, a thrown parse takes the page down over one bad field.
Map<String, dynamic> dataObject(Object? raw) =>
    raw is Map<String, dynamic> ? raw : const <String, dynamic>{};

/// Kept so a reader can see which envelope type this feature's calls unwrap
/// through, and so the import is not decorative.
typedef FamilyBookEnvelope = Envelope<Map<String, dynamic>>;

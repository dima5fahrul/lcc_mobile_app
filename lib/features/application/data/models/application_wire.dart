/// The application feature's wire → entity parsing, hand-written.
///
/// ## A recorded deviation from specs.md § 3.1
///
/// § 3.1's B7a row reads *"`@JsonKey` wire models"*. This file is
/// hand-written parsers instead, on `news_wire.dart`'s and `home_wire.dart`'s
/// precedent, for three measured reasons:
///
/// 1. **`CaseStatus` and `PaymentState` must tolerate an unknown wire value.**
///    A `json_serializable` enum throws on one unless every call site adds
///    `unknownEnumValue`, and a throw here takes the whole list down over a
///    status the backend added after this build shipped. `CaseStatus.fromWire`
///    folds it to [CaseStatus.unknown], which is what TypeScript's union does
///    by construction (see `case_status.dart`).
/// 2. **`Bilingual` arrives in two shapes on this API.** `{en, lo}` and a
///    plain string are both permitted (`news_wire.dart`'s header measures it),
///    and [bilingualAt] accepts both. A generated model would need a converter
///    per field to do the same.
/// 3. **Nothing round-trips.** These rows are read once into an entity and
///    never serialised back, so generated `toJson` for 26 fields would exist
///    only to be discarded.
///
/// What generation would buy — that the parse cannot silently disagree with
/// the entity — is bought instead by parsing the recorded fixtures
/// (`test/fidelity/fixtures/api/*.json`) through the **real** datasource, real
/// repository and real BLoC, which is stronger: `json_serializable` validates
/// a hand-written fixture against a hand-written model and both can be wrong
/// together.
///
/// The deviation is recorded rather than absorbed. The alternative reading of
/// § 3.1 — that `@JsonKey` is shorthand for "the data layer owns this
/// feature's wire knowledge", which is how `ssd.md` § 4.3 uses the same phrase
/// — is also satisfied: this file is the only place in `lib/**` that knows
/// what `under-review` or `sla_days` are called on the wire.
///
/// ## A missing scalar becomes its zero value, not a parse failure
///
/// `bilingual_converter.dart`'s reason: a half-populated row renders one field
/// blank, which is visible and diagnosable; a thrown parse error takes the
/// page down over one bad field. The **required** fields of `ApplicationRow`
/// are required in TypeScript too (`types.ts:421-449`), so a row missing one
/// is already a backend defect — this parse renders it rather than hiding it.
library;

import '../../../session/domain/entities/bilingual.dart';
import '../../domain/entities/application_detail.dart';
import '../../domain/entities/application_row.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/entities/case_event.dart';
import '../../domain/entities/case_status.dart';
import '../../domain/entities/case_timeline.dart';
import '../../domain/entities/jurisdiction.dart';
import '../../domain/entities/status_pipeline.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Primitives — the same four `news_wire.dart` declares, kept local because
// CFI forbids reaching into another feature's `data/` for them (G-L3).
// ─────────────────────────────────────────────────────────────────────────────

/// A string field, or `''`.
String stringAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  return raw is String ? raw : '';
}

/// A string field, or **null** when absent/empty — the `?:` fields of
/// `types.ts:421-449`.
///
/// Empty-string collapses to null deliberately: `assigned_officer: ""` and an
/// absent `assigned_officer` render identically on the web
/// (`HistoryDetailPage.tsx:367`, `detail.assigned_officer && …`), because JS
/// treats `""` as falsy. A Dart `''` would be truthy and would render an empty
/// officer chip.
String? nullableStringAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is! String || raw.isEmpty) return null;
  return raw;
}

/// An integer field, or [fallback].
///
/// Accepts a `double` for the reason `home_wire.dart` gives: JSON has one
/// number type, and a backend that serialises `10.0` for `sla_days` is sending
/// an integer.
int intAt(Map<String, dynamic> json, String key, {int fallback = 0}) {
  final Object? raw = json[key];
  if (raw is int) return raw;
  if (raw is double) return raw.round();
  if (raw is String) return int.tryParse(raw) ?? fallback;
  return fallback;
}

/// A boolean field, or [fallback].
bool boolAt(Map<String, dynamic> json, String key, {bool fallback = false}) {
  final Object? raw = json[key];
  return raw is bool ? raw : fallback;
}

/// The mixed-shape bilingual reader.
///
/// * `{"en": …, "lo": …}` → both sides, each defaulting to `''`
/// * `"a plain string"` → that string on **both** sides
/// * anything else → an empty pair
///
/// Copying a plain string into both sides is faithful, not a shortcut:
/// `text(value, lang)` (`types.ts:17-22`) falls back `wanted || en || lo || ""`,
/// so a single-language field already renders the same text in either locale
/// on the web.
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
// Rows
// ─────────────────────────────────────────────────────────────────────────────

/// `types.ts:96-103` — the `jurisdiction` block of a row.
///
/// An absent or non-object block yields [Jurisdiction.empty], which is what
/// makes `officeLine` render `"—"` rather than throwing.
Jurisdiction jurisdictionFrom(Object? raw) {
  if (raw is! Map<String, dynamic>) return Jurisdiction.empty;
  return Jurisdiction(
    provinceId: nullableStringAt(raw, 'province_id'),
    provinceName: nullableStringAt(raw, 'province_name'),
    districtId: nullableStringAt(raw, 'district_id'),
    districtName: nullableStringAt(raw, 'district_name'),
    villageId: nullableStringAt(raw, 'village_id'),
    villageName: nullableStringAt(raw, 'village_name'),
  );
}

/// One row of `GET /applications` — all 26 fields of `types.ts:421-449`.
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
      jurisdiction: jurisdictionFrom(json['jurisdiction']),
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

// ─────────────────────────────────────────────────────────────────────────────
// The detail half — B7b
// ─────────────────────────────────────────────────────────────────────────────

/// A **nullable** bilingual reader — `types.ts:466`'s `status_label?: Bilingual`.
///
/// [bilingualAt] cannot serve here: it answers an empty pair for an absent key,
/// and `CaseEvent` needs to tell "the API sent no label" apart from "the API
/// sent an empty one", because `HistoryDetailPage.tsx:572` falls back to the raw
/// `to_status` on **either**. Returning the empty pair would work today by
/// accident; returning null says what was measured.
Bilingual? nullableBilingualAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is String) return raw.isEmpty ? null : Bilingual(en: raw, lo: raw);
  if (raw is Map<String, dynamic>) return bilingualAt(json, key);
  return null;
}

/// One `attachments[]` entry — 8 of the 9 fields of `types.ts:450-460`.
///
/// **`mime_type` is the omitted ninth**, and `attachment.dart:56` carries the
/// reasoning: neither the source nor the port renders it, and R-21 forbids the
/// identifier repo-wide. An unparsed key is not a lossy parse here — the wire
/// map is not round-tripped, and no caller can ask for what the entity does
/// not declare.
Attachment attachmentFrom(Map<String, dynamic> json) => Attachment(
      id: stringAt(json, 'id'),
      kind: stringAt(json, 'kind'),
      slot: stringAt(json, 'slot'),
      label: stringAt(json, 'label'),
      fileName: stringAt(json, 'file_name'),
      fileUrl: stringAt(json, 'file_url'),
      sizeBytes: intAt(json, 'size_bytes'),
      uploadedAt: stringAt(json, 'uploaded_at'),
    );

/// One timeline entry — all 11 fields of `types.ts:462-474`.
///
/// `to_status` goes through [CaseStatus.fromWire] like every other status on
/// this API, so an event carrying a status this build has not heard of buckets
/// as `pending` and renders its raw wire string rather than throwing — the
/// tenth-member reasoning `case_status.dart` records, reached here by a
/// **timeline** event rather than by a row.
CaseEvent caseEventFrom(Map<String, dynamic> json) => CaseEvent(
      id: stringAt(json, 'id'),
      action: stringAt(json, 'action'),
      fromStatus: json['from_status'] == null
          ? null
          : CaseStatus.fromWire(json['from_status'] as String?),
      toStatus: CaseStatus.fromWire(json['to_status'] as String?),
      statusLabel: nullableBilingualAt(json, 'status_label'),
      actorId: nullableStringAt(json, 'actor_id'),
      actorName: nullableStringAt(json, 'actor_name'),
      actorRole: nullableStringAt(json, 'actor_role'),
      reasonCode: nullableStringAt(json, 'reason_code'),
      note: nullableStringAt(json, 'note'),
      occurredAt: stringAt(json, 'occurred_at'),
    );

/// A `CaseEvent[]`, dropping any entry that is not an object.
///
/// `whereType` rather than a cast, for `applicationRowFrom`'s reason one level
/// down: one malformed event costs that event, not the whole trail.
List<CaseEvent> caseEventsFrom(Object? raw) {
  if (raw is! List) return const <CaseEvent>[];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(caseEventFrom)
      .toList(growable: false);
}

/// `GET /applications/{id}` → the detail.
///
/// **The row half is parsed by [applicationRowFrom], the list's own parser.**
/// That is the whole point of `ApplicationDetail` composing a row rather than
/// re-declaring 26 fields: there is one place that knows `sla_days` is called
/// `sla_days`, so the list and the detail cannot disagree about a field one of
/// them added.
///
/// Three of the source's five extra fields are read. `form_data` (§ 6.3) and
/// `allowed_actions` (§ 6.2, § 6.9) are **not touched at all** — not parsed,
/// not carried, not named — so no B7 code can grow a dependency on a shape B7
/// does not understand. `application_detail.dart` records why the third,
/// `linked_reference_no`, is carried when nothing draws it.
///
/// `timeline` stays **null** when the key is absent, and becomes an empty list
/// when the key is an empty array. `HistoryDetailPage.tsx:249`'s
/// `?? detail.timeline ?? []` chain distinguishes them (`B7-AC-62`), so
/// flattening the two here would quietly remove a branch the source has.
ApplicationDetail applicationDetailFrom(Map<String, dynamic> json) =>
    ApplicationDetail(
      row: applicationRowFrom(json),
      attachments: json['attachments'] is List
          ? (json['attachments'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map(attachmentFrom)
              .toList(growable: false)
          : const <Attachment>[],
      timeline:
          json['timeline'] is List ? caseEventsFrom(json['timeline']) : null,
      linkedReferenceNo: nullableStringAt(json, 'linked_reference_no'),
    );

/// `GET /applications/{id}/timeline` → the envelope (`types.ts:493-498`).
CaseTimeline caseTimelineFrom(Map<String, dynamic> json) => CaseTimeline(
      applicationId: stringAt(json, 'application_id'),
      referenceNo: stringAt(json, 'reference_no'),
      status: CaseStatus.fromWire(json['status'] as String?),
      events: caseEventsFrom(json['events']),
    );

/// `GET /status-catalogue` → the pipeline.
///
/// **Reads `pipeline_order` and nothing else.** The `statuses[]` array — nine
/// entries, each with `transitions[]`, `acting_role`, `color`, `background` —
/// is the richest object the API sends and is consumed by nothing
/// (specs.md § 6.9). It is not parsed, not carried, and not named.
///
/// The `draft`-strip and the keep-the-seed guard both live in
/// [StatusPipeline.fromOrder], so a second caller cannot get them wrong.
StatusPipeline statusPipelineFrom(Map<String, dynamic> json) {
  final Object? raw = json['pipeline_order'];
  if (raw is! List) return StatusPipeline.seeded;
  return StatusPipeline.fromOrder(
    raw.whereType<String>().map(CaseStatus.fromWire).toList(growable: false),
  );
}

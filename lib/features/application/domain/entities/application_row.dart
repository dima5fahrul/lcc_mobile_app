/// `ApplicationRow` — one case, as `GET /applications` returns it.
///
/// Ported field-for-field from `lcc-app/src/app/api/types.ts:421-449`
/// (**26 fields**, 11 of them optional). `service_name` and `status_label` are
/// `Bilingual`, the existing shared-kernel entity
/// (`features/session/domain/entities/bilingual.dart`, `ssd.md` § 4.5).
///
/// ## Why this lives in `features/application/` and not in `features/history/`
///
/// `ssd.md` § 5.1's ruling, and § 4.2 row 4 before it: an *application* is not
/// a *history* concept. Measured, three other surfaces read this row —
/// `HistoryPage.tsx:85`/`:103` (B7), `WalletPage.tsx:105`'s Bills Due (B6b) and
/// the five certificate pages (F1–F3) — so putting it under `history` would
/// point four later batches' import arrows at the wrong module. B7a builds it,
/// B4 absorbs and extends it (specs.md § 6.2).
///
/// ## The additive contract for B4 — what is deliberately absent
///
/// **No write path lives on this entity and none may be added by B7.** The
/// fields `ApplicationDetail` adds (`form_data`, `attachments`, `timeline`,
/// `allowed_actions`, `linked_reference_no`, `types.ts:485-491`) are B7b's and
/// B4's. Every field B7 does not render is left out so B4 **adds** rather than
/// reconciles — which is the whole reason § 6.2's absorb is a merge and not a
/// rewrite.
///
/// ## The typed create-input DTO is **REFUSED**, not reserved
///
/// This paragraph used to reserve `CreateApplicationInput` to B4. B4 ran, and
/// its answer is that the type is **not created — ever, by anyone**
/// (`GOR-245-b4-application-consolidation/specs.md` § 6.3, RULING 2). It is a
/// refusal rather than a deferral, and the ground is measured:
///
/// `types.ts:500-507` declares the interface, and the five certificate wizards
/// **do not agree about the body it would type**. Resident writes
/// `province_id: form.province || undefined` (`ResidentCertificatePage.tsx:509`)
/// and `JSON.stringify` **drops** the key; Marriage writes
/// `province_id: header.provinceId` (`MarriageCertificatePage.tsx:959`) and
/// sends `""`. Same key name, two different wire bodies. A DTO would have to
/// model that key as one of nullable-elided or nullable-empty and would
/// silently impose the choice on the other family — the app would compile, the
/// form would submit, and one of five services would start receiving a six-key
/// body where the web sends five.
///
/// What the type was reaching for is already delivered by a different
/// mechanism: `EnvelopeShape`
/// (`features/certificates/domain/submission/envelope_shape.dart`) describes
/// the create and update bodies — key names, order, and per-key emptiness —
/// without *being* the body, so it can represent both families at once.
/// `SubmissionExecutor` reads it, which is the first time anything did.
///
/// The create envelope therefore stays an **ordered `Map<String, Object?>`**
/// built by the page. `test/features/application/application_scope_test.dart`
/// asserts this comment is the only occurrence of the identifier in `lib/`.
///
/// **Every field the wire carries IS parsed**, including the ones no current
/// surface draws (`applicant`, `channel`, `issued_at`, `closed_at`,
/// `certificate_id`…). That is `home_wire.dart`'s `serviceFrom` precedent: a
/// partial construction makes the entity mean something subtly different from
/// the row it came from, and the next batch that needs one of those fields has
/// to re-derive the parse rather than read it.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/bilingual.dart';
import 'case_status.dart';
import 'jurisdiction.dart';

part 'application_row.freezed.dart';

@freezed
abstract class ApplicationRow with _$ApplicationRow {
  const factory ApplicationRow({
    required String id,
    required String referenceNo,
    required String serviceCode,
    required Bilingual serviceName,
    required String applicant,
    required String subjectName,
    required CaseStatus status,
    required Bilingual statusLabel,
    required PaymentState paymentState,
    required int feeLak,
    required String channel,
    required Jurisdiction jurisdiction,
    String? assignedOfficer,
    required int slaDays,
    required int daysWaiting,
    required int daysOverdue,
    required bool isOverdue,
    String? submittedAt,
    String? dueAt,
    String? issuedAt,
    String? closedAt,
    required String createdAt,
    required String updatedAt,
    String? reasonNote,
    String? certificateId,
    String? certificateNo,
  }) = _ApplicationRow;

  const ApplicationRow._();

  /// `item.submitted_at ?? item.created_at` — `HistoryPage.tsx:387`, and the
  /// same expression again at `HistoryDetailPage.tsx:634`. Named once here so
  /// the list and the detail cannot drift on which date they call "submitted".
  String get submittedOrCreatedAt => submittedAt ?? createdAt;

  /// `bucketOf(item.status)` — `HistoryPage.tsx:288`.
  StatusBucket get bucket => bucketOf(status);
}

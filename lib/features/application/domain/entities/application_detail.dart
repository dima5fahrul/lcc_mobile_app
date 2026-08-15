/// `ApplicationDetail` — one case, as `GET /applications/{id}` returns it.
///
/// Ported from `lcc-app/src/app/api/types.ts:485-491`:
///
/// ```ts
/// export interface ApplicationDetail extends ApplicationRow {
///   form_data: Record<string, unknown>;
///   attachments: Attachment[];
///   timeline?: CaseEvent[];
///   allowed_actions?: AllowedAction[];
///   linked_reference_no?: string;
/// }
/// ```
///
/// ## `extends` becomes composition, not 26 copied fields
///
/// TypeScript's `extends` has no freezed equivalent, and the two ways to spell
/// it in Dart are not equally safe:
///
/// * **Re-declare all 26 [ApplicationRow] fields here.** Two constructors that
///   must be kept in step by hand, across a batch boundary — B4 extends both.
///   A field added to the row and forgotten here parses on the list and is
///   silently absent on the detail, which is the failure mode that is hardest
///   to see because both screens still render.
/// * **Compose.** One [row], one parse, one place a field can be added. Reads
///   cost a `.row.` hop and nothing can drift.
///
/// Composition, therefore. `applicationDetailFrom` parses the row half with the
/// **same** `applicationRowFrom` the list uses, so the two cannot disagree
/// about what `sla_days` is called.
///
/// ## Three fields of the source's five are here; two are ruled out by name
///
/// * **`form_data` — omitted entirely (specs.md § 6.3).** It is
///   `Record<string, unknown>` and `HistoryDetailPage` never reads it; it is
///   F0/F1–F4's Tier 0 surface. Carrying it as an unparsed map would let B7
///   code grow a dependency on a shape B7 does not understand.
/// * **`allowed_actions` — omitted (§ 6.2's additive contract, § 6.9).** It is
///   B4's, it needs the `statuses[]`/`transitions[]` half of the catalogue that
///   § 6.9 rules out of the port, and nothing on this page reads it.
/// * **`linked_reference_no` — carried.** No B7 surface draws it either, but
///   unlike the two above it is not ruled out by name, it is one nullable
///   string, and `application_row.dart`'s stated rule is that every field the
///   wire carries **is** parsed. Recorded rather than assumed, because the two
///   principles genuinely point in opposite directions here and the tiebreak is
///   that the rulings are specific and the rule is general.
///
/// ## `isIssued` and `canPay` are B7b's, and they gate other batches' seams
///
/// § 6.1: what goes in the `documentActions` / `paymentAction` slots is B5's
/// and B6's, but **whether the slot is offered** is a pure function of this
/// payload and is computed here (`B7-AC-52`). Putting them on the entity rather
/// than in the page is what lets a domain test assert them without a widget,
/// and what stops a later batch re-deriving `fee_lak > 0` slightly differently.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'application_row.dart';
import 'attachment.dart';
import 'case_event.dart';
import 'case_status.dart';

part 'application_detail.freezed.dart';

@freezed
abstract class ApplicationDetail with _$ApplicationDetail {
  const factory ApplicationDetail({
    /// The 26 fields of `ApplicationRow`, parsed by the list's own parser.
    required ApplicationRow row,

    /// `attachments: Attachment[]` — required in the source, so an absent key
    /// is an empty list and not a null. The empty list is a **rendered state**
    /// (`HistoryDetailPage.tsx:596-599`), which is the one part of the
    /// attachments card B7b ships (see `attachment.dart`).
    @Default(<Attachment>[]) List<Attachment> attachments,

    /// `timeline?: CaseEvent[]` — **optional, and the optionality is load
    /// bearing.** `:249` is
    /// `timelineQuery.data?.events ?? detail.timeline ?? []`: a null here falls
    /// through to the empty list, an empty list here does **not** fall through
    /// to anything. `B7-AC-62` asserts all three arrangements, so this must
    /// stay nullable rather than defaulting to `const []`.
    List<CaseEvent>? timeline,
    String? linkedReferenceNo,
  }) = _ApplicationDetail;

  const ApplicationDetail._();

  /// `bucketOf(detail.status)` — `HistoryDetailPage.tsx:242`.
  StatusBucket get bucket => bucketOf(row.status);

  /// `detail.status === "issued"` — `:148`.
  ///
  /// Gates the B5 `documentActions` and `certificatePanel` seams (§ 6.1).
  /// Note it is **not** `bucket == approved`: `registered` is approved and is
  /// not issued, and the source distinguishes them here.
  bool get isIssued => row.status == CaseStatus.issued;

  /// `detail.payment_state === "pending" && detail.fee_lak > 0` — `:251`.
  ///
  /// Gates the B6 `paymentAction` and `paymentPanel` seams. Both halves matter:
  /// a `pending` case with a zero fee offers nothing to pay, which is why the
  /// `> 0` is in the source and is asserted separately (`B7-AC-52`).
  bool get canPay =>
      row.paymentState == PaymentState.pending && row.feeLak > 0;

  /// `bucket === "rejected" && detail.reason_note` — `:441`.
  ///
  /// **Both halves**, and the second is falsy-on-empty: a `reason_note: ""`
  /// renders no card at all rather than an empty red panel (`B7-AC-59`).
  bool get showsRejectionNote =>
      bucket == StatusBucket.rejected &&
      row.reasonNote != null &&
      row.reasonNote!.isNotEmpty;

  /// `detail.due_at && bucket === "pending"` — `:500`.
  ///
  /// The ETA chip is **not** shown for an overdue approved case or a rejected
  /// one, even when `due_at` is set (`B7-AC-68`).
  bool get showsEta =>
      row.dueAt != null &&
      row.dueAt!.isNotEmpty &&
      bucket == StatusBucket.pending;
}

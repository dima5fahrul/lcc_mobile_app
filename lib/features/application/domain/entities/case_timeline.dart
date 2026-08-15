/// `CaseTimeline` — `GET /applications/{id}/timeline`.
///
/// Ported verbatim from `lcc-app/src/app/api/types.ts:493-498`:
///
/// ```ts
/// export interface CaseTimeline {
///   application_id: string;
///   reference_no: string;
///   status: CaseStatus;
///   events: CaseEvent[];
/// }
/// ```
///
/// ## Only `events` is read, and the other three are carried anyway
///
/// `HistoryDetailPage.tsx:249` reads `timelineQuery.data?.events` and nothing
/// else off this envelope — the reference number and status on screen come from
/// the **detail** payload, not from here. The other three fields are parsed on
/// `application_row.dart`'s every-field rule, and they are worth more than
/// usual on this particular type: they are the only thing that could ever show
/// that the timeline being rendered belongs to a different case than the detail
/// beside it.
///
/// ## Shared with B4 — recorded so two batches do not define it twice
///
/// `/applications/:id/timeline` and `/status-catalogue` are the two endpoints
/// B7 shares with B4 (`ssd.md` § 5.1 re-sequences B4 to run last as a
/// consolidation batch). This entity and `case_event.dart` are therefore the
/// B4-facing half of B7b's addition: B4 **absorbs and extends** them the way
/// § 6.2 rules for the read slice as a whole, and adds `allowed_actions` — the
/// field `application_detail.dart` deliberately omits — rather than starting a
/// parallel timeline model.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'case_event.dart';
import 'case_status.dart';

part 'case_timeline.freezed.dart';

@freezed
abstract class CaseTimeline with _$CaseTimeline {
  const factory CaseTimeline({
    required String applicationId,
    required String referenceNo,
    required CaseStatus status,
    @Default(<CaseEvent>[]) List<CaseEvent> events,
  }) = _CaseTimeline;

  const CaseTimeline._();

  /// The all-absent envelope — what a non-object body parses to, mirroring
  /// `StatusPipeline.seeded`'s role in the catalogue read.
  static const CaseTimeline empty = CaseTimeline(
    applicationId: '',
    referenceNo: '',
    status: CaseStatus.unknown,
  );
}

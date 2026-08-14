/// The stages a citizen sees a case move through — `GET /status-catalogue`'s
/// `pipeline_order`, with `draft` removed.
///
/// Ports `lcc-app/src/app/statusCatalogue.ts`. Three of that file's four
/// behaviours are here; the fourth (its module-level cache and
/// mutate-in-place, `:16`) is not, because Flutter has a BLoC holding the
/// value and does not need the exported-array-identity trick React's
/// import-time capture forces.
///
/// ## The three ported rules, each of which is separately assertable
///
/// 1. **`draft` is filtered out** (`:59`). The API opens `pipeline_order` with
///    `draft`; this app does not, *"a draft has not entered the pipeline at
///    all"* (`:10-13`). Measured live today the API sends 6 entries and the UI
///    counts against **5** — which is why the row copy reads "Step 1 of 5".
/// 2. **An empty or draft-only answer keeps the seed** (`:60-61`):
///    `if (order.length > 0) PIPELINE.splice(...)`. Wiping the bar because the
///    backend sent nothing is the failure this guard exists to prevent.
/// 3. **A failed fetch is swallowed** (`:67-69`) — *"Offline or the API is
///    down — the seeded order above is the fallback."* The page still renders.
///
/// ## What is NOT ported
///
/// `STATUS_META` and `statuses[]` (`:35`, `:63`). Written, never read — see
/// `case_status.dart`'s library doc and specs.md § 6.9.
///
/// **And the catalogue's colours are ignored.** Every status the live endpoint
/// returns carries `color` and `background`, and both components discard them
/// in favour of the hardcoded 3-bucket palettes (`HistoryPage.tsx:42-46`,
/// `HistoryDetailPage.tsx:111-133`). Using the API's would be a visible
/// divergence, so this entity does not even carry them.
library;

import 'package:equatable/equatable.dart';

import 'case_status.dart';

/// `statusCatalogue.ts:24` — the stage a case is in before it has entered the
/// pipeline, and the one value rule 1 above strips.
const CaseStatus kPrePipeline = CaseStatus.draft;

/// `statusCatalogue.ts:27-33` — `export const PIPELINE`.
///
/// The *initial* state so a progress bar never renders blank, and the fallback
/// when the backend cannot be reached. Byte-identical to the 5 the live
/// endpoint yields today after `draft` is stripped, which is what makes rule 2
/// invisible in practice and worth asserting anyway.
const List<CaseStatus> kSeededPipeline = <CaseStatus>[
  CaseStatus.submitted,
  CaseStatus.certified,
  CaseStatus.underReview,
  CaseStatus.registered,
  CaseStatus.issued,
];

class StatusPipeline extends Equatable {
  const StatusPipeline(this.stages);

  /// The seed — `PIPELINE` before any fetch, and after a failed one.
  static const StatusPipeline seeded = StatusPipeline(kSeededPipeline);

  /// The ordered stages, `draft` already removed. Never empty.
  final List<CaseStatus> stages;

  /// `pipeline.length` — the denominator of "Step *n* of **5**"
  /// (`HistoryPage.tsx:335`) and of `progressOf`'s percentage.
  int get length => stages.length;

  /// Applies rules 1 and 2 to a raw `pipeline_order` from the wire.
  ///
  /// ```ts
  /// const order = (cat?.pipeline_order ?? []).filter((s) => s !== PRE_PIPELINE);
  /// if (order.length > 0) PIPELINE.splice(0, PIPELINE.length, ...order);
  /// ```
  ///
  /// A `null`, empty, or draft-only answer therefore returns [seeded] — the
  /// same object the offline path uses, so the two indistinguishable-to-the-
  /// citizen outcomes are also indistinguishable to a caller.
  ///
  /// Unknown statuses are **kept**, not dropped: the source splices whatever
  /// the API sent, and a stage this build does not recognise still occupies a
  /// slot in the count. Dropping it would silently renumber every later step.
  factory StatusPipeline.fromOrder(List<CaseStatus>? order) {
    final List<CaseStatus> filtered = (order ?? const <CaseStatus>[])
        .where((CaseStatus s) => s != kPrePipeline)
        .toList(growable: false);
    return filtered.isEmpty ? seeded : StatusPipeline(filtered);
  }

  /// `progressOf(status)` against *this* pipeline — see `case_status.dart`.
  int progressFor(CaseStatus status) => progressOf(status, stages);

  /// `Math.max(1, stage + 1)` — `HistoryPage.tsx:334`.
  ///
  /// **This is deliberately inconsistent with [progressFor] and the
  /// inconsistency is the source's.** A `draft` row has `indexOf` `-1`, so the
  /// counter clamps to **1** and reads "Step 1 of 5" while the bar next to it
  /// shows **8 %** (`progressOf`'s second branch). Porting one and not the
  /// other would be the port quietly correcting its source; specs.md § 6.15
  /// rules it ported as measured, and an AC pins both numbers together.
  int stepFor(CaseStatus status) {
    final int stage = stages.indexOf(status);
    return stage + 1 < 1 ? 1 : stage + 1;
  }

  @override
  List<Object?> get props => <Object?>[stages];
}

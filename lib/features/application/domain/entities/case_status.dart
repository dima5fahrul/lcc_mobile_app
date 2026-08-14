/// The case lifecycle's two wire enums, and the three buckets the citizen UI
/// paints them in.
///
/// Ported from `lcc-app/src/app/api/types.ts:25-36`:
///
/// ```ts
/// export type CaseStatus =
///   | "draft" | "submitted" | "certified" | "under-review"
///   | "returned" | "registered" | "issued" | "rejected" | "revoked";
/// export type PaymentState = "paid" | "pending" | "failed" | "refunded" | "free";
/// ```
///
/// Confirmed against the **live** anonymous `/status-catalogue` recorded into
/// `test/fidelity/fixtures/api/status-catalogue.json` while building B7a: the
/// API's nine `statuses[].status` values are exactly these nine, in this order.
///
/// ## Why there is a tenth member
///
/// [CaseStatus.unknown] has no counterpart in the source, because TypeScript
/// does not need one — a wire value outside the union simply flows through as a
/// string, `bucketOf` falls to its `pending` default and
/// `pipelineOrder.indexOf` answers `-1`. A Dart `enum` cannot express "a value
/// I have not heard of", so the alternative to this member is a parse that
/// **throws** on a status the backend adds after this build ships, taking the
/// whole list down over one row.
///
/// [unknown] is therefore not a new behaviour, it is the Dart spelling of the
/// source's existing one: it buckets as [StatusBucket.pending] (the `return
/// "pending"` fallback at `HistoryDetailPage.tsx:53`) and it is absent from the
/// pipeline, so `progressOf` gives it the same nominal 8 % sliver `draft` gets
/// (`:60`). Both are asserted, not assumed.
///
/// ## What is deliberately NOT here
///
/// `StatusMeta`, its `transitions[]`, `acting_role`, `color` and `background`
/// (`types.ts:38-58`). `statusCatalogue.ts:63` populates `STATUS_META` and
/// `grep -rn "STATUS_META" src/**` finds only its declaration, its doc comment
/// and that write — **nothing reads it** (specs.md § 2.2 Finding E, § 6.9).
/// Modelling it would port the catalogue's richest object for zero consumers.
/// B4 will need it for `allowed_actions` and adds it additively.
library;

/// `types.ts:25-34` — the nine backend statuses.
enum CaseStatus {
  draft('draft'),
  submitted('submitted'),
  certified('certified'),
  underReview('under-review'),
  returned('returned'),
  registered('registered'),
  issued('issued'),
  rejected('rejected'),
  revoked('revoked'),

  /// Not a wire value. See the library doc — the Dart spelling of TypeScript's
  /// "a string outside the union".
  unknown('');

  const CaseStatus(this.wire);

  /// The exact string the API sends and expects. `under-review` is hyphenated
  /// on the wire and camelCased in Dart, which is the one place the two names
  /// differ and the reason this field exists rather than `name`.
  final String wire;

  /// The nine real statuses, in `types.ts` declaration order. [unknown] is
  /// excluded — it is a parser artefact, not a status.
  static const List<CaseStatus> wireValues = <CaseStatus>[
    draft,
    submitted,
    certified,
    underReview,
    returned,
    registered,
    issued,
    rejected,
    revoked,
  ];

  /// Wire string → status, [unknown] for anything else.
  static CaseStatus fromWire(String? value) {
    for (final CaseStatus s in wireValues) {
      if (s.wire == value) return s;
    }
    return unknown;
  }
}

/// `types.ts:36` — the five payment states.
enum PaymentState {
  paid('paid'),
  pending('pending'),
  failed('failed'),
  refunded('refunded'),
  free('free'),

  /// The same escape hatch [CaseStatus.unknown] is, for the same reason.
  ///
  /// It matters slightly more here: `paymentLabel`'s table lookup
  /// (`HistoryDetailPage.tsx:73`) has an explicit `?? ["—", "—"]` fallback, so
  /// the source **does** have a rendered inhabitant for "not one of the five"
  /// and this member is what reaches it.
  unknown('');

  const PaymentState(this.wire);

  final String wire;

  /// The five real states, in `types.ts` declaration order.
  static const List<PaymentState> wireValues = <PaymentState>[
    paid,
    pending,
    failed,
    refunded,
    free,
  ];

  static PaymentState fromWire(String? value) {
    for (final PaymentState s in wireValues) {
      if (s.wire == value) return s;
    }
    return unknown;
  }
}

/// `HistoryDetailPage.tsx:39` — `type StatusBucket = "approved" | "rejected" |
/// "pending"`. Nine statuses collapse into the three the citizen UI paints.
enum StatusBucket { approved, rejected, pending }

/// `bucketOf(status)` — `HistoryDetailPage.tsx:50-54`, verbatim:
///
/// ```ts
/// if (status === "issued" || status === "registered") return "approved";
/// if (status === "rejected" || status === "revoked" || status === "returned") return "rejected";
/// return "pending";
/// ```
///
/// Note `returned` buckets as **rejected** here while also sitting in the
/// `rejected` filter chip (`HistoryPage.tsx:53`) — consistent. `draft` buckets
/// as `pending`, is in the `pending` chip (`:51`), and is **absent from the
/// pipeline**; that three-way interaction is what makes [progressOf]'s second
/// branch reachable.
StatusBucket bucketOf(CaseStatus status) {
  if (status == CaseStatus.issued || status == CaseStatus.registered) {
    return StatusBucket.approved;
  }
  if (status == CaseStatus.rejected ||
      status == CaseStatus.revoked ||
      status == CaseStatus.returned) {
    return StatusBucket.rejected;
  }
  return StatusBucket.pending;
}

/// `progressOf(status)` — `HistoryDetailPage.tsx:57-62`, verbatim, in order:
///
/// 1. a rejected-bucket case is **100** — a *full* bar, painted red.
/// 2. a status the pipeline does not carry is **8** — the `draft` case: a
///    nominal sliver, deliberately neither `0` nor a first step.
/// 3. otherwise `round(((stage + 1) / pipeline.length) * 100)`.
///
/// [pipeline] is the live order, `draft` already removed — see
/// `status_pipeline.dart`. With today's live 5-entry pipeline that is
/// `submitted` 20, `certified` 40, `under-review` 60, `registered` 80,
/// `issued` 100.
///
/// `Math.round` and Dart's `num.round()` differ on exact `.5` for **negative**
/// numbers only (JS rounds toward +∞, Dart away from zero); this expression is
/// non-negative for every input, so the two agree everywhere it can be called.
int progressOf(CaseStatus status, List<CaseStatus> pipeline) {
  if (bucketOf(status) == StatusBucket.rejected) return 100;
  final int stage = pipeline.indexOf(status);
  if (stage < 0) return 8;
  return ((stage + 1) / pipeline.length * 100).round();
}

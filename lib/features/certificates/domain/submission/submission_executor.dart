/// Runs a [SubmissionPlan] — RULING 4 (specs.md § 6.5), and the only new
/// production file in B4.
///
/// ## What this is, in one sentence
///
/// It owns **order**; the page owns **bodies and conditions**.
///
/// `submission_step.dart:1-11` drew that line before this file existed: *"The
/// plan records only that a step is or is not in the sequence, and in what
/// order. The condition under which a step runs belongs to the page."* This
/// executor honours it literally. It walks [SubmissionPlan.steps], and every
/// byte it puts on the wire arrives from the caller already built.
///
/// ## Why this is not the thing `ADR-0003` cancelled
///
/// F0 § 6.2.1 refused a **strategy-dispatched payload builder** — a mechanism
/// that *computes* what goes in a body. This computes nothing that reaches a
/// body. It receives the page's `buildFormData` transcription and the page's
/// `*Envelope` functions, and decides only which call happens next. A reader
/// worried that the dynamic renderer has re-entered through the data layer
/// should check exactly one thing: no method below constructs a map that
/// reaches a request. [_bind] copies one; it does not compose one.
///
/// ## Why it exists at all
///
/// Seven of `SubmissionPlan`'s eight fields were read by nothing
/// (specs.md § 2.2 Finding H). This programme's settled disposition for
/// declared-and-unread is deletion — `STATUS_META` (B7), `deleteNotification`
/// (B9), `/verify/document-hash` (B5) — and deleting `steps`,
/// `attachmentGuard`, `createEnvelope`, `updateEnvelope` and `methodCode` would
/// discard facts F0a derived independently and break
/// `submission_plan_oracle_test.dart`'s double entry. Execution is the
/// remaining option.
///
/// ## The six obligations, each a place where "tidier" would change behaviour
///
/// 1. **Walk `plan.steps` in declared order.** Three orders across five forms;
///    the executor reads the order, it does not know it.
/// 2. **Skip `create` when a draft is already held** and reuse its
///    `{id, reference_no}` (`ResidentCertificatePage.tsx:505` `if (!current)`,
///    `MarriageCertificatePage.tsx:956` `if (!id)`).
/// 3. **Run `update` on every attempt including the first** — it is what writes
///    the case reference (`F1-AC-57`).
/// 4. **Upload sequentially, in the caller's order, honouring
///    [SubmissionPlan.attachmentGuard]** — never `Future.wait` (`F1-AC-58`).
///    The two guards differ in loop *shape*, not only in key: see
///    [AttachmentLedger].
/// 5. **Do not cache the nested payload.** [CaseReferenceBinding] carries the
///    invocation count, and it differs by family and by attempt — see [_bind].
/// 6. **Invoke `pay` only where `plan.steps` contains it, and only when the
///    page's own predicate says so.** The predicate stays in the page: this
///    file asks no question about fees or payment state, and `B4-AC-19` fails
///    if a later hand unifies the three predicates into one here.
///
/// ## What it deliberately does not do
///
/// No retry, no backoff, no partial rollback, no idempotency key. Every one of
/// those would be a better client than the web has on the path that moves a
/// citizen's money, which is the class of silent improvement `ADR-0001`
/// forbids. A failed step throws [SubmissionStepFailure] and the page decides.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../application/domain/entities/application_detail.dart';
import '../../../application/domain/entities/picked_attachment.dart';
import 'attachment_guard.dart';
import 'case_reference_binding.dart';
import 'envelope_shape.dart';
import 'method_code_source.dart';
import 'submission_plan.dart';
import 'submission_step.dart';

/// `POST /applications` — the envelope arrives built and ordered.
typedef CreateCasePort = Future<Either<Failure, ApplicationDetail>> Function(
  Map<String, Object?> envelope,
);

/// `PATCH /applications/{id}`.
typedef UpdateCasePort = Future<Either<Failure, ApplicationDetail>> Function(
  String id,
  Map<String, Object?> envelope,
);

/// `POST /applications/{id}/attachments`, once per file.
///
/// Takes the whole [SubmissionAttachment] rather than four positional
/// arguments so that each page's adapter destructures it the way its own
/// use case wants — Resident's takes an `AddAttachmentParams`, Marriage's takes
/// a positional file plus a **required** `label` the flat family never sends.
typedef AttachCasePort = Future<Either<Failure, Object?>> Function(
  String id,
  SubmissionAttachment attachment,
);

/// `POST /applications/{id}/submit`, body `{}`. Answers the **decided** case.
typedef SubmitCasePort = Future<Either<Failure, ApplicationDetail>> Function(
  String id,
);

/// The page's whole pay branch, as one function.
///
/// **The predicate is inside this closure, not in the executor** (§ 6.7).
/// Resident charges on `fee_lak > 0` alone; Marriage and Divorce add
/// `payment_state != paid`; Birth and Death never reach here because their
/// plans omit the step. Answers the receipt number, or null when the page did
/// not charge, charged and got no receipt, or holds no pay port at all — three
/// different situations that the source renders identically
/// (`ResidentCertificatePage.tsx:637-639` makes the receipt row conditional).
///
/// It is handed the **draft** as well as the decided case because the source
/// charges `current.id` — the id it created — not `decided.id`
/// (`ResidentCertificatePage.tsx:536`). The two are the same case, and reading
/// the id off the submit answer instead would be a port that trusts the server
/// to echo an identifier where the source does not.
typedef ChargeCasePort = Future<Either<Failure, String?>> Function(
  SubmissionDraft draft,
  ApplicationDetail decided,
);

/// The retained `{id, reference_no}` of a case that has already been created.
///
/// A **held** draft is what makes a retry a retry: the create branch is skipped
/// and these two values are reused, so a rejected submission leaves no trail of
/// half-filled cases (`F1-AC-56`, `F3-AC-61`).
class SubmissionDraft {
  const SubmissionDraft({required this.id, required this.referenceNo});

  final String id;

  /// The server-minted reference. It does not exist until create answers, which
  /// is why every form PATCHes a second body carrying it.
  final String referenceNo;
}

/// One file on its way to `POST /applications/{id}/attachments`.
///
/// [label] is the source's optional fourth multipart part
/// (`endpoints.ts:349-350`): Marriage and Divorce send it, Resident, Birth and
/// Death do not. **Absent means absent** — an empty string is a part the web
/// does not send.
class SubmissionAttachment {
  const SubmissionAttachment({
    required this.file,
    required this.slot,
    required this.kind,
    this.label,
  });

  final PickedAttachment file;

  /// The schema key this file answers — `"applicant.photo"`, …
  final String slot;

  /// `"photo"` or `"document"`. The **slot's** kind, never the file's (R-21).
  final String kind;

  final String? label;
}

/// What one run of the plan produced.
///
/// A return shape, not a wire shape: no `freezed`, no `fromJson`, no
/// `@JsonKey` (specs.md § 5.2).
class SubmissionOutcome {
  const SubmissionOutcome({
    required this.decided,
    required this.draft,
    this.receiptNo,
  });

  /// The case as `submit` answered it. Its `fee_lak`, `reference_no`,
  /// `subject_name` and `status_label` are the success card's four rows.
  final ApplicationDetail decided;

  /// The draft this run used — created on the first attempt, reused after.
  final SubmissionDraft draft;

  /// Null when the plan has no pay step, the page's predicate declined, or the
  /// charge carried no receipt.
  final String? receiptNo;
}

/// A step failed, and **which** step is part of the signal.
///
/// The five pages route a failure differently by step: Marriage's create
/// failure emits a plain message while its update/submit/pay failures go
/// through `_fail`, which decodes field errors and flips `showErrors`
/// (`marriage_form_cubit.dart`). An executor that threw a bare `Failure` would
/// force every page to collapse those into one branch, which is a behaviour
/// change wearing a refactor's clothes.
class SubmissionStepFailure implements Exception {
  const SubmissionStepFailure(this.step, this.failure);

  final SubmissionStep step;
  final Failure failure;

  @override
  String toString() => 'SubmissionStepFailure(${step.name}: ${failure.message})';
}

/// The page's already-sent bookkeeping, in the two shapes the source keeps it.
///
/// **The two guards are different loop shapes, not two spellings of one.**
/// That distinction is invisible in the enum and is the whole reason this class
/// exists rather than a `Set<String>` parameter:
///
/// * [AttachmentGuard.slotKeyed] — Resident checks **per file**, inside the
///   loop, and marks each as it goes (`ResidentCertificatePage.tsx:526-530`).
///   A failure on file 3 leaves files 1-2 marked, so the retry sends 3-5.
/// * [AttachmentGuard.singleFlag] — Marriage wraps the **whole loop** in
///   `if (!attachmentsSent)` and sets the flag **after** it
///   (`MarriageCertificatePage.tsx:972-977`). A failure on file 3 leaves the
///   flag false, so the retry re-sends **everything**, files 1-2 included.
///
/// Collapsing these into "mark each file as sent" would change the second
/// family's retry from four uploads to zero, silently.
///
/// ## The slot-keyed family keys on the SLOT, and D-I is not fixed here
///
/// `attachment_guard.dart:24-28` records that keying on the slot name is the
/// D-I defect — replacing a file in an already-sent slot skips the upload, so
/// the citizen's second choice never reaches the API — and states the fix as a
/// requirement on the *implementation*. **B4 does not apply it.** F1 shipped
/// Resident, Birth and Death slot-keyed, and § 4.2 freezes every byte on the
/// wire: making the executor key on file identity would fix a real defect and
/// would change the retry behaviour of three shipped forms in a batch whose
/// whole claim is that it changes none. It is the `L-10`(b) failure mode —
/// better than the source — and it would be invisible to every existing test.
/// F3 applied the fix to Marriage and Divorce *in the page*, where it belongs;
/// [invalidateAllSent] is the seam it reaches this ledger through.
///
/// It is a mutable object held by the page for exactly as long as the page
/// lives, because the source's guards are a `useRef` and a `useState` — per
/// page instance, never persisted (`specs.md` § 6.3 item 3).
class AttachmentLedger {
  /// Slot names already sent, for [AttachmentGuard.slotKeyed].
  final Set<String> _sentSlots = <String>{};
  bool _allSent = false;

  /// Test-visible copy — the shape `ResidentFormCubit.uploadedSlots` exposes
  /// for `F1-AC-58`.
  Set<String> get sentSlots => Set<String>.unmodifiable(_sentSlots);

  bool get allSent => _allSent;

  /// Forgets that the whole set was sent — the [AttachmentGuard.singleFlag]
  /// family's D-I seam. The page decides *when* the identity set has changed
  /// (`marriage_form_cubit.dart`'s `_sameIdentities`); this only records the
  /// consequence, because file identity is page data and the executor has no
  /// business deciding what makes two picked files the same.
  void invalidateAllSent() => _allSent = false;
}

/// Walks a [SubmissionPlan] against the four write ports.
///
/// Constructed with the ports (the same four for every form) and run with the
/// per-form inputs. **Five per-form inputs beyond the plan** — `buildFormData`,
/// `createEnvelope`, `updateEnvelope`, `attachments`, `charge` — against
/// § 6.7's ceiling of six. The three remaining parameters (`held`, `ledger`,
/// `onDraftCreated`) are the page's own submission *state*, the `useState` and
/// `useRef` the source keeps across attempts, not a description of the form.
class SubmissionExecutor {
  const SubmissionExecutor({
    required this.createCase,
    required this.updateCase,
    required this.attachToCase,
    required this.submitCase,
  });

  final CreateCasePort createCase;
  final UpdateCasePort updateCase;
  final AttachCasePort attachToCase;
  final SubmitCasePort submitCase;

  /// Runs [plan]'s declared steps, in order.
  ///
  /// Throws [SubmissionStepFailure] on the first step that answers a `Left`.
  /// Nothing is rolled back — the source does not roll back either, and the
  /// held draft is what makes the next attempt cheap.
  Future<SubmissionOutcome> run({
    required SubmissionPlan plan,
    required Map<String, Object?> Function(String reference) buildFormData,
    required Map<String, Object?> Function(Map<String, Object?> payload)
        createEnvelope,
    required Map<String, Object?> Function(Map<String, Object?> updatePayload)
        updateEnvelope,
    required List<SubmissionAttachment> attachments,
    required AttachmentLedger ledger,
    SubmissionDraft? held,
    void Function(SubmissionDraft draft)? onDraftCreated,
    ChargeCasePort? charge,
  }) async {
    // Double entry between two registries of the same fact, written by two
    // dispatches: `SubmissionPlan`'s per-plan `methodCode:` and
    // `methodCodeSourceFor`'s exhaustive switch. Debug-only, because a
    // disagreement is a programming error rather than a citizen-facing one —
    // and because a release build must not pay for it.
    assert(
      plan.methodCode == methodCodeSourceFor(plan.form),
      'plan.methodCode (${plan.methodCode}) disagrees with '
      'methodCodeSourceFor(${plan.form}) '
      '(${methodCodeSourceFor(plan.form)}) — two registries of one fact have '
      'drifted',
    );

    final CaseReferenceBinding binding = plan.reference;

    // The create body.
    //
    // The FLAT family builds it once per attempt, before anything, and spreads
    // that same object into the update (`ResidentCertificatePage.tsx:501`) — so
    // it is needed on a retry too, when no create will run.
    //
    // The NESTED family builds it INSIDE the create branch
    // (`MarriageCertificatePage.tsx:964`) and builds the update body
    // separately, so on a retry it builds once, not twice. Building it
    // unconditionally here would add an invocation the source does not make;
    // the value would be discarded, but each invocation re-reads the clock
    // (`case_reference_binding.dart:19-25`) and the count is `F0-AC-14`.
    final Map<String, Object?>? createPayload =
        (!binding.rebuildsPayload || held == null) ? buildFormData('') : null;

    SubmissionDraft? draft = held;
    ApplicationDetail? decided;
    String? receiptNo;

    for (final SubmissionStep step in plan.steps) {
      switch (step) {
        case SubmissionStep.create:
          // Obligation 2 — skipped outright when a draft is held.
          if (draft != null) continue;
          final ApplicationDetail created = await _orThrow(
            step,
            () => createCase(_checked(
              plan.createEnvelope,
              createEnvelope(_withoutOfficeUse(createPayload!)),
            )),
          );
          draft = SubmissionDraft(
            id: created.row.id,
            referenceNo: created.row.referenceNo,
          );
          // Handed back BEFORE the next step runs, so a failure between here
          // and submit still leaves the page holding the draft. Persisting it
          // only on success would create a second case on every retry.
          onDraftCreated?.call(draft);

        case SubmissionStep.update:
          // Obligation 3 — every attempt, including the first, outside any
          // guard.
          final SubmissionDraft d = _require(step, draft);
          await _orThrow(
            step,
            () => updateCase(
              d.id,
              _checked(
                plan.updateEnvelope,
                updateEnvelope(_withoutOfficeUse(_bind(
                  binding,
                  createPayload,
                  d.referenceNo,
                  buildFormData,
                ))),
              ),
            ),
          );

        case SubmissionStep.attach:
          await _attach(plan, _require(step, draft), attachments, ledger);

        case SubmissionStep.submit:
          decided = await _orThrow(
            step,
            () => submitCase(_require(step, draft).id),
          );

        case SubmissionStep.pay:
          // Obligation 6. Reached only because `plan.steps` contains `pay`;
          // whether a charge actually happens is the closure's decision.
          final ChargeCasePort? port = charge;
          if (port == null) continue;
          if (decided == null) {
            throw StateError(
              'plan for ${plan.form.serviceCode} orders pay before submit; '
              'there is no decided case to charge against',
            );
          }
          final ApplicationDetail settled = decided;
          receiptNo = await _orThrow(
            step,
            () => port(_require(step, draft), settled),
          );
      }
    }

    if (decided == null || draft == null) {
      throw StateError(
        'plan for ${plan.form.serviceCode} completed without '
        '${draft == null ? 'creating a case' : 'submitting it'} — '
        'steps were ${plan.steps.map((SubmissionStep s) => s.name).toList()}',
      );
    }
    return SubmissionOutcome(
      decided: decided,
      draft: draft,
      receiptNo: receiptNo,
    );
  }

  /// Obligation 4 — the two guards, as two loop shapes. See [AttachmentLedger].
  Future<void> _attach(
    SubmissionPlan plan,
    SubmissionDraft draft,
    List<SubmissionAttachment> attachments,
    AttachmentLedger ledger,
  ) async {
    // Exhaustive, no `default` arm: a sixth guard must be a compile error here
    // rather than a silently skipped upload.
    switch (plan.attachmentGuard) {
      case AttachmentGuard.slotKeyed:
        // Per file, checked and marked inside the loop, keyed on the SLOT —
        // see [AttachmentLedger] for why D-I is not fixed here.
        for (final SubmissionAttachment a in attachments) {
          if (ledger._sentSlots.contains(a.slot)) continue;
          await _orThrow(
            SubmissionStep.attach,
            () => attachToCase(draft.id, a),
          );
          ledger._sentSlots.add(a.slot);
        }

      case AttachmentGuard.singleFlag:
        // The whole loop, flagged AFTER it. A failure part-way leaves the flag
        // false, so the retry re-sends everything — including the files that
        // already arrived. That is what the source does
        // (`MarriageCertificatePage.tsx:972-977`), and it is not a bug this
        // batch may fix.
        if (ledger._allSent) return;
        for (final SubmissionAttachment a in attachments) {
          await _orThrow(
            SubmissionStep.attach,
            () => attachToCase(draft.id, a),
          );
        }
        ledger._allSent = true;

      case AttachmentGuard.none:
        throw StateError(
          'plan for ${plan.form.serviceCode} lists an attach step under '
          'AttachmentGuard.none — the guard says this page has no uploader',
        );
    }
  }

  /// Obligation 5 — the update body, produced the way this family produces it.
  ///
  /// | | key count / order | builder invocations |
  /// |---|---|---|
  /// | flat | **+1 key, appended LAST** | **zero more** — the create payload is spread |
  /// | nested | unchanged count and order, one value replaced | **one more** — the builder is re-run |
  ///
  /// The nested arm calls the builder rather than `writeInto` because that is
  /// what the source does (`MarriageCertificatePage.tsx:981`
  /// `buildFormData(reference)`), and each invocation independently re-reads
  /// the clock. Hoisting it into one call and mutating the document number is
  /// the obvious refactor, and it changes behaviour at a midnight boundary.
  Map<String, Object?> _bind(
    CaseReferenceBinding binding,
    Map<String, Object?>? createPayload,
    String reference,
    Map<String, Object?> Function(String reference) buildFormData,
  ) {
    // Exhaustive over the sealed class — a third mechanic would be a compile
    // error here.
    switch (binding) {
      case final FlatAppendedReference f:
        // `appendTo` and not a local spread, so `flat-appended-last` stays in
        // exactly one place (`case_reference_binding.dart:104-112`).
        return f.appendTo(createPayload!, reference);
      case NestedParameterReference():
        return buildFormData(reference);
    }
  }

  /// The officer-only section, dropped where it is serialised.
  ///
  /// `MOBILE-API-E-CERTIFICATES.md` ("Officer-only fields"): the
  /// `office_use` section — a birth's family book, ICD-10 and manner of
  /// death — is set by officers only, and the server drops any key a citizen
  /// sends inside it, so the app neither renders nor sends it. The five
  /// payload builders never emit one, but a guard costs nothing where the
  /// envelope is finalised and guarantees the checklist's *"never send
  /// `office_use`"* holds even if a builder later grows one by accident.
  ///
  /// Both spellings a dotted `form_data` can carry are stripped:
  /// the flat leaf (`office_use.family_book`) and the nested section
  /// (`office_use: {icd10: …}`). Everything else — keys, values and their
  /// **insertion order** — survives untouched, because the wire bytes are
  /// `JSON.stringify`'s input order. When nothing matches the **caller's own
  /// map is returned unchanged** — the flat family re-spreads
  /// `createPayload` into the update, so a mutating copy would eat keys out
  /// from under the page.
  Map<String, Object?> _withoutOfficeUse(Map<String, Object?> formData) {
    bool isOfficeUse(String key) =>
        key == 'office_use' || key.startsWith('office_use.');
    if (!formData.keys.any(isOfficeUse)) return formData;
    return <String, Object?>{
      for (final MapEntry<String, Object?> e in formData.entries)
        if (!isOfficeUse(e.key)) e.key: e.value,
    };
  }

  /// Debug-only double entry between the page's transcribed envelope and the
  /// [EnvelopeShape] F0a derived by an independent scan of the same source
  /// lines. The first thing in `lib/` to read the shape at runtime.
  ///
  /// The rule is a **subsequence**, not an equality: an optional key spelled
  /// `x || undefined` is dropped by `JSON.stringify` when blank
  /// (`envelope_shape.dart:18-24`), so Resident's five-key create body is a
  /// legitimate reading of a six-key shape. What is never legitimate is a key
  /// out of declared order, an unknown key, or a missing non-optional one.
  ///
  /// Returns the envelope so it can wrap a call argument; the check runs inside
  /// an `assert` and is stripped from a release build.
  Map<String, Object?> _checked(
    EnvelopeShape shape,
    Map<String, Object?> envelope,
  ) {
    assert(() {
      final List<String> declared = shape.names;
      final List<String> actual = envelope.keys.toList(growable: false);
      int at = 0;
      for (final String key in actual) {
        final int found = declared.indexOf(key, at);
        if (found < 0) {
          throw StateError(
            'envelope key "$key" is not in the declared shape at or after '
            'position $at. Declared: $declared. Actual: $actual. Either the '
            'page transcribed a key the shape does not have, or it emitted '
            'them out of wire order.',
          );
        }
        at = found + 1;
      }
      for (final EnvelopeKey k in shape.keys) {
        if (!k.optional && !envelope.containsKey(k.name)) {
          throw StateError(
            'envelope is missing non-optional key "${k.name}". '
            'Declared: $declared. Actual: $actual.',
          );
        }
      }
      return true;
    }());
    return envelope;
  }

  /// `await` on a rejected promise throws; an `Either` does not. This is the
  /// one place the two are reconciled, so the walk above reads the way the
  /// five `submitCase` bodies read.
  Future<T> _orThrow<T>(
    SubmissionStep step,
    Future<Either<Failure, T>> Function() call,
  ) async {
    final Either<Failure, T> result = await call();
    return result.fold(
      (Failure f) => throw SubmissionStepFailure(step, f),
      (T value) => value,
    );
  }

  /// A step that needs a case id, reached before one exists.
  ///
  /// Only a malformed plan can produce this — every inhabitant of
  /// `SubmissionPlan.all` starts with `create` — so it is a `StateError` and
  /// not a [SubmissionStepFailure]: there is no citizen-facing sentence for
  /// "the plan is wrong."
  SubmissionDraft _require(SubmissionStep step, SubmissionDraft? draft) {
    if (draft != null) return draft;
    throw StateError(
      'step ${step.name} needs a case id, but no draft has been created — '
      'the plan orders it before create',
    );
  }
}

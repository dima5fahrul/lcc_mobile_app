/// What a certificate submission **is**, declared once so five pages cannot
/// each answer it differently — RULING 1 (specs.md § 6.2).
///
/// ## What this is not
///
/// It is not a `FormDataBuilder` with three strategies, and it is not a
/// 200-field `FormData` model. Both were considered and refused on four
/// measured grounds (specs.md § 6.2.1), the first of which is that a
/// strategy-dispatched payload builder is the dynamic renderer `ADR-0003`
/// already cancelled, re-entering through the data layer.
///
/// Each page's `buildFormData` is transcribed as **one hand-written Dart
/// function returning `Map<String, Object?>`**, living with its page in
/// `features/certificates/presentation/<page>/`. **F0 writes none of them**
/// (`F0-AC-20`) — F1, F2 and F3 do. F0 writes the contract they satisfy.
///
/// A literal Dart map transcribed from a literal TS object is diffable against
/// the source by eye in review and against the Tier 0 oracle by test. A
/// strategy that *computes* the same map is diffable against neither.
///
/// ## Everything below is measured, not designed
///
/// Every field of every inhabitant carries the `file:line` it was read from.
/// The Tier 0 oracles F0a derived by an **independent** scan of the same five
/// pages carry the same facts in their `createEnvelope` / `updateEnvelope` /
/// `refBinding` blocks, and
/// `test/features/certificates/domain/submission/submission_plan_oracle_test.dart`
/// compares the two. That is the double-entry `F0-AC-13` asks for: a mis-read
/// of `MarriageCertificatePage.tsx:957-989` has to be made **twice, by two
/// dispatches, in the same direction** to survive.
library;

import 'attachment_guard.dart';
import 'case_reference_binding.dart';
import 'certificate_form.dart';
import 'envelope_shape.dart';
import 'method_code_source.dart';
import 'submission_step.dart';

class SubmissionPlan {
  const SubmissionPlan({
    required this.form,
    required this.steps,
    required this.reference,
    required this.attachmentGuard,
    required this.createEnvelope,
    required this.updateEnvelope,
    required this.methodCode,
    required this.stepsSrc,
  });

  final CertificateForm form;

  /// Ordered, declared, **not executed by F0** — B4 owns the executor.
  ///
  /// Two retry mechanics this sequence does not show and a port will get wrong
  /// by being tidier than the source (specs.md § 6.2.6):
  ///
  /// 1. On a **retry** the create branch is skipped entirely
  ///    (`ResidentCertificatePage.tsx:505` `if (!current)`,
  ///    `MarriageCertificatePage.tsx:956` `if (!id)`) and the submission sends
  ///    **one** body, not two. Tier 0's two-bodies model describes the first
  ///    attempt only.
  /// 2. The nested family calls `buildFormData` **twice** and the flat family
  ///    **once** — carried by [reference], not by this list.
  final List<SubmissionStep> steps;

  /// How the case reference enters the second body. See
  /// [CaseReferenceBinding]: the two inhabitants differ in key count/order
  /// **and** in builder-invocation count.
  final CaseReferenceBinding reference;

  final AttachmentGuard attachmentGuard;

  /// `POST /applications` — ordered. Note `form_data` is **last** here and
  /// **first** in [updateEnvelope]. That is not a stylistic accident to be
  /// normalised; it is two different byte sequences, and Tier 0 compares bytes.
  final EnvelopeShape createEnvelope;

  /// `PATCH /applications/{id}` — ordered, `form_data` **first**.
  final EnvelopeShape updateEnvelope;

  final MethodCodeSource methodCode;

  /// Where [steps] was read from, and the two retry citations § 6.2.6 requires
  /// every plan to carry.
  final String stepsSrc;

  /// The five, keyed by `service_code`.
  ///
  /// **Exactly five.** FamilyBook is excluded by name and has **no**
  /// inhabitant: `FamilyBookPage.tsx:204` builds
  /// `me.requestFamilyBookCopy({reason})` and `:236` fires it with a bilingual
  /// constant — no case, no draft, no `form_data`, no attachment, no reference
  /// number. F4 must not be forced through this contract, and an implementer
  /// must not add a `CaseReferenceBinding.none` inhabitant to make it fit
  /// (specs.md § 6.2.4, `F0-AC-18`).
  static final Map<String, SubmissionPlan> all = Map<String, SubmissionPlan>
      .unmodifiable(<String, SubmissionPlan>{
    for (final CertificateForm f in CertificateForm.values) f.serviceCode: _of(f),
  });

  static SubmissionPlan forForm(CertificateForm form) => all[form.serviceCode]!;

  /// Exhaustive `switch`, **no `default` arm** — a sixth `CertificateForm`
  /// would be a compile error here rather than a missing map entry discovered
  /// at F3.
  static SubmissionPlan _of(CertificateForm form) {
    switch (form) {
      case CertificateForm.resident:
        return _resident;
      case CertificateForm.birth:
        return _birth;
      case CertificateForm.death:
        return _death;
      case CertificateForm.marriage:
        return _marriage;
      case CertificateForm.divorce:
        return _divorce;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// The flat family — Resident, Birth, Death
//
// `province_id` / `district_id` / `village_id` are written `x || undefined`, so
// `JSON.stringify` DROPS them when blank. Contrast Marriage/Divorce below,
// which write the raw value and are present-and-empty. Same three key names,
// two different bodies (`F0-AC-19`).
// ─────────────────────────────────────────────────────────────────────────────

const EnvelopeKey _serviceCode = EnvelopeKey('service_code');
const EnvelopeKey _formData = EnvelopeKey('form_data');

/// `province_id` / `district_id` / `village_id` in their **elidable** spelling.
const List<EnvelopeKey> _elidableLocation = <EnvelopeKey>[
  EnvelopeKey('province_id', optional: true, whenEmpty: WhenEmpty.elided),
  EnvelopeKey('district_id', optional: true, whenEmpty: WhenEmpty.elided),
  EnvelopeKey('village_id', optional: true, whenEmpty: WhenEmpty.elided),
];

/// …and in their **raw** spelling: present, and empty when blank.
const List<EnvelopeKey> _rawLocation = <EnvelopeKey>[
  EnvelopeKey('province_id'),
  EnvelopeKey('district_id'),
  EnvelopeKey('village_id'),
];

/// `{form_data, event_date}` — `form_data` FIRST. All five pages, identically
/// (`F0-AC-80`).
const EnvelopeShape _updateEnvelope = EnvelopeShape(<EnvelopeKey>[
  _formData,
  EnvelopeKey('event_date'),
]);

/// Marriage's and Divorce's update body: `event_date` is `x || undefined` here
/// too, so it is elidable where the flat family's is not.
const EnvelopeShape _nestedUpdateEnvelope = EnvelopeShape(<EnvelopeKey>[
  _formData,
  EnvelopeKey('event_date', optional: true, whenEmpty: WhenEmpty.elided),
]);

final SubmissionPlan _resident = SubmissionPlan(
  form: CertificateForm.resident,
  steps: const <SubmissionStep>[
    SubmissionStep.create,
    SubmissionStep.update,
    SubmissionStep.attach,
    SubmissionStep.submit,
    SubmissionStep.pay,
  ],
  // `ResidentCertificatePage.tsx:522` —
  // `form_data: { ...payload, "header.ref_no": current.reference_no }`.
  // The only page whose key is `ref_no` rather than `document_no`.
  reference: const CaseReferenceBinding.flatAppended('header.ref_no'),
  // `:457` `uploaded.current.has(attachment.slot)`.
  attachmentGuard: AttachmentGuard.slotKeyed,
  // `:507-513`.
  createEnvelope: const EnvelopeShape(<EnvelopeKey>[
    _serviceCode,
    ..._elidableLocation,
    EnvelopeKey('event_date'),
    _formData,
  ]),
  // `:521-524`.
  updateEnvelope: _updateEnvelope,
  // `:494-498` — picks by kind from the live `/payment-methods` list.
  methodCode: MethodCodeSource.liveList,
  stepsSrc: 'ResidentCertificatePage.tsx:500-541; retry skips create at :505 '
      '`if (!current)`; one builder invocation at :501',
);

final SubmissionPlan _birth = SubmissionPlan(
  form: CertificateForm.birth,
  // **Ends at submit.** Payment is a separate mutation the review step
  // triggers (`:847-853` `payCase`), not a step inside `submitCase`.
  steps: const <SubmissionStep>[
    SubmissionStep.create,
    SubmissionStep.update,
    SubmissionStep.attach,
    SubmissionStep.submit,
  ],
  // `BirthDeclarationPage.tsx:835`.
  reference: const CaseReferenceBinding.flatAppended('header.document_no'),
  // `:738`, `:840` — `uploaded.current.has("child.hospital_notice")`.
  attachmentGuard: AttachmentGuard.slotKeyed,
  // `:820-827`.
  createEnvelope: const EnvelopeShape(<EnvelopeKey>[
    _serviceCode,
    ..._elidableLocation,
    EnvelopeKey('event_date'),
    _formData,
  ]),
  // `:834-837`.
  updateEnvelope: _updateEnvelope,
  // `:809-813`.
  methodCode: MethodCodeSource.liveList,
  stepsSrc: 'BirthDeclarationPage.tsx:816-845; retry skips create at :819 '
      '`if (!current)`; one builder invocation at :817',
);

final SubmissionPlan _death = SubmissionPlan(
  form: CertificateForm.death,
  steps: const <SubmissionStep>[
    SubmissionStep.create,
    SubmissionStep.update,
    SubmissionStep.attach,
    SubmissionStep.submit,
  ],
  // `DeathDeclarationPage.tsx:859`.
  reference: const CaseReferenceBinding.flatAppended('header.document_no'),
  // `:762`, `:864`.
  attachmentGuard: AttachmentGuard.slotKeyed,
  // `:844-851`.
  createEnvelope: const EnvelopeShape(<EnvelopeKey>[
    _serviceCode,
    ..._elidableLocation,
    EnvelopeKey('event_date'),
    _formData,
  ]),
  // `:858-861`.
  updateEnvelope: _updateEnvelope,
  // `:833-837`.
  methodCode: MethodCodeSource.liveList,
  stepsSrc: 'DeathDeclarationPage.tsx:840-869; retry skips create at :843 '
      '`if (!current)`; one builder invocation at :841',
);

// ─────────────────────────────────────────────────────────────────────────────
// The nested family — Marriage, Divorce
//
// Note the step ORDER: create, **attach, update**, submit, pay. The flat family
// updates before it attaches. Both are transcribed as measured; neither is
// normalised toward the other.
// ─────────────────────────────────────────────────────────────────────────────

final SubmissionPlan _marriage = SubmissionPlan(
  form: CertificateForm.marriage,
  steps: const <SubmissionStep>[
    SubmissionStep.create,
    SubmissionStep.attach,
    SubmissionStep.update,
    SubmissionStep.submit,
    SubmissionStep.pay,
  ],
  // `MarriageCertificatePage.tsx:899` `document_no: caseReference` inside a
  // real `header` object — NOT the literal flat key `"header.document_no"`
  // Birth emits. The two flatten to the same dotted string and are different
  // wire bytes; mutant M5 tests exactly that.
  reference: const CaseReferenceBinding.nestedParameter(
    <String>['header', 'document_no'],
  ),
  // `:972-977` — one `attachmentsSent` boolean for the whole submission.
  attachmentGuard: AttachmentGuard.singleFlag,
  // `:957-965`. `linked_reference_no` sits BETWEEN `event_date` and
  // `form_data` and is elided when `linkedRecord` is null (`F0-AC-79`).
  createEnvelope: const EnvelopeShape(<EnvelopeKey>[
    _serviceCode,
    ..._rawLocation,
    EnvelopeKey('event_date', optional: true, whenEmpty: WhenEmpty.elided),
    EnvelopeKey(
      'linked_reference_no',
      optional: true,
      whenEmpty: WhenEmpty.elided,
    ),
    _formData,
  ]),
  // `:980-983`.
  updateEnvelope: _nestedUpdateEnvelope,
  // `:140-144` — the static map. No `/payment-methods` read.
  methodCode: MethodCodeSource.staticMap,
  stepsSrc: 'MarriageCertificatePage.tsx:952-990; retry skips create at :956 '
      '`if (!id)`; TWO builder invocations, :964 `buildFormData("")` and '
      ':981 `buildFormData(reference)`, each re-evaluating today() at :900',
);

final SubmissionPlan _divorce = SubmissionPlan(
  form: CertificateForm.divorce,
  steps: const <SubmissionStep>[
    SubmissionStep.create,
    SubmissionStep.attach,
    SubmissionStep.update,
    SubmissionStep.submit,
    SubmissionStep.pay,
  ],
  // `DivorceCertificatePage.tsx:799`.
  reference: const CaseReferenceBinding.nestedParameter(
    <String>['header', 'document_no'],
  ),
  // `:868-873`.
  attachmentGuard: AttachmentGuard.singleFlag,
  // `:853-861`.
  createEnvelope: const EnvelopeShape(<EnvelopeKey>[
    _serviceCode,
    ..._rawLocation,
    EnvelopeKey('event_date', optional: true, whenEmpty: WhenEmpty.elided),
    EnvelopeKey(
      'linked_reference_no',
      optional: true,
      whenEmpty: WhenEmpty.elided,
    ),
    _formData,
  ]),
  // `:876-879`.
  updateEnvelope: _nestedUpdateEnvelope,
  // `:125-129`.
  methodCode: MethodCodeSource.staticMap,
  stepsSrc: 'DivorceCertificatePage.tsx:848-886; retry skips create at :852 '
      '`if (!id)`; TWO builder invocations, :860 `buildFormData("")` and '
      ':877 `buildFormData(reference)`, each re-evaluating today() at :800',
);

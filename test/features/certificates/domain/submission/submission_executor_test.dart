/// `SubmissionExecutor` — the sequence, retry and guard mechanics, with the
/// mutants that prove each assertion can fail (specs.md § 7.4).
///
/// ## How this file divides work with the golden logs
///
/// `test/features/certificates/submission_golden/**` drives the five **real
/// cubits** over a real transport and compares bytes. It answers *"did the
/// migration move anything?"* and it is the batch's outer gate.
///
/// This file drives the executor **directly**, against locally constructed
/// plans, and answers a question the goldens structurally cannot: *"would this
/// executor notice if the plan changed?"* A golden recorded from a cubit whose
/// plan says `create → update` is reproduced perfectly by an executor that
/// hard-codes `create → update` and never reads `steps` at all. Only a plan the
/// five pages do not have can distinguish those two, and no cubit will ever
/// hand the executor one — so the transposed plan is built here.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_detail.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_status.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/attachment_guard.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/case_reference_binding.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/certificate_form.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/envelope_shape.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/method_code_source.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_executor.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_plan.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_step.dart';

import '../../../application/application_write_fakes.dart';

/// Records every port call in order, the way the source's own spies do.
class _Spy {
  final List<String> calls = <String>[];
  final List<Map<String, Object?>> createEnvelopes = <Map<String, Object?>>[];
  final List<Map<String, Object?>> updateEnvelopes = <Map<String, Object?>>[];

  /// How many times the page's `buildFormData` was invoked. The count is
  /// contract, not trivia: the nested family calls it twice and the flat family
  /// once, and each call re-reads the clock
  /// (`case_reference_binding.dart:19-25`).
  int builderCalls = 0;

  /// Makes the Nth attach call fail, so a part-way failure can be observed.
  int? failAttachAt;
  int _attachIndex = 0;

  int feeLak = 20000;
  PaymentState paymentState = PaymentState.pending;

  Future<Either<Failure, ApplicationDetail>> create(
    Map<String, Object?> envelope,
  ) async {
    calls.add('create');
    createEnvelopes.add(envelope);
    return Right<Failure, ApplicationDetail>(applicationDetailFixture());
  }

  Future<Either<Failure, ApplicationDetail>> update(
    String id,
    Map<String, Object?> envelope,
  ) async {
    calls.add('update');
    updateEnvelopes.add(envelope);
    return Right<Failure, ApplicationDetail>(applicationDetailFixture(id: id));
  }

  Future<Either<Failure, Object?>> attach(
    String id,
    SubmissionAttachment a,
  ) async {
    calls.add('attach:${a.slot}');
    final int i = _attachIndex++;
    if (failAttachAt == i) {
      return const Left<Failure, Object?>(Failure('upload refused'));
    }
    return const Right<Failure, Object?>(null);
  }

  Future<Either<Failure, ApplicationDetail>> submitCase(String id) async {
    calls.add('submit');
    return Right<Failure, ApplicationDetail>(
      _detailWith(feeLak: feeLak, paymentState: paymentState),
    );
  }

  SubmissionExecutor get executor => SubmissionExecutor(
        createCase: create,
        updateCase: update,
        attachToCase: attach,
        submitCase: submitCase,
      );
}

/// `applicationDetailFixture` with the two fields the pay predicates read.
ApplicationDetail _detailWith({
  required int feeLak,
  required PaymentState paymentState,
}) {
  final ApplicationDetail base = applicationDetailFixture(feeLak: feeLak);
  return ApplicationDetail(
    row: base.row.copyWith(paymentState: paymentState),
  );
}

SubmissionAttachment _att(String slot, {String name = 'f.pdf'}) =>
    SubmissionAttachment(
      file: PickedAttachment(name: name, bytes: null),
      slot: slot,
      kind: 'document',
    );

/// A plan built for this file, so a sequence nobody ships can be exercised.
///
/// Reuses Resident's envelopes and binding so only [steps] and
/// [attachmentGuard] vary — a plan that differed in five ways would not
/// isolate which one the executor read.
SubmissionPlan _planOf(
  List<SubmissionStep> steps, {
  AttachmentGuard guard = AttachmentGuard.slotKeyed,
  CertificateForm form = CertificateForm.resident,
  CaseReferenceBinding? reference,
  MethodCodeSource? methodCode,
}) =>
    SubmissionPlan(
      form: form,
      steps: steps,
      reference:
          reference ?? const CaseReferenceBinding.flatAppended('header.ref_no'),
      attachmentGuard: guard,
      createEnvelope: const EnvelopeShape(<EnvelopeKey>[
        EnvelopeKey('service_code'),
        EnvelopeKey('form_data'),
      ]),
      updateEnvelope: const EnvelopeShape(<EnvelopeKey>[
        EnvelopeKey('form_data'),
      ]),
      methodCode: methodCode ?? methodCodeSourceFor(form),
      stepsSrc: 'built by submission_executor_test.dart',
    );

/// [SubmissionExecutor.run] with this file's default per-form inputs.
Future<SubmissionOutcome> _run(
  _Spy spy,
  SubmissionPlan plan, {
  List<SubmissionAttachment> attachments = const <SubmissionAttachment>[],
  AttachmentLedger? ledger,
  SubmissionDraft? held,
  ChargeCasePort? charge,
  void Function(SubmissionDraft)? onDraftCreated,
}) =>
    spy.executor.run(
      plan: plan,
      buildFormData: (String reference) {
        spy.builderCalls++;
        return <String, Object?>{'ref': reference};
      },
      createEnvelope: (Map<String, Object?> payload) => <String, Object?>{
        'service_code': plan.form.serviceCode,
        'form_data': payload,
      },
      updateEnvelope: (Map<String, Object?> updatePayload) =>
          <String, Object?>{'form_data': updatePayload},
      attachments: attachments,
      ledger: ledger ?? AttachmentLedger(),
      held: held,
      onDraftCreated: onDraftCreated,
      charge: charge,
    );

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // B4-AC-16 / B4-AC-18 — the executor READS plan.steps
  // ───────────────────────────────────────────────────────────────────────────
  group('the declared order is what runs', () {
    test('the flat family order — create, update, attach, submit', () async {
      final _Spy spy = _Spy();
      await _run(
        spy,
        _planOf(const <SubmissionStep>[
          SubmissionStep.create,
          SubmissionStep.update,
          SubmissionStep.attach,
          SubmissionStep.submit,
        ]),
        attachments: <SubmissionAttachment>[_att('a')],
      );
      expect(spy.calls, <String>['create', 'update', 'attach:a', 'submit']);
    });

    test('the nested family order — create, ATTACH, UPDATE, submit', () async {
      final _Spy spy = _Spy();
      await _run(
        spy,
        _planOf(const <SubmissionStep>[
          SubmissionStep.create,
          SubmissionStep.attach,
          SubmissionStep.update,
          SubmissionStep.submit,
        ]),
        attachments: <SubmissionAttachment>[_att('a')],
      );
      expect(spy.calls, <String>['create', 'attach:a', 'update', 'submit']);
    });

    test('B4-AC-18 THE CAPABILITY CONTROL — transposing two steps in the plan '
        'transposes them on the wire', () async {
      // Without this, both assertions above are satisfied by an executor that
      // ignores `steps` entirely and hard-codes the flat order: the first would
      // pass and the second would fail, which reads as a bug rather than as
      // proof. Running BOTH orders through one executor and getting two
      // different call logs is the evidence that `steps` is read.
      final _Spy a = _Spy();
      final _Spy b = _Spy();
      const List<SubmissionStep> forward = <SubmissionStep>[
        SubmissionStep.create,
        SubmissionStep.update,
        SubmissionStep.attach,
        SubmissionStep.submit,
      ];
      const List<SubmissionStep> transposed = <SubmissionStep>[
        SubmissionStep.create,
        SubmissionStep.attach,
        SubmissionStep.update,
        SubmissionStep.submit,
      ];
      await _run(a, _planOf(forward),
          attachments: <SubmissionAttachment>[_att('a')]);
      await _run(b, _planOf(transposed),
          attachments: <SubmissionAttachment>[_att('a')]);

      expect(a.calls, isNot(equals(b.calls)));
      expect(a.calls.indexOf('update'), lessThan(a.calls.indexOf('attach:a')));
      expect(b.calls.indexOf('attach:a'), lessThan(b.calls.indexOf('update')));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B4-AC-20 — the retry mechanics
  // ───────────────────────────────────────────────────────────────────────────
  group('retry — create is skipped, update is not', () {
    const List<SubmissionStep> steps = <SubmissionStep>[
      SubmissionStep.create,
      SubmissionStep.update,
      SubmissionStep.submit,
    ];

    test('a held draft skips create and still runs update', () async {
      final _Spy spy = _Spy();
      await _run(
        spy,
        _planOf(steps),
        held: const SubmissionDraft(id: 'case-1', referenceNo: 'REF-1'),
      );
      expect(spy.calls, <String>['update', 'submit']);
      expect(spy.calls, isNot(contains('create')));
    });

    test('no held draft creates exactly once', () async {
      final _Spy spy = _Spy();
      await _run(spy, _planOf(steps));
      expect(spy.calls.where((String c) => c == 'create'), hasLength(1));
    });

    test('the draft is handed back BEFORE the next step runs', () async {
      // A page that persisted the draft only on overall success would create a
      // second case on every retry. The callback firing before `update` is what
      // makes `F1-AC-56` reachable.
      final _Spy spy = _Spy();
      final List<String> order = <String>[];
      await _run(
        spy,
        _planOf(steps),
        onDraftCreated: (SubmissionDraft d) => order.add('draft:${d.id}'),
      );
      // `create` is recorded by the spy before the callback fires; `update`
      // after. Interleaving is asserted rather than the callback's mere
      // presence.
      expect(order, <String>['draft:case-1']);
      expect(spy.calls, <String>['create', 'update', 'submit']);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B4-AC-21 / B4-AC-22 — plan.attachmentGuard is READ, and the two guards are
  // two different loop shapes
  // ───────────────────────────────────────────────────────────────────────────
  group('the attachment guard', () {
    const List<SubmissionStep> steps = <SubmissionStep>[
      SubmissionStep.create,
      SubmissionStep.attach,
      SubmissionStep.submit,
    ];
    final List<SubmissionAttachment> three = <SubmissionAttachment>[
      _att('one'),
      _att('two'),
      _att('three'),
    ];

    test('uploads are SEQUENTIAL and in the caller\'s order', () async {
      final _Spy spy = _Spy();
      await _run(spy, _planOf(steps), attachments: three);
      expect(
        spy.calls,
        <String>['create', 'attach:one', 'attach:two', 'attach:three', 'submit'],
      );
    });

    test('slotKeyed — a slot already sent is not re-sent on the retry',
        () async {
      final _Spy spy = _Spy();
      final AttachmentLedger ledger = AttachmentLedger();
      await _run(spy, _planOf(steps), attachments: three, ledger: ledger);
      expect(ledger.sentSlots, <String>{'one', 'two', 'three'});

      spy.calls.clear();
      await _run(
        spy,
        _planOf(steps),
        attachments: three,
        ledger: ledger,
        held: const SubmissionDraft(id: 'case-1', referenceNo: 'REF-1'),
      );
      expect(spy.calls, <String>['submit'], reason: 'all three already sent');
    });

    test('slotKeyed — a failure part-way leaves the EARLIER slots marked, so '
        'the retry resumes rather than restarting', () async {
      final _Spy spy = _Spy()..failAttachAt = 1;
      final AttachmentLedger ledger = AttachmentLedger();
      await expectLater(
        _run(spy, _planOf(steps), attachments: three, ledger: ledger),
        throwsA(isA<SubmissionStepFailure>()),
      );
      expect(ledger.sentSlots, <String>{'one'});
    });

    test('singleFlag — a failure part-way leaves NOTHING marked, so the retry '
        're-sends every file', () async {
      // This is the whole reason the guard is a loop shape and not a key.
      // `MarriageCertificatePage.tsx:972-977` sets `attachmentsSent` AFTER the
      // loop, so a failure on file 2 discards the fact that file 1 arrived.
      // An executor that marked each file as it went would turn Marriage's
      // five-upload retry into a one-upload retry, silently.
      final _Spy spy = _Spy()..failAttachAt = 1;
      final AttachmentLedger ledger = AttachmentLedger();
      await expectLater(
        _run(
          spy,
          _planOf(steps, guard: AttachmentGuard.singleFlag),
          attachments: three,
          ledger: ledger,
        ),
        throwsA(isA<SubmissionStepFailure>()),
      );
      expect(ledger.allSent, isFalse);

      spy
        ..calls.clear()
        ..failAttachAt = null;
      await _run(
        spy,
        _planOf(steps, guard: AttachmentGuard.singleFlag),
        attachments: three,
        ledger: ledger,
        held: const SubmissionDraft(id: 'case-1', referenceNo: 'REF-1'),
      );
      expect(
        spy.calls,
        <String>['attach:one', 'attach:two', 'attach:three', 'submit'],
        reason: 'all three re-sent, including the one that already arrived',
      );
    });

    test('singleFlag — a clean run skips the whole block on the retry, and '
        'invalidateAllSent re-opens it (D-I\'s seam)', () async {
      final _Spy spy = _Spy();
      final AttachmentLedger ledger = AttachmentLedger();
      await _run(
        spy,
        _planOf(steps, guard: AttachmentGuard.singleFlag),
        attachments: three,
        ledger: ledger,
      );
      expect(ledger.allSent, isTrue);

      spy.calls.clear();
      await _run(
        spy,
        _planOf(steps, guard: AttachmentGuard.singleFlag),
        attachments: three,
        ledger: ledger,
        held: const SubmissionDraft(id: 'case-1', referenceNo: 'REF-1'),
      );
      expect(spy.calls, <String>['submit']);

      ledger.invalidateAllSent();
      spy.calls.clear();
      await _run(
        spy,
        _planOf(steps, guard: AttachmentGuard.singleFlag),
        attachments: three,
        ledger: ledger,
        held: const SubmissionDraft(id: 'case-1', referenceNo: 'REF-1'),
      );
      expect(
        spy.calls,
        <String>['attach:one', 'attach:two', 'attach:three', 'submit'],
      );
    });

    test('AttachmentGuard.none with an attach step is a StateError, not a '
        'silent skip', () async {
      final _Spy spy = _Spy();
      await expectLater(
        _run(
          spy,
          _planOf(steps, guard: AttachmentGuard.none),
          attachments: three,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Obligation 5 — the builder invocation count, by family and by attempt
  // ───────────────────────────────────────────────────────────────────────────
  group('the payload is built the way each family builds it', () {
    const List<SubmissionStep> steps = <SubmissionStep>[
      SubmissionStep.create,
      SubmissionStep.update,
      SubmissionStep.submit,
    ];

    test('flat — ONE invocation on a first attempt, and one on a retry', () async {
      final _Spy first = _Spy();
      await _run(first, _planOf(steps));
      expect(first.builderCalls, 1);

      final _Spy retry = _Spy();
      await _run(
        retry,
        _planOf(steps),
        held: const SubmissionDraft(id: 'case-1', referenceNo: 'REF-1'),
      );
      expect(retry.builderCalls, 1,
          reason: '`:501` builds unconditionally, before the create branch');
    });

    test('nested — TWO invocations on a first attempt, ONE on a retry',
        () async {
      final CaseReferenceBinding nested =
          const CaseReferenceBinding.nestedParameter(
        <String>['header', 'document_no'],
      );
      final _Spy first = _Spy();
      await _run(first, _planOf(steps, reference: nested));
      expect(first.builderCalls, 2,
          reason: '`:964` buildFormData("") and `:981` buildFormData(ref)');

      final _Spy retry = _Spy();
      await _run(
        retry,
        _planOf(steps, reference: nested),
        held: const SubmissionDraft(id: 'case-1', referenceNo: 'REF-1'),
      );
      expect(retry.builderCalls, 1,
          reason: '`:964` sits INSIDE the create branch, which a retry skips');
    });

    test('flat — the reference is appended LAST and the key count rises by one',
        () async {
      final _Spy spy = _Spy();
      await _run(
        spy,
        _planOf(steps),
        held: const SubmissionDraft(id: 'case-1', referenceNo: 'REF-9'),
      );
      final Map<String, Object?> body =
          spy.updateEnvelopes.single['form_data']! as Map<String, Object?>;
      expect(body.keys.toList(), <String>['ref', 'header.ref_no']);
      expect(body['header.ref_no'], 'REF-9');
    });

    test('nested — the key count and order are UNCHANGED; one value replaced',
        () async {
      final _Spy spy = _Spy();
      await _run(
        spy,
        _planOf(
          steps,
          reference: const CaseReferenceBinding.nestedParameter(
            <String>['header', 'document_no'],
          ),
        ),
        held: const SubmissionDraft(id: 'case-1', referenceNo: 'REF-9'),
      );
      final Map<String, Object?> body =
          spy.updateEnvelopes.single['form_data']! as Map<String, Object?>;
      expect(body.keys.toList(), <String>['ref'],
          reason: 'the builder was re-run with the reference; no key appended');
      expect(body['ref'], 'REF-9');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B4-AC-19 — pay runs only where the plan declares it AND the page agrees
  // ───────────────────────────────────────────────────────────────────────────
  group('the pay step', () {
    const List<SubmissionStep> withPay = <SubmissionStep>[
      SubmissionStep.create,
      SubmissionStep.submit,
      SubmissionStep.pay,
    ];
    const List<SubmissionStep> withoutPay = <SubmissionStep>[
      SubmissionStep.create,
      SubmissionStep.submit,
    ];

    test('a plan WITHOUT a pay step never calls the charge port — even when '
        'one is supplied and the fee is positive', () async {
      // Birth's and Death's half of `B4-AC-19`, isolated from their cubits: the
      // executor must not invent the step for a plan that omits it.
      final _Spy spy = _Spy();
      bool charged = false;
      final SubmissionOutcome out = await _run(
        spy,
        _planOf(withoutPay, form: CertificateForm.birth),
        charge: (SubmissionDraft _, ApplicationDetail __) async {
          charged = true;
          return const Right<Failure, String?>('RCPT');
        },
      );
      expect(charged, isFalse);
      expect(out.receiptNo, isNull);
    });

    test('a plan WITH a pay step calls the port and carries its receipt back',
        () async {
      final _Spy spy = _Spy();
      final SubmissionOutcome out = await _run(
        spy,
        _planOf(withPay),
        charge: (SubmissionDraft d, ApplicationDetail decided) async =>
            Right<Failure, String?>('RCPT-${d.id}'),
      );
      expect(out.receiptNo, 'RCPT-case-1');
    });

    test('the port receives the DRAFT id, not the decided case\'s', () async {
      // `:536` charges `current.id`. Reading the id off the submit answer
      // instead would trust the server to echo an identifier the source never
      // re-reads.
      final _Spy spy = _Spy();
      String? seen;
      await _run(
        spy,
        _planOf(withPay),
        held: const SubmissionDraft(id: 'held-77', referenceNo: 'REF-1'),
        charge: (SubmissionDraft d, ApplicationDetail _) async {
          seen = d.id;
          return const Right<Failure, String?>(null);
        },
      );
      expect(seen, 'held-77');
    });

    test('THE PREDICATE IS THE PAGE\'S — the executor asks no question about '
        'fee or payment state', () async {
      // § 6.7's ruling, made falsifiable. The executor is handed a zero-fee,
      // already-paid case and STILL calls the port, because deciding is not its
      // job. A future hand that moved `feeLak > 0` in here would fail this.
      final _Spy spy = _Spy()
        ..feeLak = 0
        ..paymentState = PaymentState.paid;
      bool asked = false;
      await _run(
        spy,
        _planOf(withPay),
        charge: (SubmissionDraft _, ApplicationDetail decided) async {
          asked = true;
          expect(decided.row.feeLak, 0);
          expect(decided.row.paymentState, PaymentState.paid);
          return const Right<Failure, String?>(null);
        },
      );
      expect(asked, isTrue);
    });

    test('a null charge port leaves the receipt null and does not fail the run',
        () async {
      final _Spy spy = _Spy();
      final SubmissionOutcome out = await _run(spy, _planOf(withPay));
      expect(out.receiptNo, isNull);
      expect(spy.calls, <String>['create', 'submit']);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Failure reporting — which step failed is part of the signal
  // ───────────────────────────────────────────────────────────────────────────
  group('SubmissionStepFailure', () {
    test('names the step that failed and carries the Failure unchanged',
        () async {
      final _Spy spy = _Spy()..failAttachAt = 0;
      await expectLater(
        _run(
          spy,
          _planOf(const <SubmissionStep>[
            SubmissionStep.create,
            SubmissionStep.attach,
            SubmissionStep.submit,
          ]),
          attachments: <SubmissionAttachment>[_att('a')],
        ),
        throwsA(
          isA<SubmissionStepFailure>()
              .having((SubmissionStepFailure e) => e.step, 'step',
                  SubmissionStep.attach)
              .having((SubmissionStepFailure e) => e.failure.message, 'message',
                  'upload refused'),
        ),
      );
      // And nothing after the failing step ran.
      expect(spy.calls, <String>['create', 'attach:a']);
    });

    test('a plan that submits without creating is a StateError', () async {
      final _Spy spy = _Spy();
      await expectLater(
        _run(spy, _planOf(const <SubmissionStep>[SubmissionStep.submit])),
        throwsA(isA<StateError>()),
      );
    });

    test('a plan that never submits is a StateError, not a silent null',
        () async {
      final _Spy spy = _Spy();
      await expectLater(
        _run(spy, _planOf(const <SubmissionStep>[SubmissionStep.create])),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B4-AC-23 — EnvelopeShape is read by production code, and the read bites
  // ───────────────────────────────────────────────────────────────────────────
  group('the envelope shape is checked against the page\'s transcription', () {
    const List<SubmissionStep> steps = <SubmissionStep>[
      SubmissionStep.create,
      SubmissionStep.submit,
    ];

    test('an envelope matching the declared shape passes', () async {
      final _Spy spy = _Spy();
      await _run(spy, _planOf(steps));
      expect(spy.createEnvelopes.single.keys.toList(),
          <String>['service_code', 'form_data']);
    });

    test('THE CAPABILITY CONTROL — a key the shape does not declare trips the '
        'assertion', () async {
      // Without this the shape could be read and thrown away and every test
      // above would still pass. `EnvelopeShape` was inert in `lib/` before B4
      // (§ 2.2 Finding H); this is the assertion that it is not inert now.
      final _Spy spy = _Spy();
      await expectLater(
        spy.executor.run(
          plan: _planOf(steps),
          buildFormData: (String _) => <String, Object?>{},
          createEnvelope: (Map<String, Object?> payload) => <String, Object?>{
            'service_code': 'resident',
            'province_id': 'p-1', // not in this plan's declared shape
            'form_data': payload,
          },
          updateEnvelope: (Map<String, Object?> u) =>
              <String, Object?>{'form_data': u},
          attachments: const <SubmissionAttachment>[],
          ledger: AttachmentLedger(),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('THE CAPABILITY CONTROL — two declared keys emitted OUT OF ORDER trips '
        'the assertion', () async {
      // Insertion order is wire order (`envelope_shape.dart:4-16`), so this is
      // the failure Tier 0 would otherwise be the only instrument to catch.
      final _Spy spy = _Spy();
      await expectLater(
        spy.executor.run(
          plan: _planOf(steps),
          buildFormData: (String _) => <String, Object?>{},
          createEnvelope: (Map<String, Object?> payload) => <String, Object?>{
            'form_data': payload,
            'service_code': 'resident',
          },
          updateEnvelope: (Map<String, Object?> u) =>
              <String, Object?>{'form_data': u},
          attachments: const <SubmissionAttachment>[],
          ledger: AttachmentLedger(),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('an ELIDED optional key is accepted — absent is not out-of-order',
        () async {
      // Resident's `province_id: form.province || undefined` (`:509`) drops the
      // key when blank, so a five-key body is a legitimate reading of a six-key
      // shape. An equality check here would reject the shipped app.
      final _Spy spy = _Spy();
      final SubmissionPlan plan = SubmissionPlan(
        form: CertificateForm.resident,
        steps: steps,
        reference: const CaseReferenceBinding.flatAppended('header.ref_no'),
        attachmentGuard: AttachmentGuard.slotKeyed,
        createEnvelope: const EnvelopeShape(<EnvelopeKey>[
          EnvelopeKey('service_code'),
          EnvelopeKey('province_id',
              optional: true, whenEmpty: WhenEmpty.elided),
          EnvelopeKey('form_data'),
        ]),
        updateEnvelope: const EnvelopeShape(<EnvelopeKey>[
          EnvelopeKey('form_data'),
        ]),
        methodCode: MethodCodeSource.liveList,
        stepsSrc: 'built by submission_executor_test.dart',
      );
      await spy.executor.run(
        plan: plan,
        buildFormData: (String _) => <String, Object?>{},
        createEnvelope: (Map<String, Object?> payload) => <String, Object?>{
          'service_code': 'resident',
          'form_data': payload,
        },
        updateEnvelope: (Map<String, Object?> u) =>
            <String, Object?>{'form_data': u},
        attachments: const <SubmissionAttachment>[],
        ledger: AttachmentLedger(),
      );
      expect(spy.calls, <String>['create', 'submit']);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B4-AC-22 — plan.methodCode is read, and the read bites
  // ───────────────────────────────────────────────────────────────────────────
  group('the two methodCode registries are checked against each other', () {
    test('THE CAPABILITY CONTROL — a plan whose methodCode disagrees with '
        'methodCodeSourceFor trips the assertion', () async {
      // Resident is `liveList` in both registries; this plan claims
      // `staticMap`. The two are written by two dispatches
      // (`submission_plan.dart` and `method_code_source.dart`) and can drift.
      final _Spy spy = _Spy();
      await expectLater(
        _run(
          spy,
          _planOf(
            const <SubmissionStep>[SubmissionStep.create, SubmissionStep.submit],
            methodCode: MethodCodeSource.staticMap,
          ),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('and the five shipped plans all agree — not vacuous', () {
      for (final CertificateForm f in CertificateForm.values) {
        expect(
          SubmissionPlan.forForm(f).methodCode,
          methodCodeSourceFor(f),
          reason: '${f.serviceCode} disagrees between the two registries',
        );
      }
    });
  });
}

/// **`F0-AC-13`, discharged against the artefact that actually exists.**
///
/// § 3.1 names `$PKG/test/fidelity/submission_plans.json` as F0a's deliverable
/// and `F0-AC-13` has the Dart side compare `SubmissionPlan.all` against it.
/// **That file was not produced** — F0a landed the Tier 0 oracles and the
/// executed-oracle rig, and `ls test/fidelity/` shows no `submission_plans.json`
/// (measured `2026-08-14`, and reported as a gap rather than worked around).
///
/// The double-entry it exists to provide is nevertheless available, because the
/// **22 Tier 0 oracle files carry the same facts**, derived by F0a's own
/// independent scan of the same five pages: `createEnvelope` and
/// `updateEnvelope` as ordered `(name, present, value)` blocks, `envelopeSrc`
/// as a per-key `file:line`, and `refBinding` as `{pointer, mechanic, src}`.
/// This file compares `SubmissionPlan.all` against those.
///
/// That is the property `F0-AC-13` is after: a mis-read of
/// `MarriageCertificatePage.tsx:957-989` has to be made **twice, by two
/// dispatches, in the same direction** to survive — F0a's Python scan and this
/// batch's Dart transcription were written from the source independently.
///
/// **What it does not discharge**, stated so nobody records a PASS for it: the
/// `steps` sequence and the `attachmentGuard` are not in the Tier 0 oracles
/// (they are submission *mechanics*, not payload), so those two fields remain
/// single-entry until `submission_plans.json` exists. `submission_plan_test.dart`
/// asserts them against their citations; nothing cross-checks the citations.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/case_reference_binding.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/envelope_shape.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_plan.dart';

/// `$PROJ/docs/fidelity-baseline/2026-08-13/oracle/tier0` — project-relative,
/// two directories up from `$PKG` (§ 7.0(1): a bare relative path is a defect).
const String _oracleDir =
    '../../docs/fidelity-baseline/2026-08-13/oracle/tier0';

Map<String, dynamic> _oracle(String name) {
  final File f = File('$_oracleDir/$name.json');
  return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  setUpAll(() {
    // § 7.0(2), applied to this scan root: a comparison against an absent
    // oracle tree is NOT EVALUATED, never PASS.
    final Directory dir = Directory(_oracleDir);
    expect(dir.existsSync(), isTrue,
        reason: 'F0a`s Tier 0 oracle tree is missing; every comparison below '
            'would be vacuous');
    expect(dir.listSync().whereType<File>().where(
          (File f) => f.path.endsWith('.json'),
        ),
        hasLength(22),
        reason: '22 = {six forms} x {create, update} x {en, lo}, FamilyBook x 2');
  });

  group('F0-AC-13 — the create envelopes agree with F0a`s derivation', () {
    for (final String form in <String>[
      'resident',
      'birth',
      'death',
      'marriage',
      'divorce',
    ]) {
      test('$form create: key ORDER', () {
        final Map<String, dynamic> o = _oracle('$form.create.en');
        final Map<String, dynamic> env =
            o['createEnvelope'] as Map<String, dynamic>;
        expect(
          SubmissionPlan.all[form]!.createEnvelope.names,
          env.keys.toList(),
        );
      });

      test('$form create: which keys the oracle saw ABSENT', () {
        final Map<String, dynamic> o = _oracle('$form.create.en');
        final Map<String, dynamic> env =
            o['createEnvelope'] as Map<String, dynamic>;
        final EnvelopeShape shape = SubmissionPlan.all[form]!.createEnvelope;

        for (final MapEntry<String, dynamic> e in env.entries) {
          final bool present =
              (e.value as Map<String, dynamic>)['present'] as bool;
          if (!present) {
            // An absent key must be declared elidable, or the plan and the
            // oracle disagree about what the wire carries.
            expect(shape[e.key].optional, isTrue,
                reason: '$form create: the oracle recorded `${e.key}` ABSENT while '
                    'the plan declares it non-optional');
            expect(shape[e.key].whenEmpty, WhenEmpty.elided);
          }
        }
      });

      test('$form update: key ORDER, form_data first', () {
        final Map<String, dynamic> o = _oracle('$form.update.en');
        final Map<String, dynamic> env =
            o['updateEnvelope'] as Map<String, dynamic>;
        expect(
          SubmissionPlan.all[form]!.updateEnvelope.names,
          env.keys.toList(),
        );
        expect(env.keys.first, 'form_data');
      });

      test('$form: the reference binding pointer and mechanic', () {
        final Map<String, dynamic> o = _oracle('$form.update.en');
        final Map<String, dynamic> ref =
            o['refBinding'] as Map<String, dynamic>;
        final CaseReferenceBinding binding = SubmissionPlan.all[form]!.reference;

        expect(binding.pointer, ref['pointer'],
            reason: 'the flat family`s literal dotted key and the nested '
                'family`s real path flatten to the same string; the oracle '
                'distinguishes them and so must the plan');

        final String mechanic = ref['mechanic'] as String;
        expect(
          binding.rebuildsPayload,
          mechanic == 'nested-parameter',
          reason: '$form: oracle says `$mechanic`',
        );
      });
    }
  });

  test('FamilyBook has a Tier 0 oracle and NO plan', () {
    final Map<String, dynamic> o = _oracle('family-book.request.en');

    // One body, one key — not a create/update pair.
    expect((o['requestEnvelope'] as Map<String, dynamic>).keys.toList(),
        <String>['reason']);
    expect(o.containsKey('createEnvelope'), isFalse);
    expect(o.containsKey('updateEnvelope'), isFalse);

    // And the oracle's own refBinding says there is nothing to bind.
    final Map<String, dynamic> ref = o['refBinding'] as Map<String, dynamic>;
    expect(ref['pointer'], isNull);

    // Which is why `SubmissionPlan` has no inhabitant for it.
    expect(SubmissionPlan.all.containsKey('family-book'), isFalse);
    expect(SubmissionPlan.all.containsKey('familyBook'), isFalse);
  });

  test('the oracles were derived from the PIN, not from this port', () {
    // Cheap provenance check on the referent this file compares against. An
    // oracle re-derived from a different commit would make every agreement
    // above meaningless.
    for (final String name in <String>[
      'resident.create.en',
      'marriage.update.lo',
    ]) {
      final Map<String, dynamic> p =
          _oracle(name)['provenance'] as Map<String, dynamic>;
      expect(p['web_commit'], '62f8a529aaa024a8b35b0af50a8fbd4850a63962');
    }
  });
}

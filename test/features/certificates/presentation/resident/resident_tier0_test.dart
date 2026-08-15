/// **Tier 0 for Resident — the F1 gate.**
///
/// `ssd.md` § 14 F-6: *"Tier 0 payload equality is blocking and takes
/// precedence over Tier 3 disagreement."* F0's exit contract § 6.12 Q-10 says
/// what that means for this file: *"F1 inherits the rig: its first
/// `buildFormData` is judged against bytes the web actually emitted, not
/// against a Python author's reading of the same file."*
///
/// ## The three things compared, weakest to strongest
///
/// | | Source | What it proves |
/// |---|---|---|
/// | Entry B | `oracle/tier0/resident.*.json` | a second, independent transcription agrees |
/// | Entry A | `oracle/tier0/executed/resident.*.json` | the **running pinned app** agrees, leaf by leaf |
/// | `raw_bytes` | Entry A's `raw_bytes` field | the literal `JSON.stringify` string that went on the wire |
///
/// The third is the one that matters. `client.ts:242` is a bare
/// `JSON.stringify(options.body)`, so `raw_bytes` *is* the request body — not a
/// model of it. Comparing `jsonEncode` of this port's envelope against that
/// string tests key order, key count, key spelling, nesting, elision and every
/// value in one assertion, and a `DeepCollectionEquality` could not.
///
/// ## The two exemptions, and why they are asserted rather than skipped
///
/// ADR-0005 rules `today()` FIXED, so two Resident keys per body legitimately
/// differ from the web: `purpose.issue_date` (a `form_data` leaf) and
/// `event_date` (an envelope key). `test/fidelity/tier0_divergences.yaml` holds
/// them as four of its sixteen rows and the register is **closed**.
///
/// They are not skipped. At the register's instant the port must say
/// `2026-08-14` **and** the oracle must say `2026-08-13`: a test that only
/// checked the first would pass against an oracle re-derived after somebody
/// "fixed" the web, and a test that skipped both would pass against a port that
/// reintroduced `toUtc()`. Both halves, every time (`F0-AC-28`).
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/case_reference_binding.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_payload.dart';

import 'resident_tier0_subject.dart';

void main() {
  final SubmissionClock clock = SubmissionClock.fixed(kRegisterInstant);

  // The reference the fixtures carry. `_reference_no` rather than a literal so
  // the fixture stays the single source for it.
  late final String referenceNo;
  late final Map<String, Map<String, dynamic>> fixtures;

  setUpAll(() {
    fixtures = <String, Map<String, dynamic>>{
      'en': readOracleJson('$kResidentFixtureDir/baseline.en.json'),
      'lo': readOracleJson('$kResidentFixtureDir/baseline.lo.json'),
    };
    referenceNo = fixtures['en']!['_reference_no'] as String;
  });

  group('the clock is the register\'s, and both halves hold (F0-AC-28)', () {
    test('the port says 2026-08-14 where the web said 2026-08-13', () {
      expect(clock.todayLocal(), kExpectedLocal);

      final Map<String, dynamic> o = readOracleJson('$kResidentOracleDir/resident.create.en.json');
      expect(o['clock'], '2026-08-14T02:00:00+07:00');
      expect(
        (o['form_data'] as Map<String, dynamic>)['purpose.issue_date'],
        kExpectedWebUtc,
        reason: 'The oracle must still carry the WEB value. If this reads '
            '2026-08-14 the oracle was re-derived against a different instant '
            'and the divergence has gone invisible — which is the failure '
            'ADR-0005 point 5 exists to catch.',
      );
    });
  });

  for (final String locale in <String>['en', 'lo']) {
    group('Resident Tier 0 — $locale', () {
      late Map<String, Object?> createPayload;
      late Map<String, Object?> updatePayload;
      late Map<String, Object?> createEnvelope;
      late Map<String, Object?> updateEnvelope;

      setUp(() {
        final ResidentFormData form = formFromFixture(fixtures[locale]!);
        final SubmissionBodies bodies =
            residentSubmissionBodies(form, clock, referenceNo);
        createPayload = bodies.create;
        updatePayload = bodies.update;
        createEnvelope = residentCreateEnvelope(
          form: form,
          payload: createPayload,
          clock: clock,
        );
        updateEnvelope = residentUpdateEnvelope(
          updatePayload: updatePayload,
          clock: clock,
        );
      });

      // ── Entry B — the independent re-transcription ────────────────────────

      test('create form_data equals Entry B, key for key and in order', () {
        final Map<String, dynamic> o =
            readOracleJson('$kResidentOracleDir/resident.create.$locale.json');
        expect(
          createPayload.keys.toList(),
          (o['form_data'] as Map<String, dynamic>).keys.toList(),
          reason: 'Key ORDER is wire order (client.ts:242). A set comparison '
              'would pass a transposition; this must not.',
        );
        expect(
          jsonEncode(createPayload),
          jsonEncode(applyDivergences(
            o['form_data'] as Map<String, dynamic>,
            isEnvelope: false,
          )),
        );
      });

      test('update form_data equals Entry B — 23 keys, ref_no LAST', () {
        final Map<String, dynamic> o =
            readOracleJson('$kResidentOracleDir/resident.update.$locale.json');
        final Map<String, dynamic> expected =
            o['form_data'] as Map<String, dynamic>;

        expect(updatePayload.keys.length, 23);
        expect(
          updatePayload.keys.last,
          'header.ref_no',
          reason: 'flatAppended puts the reference LAST and raises the key '
              'count by one (ResidentCertificatePage.tsx:522). Anywhere else '
              'is different bytes.',
        );
        expect(updatePayload.keys.toList(), expected.keys.toList());
        expect(
          jsonEncode(updatePayload),
          jsonEncode(applyDivergences(expected, isEnvelope: false)),
        );
      });

      // ── Entry A — bytes the running pinned application emitted ────────────

      test('create body is byte-identical to what the web POSTed (raw_bytes)',
          () {
        final Map<String, dynamic> a =
            readOracleJson('$kResidentOracleDir/executed/resident.create.$locale.json');
        expect(
          a['provenance']['leaf_provenance'],
          'executed',
          reason: 'A transcribed document in the executed/ directory would '
              'make this test a re-run of the Entry B test above.',
        );

        final Map<String, dynamic> wire =
            jsonDecode(a['raw_bytes'] as String) as Map<String, dynamic>;

        expect(
          jsonEncode(createEnvelope),
          jsonEncode(applyDivergences(wire, isEnvelope: true)),
          reason: 'raw_bytes IS the request body — client.ts:242 is a bare '
              'JSON.stringify. This one assertion covers key order, key count, '
              'spelling, nesting, elision and every value.',
        );
      });

      test('update body is byte-identical to what the web PATCHed (raw_bytes)',
          () {
        final Map<String, dynamic> a =
            readOracleJson('$kResidentOracleDir/executed/resident.update.$locale.json');
        final Map<String, dynamic> wire =
            jsonDecode(a['raw_bytes'] as String) as Map<String, dynamic>;

        expect(
          jsonEncode(updateEnvelope),
          jsonEncode(applyDivergences(wire, isEnvelope: true)),
        );
      });

      // ── The envelope facts the raw-bytes test would also catch, named ─────
      //
      // Named separately so a failure says WHICH property broke. The raw-bytes
      // assertion above is the gate; these are its diagnosis.

      test('form_data is LAST on create and FIRST on update', () {
        expect(createEnvelope.keys.last, 'form_data');
        expect(updateEnvelope.keys.first, 'form_data');
      });

      test('a blank province/district/village ELIDES the key, not ""', () {
        final ResidentFormData blank = formFromFixture(fixtures[locale]!)
            .copyWith(province: '', district: '', villageName: '');
        final Map<String, Object?> env = residentCreateEnvelope(
          form: blank,
          payload: buildResidentFormData(blank, clock),
          clock: clock,
        );

        expect(env.containsKey('province_id'), isFalse);
        expect(env.containsKey('district_id'), isFalse);
        expect(env.containsKey('village_id'), isFalse);
        expect(env.keys.toList(), <String>['service_code', 'event_date', 'form_data']);

        // The quotes are load-bearing. A bare `.contains('province_id')` is
        // TRUE on a correct body, because `form_data` carries the literal
        // dotted key `"header.province_id"` — this assertion was red on the
        // first run for exactly that reason. `"province_id"` with the leading
        // quote cannot match it, since the character before the run is `.`.
        expect(
          jsonEncode(env).contains('"province_id"'),
          isFalse,
          reason: 'ResidentCertificatePage.tsx:509 is `form.province || '
              'undefined` and JSON.stringify DROPS an undefined value. '
              'Marriage writes the raw value at the same key and sends "" — '
              'same key name, two different bodies (F0-AC-19).',
        );

        // …and the elision is a real distinction, not a tautology: the
        // present-and-empty spelling Marriage uses is different bytes.
        final Map<String, Object?> marriageSpelling = <String, Object?>{
          'service_code': kResidentServiceCode,
          'province_id': '',
          'district_id': '',
          'village_id': '',
          'event_date': clock.todayLocal(),
          'form_data': buildResidentFormData(blank, clock),
        };
        expect(jsonEncode(env), isNot(jsonEncode(marriageSpelling)));
      });

      test('purpose.purpose_other is present-and-empty, never elided', () {
        final ResidentFormData blank =
            formFromFixture(fixtures[locale]!).copyWith(purposeOther: '');
        final Map<String, Object?> p = buildResidentFormData(blank, clock);
        expect(p.containsKey('purpose.purpose_other'), isTrue);
        expect(p['purpose.purpose_other'], '');
      });
    });
  }

  group('the comparator can fail — the negative controls', () {
    // Capability Rule: a Tier 0 test that has never been red is evidence that
    // it ran, not that it compares. Each mutant below is the port, wrong in
    // exactly one way, and each must be REJECTED.

    late ResidentFormData form;
    late Map<String, dynamic> wire;

    setUp(() {
      form = formFromFixture(fixtures['en']!);
      wire = jsonDecode(
        readOracleJson('$kResidentOracleDir/executed/resident.create.en.json')['raw_bytes']
            as String,
      ) as Map<String, dynamic>;
    });

    Map<String, Object?> expected() => applyDivergences(wire, isEnvelope: true);

    test('M1 — one character wrong in one value is caught', () {
      final ResidentFormData mutant = form.copyWith(houseNo: '124');
      final Map<String, Object?> env = residentCreateEnvelope(
        form: mutant,
        payload: buildResidentFormData(mutant, clock),
        clock: clock,
      );
      expect(jsonEncode(env), isNot(jsonEncode(expected())));
    });

    test('M2 — two adjacent keys transposed is caught', () {
      final Map<String, Object?> good = buildResidentFormData(form, clock);
      final List<String> keys = good.keys.toList();
      final int i = keys.indexOf('applicant.age');
      final List<String> swapped = List<String>.of(keys);
      swapped[i] = keys[i + 1];
      swapped[i + 1] = keys[i];

      final Map<String, Object?> mutant = <String, Object?>{
        for (final String k in swapped) k: good[k],
      };
      final Map<String, Object?> env = residentCreateEnvelope(
        form: form,
        payload: mutant,
        clock: clock,
      );

      expect(
        jsonEncode(env),
        isNot(jsonEncode(expected())),
        reason: 'Transposing two keys leaves the map EQUAL under '
            'DeepCollectionEquality and the bytes different. That gap is the '
            'reason this file compares strings.',
      );
    });

    test('M5 — a nested header instead of the literal dotted key is caught',
        () {
      // Resident emits the LITERAL flat key "header.province_id". Nesting it
      // decodes to a different tree and serialises to different bytes, and
      // the two flatten to the same dotted string — which is why the pointer
      // list is RFC 6901 and not a dotted flattening.
      final Map<String, Object?> good = buildResidentFormData(form, clock);
      final Map<String, Object?> mutant = <String, Object?>{
        'header': <String, Object?>{'province_id': good['header.province_id']},
        for (final MapEntry<String, Object?> e in good.entries)
          if (e.key != 'header.province_id') e.key: e.value,
      };
      final Map<String, Object?> env = residentCreateEnvelope(
        form: form,
        payload: mutant,
        clock: clock,
      );
      expect(jsonEncode(env), isNot(jsonEncode(expected())));
    });

    test('M6 — reproducing the web\'s UTC date is caught by the register', () {
      // The mutant here is a port that did NOT apply ADR-0005 — it emits the
      // web's 2026-08-13. Without the both-halves assertion this would look
      // like a pass, because it matches the oracle exactly.
      final SubmissionClock utcish = SubmissionClock.fixed(
        DateTime.parse('2026-08-14T02:00:00+07:00').toUtc(),
      );
      expect(utcish.todayLocal(), kExpectedWebUtc);
      expect(
        utcish.todayLocal(),
        isNot(kExpectedLocal),
        reason: 'A port whose clock reads UTC agrees with the oracle and is '
            'WRONG. That is why the exemption asserts both sides rather than '
            'skipping the key.',
      );
    });
  });
}

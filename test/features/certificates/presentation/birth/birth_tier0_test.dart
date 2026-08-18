/// Tier 0 — Birth, the page-local gate. **294 leaves per locale, 8 documents.**
///
/// `specs.md` § 2.3 RULING 0: Birth's Tier 0 must be PASS **before any file
/// under `presentation/death/` exists**. This is the file that decides that,
/// and it is deliberately the first thing written after the payload.
///
/// The comparator is F0a's, imported from
/// `test/fidelity/tier0_payload_equality_test.dart` rather than reimplemented —
/// a second comparator would be a second chance to compare leniently.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/case_reference_binding.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/birth/birth_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/birth/birth_payload.dart';

import '../../../../fidelity/oracle.dart';
import '../../../../fidelity/tier0_payload_equality_test.dart'
    show compareTier0, leafPaths, Tier0Result, valueAt;
import 'birth_tier0_subject.dart';

void main() {
  final SubmissionClock clock = SubmissionClock.fixed(kBirthRegisterInstant);

  Map<String, dynamic> fixtureOf(String variant, String locale) =>
      readBirthJson('$kBirthFixtureDir/$variant.$locale.json');

  /// The two bodies of one submission, built the way the page builds them:
  /// **payload once**, reference appended through the binding.
  SubmissionBodies bodiesOf(String variant, String locale) {
    final Map<String, dynamic> fixture = fixtureOf(variant, locale);
    return birthBodiesFrom(
      buildBirthFormData(
        birthFormFromFixture(fixture),
        clock,
        legalBasisText: birthLegalBasisFor(locale),
      ),
      fixture['_reference_no'] as String,
    );
  }

  /// The executed (Entry A) document for a canonical name; variants live under
  /// `executed/` too, flat, with a four-part name.
  Tier0Oracle executed(String name) =>
      Tier0Oracle.load('$kBirthOracleDir/executed', name);

  // ── The eight documents, per `specs.md` § 2.1.1 ───────────────────────────
  //
  //   birth.create              79 leaves
  //   birth.update              80   (= create + header.document_no, appended)
  //   birth.father-unknown.create 67 (= 79 - 13 + 1)
  //   birth.father-unknown.update 68
  //
  // x 2 locales = 294 per locale, 8 documents. `F2-AC-28` records the counts
  // verbatim and treats a LOWER number as a FAIL even when every compared leaf
  // passed — that would mean leaves were skipped.
  const Map<String, ({String fixture, int create, int update})> kDocs =
      <String, ({String fixture, int create, int update})>{
    'birth': (fixture: 'baseline', create: 79, update: 80),
    'birth.father-unknown': (
      fixture: 'father-unknown',
      create: 67,
      update: 68
    ),
  };

  group('Tier 0 — Birth, the real buildBirthFormData (F2)', () {
    for (final MapEntry<String, ({String fixture, int create, int update})> doc
        in kDocs.entries) {
      for (final String locale in <String>['en', 'lo']) {
        test('F2-AC-27/28 ${doc.key}.create.$locale — '
            '${doc.value.create} leaves against the executed oracle', () {
          final Tier0Oracle o = executed('${doc.key}.create.$locale');
          final Map<String, Object?> want = o.formData.cast<String, Object?>();
          final Map<String, Object?> got =
              bodiesOf(doc.value.fixture, locale).create;

          expect(leafPaths(want).length, doc.value.create,
              reason: '${doc.key}.create.$locale carries '
                  '${doc.value.create} leaves (specs.md § 2.1.1)');
          expect(leafPaths(got).length, doc.value.create,
              reason: 'the port emitted a different number of leaves');

          final Tier0Result r = compareTier0(
            oracle: want,
            actual: got,
            exempt: kBirthExemptFormDataPointers,
          );
          expect(r.passed, isTrue, reason: r.toString());
        });

        test('F2-AC-27/28/29 ${doc.key}.update.$locale — '
            '${doc.value.update} leaves, header.document_no LAST', () {
          final Tier0Oracle o = executed('${doc.key}.update.$locale');
          final Map<String, Object?> want = o.formData.cast<String, Object?>();
          final Map<String, Object?> got =
              bodiesOf(doc.value.fixture, locale).update;

          expect(leafPaths(want).length, doc.value.update);
          expect(leafPaths(got).length, doc.value.update,
              reason: 'flat-appended-last raises the key count by exactly one');
          expect(got.keys.last, 'header.document_no',
              reason: 'LAST, not merged in sorted position (F0-AC-14)');

          final Tier0Result r = compareTier0(
            oracle: want,
            actual: got,
            exempt: kBirthExemptFormDataPointers,
          );
          expect(r.passed, isTrue, reason: r.toString());
        });
      }
    }

    test('F2-AC-28 the Birth total is 294 leaves per locale over 8 documents',
        () {
      int perLocale = 0;
      int documents = 0;
      for (final MapEntry<String, ({String fixture, int create, int update})>
          doc in kDocs.entries) {
        perLocale += doc.value.create + doc.value.update;
        documents += 4; // create + update, en + lo
      }
      // ignore: avoid_print
      print('F2-AC-28 Birth: $perLocale leaves per locale across $documents '
          'documents (${perLocale * 2} comparisons)');
      expect(perLocale, 294);
      expect(documents, 8);
    });

    test('F2-AC-29 every update body is its create body + 1, appended last',
        () {
      for (final MapEntry<String, ({String fixture, int create, int update})>
          doc in kDocs.entries) {
        for (final String locale in <String>['en', 'lo']) {
          final SubmissionBodies b = bodiesOf(doc.value.fixture, locale);
          final List<String> create = b.create.keys.toList();
          final List<String> update = b.update.keys.toList();
          expect(update, equals(<String>[...create, 'header.document_no']),
              reason: '${doc.key}.$locale: the flat family appends the '
                  'reference LAST to a spread copy of the same object — '
                  '+1 key, order otherwise unchanged');
        }
      }
    });

    test('F2-AC-31 the block arithmetic, not just the totals', () {
      final Map<String, Object?> base = bodiesOf('baseline', 'en').create;
      final List<String> keys = base.keys.toList();

      int startingWith(String prefix) =>
          keys.where((String k) => k.startsWith(prefix)).length;

      // `79 = 5 + 20 + 13 + 13 + 13 + 15`.
      expect(startingWith('header.'), 5);
      expect(startingWith('child.'), 20);
      expect(
          keys
              .where((String k) =>
                  k.startsWith('parents.') &&
                  !k.startsWith('parents.mother.') &&
                  !k.startsWith('parents.father.'))
              .length,
          13,
          reason: 'the mother, under the bare `parents` prefix');
      expect(startingWith('parents.mother.'), 13,
          reason: 'the SAME mother, under her own prefix — two invocations');
      expect(startingWith('parents.father.'), 13);
      expect(startingWith('informant.'), 15,
          reason: 'Death\'s informant block is 12 — F2-AC-23');
      expect(keys.length, 79);

      // `67 = 79 - 13 + 1` — the father block collapses to one key.
      final Map<String, Object?> fu = bodiesOf('father-unknown', 'en').create;
      expect(fu.keys.length, 67);
      expect(
          fu.keys.where((String k) => k.startsWith('parents.father')).toList(),
          equals(<String>['parents.father.status']));
      expect(fu['parents.father.status'], kBirthFatherUnknownStatus);
      expect(fu['parents.father.status'], 'unknown',
          reason: 'Death\'s is "deceased-or-unknown" — F2-AC-22');
    });

    test('F2-AC-45 the mother\'s double emission is TWO invocations, not one '
        'map aliased twice', () {
      // Byte-equal either way on every fixture, because the mother is one
      // object. Only a distinguishing INPUT can tell them apart, and no fixture
      // provides one — so the property is asserted by construction: two
      // separately-prefixed maps whose identity differs.
      const BirthParentInfo m = BirthParentInfo(fullName: 'M');
      final Map<String, Object?> a = birthParentData(m, 'parents');
      final Map<String, Object?> b = birthParentData(m, 'parents.mother');
      expect(identical(a, b), isFalse,
          reason: 'an aliased map would be the same object');
      expect(a.keys.first, 'parents.name');
      expect(b.keys.first, 'parents.mother.name');

      // And the payload really contains both, disjoint.
      final Map<String, Object?> payload = buildBirthFormData(
        const BirthFormData(mother: BirthParentInfo(fullName: 'M')),
        clock,
        legalBasisText: 'x',
      );
      for (final String k in a.keys) {
        expect(payload.containsKey(k), isTrue, reason: k);
      }
      for (final String k in b.keys) {
        expect(payload.containsKey(k), isTrue, reason: k);
      }
      expect(a.keys.toSet().intersection(b.keys.toSet()), isEmpty);
    });

    test('F2-AC-20 birthParentData takes 2 parameters and emits 13 keys', () {
      final Map<String, Object?> keys =
          birthParentData(const BirthParentInfo(), 'p');
      expect(keys.length, 13);
      expect(
          keys.keys.toList(),
          equals(<String>[
            'p.name',
            'p.fingerprint',
            'p.dob',
            'p.ethnicity',
            'p.nationality',
            'p.ethnic_group',
            'p.religion',
            'p.marital_status',
            'p.current_address',
            'p.house_no',
            'p.id_number',
            'p.education',
            'p.occupation',
          ]),
          reason: 'Death\'s emits a fourteenth, `workplace`, and takes a third '
              '`skipped` parameter — never share the helper (F2-AC-20)');
    });

    test('F2-AC-46 every emitted value is a String', () {
      for (final String variant in <String>['baseline', 'father-unknown']) {
        for (final String locale in <String>['en', 'lo']) {
          final SubmissionBodies b = bodiesOf(variant, locale);
          for (final MapEntry<String, Object?> e in b.update.entries) {
            expect(e.value, isA<String>(),
                reason: '$variant.$locale ${e.key} is ${e.value.runtimeType} — '
                    'no bare JSON number, boolean or null on either F2 page');
          }
        }
      }
    });

    test('F2-AC-34 the locale inequality guard fires on header.legal_basis',
        () {
      for (final String body in <String>['create', 'update']) {
        final Object? en = valueAt(
            executed('birth.$body.en').formData, '/header.legal_basis');
        final Object? lo = valueAt(
            executed('birth.$body.lo').formData, '/header.legal_basis');
        expect(en, isNot(equals(lo)),
            reason: 'birth.$body: equal across locales means either the '
                'fixture seed never took or the port hardcoded one locale');
      }
      // And the PORT reproduces the inequality, which the oracle alone cannot
      // establish.
      expect(bodiesOf('baseline', 'en').create['header.legal_basis'],
          isNot(equals(bodiesOf('baseline', 'lo').create['header.legal_basis'])));
    });

    test('F2-AC-35 the complement — every OTHER leaf is byte-identical across '
        'locales', () {
      int compared = 0;
      for (final MapEntry<String, ({String fixture, int create, int update})>
          doc in kDocs.entries) {
        for (final String body in <String>['create', 'update']) {
          final Map<String, Object?> en = body == 'create'
              ? bodiesOf(doc.value.fixture, 'en').create
              : bodiesOf(doc.value.fixture, 'en').update;
          final Map<String, Object?> lo = body == 'create'
              ? bodiesOf(doc.value.fixture, 'lo').create
              : bodiesOf(doc.value.fixture, 'lo').update;
          for (final String k in en.keys) {
            if (k == 'header.legal_basis') continue;
            expect(jsonEncode(lo[k]), equals(jsonEncode(en[k])),
                reason: '${doc.key}.$body $k differs across locales but is not '
                    'the one registered locale-dependent key — an accidental '
                    '.tr(). Over-localisation is the likelier Flutter mistake: '
                    '`.tr()` is one character from a plain string.');
            compared++;
          }
        }
      }
      // ignore: avoid_print
      print('F2-AC-35 Birth complement: $compared leaf pairs compared');
      // 78 + 79 + 66 + 67 = 290 — the four bodies minus their one legal_basis.
      expect(compared, 290);
    });

    test('F2-AC-38 header.dated is the LOCAL date, positively asserted', () {
      // Asserting only that the leaf was skipped is not sufficient: a port that
      // reintroduced `toUtc()` would also be skipped. Both halves.
      expect(bodiesOf('baseline', 'en').create['header.dated'],
          kBirthExpectedLocal);
      expect(executed('birth.create.en').formData['header.dated'],
          kBirthExpectedWebUtc,
          reason: 'the oracle must still carry the WEB value, or the '
              'divergence has gone invisible');
    });

    test('F2-AC-39 event_date is asserted positively against the fixture in '
        'all 8 Birth documents', () {
      // `specs.md` § 2.2 Finding D: this leaf is registered exempt because of
      // the `|| today()` fallback, and every fixture on disk supplies the date
      // — so the exemption protects a branch no oracle reaches, and a port
      // emitting `1999-01-01` passes Tier 0 today. This closes that hole.
      int checked = 0;
      for (final MapEntry<String, ({String fixture, int create, int update})>
          doc in kDocs.entries) {
        for (final String locale in <String>['en', 'lo']) {
          final Map<String, dynamic> fixture =
              fixtureOf(doc.value.fixture, locale);
          final BirthFormData form = birthFormFromFixture(fixture);
          final String dob =
              (fixture['child'] as Map<String, dynamic>)['dob'] as String;
          expect(dob.isNotEmpty, isTrue,
              reason: 'precondition: the fixture sets child.dob, which is why '
                  'the register row is unreachable');
          expect(birthEventDate(form, clock), dob,
              reason: '${doc.key}.$locale event_date is child.dob');
          for (final String body in <String>['create', 'update']) {
            // Entry A carries a flat `envelope` — the body it captured — where
            // Entry B carries `createEnvelope`/`updateEnvelope`. `Tier0Oracle`
            // 's getter reads the latter, so the executed document is read
            // directly rather than through a shape it does not have.
            final Map<String, dynamic> env = executed('${doc.key}.$body.$locale')
                .json['envelope']! as Map<String, dynamic>;
            expect((env['event_date']! as Map<String, dynamic>)['value'], dob,
                reason: 'and the executed oracle agrees');
            checked++;
          }
        }
      }
      // ignore: avoid_print
      print('F2-AC-39 Birth: $checked event_date envelope keys asserted '
          'positively against fixture input');
      expect(checked, 8);
    });

    test('F2-AC-40 the `|| today()` fallback emits the LOCAL date', () {
      // No oracle covers this branch and none is invented — `FU-1` carries the
      // blank-date fixture arm to F0a. Reported as evidence for the rule.
      const BirthFormData blank = BirthFormData();
      expect(blank.child.dob, '');
      expect(birthEventDate(blank, clock), kBirthExpectedLocal,
          reason: 'the local value, not the UTC 2026-08-13');
    });

    test('F2-AC-41 exactly FOUR Birth rows are exempt, and no more', () {
      expect(kBirthExemptFormDataPointers, <String>{'/header.dated'});
      expect(kBirthExemptEnvelopeKeys, <String>{'event_date'});

      // And the exemption bites on exactly one leaf per body: the other 78 of
      // the 79 create leaves are compared byte-for-byte.
      final Map<String, Object?> got = bodiesOf('baseline', 'en').create;
      final int exemptLeaves = leafPaths(got)
          .where(kBirthExemptFormDataPointers.contains)
          .length;
      expect(exemptLeaves, 1);
      expect(leafPaths(got).length - exemptLeaves, 78);
    });

    test('F2-AC-42 no Birth leaf is NOT EVALUATED', () {
      // Birth has no entry in `oracle_coverage.yaml`'s `unreachable:` register,
      // so every leaf the oracle carries must be one the port produces. A path
      // in one and not the other is a defect, never a coverage gap.
      for (final MapEntry<String, ({String fixture, int create, int update})>
          doc in kDocs.entries) {
        for (final String locale in <String>['en', 'lo']) {
          expect(
            leafPaths(bodiesOf(doc.value.fixture, locale).create).toSet(),
            equals(leafPaths(executed('${doc.key}.create.$locale').formData)
                .toSet()),
            reason: '${doc.key}.$locale: an unmatched path is a port defect',
          );
        }
      }
    });

    test('F2-AC-33 the harness FAILS on Birth, naming the leaf and document',
        () {
      // F2 inherited a GREEN instrument, which makes this demonstration more
      // necessary than it was at F1, not less. One character, one leaf, and the
      // failure must SAY which.
      final Map<String, Object?> good = bodiesOf('baseline', 'en').create;
      final Map<String, Object?> bad = Map<String, Object?>.of(good);
      bad['child.child_name'] = '${good['child.child_name']}X';

      final Tier0Result r = compareTier0(
        oracle: good,
        actual: bad,
        exempt: kBirthExemptFormDataPointers,
      );
      expect(r.passed, isFalse, reason: 'a changed leaf must not pass');
      expect(r.toString(), contains('/child.child_name'));
      // ignore: avoid_print
      print('F2-AC-33 birth.create.en planted mutant: ${r.toString()}');
    });

    test('F2-AC-43 the comparison is on BYTES, on Birth\'s own body', () {
      final Map<String, Object?> good = bodiesOf('baseline', 'en').create;

      // `{"a":"2"}` vs `{"a":2}` — a number where the wire has a string.
      final Map<String, Object?> retyped = Map<String, Object?>.of(good)
        ..['child.birth_order'] = int.parse(good['child.birth_order']! as String);
      expect(
        compareTier0(
          oracle: good,
          actual: retyped,
          exempt: kBirthExemptFormDataPointers,
        ).passed,
        isFalse,
        reason: 'child.birth_order is a STRING on the wire (`:773`)',
      );

      // Key-order swap: same keys, same values, different bytes.
      final List<String> keys = good.keys.toList();
      final Map<String, Object?> swapped = <String, Object?>{};
      for (int i = 0; i < keys.length; i++) {
        final int j = i == 0 ? 1 : (i == 1 ? 0 : i);
        swapped[keys[j]] = good[keys[j]];
      }
      expect(
        compareTier0(
          oracle: good,
          actual: swapped,
          exempt: kBirthExemptFormDataPointers,
        ).passed,
        isFalse,
        reason: 'insertion order IS wire order (client.ts:242)',
      );
    });

    test('F2-AC-30 buildBirthFormData is invoked exactly ONCE per submission',
        () {
      // What distinguishes `flatAppended` from `nestedParameter`, and invisible
      // to a leaf-by-leaf comparison. The binding is handed a counting builder
      // and must call it once for two bodies.
      int calls = 0;
      final Map<String, Object?> payload = buildBirthFormData(
        birthFormFromFixture(fixtureOf('baseline', 'en')),
        clock,
        legalBasisText: birthLegalBasisFor('en'),
      );
      final SubmissionBodies b = birthBodiesFrom(
        () {
          calls++;
          return payload;
        }(),
        'BD-2026-000456',
      );
      expect(calls, 1);
      expect(b.create.length, 79);
      expect(b.update.length, 80);
      expect(identical(b.create, b.update), isFalse,
          reason: 'two bodies, one payload — the update is a spread copy');
    });
  });
}

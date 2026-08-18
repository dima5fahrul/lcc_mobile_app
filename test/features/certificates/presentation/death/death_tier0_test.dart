/// Tier 0 — Death, the page-local gate. **405 leaves per locale, 12 documents.**
///
/// Written after Birth's Tier 0 was PASS (`specs.md` § 2.3 RULING 0,
/// `F2-AC-84`) and after the measured difference table was published in
/// `architecture-review.md` § 1 (`F2-AC-15`).
///
/// **`death.mother-skip` is the document to read twice.** 54 leaves, not 67:
/// the mother is emitted under `parents` *and* `parents.mother`, so skipping
/// her collapses **two** prefixes.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/case_reference_binding.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/death/death_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/death/death_payload.dart';

import '../../../../fidelity/oracle.dart';
import '../../../../fidelity/tier0_payload_equality_test.dart'
    show compareTier0, leafPaths, Tier0Result, valueAt;
import 'death_tier0_subject.dart';

void main() {
  final SubmissionClock clock = SubmissionClock.fixed(kDeathRegisterInstant);

  Map<String, dynamic> fixtureOf(String variant, String locale) =>
      readDeathJson('$kDeathFixtureDir/$variant.$locale.json');

  SubmissionBodies bodiesOf(String variant, String locale) {
    final Map<String, dynamic> fixture = fixtureOf(variant, locale);
    return deathBodiesFrom(
      buildDeathFormData(
        deathFormFromFixture(fixture),
        clock,
        legalBasisText: deathLegalBasisFor(locale),
      ),
      fixture['_reference_no'] as String,
    );
  }

  Tier0Oracle executed(String name) =>
      Tier0Oracle.load('$kDeathOracleDir/executed', name);

  // ── The twelve documents, per `specs.md` § 2.1.1 ──────────────────────────
  //
  //   death.create               80    death.update               81
  //   death.father-skip.create   67    death.father-skip.update   68
  //   death.mother-skip.create   54    death.mother-skip.update   55
  //
  // x 2 locales = 405 per locale, 12 documents.
  const Map<String, ({String fixture, int create, int update})> kDocs =
      <String, ({String fixture, int create, int update})>{
    'death': (fixture: 'baseline', create: 80, update: 81),
    'death.father-skip': (fixture: 'father-skip', create: 67, update: 68),
    'death.mother-skip': (fixture: 'mother-skip', create: 54, update: 55),
  };

  group('Tier 0 — Death, the real buildDeathFormData (F2)', () {
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
            exempt: kDeathExemptFormDataPointers,
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
          expect(got.keys.last, 'header.document_no');

          final Tier0Result r = compareTier0(
            oracle: want,
            actual: got,
            exempt: kDeathExemptFormDataPointers,
          );
          expect(r.passed, isTrue, reason: r.toString());
        });
      }
    }

    test('F2-AC-28 the Death total is 405 leaves per locale over 12 documents',
        () {
      int perLocale = 0;
      int documents = 0;
      for (final MapEntry<String, ({String fixture, int create, int update})>
          doc in kDocs.entries) {
        perLocale += doc.value.create + doc.value.update;
        documents += 4;
      }
      // ignore: avoid_print
      print('F2-AC-28 Death: $perLocale leaves per locale across $documents '
          'documents (${perLocale * 2} comparisons)');
      expect(perLocale, 405);
      expect(documents, 12);
    });

    test('F2-AC-31 the block arithmetic — and mother-skip collapses TWO '
        'prefixes', () {
      final List<String> keys = bodiesOf('baseline', 'en').create.keys.toList();
      int startingWith(String p) =>
          keys.where((String k) => k.startsWith(p)).length;

      // `80 = 5 + 21 + 14 + 14 + 14 + 12`.
      expect(startingWith('header.'), 5);
      expect(startingWith('deceased.'), 21);
      expect(
          keys
              .where((String k) =>
                  k.startsWith('parents.') &&
                  !k.startsWith('parents.mother.') &&
                  !k.startsWith('parents.father.'))
              .length,
          14,
          reason: 'Birth\'s is 13 — Death\'s parentData adds `workplace`');
      expect(startingWith('parents.mother.'), 14);
      expect(startingWith('parents.father.'), 14);
      expect(startingWith('informant.'), 12,
          reason: 'Birth\'s informant block is 15 — F2-AC-23');
      expect(keys.length, 80);

      // `father-skip = 80 - 14 + 1 = 67`.
      final Map<String, Object?> fs = bodiesOf('father-skip', 'en').create;
      expect(fs.keys.length, 67);
      expect(
          fs.keys.where((String k) => k.startsWith('parents.father')).toList(),
          equals(<String>['parents.father.status']));
      expect(fs['parents.father.status'], kDeathParentSkipStatus);
      expect(fs['parents.father.status'], 'deceased-or-unknown',
          reason: 'Birth\'s is "unknown" — F2-AC-22');

      // `mother-skip = 80 - 14 - 14 + 1 + 1 = 54`. **The two-prefix collapse.**
      // If this reads 67, the port collapsed one prefix instead of two and the
      // whole mother double-emission is wrong (specs.md § 11 item 7).
      final Map<String, Object?> ms = bodiesOf('mother-skip', 'en').create;
      expect(ms.keys.length, 54,
          reason: '54, not 67 — motherSkip collapses `parents` AND '
              '`parents.mother`, because the mother is emitted under both');
      expect(ms['parents.status'], 'deceased-or-unknown');
      expect(ms['parents.mother.status'], 'deceased-or-unknown');
      expect(
          ms.keys
              .where((String k) =>
                  k.startsWith('parents.') &&
                  !k.startsWith('parents.mother.') &&
                  !k.startsWith('parents.father.'))
              .toList(),
          equals(<String>['parents.status']));
      expect(startingWith('parents.father.'), 14);
      expect(
          ms.keys.where((String k) => k.startsWith('parents.father.')).length,
          14,
          reason: 'motherSkip must not collapse the father block too');
    });

    test('F2-AC-20/21/22 deathParentData takes 3 parameters, emits 14 keys, '
        'and branches INSIDE', () {
      final Map<String, Object?> full =
          deathParentData(const DeathParentInfo(), 'p', false);
      expect(full.length, 14);
      expect(
          full.keys.toList(),
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
            'p.workplace',
          ]));

      // The skip branch is inside the function — Birth's is at the call site
      // and Birth's helper has no skip branch at all.
      final Map<String, Object?> skipped =
          deathParentData(const DeathParentInfo(fullName: 'kept'), 'p', true);
      expect(skipped, <String, Object?>{'p.status': 'deceased-or-unknown'});
      expect(skipped.length, 1,
          reason: 'the skip discards the record entirely — but the RECORD is '
              'not cleared in state, so toggling back restores it (F2-AC-69)');
    });

    test('F2-AC-44 place_of_death_country is the literal "Laos" from the blank '
        'record, in all 12 death documents', () {
      // Driver-inert: the place-of-death LocationFields handler (`:1210-1216`)
      // enumerates province/district/village and stops, and there is no country
      // control on the page. F0 § 6.5.7 REFUSED to exempt it — an exempted leaf
      // catches nothing forever while a compared one still catches a pin that
      // moves.
      expect(const DeathDeceasedInfo().podCountry, 'Laos');
      int checked = 0;
      for (final MapEntry<String, ({String fixture, int create, int update})>
          doc in kDocs.entries) {
        for (final String locale in <String>['en', 'lo']) {
          final SubmissionBodies b = bodiesOf(doc.value.fixture, locale);
          for (final Map<String, Object?> body
              in <Map<String, Object?>>[b.create, b.update]) {
            expect(body['deceased.place_of_death_country'], 'Laos');
            checked++;
          }
        }
      }
      // ignore: avoid_print
      print('F2-AC-44: $checked death documents carry the literal "Laos"');
      expect(checked, 12);
    });

    test('F2-AC-62 cause_of_death_other is emitted UNCONDITIONALLY, with no '
        'length cap', () {
      // The control renders only when `cause == "other"` (`:1245`), and the key
      // goes out regardless (`:811`), empty otherwise. Eliding it would change
      // the key count.
      final Map<String, Object?> notOther = buildDeathFormData(
        const DeathFormData(
          deceased: DeathDeceasedInfo(cause: 'illness', causeOther: ''),
        ),
        clock,
        legalBasisText: 'x',
      );
      expect(notOther.containsKey('deceased.cause_of_death_other'), isTrue);
      expect(notOther['deceased.cause_of_death_other'], '');

      // No cap. Resident's `purposeOther` has a 100-char one; adding it here by
      // analogy FAILS.
      final String long = 'x' * 500;
      final Map<String, Object?> other = buildDeathFormData(
        DeathFormData(
          deceased: DeathDeceasedInfo(cause: 'other', causeOther: long),
        ),
        clock,
        legalBasisText: 'x',
      );
      expect(other['deceased.cause_of_death_other'], long);
      expect((other['deceased.cause_of_death_other']! as String).length, 500);
    });

    test('F2-AC-46 every emitted value is a String', () {
      for (final MapEntry<String, ({String fixture, int create, int update})>
          doc in kDocs.entries) {
        for (final String locale in <String>['en', 'lo']) {
          for (final MapEntry<String, Object?> e
              in bodiesOf(doc.value.fixture, locale).update.entries) {
            expect(e.value, isA<String>(),
                reason: '${doc.key}.$locale ${e.key}');
          }
        }
      }
    });

    test('F2-AC-29 every update body is its create body + 1, appended last',
        () {
      for (final MapEntry<String, ({String fixture, int create, int update})>
          doc in kDocs.entries) {
        for (final String locale in <String>['en', 'lo']) {
          final SubmissionBodies b = bodiesOf(doc.value.fixture, locale);
          expect(b.update.keys.toList(),
              equals(<String>[...b.create.keys, 'header.document_no']));
        }
      }
    });

    test('F2-AC-34 the locale inequality guard fires on header.legal_basis',
        () {
      for (final String body in <String>['create', 'update']) {
        expect(
            valueAt(executed('death.$body.en').formData, '/header.legal_basis'),
            isNot(equals(valueAt(
                executed('death.$body.lo').formData, '/header.legal_basis'))));
      }
      expect(bodiesOf('baseline', 'en').create['header.legal_basis'],
          isNot(equals(
              bodiesOf('baseline', 'lo').create['header.legal_basis'])));
    });

    test('F2-AC-35 the complement — every OTHER leaf is byte-identical across '
        'locales', () {
      int compared = 0;
      for (final MapEntry<String, ({String fixture, int create, int update})>
          doc in kDocs.entries) {
        final SubmissionBodies en = bodiesOf(doc.value.fixture, 'en');
        final SubmissionBodies lo = bodiesOf(doc.value.fixture, 'lo');
        for (final (Map<String, Object?> a, Map<String, Object?> b)
            in <(Map<String, Object?>, Map<String, Object?>)>[
          (en.create, lo.create),
          (en.update, lo.update),
        ]) {
          for (final String k in a.keys) {
            if (k == 'header.legal_basis') continue;
            expect(jsonEncode(b[k]), equals(jsonEncode(a[k])),
                reason: '${doc.key} $k differs across locales but is not the '
                    'one registered locale-dependent key — an accidental '
                    '.tr(). Over-localisation is the likelier Flutter mistake.');
            compared++;
          }
        }
      }
      // ignore: avoid_print
      print('F2-AC-35 Death complement: $compared leaf pairs compared');
      // 79+80 + 66+67 + 53+54 = 399 — the six bodies minus their legal_basis.
      expect(compared, 399);
    });

    test('F2-AC-38 header.dated is the LOCAL date, positively asserted', () {
      expect(bodiesOf('baseline', 'en').create['header.dated'],
          kDeathExpectedLocal);
      expect(executed('death.create.en').formData['header.dated'],
          kDeathExpectedWebUtc,
          reason: 'the oracle must still carry the WEB value, or the '
              'divergence has gone invisible');
    });

    test('F2-AC-39 event_date is asserted positively against the fixture in '
        'all 12 Death documents', () {
      int checked = 0;
      for (final MapEntry<String, ({String fixture, int create, int update})>
          doc in kDocs.entries) {
        for (final String locale in <String>['en', 'lo']) {
          final Map<String, dynamic> fixture =
              fixtureOf(doc.value.fixture, locale);
          final String dod = (fixture['deceased']
              as Map<String, dynamic>)['dateOfDeath'] as String;
          expect(dod.isNotEmpty, isTrue,
              reason: 'precondition: the fixture sets dateOfDeath, which is '
                  'why the register row is unreachable');
          expect(deathEventDate(deathFormFromFixture(fixture), clock), dod);
          for (final String body in <String>['create', 'update']) {
            final Map<String, dynamic> env = executed('${doc.key}.$body.$locale')
                .json['envelope']! as Map<String, dynamic>;
            expect((env['event_date']! as Map<String, dynamic>)['value'], dod);
            checked++;
          }
        }
      }
      // ignore: avoid_print
      print('F2-AC-39 Death: $checked event_date envelope keys asserted '
          'positively against fixture input');
      expect(checked, 12);
    });

    test('F2-AC-40 the `|| today()` fallback emits the LOCAL date', () {
      const DeathFormData blank = DeathFormData();
      expect(blank.deceased.dateOfDeath, '');
      expect(deathEventDate(blank, clock), kDeathExpectedLocal,
          reason: 'the local value, not the UTC 2026-08-13');
    });

    test('F2-AC-41 exactly FOUR Death rows are exempt, and no more', () {
      expect(kDeathExemptFormDataPointers, <String>{'/header.dated'});
      expect(kDeathExemptEnvelopeKeys, <String>{'event_date'});
      final Map<String, Object?> got = bodiesOf('baseline', 'en').create;
      final int exemptLeaves =
          leafPaths(got).where(kDeathExemptFormDataPointers.contains).length;
      expect(exemptLeaves, 1);
      expect(leafPaths(got).length - exemptLeaves, 79);
    });

    test('F2-AC-42 no Death leaf is NOT EVALUATED', () {
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

    test('F2-AC-33 the harness FAILS on Death, naming the leaf and document',
        () {
      // The SECOND of the two demonstrations `F2-AC-33` requires — one on each
      // new form, because F2 inherited a green instrument.
      final Map<String, Object?> good = bodiesOf('baseline', 'en').create;
      final Map<String, Object?> bad = Map<String, Object?>.of(good);
      bad['deceased.deceased_name'] = '${good['deceased.deceased_name']}X';

      final Tier0Result r = compareTier0(
        oracle: good,
        actual: bad,
        exempt: kDeathExemptFormDataPointers,
      );
      expect(r.passed, isFalse);
      expect(r.toString(), contains('/deceased.deceased_name'));
      // ignore: avoid_print
      print('F2-AC-33 death.create.en planted mutant: ${r.toString()}');
    });

    test('F2-AC-43 the comparison is on BYTES, on Death\'s own body', () {
      final Map<String, Object?> good = bodiesOf('baseline', 'en').create;

      final Map<String, Object?> retyped = Map<String, Object?>.of(good)
        ..['deceased.time_of_death'] = 42;
      expect(
        compareTier0(
          oracle: good,
          actual: retyped,
          exempt: kDeathExemptFormDataPointers,
        ).passed,
        isFalse,
      );

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
          exempt: kDeathExemptFormDataPointers,
        ).passed,
        isFalse,
        reason: 'insertion order IS wire order (client.ts:242)',
      );
    });

    test('F2-AC-30 buildDeathFormData is invoked exactly ONCE per submission',
        () {
      int calls = 0;
      final Map<String, Object?> payload = buildDeathFormData(
        deathFormFromFixture(fixtureOf('baseline', 'en')),
        clock,
        legalBasisText: deathLegalBasisFor('en'),
      );
      final SubmissionBodies b = deathBodiesFrom(
        () {
          calls++;
          return payload;
        }(),
        'DD-2026-000789',
      );
      expect(calls, 1);
      expect(b.create.length, 80);
      expect(b.update.length, 81);
    });
  });
}

/// The two date formatters — **B7-AC-77**, **B7-AC-78**, **B7-AC-79**,
/// **B7-AC-80**.
///
/// ## Every assertion here is timezone-INDEPENDENT, and that is `B7-AC-79`
///
/// Rendering is in the **device's local zone** (`toLocaleDateString`), so
/// `2026-12-31T23:59:00Z` is `01 Jan 2027` at UTC+7 and `31 Dec 2026` at UTC.
/// `B7-AC-79` says a test that passes only at UTC+7 is a FAIL — and Dart cannot
/// change the local zone inside a running isolate, so a literal `TZ` pin is not
/// available from within the test.
///
/// The resolution used here: **no assertion names an absolute rendering of an
/// instant.** Each one states a property that holds in every zone — the month
/// table's contents, locale-invariance of the time half, offset-stability
/// (the same instant written two ways renders identically), the two fallbacks,
/// and agreement/divergence *between the two formatters*. The suite was then
/// run under `TZ=UTC` and `TZ=Asia/Vientiane` and passes in both; that pair of
/// runs is the pin, and it is recorded in the batch report rather than
/// asserted here, because a test cannot assert the environment it was run in.
///
/// ## `B7-AC-77` FAILS, and the spec's premise is why
///
/// § 6.7 states the two copies differ "in **exactly one** respect: the
/// absent-value sentinel". **Measured, they differ in two.** This copy calls
/// `.toLocal()` (`application_formatting.dart:130`); `formatNewsDate` does not
/// (`news_formatting.dart:70`), so it reads the **UTC** components of a `Z`
/// input. They therefore disagree on every instant whose local date differs
/// from its UTC date — at UTC+7 that is any UTC time at or after 17:00.
///
/// **This copy is the correct one.** The source is `toLocaleDateString`, which
/// is local, and § 6.7's own ICU probe table records
/// `2026-12-31T23:59:00Z → 01 Jan 2027` at UTC+7 — the local answer. So the
/// divergence is a defect in `news_formatting.dart`, not here, and "fixing" this
/// copy to agree would break fidelity to satisfy an AC.
///
/// `lib/features/news/**` is not in B7b's § 3.1 scope, so it is **not** fixed
/// here. The divergence is pinned below instead, so it cannot widen silently
/// and whoever owns the fix inherits a failing assertion that names it.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/application/domain/application_formatting.dart';
import 'package:lcc_mobile_app/features/news/domain/news_formatting.dart';

/// `dd` — the source zero-pads the day (`day: "2-digit"`).
String _pad(int n) => n.toString().padLeft(2, '0');

/// What [formatApplicationDate] must return for [iso], derived in whatever zone
/// this test happens to run in. Verifies the table lookup, the padding and the
/// `dd MMM yyyy` order without naming a zone.
String _expectedDate(String iso, List<String> months) {
  final DateTime local = DateTime.parse(iso).toLocal();
  return '${_pad(local.day)} ${months[local.month - 1]} ${local.year}';
}

void main() {
  /// All 12 months, both boundaries, and the year-crossing instant § 6.7 names.
  const List<String> corpus = <String>[
    '2026-01-15T00:00:00Z',
    '2026-02-28T12:00:00Z',
    '2026-03-01T23:59:00Z',
    '2026-04-30T06:00:00Z',
    '2026-05-31T18:30:00Z',
    '2026-06-15T09:15:00Z',
    '2026-07-04T11:45:00Z',
    '2026-08-14T14:05:00Z',
    '2026-09-03T09:30:00Z',
    '2026-10-31T22:10:00Z',
    '2026-11-30T03:20:00Z',
    '2026-12-31T23:59:00Z',
  ];

  group('B7-AC-80 — September is `Sept`, four characters', () {
    test('the en table has Sept at index 8', () {
      expect(kApplicationShortMonthsEn[8], 'Sept');
      expect(kApplicationShortMonthsEn[8].length, 4,
          reason: 'en-GB renders four characters, not `Sep`');
    });

    test('the lo table has ກ.ຍ. at index 8', () {
      expect(kApplicationShortMonthsLo[8], 'ກ.ຍ.');
    });

    test('a September instant renders Sept / ກ.ຍ. in the local zone', () {
      // `12:00Z` so the rendered month is September in every real zone.
      const String sep = '2026-09-03T12:00:00Z';
      expect(formatApplicationDate(sep, 'en'), contains('Sept'));
      expect(formatApplicationDate(sep, kLaoCode), contains('ກ.ຍ.'));
    });
  });

  group('B7-AC-78 — the two fallbacks', () {
    test('absent → "—" (an em dash), both formatters', () {
      expect(formatApplicationDate(null, 'en'), kAbsentDate);
      expect(formatApplicationDate('', 'en'), kAbsentDate);
      expect(formatApplicationDateTime(null, 'en'), kAbsentDate);
      expect(formatApplicationDateTime('', 'en'), kAbsentDate);
      expect(kAbsentDate, '—');
    });

    test('unparseable → the input VERBATIM, not the sentinel', () {
      // `Number.isNaN(d.getTime()) → return value` — `:88`, `:99`.
      //
      // NOTE `'2026-13-45'` is NOT a usable case here: `DateTime.tryParse`
      // ROLLS OVER out-of-range components (month 13 → Feb of the next year)
      // rather than rejecting them, so it parses and renders `14 Feb 2027`.
      // Measured. A test using it would assert the opposite of what it reads.
      expect(formatApplicationDate('not-a-date', 'en'), 'not-a-date');
      expect(formatApplicationDateTime('not-a-date', 'en'), 'not-a-date');
      expect(formatApplicationDate('12/03/2026', 'en'), '12/03/2026');
    });

    test('an unparseable input gets NO ", HH:MM" appended', () {
      // The guards run before the compose — `:97-99`.
      expect(formatApplicationDateTime('not-a-date', 'en'), isNot(contains(',')));
    });

    test('the two fallbacks are distinguishable', () {
      expect(formatApplicationDate('', 'en'),
          isNot(formatApplicationDate('not-a-date', 'en')));
    });
  });

  group('B7-AC-79 — locale-invariant time, and zone-independent tests', () {
    test('en and lo render the SAME 24-hour HH:MM for every corpus instant',
        () {
      for (final String iso in corpus) {
        final String en = formatApplicationDateTime(iso, 'en');
        final String lo = formatApplicationDateTime(iso, kLaoCode);

        expect(en.split(', ').last, lo.split(', ').last,
            reason: 'the time half must not vary by locale — § 6.7(2) — on $iso');
        expect(en.split(', ').last, matches(RegExp(r'^\d{2}:\d{2}$')),
            reason: 'zero-padded 24-hour, on $iso');
      }
    });

    test('only the MONTH differs between the two locales', () {
      const String iso = '2026-08-14T12:00:00Z';
      final String en = formatApplicationDateTime(iso, 'en');
      final String lo = formatApplicationDateTime(iso, kLaoCode);

      expect(en, isNot(lo));
      expect(
        en.replaceAll(kApplicationShortMonthsEn[7], 'M'),
        lo.replaceAll(kApplicationShortMonthsLo[7], 'M'),
        reason: 'swap the month name out and the two renders are identical',
      );
    });

    test('offset-stable — the same instant written two ways renders the same',
        () {
      // `2026-12-31T23:59:00Z` and `2027-01-01T06:59:00+07:00` are ONE instant.
      // This holds in every zone; it is the property, not a UTC+7 answer.
      for (final String lang in <String>['en', kLaoCode]) {
        expect(
          formatApplicationDateTime('2026-12-31T23:59:00Z', lang),
          formatApplicationDateTime('2027-01-01T06:59:00+07:00', lang),
        );
        expect(
          formatApplicationDate('2026-12-31T23:59:00Z', lang),
          formatApplicationDate('2027-01-01T06:59:00+07:00', lang),
        );
      }
    });

    test('the whole corpus renders `dd MMM yyyy` from the LOCAL components', () {
      for (final String iso in corpus) {
        expect(formatApplicationDate(iso, 'en'),
            _expectedDate(iso, kApplicationShortMonthsEn),
            reason: 'on $iso');
        expect(formatApplicationDate(iso, kLaoCode),
            _expectedDate(iso, kApplicationShortMonthsLo),
            reason: 'on $iso');
      }
    });

    test('formatDateTime composes formatDate — `:100`', () {
      for (final String iso in corpus) {
        expect(formatApplicationDateTime(iso, 'en'),
            startsWith('${formatApplicationDate(iso, 'en')}, '),
            reason: 'on $iso');
      }
    });
  });

  group('B7-AC-77 — agreement with `news_formatting.formatNewsDate`', () {
    test('the month tables are the same 12 strings', () {
      expect(kApplicationShortMonthsEn, kNewsShortMonthsEn);
      expect(kApplicationShortMonthsLo, kNewsShortMonthsLo);
    });

    test('they agree on every instant whose LOCAL date equals its UTC date',
        () {
      // Where the zone cannot make a difference, the two are byte-identical —
      // which isolates the divergence below to the timezone basis alone, and
      // proves the tables, padding and ordering do match.
      final Iterable<String> sameDay = corpus.where((String iso) {
        final DateTime utc = DateTime.parse(iso).toUtc();
        final DateTime local = DateTime.parse(iso).toLocal();
        return utc.day == local.day &&
            utc.month == local.month &&
            utc.year == local.year;
      });
      expect(sameDay, isNotEmpty, reason: 'the corpus must exercise this arm');

      for (final String iso in sameDay) {
        for (final String lang in <String>['en', kLaoCode]) {
          expect(formatApplicationDate(iso, lang), formatNewsDate(iso, lang),
              reason: 'on $iso / $lang');
        }
      }
    });

    test('they agree on an unparseable input — both return it verbatim', () {
      expect(formatApplicationDate('rubbish', 'en'),
          formatNewsDate('rubbish', 'en'));
    });

    test('and they DIFFER on empty — "—" here, "" there (the § 6.7 difference)',
        () {
      expect(formatApplicationDate('', 'en'), '—');
      expect(formatNewsDate('', 'en'), '');
    });

    test(
        'THE SECOND DIFFERENCE § 6.7 DOES NOT RECORD — formatNewsDate reads UTC '
        'components where this copy reads LOCAL ones', () {
      // Pinned, not fixed: `lib/features/news/**` is outside B7b's § 3.1 scope.
      // This copy is the correct one — the source is `toLocaleDateString` and
      // § 6.7's own ICU probe records the local answer.
      //
      // Stated as a property so it holds in every zone: at UTC the two agree
      // everywhere and this test asserts only the tautology; away from UTC it
      // asserts the real divergence.
      const String iso = '2026-12-31T23:59:00Z';
      final DateTime utc = DateTime.parse(iso).toUtc();
      final DateTime local = DateTime.parse(iso).toLocal();

      expect(formatNewsDate(iso, 'en'),
          '${_pad(utc.day)} ${kNewsShortMonthsEn[utc.month - 1]} ${utc.year}',
          reason: 'news reads UTC — `news_formatting.dart:70`, no .toLocal()');
      expect(formatApplicationDate(iso, 'en'),
          '${_pad(local.day)} ${kApplicationShortMonthsEn[local.month - 1]} '
          '${local.year}',
          reason: 'this copy reads local — `application_formatting.dart:130`');

      if (utc.day != local.day) {
        expect(formatApplicationDate(iso, 'en'), isNot(formatNewsDate(iso, 'en')),
            reason: 'B7-AC-77 as written cannot pass — see the library doc');
      }
    });
  });
}

/// `vientianeCalendarDate` — **review M-7, 2026-10-22.**
///
/// The spec splits dates from date-times and judges validity on the Vientiane
/// calendar (§ Authentication and conventions). `revoked_at` is the one
/// date-**time** the verification screens render, and `DateTime.parse`
/// normalises its `+07:00` to UTC — so a revocation at 00:30 Vientiane read as
/// the previous day on the screen whose entire job is telling somebody whether
/// to accept a document.
///
/// **Every case here is machine-timezone independent**, which is the property
/// that makes this testable at all: the implementation never asks the device
/// what zone it is in, so these expectations hold on a CI runner in UTC and on
/// a developer's laptop in Vientiane alike.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/home/domain/home_formatting.dart'
    show formatDate;
import 'package:lcc_mobile_app/features/verify/domain/vientiane_calendar.dart';

void main() {
  group('the defect M-7 names', () {
    test('00:30+07:00 is TODAY in Vientiane, not yesterday', () {
      // `DateTime.parse` gives 2026-10-21T17:30Z, whose `.day` is 21.
      expect(DateTime.parse('2026-10-22T00:30:00+07:00').day, 21,
          reason: 'the non-vacuity control: this IS what the old code read');

      expect(vientianeCalendarDate('2026-10-22T00:30:00+07:00'), '2026-10-22');
      expect(formatDate(vientianeCalendarDate('2026-10-22T00:30:00+07:00'),
          'en'), '22 Oct 2026');
    });

    test('the property the implementation rests on: an offset-bearing string '
        'parses to a DateTime that is ALREADY UTC', () {
      // `layering_test.dart`'s ADR-0005 O-4 forbids `toUtc()` anywhere in
      // `lib/**`, so the shift is `parsed.add(7h)` on the assumption that
      // `DateTime.parse` has already normalised. That assumption is pinned
      // here rather than trusted: if it ever stopped holding, these three
      // would go red and the `!isUtc` guard in the implementation would start
      // returning values verbatim instead of shifting them wrongly.
      expect(DateTime.parse('2026-10-22T00:30:00+07:00').isUtc, isTrue);
      expect(DateTime.parse('2026-10-21T17:30:00Z').isUtc, isTrue);
      expect(DateTime.parse('2026-10-21T20:00:00-04:00').isUtc, isTrue);
      // The complement, which is why the regex gate exists at all.
      expect(DateTime.parse('2026-09-30T10:42:18').isUtc, isFalse);
    });

    test('23:30+07:00 does not roll FORWARD either', () {
      expect(vientianeCalendarDate('2026-10-22T23:30:00+07:00'), '2026-10-22');
    });

    test('the same instant written as Z lands on the same Vientiane day', () {
      // 2026-10-21T17:30Z IS 2026-10-22T00:30+07:00.
      expect(vientianeCalendarDate('2026-10-21T17:30:00Z'), '2026-10-22');
    });

    test('a non-Vientiane offset is converted, not trusted', () {
      // 2026-10-21T20:00-04:00 is 2026-10-22T07:00+07:00.
      expect(vientianeCalendarDate('2026-10-21T20:00:00-04:00'), '2026-10-22');
    });

    test('the offset may be written without a colon', () {
      expect(vientianeCalendarDate('2026-10-22T00:30:00+0700'), '2026-10-22');
    });

    test('a month and a year boundary are crossed correctly', () {
      expect(vientianeCalendarDate('2026-12-31T18:00:00Z'), '2027-01-01');
      expect(vientianeCalendarDate('2026-01-31T18:00:00Z'), '2026-02-01');
    });

    test('the output is zero-padded, so `formatDate` can parse it back', () {
      expect(vientianeCalendarDate('2026-01-01T00:30:00+07:00'), '2026-01-01');
      expect(formatDate(vientianeCalendarDate('2026-01-01T00:30:00+07:00'),
          'en'), '01 Jan 2026');
    });
  });

  group('what it must NOT touch', () {
    test('a plain YYYY-MM-DD comes back unchanged — `issued_at`, '
        '`valid_until`', () {
      // These two carry no offset and no instant. Shifting them would invent
      // one, and the spec calls them calendar dates.
      for (final String date in <String>[
        '2026-09-30',
        '2026-12-29',
        '2026-01-01',
      ]) {
        expect(vientianeCalendarDate(date), date, reason: date);
      }
    });

    test('a naive date-time with NO offset comes back unchanged', () {
      // `DateTime.parse` would read it in the DEVICE's zone, so shifting it
      // would make the rendered day depend on where the phone is.
      expect(
        vientianeCalendarDate('2026-09-30T10:42:18'),
        '2026-09-30T10:42:18',
      );
    });

    test('an empty value and an unparseable one come back verbatim', () {
      expect(vientianeCalendarDate(''), '');
      expect(vientianeCalendarDate('not a date'), 'not a date');
      // Instant-shaped but not parseable — the verbatim fallback, which is
      // `formatDate`'s own contract for the same case.
      expect(
        vientianeCalendarDate('2026-10-2xT00:30:00+07:00'),
        '2026-10-2xT00:30:00+07:00',
      );
    });

    test('out-of-range components are NORMALISED, not rejected — the shared '
        '`DateTime.tryParse` behaviour, recorded not changed', () {
      // `DateTime.tryParse('2026-13-45T…')` succeeds and rolls over; the
      // app's existing `formatDate` has always behaved this way on the same
      // input. Pinned here so the rollover is a known property rather than a
      // surprise, and so a future tightening is a deliberate change.
      expect(vientianeCalendarDate('2026-13-45T99:99:99+07:00'), '2027-02-18');
    });
  });
}

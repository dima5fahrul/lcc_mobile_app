/// **B9-AC-39 (the chat half) — `clockTime` returns `""` on an unparseable
/// timestamp and never throws.**
///
/// specs.md § 6.13: *"Both empty-string guards are load-bearing and must be
/// tested, because a Dart `DateTime.parse` on a malformed string throws where
/// JS yields `NaN` and the component renders `""`. An uncaught
/// `FormatException` inside a chat bubble is a crash the source does not
/// have."*
///
/// The transcript is **server-supplied**, so "the backend will always send a
/// valid ISO timestamp" is an assumption and not a guarantee. Each malformed
/// input below is a real shape a JSON field can hold.
///
/// `relativeTime` — the notification bell's formatter, with the `numeric:
/// "auto"` forms and the year/month/week/day/hour/minute step order — is
/// **B9a's**, tested in `relative_time_test.dart`. The chat renders no relative
/// time at all.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/chat/presentation/widgets/clock_time.dart';

void main() {
  group('the two empty-string guards — `:21-23`', () {
    test('null and empty answer ""', () {
      expect(chatClockTime(null), '');
      expect(chatClockTime(''), '');
    });

    test('an unparseable value answers "" rather than throwing', () {
      const List<String> malformed = <String>[
        'not a date',
        'garbage',
        '2026-13-45T99:99:99',
        '2026-02-30T10:00:00Z',
        '0',
        '   ',
        '{}',
        '[]',
        'null',
        'NaN',
        '2026/08/13 09:14',
        '13-08-2026',
        'ບໍ່ແມ່ນວັນທີ',
      ];

      for (final String value in malformed) {
        expect(() => chatClockTime(value), returnsNormally, reason: value);
        expect(chatClockTime(value), '', reason: value);
      }
    });

    test('OUT-OF-RANGE components are rejected, not rolled over — the half '
        '`tryParse` does not cover', () {
      // MEASURED, and it corrects a premise in specs.md § 6.13, which frames
      // the whole difficulty as "Dart throws where JS yields NaN". Dart's ISO
      // parser does not throw on these — it ROLLS THEM OVER, and a
      // tryParse-only port therefore prints a plausible, wrong time where the
      // source prints nothing.
      expect(DateTime.tryParse('2026-13-45T99:99:99'), isNotNull,
          reason: 'the premise: tryParse ACCEPTS this');
      expect(DateTime.parse('2026-13-45T99:99:99').year, 2027,
          reason: 'and rolls it into the following February');
      expect(DateTime.parse('2026-02-30T10:00:00Z').month, 3,
          reason: 'and rolls the 30th of February into the 2nd of March');

      // `new Date(...)` on either of these is an Invalid Date, so the source
      // renders "". So does this.
      expect(chatClockTime('2026-13-45T99:99:99'), '');
      expect(chatClockTime('2026-02-30T10:00:00Z'), '');
      expect(chatClockTime('2026-00-00T00:00:00'), '');
    });

    test('a VALID date is not rejected by the rollover guard — including one '
        'the guard has to convert', () {
      expect(chatClockTime('2026-08-13T09:14:00'), '09:14');
      // The leap-year pair, which is the sharpest evidence that the guard
      // compares what came OUT of the parser rather than pattern-matching the
      // string: the two inputs are identical but for the year.
      expect(chatClockTime('2024-02-29T09:14:00'), '09:14',
          reason: '2024 IS a leap year, so the date is real and renders');
      expect(chatClockTime('2026-02-29T09:14:00'), '',
          reason: '2026 is not, so `new Date` gives an Invalid Date and the '
              'source renders "". Dart rolls it to Mar 1 and a tryParse-only '
              'port would print 09:14 for a day that does not exist.');
      expect(chatClockTime('2026-12-31T23:59:00'), '23:59');
      expect(chatClockTime('2026-08-13T09:14:00Z'), isNot(''),
          reason: 'a Z form is compared against its UTC fields, not its local '
              'ones — otherwise every non-UTC machine would reject it');
    });

    test('the guard is what stops a FormatException reaching a chat bubble', () {
      // The failure mode this exists to prevent, written out: the naive port.
      expect(() => DateTime.parse('not a date'), throwsFormatException);
      // …and the one that ships.
      expect(chatClockTime('not a date'), '');
    });
  });

  group('the format — `{hour: "2-digit", minute: "2-digit"}`', () {
    test('both fields are zero-padded', () {
      expect(chatClockTime('2026-08-13T09:04:00'), '09:04');
      expect(chatClockTime('2026-08-13T00:00:00'), '00:00');
    });

    test('24-hour, so afternoon does not wrap to 12', () {
      expect(chatClockTime('2026-08-13T14:05:00'), '14:05');
      expect(chatClockTime('2026-08-13T23:59:00'), '23:59');
      expect(
        chatClockTime('2026-08-13T14:05:00'),
        isNot(contains('PM')),
        reason: 'B9B-DIV-2: `en-GB` and `lo-LA` — the app\'s two locales — are '
            'both 24-hour for this option set. The web reads the HOST locale, '
            'so a device set to `en-US` would disagree; that divergence is '
            'recorded in b9_divergences.yaml, not absorbed here.',
      );
    });

    test('seconds and sub-seconds are dropped', () {
      expect(chatClockTime('2026-08-13T09:14:59.999'), '09:14');
    });

    test('a zone-naive timestamp renders the same wall clock on any machine',
        () {
      // Which is why the fixture uses this form — see
      // `me-chat-messages.json`'s `timestamps_are_zone_naive` note. Both
      // ECMAScript and Dart treat a date-TIME form with no marker as local, so
      // this assertion holds under any TZ the suite runs in.
      expect(chatClockTime('2026-08-13T09:14:00'), '09:14');
      expect(chatClockTime('2026-08-13T09:19:00'), '09:19');
    });

    test('an explicit offset is converted to local, as toLocaleTimeString does',
        () {
      final DateTime utc = DateTime.utc(2026, 8, 13, 9, 14);
      final DateTime local = utc.toLocal();
      final String expected =
          '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';

      expect(chatClockTime('2026-08-13T09:14:00Z'), expected);
      expect(chatClockTime('2026-08-13T09:14:00+00:00'), expected);
    });
  });
}

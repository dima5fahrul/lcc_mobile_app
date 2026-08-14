/// **`F0-AC-28`** — `todayLocal()` is local, and the web-derived oracle for the
/// same key is a different date at the same instant. Both halves required
/// (ADR-0005 point 5).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';

const String _oracleDir =
    '../../docs/fidelity-baseline/2026-08-13/oracle/tier0';

void main() {
  /// `2026-08-14T02:00:00+07:00` — the instant ADR-0005 point 5 names, and the
  /// one every Tier 0 oracle carries in its `clock` field.
  final DateTime instant = DateTime.parse('2026-08-14T02:00:00+07:00');

  group('F0-AC-28 — the divergence, both halves', () {
    test('half 1: todayLocal() returns 2026-08-14 at +07:00', () {
      // `.toLocal()` because a Dart `DateTime` parsed with an offset is a UTC
      // instant; the clock's contract is that it hands out a LOCAL time, which
      // is what the app's own `DateTime.now()` returns.
      final SubmissionClock clock = SubmissionClock.fixed(
        instant.toUtc().add(const Duration(hours: 7)),
      );
      expect(clock.todayLocal(), '2026-08-14');
    });

    test('half 2: and the web-derived oracle for the same key holds '
        '2026-08-13', () {
      // This is the half that keeps the fix visible after freezing hides it. If
      // it ever stops holding, either the oracle was re-derived against a
      // different instant or somebody "fixed" the web.
      final Map<String, dynamic> o = jsonDecode(
        File('$_oracleDir/resident.create.en.json').readAsStringSync(),
      ) as Map<String, dynamic>;

      expect(o['clock'], '2026-08-14T02:00:00+07:00');

      final Map<String, dynamic> env =
          o['createEnvelope'] as Map<String, dynamic>;
      expect((env['event_date'] as Map<String, dynamic>)['value'], '2026-08-13',
          reason: '`new Date().toISOString().slice(0, 10)` is UTC, so at '
              '02:00+07:00 the web dates this YESTERDAY. That is the defect '
              'ADR-0005 fixes and the reason both halves are asserted.');
    });

    test('the two halves really do differ — the assertion is not tautological',
        () {
      final SubmissionClock clock = SubmissionClock.fixed(
        instant.toUtc().add(const Duration(hours: 7)),
      );
      final Map<String, dynamic> o = jsonDecode(
        File('$_oracleDir/resident.create.en.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final Object? webValue =
          ((o['createEnvelope'] as Map<String, dynamic>)['event_date']
              as Map<String, dynamic>)['value'];

      expect(clock.todayLocal(), isNot(webValue));
    });
  });

  group('the clock is injected, and formats without a round trip', () {
    test('a fixed clock is deterministic across calls', () {
      final SubmissionClock clock =
          SubmissionClock.fixed(DateTime(2026, 1, 2, 23, 59));
      expect(clock.todayLocal(), '2026-01-02');
      expect(clock.todayLocal(), '2026-01-02');
    });

    test('zero-padding is explicit — single-digit months and days', () {
      expect(SubmissionClock.fixed(DateTime(2026, 1, 2)).todayLocal(),
          '2026-01-02');
      expect(SubmissionClock.fixed(DateTime(2026, 12, 31)).todayLocal(),
          '2026-12-31');
      expect(SubmissionClock.fixed(DateTime(999, 3, 4)).todayLocal(),
          '0999-03-04');
    });

    test('the system clock reads local time, not UTC', () {
      // The capability, asserted rather than the wiring: build a clock from a
      // local instant one hour past midnight and confirm the emitted date is
      // that local day. Under a `toUtc()` it would be the previous one for any
      // reader east of Greenwich.
      final DateTime localEarlyMorning = DateTime(2026, 8, 14, 1, 0);
      expect(
        SubmissionClock.fixed(localEarlyMorning).todayLocal(),
        '2026-08-14',
      );
      expect(
        SubmissionClock.fixed(localEarlyMorning.toUtc()).todayLocal(),
        isNot('2026-08-14'),
        reason: 'if this ever passes, the machine is running at UTC+0 or west '
            'of it and the assertion above stopped being evidence — which is '
            'itself worth knowing',
        skip: DateTime.now().timeZoneOffset.inHours <= 0
            ? 'host is at UTC or west of it; the divergence is unobservable here'
            : null,
      );
    });

    test('SubmissionClock.system() exists and reads a live instant', () {
      final SubmissionClock clock = SubmissionClock.system();
      final DateTime a = clock.now();
      expect(a.isUtc, isFalse, reason: 'ADR-0005 O-4 — local, never converted');
      expect(clock.todayLocal(), hasLength(10));
      expect(clock.todayLocal(), matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });
  });
}

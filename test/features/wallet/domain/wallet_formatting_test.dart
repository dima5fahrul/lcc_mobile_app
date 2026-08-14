/// `wallet_formatting.dart` — the four pure transforms, and the one that is
/// the batch's highest-risk silent divergence.
///
/// specs.md § 7.3 heads this group *"the highest-risk silent divergence in this
/// batch"*, and the reason is not that the arithmetic is hard. It is that the
/// **only** wallet reference image that exists (`04-wallet`, signed out) has a
/// balance of zero, and the one live test account also measures
/// `balance_lak 0`. So no rendered surface available to this programme can ever
/// show a grouped number, and **no fidelity tier can catch a wrong separator**.
/// `B6-AC-16` therefore names six exact pairs and says a suite without the Lao
/// dot cases does not satisfy it. Those six are the first six tests below, by
/// name.
///
/// `B6-AC-19` is discharged structurally rather than by a test body: this file
/// imports `formatLak` transitively through `wallet_formatting.dart`'s
/// `export`, and `wallet_scope_test.dart` greps that `String formatLak` is
/// defined zero times under `lib/features/wallet`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/wallet/domain/wallet_formatting.dart';

void main() {
  // ── B6-AC-16 — the six named pairs ────────────────────────────────────────
  //
  // Written out one per test rather than as a table loop so that a failure
  // names the pair that broke. The Lao rows are the point of the criterion.
  group('B6-AC-16 formatKip — the six pairs the criterion names', () {
    test("(0, 'en') → '0 ₭'", () {
      expect(formatKip(0, 'en'), '0 ₭');
    });

    test("(0, 'lo') → '0 ₭'", () {
      expect(formatKip(0, 'lo'), '0 ₭');
    });

    test("(20000, 'en') → '20,000 ₭' — comma", () {
      expect(formatKip(20000, 'en'), '20,000 ₭');
    });

    test("(20000, 'lo') → '20.000 ₭' — DOT, and this is the divergence", () {
      // `WalletPage.tsx:62-65` passes `lo-LA` through to `toLocaleString`;
      // `formatLak` pins `en-US` in both locales. An implementer who reuses
      // `groupThousands` here ships `20,000 ₭` on the largest number on the
      // screen and every tier stays green.
      expect(formatKip(20000, 'lo'), '20.000 ₭');
    });

    test("(1234567, 'lo') → '1.234.567 ₭'", () {
      expect(formatKip(1234567, 'lo'), '1.234.567 ₭');
    });

    test("(-5000, 'lo') → '-5.000 ₭' — sign outside the grouping", () {
      // `Math.abs` first, `"-"` prefixed to the result, so a negative can never
      // pick up a locale's own minus glyph.
      expect(formatKip(-5000, 'lo'), '-5.000 ₭');
    });
  });

  group('formatKip — the grouping threshold, measured not assumed', () {
    // The doc records that `lo-LA` has no minimum-grouping-digits quirk: the
    // separator character is the ONLY difference from `en-US`. If that were
    // wrong the natural bad fix would be a special case at 4 digits, so both
    // sides of the threshold are pinned.
    test('999 does not group, in either locale', () {
      expect(formatKip(999, 'en'), '999 ₭');
      expect(formatKip(999, 'lo'), '999 ₭');
    });

    test('1000 groups, in either locale', () {
      expect(formatKip(1000, 'en'), '1,000 ₭');
      expect(formatKip(1000, 'lo'), '1.000 ₭');
    });

    test('an unknown language code takes the English branch', () {
      // `lang === "lo" ? "lo-LA" : "en-US"` — the source's ternary has no third
      // arm, so anything that is not `lo` is `en-US`.
      expect(formatKip(20000, 'th'), '20,000 ₭');
      expect(formatKip(20000, ''), '20,000 ₭');
    });

    test('-500 keeps the sign without grouping', () {
      expect(formatKip(-500, 'lo'), '-500 ₭');
      expect(formatKip(-500, 'en'), '-500 ₭');
    });

    test('the two groupers differ ONLY in the separator character', () {
      // The property the doc claims, asserted as a property rather than at
      // four sample points — this is what makes "just replaceAll" a legal
      // refactor and a wrong *implementation* detectable if it ever is not.
      for (final int v in <int>[0, 7, 999, 1000, 20000, 1234567, 50000000]) {
        expect(
          formatKip(v, 'lo'),
          formatKip(v, 'en').replaceAll(',', '.'),
          reason: 'separator-only divergence broke at $v',
        );
      }
    });
  });

  // ── B6-AC-18 — the kip sign by code point ─────────────────────────────────
  group('B6-AC-18 the ₭ is U+20AD, asserted by value', () {
    test('kKipSign is exactly one code unit and it is 0x20AD', () {
      expect(kKipSign.length, 1);
      expect(kKipSign.codeUnitAt(0), 0x20AD);
    });

    test('it is NOT the lookalike U+04A9 (ҩ) and NOT an ASCII K', () {
      expect(kKipSign.codeUnitAt(0), isNot(0x04A9));
      expect(kKipSign.codeUnitAt(0), isNot(0x4B));
    });

    test('formatKip emits that exact code point, not a lookalike', () {
      final String out = formatKip(20000, 'en');
      expect(out.codeUnitAt(out.length - 1), 0x20AD);
    });
  });

  // ── B6-AC-20 — formatDay, and the one character that makes it its own ─────
  group('B6-AC-20 formatDay', () {
    test("null → '—' (U+2014 EM DASH), not the empty string", () {
      // The whole reason this is not a call to `home_formatting.dart`'s
      // `formatDate`, which answers `''` here. A ledger row would print
      // ` · 20,000 ₭` with a leading gap.
      expect(formatDay(null, 'en'), '—');
      expect(formatDay(null, 'en').codeUnitAt(0), 0x2014);
    });

    test("'' → '—' too — `if (!value)` catches both", () {
      expect(formatDay('', 'en'), '—');
      expect(formatDay('', 'lo'), '—');
    });

    test('unparseable input comes back VERBATIM, not as the dash', () {
      // `Number.isNaN(d.getTime()) → return value`. Distinct from the absent
      // branch: a malformed date is diagnosable, a dash is not.
      expect(formatDay('not-a-date', 'en'), 'not-a-date');
      expect(formatDay('not-a-date', 'lo'), 'not-a-date');
    });

    test("'2026-08-06' in Lao → '06 ສ.ຫ. 2026'", () {
      expect(formatDay('2026-08-06', 'lo'), '06 ສ.ຫ. 2026');
    });

    test("'2026-08-06' in English → '06 Aug 2026'", () {
      expect(formatDay('2026-08-06', 'en'), '06 Aug 2026');
    });

    test('the day is zero-padded to two digits', () {
      expect(formatDay('2026-08-06', 'en'), startsWith('06 '));
      expect(formatDay('2026-08-16', 'en'), startsWith('16 '));
    });

    test('September is the four-character `Sept` — the source uses en-GB', () {
      // `WalletPage.tsx:71` passes `en-GB`, not `en-US`, for this one call.
      expect(formatDay('2026-09-01', 'en'), '01 Sept 2026');
    });

    test('a full ISO instant parses, not only a bare date', () {
      expect(formatDay('2026-08-06T13:45:00Z', 'en'), '06 Aug 2026');
    });
  });

  // ── B6-AC-34 — the money parse, including its coercion ────────────────────
  group('B6-AC-34 parseTopUpAmount matches WalletPage.tsx:735', () {
    test("'12a3' → 123 — the case a int.tryParse port gets WRONG", () {
      // `Number("12a3".replace(/[^\d]/g,""))` is 123. `int.tryParse('12a3')` is
      // null. That is a different amount of money from the same keystrokes,
      // silently, which is why the criterion names this pair first.
      expect(parseTopUpAmount('12a3'), 123);
      expect(int.tryParse('12a3'), isNull); // the wrong port, pinned
    });

    test("'' → 0 via `|| 0`", () {
      expect(parseTopUpAmount(''), 0);
    });

    test("'abc' → 0 — NaN is falsy", () {
      expect(parseTopUpAmount('abc'), 0);
    });

    test("'0050000' → 50000 — leading zeros are not octal and not an error", () {
      expect(parseTopUpAmount('0050000'), 50000);
    });

    test("'50,000' → 50000 — the grouping separator is stripped", () {
      expect(parseTopUpAmount('50,000'), 50000);
      expect(parseTopUpAmount('50.000'), 50000); // the Lao separator too
    });

    test("'-500' → 500 — the minus is not a digit; there is no negative top-up",
        () {
      expect(parseTopUpAmount('-500'), 500);
    });

    test('whitespace and a kip sign are stripped like any other non-digit', () {
      expect(parseTopUpAmount(' 20 000 ₭ '), 20000);
    });

    test('a digit string beyond 64-bit yields 0, which FAILS the min guard', () {
      // Unreachable through the bounded field; recorded because 0 is the safe
      // direction — it is rejected by the `value < min` guard rather than
      // wrapping to some other amount.
      expect(parseTopUpAmount('9' * 40), 0);
    });
  });
}

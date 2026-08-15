/// `PaymentResult` — the three resolution rules, and `daysUntil`'s ceil.
///
/// `B6-AC-30` and `B6-AC-21`, both tagged **B6b**.
///
/// ## Why these live in a domain test and not in a widget test
///
/// The rules are the *only* part of the pay path an empty account lets a test
/// reach honestly. `POST /applications/{id}/pay` has never been executed
/// against a host and § 4.4 forbids executing it, so there is no recorded
/// response and no populated Tier 3 verdict; what there is, is a pure function
/// over a parsed body, and that is testable without pretending otherwise.
/// § 6.9(1) states the rules as behaviour precisely so they can be asserted
/// here rather than inferred from a rendered screen.
///
/// The bodies come from the declared-synthetic fixtures, which say in their own
/// `_capture.provenance` that they are not recordings.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/wallet/data/models/wallet_wire.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/payment_result.dart';
import 'package:lcc_mobile_app/features/wallet/domain/wallet_formatting.dart';

Map<String, dynamic> _payload(String fixture) {
  final Map<String, dynamic> doc =
      jsonDecode(File('test/fidelity/fixtures/api/$fixture').readAsStringSync())
          as Map<String, dynamic>;
  return doc['data'] as Map<String, dynamic>;
}

void main() {
  group('B6-AC-30 — the three resolution rules, and the operator difference', () {
    test('rule 1 uses || — a server-sent "" FALLS THROUGH to the nested one', () {
      final PaymentResult r = paymentResultFrom(
        _payload('application-pay-nested.json'),
      );

      // The fixture's flat `receipt_no` is the empty string, which is falsy in
      // JS. A Dart `??` chain would stop there and print a receipt line with no
      // receipt.
      expect(r.receiptNo, '');
      expect(r.transaction?.receiptNo, 'RCPT-900002');
      expect(r.resolvedReceiptNo, 'RCPT-900002');
    });

    test(
      'rule 2 uses ?? — a server-sent 0 WINS over the mounting page\'s prop',
      () {
        final PaymentResult r = paymentResultFrom(
          _payload('application-pay-nested.json'),
        );

        expect(r.amountLak, 0);
        // The prop is 50000; the server said the charge was zero, and it wins.
        // Under `||` this would answer 50000 — a number the server did not send,
        // printed to a citizen, on a money surface.
        expect(r.chargedAmount(50000), 0);
      },
    );

    test('the two operators are genuinely different on the SAME body', () {
      // The point of `B6-AC-30`, stated as one assertion: one field falls
      // through on empty and the other does not fall through on zero. A port
      // that unified them fails exactly one of these two lines.
      final PaymentResult r = paymentResultFrom(
        _payload('application-pay-nested.json'),
      );

      expect(r.resolvedReceiptNo, isNot(''), reason: '|| must fall through');
      expect(r.chargedAmount(50000), 0, reason: '?? must NOT fall through');
    });

    test(
      'rule 1 keeps a non-empty flat receipt and never reaches the nested',
      () {
        const PaymentResult r = PaymentResult(
          receiptNo: 'FLAT-1',
          transaction: PaymentTransaction(receiptNo: 'NESTED-1'),
        );
        expect(r.resolvedReceiptNo, 'FLAT-1');
      },
    );

    test('rule 1 ends at "" when neither side has one', () {
      const PaymentResult r = PaymentResult();
      expect(r.resolvedReceiptNo, '');
    });

    test('rule 2 falls all the way to the prop when both are absent', () {
      const PaymentResult r = PaymentResult();
      expect(r.chargedAmount(50000), 50000);
    });

    test('rule 2 prefers the flat amount over the nested one', () {
      const PaymentResult r = PaymentResult(
        amountLak: 111,
        transaction: PaymentTransaction(amountLak: 222),
      );
      expect(r.chargedAmount(333), 111);
    });

    group('rule 3 — three independent ways to be paid, any one sufficient', () {
      test('arm 1: settled === true', () {
        expect(const PaymentResult(settled: true).isSettled, isTrue);
      });

      test('arm 2: payment_state === "paid"', () {
        expect(const PaymentResult(paymentState: 'paid').isSettled, isTrue);
      });

      test('arm 3: transaction.status === "paid", alone', () {
        // The nested fixture settles by this arm ONLY — its `settled` is absent
        // and its `payment_state` is `processing`. A port that read just the
        // first two arms would render a charge button over a paid case.
        final PaymentResult r = paymentResultFrom(
          _payload('application-pay-nested.json'),
        );
        expect(r.settled, isNull);
        expect(r.paymentState, 'processing');
        expect(r.transaction?.status, 'paid');
        expect(r.isSettled, isTrue);
      });

      test(
        'absent is NOT false by accident — none of the three arms fires',
        () {
          final PaymentResult r = paymentResultFrom(
            _payload('application-pay-instruction.json'),
          );
          expect(r.settled, isNull);
          expect(r.paymentState, 'processing');
          expect(r.transaction, isNull);
          expect(r.isSettled, isFalse);
        },
      );

      test('settled: false does not settle', () {
        expect(const PaymentResult(settled: false).isSettled, isFalse);
      });
    });

    test(
      'the flat documented shape parses whole, including wallet_balance_lak',
      () {
        // The field `PaymentSection.tsx`'s own type omits — porting only the
        // component's half would have dropped it.
        final PaymentResult r = paymentResultFrom(
          _payload('application-pay-settled.json'),
        );
        expect(r.walletBalanceLak, 120000);
        expect(r.resolvedReceiptNo, 'RCPT-900001');
        expect(r.isSettled, isTrue);
      },
    );

    test(
      'the settle-elsewhere arm parses its steps as Bilingual, not String',
      () {
        final PaymentResult r = paymentResultFrom(
          _payload('application-pay-instruction.json'),
        );
        final PaymentInstruction i = r.instruction!;

        expect(i.hasSteps, isTrue);
        expect(i.steps, hasLength(3));
        // `text(step, lang)` renders these (`:434`), so both sides must survive
        // the parse — a `String` port would silently keep only one language.
        expect(i.steps.first.en, 'Open your banking app and choose Transfer.');
        expect(i.steps.first.lo, isNotEmpty);
        expect(i.note?.lo, isNotEmpty);
        expect(i.referenceNo, 'REF-900003');
        expect(i.qrPayload, isNull);
      },
    );

    test('an instruction with only a qr_payload has no steps and no account', () {
      // `B6-DIV-3`'s most exposed form: the panel renders a bitmap and a string
      // and nothing else identifies the payment.
      final PaymentResult r = paymentResultFrom(
        _payload('application-pay-instruction-qr.json'),
      );
      final PaymentInstruction i = r.instruction!;

      expect(i.qrPayload, isNotNull);
      expect(i.qrPayload, isNotEmpty);
      expect(i.account, isNull);
      expect(i.referenceNo, isNull);
      expect(i.hasSteps, isFalse);
    });

    test(
      'hasSteps treats absent and empty identically, as the source does',
      () {
        expect(const PaymentInstruction().hasSteps, isFalse);
        expect(const PaymentInstruction(steps: <Never>[]).hasSteps, isFalse);
      },
    );
  });

  group('PaymentFailure — the code, never the message', () {
    test('it is a Failure, so every existing consumer keeps working', () {
      const PaymentFailure f = PaymentFailure('nope', 'INSUFFICIENT_FUNDS');
      expect(f.message, 'nope');
      expect(f.code, 'INSUFFICIENT_FUNDS');
      // `props` starts with the message, so equality with a plain `Failure`
      // consumer's expectations is unchanged.
      expect(f.props.first, 'nope');
    });

    test('two failures with the same message and different codes differ', () {
      // The whole reason the subclass exists. If these compared equal, the
      // amber-panel branch could not distinguish them and would be keyed to
      // server-authored, localised prose.
      const PaymentFailure a = PaymentFailure('same', 'INSUFFICIENT_FUNDS');
      const PaymentFailure b = PaymentFailure('same', 'INTERNAL_ERROR');
      expect(a, isNot(equals(b)));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-21 — daysUntil ceils, and its clock is injected', () {
    // A fixed instant, so nothing here reads `DateTime.now()`. The AC says so
    // in as many words: a test that computed its expectation from the real
    // clock would be asserting the implementation against itself and would
    // still pass with `ceil` replaced by anything monotonic.
    final DateTime clock = DateTime.utc(2026, 8, 15, 12, 0, 0);

    test('a due instant 30 MINUTES away is 1, not 0', () {
      // `Math.ceil(0.0208…)` — the criterion's own case. A `truncate()` or a
      // `round()` port answers 0 and moves the overdue boundary by up to a day
      // on a surface that tells a citizen a fee is late.
      expect(daysUntil('2026-08-15T12:30:00Z', now: clock), 1);
    });

    test('exactly 24 hours away is 1', () {
      expect(daysUntil('2026-08-16T12:00:00Z', now: clock), 1);
    });

    test('24 hours and one minute away is 2, because ceil', () {
      expect(daysUntil('2026-08-16T12:01:00Z', now: clock), 2);
    });

    test('an absent value yields null', () {
      expect(daysUntil(null, now: clock), isNull);
    });

    test('an empty value yields null', () {
      expect(daysUntil('', now: clock), isNull);
    });

    test('an unparseable value yields null, and does not throw', () {
      expect(daysUntil('not-a-date', now: clock), isNull);
    });

    test('a past date yields a negative', () {
      expect(daysUntil('2026-08-11T12:00:00Z', now: clock), -4);
    });

    test(
      'ceil rounds toward +infinity on negatives too: 30 min PAST due is 0',
      () {
        // Named because it is the reason `WalletPage.tsx:333` ORs the arithmetic
        // with the server's own `is_overdue` flag instead of trusting it. By this
        // number alone, a bill half an hour late is not late.
        expect(daysUntil('2026-08-15T11:30:00Z', now: clock), 0);
      },
    );

    test('the clock really is the parameter — two clocks, two answers', () {
      // The negative control for "injected": if `now` were ignored, these two
      // would agree.
      const String due = '2026-08-20T12:00:00Z';
      expect(daysUntil(due, now: clock), 5);
      expect(daysUntil(due, now: DateTime.utc(2026, 8, 18, 12)), 2);
    });
  });
}

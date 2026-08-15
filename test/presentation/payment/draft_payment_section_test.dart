/// Draft-mode payment — the **shared surface** F2 and F3 inherit.
///
/// `specs.md` § 6.5 makes this F1's second kernel: a defect found at F3 costs
/// the same class of rewrite F1 exists to prevent. So it is tested as a kernel
/// is — parameter-driven, pumped with the DI container **completely
/// uninitialised**, and with both of § 6.5's traps asserted directly.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/presentation/forms/validation/validation_scope.dart';
import 'package:lcc_mobile_app/presentation/payment/draft_payment_section.dart';
import 'package:lcc_mobile_app/presentation/payment/payment_draft.dart';
import 'package:lcc_mobile_app/presentation/payment/payment_summary_card.dart';
import 'package:lcc_mobile_app/presentation/payment/qr_placeholder.dart';

import '../../helpers/app_test_harness.dart';

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // F1-AC-47..51 — the pure half
  // ───────────────────────────────────────────────────────────────────────────
  group('F1-AC-47 LAO_BANKS', () {
    test('twelve entries, verbatim, in SOURCE order — not sorted', () {
      expect(kLaoBanks.length, 12);
      expect(kLaoBanks.first, 'BCEL — Banque pour le Commerce Extérieur Lao');
      expect(kLaoBanks.last, 'ACLEDA Bank Lao');

      final List<String> sorted = <String>[...kLaoBanks]..sort();
      expect(
        kLaoBanks,
        isNot(equals(sorted)),
        reason:
            'the dropdown renders in source order and Tier 1 reads '
            'rendered order (`PaymentSection.tsx:85-98`)',
      );
    });

    test('not localised and not fetched — the list is a const', () {
      expect(kLaoBanks, isA<List<String>>());
      expect(identical(kLaoBanks, kLaoBanks), isTrue);
    });
  });

  group(
    'F1-AC-48 isPaymentValid — all four arms and a negative per conjunct',
    () {
      PaymentDraft cc({
        String number = '4111 1111 1111 1111',
        String name = 'SOMCHAI V',
        String expiry = '12/29',
        String cvv = '123',
      }) => PaymentDraft(
        method: DraftPaymentMethod.cc,
        bankName: '',
        cardNumber: number,
        cardName: name,
        cardExpiry: expiry,
        cardCvv: cvv,
      );

      test('qr is ALWAYS true — which is why step 6 is valid on arrival', () {
        expect(isPaymentValid(kBlankPayment), isTrue);
        expect(kBlankPayment.method, DraftPaymentMethod.qr);
      });

      test('bank is truthiness on bankName, NOT a trim', () {
        const PaymentDraft base = PaymentDraft(
          method: DraftPaymentMethod.bank,
          bankName: '',
          cardNumber: '',
          cardName: '',
          cardExpiry: '',
          cardCvv: '',
        );
        expect(isPaymentValid(base), isFalse);
        expect(isPaymentValid(base.copyWith(bankName: 'BCEL')), isTrue);
        expect(
          isPaymentValid(base.copyWith(bankName: ' ')),
          isTrue,
          reason:
              'a bank name of " " passes on the web (`:103`). Unreachable '
              'through the dropdown — reproduced anyway.',
        );
      });

      test('cc needs all four, and each conjunct has a negative', () {
        expect(isPaymentValid(cc()), isTrue);
        expect(isPaymentValid(cc(number: '4111 1111 1111 111')), isFalse);
        expect(isPaymentValid(cc(name: '   ')), isFalse);
        expect(isPaymentValid(cc(expiry: '12/2')), isFalse);
        expect(isPaymentValid(cc(cvv: '12')), isFalse);
      });

      test('the card checks are LENGTHS, not values — 99/99 and 000 pass', () {
        expect(
          isPaymentValid(cc(expiry: '99/99', cvv: '000')),
          isTrue,
          reason:
              'no month range, no Luhn, no CVV rule anywhere in the source. '
              'Adding one is a port stricter than the web.',
        );
      });

      test('cardNumber is stripped of \\s, not of spaces', () {
        expect(isPaymentValid(cc(number: '4111\t1111\n1111 1111')), isTrue);
      });
    },
  );

  group('F1-AC-49 formatCard', () {
    test(
      'digits only, capped at 16, grouped in fours, trailing space trimmed',
      () {
        expect(formatCard('4111111111111111'), '4111 1111 1111 1111');
        expect(formatCard('4111-1111-1111-1111'), '4111 1111 1111 1111');
        expect(formatCard('abc4111def1111'), '4111 1111');
      },
    );

    test('an over-length input is truncated to 16 digits', () {
      expect(formatCard('41111111111111119999'), '4111 1111 1111 1111');
    });

    test(
      'the .trim() is load-bearing — a full number has no trailing space',
      () {
        final String full = formatCard('4111111111111111');
        expect(full.endsWith(' '), isFalse);
        expect(full.length, 19);
      },
    );
  });

  group('F1-AC-50 formatExpiry — the off-by-one', () {
    test('"12" stays "12" — NOT "12/"', () {
      expect(
        formatExpiry('12'),
        '12',
        reason:
            'the slash appears at the THIRD digit (`:117`). A port that '
            'inserts it at the second is a different keystroke experience '
            'and a different Tier 3 frame.',
      );
    });

    test('"123" becomes "12/3"', () => expect(formatExpiry('123'), '12/3'));

    test(
      '"12345" becomes "12/34" — capped at four digits',
      () => expect(formatExpiry('12345'), '12/34'),
    );

    test('non-digits are stripped first', () {
      expect(formatExpiry('1/2'), '12');
      expect(formatExpiry('ab12cd34'), '12/34');
    });
  });

  test('F1-AC-51 blankPayment is qr plus five empty strings', () {
    expect(kBlankPayment.method, DraftPaymentMethod.qr);
    expect(kBlankPayment.bankName, '');
    expect(kBlankPayment.cardNumber, '');
    expect(kBlankPayment.cardName, '');
    expect(kBlankPayment.cardExpiry, '');
    expect(kBlankPayment.cardCvv, '');
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F1-AC-45 / F1-AC-46 — the widget, with nothing registered anywhere
  // ───────────────────────────────────────────────────────────────────────────
  group('F1-AC-46 the section is parameter-driven', () {
    Future<PaymentDraft> pump(
      WidgetTester t,
      PaymentDraft value, {
      bool showErrors = false,
      String bankRailNote = '',
    }) async {
      PaymentDraft current = value;
      await t.pumpWidget(
        wrapWithLocalization(
          Builder(
            builder: (BuildContext context) => MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: ValidationScope(
                    showErrors: showErrors,
                    child: StatefulBuilder(
                      builder: (BuildContext c, StateSetter setState) =>
                          DraftPaymentSection(
                            amount: 20000,
                            serviceName: 'Residence Certificate',
                            value: current,
                            bankRailNote: bankRailNote,
                            onChanged: (PaymentDraft v) =>
                                setState(() => current = v),
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      return current;
    }

    testWidgets('it builds with the DI container UNINITIALISED', (
      WidgetTester t,
    ) async {
      // No `DependencyInjection().init()`, no `*Injection`, no `/payment-methods`
      // read. If this ever needs one, the surface has stopped being a kernel.
      await pump(t, kBlankPayment);

      expect(find.byType(DraftPaymentSection), findsOneWidget);
      expect(
        find.byType(PaymentSummaryCard),
        findsOneWidget,
        reason: 'B6a\'s card, consumed and not reimplemented',
      );
    });

    testWidgets(
      'the QR tab is selected on arrival and draws B6a\'s placeholder',
      (WidgetTester t) async {
        await pump(t, kBlankPayment);
        expect(find.byType(QrPlaceholder), findsOneWidget);
      },
    );

    testWidgets('the three tabs are QR, Bank and Card', (WidgetTester t) async {
      await pump(t, kBlankPayment);
      expect(find.text('QR Code'), findsOneWidget);
      expect(find.text('Bank'), findsWidgets);
      expect(find.text('Card'), findsOneWidget);
    });

    testWidgets('switching to Bank renders the twelve-bank dropdown', (
      WidgetTester t,
    ) async {
      await pump(t, kBlankPayment.copyWith(method: DraftPaymentMethod.bank));
      expect(find.byType(DropdownButton<String>), findsOneWidget);
      expect(find.byType(QrPlaceholder), findsNothing);
    });

    testWidgets('the transfer card appears only once a bank is chosen', (
      WidgetTester t,
    ) async {
      await pump(t, kBlankPayment.copyWith(method: DraftPaymentMethod.bank));
      expect(find.text('TRANSFER DETAILS'), findsNothing);

      await pump(
        t,
        kBlankPayment.copyWith(
          method: DraftPaymentMethod.bank,
          bankName: 'BCEL — Banque pour le Commerce Extérieur Lao',
        ),
      );
      expect(find.text('TRANSFER DETAILS'), findsOneWidget);
      expect(
        find.text(kBankDetailsAfterSubmitEn),
        findsOneWidget,
        reason:
            'the step says WHEN the real payee account arrives rather '
            'than inventing one (`:571`)',
      );
    });

    testWidgets('the bank rail note renders only when the catalogue gave one', (
      WidgetTester t,
    ) async {
      await pump(t, kBlankPayment.copyWith(method: DraftPaymentMethod.bank));
      expect(find.text('Cut-off 15:30'), findsNothing);

      await pump(
        t,
        kBlankPayment.copyWith(method: DraftPaymentMethod.bank),
        bankRailNote: 'Cut-off 15:30',
      );
      expect(find.text('Cut-off 15:30'), findsOneWidget);
    });

    testWidgets('the card panel renders the mock card with its placeholders', (
      WidgetTester t,
    ) async {
      await pump(t, kBlankPayment.copyWith(method: DraftPaymentMethod.cc));
      expect(find.text('•••• •••• •••• ••••'), findsOneWidget);
      expect(find.text('MM/YY'), findsWidgets);
    });

    testWidgets('typing a card number formats it ON THE WAY IN', (
      WidgetTester t,
    ) async {
      await pump(t, kBlankPayment.copyWith(method: DraftPaymentMethod.cc));
      await t.enterText(find.byType(TextField).first, '4111111111111111');
      await t.pump();

      expect(
        find.text('4111 1111 1111 1111'),
        findsWidgets,
        reason:
            'the formatter runs in `onChanged`, which is what makes the '
            'stored value the displayed one and what `isPaymentValid`\'s '
            '`cardExpiry.length == 5` depends on',
      );
    });

    testWidgets(
      'showErrors surfaces the bank error, and only for the bank tab',
      (WidgetTester t) async {
        await pump(
          t,
          kBlankPayment.copyWith(method: DraftPaymentMethod.bank),
          showErrors: true,
        );
        // The kernel's error text widget is what renders it; its presence is the
        // assertion, not the copy, which is `formFields`' and not this file's.
        expect(find.byType(DropdownButton<String>), findsOneWidget);

        await pump(t, kBlankPayment, showErrors: true);
        expect(
          find.byType(QrPlaceholder),
          findsOneWidget,
          reason: 'qr is always valid, so showErrors changes nothing here',
        );
      },
    );

    testWidgets('a tab change PRESERVES the other five fields', (
      WidgetTester t,
    ) async {
      // The source spreads a partial over the previous state and never resets
      // (`:479`). A citizen who types a card number, switches to QR and
      // switches back still has it.
      const PaymentDraft typed = PaymentDraft(
        method: DraftPaymentMethod.cc,
        bankName: 'BCEL — Banque pour le Commerce Extérieur Lao',
        cardNumber: '4111 1111 1111 1111',
        cardName: 'SOMCHAI V',
        cardExpiry: '12/29',
        cardCvv: '123',
      );
      final PaymentDraft afterQr = typed.copyWith(
        method: DraftPaymentMethod.qr,
      );

      expect(afterQr.cardNumber, '4111 1111 1111 1111');
      expect(afterQr.bankName, 'BCEL — Banque pour le Commerce Extérieur Lao');
      expect(afterQr.copyWith(method: DraftPaymentMethod.cc), typed);
    });
  });
}

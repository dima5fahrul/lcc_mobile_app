/// `LivePaymentSection` — the four CTA states, the default selection, the
/// insufficient-funds split, and the boundary the widget may not cross.
///
/// `B6-AC-31`, `B6-AC-32`, `B6-AC-53`, `B6-AC-10` and `B6-AC-9`, all **B6b**.
///
/// ## What these tests are evidence FOR, and what they are not
///
/// They are evidence that the widget branches the way `PaymentSection.tsx`
/// branches, given a state. They are **not** evidence that any of it has ever
/// rendered over a real charge: `POST /applications/{id}/pay` has never been
/// executed against a host, § 4.4 forbids executing it, and the only available
/// test citizen has `applications total 0` — nothing to pay for. Every
/// `PaymentResult` below comes from a fixture whose own `_capture.provenance`
/// declares it synthetic. The Tier 3 verdict for every surface here is
/// NOT EVALUATED, with that reason, in `qa-report.md`.
///
/// ## The negative half is the criterion
///
/// Each of the four CTA states asserts the state it renders **and the two it
/// suppresses**. A test that only looked for the green receipt line would pass
/// with the charge button rendered beside it, which is the defect § 6.9(4)
/// describes.
library;

import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/wallet/data/models/wallet_wire.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/payment_method.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/payment_result.dart';
import 'package:lcc_mobile_app/presentation/payment/insufficient_funds_panel.dart';
import 'package:lcc_mobile_app/presentation/payment/live_payment_section.dart';
import 'package:lcc_mobile_app/presentation/payment/payment_instruction_panel.dart';
import 'package:lcc_mobile_app/presentation/payment/payment_method_tile.dart';
import 'package:lcc_mobile_app/presentation/payment/payment_summary_card.dart';
import 'package:lcc_mobile_app/presentation/payment/qr_placeholder.dart';

import '../../features/wallet/wallet_fixtures.dart';
import '../../helpers/app_test_harness.dart';

PaymentResult _result(String fixture) {
  final Map<String, dynamic> doc =
      jsonDecode(File('test/fidelity/fixtures/api/$fixture').readAsStringSync())
          as Map<String, dynamic>;
  return paymentResultFrom(doc['data'] as Map<String, dynamic>);
}

void main() {
  /// Records what the widget handed back, so the charge callback is observable
  /// without a BLoC — which is the whole shape `B6-AC-10` requires.
  late List<String> charged;
  late int topUpTaps;

  setUp(() {
    charged = <String>[];
    topUpTaps = 0;
  });

  Future<void> pump(
    WidgetTester tester, {
    List<PaymentMethod>? methods,
    bool methodsLoading = false,
    String? methodsError,
    bool pending = false,
    String? genericError,
    bool insufficient = false,
    PaymentResult? result,
    bool withTopUp = false,
    int amount = 50000,
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      wrapWithLocalization(
        startLocale: locale,
        Builder(
          builder: (BuildContext context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  width: 390,
                  child: LivePaymentSection(
                    amount: amount,
                    serviceName: 'Resident Certificate',
                    reference: 'LCC-2026-900001',
                    methods: methods ?? tMethodCatalogue(),
                    methodsLoading: methodsLoading,
                    methodsError: methodsError,
                    onRetryMethods: () {},
                    pending: pending,
                    genericError: genericError,
                    insufficient: insufficient,
                    result: result,
                    onCharge: (String code) async => charged.add(code),
                    onTopUp: withTopUp ? () => topUpTaps++ : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder chargeButton() =>
      find.widgetWithIcon(ElevatedButton, Icons.lock_outline);
  Finder settledLine() => find.byIcon(Icons.check_circle_outline);

  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-53 — live mode INCLUDES wallet; the top-up sheet excludes it', () {
    testWidgets('the 8-row catalogue renders its 7 enabled rows, wallet among '
        'them', (WidgetTester tester) async {
      await pump(tester);

      // `m.enabled` alone — `PaymentSection.tsx:211`. The fixture carries eight
      // rows, one of them `enabled: false`.
      expect(find.byType(PaymentMethodTile), findsNWidgets(7));

      final Iterable<PaymentMethodTile> tiles = tester
          .widgetList<PaymentMethodTile>(find.byType(PaymentMethodTile));
      expect(
        tiles.map((PaymentMethodTile t) => t.method.code),
        contains('wallet'),
        reason:
            'live mode keeps the wallet rail; only the TOP-UP sheet drops '
            'it (`WalletPage.tsx:728`), and that asymmetry is the criterion',
      );
      expect(
        tiles.map((PaymentMethodTile t) => t.method.code),
        isNot(contains('retired')),
        reason: 'the disabled row must not render',
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-31 — the default selection is data, never a literal', () {
    testWidgets('the FIRST enabled row is active before any tap', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      final List<PaymentMethodTile> tiles = tester
          .widgetList<PaymentMethodTile>(find.byType(PaymentMethodTile))
          .toList();

      expect(tiles.first.active, isTrue);
      expect(tiles.skip(1).every((PaymentMethodTile t) => !t.active), isTrue);
    });

    testWidgets('REORDER the catalogue and the default follows it — proving it '
        'is not a hardcoded code', (WidgetTester tester) async {
      // The negative control `B6-AC-31` needs. A widget that defaulted to
      // `'wallet'` or `'laoqr'` would pass the previous test against the real
      // fixture, whose first row happens to be `wallet`, and fail this one.
      await pump(
        tester,
        methods: <PaymentMethod>[
          tMethod(code: 'apb'),
          tMethod(code: 'wallet', kind: PaymentMethodKind.wallet),
          tMethod(code: 'laoqr', kind: PaymentMethodKind.qr),
        ],
      );

      final List<PaymentMethodTile> tiles = tester
          .widgetList<PaymentMethodTile>(find.byType(PaymentMethodTile))
          .toList();

      expect(tiles.first.method.code, 'apb');
      expect(tiles.first.active, isTrue);
      expect(tiles[1].active, isFalse, reason: 'wallet must NOT win by name');
    });

    testWidgets('a tap moves the selection and the charge sends THAT code', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      // `ensureVisible` before each tap: seven rails plus a summary card is
      // taller than the 600 px test viewport, and a tap on an off-screen
      // widget silently hits nothing — which would make this test pass with
      // `onCharge` never wired at all.
      await tester.ensureVisible(find.byType(PaymentMethodTile).at(4));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PaymentMethodTile).at(4));
      await tester.pumpAndSettle();

      await tester.ensureVisible(chargeButton());
      await tester.pumpAndSettle();
      await tester.tap(chargeButton());
      await tester.pumpAndSettle();

      // The fifth enabled row of `tMethodCatalogue()` is `laoqr`.
      expect(charged, <String>['laoqr']);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-32 — INSUFFICIENT_FUNDS gets the amber panel, and it suppresses '
      'the generic line', () {
    testWidgets('the panel renders and the generic red line does NOT', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        insufficient: true,
        // The mount is responsible for the split — `WalletState.payGenericError`
        // is null while `payInsufficient` is true. Passing a message here as
        // well would test a state the BLoC cannot produce.
        genericError: null,
      );

      expect(find.byType(InsufficientFundsPanel), findsOneWidget);
      expect(
        find.text('Your wallet does not have enough money'),
        findsOneWidget,
      );
    });

    testWidgets(
      'the generic line renders when the failure is NOT insufficient',
      (WidgetTester tester) async {
        // The other half. Without this, "the panel suppresses the line" would be
        // satisfied by a widget that never renders the line at all.
        await pump(tester, genericError: 'The gateway did not answer.');

        expect(find.byType(InsufficientFundsPanel), findsNothing);
        expect(find.text('The gateway did not answer.'), findsOneWidget);
      },
    );

    testWidgets('the Top-up button appears when the mount supplied onTopUp', (
      WidgetTester tester,
    ) async {
      await pump(tester, insufficient: true, withTopUp: true);

      final Finder topUp = find.widgetWithText(ElevatedButton, 'Top up');
      expect(topUp, findsOneWidget);

      await tester.ensureVisible(topUp);
      await tester.pumpAndSettle();
      await tester.tap(topUp);
      await tester.pumpAndSettle();
      expect(topUpTaps, 1);
    });

    testWidgets('and is ABSENT when it did not — the HistoryDetailPage mount', (
      WidgetTester tester,
    ) async {
      // `HistoryDetailPage.tsx:427-436` passes no `onTopUp`, so a citizen who
      // cannot afford the fee is told so and offered nothing. Both branches are
      // the source's and `B6-AC-32` requires a test for each.
      await pump(tester, insufficient: true);

      expect(find.byType(InsufficientFundsPanel), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Top up'), findsNothing);
    });

    testWidgets('the fee in the panel is formatLak, not formatKip', (
      WidgetTester tester,
    ) async {
      // § 6.5 / `B6-AC-22`. All six `formatLak` sites are inside
      // `PaymentSection`; the nine `formatKip` sites are inside `WalletPage`.
      // The currency token is what tells them apart.
      await pump(tester, insufficient: true, amount: 20000);

      expect(
        find.textContaining('20,000 LAK'),
        findsWidgets,
        reason: 'formatLak renders "LAK"; formatKip would render "₭"',
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group(
    '§ 6.9(4) — the CTA disappears in two different ways, and they differ',
    () {
      testWidgets('settled → a green receipt line, and NO charge button', (
        WidgetTester tester,
      ) async {
        await pump(tester, result: _result('application-pay-settled.json'));

        expect(settledLine(), findsOneWidget);
        expect(find.textContaining('RCPT-900001'), findsOneWidget);
        expect(chargeButton(), findsNothing);
      });

      testWidgets('instruction but not settled → the grey sentence, no button, '
          'no green line', (WidgetTester tester) async {
        await pump(tester, result: _result('application-pay-instruction.json'));

        expect(
          find.text('We will confirm as soon as the bank replies.'),
          findsOneWidget,
        );
        expect(chargeButton(), findsNothing);
        expect(settledLine(), findsNothing);
        expect(find.byType(PaymentInstructionPanel), findsOneWidget);
      });

      testWidgets('settled WINS over instruction when a body carries both', (
        WidgetTester tester,
      ) async {
        // `settled ? … : instruction ? … : button` — the order is the source's
        // and a body can satisfy both predicates.
        await pump(
          tester,
          result: const PaymentResult(
            receiptNo: 'RCPT-BOTH',
            paymentState: 'paid',
            instruction: PaymentInstruction(account: '000-00-00-00000'),
          ),
        );

        expect(settledLine(), findsOneWidget);
        expect(
          find.text('We will confirm as soon as the bank replies.'),
          findsNothing,
        );
        // The panel still renders — it is not part of the three-way tail.
        expect(find.byType(PaymentInstructionPanel), findsOneWidget);
      });

      testWidgets('neither → the lock-icon charge button', (
        WidgetTester tester,
      ) async {
        await pump(tester);

        expect(chargeButton(), findsOneWidget);
        expect(settledLine(), findsNothing);
      });

      testWidgets(
        'an empty catalogue renders NO button and no error — just the '
        'sentence',
        (WidgetTester tester) async {
          // `:305-313` and `:452`. The request succeeded; the answer was empty.
          await pump(tester, methods: <PaymentMethod>[]);

          expect(chargeButton(), findsNothing);
          expect(find.byType(PaymentMethodTile), findsNothing);
          expect(
            find.text('No payment method is available right now.'),
            findsOneWidget,
          );
        },
      );

      testWidgets('a catalogue of only DISABLED rows is the same empty state', (
        WidgetTester tester,
      ) async {
        // `enabled.length === 0` is computed after the filter, not before it.
        await pump(
          tester,
          methods: <PaymentMethod>[
            tMethod(code: 'retired', enabled: false),
            tMethod(code: 'gone', enabled: false),
          ],
        );

        expect(find.byType(PaymentMethodTile), findsNothing);
        expect(
          find.text('No payment method is available right now.'),
          findsOneWidget,
        );
      });

      testWidgets('pending disables the button and swaps its label', (
        WidgetTester tester,
      ) async {
        await pump(tester, pending: true);

        expect(find.text('Processing…'), findsOneWidget);
        final ElevatedButton button = tester.widget<ElevatedButton>(
          chargeButton(),
        );
        expect(button.onPressed, isNull);

        // And the charge cannot be re-fired by tapping it.
        await tester.tap(chargeButton(), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(charged, isEmpty);
      });

      testWidgets('the CTA names the amount and the chosen rail', (
        WidgetTester tester,
      ) async {
        await pump(tester, amount: 20000);

        // `Pay ${formatLak(amount, lang)}${chosen ? ` · ${label}` : ""}` —
        // `:466-468`. `formatLak`, so "LAK" and not "₭".
        expect(find.textContaining('Pay 20,000 LAK · '), findsOneWidget);
      });
    },
  );

  // ───────────────────────────────────────────────────────────────────────────
  group('the catalogue\'s own loading and error states', () {
    testWidgets('loading renders neither tiles nor a button', (
      WidgetTester tester,
    ) async {
      await pump(tester, methodsLoading: true, methods: <PaymentMethod>[]);

      expect(find.byType(PaymentMethodTile), findsNothing);
      expect(chargeButton(), findsNothing);
      // …and NOT the empty-catalogue sentence, which is a different state.
      expect(
        find.text('No payment method is available right now.'),
        findsNothing,
      );
    });

    testWidgets('an error renders the server message and a retry', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        methods: <PaymentMethod>[],
        methodsError: 'The catalogue is unavailable.',
      );

      expect(find.text('The catalogue is unavailable.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Try again'), findsOneWidget);
      expect(
        find.text('No payment method is available right now.'),
        findsNothing,
        reason: 'an error is not an empty catalogue',
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('B6-DIV-3 / § 6.9(5) — the QR appears for a QR rail with NO payload', () {
    testWidgets('a payload renders the bitmap AND the payload text', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        result: _result('application-pay-instruction-qr.json'),
        methods: <PaymentMethod>[
          tMethod(code: 'laoqr', kind: PaymentMethodKind.qr),
        ],
      );

      expect(find.byType(QrPlaceholder), findsOneWidget);
      // The only payable datum on the screen, printed beneath a bitmap that
      // does not encode it. Ported as measured; § 7.9 item 4 records what that
      // means for a citizen.
      expect(find.textContaining('00020101021238'), findsOneWidget);
    });

    testWidgets('NO payload, but a qr-kind rail selected → bitmap and nothing '
        'beneath it', (WidgetTester tester) async {
      // `instruction.qr_payload || chosen?.kind === "qr"` — `:391`. The `||` is
      // the divergence. § 6.10 forbids hiding it, adding an encoder, or
      // captioning it with a warning.
      await pump(
        tester,
        methods: <PaymentMethod>[
          tMethod(code: 'laoqr', kind: PaymentMethodKind.qr),
        ],
        result: const PaymentResult(
          paymentState: 'processing',
          instruction: PaymentInstruction(account: '000-00-00-00000'),
        ),
      );

      expect(find.byType(QrPlaceholder), findsOneWidget);
      expect(find.byType(PaymentInstructionPanel), findsOneWidget);
    });

    testWidgets('a NON-qr rail with no payload renders no bitmap at all', (
      WidgetTester tester,
    ) async {
      // The negative control: without it, "the QR shows for a qr rail" would be
      // satisfied by a panel that always shows one.
      await pump(
        tester,
        methods: <PaymentMethod>[
          tMethod(code: 'bcel', kind: PaymentMethodKind.bank),
        ],
        result: const PaymentResult(
          paymentState: 'processing',
          instruction: PaymentInstruction(account: '000-00-00-00000'),
        ),
      );

      expect(find.byType(PaymentInstructionPanel), findsOneWidget);
      expect(find.byType(QrPlaceholder), findsNothing);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('the instruction panel\'s three-deep reference fallback (`:416`)', () {
    testWidgets('instruction.reference_no wins', (WidgetTester tester) async {
      await pump(tester, result: _result('application-pay-instruction.json'));
      expect(find.text('REF-900003'), findsOneWidget);
    });

    testWidgets('an EMPTY reference_no falls through to the receipt — JS ||, '
        'not Dart ??', (WidgetTester tester) async {
      await pump(
        tester,
        result: const PaymentResult(
          receiptNo: 'RCPT-FALLBACK',
          paymentState: 'processing',
          instruction: PaymentInstruction(referenceNo: ''),
        ),
      );

      expect(find.text('RCPT-FALLBACK'), findsOneWidget);
    });

    testWidgets('all three empty falls to the mount\'s reference prop', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        result: const PaymentResult(
          paymentState: 'processing',
          instruction: PaymentInstruction(account: '000-00-00-00000'),
        ),
      );

      expect(find.text('LCC-2026-900001'), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('B6-DIV-2 — the method note is English in the Lao run', () {
    testWidgets('the rail note is NOT translated, while an instruction note IS', (
      WidgetTester tester,
    ) async {
      // Two notes, two lines apart in the source, one `Bilingual` and one not
      // (`PaymentSection.tsx:337` vs `:434`). The API has no Lao for the first;
      // translating it client-side would invent copy. FU-7 files it where the
      // fix belongs.
      await pump(
        tester,
        locale: const Locale('lo'),
        methods: <PaymentMethod>[
          tMethod(code: 'bcel').copyWith(note: 'Settles same day'),
        ],
        result: _result('application-pay-instruction.json'),
      );

      expect(find.text('Settles same day'), findsOneWidget);
      // The instruction note, in Lao.
      expect(
        find.text('ການໂອນຫຼັງ 16:00 ຈະຖືກຢືນຢັນໃນວັນເຮັດວຽກຖັດໄປ.'),
        findsOneWidget,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('the shared summary card is mounted by live mode too', () {
    testWidgets('B6a\'s PaymentSummaryCard renders above the rails', (
      WidgetTester tester,
    ) async {
      // `PaymentSection.tsx:246-271` is outside the `{live && …}` guard, so it
      // renders in both modes. It is B6a's file and B6b consumes it unchanged.
      await pump(tester);
      expect(find.byType(PaymentSummaryCard), findsOneWidget);
    });
  });
}

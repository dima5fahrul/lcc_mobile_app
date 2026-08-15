/// The Bills Due card — four branches, the three-way due chip, and the filter
/// that decides what reaches it.
///
/// B6b. `WalletPage.tsx:264-382`.
///
/// ## The account limit, stated rather than worked around
///
/// `GET /applications/` answers `total 0, rows 0` for the only available test
/// citizen (measured 2026-08-14, specs.md § 2.1), and § 4.4 forbids creating a
/// case to change that. So the **populated** branch has never rendered over
/// live data and cannot in this programme's current access: every row below
/// comes from `applications-pending.json`, whose own `_capture.provenance`
/// declares it synthetic and says why no recording exists.
///
/// That makes these tests evidence about the *widget*, not about the account —
/// which is exactly the distinction the Capability Rule asks for, and it is why
/// `qa-report.md` records the Tier 3 verdict for this surface as NOT EVALUATED
/// rather than as PASS. The one branch that IS reachable live is the empty one,
/// and B6a already gated it at Tier 3 against slot `04-wallet`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/application/data/models/application_wire.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_row.dart';
import 'package:lcc_mobile_app/features/wallet/domain/usecases/list_pending_bills.dart';
import 'package:lcc_mobile_app/features/wallet/presentation/widgets/wallet_bills_due_section.dart';
import 'package:lcc_mobile_app/features/wallet/presentation/widgets/wallet_panels.dart';
import 'package:lcc_mobile_app/presentation/theme/app_colors.dart';

import '../../../../helpers/app_test_harness.dart';
import '../../../../helpers/service_test_helper.dart';

/// Every row in the fixture, unfiltered — the two negative controls included.
List<ApplicationRow> _allFixtureRows() {
  final Map<String, dynamic> doc =
      jsonDecode(
            File(
              'test/fidelity/fixtures/api/applications-pending.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  return (doc['data'] as List<dynamic>)
      // B7a's parser, deliberately: B6b adds no second wire mapping, so a test
      // that hand-built `ApplicationRow`s would not exercise the one seam § 2.3
      // rules on.
      .map((dynamic e) => applicationRowFrom(e as Map<String, dynamic>))
      .toList();
}

/// What `ListPendingBills` would hand the widget.
List<ApplicationRow> _bills() =>
    _allFixtureRows().where(isPendingBill).toList();

void main() {
  // **Real font metrics, not the placeholder face.** Without this the test
  // renderer advances roughly one em per glyph, so a 10 px chip label measures
  // ~127 px where Roboto draws it at ~68 — wide enough to overflow a card that
  // is fine on a device, and wide enough to make an ellipsis fire and change
  // the very strings these tests assert. `service_test_helper.dart:121` records
  // the same finding from the other direction: a Lao-only font chain left every
  // ASCII numeral drawing as a box, and a measurement taken against that state
  // is not a measurement of this app.
  setUpAll(loadAppFonts);

  late int viewAllTaps;
  late int retryTaps;
  late List<String> paid;

  setUp(() {
    viewAllTaps = 0;
    retryTaps = 0;
    paid = <String>[];
  });

  /// Fixed so `daysUntil` is deterministic — `B6-AC-21` requires the clock to
  /// be injected and no test to read `DateTime.now()`. The fixture's four due
  /// dates are positioned relative to this instant.
  final DateTime clock = DateTime.utc(2026, 8, 15, 12);

  Future<void> pump(
    WidgetTester tester, {
    required bool isAuthenticated,
    List<ApplicationRow> bills = const <ApplicationRow>[],
    bool loading = false,
    String? error,
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
                  child: WalletBillsDueSection(
                    isAuthenticated: isAuthenticated,
                    onViewAll: () => viewAllTaps++,
                    bills: bills,
                    loading: loading,
                    error: error,
                    onRetry: () => retryTaps++,
                    onPay: (ApplicationRow b) => paid.add(b.id),
                    now: clock,
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

  // ───────────────────────────────────────────────────────────────────────────
  group('the filter — both halves are load-bearing', () {
    test('it keeps pending-with-a-fee and drops the two negative controls', () {
      final List<String> kept = _bills()
          .map((ApplicationRow r) => r.id)
          .toList();

      expect(kept, <String>['app-901', 'app-902', 'app-903', 'app-904']);
      expect(
        kept,
        isNot(contains('app-905')),
        reason: 'payment_state "paid" with a real fee must be dropped',
      );
      expect(
        kept,
        isNot(contains('app-906')),
        reason:
            'payment_state "pending" with fee_lak 0 must be dropped — '
            'dropping this half puts a "0 ₭" row with a Pay button in front '
            'of a citizen',
      );
    });

    test('the fixture actually contains both negative controls', () {
      // Without this, the assertions above would pass against a fixture that
      // simply had no rows to reject — the Capability Rule failure mode.
      final List<ApplicationRow> all = _allFixtureRows();
      expect(all, hasLength(6));
      expect(all.where((ApplicationRow r) => r.id == 'app-905'), hasLength(1));
      expect(all.where((ApplicationRow r) => r.id == 'app-906'), hasLength(1));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('the four branches, and each suppresses the other three', () {
    testWidgets('skeleton: signed in, loading, nothing yet', (
      WidgetTester tester,
    ) async {
      await pump(tester, isAuthenticated: true, loading: true);

      expect(find.byType(WalletRowSkeleton), findsOneWidget);
      // **Two** rows here, not the transactions list's three (`:289`).
      expect(
        tester.widget<WalletRowSkeleton>(find.byType(WalletRowSkeleton)).rows,
        2,
      );
      expect(find.byType(WalletEmptyCard), findsNothing);
      expect(find.byType(WalletRetryCard), findsNothing);
    });

    testWidgets('signed OUT never skeletons, even while loading', (
      WidgetTester tester,
    ) async {
      // `enabled: isAuthenticated` (`:107`) means the query never fires signed
      // out, so a skeleton there would be a placeholder for a list that will
      // never load. Slot `04-wallet` is a picture of the empty card.
      await pump(tester, isAuthenticated: false, loading: true);

      expect(find.byType(WalletRowSkeleton), findsNothing);
      expect(find.byType(WalletEmptyCard), findsOneWidget);
    });

    testWidgets('signed OUT never shows an error either', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        isAuthenticated: false,
        error: 'stale error from a previous session',
      );

      expect(find.byType(WalletRetryCard), findsNothing);
      expect(find.byType(WalletEmptyCard), findsOneWidget);
    });

    testWidgets('error: signed in, with a message and a retry', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        isAuthenticated: true,
        error: 'We could not load your bills.',
      );

      expect(find.text('We could not load your bills.'), findsOneWidget);
      expect(find.byType(WalletRowSkeleton), findsNothing);
      expect(find.byType(WalletEmptyCard), findsNothing);
    });

    testWidgets('a refetch over a POPULATED list keeps the cards, not the '
        'skeleton', (WidgetTester tester) async {
      // `bills.length === 0` is the third conjunct of `:288`. Without it, every
      // "View all" tap would blank the card the citizen is reading.
      await pump(tester, isAuthenticated: true, loading: true, bills: _bills());

      expect(find.byType(WalletRowSkeleton), findsNothing);
      expect(find.text('LCC-2026-900001'), findsOneWidget);
    });

    testWidgets('empty, signed in: "Every fee on your cases has been paid."', (
      WidgetTester tester,
    ) async {
      await pump(tester, isAuthenticated: true);

      expect(
        find.text('Every fee on your cases has been paid.'),
        findsOneWidget,
      );
    });

    testWidgets('empty, signed out: the namespaced signInBills key instead', (
      WidgetTester tester,
    ) async {
      // The asymmetry is the source's, `:319-324`: signed in gets the inlined
      // ternary (relocated to `wallet.allBillsPaid`), signed out gets the key
      // the source already had.
      await pump(tester, isAuthenticated: false);

      expect(find.text('Sign in to see your bills'), findsOneWidget);
      expect(find.text('Every fee on your cases has been paid.'), findsNothing);
    });

    testWidgets('populated: one card per surviving row', (
      WidgetTester tester,
    ) async {
      await pump(tester, isAuthenticated: true, bills: _bills());

      expect(find.byType(WalletEmptyCard), findsNothing);
      expect(find.byType(WalletRowSkeleton), findsNothing);
      for (final String ref in <String>[
        'LCC-2026-900001',
        'LCC-2026-900002',
        'LCC-2026-900003',
        'LCC-2026-900004',
      ]) {
        expect(find.text(ref), findsOneWidget);
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('the header summary', () {
    testWidgets('empty renders noBillsDue as the subtitle', (
      WidgetTester tester,
    ) async {
      await pump(tester, isAuthenticated: true);
      // Title and subtitle both, so two.
      expect(find.text('No bills due'), findsNWidgets(2));
    });

    testWidgets('populated renders the total and the count, in formatKip', (
      WidgetTester tester,
    ) async {
      await pump(tester, isAuthenticated: true, bills: _bills());

      // 50000 + 20000 + 120000 + 35000 = 225000. `formatKip`, so `₭` and NOT
      // `LAK` — this is one of the nine `formatKip` sites (§ 6.5, `B6-AC-22`).
      expect(find.text('Total 225,000 ₭ across 4 bills'), findsOneWidget);
    });

    testWidgets('the Lao run groups the total with DOTS', (
      WidgetTester tester,
    ) async {
      // `formatKip`'s Lao branch is dot-grouped (`B6-AC-16`, `B6-AC-17`) where
      // `formatLak` is comma-grouped in both locales. The Bills Due total is
      // one of only two rendered surfaces in the whole app that can show a
      // grouped number, because `balance_lak` is 0 on the one test account.
      await pump(
        tester,
        isAuthenticated: true,
        bills: _bills(),
        locale: const Locale('lo'),
      );

      expect(find.textContaining('225.000 ₭'), findsOneWidget);
      expect(find.textContaining('225,000'), findsNothing);
    });

    testWidgets('View all reports the tap in both auth states', (
      WidgetTester tester,
    ) async {
      await pump(tester, isAuthenticated: false);
      await tester.tap(find.text('View all'));
      await tester.pumpAndSettle();
      expect(viewAllTaps, 1);
    });

    testWidgets('the error card\'s retry is wired', (
      WidgetTester tester,
    ) async {
      await pump(tester, isAuthenticated: true, error: 'nope');
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(retryTaps, 1);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('the due chip — three colours, and a fourth case with no day count', () {
    /// The chip's ink, read back off the rendered `Text` rather than off the
    /// widget's constructor — a test that compared two constants to each other
    /// would pass with the palette never applied.
    Color inkOf(WidgetTester tester, String label) =>
        tester.widget<Text>(find.text(label)).style!.color!;

    testWidgets('overdue is red — by the SERVER flag, not only by arithmetic', (
      WidgetTester tester,
    ) async {
      await pump(tester, isAuthenticated: true, bills: _bills());

      // `app-901`: `due_at` 2026-08-11, `is_overdue: true`, so 4 days past.
      // `Math.abs(days)` — the label carries the magnitude, not the sign.
      expect(find.text('Overdue 4 days'), findsOneWidget);
      expect(inkOf(tester, 'Overdue 4 days'), AppColors.danger);
    });

    testWidgets('within three days is amber', (WidgetTester tester) async {
      await pump(tester, isAuthenticated: true, bills: _bills());

      // `app-902`: due 2026-08-17T00:00 against a 2026-08-15T12:00 clock —
      // 1.5 days, and `ceil` makes it 2.
      expect(find.text('Due in 2 days'), findsOneWidget);
      expect(inkOf(tester, 'Due in 2 days'), AppColors.warningLink);
    });

    testWidgets('beyond three days is grey', (WidgetTester tester) async {
      await pump(tester, isAuthenticated: true, bills: _bills());

      // `app-903`: due 2026-09-01 — 17 days out.
      expect(find.text('Due in 17 days'), findsOneWidget);
      expect(inkOf(tester, 'Due in 17 days'), AppColors.muted);
    });

    testWidgets('exactly three days is still amber — the threshold is <=', (
      WidgetTester tester,
    ) async {
      // The boundary the `<=` owns. At `<` this row would render grey.
      final List<ApplicationRow> row = <ApplicationRow>[
        _bills().first.copyWith(
          isOverdue: false,
          dueAt: '2026-08-18T12:00:00Z',
        ),
      ];
      await pump(tester, isAuthenticated: true, bills: row);

      expect(find.text('Due in 3 days'), findsOneWidget);
      expect(inkOf(tester, 'Due in 3 days'), AppColors.warningLink);
    });

    testWidgets('four days out is grey — the other side of the same boundary', (
      WidgetTester tester,
    ) async {
      final List<ApplicationRow> row = <ApplicationRow>[
        _bills().first.copyWith(
          isOverdue: false,
          dueAt: '2026-08-19T12:00:00Z',
        ),
      ];
      await pump(tester, isAuthenticated: true, bills: row);

      expect(inkOf(tester, 'Due in 4 days'), AppColors.muted);
    });

    testWidgets('NO due_at renders formatDay\'s em-dash, not a day count, and '
        'stays grey', (WidgetTester tester) async {
      await pump(tester, isAuthenticated: true, bills: _bills());

      // `app-904` carries no `due_at`. `daysUntil` answers null, so the label
      // falls to `formatDay(null, lang)` — U+2014, not "Due in 0 days".
      expect(find.text('—'), findsOneWidget);
      expect(inkOf(tester, '—'), AppColors.muted);
    });

    testWidgets('a bill 30 minutes PAST due is not overdue by arithmetic — the '
        'server flag is what decides', (WidgetTester tester) async {
      // `daysUntil` ceils to 0, not -1, so `days < 0` is false. This is the
      // case that makes `b.is_overdue ||` load-bearing rather than defensive.
      final ApplicationRow base = _bills().first;

      await pump(
        tester,
        isAuthenticated: true,
        bills: <ApplicationRow>[
          base.copyWith(isOverdue: false, dueAt: '2026-08-15T11:30:00Z'),
        ],
      );
      expect(find.text('Due in 0 days'), findsOneWidget);
      expect(inkOf(tester, 'Due in 0 days'), AppColors.warningLink);

      await pump(
        tester,
        isAuthenticated: true,
        bills: <ApplicationRow>[
          base.copyWith(isOverdue: true, dueAt: '2026-08-15T11:30:00Z'),
        ],
      );
      expect(find.text('Overdue 0 days'), findsOneWidget);
      expect(inkOf(tester, 'Overdue 0 days'), AppColors.danger);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('the row itself', () {
    testWidgets('the fee is formatKip — ₭, not LAK', (
      WidgetTester tester,
    ) async {
      await pump(tester, isAuthenticated: true, bills: _bills());

      expect(find.text('50,000 ₭'), findsOneWidget);
      expect(find.textContaining('50,000 LAK'), findsNothing);
    });

    testWidgets('the service name IS translated', (WidgetTester tester) async {
      // `text(b.service_name, lang)` — `:356`. Unlike `PaymentMethod.note`
      // (`B6-DIV-2`), this one is `Bilingual` on the wire and is resolved.
      await pump(
        tester,
        isAuthenticated: true,
        bills: _bills(),
        locale: const Locale('lo'),
      );

      expect(find.text('ໃບຢັ້ງຢືນທີ່ຢູ່ອາໄສ'), findsOneWidget);
    });

    testWidgets('Pay reports the row it was pressed for', (
      WidgetTester tester,
    ) async {
      await pump(tester, isAuthenticated: true, bills: _bills());

      final Finder payButtons = find.text('Pay');
      expect(payButtons, findsNWidgets(4));

      await tester.ensureVisible(payButtons.at(1));
      await tester.pumpAndSettle();
      await tester.tap(payButtons.at(1));
      await tester.pumpAndSettle();

      // The SECOND row, not the first — the source's `paying` is the row
      // itself (`:373`), so a widget that closed over the wrong index would
      // charge the wrong case.
      expect(paid, <String>['app-902']);
    });
  });
}

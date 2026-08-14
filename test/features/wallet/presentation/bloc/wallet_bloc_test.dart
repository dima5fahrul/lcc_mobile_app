/// `WalletBloc` — four queries, four enablement conditions, one write.
///
/// ## The counters are the point of this file
///
/// `B6-AC-23` says the four `enabled` conditions must be proven *"by a BLoC test
/// that asserts, per condition, **which endpoints were and were not hit**"*, and
/// `B6-AC-25` says a page load must issue **zero** `/payment-methods` requests.
/// Both are negative claims, and a `verifyNever` on a mock that was never wired
/// would satisfy them vacuously. So every group here asserts the positive and
/// the negative from the same counters in the same act: something was called,
/// and something else was not.
///
/// ## § 4.4
///
/// `TopUpWallet` is mocked. No transport exists in this file at all, so
/// `POST /me/wallet/topup` cannot reach a host even by accident.
library;

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/usecase/usecase.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/paged.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/payment_method.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/transaction.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/wallet_entry.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/wallet_overview.dart';
import 'package:lcc_mobile_app/features/wallet/domain/usecases/wallet_usecases.dart';
import 'package:lcc_mobile_app/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../wallet_fixtures.dart';

class _MockGetWalletOverview extends Mock implements GetWalletOverview {}

class _MockGetWalletEntries extends Mock implements GetWalletEntries {}

class _MockGetTransactions extends Mock implements GetTransactions {}

class _MockGetPaymentMethods extends Mock implements GetPaymentMethods {}

class _MockTopUpWallet extends Mock implements TopUpWallet {}

void main() {
  late _MockGetWalletOverview getOverview;
  late _MockGetWalletEntries getEntries;
  late _MockGetTransactions getTransactions;
  late _MockGetPaymentMethods getMethods;
  late _MockTopUpWallet topUp;

  setUpAll(() {
    registerFallbackValue(NoParams());
    registerFallbackValue(const WalletPageParams(page: 1));
    registerFallbackValue(const TopUpParams(amountLak: 1, methodCode: 'x'));
  });

  setUp(() {
    getOverview = _MockGetWalletOverview();
    getEntries = _MockGetWalletEntries();
    getTransactions = _MockGetTransactions();
    getMethods = _MockGetPaymentMethods();
    topUp = _MockTopUpWallet();

    when(() => getOverview(any())).thenAnswer(
      (_) async => Right<Failure, WalletOverview>(tOverview()),
    );
    when(() => getEntries(any())).thenAnswer(
      (_) async => Right<Failure, PagedRows<WalletEntry>>(
        tPage<WalletEntry>(<WalletEntry>[tEntry()]),
      ),
    );
    when(() => getTransactions(any())).thenAnswer(
      (_) async => Right<Failure, PagedRows<Transaction>>(
        tPage<Transaction>(<Transaction>[tTransaction()]),
      ),
    );
    when(() => getMethods(any())).thenAnswer(
      (_) async => Right<Failure, List<PaymentMethod>>(tMethodCatalogue()),
    );
    when(() => topUp(any())).thenAnswer(
      (_) async => Right<Failure, Wallet>(tWallet(balanceLak: 70000)),
    );
  });

  WalletBloc build() => WalletBloc(
        getWalletOverview: getOverview,
        getWalletEntries: getEntries,
        getTransactions: getTransactions,
        getPaymentMethods: getMethods,
        topUpWallet: topUp,
      );

  /// Asserts the whole call surface at once — every AC in § 7.4 is a claim
  /// about which of these five moved and which did not.
  void expectCalls({
    required int overview,
    required int entries,
    required int transactions,
    required int methods,
    int topUps = 0,
  }) {
    // `verifyNever` for zero rather than `.called(0)`: mocktail treats the
    // latter as "consume 0 recorded calls", which passes whatever happened.
    // The negative half of every § 7.4 criterion lives in this branch, so
    // getting it wrong would make the criteria vacuous — the exact failure mode
    // the Capability Rule names.
    void check(int want, dynamic Function() call) {
      if (want == 0) {
        verifyNever(call);
      } else {
        verify(call).called(want);
      }
    }

    check(overview, () => getOverview(any()));
    check(entries, () => getEntries(any()));
    check(transactions, () => getTransactions(any()));
    check(methods, () => getMethods(any()));
    check(topUps, () => topUp(any()));
  }

  // ───────────────────────────────────────────────────────────────────────────
  // B6-AC-25 / B6-AC-23 — the mount, and the four enablement conditions
  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-25 a page mount issues ZERO requests', () {
    blocTest<WalletBloc, WalletState>(
      'WalletStarted fetches nothing at all — not even the overview',
      build: build,
      act: (WalletBloc b) => b.add(const WalletStarted()),
      expect: () => <WalletState>[],
      verify: (_) {
        // All four page queries are `enabled: isAuthenticated`
        // (`WalletPage.tsx:101,105,113,119`) and the flag has not arrived. The
        // *positive* half of this claim is the group below: the same counters
        // move the moment auth flips.
        expectCalls(overview: 0, entries: 0, transactions: 0, methods: 0);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'and specifically ZERO /payment-methods — that is the sheet\'s query',
      build: build,
      act: (WalletBloc b) => b
        ..add(const WalletStarted())
        ..add(const WalletAuthChanged(isAuthenticated: true)),
      wait: const Duration(milliseconds: 10),
      verify: (_) {
        // Even a fully authenticated page load must not fetch the catalogue:
        // `useQuery(payments.methods, [])` is inside the sheet component
        // (`:726`), which is unmounted until the sheet opens.
        verifyNever(() => getMethods(any()));
      },
    );
  });

  group('B6-AC-23 the four enabled conditions', () {
    blocTest<WalletBloc, WalletState>(
      'authenticated: overview + receipts fire; ledger and methods do NOT',
      build: build,
      act: (WalletBloc b) =>
          b.add(const WalletAuthChanged(isAuthenticated: true)),
      wait: const Duration(milliseconds: 10),
      verify: (_) {
        // The ledger is `isAuthenticated && showLedger`, and showLedger is
        // false until the toggle. The asymmetry IS the criterion.
        expectCalls(overview: 1, entries: 0, transactions: 1, methods: 0);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'authenticated + ledger open: the ledger fires too',
      build: build,
      act: (WalletBloc b) async {
        b.add(const WalletAuthChanged(isAuthenticated: true));
        await Future<void>.delayed(const Duration(milliseconds: 5));
        b.add(const WalletLedgerToggled());
      },
      wait: const Duration(milliseconds: 20),
      verify: (_) {
        expectCalls(overview: 1, entries: 1, transactions: 1, methods: 0);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'the sheet opening is the ONLY thing that fetches /payment-methods',
      build: build,
      act: (WalletBloc b) => b.add(const WalletTopUpSheetOpened()),
      wait: const Duration(milliseconds: 10),
      verify: (_) {
        // Note it fires with isAuthenticated FALSE — the catalogue is the one
        // anonymous read, and the signed-out wallet depends on it.
        expectCalls(overview: 0, entries: 0, transactions: 0, methods: 1);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'signing OUT fetches nothing and clears the money fields',
      build: build,
      seed: () => WalletState(
        isAuthenticated: true,
        overview: tOverview(balanceLak: 20000),
        receipts: <Transaction>[tTransaction()],
        showLedger: true,
        ledgerPage: 3,
      ),
      act: (WalletBloc b) =>
          b.add(const WalletAuthChanged(isAuthenticated: false)),
      wait: const Duration(milliseconds: 10),
      verify: (WalletBloc b) {
        expectCalls(overview: 0, entries: 0, transactions: 0, methods: 0);
        // Deliberately STRICTER than `useQuery`, which keeps the last rows in
        // memory (`hooks.ts:58-61` returns early without touching `data`).
        // Holding a balance and an account number for the next citizen on the
        // device is not a behaviour worth being faithful about.
        expect(b.state.overview, isNull);
        expect(b.state.receipts, isEmpty);
        expect(b.state.ledger, isNull);
        expect(b.state.showLedger, isFalse);
        expect(b.state.ledgerPage, 1);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'a repeated auth value is a no-op, not a refetch',
      build: build,
      seed: () => const WalletState(isAuthenticated: true),
      act: (WalletBloc b) =>
          b.add(const WalletAuthChanged(isAuthenticated: true)),
      wait: const Duration(milliseconds: 10),
      verify: (_) =>
          expectCalls(overview: 0, entries: 0, transactions: 0, methods: 0),
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B6-AC-27 / B6-DIV-5 — the deliberately stale first frame
  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-27 the ledger renders stale rows and suppresses the skeleton',
      () {
    test('ledgerEntries falls back to overview.recentEntries — `:130`', () {
      final WalletState s = WalletState(
        overview: tOverview(recentEntries: <WalletEntry>[tEntry()]),
      );

      expect(s.ledger, isNull);
      expect(s.ledgerEntries, hasLength(1));
    });

    test('the skeleton is SUPPRESSED while the stale list has something', () {
      // `ledgerQuery.loading && entries.length === 0` — `:418`. Loading is
      // true and the skeleton is still false, which is the whole divergence.
      final WalletState s = WalletState(
        overview: tOverview(recentEntries: <WalletEntry>[tEntry()]),
        ledgerLoading: true,
      );

      expect(s.ledgerSkeleton, isFalse);
    });

    test('and appears when the stale list is empty', () {
      const WalletState s = WalletState(ledgerLoading: true);
      expect(s.ledgerSkeleton, isTrue);
    });

    test('a loaded page WINS over the stale rows', () {
      final WalletState s = WalletState(
        overview: tOverview(recentEntries: <WalletEntry>[tEntry(id: 'stale')]),
        ledger: tPage<WalletEntry>(<WalletEntry>[tEntry(id: 'fresh')]),
      );

      expect(s.ledgerEntries.single.id, 'fresh');
    });

    test('an EMPTY loaded page also wins — `??` not `isEmpty`', () {
      // The distinction `PagedRows?` exists to carry: a genuinely empty ledger
      // must not fall back to showing the overview's rows again.
      final WalletState s = WalletState(
        overview: tOverview(recentEntries: <WalletEntry>[tEntry()]),
        ledger: tPage<WalletEntry>(const <WalletEntry>[]),
      );

      expect(s.ledgerEntries, isEmpty);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B6-AC-28 — the toggle
  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-28 the ledger toggle resets paging in BOTH directions', () {
    blocTest<WalletBloc, WalletState>(
      'opening from page 1 loads page 1',
      build: build,
      seed: () => const WalletState(isAuthenticated: true),
      act: (WalletBloc b) => b.add(const WalletLedgerToggled()),
      wait: const Duration(milliseconds: 10),
      verify: (WalletBloc b) {
        expect(b.state.showLedger, isTrue);
        expect(b.state.ledgerPage, 1);
        verify(() => getEntries(const WalletPageParams(page: 1))).called(1);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'CLOSING from page 3 also resets to 1 — the direction that gets missed',
      build: build,
      seed: () => WalletState(
        isAuthenticated: true,
        showLedger: true,
        ledgerPage: 3,
        ledger: tPage<WalletEntry>(<WalletEntry>[tEntry()], page: 3),
      ),
      act: (WalletBloc b) => b.add(const WalletLedgerToggled()),
      wait: const Duration(milliseconds: 10),
      verify: (WalletBloc b) {
        expect(b.state.showLedger, isFalse);
        expect(b.state.ledgerPage, 1);
        // Closing drops the rows: the query's `enabled` goes false.
        expect(b.state.ledger, isNull);
        // And it fetches nothing on the way out.
        verifyNever(() => getEntries(any()));
      },
    );

    blocTest<WalletBloc, WalletState>(
      'the pager fetches the requested page',
      build: build,
      seed: () => const WalletState(
        isAuthenticated: true,
        showLedger: true,
        ledgerPage: 1,
      ),
      act: (WalletBloc b) => b.add(const WalletLedgerPageChanged(2)),
      wait: const Duration(milliseconds: 10),
      verify: (_) =>
          verify(() => getEntries(const WalletPageParams(page: 2))).called(1),
    );

    blocTest<WalletBloc, WalletState>(
      'asking for the page already shown is a no-op',
      build: build,
      seed: () => const WalletState(
        isAuthenticated: true,
        showLedger: true,
        ledgerPage: 2,
      ),
      act: (WalletBloc b) => b.add(const WalletLedgerPageChanged(2)),
      wait: const Duration(milliseconds: 10),
      verify: (_) => verifyNever(() => getEntries(any())),
    );

    blocTest<WalletBloc, WalletState>(
      'the pager does nothing while the ledger is closed',
      build: build,
      seed: () => const WalletState(isAuthenticated: true),
      act: (WalletBloc b) => b.add(const WalletLedgerPageChanged(2)),
      wait: const Duration(milliseconds: 10),
      verify: (_) => verifyNever(() => getEntries(any())),
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  // The generation guard — `hooks.ts:55-83`, ported and load-bearing
  // ───────────────────────────────────────────────────────────────────────────
  group('the generation guard — a newer request wins', () {
    test('two overlapping ledger fetches: the SLOWER one does not overwrite',
        () async {
      // `bloc` 9.2.1's default event transformer is CONCURRENT, so two taps on
      // the pager start two fetches. Without `const mine = ++generation.current`
      // the slower one lands last and the citizen sees page 1 while the pager
      // reads 2. Four B2 BLoCs shipped without this; B9 ported it.
      final List<Completer<Either<Failure, PagedRows<WalletEntry>>>> pending =
          <Completer<Either<Failure, PagedRows<WalletEntry>>>>[];

      when(() => getEntries(any())).thenAnswer((_) {
        final Completer<Either<Failure, PagedRows<WalletEntry>>> c =
            Completer<Either<Failure, PagedRows<WalletEntry>>>();
        pending.add(c);
        return c.future;
      });

      final WalletBloc bloc = build();
      bloc.emit(const WalletState(
        isAuthenticated: true,
        showLedger: true,
        ledgerPage: 1,
      ));

      bloc.add(const WalletLedgerPageChanged(2));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      bloc.add(const WalletLedgerPageChanged(3));
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(pending, hasLength(2), reason: 'both fetches should be in flight');

      // The NEWER request (page 3) answers first…
      pending[1].complete(
        Right<Failure, PagedRows<WalletEntry>>(
          tPage<WalletEntry>(<WalletEntry>[tEntry(id: 'page-3')], page: 3),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));

      // …then the stale one arrives late.
      pending[0].complete(
        Right<Failure, PagedRows<WalletEntry>>(
          tPage<WalletEntry>(<WalletEntry>[tEntry(id: 'page-2')], page: 2),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(bloc.state.ledger?.rows.single.id, 'page-3');
      expect(bloc.state.ledgerLoading, isFalse);
      await bloc.close();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B6-AC-29 (state half) — the balance placeholder
  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-29 balanceIsPlaceholder — `walletQuery.loading && !overview`',
      () {
    test('loading with NO overview is a placeholder', () {
      const WalletState s = WalletState(overviewLoading: true);
      expect(s.balanceIsPlaceholder, isTrue);
    });

    test('a REFETCH with an overview in hand is NOT', () {
      // § 6.8(7): the old balance stays on screen through a refetch. Showing
      // the ellipsis here would flicker the number on every `refreshMoney`.
      final WalletState s = WalletState(
        overviewLoading: true,
        overview: tOverview(balanceLak: 20000),
      );

      expect(s.balanceIsPlaceholder, isFalse);
      expect(s.balanceLak, 20000);
    });

    test('balanceLak is 0 when there is no overview — `?? 0`, `:122`', () {
      expect(const WalletState().balanceLak, 0);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B6-AC-53 — two filters over one catalogue
  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-53 topUpOptions excludes `wallet`', () {
    test('the 8-row catalogue yields 6 top-up options', () {
      // `m.enabled && m.code !== "wallet"` — `:728`. The wallet cannot top
      // itself up. Live `PaymentSection` uses `m.enabled` alone (`:211`) and
      // keeps it; that half is B6b's and is asserted there.
      final WalletState s = WalletState(methods: tMethodCatalogue());

      expect(s.methods, hasLength(8));
      expect(s.topUpOptions, hasLength(6));
      expect(
        s.topUpOptions.map((PaymentMethod m) => m.code),
        isNot(contains('wallet')),
      );
    });

    test('the disabled row is excluded by the OTHER half of the filter', () {
      final WalletState s = WalletState(methods: tMethodCatalogue());
      expect(
        s.topUpOptions.map((PaymentMethod m) => m.code),
        isNot(contains('retired')),
      );
    });

    test('an enabled non-wallet row survives', () {
      final WalletState s = WalletState(methods: tMethodCatalogue());
      expect(s.topUpOptions.map((PaymentMethod m) => m.code), contains('bcel'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // The write, and refreshMoney
  // ───────────────────────────────────────────────────────────────────────────
  group('the top-up write', () {
    blocTest<WalletBloc, WalletState>(
      'a success re-reads /me/wallet and /me/transactions, NOT the ledger',
      build: build,
      seed: () => const WalletState(isAuthenticated: true),
      act: (WalletBloc b) => b.add(
        const WalletTopUpSubmitted(amountLak: 50000, methodCode: 'bcel'),
      ),
      wait: const Duration(milliseconds: 20),
      verify: (WalletBloc b) {
        // `refreshMoney` refetches the ledger ONLY when the ledger is open
        // (`:136`). Closed here, so entries must stay at zero.
        expectCalls(overview: 1, entries: 0, transactions: 1, methods: 0,
            topUps: 1);
        expect(b.state.topUpSucceeded, isTrue);
        expect(b.state.topUpPending, isFalse);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'with the ledger OPEN it refetches that too',
      build: build,
      seed: () => const WalletState(isAuthenticated: true, showLedger: true),
      act: (WalletBloc b) => b.add(
        const WalletTopUpSubmitted(amountLak: 50000, methodCode: 'bcel'),
      ),
      wait: const Duration(milliseconds: 20),
      verify: (_) => expectCalls(
          overview: 1, entries: 1, transactions: 1, methods: 0, topUps: 1),
    );

    blocTest<WalletBloc, WalletState>(
      'a FAILURE refreshes nothing and surfaces the message',
      build: build,
      setUp: () => when(() => topUp(any())).thenAnswer(
        (_) async => const Left<Failure, Wallet>(Failure('Insufficient funds')),
      ),
      seed: () => const WalletState(isAuthenticated: true),
      act: (WalletBloc b) => b.add(
        const WalletTopUpSubmitted(amountLak: 50000, methodCode: 'bcel'),
      ),
      wait: const Duration(milliseconds: 20),
      verify: (WalletBloc b) {
        expectCalls(overview: 0, entries: 0, transactions: 0, methods: 0,
            topUps: 1);
        expect(b.state.topUpError, 'Insufficient funds');
        expect(b.state.topUpSucceeded, isFalse);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'a second submit while one is in flight is DROPPED — `!topUp.pending`',
      build: build,
      seed: () => const WalletState(isAuthenticated: true, topUpPending: true),
      act: (WalletBloc b) => b.add(
        const WalletTopUpSubmitted(amountLak: 50000, methodCode: 'bcel'),
      ),
      wait: const Duration(milliseconds: 10),
      verify: (_) {
        // The double-charge guard, at the BLoC. The widget disables the button
        // too; this is the layer that holds when the widget does not.
        verifyNever(() => topUp(any()));
      },
    );

    blocTest<WalletBloc, WalletState>(
      'the exact amount and code reach the use case, unmodified',
      build: build,
      seed: () => const WalletState(isAuthenticated: true),
      act: (WalletBloc b) => b.add(
        const WalletTopUpSubmitted(amountLak: 123, methodCode: 'ldb'),
      ),
      wait: const Duration(milliseconds: 20),
      verify: (_) => verify(
        () => topUp(const TopUpParams(amountLak: 123, methodCode: 'ldb')),
      ).called(1),
    );

    blocTest<WalletBloc, WalletState>(
      'closing the sheet clears the last attempt\'s error',
      build: build,
      seed: () => const WalletState(topUpError: 'boom'),
      act: (WalletBloc b) => b.add(const WalletTopUpSheetClosed()),
      verify: (WalletBloc b) => expect(b.state.topUpError, isNull),
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Errors and retries, per region
  // ───────────────────────────────────────────────────────────────────────────
  group('per-region errors and retries', () {
    blocTest<WalletBloc, WalletState>(
      'a failed overview leaves the PREVIOUS overview standing',
      build: build,
      setUp: () => when(() => getOverview(any())).thenAnswer(
        (_) async => const Left<Failure, WalletOverview>(Failure('offline')),
      ),
      seed: () => WalletState(
        isAuthenticated: true,
        overview: tOverview(balanceLak: 20000),
      ),
      act: (WalletBloc b) => b.add(const WalletOverviewRetried()),
      wait: const Duration(milliseconds: 10),
      verify: (WalletBloc b) {
        // `setData` on success only — a failed refetch must not blank the card.
        expect(b.state.overview?.wallet.balanceLak, 20000);
        expect(b.state.overviewError, 'offline');
      },
    );

    blocTest<WalletBloc, WalletState>(
      'each region\'s retry touches only its own endpoint',
      build: build,
      seed: () => const WalletState(isAuthenticated: true),
      act: (WalletBloc b) => b.add(const WalletReceiptsRetried()),
      wait: const Duration(milliseconds: 10),
      verify: (_) =>
          expectCalls(overview: 0, entries: 0, transactions: 1, methods: 0),
    );

    blocTest<WalletBloc, WalletState>(
      'a signed-out retry fetches nothing',
      build: build,
      act: (WalletBloc b) => b.add(const WalletOverviewRetried()),
      wait: const Duration(milliseconds: 10),
      verify: (_) =>
          expectCalls(overview: 0, entries: 0, transactions: 0, methods: 0),
    );

    blocTest<WalletBloc, WalletState>(
      'the methods retry works signed out — it is the anonymous read',
      build: build,
      act: (WalletBloc b) => b.add(const WalletPaymentMethodsRetried()),
      wait: const Duration(milliseconds: 10),
      verify: (_) =>
          expectCalls(overview: 0, entries: 0, transactions: 0, methods: 1),
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B6-AC-45 — the named empty bill list
  // ───────────────────────────────────────────────────────────────────────────
  test('B6-AC-45 kBillsDueB6b is a NAMED empty constant, not an inline []', () {
    // An inline `[]` at the widget would be indistinguishable from "the citizen
    // has no bills" — which is the state it happens to produce today and is not
    // what it means. `GET /applications/` is B7a's endpoint and B6b's consumer.
    expect(kBillsDueB6b, isEmpty);
  });
}

/// `WalletBloc` — the wallet page's whole read surface, and its one write.
///
/// One screen-level BLoC (SSD § 7.2), holding the four `useQuery` calls of
/// `WalletPage.tsx:101-120` plus the top-up sheet's catalogue query (`:726`)
/// and its mutation (`:733`).
///
/// ## Events and state live in this file, not in `part` siblings
///
/// `notifications_bloc.dart` and `news_bloc.dart` split into
/// `*_event.dart` / `*_state.dart` parts. This one does not, and the reason is
/// scope rather than taste: specs.md § 3.1's B6a table admits
/// `presentation/bloc/wallet_bloc.dart (+ .freezed.dart)` and no sibling, and
/// an unlisted file is an automatic FAIL of the batch. Nothing else about the
/// pattern changes.
///
/// ## Four queries, four different enablement conditions (§ 6.8(1))
///
/// | Query | Endpoint | `enabled` | Source |
/// |---|---|---|---|
/// | overview | `/me/wallet` | `isAuthenticated` | `:101` |
/// | **bills** | `/applications/?page=1&per_page=50` | `isAuthenticated` | `:104-108` |
/// | receipts | `/me/transactions?page=1&per_page=10` | `isAuthenticated` | `:110-114` |
/// | ledger | `/me/wallet/entries?page=N&per_page=10` | `isAuthenticated && showLedger` | `:116-120` |
/// | methods | `/payment-methods` | **a sheet mounted** — not a page query | `:726`, `PaymentSection.tsx:205` |
///
/// Not one composite fetch. `B6-AC-23` asserts, per condition, which endpoints
/// were and were not hit, and `B6-AC-25` asserts a page load issues **zero**
/// `/payment-methods` requests.
///
/// **The bills row is B6b's**, and it is the one query that does not belong to
/// `features/wallet`: it is `ListApplications` over B7a's
/// `features/application/domain`, reached by a DI closure over
/// `applicationInjection` (`ListPendingBills`, § 2.3). B6a rendered the empty
/// branch from a named constant and left a `TODO(B6b)`; that constant is gone
/// and this is what replaced it.
///
/// ## Two sheets, one `/payment-methods` region (B6b)
///
/// The top-up sheet (`:726`) and the live pay sheet (`PaymentSection.tsx:205`)
/// are two component instances with two independent `useQuery`s on the web; in
/// one screen-level BLoC they share [WalletState.methods],
/// [WalletState.methodsLoading] and [WalletState.methodsError]. That is
/// observationally identical here because **the two can never be open at
/// once** — the pay sheet's own top-up affordance closes itself first
/// (`WalletPage.tsx:544-547`) — and both mount-time fetches are unconditional
/// refetches, so neither ever reads the other's leftovers. Recorded rather than
/// assumed, because a third mount point (B7's case-detail panel, which mounts
/// the same widget) would sit on a different page and a different BLoC.
///
/// The **filters** over that one region stay two (`B6-AC-53`):
/// [WalletState.topUpOptions] drops `wallet` (`:728`, the wallet cannot top
/// itself up) and the live pay sheet keeps it (`PaymentSection.tsx:211`) — 6
/// rows and 7 from the same recorded catalogue.
///
/// ## Nothing here refreshes on a timer, on resume, or on focus (`B6-DIV-4`)
///
/// `WalletPage.tsx:132-137`'s `refreshMoney` is called from exactly two places:
/// after a successful top-up (`:559-562`) and after a successful pay (B6b,
/// `:544`). `hooks.ts`'s `useQuery` installs no interval, no focus listener and
/// no window revalidation. So the wallet is stale between actions and **the
/// port is stale with it**. There is deliberately no `dart:async` import in
/// this file: `B6-AC-26` greps `lib/features/wallet` and
/// `lib/presentation/payment` for `Timer|periodic|WidgetsBindingObserver|
/// RefreshIndicator` and requires zero. Adding a pull-to-refresh would make the
/// app *better* than its source, which is a divergence no fidelity tier can
/// see — the same class of change B9 refused for the bell.
///
/// ## The generation guard is a port, not an embellishment
///
/// `hooks.ts:55-83` stamps every in-flight request with
/// `const mine = ++generation.current` and drops the response when
/// `mine !== generation.current` — *"a newer request won"*. Reproduced here as
/// five counters, one per query, and load-bearing rather than decorative:
/// `bloc` 9.2.1's default event transformer is **concurrent**, so two taps on
/// the ledger pager start two fetches and without the stamp the slower one
/// overwrites the fresher one on arrival. Four B2 BLoCs `emit(… await …)` with
/// no such re-check; B9 ported it; this one does too.
///
/// ## What this BLoC does NOT hold
///
/// The **balance eye toggle**. `WalletPage.tsx:95` is a plain `useState`, and
/// SSD § 7.2's *"`setState` is permitted only for ephemeral local UI"* is
/// exactly this case: nothing fetches on it, nothing else reads it, and putting
/// it here would make hiding a balance a state transition every `bloc_test` in
/// this feature has to spell. `wallet_page.dart` owns it (§ 6.8(6)).
library;

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../application/domain/entities/application_row.dart';
import '../../domain/entities/paged.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/payment_result.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/wallet_entry.dart';
import '../../domain/entities/wallet_overview.dart';
import '../../domain/usecases/list_pending_bills.dart';
import '../../domain/usecases/pay_application.dart';
import '../../domain/usecases/wallet_usecases.dart';

part 'wallet_bloc.freezed.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Events
// ─────────────────────────────────────────────────────────────────────────────

sealed class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The mount event, dispatched by the `/wallet` route builder (`B6-AC-12`).
///
/// **It fetches nothing, and that is the port.** All four page queries are
/// `enabled: isAuthenticated` (`WalletPage.tsx:101,105,113,119`), and this BLoC
/// does not read `SessionBloc` — the flag arrives as [WalletAuthChanged] from
/// the page's listener, exactly as `isAuthenticated` arrives at the React
/// component as a prop. So there is nothing to fetch until the session
/// resolves. The same asymmetry `NotificationsBloc` documents: `/` and
/// `/service` dispatch a mount fetch because they have public reads; the bell,
/// the chat and the wallet do not because they have none.
///
/// It is kept rather than dropped because the *provider* must be created at
/// mount either way, and a builder that creates a BLoC and dispatches nothing
/// reads as an oversight. `B6-AC-25` asserts a mount issues zero requests.
final class WalletStarted extends WalletEvent {
  const WalletStarted();
}

/// `isAuthenticated` changed, from the page's `BlocListener<SessionBloc>`.
final class WalletAuthChanged extends WalletEvent {
  const WalletAuthChanged({required this.isAuthenticated});

  final bool isAuthenticated;

  @override
  List<Object?> get props => <Object?>[isAuthenticated];
}

/// The balance card's "Try again" pill — `WalletPage.tsx:194`.
final class WalletOverviewRetried extends WalletEvent {
  const WalletOverviewRetried();
}

/// The receipts card's retry — `:441`.
final class WalletReceiptsRetried extends WalletEvent {
  const WalletReceiptsRetried();
}

/// The Bills Due section's control — B6b, `WalletPage.tsx:279`.
///
/// **One event, two affordances, because the source has one handler.** The
/// "View all" link is `onClick={() => isAuthenticated ? billsQuery.refetch()
/// : onRequireAuth()}`, and the error card's own button is the bare
/// `onClick={billsQuery.refetch}` (`:302`). Both are a refetch; the signed-out
/// half is a navigation the *widget* performs, so it never reaches this BLoC.
///
/// So "View all" **does not view all** — it re-reads the same 50 rows and
/// re-renders the same card. There is no `/applications` list route in the
/// citizen web app for it to open (`HistoryPage` is a different surface with a
/// different query), and inventing a navigation here would be a divergence no
/// fidelity tier can see. Ported as measured.
final class WalletBillsRetried extends WalletEvent {
  const WalletBillsRetried();
}

/// The ledger card's retry — `:609`.
final class WalletLedgerRetried extends WalletEvent {
  const WalletLedgerRetried();
}

/// The toggle above the list — `:394-404`.
///
/// Resets paging to 1 **in both directions** and the label names the
/// destination, not the current view (`B6-DIV-5`, `B6-AC-28`).
final class WalletLedgerToggled extends WalletEvent {
  const WalletLedgerToggled();
}

/// The ledger pager — `:686-700`.
final class WalletLedgerPageChanged extends WalletEvent {
  const WalletLedgerPageChanged(this.page);

  final int page;

  @override
  List<Object?> get props => <Object?>[page];
}

/// The top-up sheet mounted — `:726`, `useQuery(payments.methods, [])`.
///
/// This is where `/payment-methods` is fetched, and nowhere else in B6a
/// (`B6-AC-25`). Refetched on every mount, because the source's query has an
/// empty dependency list inside a component that is unmounted when the sheet
/// closes.
final class WalletTopUpSheetOpened extends WalletEvent {
  const WalletTopUpSheetOpened();
}

/// The sheet closed — clears the mutation's error so reopening does not show
/// the last attempt's message. `:812`'s error branch belongs to the query;
/// `:876`'s belongs to the mutation, and a `useMutation` is recreated with the
/// component.
final class WalletTopUpSheetClosed extends WalletEvent {
  const WalletTopUpSheetClosed();
}

/// The sheet's "Try again" — `:815`.
final class WalletPaymentMethodsRetried extends WalletEvent {
  const WalletPaymentMethodsRetried();
}

/// `submit()` — `WalletPage.tsx:741-749`.
///
/// **This event moves real money.** specs.md § 4.4 forbids executing the
/// underlying `POST /me/wallet/topup` against any host; every test of this path
/// runs against a mock transport.
///
/// [amountLak] is already an `int` here: the parse
/// (`parseTopUpAmount`, `B6-AC-34`) and the min/max guard (`B6-AC-35`,
/// security-review item 9) both run **before** the event is constructed, so no
/// unparsed value can reach the request body.
final class WalletTopUpSubmitted extends WalletEvent {
  const WalletTopUpSubmitted({
    required this.amountLak,
    required this.methodCode,
  });

  final int amountLak;
  final String methodCode;

  @override
  List<Object?> get props => <Object?>[amountLak, methodCode];
}

/// The pay sheet mounted over a Bills Due row — B6b, `WalletPage.tsx:520-550`.
///
/// `PaymentSection` fetches `/payment-methods` **on mount, unconditionally**
/// (`:205`) — the query has no `enabled` and no dependency list, because the
/// catalogue is anonymous. So this event does what [WalletTopUpSheetOpened]
/// does, for the other sheet, and clears the previous charge's outcome the way
/// remounting a `useMutation` does.
final class WalletPaySheetOpened extends WalletEvent {
  const WalletPaySheetOpened();
}

/// The pay sheet closed — clears the charge's error and result.
final class WalletPaySheetClosed extends WalletEvent {
  const WalletPaySheetClosed();
}

/// `submit()` — `PaymentSection.tsx:236-244`.
///
/// **This event moves real money.** specs.md § 4.4 forbids executing the
/// underlying `POST /applications/:id/pay` against any host, absolutely, and
/// forbids creating a case in order to have one to charge. Every test of this
/// path runs against a mock transport.
///
/// [applicationId] travels on the event rather than living in state because the
/// sheet is opened *for a row*: the source's `paying` is the `ApplicationRow`
/// itself (`:99`), and a BLoC field holding "the case currently being charged"
/// would be a second source of truth for something the widget already has.
final class WalletPaySubmitted extends WalletEvent {
  const WalletPaySubmitted({
    required this.applicationId,
    required this.methodCode,
  });

  final String applicationId;

  /// The method's `code` — never its id, label or kind (`B6-AC-36`).
  final String methodCode;

  @override
  List<Object?> get props => <Object?>[applicationId, methodCode];
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

/// One region's async status, ported from `useQuery`'s `{data, loading, error}`.
///
/// `error` is a `String?` and not a [Failure] because the four error branches
/// **render it** (`WalletPage.tsx:439,607,812,876`), so what the state needs is
/// the message; keeping the `Failure` would push `.message` into four widgets.
@freezed
abstract class WalletState with _$WalletState {
  const factory WalletState({
    @Default(false) bool isAuthenticated,

    // ── overview: `/me/wallet` ───────────────────────────────────────────────
    WalletOverview? overview,
    @Default(false) bool overviewLoading,
    String? overviewError,

    // ── bills: `/applications/?page=1&per_page=50` (B6b) ─────────────────────
    /// Already filtered to `payment_state === "pending" && fee_lak > 0` by
    /// [ListPendingBills] — the source filters at `:123-125`, immediately after
    /// the query and before anything reads it, so an unfiltered list never
    /// exists on the web either.
    @Default(<ApplicationRow>[]) List<ApplicationRow> bills,
    @Default(false) bool billsLoading,
    String? billsError,

    // ── receipts: `/me/transactions` ─────────────────────────────────────────
    @Default(<Transaction>[]) List<Transaction> receipts,
    @Default(false) bool receiptsLoading,
    String? receiptsError,

    // ── ledger: `/me/wallet/entries`, enabled only while [showLedger] ────────
    /// `null` until the first page has arrived. Distinguished from an empty
    /// page because the *first frame* of the ledger deliberately renders
    /// `overview.recentEntries` instead (§ 6.8(3)) — a distinction an empty
    /// `PagedRows` could not carry.
    PagedRows<WalletEntry>? ledger,
    @Default(false) bool ledgerLoading,
    String? ledgerError,
    @Default(false) bool showLedger,
    @Default(1) int ledgerPage,

    // ── methods: `/payment-methods`, fetched by the sheet ────────────────────
    @Default(<PaymentMethod>[]) List<PaymentMethod> methods,
    @Default(false) bool methodsLoading,
    String? methodsError,

    // ── the top-up mutation ──────────────────────────────────────────────────
    @Default(false) bool topUpPending,
    String? topUpError,

    /// Raised for one state emission after a successful credit, so the page can
    /// close the sheet. `onDone` (`:559-562`) is a callback on the web; a BLoC
    /// has no callbacks, so it is a flag the listener consumes.
    @Default(false) bool topUpSucceeded,

    // ── the pay mutation (B6b) ───────────────────────────────────────────────
    /// `charge.pending` — `PaymentSection.tsx:456`.
    @Default(false) bool payPending,

    /// `charge.error` — the **whole** failure, not its message.
    ///
    /// A `String?` here (as the four read regions carry) would throw away
    /// `.code`, and `.code` is what splits the render in two: an amber
    /// insufficient-funds panel with a top-up button versus a red line
    /// (`:219`, `:352-385`). [payInsufficient] is the split and it is the only
    /// reason this field is not a message.
    PaymentFailure? payFailure,

    /// `charge.data` — absent until a charge returns. **There is no
    /// "succeeded" flag beside it**, unlike [topUpSucceeded]: the source does
    /// not close the pay sheet on success, it *re-renders it* into a settled
    /// line or an instruction panel (`:439-450`), and the sheet stays open
    /// until the citizen dismisses it. `PaymentResult.isSettled` is what the
    /// terminal branch reads.
    PaymentResult? payResult,
  }) = _WalletState;

  const WalletState._();

  /// `overview?.wallet.balance_lak ?? 0` — `WalletPage.tsx:122`.
  int get balanceLak => overview?.wallet.balanceLak ?? 0;

  /// `walletQuery.loading && !overview` — `:184`.
  ///
  /// The ellipsis shows **only** before the first overview arrives. A refetch
  /// with an overview in hand shows the *old* balance (§ 6.8(7), `B6-AC-29`).
  bool get balanceIsPlaceholder => overviewLoading && overview == null;

  /// `ledgerQuery.data?.data ?? overview?.recent_entries ?? []` — `:130`.
  ///
  /// The ledger's first frame is deliberately **stale** (`B6-DIV-5`).
  List<WalletEntry> get ledgerEntries =>
      ledger?.rows ?? overview?.recentEntries ?? const <WalletEntry>[];

  /// `ledgerQuery.loading && entries.length === 0` — `:418`.
  ///
  /// The skeleton is **suppressed** whenever the stale first frame has
  /// something to draw (`B6-AC-27`).
  bool get ledgerSkeleton => ledgerLoading && ledgerEntries.isEmpty;

  /// `txQuery.loading && receipts.length === 0` — `:428`.
  bool get receiptsSkeleton => receiptsLoading && receipts.isEmpty;

  /// `isAuthenticated && billsQuery.loading && bills.length === 0` — `:287`.
  ///
  /// The `isAuthenticated` half is the source's and is not redundant: signed
  /// out the query never fires, so a skeleton there would be a two-card
  /// placeholder for a list that will never load. Slot `04-wallet` is a picture
  /// of the empty card, not of a skeleton.
  bool get billsSkeleton => isAuthenticated && billsLoading && bills.isEmpty;

  /// `bills.reduce((sum, b) => sum + b.fee_lak, 0)` — `WalletPage.tsx:126`.
  ///
  /// Rendered through `formatKip`, **not** `formatLak` (§ 6.5's table, `:274`)
  /// — this is one of the nine `formatKip` sites and one of the two the Bills
  /// Due card owns.
  int get billsTotalDue =>
      bills.fold<int>(0, (int sum, ApplicationRow b) => sum + b.feeLak);

  /// `charge.error?.code === "INSUFFICIENT_FUNDS"` — `PaymentSection.tsx:219`.
  ///
  /// The code, never the message (see [payFailure]). `ApiCode.insufficientFunds`
  /// was already in the substrate before B6 —
  /// `core/network/api_exception.dart:39`, specs.md § 2.2 Finding O — so this
  /// batch adds no code and invents no string.
  bool get payInsufficient => payFailure?.code == ApiCode.insufficientFunds;

  /// `charge.error && !insufficient` — `:380`.
  ///
  /// The generic red line is **suppressed** while the amber panel shows
  /// (`B6-AC-32`). Two error renders for one error, and only ever one at a
  /// time.
  String? get payGenericError => payInsufficient ? null : payFailure?.message;

  /// `ledgerQuery.data?.meta.page ?? ledgerPage` — `:421`.
  int get ledgerPageShown => ledger?.page ?? ledgerPage;

  /// `ledgerQuery.data?.meta.total_pages ?? 1` — `:422`.
  int get ledgerTotalPages => ledger?.totalPages ?? 1;

  /// `(methods.data ?? []).filter(m => m.enabled && m.code !== "wallet")`
  /// — `WalletPage.tsx:728`.
  ///
  /// **The wallet cannot top itself up.** Live `PaymentSection` filters on
  /// `m.enabled` alone (`PaymentSection.tsx:211`) and therefore keeps it — two
  /// different filters over one API, and `B6-AC-53` asserts 6 rows here and 7
  /// there against the same recorded fixture.
  List<PaymentMethod> get topUpOptions => methods
      .where((PaymentMethod m) => m.enabled && m.code != 'wallet')
      .toList(growable: false);
}

// ─────────────────────────────────────────────────────────────────────────────
// Bloc
// ─────────────────────────────────────────────────────────────────────────────

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  WalletBloc({
    required this.getWalletOverview,
    required this.getWalletEntries,
    required this.getTransactions,
    required this.getPaymentMethods,
    required this.topUpWallet,
    required this.listPendingBills,
    required this.payApplication,
  }) : super(const WalletState()) {
    on<WalletStarted>(_onStarted);
    on<WalletAuthChanged>(_onAuthChanged);
    on<WalletOverviewRetried>(_onOverviewRetried);
    on<WalletReceiptsRetried>(_onReceiptsRetried);
    on<WalletBillsRetried>(_onBillsRetried);
    on<WalletLedgerRetried>(_onLedgerRetried);
    on<WalletLedgerToggled>(_onLedgerToggled);
    on<WalletLedgerPageChanged>(_onLedgerPageChanged);
    on<WalletTopUpSheetOpened>(_onSheetOpened);
    on<WalletTopUpSheetClosed>(_onSheetClosed);
    on<WalletPaymentMethodsRetried>(_onMethodsRetried);
    on<WalletTopUpSubmitted>(_onTopUpSubmitted);
    on<WalletPaySheetOpened>(_onPaySheetOpened);
    on<WalletPaySheetClosed>(_onPaySheetClosed);
    on<WalletPaySubmitted>(_onPaySubmitted);
  }

  final GetWalletOverview getWalletOverview;
  final GetWalletEntries getWalletEntries;
  final GetTransactions getTransactions;
  final GetPaymentMethods getPaymentMethods;
  final TopUpWallet topUpWallet;

  /// B6b. Composes B7a's `ListApplications`, resolved out of
  /// `applicationInjection` by a DI closure — not a second `/applications`
  /// datasource (§ 2.3).
  final ListPendingBills listPendingBills;

  /// B6b. The pay capability F1, F2, F3 and B7 also consume (§ 6.3).
  final PayApplication payApplication;

  /// `hooks.ts:55` — `const generation = useRef(0)`, **one per query**.
  int _overviewGeneration = 0;
  int _receiptsGeneration = 0;
  int _ledgerGeneration = 0;
  int _methodsGeneration = 0;
  int _billsGeneration = 0;

  // ── Mount and session ──────────────────────────────────────────────────────

  /// Deliberately empty. See [WalletStarted].
  void _onStarted(WalletStarted event, Emitter<WalletState> emit) {}

  Future<void> _onAuthChanged(
    WalletAuthChanged event,
    Emitter<WalletState> emit,
  ) async {
    if (event.isAuthenticated == state.isAuthenticated) return;
    emit(state.copyWith(isAuthenticated: event.isAuthenticated));

    if (!event.isAuthenticated) {
      // `hooks.ts:58-61` returns early on `!enabled` **without touching
      // `data`**, so the web keeps the last-read rows in memory after a sign
      // out — they are simply never rendered, because every consuming branch is
      // itself behind `isAuthenticated` (`:409`). Holding a balance and an
      // account number in memory for the next citizen on the device is not a
      // behaviour worth being faithful about: SSD § 12 forbids persisting them
      // and this is the same hazard one layer up. Cleared, and recorded as the
      // one place this BLoC is deliberately stricter than `useQuery` — it is
      // unobservable on every fidelity tier because no signed-out surface reads
      // these fields.
      emit(
        state.copyWith(
          overview: null,
          receipts: const <Transaction>[],
          // B6b: a case's reference number, service name and outstanding fee are
          // the same class of datum as a balance, and the reasoning above applies
          // to them unchanged.
          bills: const <ApplicationRow>[],
          ledger: null,
          showLedger: false,
          ledgerPage: 1,
          overviewError: null,
          receiptsError: null,
          billsError: null,
          ledgerError: null,
        ),
      );
      return;
    }

    await Future.wait(<Future<void>>[
      _loadOverview(emit),
      _loadBills(emit),
      _loadReceipts(emit),
    ]);
  }

  // ── overview ───────────────────────────────────────────────────────────────

  Future<void> _onOverviewRetried(
    WalletOverviewRetried event,
    Emitter<WalletState> emit,
  ) async {
    if (!state.isAuthenticated) return;
    await _loadOverview(emit);
  }

  Future<void> _loadOverview(Emitter<WalletState> emit) async {
    final int mine = ++_overviewGeneration;
    emit(state.copyWith(overviewLoading: true, overviewError: null));

    final Either<Failure, WalletOverview> result = await getWalletOverview(
      NoParams(),
    );

    // "a newer request won" — `hooks.ts:73`.
    if (mine != _overviewGeneration || emit.isDone) return;

    emit(
      result.fold(
        (Failure f) =>
            state.copyWith(overviewLoading: false, overviewError: f.message),
        // `setData` on success only: a failed refetch leaves the previous
        // overview standing rather than blanking the card.
        (WalletOverview o) => state.copyWith(
          overviewLoading: false,
          overview: o,
          overviewError: null,
        ),
      ),
    );
  }

  // ── receipts ───────────────────────────────────────────────────────────────

  Future<void> _onReceiptsRetried(
    WalletReceiptsRetried event,
    Emitter<WalletState> emit,
  ) async {
    if (!state.isAuthenticated) return;
    await _loadReceipts(emit);
  }

  Future<void> _loadReceipts(Emitter<WalletState> emit) async {
    final int mine = ++_receiptsGeneration;
    emit(state.copyWith(receiptsLoading: true, receiptsError: null));

    // `{page: 1, per_page: 10}` — `WalletPage.tsx:111`. Page 1 is a literal on
    // the web: the receipts list has no pager, only the ledger does.
    final Either<Failure, PagedRows<Transaction>> result =
        await getTransactions(const WalletPageParams(page: 1));

    if (mine != _receiptsGeneration || emit.isDone) return;

    emit(
      result.fold(
        (Failure f) =>
            state.copyWith(receiptsLoading: false, receiptsError: f.message),
        (PagedRows<Transaction> p) => state.copyWith(
          receiptsLoading: false,
          receipts: p.rows,
          receiptsError: null,
        ),
      ),
    );
  }

  // ── bills (B6b) ────────────────────────────────────────────────────────────

  Future<void> _onBillsRetried(
    WalletBillsRetried event,
    Emitter<WalletState> emit,
  ) async {
    if (!state.isAuthenticated) return;
    await _loadBills(emit);
  }

  Future<void> _loadBills(Emitter<WalletState> emit) async {
    final int mine = ++_billsGeneration;
    emit(state.copyWith(billsLoading: true, billsError: null));

    final Either<Failure, List<ApplicationRow>> result = await listPendingBills(
      NoParams(),
    );

    if (mine != _billsGeneration || emit.isDone) return;

    emit(
      result.fold(
        (Failure f) =>
            state.copyWith(billsLoading: false, billsError: f.message),
        // `setData` on success only, as the other three regions do: a failed
        // refetch after a pay leaves the previous card standing rather than
        // blanking a list of outstanding fees.
        (List<ApplicationRow> rows) =>
            state.copyWith(billsLoading: false, bills: rows, billsError: null),
      ),
    );
  }

  // ── ledger ─────────────────────────────────────────────────────────────────

  /// `setLedgerPage(1); setShowLedger(s => !s)` — `WalletPage.tsx:399-400`.
  ///
  /// **Both directions reset the page** (`B6-DIV-5`, `B6-AC-28`), and closing
  /// the ledger drops its rows: the query's `enabled` goes false, and reopening
  /// re-runs it from page 1.
  Future<void> _onLedgerToggled(
    WalletLedgerToggled event,
    Emitter<WalletState> emit,
  ) async {
    if (!state.isAuthenticated) return;

    final bool opening = !state.showLedger;
    emit(
      state.copyWith(
        showLedger: opening,
        ledgerPage: 1,
        ledger: null,
        ledgerError: null,
      ),
    );

    if (opening) await _loadLedger(emit, 1);
  }

  Future<void> _onLedgerPageChanged(
    WalletLedgerPageChanged event,
    Emitter<WalletState> emit,
  ) async {
    if (!state.isAuthenticated || !state.showLedger) return;
    if (event.page == state.ledgerPage) return;

    emit(state.copyWith(ledgerPage: event.page));
    await _loadLedger(emit, event.page);
  }

  Future<void> _onLedgerRetried(
    WalletLedgerRetried event,
    Emitter<WalletState> emit,
  ) async {
    if (!state.isAuthenticated || !state.showLedger) return;
    await _loadLedger(emit, state.ledgerPage);
  }

  Future<void> _loadLedger(Emitter<WalletState> emit, int page) async {
    final int mine = ++_ledgerGeneration;
    emit(state.copyWith(ledgerLoading: true, ledgerError: null));

    final Either<Failure, PagedRows<WalletEntry>> result =
        await getWalletEntries(WalletPageParams(page: page));

    // The pager is the reason this stamp is not decorative: two taps on "next"
    // start two fetches, and `bloc`'s default transformer is concurrent.
    if (mine != _ledgerGeneration || emit.isDone) return;

    emit(
      result.fold(
        (Failure f) =>
            state.copyWith(ledgerLoading: false, ledgerError: f.message),
        (PagedRows<WalletEntry> p) =>
            state.copyWith(ledgerLoading: false, ledger: p, ledgerError: null),
      ),
    );
  }

  // ── /payment-methods, the sheet's own query ────────────────────────────────

  Future<void> _onSheetOpened(
    WalletTopUpSheetOpened event,
    Emitter<WalletState> emit,
  ) async {
    // The mutation is recreated with the component on the web (`:733`), so its
    // error does not survive a close/reopen.
    emit(state.copyWith(topUpError: null, topUpSucceeded: false));
    await _loadMethods(emit);
  }

  void _onSheetClosed(WalletTopUpSheetClosed event, Emitter<WalletState> emit) {
    emit(state.copyWith(topUpError: null, topUpSucceeded: false));
  }

  Future<void> _onMethodsRetried(
    WalletPaymentMethodsRetried event,
    Emitter<WalletState> emit,
  ) => _loadMethods(emit);

  Future<void> _loadMethods(Emitter<WalletState> emit) async {
    final int mine = ++_methodsGeneration;
    emit(state.copyWith(methodsLoading: true, methodsError: null));

    final Either<Failure, List<PaymentMethod>> result = await getPaymentMethods(
      NoParams(),
    );

    if (mine != _methodsGeneration || emit.isDone) return;

    emit(
      result.fold(
        (Failure f) =>
            state.copyWith(methodsLoading: false, methodsError: f.message),
        (List<PaymentMethod> rows) => state.copyWith(
          methodsLoading: false,
          methods: rows,
          methodsError: null,
        ),
      ),
    );
  }

  // ── the one write ──────────────────────────────────────────────────────────

  /// `submit()` — `WalletPage.tsx:741-749`, then `onDone` → `refreshMoney()`.
  ///
  /// **`refreshMoney` refetches the ledger only when the ledger is open**
  /// (`:136`, `B6-AC-26`) — and `/applications/` is B6b's, so two of the
  /// source's four refetches are what this reproduces.
  Future<void> _onTopUpSubmitted(
    WalletTopUpSubmitted event,
    Emitter<WalletState> emit,
  ) async {
    if (state.topUpPending) return; // `!topUp.pending` — `:740`.

    emit(
      state.copyWith(
        topUpPending: true,
        topUpError: null,
        topUpSucceeded: false,
      ),
    );

    final Either<Failure, Wallet> result = await topUpWallet(
      TopUpParams(amountLak: event.amountLak, methodCode: event.methodCode),
    );

    if (emit.isDone) return;

    final bool ok = result.isRight();
    emit(
      result.fold(
        (Failure f) =>
            state.copyWith(topUpPending: false, topUpError: f.message),
        // The returned `Wallet` is **discarded**, exactly as the source
        // discards the mutation's result: `onDone` closes the sheet and
        // re-reads `/me/wallet`. Rendering the returned balance instead would
        // be a narrowing the web does not perform.
        (Wallet _) => state.copyWith(topUpPending: false, topUpSucceeded: true),
      ),
    );

    if (!ok) return;

    await _refreshMoney(emit);
  }

  // ── the second write: the charge (B6b) ─────────────────────────────────────

  /// The pay sheet mounted. `PaymentSection.tsx:205` fetches the catalogue
  /// unconditionally on mount; `:207`'s `useMutation` is created with the
  /// component, so the previous charge's outcome does not survive a reopen.
  Future<void> _onPaySheetOpened(
    WalletPaySheetOpened event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(payFailure: null, payResult: null));
    await _loadMethods(emit);
  }

  void _onPaySheetClosed(
    WalletPaySheetClosed event,
    Emitter<WalletState> emit,
  ) {
    emit(state.copyWith(payFailure: null, payResult: null));
  }

  /// `submit()` — `PaymentSection.tsx:236-244`, then `onPaid` → `refreshMoney`
  /// (`WalletPage.tsx:543`).
  ///
  /// **§ 4.4 forbids executing this against any host.** The surface is built
  /// and proven against a mock transport; nothing in this batch has fired it.
  ///
  /// `if (!methodCode) return` (`:237`) is the widget's guard and stays there —
  /// it is the same condition as the CTA's `disabled` (`:456`), and duplicating
  /// it here would make the button's disabled state and the BLoC's early return
  /// two facts that can disagree. What *is* here is the in-flight guard, for the
  /// reason [WalletTopUpSubmitted]'s handler has one: `bloc`'s default event
  /// transformer is concurrent, so a double tap that outran a rebuild would
  /// otherwise issue two charges.
  Future<void> _onPaySubmitted(
    WalletPaySubmitted event,
    Emitter<WalletState> emit,
  ) async {
    if (state.payPending) return;

    emit(state.copyWith(payPending: true, payFailure: null, payResult: null));

    final Either<Failure, PaymentResult> result = await payApplication(
      PayApplicationParams(
        applicationId: event.applicationId,
        methodCode: event.methodCode,
      ),
    );

    if (emit.isDone) return;

    emit(
      result.fold(
        // The repository guarantees a `PaymentFailure` on this path — see
        // `wallet_repository_impl.dart`. The `is` test is the type system's
        // price for a shared `Either<Failure, …>`, not a doubt about it; a bare
        // `Failure` arriving here would lose only the amber branch, not the
        // message, which is the safe direction.
        (Failure f) => state.copyWith(
          payPending: false,
          payFailure: f is PaymentFailure
              ? f
              : PaymentFailure(f.message, ApiCode.internalError),
        ),
        (PaymentResult r) => state.copyWith(payPending: false, payResult: r),
      ),
    );

    if (result.isLeft()) return;

    // `onPaid={refreshMoney}` — `WalletPage.tsx:543`. **Fires on any successful
    // response, not only on a settled one**: a method that answers with an
    // instruction has still changed the case's payment state, and the source
    // does not inspect the result before refreshing.
    await _refreshMoney(emit);
  }

  /// `refreshMoney` — `WalletPage.tsx:132-137`.
  ///
  /// All four of the source's refetches now exist: overview, **bills** (B6b),
  /// receipts, and the ledger **only when the ledger is open** (`:136`). It
  /// fires from exactly two places — after a successful top-up and after a
  /// successful charge — and never on resume, on focus or on a timer
  /// (`B6-DIV-4`, `B6-AC-26`).
  Future<void> _refreshMoney(Emitter<WalletState> emit) async {
    await Future.wait(<Future<void>>[
      _loadOverview(emit),
      _loadBills(emit),
      _loadReceipts(emit),
      if (state.showLedger) _loadLedger(emit, state.ledgerPage),
    ]);
  }
}

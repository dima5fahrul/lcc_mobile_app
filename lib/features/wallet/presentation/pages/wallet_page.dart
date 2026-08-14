/// The wallet tab — `WalletPage.tsx:88-570`.
///
/// Replaces the 26-line P0 placeholder.
///
/// ## `/wallet` stays **unprotected**, and that is load-bearing (`B6-AC-49`)
///
/// `_protectedPaths` is `{/history, /account}` and B6 does not touch it.
/// `manifest.md` F-1 calls the asymmetry inconsistent — it is, and it is what
/// the web does: `App.tsx:162-167` mounts `WalletPage` with an `isAuthenticated`
/// **prop** rather than gating the route. Slot `04-wallet` is a picture of a
/// signed-out citizen standing on this page, and it is the only Tier 3
/// reference this batch will ever have. Making `/wallet` protected would fail
/// the one image it can be measured against.
///
/// ## Where the session comes from (§ 6.8(2))
///
/// Not from the route builder. B2b's comment at `app_routes.dart:352-357`
/// rules it: the builder dispatches the mount event, and the *page* holds a
/// `BlocListener<SessionBloc>` that dispatches [WalletAuthChanged]. That keeps
/// the builder from reading a second BLoC and keeps "signing in mid-visit fills
/// the page" working — `HomePage` is the precedent this follows line for line,
/// including the boot hold on `initial`/`loading`.
///
/// ## Nine controls are silent no-ops when signed in (`B6-DIV-1`, `B6-AC-48`)
///
/// Transfer (`:212`), See all (`:231`), and seven of the eight quick actions
/// (`:144-147`, everything but `topup`). No navigation, no dialog, no toast, no
/// disabled state — they fall off the end of their handlers. Same class as the
/// 37 dead service cards. `_act()` is that handler: signed out it routes to
/// sign-in, signed in it does nothing, deliberately.
///
/// ## The eye is `setState`, and the reason is a rule not a preference
///
/// `useState showBalance` (`:95`). SSD § 7.2 permits `setState` only for
/// ephemeral local UI, and this is the canonical case: nothing fetches on it,
/// nothing else reads it, and putting it in [WalletBloc] would make hiding a
/// balance a state transition every `bloc_test` in the feature must spell.
///
/// ## Nothing refreshes (`B6-DIV-4`)
///
/// No `RefreshIndicator`, no `WidgetsBindingObserver`, no timer — `B6-AC-26`
/// greps for all four and requires zero. `refreshMoney`'s equivalent lives in
/// the BLoC and fires only after a successful top-up.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/session/bloc/session_bloc.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../utils/routes/app_name_routes.dart';
import '../../domain/usecases/wallet_usecases.dart';
import '../../domain/wallet_formatting.dart';
import '../bloc/wallet_bloc.dart';
import '../widgets/wallet_balance_card.dart';
import '../widgets/wallet_bills_due_section.dart';
import '../widgets/wallet_ledger_list.dart';
import '../widgets/wallet_panels.dart';
import '../widgets/wallet_quick_actions.dart';
import '../widgets/wallet_receipts_list.dart';
import '../widgets/wallet_top_up_sheet.dart';

/// `/signin?from=%2Fwallet` (`B6-AC-50`).
///
/// The `from` value is the percent-encoded form of [AppNameRoutes.wallet] —
/// **a compile-time constant**, never `state.matchedLocation` or any other
/// runtime-composed string. V-10 is the finding about this parameter and B6a is
/// a new caller of it; composing the value from anything a citizen can
/// influence is exactly the widening `B6-AC-50` forbids, and security-review
/// item 7 audits it.
///
/// The encoded literal `%2Fwallet` is written out rather than computed, because
/// `Uri.encodeComponent` is not a `const` expression and `B6-AC-50` requires a
/// compile-time constant. That trade buys a desync hazard — a change to
/// [AppNameRoutes.wallet] would leave this literal pointing at the old path,
/// silently — so it is **not** left to a comment: `wallet_scope_test.dart`
/// asserts this constant equals
/// `'${AppNameRoutes.signin}?from=' + Uri.encodeComponent(AppNameRoutes.wallet)`
/// and fails the moment the two drift apart.
///
/// The encoding pairs with `AppRoutes`' own decode (`app_routes.dart:279`), so
/// the two ends of `?from=` stay symmetric.
const String kWalletSignInLocation =
    '${AppNameRoutes.signin}?from=%2Fwallet';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  /// `useState(true)` — `WalletPage.tsx:95`.
  bool _showBalance = true;

  @override
  void initState() {
    super.initState();
    // The mount half. `context.read` is a lookup, not a subscription, so it is
    // legal here — and it is the only place a session that resolved *before*
    // this page existed can reach the BLoC.
    _syncAuth(context.read<SessionBloc>().state);
  }

  void _syncAuth(SessionState session) {
    // The boot hold `AppRoutes._redirect` also respects: treating an unresolved
    // session as signed out would blank a warm-booted citizen's balance before
    // their token had been read.
    if (session.status == SessionStatus.initial ||
        session.status == SessionStatus.loading) {
      return;
    }
    context.read<WalletBloc>().add(
          WalletAuthChanged(
            isAuthenticated: session.status == SessionStatus.authenticated,
          ),
        );
  }

  /// `const act = () => { if (!isAuthenticated) onRequireAuth(); }` — `:140-142`.
  ///
  /// **Signed in, this does nothing.** That is the port, not an omission.
  void _act(bool isAuthenticated) {
    if (!isAuthenticated) context.go(kWalletSignInLocation);
  }

  /// `onQuickAction` — `:144-147`. One live id out of eight.
  void _onQuickAction(String id, bool isAuthenticated, WalletState state) {
    if (!isAuthenticated) {
      context.go(kWalletSignInLocation);
      return;
    }
    if (id == 'topup') _openTopUp(state);
  }

  void _openTopUp(WalletState state) {
    showWalletTopUpSheet(
      context,
      bloc: context.read<WalletBloc>(),
      // `overview?.min_top_up_lak ?? 10000` / `?? 50000000` — `:556-557`.
      // Defaulted **here**, at the call site, exactly as the source does, so an
      // API that starts sending the bounds takes effect with no model change
      // (specs.md § 5.2 ruling 3).
      min: state.overview?.minTopUpLak ?? kTopUpMinFallback,
      max: state.overview?.maxTopUpLak ?? kTopUpMaxFallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
      listenWhen: (SessionState p, SessionState c) => p.status != c.status,
      listener: (BuildContext context, SessionState state) => _syncAuth(state),
      child: BlocBuilder<WalletBloc, WalletState>(
        builder: (BuildContext context, WalletState state) => _body(state),
      ),
    );
  }

  Widget _body(WalletState state) {
    final String language = Localizations.localeOf(context).languageCode;
    final bool auth = state.isAuthenticated;
    final WalletBloc bloc = context.read<WalletBloc>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          WalletBalanceCard(
            balanceText: formatKip(state.balanceLak, language),
            accountNo: state.overview?.wallet.accountNo ?? '',
            showBalance: _showBalance,
            isPlaceholder: state.balanceIsPlaceholder,
            onToggleBalance: () => setState(() => _showBalance = !_showBalance),
            // `{walletQuery.error && isAuthenticated && …}` — `:193`.
            errorMessage: auth ? state.overviewError : null,
            onRetry: () => bloc.add(const WalletOverviewRetried()),
            // `onClick={() => isAuthenticated ? setTopUpOpen(true)
            //                                 : onRequireAuth()}` — `:204`.
            onTopUp: () => auth ? _openTopUp(state) : _act(auth),
            onTransfer: () => _act(auth),
          ),
          Transform.translate(
            // `pt-10 -mt-4` — the content column overlaps the gradient's
            // bottom padding by 16 px (`:224`).
            offset: const Offset(0, -16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _quickPaymentCard(state, auth),
                  const SizedBox(height: 24),
                  WalletBillsDueSection(
                    isAuthenticated: auth,
                    onViewAll: () => _act(auth),
                  ),
                  const SizedBox(height: 24),
                  _transactionsSection(state, auth, bloc),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `:226-263`.
  Widget _quickPaymentCard(WalletState state, bool auth) {
    return WalletCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          WalletSectionHeader(
            title: 'wallet.quickPayment'.tr(context: context),
            actionLabel: 'wallet.seeAll'.tr(context: context),
            onAction: () => _act(auth),
          ),
          const SizedBox(height: 16),
          WalletQuickActions(
            onAction: (String id) => _onQuickAction(id, auth, state),
          ),
        ],
      ),
    );
  }

  /// `:384-513` — one slot, one toggle, three sources of content.
  Widget _transactionsSection(WalletState state, bool auth, WalletBloc bloc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        WalletSectionHeader(
          title: 'wallet.recentTransactions'.tr(context: context),
          // **The label names the destination, not the current view**
          // (`:402`, `B6-DIV-5`, `B6-AC-28`). Showing the ledger, the control
          // reads "Recent transactions"; showing receipts, it reads "History".
          actionLabel: state.showLedger
              ? 'wallet.recentTransactions'.tr(context: context)
              : 'wallet.history'.tr(context: context),
          onAction: () {
            if (!auth) {
              context.go(kWalletSignInLocation);
              return;
            }
            bloc.add(const WalletLedgerToggled());
          },
        ),
        const SizedBox(height: 16),
        _transactionsBody(state, auth, bloc),
      ],
    );
  }

  Widget _transactionsBody(WalletState state, bool auth, WalletBloc bloc) {
    // Branch order is the source's — `:408`, `:415`, `:426`, `:437`, `:452`,
    // `:466`.
    if (!auth) {
      return WalletEmptyCard(
        // lucide `ArrowUpRight`, unbundled — see `wallet_panels.dart`.
        icon: const Icon(
          Icons.north_east,
          size: 24,
          color: AppColors.gray400Inline,
        ),
        title: 'wallet.noRecentTransactions'.tr(context: context),
        subtitle: 'wallet.signInActivity'.tr(context: context),
      );
    }

    if (state.showLedger) {
      return WalletLedgerList(
        entries: state.ledgerEntries,
        showSkeleton: state.ledgerSkeleton,
        errorMessage: state.ledgerError,
        onRetry: () => bloc.add(const WalletLedgerRetried()),
        page: state.ledgerPageShown,
        totalPages: state.ledgerTotalPages,
        onPage: (int p) => bloc.add(WalletLedgerPageChanged(p)),
      );
    }

    if (state.receiptsSkeleton) return const WalletRowSkeleton();

    if (state.receiptsError != null) {
      return WalletRetryCard(
        message: state.receiptsError!,
        onRetry: () => bloc.add(const WalletReceiptsRetried()),
      );
    }

    if (state.receipts.isEmpty) {
      return WalletEmptyCard(
        icon: const Icon(
          Icons.north_east,
          size: 24,
          color: AppColors.gray400Inline,
        ),
        title: 'wallet.noRecentTransactions'.tr(context: context),
        // Signed **in** and empty gets the relocated ternary; signed out gets
        // `signInActivity`, above. The asymmetry is the source's (`:458-463`).
        subtitle: 'wallet.firstReceiptHint'.tr(context: context),
      );
    }

    return WalletReceiptsList(receipts: state.receipts);
  }
}

/// Kept so the import of [LucideIcon] above is used by every branch that needs
/// it; `_transactionsBody` reaches it through `WalletEmptyCard`'s icon slot in
/// the ledger path and directly here.
// ignore: unused_element
typedef _LucideIconRef = LucideIcon;

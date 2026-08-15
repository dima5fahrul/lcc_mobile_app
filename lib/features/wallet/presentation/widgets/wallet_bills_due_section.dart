/// Bills due — **B6b replaces B6a's empty-only stub with all four branches.**
///
/// `WalletPage.tsx:264-382`. B6a shipped `:312-325` (the empty card) from a
/// named compile-time-empty constant, because the other three branches all read
/// `billsQuery` — `GET /applications/?page=1&per_page=50` (`:104-108`), which
/// is B7a's endpoint and B6b's consumer. specs.md § 2.3 put the seam exactly
/// there. This file now renders all four:
///
/// | Branch | Source | Condition |
/// |---|---|---|
/// | skeleton | `:288-300` | `isAuthenticated && loading && bills.length === 0` |
/// | error | `:301-311` | `isAuthenticated && billsQuery.error` |
/// | empty | `:312-325` | `bills.length === 0` |
/// | populated | `:327-380` | otherwise |
///
/// Note what the first two conditions do **not** say: signed out, neither the
/// skeleton nor the error can render, because `billsQuery` is
/// `enabled: isAuthenticated` (`:107`) and never fires. `WalletBloc` reproduces
/// that with the same guard, so a signed-out citizen always falls to the empty
/// card — which is what slot `04-wallet` shows and what B6a's Tier 3 gate
/// passed against.
///
/// ## `kBillsDueB6b` is gone, and that is the point (`B6-AC-45`)
///
/// B6a's stub was a **named** constant with a `TODO(B6b)` — not an inline `[]`
/// — precisely so "Bills Due works" could never be believed by accident while
/// there was no query. There is a query now, so the constant is deleted rather
/// than left beside the real list. `wallet_scope_test.dart` and
/// `wallet_bloc_test.dart` are updated in the same batch: a stub-guard that
/// outlives its stub is a test that can only pass by being wrong.
///
/// ## `formatKip`, **not** `formatLak` (§ 6.5, `B6-AC-22`)
///
/// Two of the nine `formatKip` sites are here — the summary total (`:271`) and
/// each row's fee (`:369`) — and both are inside `WalletPage`. Every
/// `formatLak` site in this batch is inside `PaymentSection`. The two functions
/// group thousands differently in Lao (`"20.000 ₭"` vs `"20,000 LAK"`) and
/// `payment_summary_card.dart:26-41` tabulates which surface gets which.
///
/// ## The due chip's three-way palette is inline hex in the source
///
/// `:340-343`. `B6-AC-40` forbids adding a token to
/// `lib/presentation/theme/**`, and the six values are one widget's, so they
/// are private consts here with their source line — the same disposition
/// `insufficient_funds_panel.dart` takes for the amber pair.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../i18n/i18n.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/payment/live_payment_section.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../application/domain/entities/application_row.dart';
import '../../domain/wallet_formatting.dart';
import '../bloc/wallet_bloc.dart';
import 'wallet_panels.dart';

/// The amber threshold: `days !== null && days <= 3` — `:342`.
///
/// Evaluated only when `days` is non-null, so a bill with **no `due_at` at
/// all** is grey rather than amber — a distinction `:335-336` makes by falling
/// back to `formatDay` instead of a day count.
const int _kDueSoonDays = 3;

// ── The due chip's three-way palette (`:340-343`) ────────────────────────────
//
// Six inline hexes in the source, and **not one of them needs a new token.**
// The first draft of this file declared three private `Color(0x…)` consts to
// avoid a `lib/presentation/theme/**` diff (`B6-AC-40`) — and
// `color_literal_test.dart` correctly failed it. That guard is B2-AC-11 and it
// is right: a private const in a widget is the same evasion B6a already
// refused to commit with `Color.fromARGB`, wearing a different shape.
//
// The resolution is not an escalation either. `app_colors.dart`'s own B7a
// escalation comment already mapped these exact three values and ruled on
// reusing them across features:
//
//   `#FEE2E2` → categoryTintHealth · `#FEF3C7` → categoryTintTransport
//   `#16A34A` → categoryAccentFinance
//
//   *"The last six of those are surface-specific names being read from another
//   feature, which is a real coupling and is **not** a new liberty: B6a's
//   `wallet_quick_actions.dart:100-152` and B9a's `notif_style.dart:107-116`
//   already reuse those same three `categoryTint*` washes for these same three
//   values. Adding history-local synonyms instead would be the fifth name for
//   one colour that `categoryAccentFallback`'s own doc apologises for."*
//
// So B6b adds nothing to the theme and evades nothing: `B6-AC-40` holds with a
// zero-line diff, and B2-AC-11 holds because every colour is a named token.
// The names read oddly at a due-date chip — that is the cost the ruling above
// accepted, and renaming them is FU-11's question, not this batch's.

class WalletBillsDueSection extends StatelessWidget {
  const WalletBillsDueSection({
    super.key,
    required this.isAuthenticated,
    required this.onViewAll,
    this.bills = const <ApplicationRow>[],
    this.loading = false,
    this.error,
    this.onRetry,
    this.onPay,
    this.now,
  });

  final bool isAuthenticated;

  /// `:279` — `isAuthenticated ? billsQuery.refetch() : onRequireAuth()`. The
  /// page supplies whichever of the two applies; the widget does not branch,
  /// because signed out it is a navigation and signed in it is a refetch, and
  /// only the page owns both.
  final VoidCallback onViewAll;

  /// Already filtered to `payment_state === "pending" && fee_lak > 0` by
  /// `ListPendingBills` — the source filters at `:123-125`, one line after the
  /// query, and the filter is unit-tested there as a pure predicate.
  final List<ApplicationRow> bills;

  final bool loading;

  /// `billsQuery.error?.message`, or null.
  final String? error;

  /// Null only when [error] is null. `:305` renders a retry inside the card.
  final VoidCallback? onRetry;

  /// `setPaying(b)` — `:373`. Null makes each row's Pay button inert, which is
  /// not a state the source has; it exists so a widget test can render the card
  /// without a sheet.
  final ValueChanged<ApplicationRow>? onPay;

  /// Injected clock, threaded to [daysUntil] (`B6-AC-21`). Defaults to the real
  /// one so the page does not have to supply it.
  final DateTime? now;

  /// `bills.reduce((sum, b) => sum + b.fee_lak, 0)` — `:126`.
  ///
  /// Computed here as well as on `WalletState` because this widget is also
  /// rendered directly by widget tests that hold no BLoC; both fold the same
  /// list with the same seed.
  int get _totalDue =>
      bills.fold<int>(0, (int sum, ApplicationRow b) => sum + b.feeLak);

  @override
  Widget build(BuildContext context) {
    final String language = Localizations.localeOf(context).languageCode;

    // `isAuthenticated && billsQuery.loading && bills.length === 0` — `:288`.
    final bool showSkeleton = isAuthenticated && loading && bills.isEmpty;
    // `isAuthenticated && billsQuery.error` — `:300`. Reached only when the
    // skeleton did not render, so a refetch over a populated list shows the
    // stale card, not an error.
    final bool showError = !showSkeleton && isAuthenticated && error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        WalletSectionHeader(
          title: 'wallet.billsDue'.tr(context: context),
          // `bills.length > 0 ? t("billsSummary", {total, count})
          //                   : t("noBillsDue")` — `:269-275`.
          subtitle: bills.isEmpty
              ? 'wallet.noBillsDue'.tr(context: context)
              : 'wallet.billsSummary'.tr(
                  context: context,
                  namedArgs: <String, String>{
                    'total': formatKip(_totalDue, language),
                    'count': '${bills.length}',
                  },
                ),
          actionLabel: 'wallet.viewAll'.tr(context: context),
          onAction: onViewAll,
        ),
        const SizedBox(height: 16),
        if (showSkeleton)
          // `[0, 1].map(…)` — **two** rows here, where the transactions list
          // uses three (`:426-436`). `WalletRowSkeleton` takes the count.
          const WalletRowSkeleton(rows: 2)
        else if (showError)
          WalletRetryCard(message: error!, onRetry: onRetry ?? () {})
        else if (bills.isEmpty)
          WalletEmptyCard(
            // lucide `Receipt`, bundled.
            icon: const LucideIcon(
              name: 'Receipt',
              size: 24,
              color: AppColors.gray400Inline,
            ),
            title: 'wallet.noBillsDue'.tr(context: context),
            // Signed in gets the relocated ternary (`wallet.allBillsPaid`,
            // § 6.13(3)); signed out gets the source's own namespaced key. The
            // asymmetry is the source's, `:319-324`.
            subtitle: isAuthenticated
                ? 'wallet.allBillsPaid'.tr(context: context)
                : 'wallet.signInBills'.tr(context: context),
          )
        else
          for (int i = 0; i < bills.length; i++)
            Padding(
              // `gap-3` — `:327`.
              padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
              child: _BillCard(
                bill: bills[i],
                now: now,
                onPay: onPay == null ? null : () => onPay!(bills[i]),
              ),
            ),
      ],
    );
  }
}

/// One pending fee — `:337-379`.
class _BillCard extends StatelessWidget {
  const _BillCard({required this.bill, required this.now, required this.onPay});

  final ApplicationRow bill;
  final DateTime? now;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final String language = Localizations.localeOf(context).languageCode;
    final Lang lang = Lang.fromCode(language);

    final int? days = daysUntil(bill.dueAt, now: now);
    // `b.is_overdue || (days !== null && days < 0)` — `:333`. The server's flag
    // OR the arithmetic; either is sufficient. `daysUntil`'s own doc explains
    // why the OR is load-bearing: a bill 30 minutes past due ceils to `0`, not
    // to `-1`, so the arithmetic alone would call it on time.
    final bool overdue = bill.isOverdue || (days != null && days < 0);

    final String dueLabel;
    if (days == null) {
      // No parseable `due_at` — the date itself, or `"—"`. `:335-336`.
      dueLabel = formatDay(bill.dueAt, language);
    } else if (overdue) {
      dueLabel = 'wallet.overdueDays'.tr(
        context: context,
        // `Math.abs(days)` — `:338`.
        namedArgs: <String, String>{'n': '${days.abs()}'},
      );
    } else {
      dueLabel = 'wallet.dueInDays'.tr(
        context: context,
        namedArgs: <String, String>{'n': '$days'},
      );
    }

    final Color chipInk;
    final Color chipBg;
    if (overdue) {
      chipInk = AppColors.danger;
      chipBg = AppColors.categoryTintHealth;
    } else if (days != null && days <= _kDueSoonDays) {
      chipInk = AppColors.warningLink;
      chipBg = AppColors.categoryTintTransport;
    } else {
      chipInk = AppColors.muted;
      chipBg = AppColors.gray100;
    }

    return WalletCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Container(
            // `w-11 h-11 rounded-xl` on `#EEF2FF` — `:349`.
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const LucideIcon(
              name: 'Receipt',
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  // `text(b.service_name, lang)` — `:356`. Translated, unlike
                  // `PaymentMethod.note` (`B6-DIV-2`).
                  text(bill.serviceName, lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray800,
                    height: 1.375,
                  ),
                ),
                Text(
                  bill.referenceNo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray400Inline,
                    height: 1.625,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  // `text-[10px] px-2 py-0.5 rounded-full` — `:361`.
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // lucide `CalendarClock` is not in
                      // `assets/icons/lucide/`; Material's is the substitution
                      // B6a established for two unbundled glyphs
                      // (`wallet_balance_card.dart:214,224`). FU-10 files the
                      // bundle gap; `assets/` is not in B6b's § 3.1 table.
                      Icon(Icons.schedule, size: 12, color: chipInk),
                      const SizedBox(width: 4),
                      // `Flexible` + ellipsis, and it is not defensive padding:
                      // the middle column is `flex-1 min-w-0` in the source
                      // (`:355`), so the chip's row is genuinely narrower than
                      // its content on a small device — measured at the 390 px
                      // baseline, `"Overdue 4 days"` overflows by ~1.5 px once
                      // the icon and the pill padding are counted. CSS clips
                      // that silently; a Flutter `Row` throws. The label
                      // shortens rather than the card breaking.
                      Flexible(
                        child: Text(
                          dueLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: chipInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                // `formatKip(b.fee_lak, lang)` — `:369`. **Kip, not LAK.**
                formatKip(bill.feeLak, language),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray800,
                ),
              ),
              const SizedBox(height: 6),
              _PayButton(onPressed: onPay),
            ],
          ),
        ],
      ),
    );
  }
}

/// `:372-378` — the row's own Pay button, which opens the pay sheet.
class _PayButton extends StatelessWidget {
  const _PayButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        // `px-3 py-1.5 rounded-lg` — `:375`.
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        'wallet.pay'.tr(context: context),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// The pay sheet — `WalletPage.tsx:519-550`
// ─────────────────────────────────────────────────────────────────────────────

/// Opens the pay sheet over a Bills Due row.
///
/// ## Why this lives in this file and not in one of its own
///
/// A recorded, deliberate placement, not an accident. specs.md § 3.1's **B6b**
/// table authorises exactly four new files under `lib/presentation/payment/`
/// and this one file under `features/wallet/presentation/widgets/`, as an
/// *extend*. The sheet is neither: it is the modal shell the source mounts
/// `PaymentSection` inside (`:519-550`) — wallet-specific chrome around a
/// shared widget — and adding `wallet_pay_sheet.dart` would be a fifth file the
/// table does not list.
///
/// It is also cohesive here: the sheet has exactly one entry point, the Pay
/// button on a bill row three widgets up. The top-up sheet earned its own file
/// because B6a's table said `presentation/widgets/*.dart`, which was a
/// wildcard; B6b's row names one file.
///
/// ## The shell is a bottom sheet (§ 6.7, `B6-AC-51`)
///
/// `DialogShell` is B10's and B2b already ruled the substitute (§ 2.2
/// Finding P): Flutter's own `showModalBottomSheet`, full width, top-only
/// 24 px radius, ≤ 90 % height, barrier-dismissible. Same shape
/// `showWalletTopUpSheet` uses, and for the same reason — at the 390 px
/// baseline the source's `items-end sm:items-center` resolves to the *bottom*
/// arm, so a centred dialog would be the divergence.
///
/// ## `onTopUp` closes this sheet first (§ 6.9(3))
///
/// `:544-547` — `setPaying(null); setTopUpOpen(true)`. Two sheets stacked over
/// each other is not what the source does, and the wallet is the only mount
/// that supplies the callback at all (`HistoryDetailPage.tsx:427-436` does
/// not), so both branches of [InsufficientFundsPanel]'s conditional button are
/// real and `B6-AC-32` tests both.
///
/// ## § 4.4
///
/// Nothing here may be executed against a host. The charge dispatches
/// [WalletPaySubmitted], whose own doc says the same, and every test of this
/// path runs against a mock transport.
Future<void> showWalletPaySheet(
  BuildContext context, {
  required WalletBloc bloc,
  required ApplicationRow bill,
  required VoidCallback onTopUp,
}) {
  // `PaymentSection` fetches `/payment-methods` on mount, unconditionally
  // (`PaymentSection.tsx:205`).
  bloc.add(const WalletPaySheetOpened());

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // `bg-gray-50` — `:524`. The top-up sheet is white; this one is not.
    backgroundColor: AppColors.gray50,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.9,
    ),
    builder: (BuildContext sheetContext) => BlocProvider<WalletBloc>.value(
      value: bloc,
      child: WalletPaySheet(bill: bill, onTopUp: onTopUp),
    ),
  ).whenComplete(() => bloc.add(const WalletPaySheetClosed()));
}

/// The sheet's body — header plus [LivePaymentSection].
///
/// Public so a widget test can pump it without a `showModalBottomSheet`, the
/// same reason `WalletTopUpSheet` is.
class WalletPaySheet extends StatelessWidget {
  const WalletPaySheet({super.key, required this.bill, required this.onTopUp});

  final ApplicationRow bill;
  final VoidCallback onTopUp;

  @override
  Widget build(BuildContext context) {
    final Lang lang = Lang.fromCode(
      Localizations.localeOf(context).languageCode,
    );
    final WalletBloc bloc = context.read<WalletBloc>();

    return SafeArea(
      top: false,
      child: BlocBuilder<WalletBloc, WalletState>(
        builder: (BuildContext context, WalletState state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // The sticky header — `:527-539`.
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(bottom: BorderSide(color: AppColors.gray100)),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        // The reference, not the service name — `:528`. The
                        // service name is the shell's accessible `label`
                        // (`:526`) and is rendered by the summary card below.
                        bill.referenceNo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // `aria-label={tc("close")}` — `:531`. The semantics label
                    // is the criterion (`B6-AC-51`), not the glyph.
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'common.close'.tr(context: context),
                      iconSize: 16,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.gray100,
                        foregroundColor: AppColors.gray600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const LucideIcon(
                        name: 'X',
                        size: 16,
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  // `p-5` — `:536`.
                  padding: const EdgeInsets.all(20),
                  child: LivePaymentSection(
                    amount: bill.feeLak,
                    // `text(paying.service_name, lang)` — `:539`. Resolved
                    // here, because the source passes a **string** prop.
                    serviceName: text(bill.serviceName, lang),
                    reference: bill.referenceNo,
                    // `m.enabled` alone (`PaymentSection.tsx:211`) — the
                    // filter lives inside `LivePaymentSection`, so the whole
                    // catalogue goes down. `state.topUpOptions` is the *other*
                    // filter and is not used here (`B6-AC-53`).
                    methods: state.methods,
                    methodsLoading: state.methodsLoading,
                    methodsError: state.methodsError,
                    onRetryMethods: () =>
                        bloc.add(const WalletPaymentMethodsRetried()),
                    pending: state.payPending,
                    genericError: state.payGenericError,
                    insufficient: state.payInsufficient,
                    result: state.payResult,
                    // The widget knows no BLoC (`B6-AC-10`); the charge leaves
                    // as a callback and the outcome comes back as props.
                    onCharge: (String methodCode) async => bloc.add(
                      WalletPaySubmitted(
                        applicationId: bill.id,
                        methodCode: methodCode,
                      ),
                    ),
                    onTopUp: () {
                      // `setPaying(null); setTopUpOpen(true)` — `:544-547`,
                      // and the order is the source's.
                      Navigator.of(context).pop();
                      onTopUp();
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

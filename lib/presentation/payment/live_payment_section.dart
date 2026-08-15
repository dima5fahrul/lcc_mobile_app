/// Live-mode `PaymentSection` — `PaymentSection.tsx:274-471`.
///
/// A citizen picks a rail from `/payment-methods` and presses a charge button.
/// B6b owns this; specs.md § 6.3 rules the seam.
///
/// ## What this widget is NOT allowed to do (`B6-AC-10`)
///
/// It resolves nothing, injects nothing and knows no BLoC. Everything arrives
/// as a parameter and the charge leaves as [onCharge], a
/// `Future<void> Function(String methodCode)` supplied by the mount. That is
/// not stylistic: it is what keeps B7 able to mount it over
/// `features/history`'s BLoC without a second copy, and `lib/presentation/**`
/// may not import `features/*/presentation/**` at all (G-L7). The grep in
/// `B6-AC-10` looks for `BlocProvider`, `*Injection`, a `di/` import and a
/// direct use-case call, and finds none of the four here.
///
/// The one piece of state it *does* own is [_LivePaymentSectionState._picked] —
/// `useState<string>("")` at `:207`, local UI selection, which the source also
/// keeps inside the component.
///
/// ## Who mounts it
///
/// The wallet's Bills Due pay sheet (`WalletPage.tsx:538-548`, B6b) and the
/// history detail panel (`HistoryDetailPage.tsx:427-436`, B7). **Not** the
/// certificate wizards: F1/F2/F3 call `PayApplication` from inside their submit
/// orchestration and have no method picker to show, because their method code
/// comes from draft form state or a fixed preference order. `pay_application.dart`
/// tabulates all five call sites.
///
/// **Draft mode is not here and is not B6's** (`PaymentSection.tsx:474-670`,
/// `LAO_BANKS`, `isPaymentValid`, `formatCard`, `formatExpiry`). It is a wizard
/// step over a form kernel, it belongs to F0/F1/F3, and `B6-AC-47` greps `lib`
/// for its identifiers and requires zero from this batch.
///
/// ## Default selection is data, never a literal (`B6-AC-31`)
///
/// `picked || enabled[0]?.code || ""` (`:215`) — whatever the API sorts first,
/// which is `wallet` in today's recording and is not guaranteed to stay that
/// way. Hardcoding a preferred rail would be a product decision this port has
/// no authority to make.
///
/// ## The four CTA states, and they are four (§ 6.9(4))
///
/// `settled` → a green receipt line. `instruction` present but not settled → a
/// centred grey sentence. Otherwise → the charge button, **rendered only when
/// `enabled.length > 0`** (`:452`). And a catalogue that resolved to nothing
/// enabled renders neither a button nor an error, just a sentence (`:305-313`).
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../features/wallet/domain/entities/payment_method.dart';
import '../../features/wallet/domain/entities/payment_result.dart';
import '../../features/wallet/domain/wallet_formatting.dart';
import '../../i18n/i18n.dart';
import '../icons/lucide_icon.dart';
import '../theme/app_colors.dart';
import 'insufficient_funds_panel.dart';
import 'payment_instruction_panel.dart';
import 'payment_method_tile.dart';
import 'payment_summary_card.dart';

class LivePaymentSection extends StatefulWidget {
  const LivePaymentSection({
    super.key,
    required this.amount,
    required this.serviceName,
    required this.reference,
    required this.methods,
    required this.methodsLoading,
    required this.onRetryMethods,
    required this.onCharge,
    this.methodsError,
    this.breakdown = const <PaymentBreakdownItem>[],
    this.pending = false,
    this.genericError,
    this.insufficient = false,
    this.result,
    this.onTopUp,
  });

  /// The case fee in LAK — the source's `amount` prop.
  final int amount;

  /// Already resolved to a string by the mount, as `WalletPage.tsx:538` does
  /// (`text(paying.service_name, lang)`).
  final String serviceName;

  /// The case's `reference_no`. Third in the instruction panel's fallback.
  final String reference;

  /// The **whole** catalogue. Filtered to `m.enabled` here, at `:211` — the
  /// top-up sheet's filter is different (`m.enabled && m.code !== "wallet"`,
  /// `WalletPage.tsx:728`) and `B6-AC-53` asserts the two against the same
  /// 7-row fixture, expecting 7 rows here and 6 there.
  final List<PaymentMethod> methods;

  final bool methodsLoading;

  /// `methods.error?.message`, or null.
  final String? methodsError;

  final VoidCallback onRetryMethods;

  /// The itemised fee, if the mount has one. Passed through to
  /// [PaymentSummaryCard], which shows it only at two rows or more.
  final List<PaymentBreakdownItem> breakdown;

  /// `charge.pending` — `:456`.
  final bool pending;

  /// `charge.error.message` for a failure that is **not** insufficient funds.
  /// The mount is responsible for the split, because it is the layer that holds
  /// the `PaymentFailure` and its `code` (`WalletState.payGenericError`).
  final String? genericError;

  /// `charge.error?.code === "INSUFFICIENT_FUNDS"` — `:219`.
  final bool insufficient;

  /// `charge.data` — absent until a charge answers.
  final PaymentResult? result;

  /// `submit()` — `:236-244`. Returns a `Future` so a mount that awaits the
  /// charge can, and so this widget never needs to know whether it resolved.
  /// The source swallows the rejection (`catch { /* rendered from
  /// charge.error */ }`) because the failure comes back down as a prop, and so
  /// does this: [genericError] and [insufficient] are how a failure is seen.
  final Future<void> Function(String methodCode) onCharge;

  /// Null when the mount offers no top-up route — see
  /// [InsufficientFundsPanel]'s library doc for why both branches are real.
  final VoidCallback? onTopUp;

  @override
  State<LivePaymentSection> createState() => _LivePaymentSectionState();
}

class _LivePaymentSectionState extends State<LivePaymentSection> {
  /// `const [picked, setPicked] = useState<string>("")` — `:207`. Empty means
  /// "the citizen has not chosen", which is different from "the first one".
  String _picked = '';

  /// `(methods.data ?? []).filter((m) => m.enabled)` — `:210`.
  List<PaymentMethod> get _enabled => widget.methods
      .where((PaymentMethod m) => m.enabled)
      .toList(growable: false);

  /// `picked || enabled[0]?.code || ""` — `:215`. JS `||`, so a `picked` that
  /// was somehow set to `""` falls through to the catalogue's first, and a
  /// catalogue with nothing enabled yields `""`, which disables the CTA.
  String _methodCode(List<PaymentMethod> enabled) {
    if (_picked.isNotEmpty) return _picked;
    if (enabled.isNotEmpty) return enabled.first.code;
    return '';
  }

  Future<void> _submit(String methodCode) async {
    // `if (!methodCode) return;` — `:237`.
    if (methodCode.isEmpty) return;
    await widget.onCharge(methodCode);
  }

  @override
  Widget build(BuildContext context) {
    final String language = Localizations.localeOf(context).languageCode;
    final Lang lang = Lang.fromCode(language);

    final List<PaymentMethod> enabled = _enabled;
    final String methodCode = _methodCode(enabled);
    // `enabled.find((m) => m.code === methodCode)` — `:218`. Null when the
    // catalogue is empty or still loading.
    PaymentMethod? chosen;
    for (final PaymentMethod m in enabled) {
      if (m.code == methodCode) {
        chosen = m;
        break;
      }
    }

    final PaymentResult? result = widget.result;
    final PaymentInstruction? instruction = result?.instruction;
    // The three resolution rules live on the entity (§ 6.9(1)) so `B6-AC-30`
    // can exercise the `||` / `??` difference without a widget.
    final String receiptNo = result?.resolvedReceiptNo ?? '';
    final int chargedAmount =
        result?.chargedAmount(widget.amount) ?? widget.amount;
    final bool settled = result?.isSettled ?? false;

    final String? methodsError = widget.methodsError;
    final bool showEmptyCatalogue =
        !widget.methodsLoading && methodsError == null && enabled.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // `:246-271` — shared with draft mode, which is why it is B6a's.
        PaymentSummaryCard(
          amount: widget.amount,
          serviceName: widget.serviceName,
          breakdown: widget.breakdown,
        ),

        if (widget.methodsLoading) ...<Widget>[
          const SizedBox(height: 20),
          const _MethodSkeleton(),
        ],

        if (methodsError != null && !widget.methodsLoading) ...<Widget>[
          const SizedBox(height: 20),
          _MethodsErrorCard(
            message: methodsError,
            onRetry: widget.onRetryMethods,
          ),
        ],

        if (showEmptyCatalogue) ...<Widget>[
          const SizedBox(height: 20),
          _CentredNoticeCard(
            message: 'payment.noMethodAvailable'.tr(context: context),
          ),
        ],

        if (enabled.isNotEmpty) ...<Widget>[
          const SizedBox(height: 20),
          for (int i = 0; i < enabled.length; i++)
            Padding(
              // `space-y-2` — `:315`.
              padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
              child: PaymentMethodTile(
                method: enabled[i],
                active: enabled[i].code == methodCode,
                onTap: () => setState(() => _picked = enabled[i].code),
              ),
            ),
        ],

        if (widget.insufficient) ...<Widget>[
          const SizedBox(height: 20),
          InsufficientFundsPanel(
            amount: widget.amount,
            onTopUp: widget.onTopUp,
          ),
        ],

        // `charge.error && !insufficient` — `:380`. The suppression is the
        // point: without it a citizen with an empty wallet gets a red line
        // saying so *and* an amber panel offering the fix.
        if (widget.genericError != null && !widget.insufficient) ...<Widget>[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: LucideIcon(
                    name: 'AlertCircle',
                    size: 16,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.genericError!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (instruction != null) ...<Widget>[
          const SizedBox(height: 20),
          PaymentInstructionPanel(
            instruction: instruction,
            chosenKind: chosen?.kind,
            chargedAmount: chargedAmount,
            receiptNo: receiptNo,
            reference: widget.reference,
          ),
        ],

        const SizedBox(height: 20),
        // `:438-469` — the three-way tail. `settled` wins over `instruction`,
        // and both win over the button.
        if (settled)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // lucide `CheckCircle2` is not bundled; Material's outlined
                // check circle is the substitution, per B6a's precedent at
                // `wallet_balance_card.dart:214`. FU-10 files the bundle gap.
                const Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: AppColors.categoryAccentFinance,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'payment.paidReceipt'.tr(
                      context: context,
                      namedArgs: <String, String>{'receipt': receiptNo},
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.categoryAccentFinance,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (instruction != null)
          Text(
            'payment.awaitingBank'.tr(context: context),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          )
        else if (enabled.isNotEmpty)
          // `disabled={charge.pending || !methodCode}` — `:457`.
          _ChargeButton(
            label: widget.pending
                ? 'payment.processing'.tr(context: context)
                : _payLabel(context, lang, language, chosen),
            onPressed: (widget.pending || methodCode.isEmpty)
                ? null
                : () => _submit(methodCode),
          ),
      ],
    );
  }

  /// `Pay ${formatLak(amount, lang)}${chosen ? ` · ${text(chosen.label, lang)}`
  /// : ""}` — `:466-468`, and the Lao arm one line above it.
  ///
  /// The `" · "` is a separator rather than copy, so it stays in Dart; the two
  /// translated arms are `payment.payAmount`, relocated byte-identically per
  /// § 6.13(3) with `${…}` replaced by `{amount}`.
  String _payLabel(
    BuildContext context,
    Lang lang,
    String language,
    PaymentMethod? chosen,
  ) {
    final String base = 'payment.payAmount'.tr(
      context: context,
      namedArgs: <String, String>{'amount': formatLak(widget.amount, language)},
    );
    if (chosen == null) return base;
    return '$base · ${text(chosen.label, lang)}';
  }
}

/// The charge CTA — `:453-468`.
class _ChargeButton extends StatelessWidget {
  const _ChargeButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        // `disabled:opacity-60` — `:455`. Material's default disabled fill is a
        // grey, not a faded brand blue, so the source's treatment is imposed.
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
        disabledForegroundColor: AppColors.white.withValues(alpha: 0.6),
        elevation: 0,
        // `py-3.5` — `:454`.
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      // lucide `Lock` is not bundled — Material's outline padlock, per the same
      // precedent the check circle above cites. FU-10.
      icon: const Icon(Icons.lock_outline, size: 16),
      label: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// The 3-row catalogue skeleton — `:277-289`.
///
/// A local copy rather than `WalletRowSkeleton`: that widget lives under
/// `features/wallet/presentation/`, which `lib/presentation/**` may not import
/// (G-L7, `B6-AC-9`). The geometry differs anyway — this one is three separate
/// cards with a 2-unit gap, the wallet's is one card with dividers.
///
/// **Not animated**, for the reason `wallet_panels.dart:186-191` gives:
/// `animate-pulse` is a CSS keyframe, a Flutter port needs an
/// `AnimationController`, and `B6-AC-26` greps this directory for `Timer` and
/// requires zero.
class _MethodSkeleton extends StatelessWidget {
  const _MethodSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gray100),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        FractionallySizedBox(
                          widthFactor: 1 / 3,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.gray200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FractionallySizedBox(
                          widthFactor: 2 / 3,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// `:291-303` — the catalogue's own error, with a retry.
class _MethodsErrorCard extends StatelessWidget {
  const _MethodsErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        children: <Widget>[
          Text(
            // The server's message, rendered as sent — `:294`.
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.gray700),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const LucideIcon(
              name: 'RefreshCw',
              size: 16,
              color: AppColors.white,
            ),
            label: Text(
              'payment.tryAgain'.tr(context: context),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// `:305-313` — a catalogue that resolved with nothing enabled. No retry, no
/// error styling: the request succeeded, the answer was just empty.
class _CentredNoticeCard extends StatelessWidget {
  const _CentredNoticeCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, color: AppColors.muted),
      ),
    );
  }
}

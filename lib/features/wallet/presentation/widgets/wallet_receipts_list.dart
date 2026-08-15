/// The receipts list — `WalletPage.tsx:466-511`.
///
/// A *receipt* (`/me/transactions`) is not a *ledger entry*
/// (`/me/wallet/entries`). They share a slot behind one toggle and nothing
/// else: different endpoints, different fields, different empty copy, different
/// arrow rules. See `transaction.dart`'s library doc.
///
/// ## The three fallback chains, ported exactly
///
/// * title — `text(tx.service_name, lang) || tx.service_code || tx.kind`
///   (`:486`), three deep, in that order.
/// * subtitle — `[receipt_no, reference_no, text(method_label) || method_code]
///   .filter(Boolean).join(" · ")` (`:489`). `filter(Boolean)` drops empty
///   strings as well as absent values, which is why `nullableStringAt` models
///   `""` as `null` in `wallet_wire.dart`.
/// * date — `formatDay(tx.paid_at ?? tx.date, lang)` (`:506`) — `??`, so an
///   **empty-string** `paid_at` still wins over `date`. `wallet_wire.dart` maps
///   `""` to `null` on both, which is what makes the `??` mean on the wire what
///   it means in JS over an omitted key.
///
/// ## `refunded` is the only inbound status
///
/// `const isIn = tx.status === "refunded"` (`:468`). A refund is money coming
/// **in**: down-left arrow, green wash, green amount, `+` prefix. Every other
/// status — including `failed` — renders as an outgoing receipt. The green
/// check beside the date is a *different* test, `tx.status === "paid"` (`:503`),
/// so a `refunded` row shows the in-arrow and **no** check.
///
/// ## `formatKip`, not `formatLak` (§ 6.5, `B6-AC-22`)
///
/// Two sites in this file: the amount (`:500`) and — via [WalletLedgerList] —
/// the running balance. `₭`, locale-dependent grouping.
library;

import 'package:flutter/material.dart';

import '../../../../i18n/i18n.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/wallet_formatting.dart';
import 'wallet_panels.dart';

class WalletReceiptsList extends StatelessWidget {
  const WalletReceiptsList({super.key, required this.receipts});

  final List<Transaction> receipts;

  @override
  Widget build(BuildContext context) {
    final String language = Localizations.localeOf(context).languageCode;
    final Lang lang = Lang.fromCode(language);

    return WalletCard(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < receipts.length; i++) ...<Widget>[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AppColors.gray100),
            _ReceiptRow(tx: receipts[i], lang: lang, language: language),
          ],
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.tx,
    required this.lang,
    required this.language,
  });

  final Transaction tx;
  final Lang lang;
  final String language;

  /// `text(tx.service_name, lang) || tx.service_code || tx.kind` — `:486`.
  String get _title {
    final String named = text(tx.serviceName, lang);
    if (named.isNotEmpty) return named;
    if (tx.serviceCode.isNotEmpty) return tx.serviceCode;
    return tx.kind;
  }

  /// `[…].filter(Boolean).join(" · ")` — `:489-491`.
  String get _subtitle {
    final String method = text(tx.methodLabel, lang);
    return <String>[
      tx.receiptNo,
      tx.referenceNo ?? '',
      method.isNotEmpty ? method : tx.methodCode,
    ].where((String s) => s.isNotEmpty).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final bool isIn = tx.isRefund;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isIn
                  ? AppColors.categoryTintFinance
                  : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isIn
                // lucide `ArrowDownLeft`, unbundled — see `wallet_panels.dart`.
                ? const Icon(
                    Icons.south_west,
                    size: 20,
                    color: AppColors.categoryAccentFinance,
                  )
                : const LucideIcon(
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
                  _title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray800,
                  ),
                ),
                Text(
                  _subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray400Inline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                // `{isIn ? "+" : ""}{formatKip(tx.amount_lak, lang)}` — `:499`.
                // Note the **empty** string for an outgoing receipt; the ledger
                // uses `"-"` in the same slot. Two different rules, `:499` and
                // `:672`, and they are not a typo in either place.
                '${isIn ? '+' : ''}${formatKip(tx.amountLak, language)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isIn
                      ? AppColors.categoryAccentFinance
                      : AppColors.gray800,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (tx.isPaid) ...<Widget>[
                    // lucide `CheckCircle2`, unbundled.
                    const Icon(
                      Icons.check_circle_outline,
                      size: 12,
                      color: AppColors.categoryAccentFinance,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    formatDay(tx.paidAt ?? tx.date, language),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.gray400Inline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

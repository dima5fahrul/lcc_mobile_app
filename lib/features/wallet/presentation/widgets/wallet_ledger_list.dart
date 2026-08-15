/// The wallet ledger — `WalletPage.tsx:568-712`, the `LedgerList` component.
///
/// ## The first frame is deliberately stale, and it suppresses its own skeleton
///
/// ```
/// const entries = ledgerQuery.data?.data ?? overview?.recent_entries ?? [];
///                                                         — :130
/// loading={ledgerQuery.loading && entries.length === 0}    — :418
/// ```
///
/// Opening the ledger shows the **overview's** last few entries immediately and
/// hides the skeleton while page 1 loads, then swaps them for the real page.
/// `B6-DIV-5` / `B6-AC-27`. The `WalletState` getters `ledgerEntries` and
/// `ledgerSkeleton` compute both halves, so this widget receives them already
/// resolved and cannot get the pair out of step.
///
/// ## The pager reads two numbers, and disables from those two alone
///
/// `page <= 1` and `page >= totalPages` (`:689`, `:699`) — **not** `has_prev` /
/// `has_next`, which the envelope also sends. `paged.dart` explains why both
/// pairs are carried anyway. The pager row is **absent**, not disabled, when
/// `totalPages <= 1` (`:683`), which is the only state the empty test account
/// can reach.
///
/// ## `-`, not `""`
///
/// `{isIn ? "+" : "-"}` (`:672`). The receipts list writes `{isIn ? "+" : ""}`
/// in the visually identical slot (`:499`). Two different rules; both ported.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../i18n/i18n.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../domain/entities/wallet_entry.dart';
import '../../domain/wallet_formatting.dart';
import 'wallet_panels.dart';

class WalletLedgerList extends StatelessWidget {
  const WalletLedgerList({
    super.key,
    required this.entries,
    required this.showSkeleton,
    required this.errorMessage,
    required this.onRetry,
    required this.page,
    required this.totalPages,
    required this.onPage,
  });

  final List<WalletEntry> entries;

  /// `ledgerQuery.loading && entries.length === 0` — already computed by
  /// `WalletState.ledgerSkeleton`.
  final bool showSkeleton;

  final String? errorMessage;
  final VoidCallback onRetry;
  final int page;
  final int totalPages;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    // Branch order is the source's: loading, then error, then empty, then rows
    // (`:591`, `:606`, `:625`, `:646`).
    if (showSkeleton) return const WalletRowSkeleton();

    if (errorMessage != null) {
      return WalletRetryCard(message: errorMessage!, onRetry: onRetry);
    }

    if (entries.isEmpty) {
      return WalletEmptyCard(
        icon: const LucideIcon(
          name: 'Wallet',
          size: 24,
          color: AppColors.gray400Inline,
        ),
        title: 'wallet.noRecentTransactions'.tr(context: context),
        subtitle: 'wallet.emptyLedgerHint'.tr(context: context),
      );
    }

    final String language = Localizations.localeOf(context).languageCode;
    final Lang lang = Lang.fromCode(language);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        WalletCard(
          child: Column(
            children: <Widget>[
              for (int i = 0; i < entries.length; i++) ...<Widget>[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.gray100,
                  ),
                _LedgerRow(entry: entries[i], lang: lang, language: language),
              ],
            ],
          ),
        ),
        // `{totalPages > 1 && …}` — `:683`.
        if (totalPages > 1) ...<Widget>[
          const SizedBox(height: 12),
          WalletCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: <Widget>[
                _PagerButton(
                  label: 'common.back'.tr(context: context),
                  // `onPage(Math.max(1, page - 1))` — `:687`.
                  onTap: page <= 1
                      ? null
                      : () => onPage(page > 1 ? page - 1 : 1),
                ),
                Expanded(
                  child: Text(
                    '$page / $totalPages',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
                _PagerButton(
                  label: 'common.next'.tr(context: context),
                  onTap: page >= totalPages ? null : () => onPage(page + 1),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.entry,
    required this.lang,
    required this.language,
  });

  final WalletEntry entry;
  final Lang lang;
  final String language;

  @override
  Widget build(BuildContext context) {
    final bool isIn = entry.isCredit;

    // `text(e.description, lang) || e.kind` — `:663`.
    final String described = text(entry.description, lang);
    final String title = described.isNotEmpty ? described : entry.kind;

    // `[e.reference_no, e.method_code].filter(Boolean).join(" · ")` — `:666`.
    final String subtitle = <String>[
      entry.referenceNo ?? '',
      entry.methodCode ?? '',
    ].where((String s) => s.isNotEmpty).join(' · ');

    // `formatDay(e.occurred_at ?? e.date, lang)` — `:675`. `occurredAt` is a
    // non-nullable `String` on the entity with `''` for absent, so the `??` is
    // written as an emptiness test rather than a null test; the wire has no
    // third state.
    final String when = formatDay(
      entry.occurredAt.isNotEmpty ? entry.occurredAt : entry.date,
      language,
    );

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
            // lucide `ArrowDownLeft` / `ArrowUpRight`, both unbundled — see
            // `wallet_panels.dart`'s library doc.
            child: Icon(
              isIn ? Icons.south_west : Icons.north_east,
              size: 20,
              color: isIn ? AppColors.categoryAccentFinance : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray800,
                  ),
                ),
                Text(
                  subtitle,
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
                '${isIn ? '+' : '-'}${formatKip(entry.amountLak, language)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isIn
                      ? AppColors.categoryAccentFinance
                      : AppColors.gray800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                // `{formatDay(…)} · {formatKip(e.balance_after_lak, lang)}`
                // — `:675`. Two `formatKip` sites in one row.
                '$when · ${formatKip(entry.balanceAfterLak, language)}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.gray400Inline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `text-xs px-3 py-1.5 rounded-full border border-gray-200 text-gray-600
/// disabled:opacity-40` — `:686-693`.
class _PagerButton extends StatelessWidget {
  const _PagerButton({required this.label, required this.onTap});

  final String label;

  /// `null` renders the disabled state (`disabled:opacity-40`).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray200),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.gray600,
            ),
          ),
        ),
      ),
    );
  }
}

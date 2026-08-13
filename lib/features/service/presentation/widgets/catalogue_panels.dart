/// The catalogue's **error** and **empty** panels — two of the four states
/// § 6.6 makes mandatory.
///
/// `ErrorPanel` is `ServicePage.tsx:255-283`; the two empty panels are the
/// inline blocks at `:433-441` (no categories published) and `:509-529` (no
/// services matched). All three are the same shell — a `p-10` white card, a
/// 56 px round-rect tile with a glyph, a `text-sm font-medium` line, and
/// optionally a hint plus a pill button — so the shell is written once.
///
/// ## Why the error state is not "an empty list"
///
/// B2-AC-16 states it as a rule: *an empty list or dropdown is never an
/// acceptable rendering of a failed fetch.* These are visually different
/// panels (red tile + retry vs grey tile + no retry) carrying different
/// strings, because "nothing matched your search" and "we could not reach the
/// server" are different facts and a citizen who cannot tell them apart will
/// retype their search instead of checking their connection.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import 'catalogue_grid.dart';

/// `ErrorPanel` — message, hint, and a "Retry" pill.
///
/// The retry is not optional and not a nicety: § 6.6 requires
/// **error-with-retry**, and SSD § 12.1 rules that these four states are the
/// *whole* offline story — there is no cache behind them to fall back on, so
/// the button is the only way out of this state.
class CatalogueErrorPanel extends StatelessWidget {
  const CatalogueErrorPanel({
    super.key,
    required this.message,
    required this.hint,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String hint;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      // `bg-red-50` + `AlertCircle` at `#DC2626`.
      tileColor: AppColors.dangerSoft,
      glyph: 'AlertCircle',
      glyphColor: AppColors.danger,
      message: message,
      hint: hint,
      action: _PillButton(
        label: retryLabel,
        onPressed: onRetry,
        // `RefreshCw className="w-3.5 h-3.5"` — 14 px, the only leading glyph
        // any of these pills has.
        leadingGlyph: 'RefreshCw',
      ),
    );
  }
}

/// The two empty states: a neutral grey tile and a `Search` glyph.
///
/// [hint] and [action] are null for the "no categories are published yet"
/// variant, which the source renders as a bare message
/// (`ServicePage.tsx:433-441`), and populated for the "no services matched"
/// one (`:509-529`).
class CatalogueEmptyPanel extends StatelessWidget {
  const CatalogueEmptyPanel({
    super.key,
    required this.message,
    this.hint,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final String? label = actionLabel;
    final VoidCallback? action = onAction;

    return _PanelShell(
      tileColor: AppColors.gray100,
      glyph: 'Search',
      // `text-gray-400` as a CLASS, so it is the accessible override
      // (`#616B7A`), not the stock grey. See `AppColors.gray400Inline`.
      glyphColor: AppColors.gray400,
      message: message,
      hint: hint,
      action: (label != null && action != null)
          ? _PillButton(label: label, onPressed: action)
          : null,
    );
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({
    required this.tileColor,
    required this.glyph,
    required this.glyphColor,
    required this.message,
    this.hint,
    this.action,
  });

  final Color tileColor;
  final String glyph;
  final Color glyphColor;
  final String message;
  final String? hint;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final String? hintText = hint;
    final Widget? actionWidget = action;

    return DecoratedBox(
      decoration: catalogueCardDecoration,
      child: Padding(
        // `p-10`
        padding: const EdgeInsets.all(AppSpacing.gap40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // `w-14 h-14 rounded-2xl … mx-auto mb-3`
            Container(
              width: AppSpacing.tile56,
              height: AppSpacing.tile56,
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
              ),
              // `w-6 h-6` — 24 px.
              child: Center(
                child: LucideIcon(name: glyph, size: 24, color: glyphColor),
              ),
            ),
            const SizedBox(height: AppSpacing.gap12),
            // `text-gray-700 text-sm font-medium`
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.gray700,
                fontSize: AppTypography.size14,
                fontWeight: AppTypography.medium,
              ),
            ),
            if (hintText != null) ...<Widget>[
              // `mt-1`
              const SizedBox(height: AppSpacing.gap4),
              // `text-gray-400 text-xs`
              Text(
                hintText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.gray400,
                  fontSize: AppTypography.size12,
                ),
              ),
            ],
            if (actionWidget != null) ...<Widget>[
              // `mt-4`
              const SizedBox(height: AppSpacing.gap16),
              actionWidget,
            ],
          ],
        ),
      ),
    );
  }
}

/// `text-xs font-medium px-4 py-2 rounded-full`, brand-blue on `#EEF2FF`.
///
/// Both pills in this page — "Retry" and "Browse other categories" — are the
/// same inline style (`ServicePage.tsx:275-277` and `:523-524`), so they are
/// one widget. Only the retry carries a leading glyph.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onPressed,
    this.leadingGlyph,
  });

  final String label;
  final VoidCallback onPressed;
  final String? leadingGlyph;

  @override
  Widget build(BuildContext context) {
    final String? glyph = leadingGlyph;

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gap16,
            vertical: AppSpacing.gap8,
          ),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (glyph != null) ...<Widget>[
                // Addressed directly, NOT through `AppIcons.service`. The
                // scope resolvers exist for **API-supplied** names, where the
                // web's two registries disagree and merging them would render
                // the wrong glyph (§ 6.3.5). `RefreshCw` is a component the
                // page imports by identity — `ServicePage.tsx:67` — and is not
                // in that 54-name table at all, so resolving it through the
                // service scope would fall back to `FileText` and put a
                // document icon on the retry button.
                LucideIcon(name: glyph, size: 14, color: AppColors.primary),
                // `gap-1.5`
                const SizedBox(width: AppSpacing.gap6),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: AppTypography.size12,
                  fontWeight: AppTypography.medium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

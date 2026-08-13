/// The action banner — `HomePage.tsx:393-423` — and its dismiss confirmation.
///
/// An amber notice carrying whatever `/me/home-summary` says needs the citizen
/// next: a title, an optional reference number, a link to the relevant tab, and
/// an `X` that asks before it hides anything.
///
/// ## Why the `X` opens a dialog instead of hiding the banner
///
/// Because the source does (`HomePage.tsx:417`,
/// `onClick={() => setShowDismissConfirm(true)}`), and the confirmation copy
/// says why: *"Your application still requires attention and may be cancelled
/// if not resolved."* A one-tap dismiss on a notice with that consequence is a
/// different product.
///
/// `DialogShell.tsx` is B10's (§ 6.3.4), so the confirmation is Flutter's
/// `showDialog` — same overlay, barrier, focus trap and Escape handling,
/// provided by the framework instead of authored in another batch's directory.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/entities/home_summary.dart';
import 'bilingual_text.dart';

class ActionBanner extends StatelessWidget {
  const ActionBanner({
    super.key,
    required this.action,
    required this.onFollow,
    required this.onDismissConfirmed,
  });

  final HomeNextAction action;

  /// `onTabChange(summary.data?.next_action?.tab ?? "history")` —
  /// `HomePage.tsx:409`. The default lives at the call site, as it does in the
  /// source.
  final ValueChanged<String> onFollow;

  final VoidCallback onDismissConfirmed;

  @override
  Widget build(BuildContext context) {
    // `text(label, lang) || t("actionRequiredTitle")` — `HomePage.tsx:401`.
    // "Older payloads describe the step without a label of their own."
    final String? label = action.label?.forContext(context);
    final String title = (label == null || label.isEmpty)
        ? 'home.actionRequiredTitle'.tr()
        : label;

    return Container(
      // `flex items-start gap-3 p-4 rounded-2xl border border-amber-200
      //  bg-amber-50`
      padding: const EdgeInsets.all(AppSpacing.gap16),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        border: Border.all(color: AppColors.warningOutline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: AppSpacing.tile36,
            height: AppSpacing.tile36,
            decoration: BoxDecoration(
              color: AppColors.warningTint,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: const Center(
              child: LucideIcon(
                name: 'AlertTriangle',
                size: AppSpacing.gap20,
                color: AppColors.warningLink,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.gap12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.warningTitle,
                    fontSize: AppTypography.size14,
                    fontWeight: AppTypography.semiBold,
                    height: AppTypography.lineSnug,
                  ),
                ),
                if (action.referenceNo.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.gap4),
                  Text(
                    action.referenceNo,
                    style: const TextStyle(
                      color: AppColors.warningReference,
                      fontSize: AppTypography.size12,
                      height: AppTypography.lineRelaxed,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.gap8),
                InkWell(
                  onTap: () => onFollow(action.tab),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'home.updateDocument'.tr(),
                        style: const TextStyle(
                          color: AppColors.warningLink,
                          fontSize: AppTypography.size12,
                          fontWeight: AppTypography.semiBold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.gap4),
                      const LucideIcon(
                        name: 'ChevronRight',
                        size: AppSpacing.gap12,
                        color: AppColors.warningLink,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDismiss(context),
            tooltip: 'home.dismissTitle'.tr(),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(
              minWidth: AppSpacing.gap24,
              minHeight: AppSpacing.gap24,
            ),
            icon: LucideIcon(
              name: 'X',
              size: AppSpacing.gap16,
              color: AppColors.warningDismiss,
              semanticsLabel: 'home.dismissTitle'.tr(),
            ),
          ),
        ],
      ),
    );
  }

  /// `HomePage.tsx:794-831`.
  Future<void> _confirmDismiss(BuildContext context) async {
    final bool? dismissed = await showDialog<bool>(
      context: context,
      // `bg-black/40` — `HomePage.tsx:797`.
      barrierColor: AppColors.black.withValues(alpha: 0.4),
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius3xl),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.gap24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: AppSpacing.tile56,
              height: AppSpacing.tile56,
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
              ),
              child: const Center(
                child: LucideIcon(
                  name: 'AlertCircle',
                  size: 28,
                  color: AppColors.dangerGlyph,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.gap12),
            Text(
              'home.dismissTitle'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.gray800,
                fontSize: AppTypography.size16,
                fontWeight: AppTypography.semiBold,
              ),
            ),
            const SizedBox(height: AppSpacing.gap4),
            Text(
              'home.dismissDesc'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.gray500,
                fontSize: AppTypography.size14,
                height: AppTypography.lineRelaxed,
              ),
            ),
            const SizedBox(height: AppSpacing.gap24),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gray600,
                      side: const BorderSide(color: AppColors.gray200),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.gap12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXl),
                      ),
                    ),
                    child: Text('home.keepIt'.tr()),
                  ),
                ),
                const SizedBox(width: AppSpacing.gap12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: FilledButton.styleFrom(
                      // `style={{ backgroundColor: "#DC2626" }}` — an inline
                      // hex, so this is `danger` and not the `red-600` class
                      // value `dangerText`.
                      backgroundColor: AppColors.danger,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.gap12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXl),
                      ),
                    ),
                    child: Text('home.yesDismiss'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (dismissed ?? false) onDismissConfirmed();
  }
}

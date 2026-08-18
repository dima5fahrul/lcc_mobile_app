/// `ToggleRow` — Marriage `:421-454`, Divorce `:424-457`, byte-identical.
///
/// A yes/no condition rendered as a whole-row button with a filled circle on
/// the right. Four conditional colours, all Tier 2 values:
///
/// | | active | inactive |
/// | --- | --- | --- |
/// | row background | `#EEF2FF` | `white` |
/// | row border | `#344EAD` | `#E5E7EB` |
/// | dot fill | `#344EAD` | `transparent` |
/// | dot border | `#344EAD` | `#D1D5DB` |
///
/// It is a **button, not a checkbox**: `onToggle` takes no argument and the
/// caller flips its own boolean (`:1442` `setHasChildren(v => !v)`). Modelling
/// it as a `Switch` or `Checkbox` would introduce a platform control with its
/// own semantics and its own animation.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

class CertificateToggleRow extends StatelessWidget {
  const CertificateToggleRow({
    super.key,
    required this.active,
    required this.onToggle,
    required this.title,
    required this.hint,
  });

  final bool active;
  final VoidCallback onToggle;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: active,
      child: GestureDetector(
        onTap: onToggle,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          // `p-4`
          padding: const EdgeInsets.all(AppSpacing.gap16),
          decoration: BoxDecoration(
            color: active ? AppColors.primarySoft : AppColors.white,
            // `rounded-2xl`
            borderRadius: const BorderRadius.all(
              Radius.circular(AppSpacing.radius2xl),
            ),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.gray200,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // `w-4 h-4 flex-shrink-0 mt-0.5`
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.gap2),
                child: LucideIcon(
                  name: 'Info',
                  size: AppSpacing.gap16,
                  color: AppColors.primary,
                ),
              ),
              // `gap-2.5`
              const SizedBox(width: AppSpacing.gap10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      // `text-sm font-medium text-gray-800`
                      style: const TextStyle(
                        fontSize: AppTypography.size14,
                        fontWeight: AppTypography.medium,
                        color: AppColors.gray800,
                      ),
                    ),
                    // `mt-0.5`
                    const SizedBox(height: AppSpacing.gap2),
                    Text(
                      hint,
                      // `text-xs text-gray-400`
                      style: const TextStyle(
                        fontSize: AppTypography.size12,
                        color: AppColors.gray400Inline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.gap12),
              // `w-5 h-5 rounded-full border-2`
              Container(
                width: AppSpacing.gap20,
                height: AppSpacing.gap20,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.gray300,
                    width: 2,
                  ),
                ),
                child: active
                    ? const Center(
                        child: LucideIcon(
                          name: 'Check',
                          size: AppSpacing.gap12,
                          color: AppColors.white,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

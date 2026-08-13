/// The help centre's search field — the white pill inside the gradient band.
///
/// `HelpCenterPage.tsx:179-204`: `bg-white rounded-2xl p-1.5 shadow-lg`, a
/// leading magnifier, and a clear `X` that appears only while `searching`.
///
/// ## Stateful, and why
///
/// The BLoC owns the query, but the `TextEditingController` has to live
/// somewhere that survives a rebuild — a controller created in `build` loses
/// the caret on every keystroke. So the widget owns the controller and mirrors
/// the BLoC's value into it in `didUpdateWidget`, which is what makes the
/// programmatic clear (`HelpSearchCleared`) empty the visible field.
///
/// The mirror is guarded on inequality: assigning `controller.text` when it
/// already matches would reset the selection to offset 0 mid-typing.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

class HelpSearchField extends StatefulWidget {
  const HelpSearchField({
    super.key,
    required this.query,
    required this.label,
    required this.placeholder,
    required this.clearLabel,
    required this.onChanged,
    required this.onCleared,
  });

  final String query;

  /// `aria-label` — `t("searchLabel")`.
  final String label;

  /// `placeholder` — `t("searchPlaceholder")`.
  final String placeholder;

  /// The clear control's `aria-label` — `t("clearSearch")`.
  final String clearLabel;

  final ValueChanged<String> onChanged;
  final VoidCallback onCleared;

  @override
  State<HelpSearchField> createState() => _HelpSearchFieldState();
}

class _HelpSearchFieldState extends State<HelpSearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.query);

  @override
  void didUpdateWidget(HelpSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.text = widget.query;
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // `searching` — `:129`, `query.trim().length > 0`.
    final bool searching = widget.query.trim().isNotEmpty;

    return Container(
      // `bg-white rounded-2xl p-1.5 shadow-lg`
      padding: const EdgeInsets.all(AppSpacing.gap6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.cardShadowMedium,
            blurRadius: AppSpacing.gap16,
            offset: Offset(0, AppSpacing.gap4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: AppSpacing.gap12),
          // `aria-hidden` — decorative.
          const LucideIcon(
            name: 'Search',
            size: AppSpacing.gap20,
            color: AppColors.gray400Inline,
          ),
          const SizedBox(width: AppSpacing.gap8),
          Expanded(
            child: Semantics(
              textField: true,
              label: widget.label,
              child: TextField(
                controller: _controller,
                onChanged: widget.onChanged,
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  color: AppColors.gray800,
                  fontSize: AppTypography.size14,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.gap10,
                  ),
                  hintText: widget.placeholder,
                  hintStyle: const TextStyle(
                    color: AppColors.gray400Inline,
                    fontSize: AppTypography.size14,
                  ),
                ),
              ),
            ),
          ),
          if (searching)
            Semantics(
              button: true,
              label: widget.clearLabel,
              child: InkWell(
                onTap: widget.onCleared,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: const SizedBox(
                  // `w-8 h-8 mr-1`
                  width: AppSpacing.gap32,
                  height: AppSpacing.gap32,
                  child: Center(
                    child: LucideIcon(
                      name: 'X',
                      size: AppSpacing.gap16,
                      color: AppColors.gray400Inline,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: AppSpacing.gap4),
        ],
      ),
    );
  }
}

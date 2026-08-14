/// The hero's search field — `HomePage.tsx:292-310`.
///
/// One tap-anywhere field on a white rounded card: a `Search` glyph, the input,
/// and a clear button that appears only when there is something to clear.
///
/// ## Why it owns a `TextEditingController` instead of reading state
///
/// A `TextField` whose `controller.text` is rewritten from BLoC state on every
/// rebuild fights the citizen's cursor: setting `text` moves the selection to
/// the end, so typing in the middle of a query jumps. The controller is
/// therefore the field's own, the BLoC is told about each change, and state
/// flows *back* into the field only for the one transition that needs it —
/// [query] going empty when the clear button or a state reset fires.
///
/// That is also the seam `text_dump.dart` reads: a `TextField` contributes one
/// node, its value if it has one and its placeholder otherwise, and its subtree
/// is skipped. Keeping the real text in the controller is what makes the Tier 1
/// dump report what a citizen sees.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

class HomeSearchField extends StatefulWidget {
  const HomeSearchField({
    super.key,
    required this.query,
    required this.onChanged,
    required this.onCleared,
  });

  /// The BLoC's `searchQuery`. Used only to re-sync the controller when it is
  /// cleared from outside the field.
  final String query;

  final ValueChanged<String> onChanged;
  final VoidCallback onCleared;

  @override
  State<HomeSearchField> createState() => _HomeSearchFieldState();
}

class _HomeSearchFieldState extends State<HomeSearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.query);

  @override
  void didUpdateWidget(HomeSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only the outside-in direction, and only when the two actually disagree.
    // An unconditional assignment would rewrite the field on every rebuild and
    // send the cursor to the end mid-word.
    if (widget.query != _controller.text) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasQuery = _controller.text.isNotEmpty;

    return Container(
      // `bg-white rounded-2xl px-4 py-3.5 shadow-lg`
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gap16,
        vertical: AppSpacing.gap6,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.cardShadowMedium,
            blurRadius: 15,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          const LucideIcon(
            name: 'Search',
            size: AppSpacing.gap16,
            color: AppColors.gray400,
          ),
          const SizedBox(width: AppSpacing.gap10),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (String value) {
                // `setState` for the clear button's visibility only; the query
                // itself lives in the BLoC.
                setState(() {});
                widget.onChanged(value);
              },
              style: const TextStyle(
                color: AppColors.gray700,
                fontSize: AppTypography.size14,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.gap8,
                ),
                hintText: 'home.searchPlaceholder'.tr(context: context),
                hintStyle: const TextStyle(
                  color: AppColors.gray400,
                  fontSize: AppTypography.size14,
                ),
              ),
            ),
          ),
          if (hasQuery)
            IconButton(
              onPressed: () {
                _controller.clear();
                setState(() {});
                widget.onCleared();
              },
              tooltip: 'home.searchClear'.tr(context: context),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(
                minWidth: AppSpacing.gap24,
                minHeight: AppSpacing.gap24,
              ),
              icon: LucideIcon(
                name: 'X',
                size: AppSpacing.gap16,
                color: AppColors.gray400,
                semanticsLabel: 'home.searchClear'.tr(context: context),
              ),
            ),
        ],
      ),
    );
  }
}

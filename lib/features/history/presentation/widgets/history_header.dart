/// The page header — `HistoryPage.tsx:135-159`.
///
/// A 135° three-stop gradient, the title and subtitle, and the search box.
/// `linear-gradient(135deg, #344EAD 0%, #2A3F99 60%, #1E3070 100%)` — the three
/// stops are `AppColors.primary` / `.headerGradientMid` / `.headerGradientEnd`,
/// imported rather than restated so this header cannot drift from every other
/// page's (see `history_palette.dart`).
///
/// **The 60 % middle stop is load-bearing.** A two-stop gradient, or three
/// evenly spaced ones, renders a visibly different band and is exactly what
/// Tier 2 exists to catch.
///
/// The search field is uncontrolled here: it owns a [TextEditingController] so
/// typing is not a round trip through the BLoC, and reports every keystroke
/// upward. The 350 ms debounce lives in `HistoryBloc`, not in this widget — a
/// debounce in the field would be invisible to `bloc_test` and could not be
/// asserted by counting requests (`B7-AC-19`).
library;

import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import 'history_palette.dart';

class HistoryHeader extends StatefulWidget {
  const HistoryHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.searchPlaceholder,
    required this.onSearchChanged,
  });

  final String title;
  final String subtitle;
  final String searchPlaceholder;
  final ValueChanged<String> onSearchChanged;

  @override
  State<HistoryHeader> createState() => _HistoryHeaderState();
}

class _HistoryHeaderState extends State<HistoryHeader> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gap16,
        AppSpacing.gap24,
        AppSpacing.gap16,
        AppSpacing.gap32,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          // `135deg` in CSS is top-left → bottom-right.
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.primary,
            AppColors.headerGradientMid,
            AppColors.headerGradientEnd,
          ],
          stops: <double>[0, kHistoryHeaderMidStop, 1],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: AppTypography.size20,
              fontWeight: AppTypography.semiBold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.gap4),
          Text(
            widget.subtitle,
            // `text-white/70`
            style: TextStyle(
              fontSize: AppTypography.size14,
              color: AppColors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.gap20),
          // `mt-5 bg-white rounded-xl px-4 py-3 shadow-md` (`:150`).
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gap16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: AppColors.cardShadowMedium,
                  blurRadius: AppSpacing.gap6,
                  offset: Offset(0, AppSpacing.gap4),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.search,
                  size: AppSpacing.gap16,
                  color: AppColors.gray400Inline,
                ),
                const SizedBox(width: AppSpacing.gap8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: widget.onSearchChanged,
                    style: const TextStyle(
                      fontSize: AppTypography.size14,
                      color: AppColors.gray700,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: widget.searchPlaceholder,
                      hintStyle: const TextStyle(
                        fontSize: AppTypography.size14,
                        color: AppColors.gray400Inline,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.gap12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

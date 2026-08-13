/// "Frequently Asked Questions" — `HomePage.tsx:738-785`.
///
/// Five questions from `/help/faqs`, one open at a time, the **first open on
/// arrival** (`useState<number | null>(0)`). Tapping the open one closes it.
///
/// ## The open index lives in the BLoC, not here
///
/// Unlike the UIN toggle or a hover, this is page state Tier 1 compares: the
/// first question's *answer* is on screen when Home loads, so it is part of
/// what the page presents and a widget-local `setState` would put it outside
/// the state a test can set up. See `home_bloc.dart`'s note on which `useState`
/// crossed and which did not.
///
/// ## Why the accordion is hand-rolled and not `ExpansionTile`
///
/// `ExpansionTile` owns its own expanded flag and animates a `trailing` icon it
/// also owns; driving it from outside means fighting it with a `key` per
/// rebuild, and its default chrome (dividers, tile padding, a rotating Material
/// chevron) is not what the source draws. Two `Text`s and a rotated
/// [LucideIcon] in a `Column` is both shorter and exactly the port.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/entities/home_faq_item.dart';
import 'bilingual_text.dart';

class FaqAccordion extends StatelessWidget {
  const FaqAccordion({
    super.key,
    required this.items,
    required this.openIndex,
    required this.onToggle,
  });

  final List<HomeFaqItem> items;

  /// Null means all closed.
  final int? openIndex;

  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final String languageCode = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < items.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.gap12),
          _row(items[i], i, i == openIndex, languageCode),
        ],
      ],
    );
  }

  Widget _row(HomeFaqItem item, int index, bool open, String languageCode) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            InkWell(
              onTap: () => onToggle(index),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.gap16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.question.forLanguage(languageCode),
                        style: const TextStyle(
                          color: AppColors.gray800,
                          fontSize: AppTypography.size16,
                          fontWeight: AppTypography.semiBold,
                          height: AppTypography.lineSnug,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.gap12),
                    // `transition-transform duration-200 ${open ?
                    // "rotate-180" : ""}` — a half turn, animated.
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const LucideIcon(
                        name: 'ChevronDown',
                        size: AppSpacing.gap20,
                        color: AppColors.gray400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (open)
              Padding(
                // `px-4 pb-4 -mt-1`
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gap16,
                  0,
                  AppSpacing.gap16,
                  AppSpacing.gap16,
                ),
                child: Text(
                  item.answer.forLanguage(languageCode),
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: AppTypography.size14,
                    height: AppTypography.lineRelaxed,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

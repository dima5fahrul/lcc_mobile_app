/// One question in the accordion: the header button, and — when open — the
/// answer, the optional deep link, and the helpful vote.
///
/// `HelpCenterPage.tsx:277-362`.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/entities/help_entities.dart';
import 'bilingual_text.dart';

/// `pl-15` — the 60 CSS px left inset that lines the answer up under the
/// question text rather than under its icon.
const double kFaqAnswerInset = AppSpacing.gap20 * 3;

class FaqCard extends StatelessWidget {
  const FaqCard({
    super.key,
    required this.item,
    required this.open,
    required this.swatch,
    required this.iconName,
    required this.showPopular,
    required this.popularLabel,
    required this.relatedLabel,
    required this.relatedTab,
    required this.helpfulPrompt,
    required this.thanksLabel,
    required this.yesLabel,
    required this.noLabel,
    required this.vote,
    required this.onToggle,
    required this.onVote,
    required this.onRelated,
  });

  final FaqItem item;
  final bool open;

  /// `swatch(catMeta(a.category).index)` — `AppColors.helpSwatch`.
  final ({Color color, Color background}) swatch;

  /// Already resolved through `AppIcons.help`.
  final String iconName;

  /// `a.helpful >= 5 && !searching` — `:302`.
  final bool showPopular;
  final String popularLabel;

  final String relatedLabel;

  /// `CATEGORY_TAB[a.category]` — null when the topic names no app tab.
  final String? relatedTab;

  final String helpfulPrompt;
  final String thanksLabel;
  final String yesLabel;
  final String noLabel;

  /// The vote cast this visit, or null for "not voted".
  final bool? vote;

  final VoidCallback onToggle;
  final ValueChanged<bool> onVote;
  final ValueChanged<String> onRelated;

  @override
  Widget build(BuildContext context) {
    return Container(
      // `bg-white rounded-2xl border border-gray-100 overflow-hidden`
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        border: Border.all(color: AppColors.gray100),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            button: true,
            // `aria-expanded={isOpen}` — `:288`.
            expanded: open,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                // `p-4 text-left`
                padding: const EdgeInsets.all(AppSpacing.gap16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // `w-8 h-8 rounded-lg` on the swatch background
                    Container(
                      width: AppSpacing.gap32,
                      height: AppSpacing.gap32,
                      margin: const EdgeInsets.only(top: AppSpacing.gap2),
                      decoration: BoxDecoration(
                        color: swatch.background,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      child: Center(
                        child: LucideIcon(
                          name: iconName,
                          size: AppSpacing.gap16,
                          color: swatch.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.gap12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.question.forContext(context),
                            style: const TextStyle(
                              color: AppColors.gray800,
                              fontSize: AppTypography.size16,
                              fontWeight: AppTypography.semiBold,
                              height: AppTypography.lineSnug,
                            ),
                          ),
                          if (showPopular) ...<Widget>[
                            const SizedBox(height: AppSpacing.gap4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.gap8,
                                vertical: AppSpacing.gap2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull,
                                ),
                              ),
                              child: Text(
                                popularLabel,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: AppTypography.size11,
                                  fontWeight: AppTypography.semiBold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.gap12),
                    // `transition-transform … rotate-180` when open.
                    // `aria-hidden`, so no semantics label.
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const LucideIcon(
                        name: 'ChevronDown',
                        size: AppSpacing.gap20,
                        color: AppColors.gray400Inline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (open)
            Padding(
              // `px-4 pb-4 pl-15`
              padding: const EdgeInsets.fromLTRB(
                kFaqAnswerInset,
                0,
                AppSpacing.gap16,
                AppSpacing.gap16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.answer.forContext(context),
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: AppTypography.size14,
                      height: AppTypography.lineRelaxed,
                    ),
                  ),
                  if (relatedTab != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.gap12),
                    Semantics(
                      button: true,
                      child: InkWell(
                        onTap: () => onRelated(relatedTab!),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.gap4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                relatedLabel,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: AppTypography.size14,
                                  fontWeight: AppTypography.semiBold,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.gap4),
                              const LucideIcon(
                                name: 'ChevronRight',
                                size: AppSpacing.gap16,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.gap16),
                  _voteRow(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// `:331-357` — the prompt and two thumbs, replaced by the thanks line once a
  /// vote has been cast. **Not** reversible: the source has no un-vote.
  Widget _voteRow() {
    if (vote != null) {
      return Text(
        thanksLabel,
        style: const TextStyle(
          color: AppColors.success,
          fontSize: AppTypography.size12,
          fontWeight: AppTypography.medium,
        ),
      );
    }

    return Row(
      children: <Widget>[
        Flexible(
          child: Text(
            helpfulPrompt,
            style: const TextStyle(
              color: AppColors.gray400Inline,
              fontSize: AppTypography.size12,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.gap8),
        _ThumbButton(
          icon: 'ThumbsUp',
          label: yesLabel,
          onTap: () => onVote(true),
        ),
        const SizedBox(width: AppSpacing.gap8),
        _ThumbButton(
          icon: 'ThumbsDown',
          label: noLabel,
          onTap: () => onVote(false),
        ),
      ],
    );
  }
}

/// `w-8 h-8 rounded-lg border border-gray-200` — `:337-350`.
class _ThumbButton extends StatelessWidget {
  const _ThumbButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          width: AppSpacing.gap32,
          height: AppSpacing.gap32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Center(
            child: LucideIcon(
              name: icon,
              size: AppSpacing.gap16,
              color: AppColors.gray500,
            ),
          ),
        ),
      ),
    );
  }
}

/// One step-by-step guide in the second accordion.
///
/// `HelpCenterPage.tsx:411-458`. Structurally the FAQ card with three
/// differences the source insists on:
///
/// 1. the glyph is always `BookOpen` on `#EEF2FF` — guides carry no category,
///    so there is no swatch to cycle;
/// 2. the body arrives from a **second** request, so an expanded guide shows
///    three skeleton bars until `guide.data?.slug === g.slug`
///    (`:442`, `:448-452`);
/// 3. that body renders `whitespace-pre-line` (`:444`) — newlines in the wire
///    text are line breaks, which is how the numbered steps read as steps.
///    Flutter's `Text` already preserves `\n`, so this is satisfied by not
///    collapsing it.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../session/domain/entities/bilingual.dart';
import '../../domain/entities/help_entities.dart';
import 'bilingual_text.dart';
import 'faq_card.dart' show kFaqAnswerInset;
import 'help_panels.dart';

class GuideCard extends StatelessWidget {
  const GuideCard({
    super.key,
    required this.guide,
    required this.open,
    required this.body,
    required this.bodyFailed,
    required this.errorMessage,
    required this.retryLabel,
    required this.onToggle,
    required this.onRetry,
  });

  final HelpArticle guide;
  final bool open;

  /// The fetched body for **this** guide, or null while it is in flight.
  final HelpArticle? body;

  final bool bodyFailed;
  final String errorMessage;
  final String retryLabel;

  final VoidCallback onToggle;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            expanded: open,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.gap16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: AppSpacing.gap32,
                      height: AppSpacing.gap32,
                      margin: const EdgeInsets.only(top: AppSpacing.gap2),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      child: const Center(
                        child: LucideIcon(
                          name: 'BookOpen',
                          size: AppSpacing.gap16,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.gap12),
                    Expanded(
                      child: Text(
                        guide.title.forContext(context),
                        style: const TextStyle(
                          color: AppColors.gray800,
                          fontSize: AppTypography.size16,
                          fontWeight: AppTypography.semiBold,
                          height: AppTypography.lineSnug,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.gap12),
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
              padding: const EdgeInsets.fromLTRB(
                kFaqAnswerInset,
                0,
                AppSpacing.gap16,
                AppSpacing.gap16,
              ),
              child: _body(context),
            ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (bodyFailed) {
      return HelpErrorBlock(
        message: errorMessage,
        retryLabel: retryLabel,
        onRetry: onRetry,
        verticalPadding: AppSpacing.gap8,
      );
    }

    final Bilingual? text = body?.body;
    if (body != null && body!.slug == guide.slug && text != null) {
      return Text(
        text.forContext(context),
        style: const TextStyle(
          color: AppColors.gray500,
          fontSize: AppTypography.size14,
          height: AppTypography.lineRelaxed,
        ),
      );
    }

    // `[0,1,2].map(...)` — three bars while the body is in flight (`:448`).
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        HelpSkeleton(height: AppSpacing.gap12),
        SizedBox(height: AppSpacing.gap8),
        HelpSkeleton(height: AppSpacing.gap12),
        SizedBox(height: AppSpacing.gap8),
        HelpSkeleton(height: AppSpacing.gap12),
      ],
    );
  }
}

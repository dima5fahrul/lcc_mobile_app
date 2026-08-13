/// The topic filter row — "All topics" plus one chip per `/help/categories`
/// row, each carrying its category's icon.
///
/// `HelpCenterPage.tsx:210-249`. `flex flex-wrap gap-2 justify-center`.
///
/// Two differences from news' chip row, both the source's:
/// 1. every chip has a leading icon, resolved through **`AppIcons.help`** (the
///    12-name scope — see `app_icons.dart` for why the two registries are not
///    merged);
/// 2. the active colour is always the brand, never the category's — help
///    categories carry an `icon`, not a `color`, and the swatch appears only on
///    the *inactive* glyph (`swatch(i).color`, `:244`).
library;

import 'package:flutter/material.dart';

import '../../../../presentation/icons/app_icons.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/entities/help_entities.dart';
import '../../domain/usecases/help_usecases.dart';
import 'bilingual_text.dart';

class HelpTopicChips extends StatelessWidget {
  const HelpTopicChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.allLabel,
    required this.onPick,
  });

  final List<FaqCategory> categories;
  final String selected;
  final String allLabel;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.gap8,
      runSpacing: AppSpacing.gap8,
      alignment: WrapAlignment.center,
      children: <Widget>[
        _Chip(
          label: allLabel,
          active: selected == kHelpAllTopics,
          onTap: () => onPick(kHelpAllTopics),
        ),
        for (int i = 0; i < categories.length; i++)
          _Chip(
            label: categories[i].name.forContext(context),
            active: selected == categories[i].code,
            icon: AppIcons.help(categories[i].icon),
            // `swatch(i)` — position in the list, not the code.
            iconColor: AppColors.helpSwatch(i).color,
            onTap: () => onPick(categories[i].code),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
    this.iconColor,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final String? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      // `aria-pressed={active}` — `:216`, `:231`.
      selected: active,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gap16,
            vertical: AppSpacing.gap8,
          ),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.gray200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                LucideIcon(
                  name: icon!,
                  size: AppSpacing.gap16,
                  // `style={{ color: active ? "white" : swatch(i).color }}`
                  color: active ? AppColors.white : iconColor,
                ),
                const SizedBox(width: AppSpacing.gap8),
              ],
              // `Flexible`, not a bare `Text`. B2-AC-15: the Lao render is
              // taller than the English one and must neither clip nor
              // overflow — and it does overflow without this. `ບໍລິການ ແລະ
              // ເອກະສານ` beside its icon is 338 CSS px wide, 14 px past the
              // 324 px a 390 px viewport leaves for a chip, and an unflexible
              // `Text` inside a `mainAxisSize.min` `Row` takes its intrinsic
              // width and reports a RenderFlex overflow. The web wraps inside
              // the pill (`flex-wrap` on the row, no `whitespace-nowrap` on the
              // chip), so wrapping is the port and not a workaround.
              //
              // Caught by the Lao half of `tier1_help_test.dart`, which is what
              // § 6.5.6's "every comparison pairs against the locale-matching
              // artefact" buys.
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: active ? AppColors.white : AppColors.gray600,
                    fontSize: AppTypography.size14,
                    fontWeight: AppTypography.medium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

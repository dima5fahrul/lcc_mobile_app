/// The catalogue's gradient header: an optional back link, a title, a subtitle
/// and the search field.
///
/// Port of `ServicePage.tsx:359-412`.
///
/// ## The title is an `h1`
///
/// `theme.css:152-156` gives every `h1` `font-size: var(--text-2xl)` (24 px),
/// `font-weight: var(--font-weight-medium)` (500) and `line-height: 1.5`, and
/// `ServicePage.tsx:377` applies only `text-white` on top — no size utility —
/// so the base rule is what renders. That is why the style below is 24/500/1.5
/// and not `titleLarge`: `AppTypography` deliberately does not override
/// Material's global `TextTheme` (see its own doc), so a Material text style
/// here would silently be Material's scale rather than Tailwind's.
///
/// It is also marked `Semantics(header: true)`, which is the closest Flutter
/// has to an `<h1>`. The Tier 1 oracle records role and heading level per node,
/// and a text dump alone cannot tell a heading from a paragraph.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

class CatalogueHeader extends StatelessWidget {
  const CatalogueHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClear,
    required this.showBack,
    required this.onBack,
  });

  /// The drilled-into category's name, or `service.allServices`.
  final String title;

  /// The category's blurb, or `service.subtitle`.
  final String subtitle;

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;

  /// True while a category is active — `{activeCategory && (…)}`.
  final bool showBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        // `linear-gradient(135deg, #344EAD 0%, #2A3F99 60%, #1E3070 100%)`.
        // 135° in CSS is the topLeft → bottomRight diagonal exactly, so no
        // angle arithmetic is needed (unlike `GlassIcon`'s 145°).
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.primary,
            AppColors.headerGradientMid,
            AppColors.headerGradientEnd,
          ],
          stops: <double>[0.0, 0.6, 1.0],
        ),
      ),
      child: Padding(
        // `px-4 pt-6 pb-8`
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gap16,
          AppSpacing.gap24,
          AppSpacing.gap16,
          AppSpacing.gap32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (showBack) ...<Widget>[
              _BackLink(onTap: onBack),
              // `mb-3`
              const SizedBox(height: AppSpacing.gap12),
            ],
            Semantics(
              header: true,
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: AppTypography.size24,
                  fontWeight: AppTypography.medium,
                  height: AppTypography.lineBaseElement,
                ),
              ),
            ),
            // `mt-1`
            const SizedBox(height: AppSpacing.gap4),
            // `text-white/70 text-sm`
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.7),
                fontSize: AppTypography.size14,
              ),
            ),
            // `mt-5`
            const SizedBox(height: AppSpacing.gap20),
            _SearchField(
              controller: searchController,
              onChanged: onSearchChanged,
              onClear: onClear,
            ),
          ],
        ),
      ),
    );
  }
}

/// `<ChevronLeft/> {t("allCategories")}` at `text-white/80 text-sm`.
class _BackLink extends StatelessWidget {
  const _BackLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = AppColors.white.withValues(alpha: 0.8);

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // `w-4 h-4`
            LucideIcon(name: 'ChevronLeft', size: 16, color: color),
            // `gap-1`
            const SizedBox(width: AppSpacing.gap4),
            Text(
              'service.allCategories'.tr(),
              style: TextStyle(color: color, fontSize: AppTypography.size14),
            ),
          ],
        ),
      ),
    );
  }
}

/// `bg-white rounded-xl px-4 py-3 shadow-md` holding a glyph, the input and a
/// "Clear" affordance that appears only once something is typed.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gap16,
        vertical: AppSpacing.gap12,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: const <BoxShadow>[
          // Tailwind `shadow-md`: `0 4px 6px -1px rgb(0 0 0 / 0.1)`.
          BoxShadow(
            color: AppColors.cardShadowMedium,
            offset: Offset(0, 4),
            blurRadius: 6,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          // `w-4 h-4 text-gray-400 flex-shrink-0`
          const LucideIcon(name: 'Search', size: 16, color: AppColors.gray400),
          // `gap-2`
          const SizedBox(width: AppSpacing.gap8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              // `text-gray-700 text-sm`
              style: const TextStyle(
                color: AppColors.gray700,
                fontSize: AppTypography.size14,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                // `outline-none` + `bg-transparent`: the source's input has no
                // chrome of its own; the white pill around it IS the field.
                contentPadding: EdgeInsets.zero,
                hintText: 'service.searchPlaceholder'.tr(),
                // `placeholder:text-gray-400`
                hintStyle: const TextStyle(
                  color: AppColors.gray400,
                  fontSize: AppTypography.size14,
                ),
              ),
            ),
          ),
          // `{searchQuery && (<button>{t("clear")}</button>)}` — keyed on the
          // RAW value, not the trimmed one, so a field holding only spaces
          // still offers a way out.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (BuildContext context, TextEditingValue value, Widget? _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return Semantics(
                button: true,
                child: InkWell(
                  onTap: onClear,
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.gap8),
                    // `text-xs text-gray-400`
                    child: Text(
                      'service.clear'.tr(),
                      style: const TextStyle(
                        color: AppColors.gray400,
                        fontSize: AppTypography.size12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

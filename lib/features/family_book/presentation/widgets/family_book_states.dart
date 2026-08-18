/// The four **bookless** states' bodies — loading (`:278-291`), signed out
/// (`:296-301`), error (`:306-322`) and empty (`:327-335`).
///
/// These four are the ones `specs.md` § 6.4 rules Tier-1-gated, because every
/// string in them comes from the pinned source: `familyBook.title` /
/// `.subtitle` from the namespace and the rest from the component's own `COPY`
/// table. The error card's **middle line is the exception** — `{error.message}`
/// at `:311` is the backend's sentence — and the oracle marks it
/// `role: "server-text"`, compared for presence and position and never for
/// content (`F4-AC-62`).
///
/// ## Three glyphs on this page are not bundled, and that is a recorded gap
///
/// `BookX` (`:298`, `:329`), `RotateCcw` (`:318`) and `Crown` (`:462`) are none
/// of the 89 lucide SVGs in `assets/icons/lucide/`. Regenerating that set means
/// `tool/generate_lucide_svgs.mjs`, `assets/**` and
/// `lib/presentation/icons/lucide_registry.g.dart` — and `specs.md` § 4.1 puts
/// `lib/presentation/icons/**` outside F4's scope, so F4 cannot add them.
///
/// They are written with the **source's own component names** anyway.
/// `AppIcons.assetFor` falls back to `FileText` for an unbundled name
/// (`app_icons.dart:110-111`, and `lucide_icon.dart`'s own doc says the
/// fallback is safe rather than a crash), so each renders a document glyph
/// today — visible, wrong, and self-healing the moment the assets land, with no
/// edit to this file.
///
/// The alternative — substituting a bundled lookalike such as `RefreshCw` for
/// `RotateCcw` — was rejected: it would hide the gap behind a glyph the source
/// does not name, and the point of a fidelity instrument is that the gap shows
/// up in the Tier 3 review. Recorded as **F4-DIV-2/3/4** in `qa-report.md` and
/// escalated in `blocked.md`, because slot 47's baseline carries `BookX` and a
/// document glyph in its place is a likely Tier 3 MAJOR that F4 cannot resolve
/// in scope.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/family_book_copy.dart';

/// `bg-white rounded-2xl border border-gray-100 shadow-sm` — the shell all
/// four of these states' cards share (`:284`, `:297`, `:307`, `:328`).
class FamilyBookCard extends StatelessWidget {
  const FamilyBookCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.gap24),
  });

  final Widget child;

  /// `p-6` for the three message cards, `p-4` for the loading skeletons.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
          border: Border.all(color: AppColors.gray100),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: AppColors.cardShadow, blurRadius: 2),
          ],
        ),
        child: child,
      );
}

/// `:279-282` — the spinner line above the skeletons.
class FamilyBookLoadingLine extends StatelessWidget {
  const FamilyBookLoadingLine({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        // `py-6`
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.gap24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(
              width: AppSpacing.gap16,
              height: AppSpacing.gap16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.gray400Inline),
              ),
            ),
            // `gap-2`
            const SizedBox(width: AppSpacing.gap8),
            Flexible(
              child: Text(
                '$kFamilyBookPageNamespace.loading'.tr(context: context),
                // `text-sm text-gray-400`
                style: const TextStyle(
                  fontSize: AppTypography.size14,
                  color: AppColors.gray400Inline,
                ),
              ),
            ),
          ],
        ),
      );
}

/// `:283-289` — one of the three skeleton cards. Three bars, `h-3`, at
/// `w-24` / `w-full` / `w-2/3`, `space-y-3` apart. No text: a text oracle sees
/// nothing here, which is why the loading view's node list is three long.
class FamilyBookSkeletonCard extends StatelessWidget {
  const FamilyBookSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) => FamilyBookCard(
        padding: const EdgeInsets.all(AppSpacing.gap16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _bar(const BoxConstraints.tightFor(width: 96)),
            const SizedBox(height: AppSpacing.gap12),
            _bar(const BoxConstraints.expand(height: 12)),
            const SizedBox(height: AppSpacing.gap12),
            FractionallySizedBox(
              widthFactor: 2 / 3,
              alignment: Alignment.centerLeft,
              child: _bar(const BoxConstraints.expand(height: 12)),
            ),
          ],
        ),
      );

  Widget _bar(BoxConstraints constraints) => ConstrainedBox(
        constraints: constraints,
        child: Container(
          // `h-3 rounded-full bg-gray-100`
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
        ),
      );
}

/// `:296-301` — the signed-out card. One glyph, one sentence, centred.
class FamilyBookSignedOutCard extends StatelessWidget {
  const FamilyBookSignedOutCard({super.key});

  @override
  Widget build(BuildContext context) => FamilyBookCard(
        child: Column(
          children: <Widget>[
            // NOT BUNDLED — renders `FileText`. See the library doc, F4-DIV-2.
            const LucideIcon(
              name: 'BookX',
              size: AppSpacing.gap32,
              color: AppColors.gray300,
            ),
            // `gap-3`
            const SizedBox(height: AppSpacing.gap12),
            Text(
              '$kFamilyBookPageNamespace.signedOut'.tr(context: context),
              textAlign: TextAlign.center,
              // `text-sm text-gray-500 leading-relaxed`
              style: const TextStyle(
                fontSize: AppTypography.size14,
                height: AppTypography.lineRelaxed,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      );
}

/// `:306-322` — the error card, **with its retry inside the card** rather than
/// in the bottom CTA slot (`:313-320`).
///
/// The middle line is the backend's own sentence (`:311`). It is rendered
/// verbatim rather than replaced with fixed bilingual copy — a deliberate
/// divergence from this tree's standing disposition, argued in
/// `family_book_repository_impl.dart`'s library doc, and the reason the Tier 1
/// oracle declares that node `role: "server-text"`.
class FamilyBookErrorCard extends StatelessWidget {
  const FamilyBookErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  /// `error.message` — never a hardcoded sentence (`F4-AC-25`).
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => FamilyBookCard(
        child: Column(
          children: <Widget>[
            const LucideIcon(
              name: 'AlertCircle',
              size: AppSpacing.gap32,
              color: AppColors.warningStrong,
            ),
            // `gap-4`
            const SizedBox(height: AppSpacing.gap16),
            Text(
              '$kFamilyBookPageNamespace.errorTitle'.tr(context: context),
              textAlign: TextAlign.center,
              // `text-sm font-semibold text-gray-800`
              style: const TextStyle(
                fontSize: AppTypography.size14,
                fontWeight: AppTypography.semiBold,
                color: AppColors.gray800,
              ),
            ),
            // `mt-1`
            const SizedBox(height: AppSpacing.gap4),
            Text(
              message,
              textAlign: TextAlign.center,
              // `text-xs text-gray-400 leading-relaxed`
              style: const TextStyle(
                fontSize: AppTypography.size12,
                height: AppTypography.lineRelaxed,
                color: AppColors.gray400Inline,
              ),
            ),
            const SizedBox(height: AppSpacing.gap16),
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onRetry,
                child: Container(
                  // `px-5 py-3 rounded-2xl shadow-md`
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gap20,
                    vertical: AppSpacing.gap12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radius2xl),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: AppColors.cardShadowMedium,
                        blurRadius: 6,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // NOT BUNDLED — renders `FileText`. F4-DIV-3.
                      const LucideIcon(
                        name: 'RotateCcw',
                        size: AppSpacing.gap16,
                        color: AppColors.white,
                      ),
                      // `gap-2`
                      const SizedBox(width: AppSpacing.gap8),
                      Text(
                        '$kFamilyBookPageNamespace.retry'.tr(context: context),
                        style: const TextStyle(
                          fontSize: AppTypography.size14,
                          fontWeight: AppTypography.semiBold,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

/// `:327-335` — the empty card. **This is slot 47's render**, in both locales,
/// and the only Tier 3 reference this page has.
class FamilyBookEmptyCard extends StatelessWidget {
  const FamilyBookEmptyCard({super.key});

  @override
  Widget build(BuildContext context) => FamilyBookCard(
        child: Column(
          children: <Widget>[
            // NOT BUNDLED — renders `FileText`. F4-DIV-4, and this is the one
            // that lands in the Tier 3 comparison.
            const LucideIcon(
              name: 'BookX',
              size: AppSpacing.gap32,
              color: AppColors.gray300,
            ),
            const SizedBox(height: AppSpacing.gap12),
            Text(
              '$kFamilyBookPageNamespace.emptyTitle'.tr(context: context),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppTypography.size14,
                fontWeight: AppTypography.semiBold,
                color: AppColors.gray800,
              ),
            ),
            const SizedBox(height: AppSpacing.gap4),
            Text(
              '$kFamilyBookPageNamespace.emptyBody'.tr(context: context),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppTypography.size12,
                height: AppTypography.lineRelaxed,
                color: AppColors.gray400Inline,
              ),
            ),
          ],
        ),
      );
}

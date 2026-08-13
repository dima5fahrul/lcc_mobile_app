/// The `/help` header band — back control, life-buoy badge, title, subtitle,
/// search field.
///
/// `HelpCenterPage.tsx:151-206`. `linear-gradient(135deg, #344EAD 0%, #1a2d7a
/// 100%)`, `px-4 pt-4 pb-12`, with an amber radial bloom bleeding off the
/// top-right corner (`:155-158`).
///
/// The bloom is `pointer-events-none absolute -top-16 -right-10 w-64 h-64
/// rounded-full` filled with
/// `radial-gradient(circle, rgba(245,158,11,0.28) 0%, transparent 70%)` — drawn
/// with `Stack` + `ClipRect` so the overflow really is clipped, as
/// `overflow-hidden` on the band requires.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

// The four sizes below are derived from `AppSpacing`'s scale rather than
// written as bare numbers, and are NOT added to `AppSpacing` itself:
// `lib/presentation/theme/**` is B2a's and is outside B2c's § 3.1 modify list
// (B2-AC-38). Keeping them as arithmetic over existing steps preserves the
// traceability that file's own doc asks for.

/// `w-64 h-64` — the bloom's 256 CSS px box.
const double _bloomSize = AppSpacing.gap32 * 8;

/// `-top-16` / `-right-10` — offsets of −64 and −40 CSS px.
const double _bloomTop = -AppSpacing.gap32 * 2;
const double _bloomRight = -AppSpacing.gap40;

/// `w-14 h-14` — the life-buoy badge.
const double _badgeSize = AppSpacing.tile56;

/// `w-7 h-7` — the life-buoy glyph inside it.
const double _badgeGlyph = AppSpacing.gap14 * 2;

class HelpHeader extends StatelessWidget {
  const HelpHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.backLabel,
    required this.onBack,
    required this.search,
  });

  final String title;
  final String subtitle;
  final String backLabel;
  final VoidCallback onBack;

  /// The search field. Injected rather than built here so the page owns the
  /// controller's lifetime — the same split `HeroHeader` uses for Home.
  final Widget search;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[AppColors.primary, AppColors.helpHeaderEnd],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: _bloomTop,
              right: _bloomRight,
              child: IgnorePointer(
                child: Container(
                  width: _bloomSize,
                  height: _bloomSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      // `rgba(245,158,11,0.28) 0%, transparent 70%`.
                      //
                      // The outer stop is the SAME amber at zero alpha, not
                      // `Colors.transparent`: B2-AC-11's scan rejects any
                      // `Colors.<name>` outside `presentation/theme/`, and a
                      // fully-transparent *black* would grey-fringe the ramp on
                      // the way out, which transparent amber does not.
                      //
                      // `withValues` is a method call, so this `BoxDecoration`
                      // cannot be `const` — the alternative would be a second
                      // zero-alpha token in the theme, which is out of B2c's
                      // § 3.1 scope for one throwaway value.
                      stops: const <double>[0.0, 0.7],
                      colors: <Color>[
                        AppColors.helpHeaderBloom,
                        AppColors.helpHeaderBloom.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              // `px-4 pt-4 pb-12`
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gap16,
                AppSpacing.gap16,
                AppSpacing.gap16,
                AppSpacing.gap24 * 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // `w-9 h-9 -ml-1` — the back control. Negative margin as a
                  // translation, because Flutter padding cannot be negative.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Transform.translate(
                      offset: const Offset(-AppSpacing.gap4, 0),
                      child: Semantics(
                        button: true,
                        label: backLabel,
                        child: InkWell(
                          onTap: onBack,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXl),
                          child: const SizedBox(
                            width: AppSpacing.tile36,
                            height: AppSpacing.tile36,
                            child: Center(
                              child: LucideIcon(
                                name: 'ChevronLeft',
                                size: AppSpacing.gap20,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gap8),
                  // `w-14 h-14 rounded-2xl bg-white/15 border border-white/20
                  //  mx-auto mb-4`
                  Center(
                    child: Container(
                      width: _badgeSize,
                      height: _badgeSize,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radius2xl),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.20),
                        ),
                      ),
                      child: const Center(
                        child: LucideIcon(
                          name: 'LifeBuoy',
                          size: _badgeGlyph,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gap16),
                  // `<h1 class="font-bold text-2xl">`, centred.
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: AppTypography.size24,
                        fontWeight: AppTypography.bold,
                        height: AppTypography.lineSnug,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gap8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      // `text-white/75`
                      color: AppColors.white.withValues(alpha: 0.75),
                      fontSize: AppTypography.size14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gap24),
                  search,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

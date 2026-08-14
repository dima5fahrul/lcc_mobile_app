/// `Hero` — `Hero.tsx:52-134`.
///
/// A photo backdrop under a navy scrim, carrying one phone-width column:
/// greeting + the two issuing ministries, the LaoID card, and the search field.
///
/// ## The backdrop is Tier A and is decoded at paint size
///
/// `hero-bg` is B1b § 6.3 row 9 — 1600×818 native, ~5.2 MB RGBA if decoded
/// whole. It is painted full-bleed at the viewport width, so the decode target
/// is that width in device pixels, capped at native. [TierAImage] does the
/// arithmetic; B2-AC-31's guard makes sure nobody adds a second, undisciplined
/// call site.
///
/// ## The two ministry marks are Tier B and are NOT
///
/// `moha-sm` and `mops-sm` ship a 1x/2.0x/3.0x ladder (B1b § 6.3 rows 13-14),
/// so a plain `Image.asset` resolves the right rung *and* decodes it at the
/// right size with no call-site discipline. Adding `cacheWidth` there would be
/// cargo-culting the Tier A rule onto the tier B1b § 6.4 explicitly exempted —
/// which is why the guard test keys on the asset, not on the constructor.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/entities/digital_id_card.dart';
import 'lao_id_card.dart';
import 'tier_a_image.dart';

class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    required this.authenticated,
    required this.name,
    required this.card,
    required this.onSignIn,
    required this.search,
  });

  final bool authenticated;

  /// `summary.data?.name ?? ""`, and `""` when signed out
  /// (`HomePage.tsx:279`).
  final String name;

  final DigitalIdCard? card;
  final VoidCallback onSignIn;

  /// `children` — the search field `HomePage` passes in
  /// (`HomePage.tsx:292-310`). A slot rather than a field on this widget
  /// because that is what the source models: `Hero` does not know what is
  /// under the card.
  final Widget search;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: TierAImage(
                asset: kHeroBackdrop,
                paintWidth: constraints.maxWidth,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  // `linear-gradient(to bottom, rgba(18,31,80,0.72) 0%,
                  //  rgba(18,31,80,0.82) 60%, rgba(18,31,80,0.90) 100%)`
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      AppColors.scrimNavy.withValues(alpha: 0.72),
                      AppColors.scrimNavy.withValues(alpha: 0.82),
                      AppColors.scrimNavy.withValues(alpha: 0.90),
                    ],
                    stops: const <double>[0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              // `px-5 pt-5 pb-6`
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gap20,
                AppSpacing.gap20,
                AppSpacing.gap20,
                AppSpacing.gap24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _greetingRow(context),
                  const SizedBox(height: AppSpacing.gap16),
                  LaoIdCard(
                    authenticated: authenticated,
                    name: name,
                    card: card,
                    onSignIn: onSignIn,
                  ),
                  const SizedBox(height: AppSpacing.gap16),
                  search,
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// `Hero.tsx:85-115`.
  ///
  /// The greeting's *style* switches on whether a name is present: with one it
  /// is a small translucent label above a large name; without, it is the large
  /// element itself (`Hero.tsx:88-93`). That is a real branch, not a nicety —
  /// it is what makes the signed-out hero read as a heading.
  /// Takes [context] so `home.greeting` can be read through the
  /// `Localizations` scope rather than off `Localization.instance` — D-3's fix
  /// (B10 § 6.7). A bare `.tr()` here creates no `InheritedWidget` dependency,
  /// and this string is one of the nine § 6.6.1 measured going stale.
  Widget _greetingRow(BuildContext context) {
    final bool hasName = name.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                header: !hasName,
                child: Text(
                  'home.greeting'.tr(context: context),
                  style: hasName
                      ? TextStyle(
                          color: AppColors.white.withValues(alpha: 0.75),
                          fontSize: AppTypography.size14,
                          height: AppTypography.lineTight,
                        )
                      : const TextStyle(
                          color: AppColors.white,
                          fontSize: AppTypography.size20,
                          fontWeight: AppTypography.semiBold,
                          height: AppTypography.lineTight,
                        ),
                ),
              ),
              if (hasName) ...<Widget>[
                const SizedBox(height: AppSpacing.gap2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: AppTypography.size24,
                    fontWeight: AppTypography.bold,
                    height: AppTypography.lineTight,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.gap12),
        // `h-7 w-7 object-contain` × 2, with a `w-px h-5 bg-white/25` rule
        // between them. Tier B assets — see the library doc on why these have
        // no `cacheWidth`.
        Image.asset(
          'assets/images/moha-sm.webp',
          height: 28,
          width: 28,
          fit: BoxFit.contain,
          semanticLabel: 'Ministry of Home Affairs',
        ),
        const SizedBox(width: AppSpacing.gap10),
        Container(
          width: 1,
          height: AppSpacing.flagSize,
          color: AppColors.white.withValues(alpha: 0.25),
        ),
        const SizedBox(width: AppSpacing.gap10),
        Image.asset(
          'assets/images/mops-sm.webp',
          height: 28,
          width: 28,
          fit: BoxFit.contain,
          semanticLabel: 'Ministry of Public Security',
        ),
      ],
    );
  }
}

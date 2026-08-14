/// The six tutorial step visuals — `TutorialOverlay.tsx`:29-325's
/// `buildSteps()`.
///
/// ## Hand-ported, not generated from a schema
///
/// ADR-0003 forbids a dynamic renderer: *"mirror the web exactly."* The six
/// visuals in the source are six different hand-built compositions — a stat
/// row, a fake search header, a chip strip over a service grid, a service
/// detail card, a status list, a news card with a chat FAB. They share a
/// wrapper and nothing else. A schema that produced all six would be a small
/// layout engine, and every future edit to one visual would be an edit to that
/// engine's vocabulary. Six functions, one per visual, is the port.
///
/// ## Every string is a `tutorial.*` key, and every `.tr()` passes `context:`
///
/// Including the ones that look like data: `statServicesLabel` is `"7"` in both
/// locales and `statOnlineLabel` is `"100%"`. They are keys in the source
/// (`tutorial.ts`), so they are keys here. Transcribing them as literals would
/// be a divergence that only shows up the day someone translates them.
///
/// The two timestamps in step 5 (`"12 Apr 2026"` and friends) and step 6's
/// `10 / Apr` date chip are **not** keys in the source either — they are inline
/// literals in the `.tsx` — so they are literals here.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

/// One step's fixed data — `TutorialOverlay.tsx`:17-25's `TutorialStep`,
/// minus `visual`, which is built by [tutorialVisual].
@immutable
class TutorialStepSpec {
  const TutorialStepSpec({
    required this.badgeBg,
    required this.badgeInk,
    required this.badgeKey,
    required this.titleKey,
    required this.descKey,
    this.iconLucide,
    this.iconMaterial,
  }) : assert(
          (iconLucide == null) != (iconMaterial == null),
          'exactly one glyph source',
        );

  final Color badgeBg;
  final Color badgeInk;
  final String badgeKey;
  final String titleKey;
  final String descKey;

  /// A bundled lucide name — the source's own glyph, where it exists here.
  final String? iconLucide;

  /// A Material stand-in for the two the bundled set does not carry. See
  /// [kTutorialSteps].
  final IconData? iconMaterial;
}

/// `buildSteps()` — `TutorialOverlay.tsx`:30-324, in source order.
///
/// **Two of six glyphs are named divergences.** The source's six are
/// `Sparkles`, `Search`, `LayoutGrid`, `FileText`, `History` and `Bell`. Four
/// are in the bundled 86 and are used as-is; **`Sparkles` and `History` are
/// not**, and bundling SVGs is outside B10's § 3.1 scope. Passing an unbundled
/// name to `LucideIcon` resolves to `FileText` (`app_icons.dart`:43), so step 1
/// and step 5 would both show a *document* badge and nothing would report it.
/// The stand-ins are explicit here so a reviewer can see the substitution
/// instead of discovering it in Tier 3.
const List<TutorialStepSpec> kTutorialSteps = <TutorialStepSpec>[
  TutorialStepSpec(
    // `Sparkles` — NOT BUNDLED.
    iconMaterial: Icons.auto_awesome,
    badgeBg: AppColors.tutorialBadgeBgIndigo,
    badgeInk: AppColors.tutorialBadgeInkIndigo,
    badgeKey: 'tutorial.badgeWelcome',
    titleKey: 'tutorial.step1Title',
    descKey: 'tutorial.step1Desc',
  ),
  TutorialStepSpec(
    iconLucide: 'Search',
    badgeBg: AppColors.tutorialBadgeBgAmber,
    badgeInk: AppColors.tutorialBadgeInkAmber,
    badgeKey: 'tutorial.badgeStep1',
    titleKey: 'tutorial.step2Title',
    descKey: 'tutorial.step2Desc',
  ),
  TutorialStepSpec(
    iconLucide: 'LayoutGrid',
    badgeBg: AppColors.tutorialBadgeBgGreen,
    badgeInk: AppColors.tutorialBadgeInkGreen,
    badgeKey: 'tutorial.badgeStep2',
    titleKey: 'tutorial.step3Title',
    descKey: 'tutorial.step3Desc',
  ),
  TutorialStepSpec(
    iconLucide: 'FileText',
    badgeBg: AppColors.tutorialBadgeBgIndigo,
    badgeInk: AppColors.tutorialBadgeInkIndigo,
    badgeKey: 'tutorial.badgeStep3',
    titleKey: 'tutorial.step4Title',
    descKey: 'tutorial.step4Desc',
  ),
  TutorialStepSpec(
    // `History` — NOT BUNDLED.
    iconMaterial: Icons.history,
    badgeBg: AppColors.tutorialBadgeBgPurple,
    badgeInk: AppColors.tutorialBadgeInkPurple,
    badgeKey: 'tutorial.badgeStep4',
    titleKey: 'tutorial.step5Title',
    descKey: 'tutorial.step5Desc',
  ),
  TutorialStepSpec(
    iconLucide: 'Bell',
    badgeBg: AppColors.tutorialBadgeBgRed,
    badgeInk: AppColors.tutorialBadgeInkRed,
    badgeKey: 'tutorial.badgeReady',
    titleKey: 'tutorial.step6Title',
    descKey: 'tutorial.step6Desc',
  ),
];

/// The visual for step [index] (0-based).
Widget tutorialVisual(BuildContext context, int index) {
  switch (index) {
    case 0:
      return const _WelcomeVisual();
    case 1:
      return const _SearchVisual();
    case 2:
      return const _BrowseVisual();
    case 3:
      return const _ApplyVisual();
    case 4:
      return const _TrackVisual();
    default:
      return const _InformedVisual();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — welcome (`:38-65`)
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeVisual extends StatelessWidget {
  const _WelcomeVisual();

  @override
  Widget build(BuildContext context) {
    const List<(String, String)> stats = <(String, String)>[
      ('tutorial.statServicesLabel', 'tutorial.statServicesSub'),
      ('tutorial.statSupportLabel', 'tutorial.statSupportSub'),
      ('tutorial.statOnlineLabel', 'tutorial.statOnlineSub'),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: AppSpacing.tutorialHeroTile,
          height: AppSpacing.tutorialHeroTile,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radius3xl),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: AppColors.cardShadowMedium, blurRadius: 15),
            ],
          ),
          child: const Center(
            child: LucideIcon(
              name: 'Home',
              size: AppSpacing.gap40,
              color: AppColors.white,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.gap16),
        Row(
          children: <Widget>[
            for (int i = 0; i < stats.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: AppSpacing.gap8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.gap12,
                    horizontal: AppSpacing.gap8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        stats[i].$1.tr(context: context),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: AppTypography.size16,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.gap2),
                      Text(
                        stats[i].$2.tr(context: context),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.gray500,
                          fontSize: AppTypography.size12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — search (`:74-111`)
// ─────────────────────────────────────────────────────────────────────────────

class _SearchVisual extends StatelessWidget {
  const _SearchVisual();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gray100),
          borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // The miniature top bar.
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gap16,
                vertical: AppSpacing.gap12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      'tutorial.greeting'.tr(context: context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.7),
                        fontSize: AppTypography.size12,
                      ),
                    ),
                  ),
                  LucideIcon(
                    name: 'Bell',
                    size: AppSpacing.gap16,
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.all(AppSpacing.gap12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.gap12,
                            vertical: AppSpacing.gap10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gray50,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusXl),
                            // `border-2 border-amber-300` — the highlight that
                            // is the whole point of this step's visual.
                            border: Border.all(
                              color: AppColors.tutorialSearchOutline,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              const LucideIcon(
                                name: 'Search',
                                size: AppSpacing.gap14,
                                color: AppColors.tutorialSearchGlyph,
                              ),
                              const SizedBox(width: AppSpacing.gap8),
                              Flexible(
                                child: Text(
                                  'tutorial.searchPlaceholder'
                                      .tr(context: context),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.gray400Inline,
                                    fontSize: AppTypography.size12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.gap8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.gap16,
                          vertical: AppSpacing.gap10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.tutorialAmberFill,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXl),
                        ),
                        child: Text(
                          'tutorial.searchButton'.tr(context: context),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: AppTypography.size12,
                            fontWeight: AppTypography.medium,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.gap8),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.gap8),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        for (final String key in <String>[
                          'tutorial.svcBirth',
                          'tutorial.svcResident',
                        ])
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.gap6),
                            child: Row(
                              children: <Widget>[
                                const LucideIcon(
                                  name: 'Search',
                                  size: AppSpacing.gap12,
                                  color: AppColors.gray300,
                                ),
                                const SizedBox(width: AppSpacing.gap8),
                                Flexible(
                                  child: Text(
                                    key.tr(context: context),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.gray500,
                                      fontSize: AppTypography.size12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — browse & filter (`:120-166`)
// ─────────────────────────────────────────────────────────────────────────────

class _BrowseVisual extends StatelessWidget {
  const _BrowseVisual();

  @override
  Widget build(BuildContext context) {
    const List<String> chips = <String>[
      'tutorial.catAll',
      'tutorial.catHousing',
      'tutorial.catIdentity',
      'tutorial.catFamily',
    ];
    const List<(String, String)> tiles = <(String, String)>[
      ('tutorial.svcResident', 'Home'),
      ('tutorial.svcBiography', 'UserCircle'),
      ('tutorial.svcBirth', 'FileText'),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // `overflow-hidden` — the chip strip clips rather than wraps.
        ClipRect(
          child: Row(
            children: <Widget>[
              for (int i = 0; i < chips.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: AppSpacing.gap6),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.gap12,
                      vertical: AppSpacing.gap6,
                    ),
                    decoration: BoxDecoration(
                      color: i == 0 ? AppColors.primary : AppColors.white,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                      border: i == 0
                          ? null
                          : Border.all(color: AppColors.gray200),
                    ),
                    child: Text(
                      chips[i].tr(context: context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: i == 0 ? AppColors.white : AppColors.muted,
                        fontSize: AppTypography.size12,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.gap10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (int i = 0; i < tiles.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: AppSpacing.gap8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.gap12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
                    border: Border.all(color: AppColors.gray100),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(color: AppColors.cardShadow, blurRadius: 2),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: AppSpacing.gap32,
                        height: AppSpacing.gap32,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXl),
                        ),
                        child: Center(
                          child: LucideIcon(
                            name: tiles[i].$2,
                            size: AppSpacing.gap16,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.gap8),
                      Text(
                        tiles[i].$1.tr(context: context),
                        style: const TextStyle(
                          color: AppColors.gray700,
                          fontSize: AppTypography.size12,
                          fontWeight: AppTypography.medium,
                          height: AppTypography.lineTight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — apply (`:175-221`)
// ─────────────────────────────────────────────────────────────────────────────

class _ApplyVisual extends StatelessWidget {
  const _ApplyVisual();

  @override
  Widget build(BuildContext context) {
    const List<(String, String)> rows = <(String, String)>[
      ('tutorial.processingTimeLabel', 'tutorial.processingTimeValue'),
      ('tutorial.requiredDocsLabel', 'tutorial.requiredDocsValue'),
      ('tutorial.serviceFeeLabel', 'tutorial.serviceFeeValue'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        border: Border.all(color: AppColors.gray100),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: AppColors.cardShadowMedium, blurRadius: 6),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gap16),
            child: Row(
              children: <Widget>[
                Container(
                  width: AppSpacing.control40,
                  height: AppSpacing.control40,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  ),
                  child: const Center(
                    child: LucideIcon(
                      name: 'Home',
                      size: AppSpacing.gap20,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.gap12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'tutorial.svcResident'.tr(context: context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.gray800,
                          fontSize: AppTypography.size14,
                          fontWeight: AppTypography.semiBold,
                        ),
                      ),
                      Text(
                        'tutorial.requestRenew'.tr(context: context),
                        style: const TextStyle(
                          color: AppColors.gray400Inline,
                          fontSize: AppTypography.size12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.gray50),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gap12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < rows.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: AppSpacing.gap8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.gap12,
                      vertical: AppSpacing.gap8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          rows[i].$1.tr(context: context),
                          style: const TextStyle(
                            color: AppColors.gray400Inline,
                            fontSize: AppTypography.size12,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.gap2),
                        Text(
                          rows[i].$2.tr(context: context),
                          style: const TextStyle(
                            color: AppColors.gray700,
                            fontSize: AppTypography.size12,
                            fontWeight: AppTypography.medium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gap12,
              0,
              AppSpacing.gap12,
              AppSpacing.gap12,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.gap10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Text(
                'tutorial.applyNow'.tr(context: context),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: AppTypography.size12,
                  fontWeight: AppTypography.medium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 5 — track (`:231-273`)
// ─────────────────────────────────────────────────────────────────────────────

class _TrackVisual extends StatelessWidget {
  const _TrackVisual();

  @override
  Widget build(BuildContext context) {
    // `date` is an inline literal in the source, not a `tutorial.*` key.
    const List<({String nameKey, String date, String statusKey, Color ink, Color bg})>
        items = <({
      String nameKey,
      String date,
      String statusKey,
      Color ink,
      Color bg
    })>[
      (
        nameKey: 'tutorial.svcResident',
        date: '12 Apr 2026',
        statusKey: 'tutorial.statusApproved',
        ink: AppColors.tutorialBadgeInkGreen,
        bg: AppColors.tutorialBadgeBgGreen,
      ),
      (
        nameKey: 'tutorial.svcBiography',
        date: '08 Apr 2026',
        statusKey: 'tutorial.statusPending',
        ink: AppColors.tutorialBadgeInkAmber,
        bg: AppColors.tutorialBadgeBgAmber,
      ),
      (
        nameKey: 'tutorial.svcGeneral',
        date: '01 Apr 2026',
        statusKey: 'tutorial.statusRejected',
        ink: AppColors.tutorialBadgeInkRed,
        bg: AppColors.tutorialBadgeBgRed,
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < items.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.gap8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gap16,
              vertical: AppSpacing.gap12,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
              border: Border.all(color: AppColors.gray50),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: AppColors.cardShadow, blurRadius: 2),
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        items[i].nameKey.tr(context: context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.gray700,
                          fontSize: AppTypography.size12,
                          fontWeight: AppTypography.medium,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.gap2),
                      Text(
                        items[i].date,
                        style: const TextStyle(
                          color: AppColors.gray400Inline,
                          fontSize: AppTypography.size12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.gap8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gap10,
                    vertical: AppSpacing.gap4,
                  ),
                  decoration: BoxDecoration(
                    color: items[i].bg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    items[i].statusKey.tr(context: context),
                    style: TextStyle(
                      color: items[i].ink,
                      fontSize: AppTypography.size12,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 6 — stay informed (`:282-321`)
// ─────────────────────────────────────────────────────────────────────────────

class _InformedVisual extends StatelessWidget {
  const _InformedVisual();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(AppSpacing.gap12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
            border: Border.all(color: AppColors.gray100),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: AppColors.cardShadow, blurRadius: 2),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                constraints: const BoxConstraints(minWidth: AppSpacing.tile44),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gap8,
                  vertical: AppSpacing.gap6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                // `10<br/>Apr` — an inline literal in the source, not a key.
                child: const Text(
                  '10\nApr',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: AppTypography.size12,
                    fontWeight: AppTypography.bold,
                    height: AppTypography.lineTight,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.gap12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'tutorial.newsTitle'.tr(context: context),
                      style: const TextStyle(
                        color: AppColors.gray800,
                        fontSize: AppTypography.size12,
                        fontWeight: AppTypography.medium,
                        height: AppTypography.lineSnug,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.gap2),
                    Text(
                      'tutorial.newsDesc'.tr(context: context),
                      style: const TextStyle(
                        color: AppColors.gray400Inline,
                        fontSize: AppTypography.size12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.gap10),
        // The chat FAB with its unread pip, right-aligned.
        Align(
          alignment: Alignment.centerRight,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Container(
                width: AppSpacing.tile48,
                height: AppSpacing.tile48,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.cardShadowMedium,
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: const Center(
                  child: LucideIcon(
                    name: 'MessageCircle',
                    size: AppSpacing.gap20,
                    color: AppColors.white,
                  ),
                ),
              ),
              Positioned(
                top: -AppSpacing.gap4,
                right: -AppSpacing.gap4,
                child: Container(
                  width: AppSpacing.gap16,
                  height: AppSpacing.gap16,
                  decoration: const BoxDecoration(
                    color: AppColors.tutorialAmberFill,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 8,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.gap10),
        Text(
          'tutorial.chatSupportNote'.tr(context: context),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.gray400Inline,
            fontSize: AppTypography.size12,
          ),
        ),
      ],
    );
  }
}

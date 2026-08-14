/// Port of `lcc-app/src/app/components/TutorialOverlay.tsx` (473 lines) — the
/// six-step first-run walkthrough shown **over Home**.
///
/// ## Why it lives in `features/home/` and not `presentation/` (§ 6.10)
///
/// `ssd.md` § 4.1 reserves `lib/presentation/<group>/` for *"UI consumed by 2
/// or more features"*. This has exactly **one** consumer — `HomePage.tsx`:791
/// — so § 4.1 puts it here. The roadmap groups it with `presentation/common/`,
/// but that is a batching convenience, not a placement decision, and § 4.1
/// governs.
///
/// ## Its gate is NOT the splash's gate
///
/// `lcc.tutorial_seen` and `lcc.onboarding_seen` are **two independent keys**,
/// set by two different handlers: `finish()` (`SplashScreens.tsx`:216) writes
/// only the onboarding one, `handleTutorialDone` (`HomePage.tsx`:229) only this
/// one.
///
/// This was measured and mis-recorded once already. `manifest.md`:190-191
/// claims dismissing the splash sets both; `:262-264` corrects it — *"dismissing
/// the onboarding splash does **not** set it (step 4 above says it does;
/// measured, it does not)"*. So on a fresh install a citizen sees **splash →
/// Home → tutorial over Home**, and `B10-AC-35` asserts the independence in
/// both directions.
///
/// ## The scrim's blur
///
/// `backdrop-filter: blur(4px)` (`:364`) maps to
/// `BackdropFilter(ImageFilter.blur(sigmaX: 2, sigmaY: 2))` — **sigma 2, not
/// 4**: CSS's blur radius is twice the Gaussian standard deviation, the same
/// conversion `glass_icon.dart` records as its fidelity note 3. Passing 4
/// would double the softness.
///
/// If that ever proves too costly on a low-end device the fallback is a solid
/// scrim, and § 8.4 FU-5 requires it be recorded as a named divergence rather
/// than silently dropped. It is **not** dropped here.
///
/// ## Skip is hidden on the last step
///
/// `{!isLast && …}` (`:458`). Small, easy to lose in a port, and asserted by
/// `B10-AC-22`.
library;

import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import 'tutorial_steps.dart';

class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({super.key, required this.onDone});

  /// Fired [AppMotion.tutorialExit] after close or skip — `:344`.
  final VoidCallback onDone;

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _step = 0;
  bool _exiting = false;

  bool get _isLast => _step == kTutorialSteps.length - 1;

  /// `handleClose` — `:342-345`. The 300 ms exit runs **before** `onDone`
  /// (`B10-AC-42`), so the sheet is seen to leave rather than vanishing.
  void _close() {
    if (_exiting) return;
    setState(() => _exiting = true);
    Future<void>.delayed(AppMotion.tutorialExit, () {
      if (mounted) widget.onDone();
    });
  }

  void _next() => _isLast ? _close() : setState(() => _step += 1);

  void _prev() {
    if (_step > 0) setState(() => _step -= 1);
  }

  @override
  Widget build(BuildContext context) {
    final TutorialStepSpec step = kTutorialSteps[_step];

    return AnimatedOpacity(
      opacity: _exiting ? 0 : 1,
      duration: AppMotion.tutorialExit,
      child: BackdropFilter(
        // CSS `blur(4px)` → sigma 2. See the library doc.
        filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: ColoredBox(
          color: AppColors.tutorialScrim,
          child: SafeArea(
            top: false,
            child: Column(
              // `items-end` on phones: a bottom sheet.
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                // `Flexible`, not a bare child: six steps of different heights
                // share one sheet, and the tallest is taller than a short
                // viewport. In CSS the sheet just grows and the page scrolls;
                // a Flutter `Column` overflows instead. This caps it at the
                // available height and lets the sheet's own
                // `SingleChildScrollView` take over — which is what
                // `overflow-y` does in the browser.
                Flexible(
                  child: AnimatedSlide(
                    // `translate-y-8` on exit — `:368`.
                    offset: Offset(0, _exiting ? 0.05 : 0),
                    duration: AppMotion.tutorialExit,
                    child: _sheet(step),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheet(TutorialStepSpec step) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radius3xl),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(color: AppColors.cardShadowMedium, blurRadius: 24),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _topBar(step),
            _visualWell(),
            _text(step),
            _footer(),
          ],
        ),
      ),
    );
  }

  /// `:372-387` — the badge and the close button.
  Widget _topBar(TutorialStepSpec step) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gap20,
        AppSpacing.gap20,
        AppSpacing.gap20,
        AppSpacing.gap8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gap12,
                vertical: AppSpacing.gap6,
              ),
              decoration: BoxDecoration(
                color: step.badgeBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (step.iconLucide != null)
                    LucideIcon(
                      name: step.iconLucide!,
                      size: AppSpacing.gap12,
                      color: step.badgeInk,
                    )
                  else
                    Icon(
                      step.iconMaterial,
                      size: AppSpacing.gap12,
                      color: step.badgeInk,
                    ),
                  const SizedBox(width: AppSpacing.gap6),
                  Flexible(
                    child: Text(
                      step.badgeKey.tr(context: context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: step.badgeInk,
                        fontSize: AppTypography.size12,
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.gap8),
          // `aria-label={tc("close")}` — the **common** namespace, not
          // `tutorial`. Ported as written; the two are different namespaces and
          // silently folding it into `tutorial.close` would invent a key.
          IconButton(
            onPressed: _close,
            tooltip: 'common.close'.tr(context: context),
            iconSize: AppSpacing.gap16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: AppSpacing.gap32,
              minHeight: AppSpacing.gap32,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.gray100,
              shape: const CircleBorder(),
            ),
            icon: LucideIcon(
              name: 'X',
              size: AppSpacing.gap16,
              color: AppColors.gray400Inline,
              semanticsLabel: 'common.close'.tr(context: context),
            ),
          ),
        ],
      ),
    );
  }

  /// `:390-397` — the wash the step's visual sits in.
  Widget _visualWell() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gap20,
        AppSpacing.gap12,
        AppSpacing.gap20,
        AppSpacing.gap16,
      ),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.tutorialVisualMinHeight,
        ),
        padding: const EdgeInsets.all(AppSpacing.gap16),
        decoration: BoxDecoration(
          color: AppColors.tutorialVisualSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        ),
        child: Center(child: tutorialVisual(context, _step)),
      ),
    );
  }

  /// `:400-407`. The title's `fontSize: "1.05rem"` is 16.8 px at the 16 px
  /// root — an inline style, not a Tailwind step, so it is not a
  /// [AppTypography] size and is written as the arithmetic it is.
  Widget _text(TutorialStepSpec step) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gap20,
        0,
        AppSpacing.gap20,
        AppSpacing.gap8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            step.titleKey.tr(context: context),
            style: const TextStyle(
              color: AppColors.gray900,
              fontSize: 16.8,
            ),
          ),
          const SizedBox(height: AppSpacing.gap8),
          Text(
            step.descKey.tr(context: context),
            style: const TextStyle(
              color: AppColors.gray500,
              fontSize: AppTypography.size14,
              height: AppTypography.lineRelaxed,
            ),
          ),
        ],
      ),
    );
  }

  /// `:410-468` — Back | dots | Next, then the skip link on steps 1-5.
  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gap20,
        AppSpacing.gap12,
        AppSpacing.gap20,
        AppSpacing.gap24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child:
                      _step > 0 ? _backButton() : const SizedBox.shrink(),
                ),
              ),
              _dots(),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _nextButton(),
                ),
              ),
            ],
          ),
          // `{!isLast && …}` — `:458`.
          if (!_isLast) ...<Widget>[
            const SizedBox(height: AppSpacing.gap16),
            TextButton(
              onPressed: _close,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.gray400Inline,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gap12,
                  vertical: AppSpacing.gap4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: AppTypography.size12),
              ),
              child: Text('tutorial.skipTutorial'.tr(context: context)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _backButton() {
    return OutlinedButton(
      onPressed: _prev,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gray500,
        side: const BorderSide(color: AppColors.gray200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gap16,
          vertical: AppSpacing.gap10,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        textStyle: const TextStyle(
          fontSize: AppTypography.size14,
          fontWeight: AppTypography.medium,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const LucideIcon(
            name: 'ChevronLeft',
            size: AppSpacing.gap16,
            color: AppColors.gray500,
          ),
          const SizedBox(width: AppSpacing.gap6),
          Text('tutorial.back'.tr(context: context)),
        ],
      ),
    );
  }

  /// `:446-453`. Unlike the splash's, this button's **glyph does not change**
  /// on the last step — only the label does (`ChevronRight` either way). That
  /// asymmetry between the two components is the source's, and reproducing it
  /// is the point.
  Widget _nextButton() {
    return FilledButton(
      onPressed: _next,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gap16,
          vertical: AppSpacing.gap10,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        textStyle: const TextStyle(
          fontSize: AppTypography.size14,
          fontWeight: AppTypography.medium,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            (_isLast ? 'tutorial.getStarted' : 'tutorial.next')
                .tr(context: context),
          ),
          const SizedBox(width: AppSpacing.gap6),
          const LucideIcon(
            name: 'ChevronRight',
            size: AppSpacing.gap16,
            color: AppColors.white,
          ),
        ],
      ),
    );
  }

  /// `:429-442`. Six dots, the active one 20 px wide.
  ///
  /// The source's dots here carry **no** `aria-label` (unlike the splash's,
  /// which has `slideOf`). Ported as-is: adding labels would be an
  /// accessibility improvement over the source, which is still a divergence.
  /// Recorded so the omission reads as deliberate.
  Widget _dots() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gap16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < kTutorialSteps.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: AppSpacing.gap6),
            GestureDetector(
              onTap: () => setState(() => _step = i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: AppMotion.dotMorph,
                width: i == _step
                    ? AppSpacing.dotActiveWidth
                    : AppSpacing.dotSize,
                height: AppSpacing.dotSize,
                decoration: BoxDecoration(
                  color: i == _step ? AppColors.primary : AppColors.gray300,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

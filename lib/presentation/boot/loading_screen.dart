/// Port of `lcc-app/src/app/components/LoadingScreen.tsx` (133 lines) — the
/// boot splash shown on **every** launch.
///
/// Holds for [duration], fades out over [AppMotion.exitFade], then calls
/// [onDone] — which is what advances the app to onboarding (first run) or
/// straight to Home. `main.dart` owns that transition; this widget owns only
/// the hold and the fade.
///
/// ## Timing is ported as data, not as feel (§ 6.8)
///
/// `LoadingScreen.tsx`:17-18 states `DEFAULT_DURATION = 1800` and
/// `FADE_MS = 320`, and `:36-37` fires the fade at `duration` and `onDone` at
/// **`duration + FADE_MS`** — 2120 ms, not 1800. Both are tokens
/// ([AppMotion.bootHold], [AppMotion.exitFade], [AppMotion.bootTotal]) and
/// `B10-AC-32` asserts the sum rather than the hold, because "fires at 1800"
/// is the plausible-looking wrong answer.
///
/// ## Accessibility, ported rather than re-decided
///
/// `LoadingScreen.tsx`:10-14 records three decisions this port keeps:
///
/// 1. The whole screen is a **polite live region** announcing "Loading…", so a
///    screen reader says something meaningful instead of reading the logo.
///    Flutter: `Semantics(liveRegion: true, label:)`.
/// 2. The progress bar is **decorative** and `aria-hidden` — the wait is a
///    fixed timer, not a measure of work, so a real progressbar role would be
///    a lying one. Flutter: `ExcludeSemantics`.
/// 3. The logo is `alt="" aria-hidden`. Flutter: `excludeFromSemantics`.
///
/// ## Two divergences, named
///
/// * **`prefers-reduced-motion`.** The source disables all motion under it via
///   `.lcc-boot-*` rules in `styles/index.css`. Flutter's equivalent signal is
///   `MediaQuery.disableAnimationsOf(context)`, and it is honoured below: the
///   halo pulse and the progress sweep are simply not animated when it is set.
///   The **hold itself is not shortened** — the source does not shorten it
///   either; reduced motion is about movement, not about time.
/// * **`filter: blur(40px)` / `blur(50px)` on the two decorative glows.** CSS
///   blur radius is twice the Gaussian standard deviation, so these become
///   `sigma = 20` and `sigma = 25` — the same conversion `glass_icon.dart`'s
///   library doc records as fidelity note 3. Passing 40 straight to
///   [ImageFilter.blur] would double the softness.
library;

import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// The boot splash.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({
    super.key,
    required this.onDone,
    this.duration = AppMotion.bootHold,
  });

  /// Fires at `duration + FADE_MS` — `LoadingScreen.tsx`:37.
  final VoidCallback onDone;

  /// `duration = DEFAULT_DURATION` — `:22`.
  final Duration duration;

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  bool _exiting = false;

  /// Drives the halo pulse and the progress sweep. One controller for both:
  /// the source runs them off the same `--lcc-boot-ms`, so a second controller
  /// would be two clocks that could drift apart on a slow frame.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    _pulse.forward();

    // `setTimeout(() => setExiting(true), duration)` — `:36`.
    Future<void>.delayed(widget.duration, () {
      if (mounted) setState(() => _exiting = true);
    });
    // `setTimeout(() => onDoneRef.current(), duration + FADE_MS)` — `:37`.
    //
    // Read through the widget at fire time rather than captured, which is the
    // Flutter equivalent of the source's `onDoneRef`: an inline closure from
    // the parent must not be able to restart or stale-capture the callback.
    Future<void>.delayed(widget.duration + AppMotion.exitFade, () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      // `role="status" aria-live="polite"` — `:47-48`.
      liveRegion: true,
      label: 'onboarding.loading'.tr(context: context),
      child: AnimatedOpacity(
        opacity: _exiting ? 0 : 1,
        duration: AppMotion.exitFade,
        curve: Curves.easeOut,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            // `linear-gradient(160deg, #4460C9 0%, #344EAD 45%, #1B2C68 100%)`
            // — `:51-52`. 160° points down-and-slightly-left; the gradient line
            // for angle θ runs along (sin θ, −cos θ) with y downward, so
            // 160° → (0.342, 0.940).
            gradient: LinearGradient(
              begin: Alignment(-0.342, -0.940),
              end: Alignment(0.342, 0.940),
              colors: <Color>[
                AppColors.bootGradientStart,
                AppColors.bootGradientMid,
                AppColors.bootGradientEnd,
              ],
              stops: <double>[0.0, 0.45, 1.0],
            ),
          ),
          child: ClipRect(
            // `overflow-hidden` — both glows are positioned outside the frame.
            child: Stack(
              children: <Widget>[
                // `-top-24 -right-20 w-72 h-72`, `blur(40px)` → sigma 20.
                Positioned(
                  top: -96,
                  right: -80,
                  child: _glow(288, AppColors.bootGlowWhite, 20),
                ),
                // `-bottom-28 -left-16 w-80 h-80`, `blur(50px)` → sigma 25.
                Positioned(
                  bottom: -112,
                  left: -64,
                  child: _glow(320, AppColors.bootGlowAmber, 25),
                ),
                Padding(
                  // `px-6 py-10`
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gap24,
                    vertical: AppSpacing.gap40,
                  ),
                  child: SafeArea(
                    child: Column(
                      // `justify-between` with an empty first child (`:69`),
                      // which is what centres the brand block between the top
                      // of the frame and the issuing-authority footer.
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        const SizedBox.shrink(),
                        _brand(reduceMotion),
                        _issuedBy(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One decorative blurred circle. `aria-hidden` in the source, so it is
  /// excluded from semantics here.
  Widget _glow(double diameter, Color color, double sigma) {
    return ExcludeSemantics(
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }

  /// The logo tile, the two brand lines, the progress bar and its caption —
  /// `LoadingScreen.tsx`:72-115.
  Widget _brand(bool reduceMotion) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: AppSpacing.bootLogoTile,
          height: AppSpacing.bootLogoTile,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              // `.lcc-boot-ring` — the pulsing halo behind the tile.
              ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (BuildContext context, Widget? child) {
                    final double t = reduceMotion ? 0 : _pulse.value;
                    // A single sweep of scale + fade, matching the CSS
                    // keyframes' shape: grows outward while fading away.
                    return Transform.scale(
                      scale: 1 + 0.18 * t,
                      child: Opacity(opacity: 1 - t, child: child),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      // `rounded-[28%]` of a 96 px tile.
                      borderRadius: BorderRadius.circular(
                        AppSpacing.bootLogoTile * 0.28,
                      ),
                      border: Border.all(color: AppColors.bootRing),
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(
                    AppSpacing.bootLogoTile * 0.28,
                  ),
                  boxShadow: const <BoxShadow>[
                    // `0 20px 45px rgba(0,0,0,0.28)` — `:82`.
                    BoxShadow(
                      color: AppColors.bootLogoShadow,
                      offset: Offset(0, 20),
                      blurRadius: 45,
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    // Tier B (`2.0x`/`3.0x` rungs present), so a plain
                    // `Image.asset` is correct and the Tier A decode rule does
                    // not apply — `tier_a_image.dart`:144-150 states that
                    // asymmetry.
                    'assets/images/logo-lcc.webp',
                    width: AppSpacing.bootLogoGlyph,
                    height: AppSpacing.bootLogoGlyph,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.gap24),
        Text(
          'onboarding.appName'.tr(context: context),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: AppTypography.size18,
            fontWeight: AppTypography.semiBold,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.gap4),
        Text(
          'onboarding.appSub'.tr(context: context),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.7),
            fontSize: AppTypography.size14,
          ),
        ),
        const SizedBox(height: AppSpacing.gap32),
        // `aria-hidden` — decorative, see the library doc.
        ExcludeSemantics(
          child: SizedBox(
            width: AppSpacing.bootProgressWidth,
            height: AppSpacing.bootProgressHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: ColoredBox(
                color: AppColors.bootProgressTrack,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (BuildContext context, _) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      // Under reduced motion the bar sits full rather than
                      // sweeping — present, not moving.
                      widthFactor: reduceMotion ? 1.0 : _pulse.value,
                      child: const ColoredBox(color: AppColors.bootAccent),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.gap12),
        Text(
          'onboarding.loading'.tr(context: context),
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.6),
            fontSize: AppTypography.size12,
          ),
        ),
      ],
    );
  }

  /// `LoadingScreen.tsx`:117-130 — the star glyph and the issuing ministries.
  ///
  /// The source's own comment explains why this is text and not the two
  /// ministry logos: *"those PNGs are ~3 MB each, which would leave the splash
  /// half-empty on a slow link."* The port keeps the decision even though a
  /// bundled asset has no download cost, because changing it would put two
  /// marks on a screen the source deliberately leaves bare.
  Widget _issuedBy() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const ExcludeSemantics(
          child: Icon(
            // The source hand-draws a five-pointed star as an inline `<svg>`
            // path (`:121-126`) rather than importing a lucide glyph. `Star`
            // is not in the bundled 86, and adding an asset is outside B10's
            // § 3.1 scope, so this is Material's filled star at the same size
            // and colour. **A named divergence**, recorded here and in the
            // batch report rather than left for Tier 3 to find.
            Icons.star,
            size: AppSpacing.gap20,
            color: AppColors.bootAccent,
          ),
        ),
        const SizedBox(height: AppSpacing.gap10),
        Text(
          'onboarding.issuedBy'.tr(context: context),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.5),
            fontSize: AppTypography.size11,
            height: AppTypography.lineRelaxed,
          ),
        ),
      ],
    );
  }
}

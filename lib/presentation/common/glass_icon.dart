/// Port of `lcc-app/src/app/components/GlassIcon.tsx` (83 lines).
///
/// A glassmorphism icon tile: a coloured squircle built from a gradient base,
/// two blurred floating bubbles, a frosted translucent panel, a white glyph and
/// a diagonal gloss highlight.
///
/// ## Why it lives in `presentation/common/`
///
/// It is consumed by `ServiceCard`, `ServicePage` and `HomePage` — three
/// surfaces in two features — which is SSD § 4.2 row 3, `lib/presentation/`.
/// § 4.4 schedules `presentation/common/` for B10; that column is a *schedule*,
/// not a placement rule, so specs.md § 6.3.4 pulls the folder forward for this
/// one widget. B10 adds `Button`, `DialogShell`, `LoadingScreen` and `Footer`
/// unchanged. No fifth `presentation/` group is created by this.
///
/// ## Fidelity notes — the three places CSS has something Flutter does not
///
/// Recorded here rather than discovered during Tier 3:
///
/// 1. **`box-shadow: inset …`** has no Flutter equivalent; `BoxShadow` is
///    outer-only. The tile's `inset 0 1px 1px rgba(255,255,255,0.45)` and the
///    frosted panel's `inset 0 1px 1px rgba(255,255,255,0.6)` are drawn as
///    top-edge gradient overlays, which is what an inset highlight of that size
///    looks like. Sub-pixel, but it is an approximation and not a copy.
/// 2. **`filter: drop-shadow(...)`** on the glyph is emulated by painting the
///    glyph twice — a blurred dark copy offset one pixel down, then the white
///    one on top. Same result, different mechanism.
/// 3. **CSS `blur(Npx)` is not a Gaussian sigma.** The CSS blur radius is twice
///    the standard deviation, so every `filter: blur(N)` below becomes
///    `sigma = N / 2`. Passing N straight to [ImageFilter.blur] would double
///    the softness of both bubbles.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../icons/lucide_icon.dart';
import '../theme/app_colors.dart';

/// A glass icon tile.
///
/// [color] is normally a colour the **API supplied** (`Service.color`,
/// `ServiceCategory.color`), which is why it is a required parameter with no
/// default: there is no correct constant for it (see `AppColors`' note on
/// runtime colour families).
///
/// [iconName] must already be scope-resolved by the caller through
/// `AppIcons.service` / `AppIcons.help`. This widget does not resolve scopes —
/// it does not know which surface it is on, and guessing is exactly the merge
/// that § 6.3.5 forbids.
class GlassIcon extends StatelessWidget {
  const GlassIcon({
    super.key,
    required this.iconName,
    required this.color,
    this.size = 44,
  });

  /// A lucide component name, already resolved against the caller's registry.
  final String iconName;

  /// The tile's accent colour. Usually catalogue data, not a token.
  final Color color;

  /// Tile edge length. `GlassIcon.tsx`'s `size = 44` default.
  final double size;

  @override
  Widget build(BuildContext context) {
    // `Math.round(size * 0.46)` — the source rounds, so this does too.
    final double glyph = (size * 0.46).roundToDouble();
    final BorderRadius tileRadius = BorderRadius.circular(size * 0.28);

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: tileRadius,
          gradient: LinearGradient(
            // CSS `linear-gradient(145deg, …)`. The gradient line for an angle
            // θ points along (sin θ, −cos θ) with y measured downward; 145°
            // gives (0.574, 0.819), i.e. upper-left to lower-right, steeper
            // than a plain diagonal.
            begin: const Alignment(-0.574, -0.819),
            end: const Alignment(0.574, 0.819),
            colors: <Color>[
              AppColors.shade(color, 30),
              color,
              AppColors.shade(color, -16),
            ],
            stops: const <double>[0.0, 0.55, 1.0],
          ),
          boxShadow: <BoxShadow>[
            // `0 6px 14px hexToRgba(color, 0.4)`. CSS blur radius → sigma.
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              offset: const Offset(0, 6),
              blurRadius: 14,
            ),
          ],
        ),
        child: ClipRRect(
          // `overflow-hidden` on the tile: the bubbles are positioned outside
          // its bounds and must be cut off by the squircle, not by a rectangle.
          borderRadius: tileRadius,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              // ── inset 0 1px 1px rgba(255,255,255,0.45) ──
              Positioned.fill(child: _insetHighlight(size, 0.45)),

              // ── floating blurred glass bubbles ──
              Positioned(
                top: -size * 0.16,
                right: -size * 0.12,
                child: _bubble(
                  diameter: size * 0.55,
                  opacity: 0.42,
                  cssBlur: size * 0.06,
                ),
              ),
              Positioned(
                bottom: size * 0.05,
                left: size * 0.08,
                child: _bubble(
                  diameter: size * 0.3,
                  opacity: 0.3,
                  cssBlur: size * 0.045,
                ),
              ),

              // ── frosted translucent panel + glyph ──
              Positioned(
                top: size * 0.1,
                left: size * 0.1,
                right: size * 0.1,
                bottom: size * 0.1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size * 0.24),
                    color: AppColors.white.withValues(alpha: 0.16),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Positioned.fill(child: _insetHighlight(size, 0.6)),
                      _glyph(glyph),
                    ],
                  ),
                ),
              ),

              // ── diagonal gloss highlight ──
              // `linear-gradient(135deg, rgba(255,255,255,0.5) 0%,
              //  rgba(255,255,255,0) 42%)` — 135° is exactly the topLeft →
              // bottomRight diagonal, so no angle arithmetic is needed here.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          AppColors.white.withValues(alpha: 0.5),
                          AppColors.white.withValues(alpha: 0),
                        ],
                        stops: const <double>[0.0, 0.42],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The white glyph, with the source's `drop-shadow(0 1px 1px …)` painted as a
  /// blurred dark copy underneath. See fidelity note 2.
  Widget _glyph(double glyph) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Transform.translate(
          offset: const Offset(0, 1),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
            child: LucideIcon(
              name: iconName,
              size: glyph,
              color: AppColors.glyphShadow, // rgba(0,0,0,0.18)
            ),
          ),
        ),
        LucideIcon(name: iconName, size: glyph, color: AppColors.white),
      ],
    );
  }

  /// A top-edge white gradient standing in for a 1 px inset box-shadow.
  /// See fidelity note 1.
  static Widget _insetHighlight(double size, double alpha) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              AppColors.white.withValues(alpha: alpha),
              AppColors.white.withValues(alpha: 0),
            ],
            // Two logical pixels of falloff, whatever the tile size: the
            // source's inset shadow is 1 px + 1 px blur and does not scale.
            stops: <double>[0.0, (2 / size).clamp(0.0, 1.0)],
          ),
        ),
      ),
    );
  }

  /// One blurred glass bubble. See fidelity note 3 on the sigma.
  static Widget _bubble({
    required double diameter,
    required double opacity,
    required double cssBlur,
  }) {
    final double sigma = cssBlur / 2;

    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

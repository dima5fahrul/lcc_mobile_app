/// Renders one bundled lucide glyph.
///
/// ## Why a `ColorFilter` and not a `fill`
///
/// lucide SVGs are stroked, not filled: every generated file carries
/// `fill="none" stroke="currentColor"` from lucide's own `defaultAttributes`.
/// `currentColor` has no meaning to `flutter_svg` — there is no cascading
/// `color` property to inherit — so the colour has to be imposed from outside.
/// `ColorFilter.mode(c, BlendMode.srcIn)` replaces the colour of every painted
/// pixel while keeping its alpha, which recolours the stroke *and* its
/// antialiased edges. Setting a `fill` instead would paint the interior of
/// glyphs that are meant to be outlines.
///
/// ## Stroke width
///
/// **2 at a 24-unit viewBox**, baked into the asset by the generator, matching
/// `defaultAttributes` and `GlassIcon`'s explicit `strokeWidth={2}`. It is not
/// optically corrected at small sizes: the web does not correct it either, and
/// a Flutter-only correction is a Tier 3 disparity with no source.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import 'app_icons.dart';

/// A single lucide glyph, addressed by its lucide component name.
///
/// The name is the same string the catalogue API sends and the same string the
/// SVG is filed under (§ 6.3.3) — there is no case-mapping layer to get wrong.
///
/// Callers rendering an **API-supplied** name must resolve it through
/// [AppIcons.service] or [AppIcons.help] first, so the right registry scope is
/// applied. Passing an unbundled name here is still safe — it renders
/// [AppIcons.fallback] rather than crashing or drawing nothing — but it
/// bypasses the scoping rule, so the two-registry fidelity guarantee only holds
/// if the caller does the resolution.
class LucideIcon extends StatelessWidget {
  const LucideIcon({
    super.key,
    required this.name,
    this.size = 24,
    this.color,
    this.semanticsLabel,
  });

  /// A lucide component name, e.g. `FileText`, `Users2`.
  final String name;

  /// Rendered edge length, in logical pixels. Square, like the 24-unit viewBox.
  final double size;

  /// The stroke colour. Defaults to the ambient [IconTheme]'s colour so a
  /// [LucideIcon] tints the same way a Material [Icon] does in the same slot,
  /// and to [AppColors.gray900] where there is no ambient icon colour.
  final Color? color;

  /// Passed straight to the underlying picture. Left null by default: most
  /// icons in this app sit beside their own visible label and announcing the
  /// glyph as well would double every list item.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final Color resolved =
        color ?? IconTheme.of(context).color ?? AppColors.gray900;

    return SvgPicture.asset(
      AppIcons.assetFor(name),
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(resolved, BlendMode.srcIn),
      semanticsLabel: semanticsLabel,
    );
  }
}

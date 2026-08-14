/// **B2-AC-31 — Tier A asset discipline, as a mechanism rather than a memo.**
///
/// B1b § 6.4 ruled that the eight category photographs, `hero-bg`, `bg-id` and
/// `user-photo` ship as **one** asset each at their 3x size, with no density
/// ladder, and it named the cost of that decision in the same paragraph:
///
/// > *"The one real cost of a single large asset is decode memory, not
/// > sharpness: Flutter decodes the full 864×1152 bitmap (~4 MB RGBA) even when
/// > painting into a 281×360 box, and the HomePage slider holds eight of them.
/// > That is a call-site problem with a zero-payload fix … **This binds B2, not
/// > this ticket** (this ticket creates no call site): every `Image.asset` /
/// > `AssetImage` for a Tier A asset must supply `cacheWidth`/`cacheHeight`."*
///
/// B2b is the batch that creates those call sites, so B2b is where the
/// constraint stops being a forward note. Eight slides at 864×1152 RGBA is
/// **31.8 MB** of image cache for a strip that paints 281×360 boxes — on the
/// 2 GB handsets this app targets that is the difference between a scroll and
/// an eviction storm.
///
/// ## The shape of the fix, and why it is one widget and not a convention
///
/// A convention is a thing every future call site has to remember. This is one
/// place that computes the decode size and one test
/// (`test/features/home/architecture/tier_a_asset_test.dart`) that fails the
/// build if a Tier A asset is loaded anywhere else. The test is the part that
/// matters: a helper nobody is required to use is a convention with extra
/// steps.
///
/// ## The arithmetic
///
/// `cacheWidth = min(native, ceil(logical × devicePixelRatio))`, and the height
/// derived from the asset's own aspect so the decode never distorts.
///
/// * **× devicePixelRatio**, because `cacheWidth` is in *device* pixels while
///   the layout box is in logical ones. Decoding at the logical width would
///   halve the resolution on a 2x screen and third it on a 3x — a visible
///   regression dressed up as an optimisation, and the reason this is a helper
///   rather than a hardcoded number per call site.
/// * **capped at native**, because decoding above the source's own pixel
///   dimensions costs memory to invent detail that is not there. B1b § 6.2's
///   "never upscale" rule, applied at the call site instead of the encoder.
/// * **`ceil`**, not `round`: a decode one pixel short of the paint box is
///   upsampled at draw time, which is exactly the softness this is meant to
///   avoid.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One bundled Tier A photograph: its path and its **native** pixel size.
///
/// The dimensions are B1b § 6.3's "Target px" column, which is what
/// `tool/optimise_images.sh` actually produced — not a guess, and not read back
/// off the file at runtime, because the cap has to be known before the decode
/// is scheduled.
class TierAAsset {
  const TierAAsset({
    required this.path,
    required this.nativeWidth,
    required this.nativeHeight,
  });

  final String path;
  final int nativeWidth;
  final int nativeHeight;

  /// Native aspect, used to derive `cacheHeight` from `cacheWidth` so a
  /// clamped decode stays proportional.
  double get aspect => nativeWidth / nativeHeight;
}

/// The eight category slides, indexed by the category `code` they illustrate.
///
/// `HomePage.tsx:109-118`'s `CATEGORY_SLIDES`, in the source's order — which is
/// also `/service-categories`' `sort_order`, so the strip reads the same way in
/// both applications without a client-side sort (SSD § 11.2 L-3/L-4).
///
/// All eight are 864×1152 (B1b § 6.3 rows 1-8): the cover box is 281×360 CSS at
/// a 0.781 aspect, the 3:4 source is narrower so width binds, and 864 ≥ 843
/// clears 281 × 3.
const Map<String, TierAAsset> kCategorySlideAssets = <String, TierAAsset>{
  'civil': TierAAsset(
    path: 'assets/images/civil-population.webp',
    nativeWidth: 864,
    nativeHeight: 1152,
  ),
  'immigration': TierAAsset(
    path: 'assets/images/immigration.webp',
    nativeWidth: 864,
    nativeHeight: 1152,
  ),
  'finance': TierAAsset(
    path: 'assets/images/tax-payment.webp',
    nativeWidth: 864,
    nativeHeight: 1152,
  ),
  'housing': TierAAsset(
    path: 'assets/images/land-property.webp',
    nativeWidth: 864,
    nativeHeight: 1152,
  ),
  'transport': TierAAsset(
    path: 'assets/images/transport.webp',
    nativeWidth: 864,
    nativeHeight: 1152,
  ),
  'welfare': TierAAsset(
    path: 'assets/images/social-protection.webp',
    nativeWidth: 864,
    nativeHeight: 1152,
  ),
  'education': TierAAsset(
    path: 'assets/images/education.webp',
    nativeWidth: 864,
    nativeHeight: 1152,
  ),
  'health': TierAAsset(
    path: 'assets/images/health.webp',
    nativeWidth: 864,
    nativeHeight: 1152,
  ),
};

/// `hero-bg` — B1b § 6.3 row 9. Kept at its native 1600×818 because it is
/// already at or below its 3x requirement; resizing it would be a visible
/// regression rather than removed waste.
const TierAAsset kHeroBackdrop = TierAAsset(
  path: 'assets/images/hero-bg.webp',
  nativeWidth: 1600,
  nativeHeight: 818,
);

/// `bg-id` — B1b § 6.3 row 10, the ID card's security pattern. Native
/// 1000×585, painted into a 16:9 card roughly 350×197 CSS.
const TierAAsset kIdCardBackdrop = TierAAsset(
  path: 'assets/images/bg-id.webp',
  nativeWidth: 1000,
  nativeHeight: 585,
);

/// A bundled Tier A photograph, decoded no larger than it is painted.
///
/// The **only** sanctioned way to put a Tier A asset on screen. `Image.asset`
/// and `AssetImage` are not forbidden in general — the Tier B marks
/// (`moha-sm`, `mops-sm`, …) use them directly and correctly, because Flutter's
/// resolution-aware `AssetImage` picks their `2.0x`/`3.0x` rung and decodes it
/// at the right size with no call-site discipline required. That asymmetry is
/// B1b § 6.4's whole ruling, and it is why the guard test keys on the *asset*
/// rather than on the constructor.
class TierAImage extends StatelessWidget {
  const TierAImage({
    super.key,
    required this.asset,
    required this.paintWidth,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final TierAAsset asset;

  /// The **logical** width this image will be painted at. Device pixels are
  /// derived; see the library doc.
  final double paintWidth;

  final BoxFit fit;

  /// CSS `object-position`, added by B10 § 6.9.
  ///
  /// **Additive, and the default is the pre-B10 behaviour** —
  /// [Image.alignment] already defaults to [Alignment.center], so every
  /// existing call site renders byte-identically. The parameter exists because
  /// `SplashScreens.tsx` frames the *same* `hero-bg` photograph three
  /// different ways (`50% 42%`, `22% 55%`, `78% 48%`) to keep three slides
  /// from looking like one screen repeated, and `object-position` is the only
  /// thing that differs between them.
  ///
  /// It is added here rather than worked around because the alternatives are
  /// worse: this is the **only** sanctioned way to put a Tier A asset on
  /// screen (`tier_a_asset_test.dart` fails the build on any other), so a
  /// splash that could not express the framing would either duplicate the
  /// decode arithmetic outside the guard or drop the framing silently.
  final Alignment alignment;

  /// The decode width, in device pixels, for [paintWidth] at [devicePixelRatio].
  ///
  /// Static and pure so the guard test can assert the *arithmetic* — that a
  /// 281 px box on a 3x screen decodes at 843 and not at 864, and that a
  /// hypothetical 400 px box clamps to 864 instead of asking for 1200.
  static int decodeWidthFor(
    TierAAsset asset,
    double paintWidth,
    double devicePixelRatio,
  ) {
    final int wanted = (paintWidth * devicePixelRatio).ceil();
    // `max(1, …)`: a zero-width box during a layout pass would otherwise ask
    // the decoder for a zero-pixel image, which throws rather than degrades.
    return math.max(1, math.min(asset.nativeWidth, wanted));
  }

  @override
  Widget build(BuildContext context) {
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final int cacheWidth = decodeWidthFor(asset, paintWidth, dpr);
    final int cacheHeight = math.max(1, (cacheWidth / asset.aspect).ceil());

    return Image.asset(
      asset.path,
      fit: fit,
      alignment: alignment,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      // `excludeFromSemantics`, because every Tier A surface in this port is
      // `alt="" aria-hidden` in the source (`HomePage.tsx:567`,
      // `Hero.tsx:70,195`): they are backdrops behind text, and announcing
      // eight unlabelled photographs would make the slider unusable with a
      // screen reader rather than more accessible.
      excludeFromSemantics: true,
    );
  }
}

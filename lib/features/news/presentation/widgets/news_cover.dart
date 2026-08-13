/// An article thumbnail: the category gradient, with the remote cover on top
/// when there is one.
///
/// `NewsPage.tsx:160-174`, `NewsDetailPage.tsx:189-202` and `:264-278` are the
/// same two layers — an absolutely-positioned
/// `linear-gradient(135deg, <category_color> 0%, #17235c 100%)`, and an
/// `object-cover` image over it. The gradient is drawn **unconditionally**, so
/// a missing or slow cover is a styled tile rather than a hole.
///
/// ## Why `Image.network` and not a cached image widget
///
/// The app declares no image-caching package and `pubspec.yaml` is out of
/// B2c's § 3.1 scope. `Image.network` is what B2b's `TierAImage` wraps for the
/// same reason.
///
/// **`cacheWidth` is supplied** on every instance. B2-AC-31 scopes the Tier A
/// asset guard to `Image.asset`/`AssetImage`, so these remote images are not
/// what it inspects — but decoding a full-resolution press photo into a 112 px
/// tile is the same defect the guard exists to prevent, and the fix is one
/// argument.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../domain/news_formatting.dart';

class NewsCover extends StatelessWidget {
  const NewsCover({
    super.key,
    required this.coverUrl,
    required this.categoryColor,
    required this.width,
    required this.height,
    required this.radius,
  });

  final String coverUrl;

  /// The raw wire value, e.g. `#3752AE`. May be empty or malformed.
  final String categoryColor;

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final int? solid = newsSolid(categoryColor);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  // `135deg` in CSS is top-left → bottom-right.
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    // `${item.category_color} 0%` — an unusable value leaves
                    // the CSS gradient invalid, so the element renders its
                    // inherited surface; `AppColors.primary` is the brand stop
                    // the rest of the page is built on.
                    solid == null ? AppColors.primary : Color(solid),
                    AppColors.photoGradientEnd,
                  ],
                ),
              ),
            ),
            if (coverUrl.isNotEmpty)
              Image.network(
                coverUrl,
                fit: BoxFit.cover,
                cacheWidth: (width * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                // `alt="" aria-hidden` — decorative. Excluding it from
                // semantics is the port of that, not an accessibility
                // shortcut: the headline beside it carries the meaning.
                excludeFromSemantics: true,
                // A 404 on a cover must not paint an error glyph over the
                // gradient; the web's `<img>` simply fails to render.
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}

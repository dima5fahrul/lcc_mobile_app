/// `GlassIcon` — the `presentation/common/` widget § 6.3.4 pulls forward.
///
/// The assertions worth having here are the ones a screenshot review cannot
/// make cheaply: that the gradient stops are the source's `shade()` values
/// rather than a Flutter `lerp`, that the glyph is 46 % of the tile *rounded*,
/// and that the whole thing paints without an exception at the sizes the
/// catalogue uses.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/presentation/common/glass_icon.dart';
import 'package:lcc_mobile_app/presentation/icons/app_icons.dart';
import 'package:lcc_mobile_app/presentation/icons/lucide_icon.dart';
import 'package:lcc_mobile_app/presentation/theme/app_colors.dart';

const Key _boundary = Key('glass-boundary');

/// A catalogue-supplied accent colour — data, not a token, which is why it is
/// written out here rather than pulled from `AppColors`.
const Color kCategoryColor = Color(0xFF344EAD);

Future<Uint8List> _raster(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: RepaintBoundary(key: _boundary, child: child)),
      ),
    ),
  );

  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pumpAndSettle();

  final RenderRepaintBoundary boundary =
      tester.renderObject(find.byKey(_boundary));
  final ui.Image image = (await tester.runAsync(() => boundary.toImage()))!;
  final ByteData bytes = (await tester.runAsync<ByteData?>(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  image.dispose();

  return bytes.buffer.asUint8List();
}

void main() {
  group('GlassIcon renders', () {
    testWidgets('at the default 44 px, with no exception',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassIcon(iconName: 'Plane', color: kCategoryColor),
            ),
          ),
        ),
      );
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(GlassIcon)), const Size(44, 44));
    });

    testWidgets('the glyph is round(size * 0.46), the source s arithmetic',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassIcon(
                iconName: 'Plane',
                color: kCategoryColor,
                size: 44,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 44 * 0.46 = 20.24 → 20. A truncating port gives the same answer here,
      // so the size that discriminates is checked below.
      final Iterable<LucideIcon> glyphs =
          tester.widgetList<LucideIcon>(find.byType(LucideIcon));
      expect(glyphs.map((LucideIcon g) => g.size).toSet(), <double>{20});
    });

    testWidgets('rounding, not truncation, at a size where they differ',
        (WidgetTester tester) async {
      // 32 * 0.46 = 14.72 → round 15, truncate 14.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassIcon(
                iconName: 'Plane',
                color: kCategoryColor,
                size: 32,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widgetList<LucideIcon>(find.byType(LucideIcon))
            .map((LucideIcon g) => g.size)
            .toSet(),
        <double>{15},
      );
    });

    testWidgets('the glyph is painted twice — white over its drop shadow',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassIcon(iconName: 'Plane', color: kCategoryColor),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final List<Color?> colors = tester
          .widgetList<LucideIcon>(find.byType(LucideIcon))
          .map((LucideIcon g) => g.color)
          .toList();
      expect(colors, <Color>[AppColors.glyphShadow, AppColors.white]);
    });

    testWidgets('an unresolvable icon name still paints a tile',
        (WidgetTester tester) async {
      // The caller is supposed to resolve the scope first; if it forgets, the
      // tile must degrade to the FileText fallback, not vanish.
      final Uint8List rendered = await _raster(
        tester,
        GlassIcon(
          iconName: AppIcons.service('NotARealIconName'),
          color: kCategoryColor,
        ),
      );

      expect(tester.takeException(), isNull);

      int nonWhite = 0;
      for (int i = 0; i < rendered.length; i += 4) {
        final bool white =
            rendered[i] == 255 && rendered[i + 1] == 255 && rendered[i + 2] == 255;
        if (!white && rendered[i + 3] != 0) nonWhite++;
      }
      expect(nonWhite, greaterThan(100));
    });
  });

  group('the gradient is built from glass.ts shade()', () {
    testWidgets('stops are shade(+30), the colour itself, shade(-16)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassIcon(iconName: 'Plane', color: kCategoryColor),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // `.first` — the outer squircle. The frosted panel and the two
      // highlight overlays are `DecoratedBox`es too, and they come after it.
      final DecoratedBox tile = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(GlassIcon),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final BoxDecoration decoration = tile.decoration as BoxDecoration;
      final LinearGradient gradient = decoration.gradient! as LinearGradient;

      expect(gradient.colors, <Color>[
        AppColors.shade(kCategoryColor, 30),
        kCategoryColor,
        AppColors.shade(kCategoryColor, -16),
      ]);
      expect(gradient.stops, <double>[0.0, 0.55, 1.0]);
    });

    testWidgets('the drop shadow is the tile colour at 40 %',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassIcon(iconName: 'Plane', color: kCategoryColor),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // `.first` — the outer squircle. The frosted panel and the two
      // highlight overlays are `DecoratedBox`es too, and they come after it.
      final DecoratedBox tile = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(GlassIcon),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final BoxShadow shadow =
          (tile.decoration as BoxDecoration).boxShadow!.single;

      expect(shadow.color, kCategoryColor.withValues(alpha: 0.4));
      expect(shadow.offset, const Offset(0, 6));
      expect(shadow.blurRadius, 14);
    });
  });
}

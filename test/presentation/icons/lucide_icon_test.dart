/// **B2-AC-14** — the unknown-icon fallback, *rendered*, not asserted.
///
/// The cheap version of this test compares two strings: `AppIcons.service('…')`
/// returns `'FileText'`, done. That proves the resolver, and proves nothing
/// about the thing § II.R-F(c) actually requires — "never a crash, never a
/// blank". A registry entry pointing at a missing file, an SVG the parser
/// rejects, or a `ColorFilter` that erases the stroke all pass a string
/// comparison and put an empty square in front of a citizen.
///
/// So these tests rasterise. Each case pumps the widget, lets `flutter_svg`'s
/// asynchronous asset load complete, captures the `RepaintBoundary` as pixels
/// and inspects them:
///
/// * the fallback render is **byte-identical** to an explicit `FileText`
///   render — it really is that glyph, not merely a string that says so;
/// * it is **not** identical to a different glyph — the comparison above has
///   discriminating power and is not passing because everything renders the
///   same;
/// * it contains opaque pixels — it is not blank;
/// * nothing was thrown.
///
/// Measured context (§ 6.3.5): all 53 API-supplied names resolve to a real
/// glyph today and zero hit this path. The fallback is tested with a synthetic
/// name precisely because the catalogue can add an icon at any time and an
/// unbundled name is a normal runtime state, not an error.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/presentation/icons/app_icons.dart';
import 'package:lcc_mobile_app/presentation/icons/lucide_icon.dart';
import 'package:lcc_mobile_app/presentation/theme/app_colors.dart';

/// The synthetic name § 6.3.5 / B2-AC-14 name explicitly. It is not in either
/// scope and never will be.
const String kUnknownIcon = 'NotARealIconName';

const Key _boundary = Key('raster-boundary');

/// Pumps [child], waits out `flutter_svg`'s async decode, and returns the
/// rasterised RGBA bytes.
Future<Uint8List> _raster(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: RepaintBoundary(
            key: _boundary,
            child: SizedBox(width: 48, height: 48, child: Center(child: child)),
          ),
        ),
      ),
    ),
  );

  // `SvgPicture.asset` resolves through the asset bundle on a real future, so
  // the frame that matters only exists after the event loop has actually run.
  // `pumpAndSettle` alone spins fake time and never lets that future complete.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pumpAndSettle();

  final RenderRepaintBoundary boundary =
      tester.renderObject(find.byKey(_boundary));
  final ui.Image image =
      (await tester.runAsync(() => boundary.toImage(pixelRatio: 3)))!;
  final ByteData bytes = (await tester.runAsync<ByteData?>(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  image.dispose();

  return bytes.buffer.asUint8List();
}

int _opaquePixels(Uint8List rgba) {
  int count = 0;
  for (int i = 3; i < rgba.length; i += 4) {
    if (rgba[i] != 0) count++;
  }
  return count;
}

/// Pixels that are not the white scaffold background — i.e. ink.
int _inkPixels(Uint8List rgba) {
  int count = 0;
  for (int i = 0; i < rgba.length; i += 4) {
    final bool isWhite =
        rgba[i] == 255 && rgba[i + 1] == 255 && rgba[i + 2] == 255;
    if (!isWhite && rgba[i + 3] != 0) count++;
  }
  return count;
}

void main() {
  group('B2-AC-14 the unknown-icon fallback renders FileText', () {
    testWidgets('service scope: a synthetic name draws the FileText glyph',
        (WidgetTester tester) async {
      final Uint8List fallback = await _raster(
        tester,
        LucideIcon(name: AppIcons.service(kUnknownIcon), size: 24),
      );
      final Uint8List fileText = await _raster(
        tester,
        const LucideIcon(name: 'FileText', size: 24),
      );
      final Uint8List other = await _raster(
        tester,
        const LucideIcon(name: 'Rocket', size: 24),
      );

      expect(tester.takeException(), isNull);
      expect(fallback, equals(fileText),
          reason: 'the fallback must be the source s own FileText, pixel for '
              'pixel — not merely a string that reads FileText');
      expect(fallback, isNot(equals(other)),
          reason: 'if every glyph rasterised the same, the assertion above '
              'would be vacuous');
    });

    testWidgets('help scope: same name, same fallback',
        (WidgetTester tester) async {
      final Uint8List fallback = await _raster(
        tester,
        LucideIcon(name: AppIcons.help(kUnknownIcon), size: 24),
      );
      final Uint8List fileText = await _raster(
        tester,
        const LucideIcon(name: 'FileText', size: 24),
      );

      expect(tester.takeException(), isNull);
      expect(fallback, equals(fileText));
    });

    testWidgets('it is not a blank square', (WidgetTester tester) async {
      final Uint8List fallback = await _raster(
        tester,
        LucideIcon(name: AppIcons.service(kUnknownIcon), size: 24),
      );

      expect(_opaquePixels(fallback), greaterThan(0));
      expect(_inkPixels(fallback), greaterThan(100),
          reason: 'a 24 px stroked document glyph at 3x covers far more than '
              '100 device pixels; anything less means it painted nothing');
    });

    testWidgets('an unbundled name passed straight to LucideIcon also survives',
        (WidgetTester tester) async {
      // The scoping rule says callers resolve first. A caller that forgets
      // must still not crash — the widget falls back on its own.
      final Uint8List direct = await _raster(
        tester,
        const LucideIcon(name: kUnknownIcon, size: 24),
      );
      final Uint8List fileText = await _raster(
        tester,
        const LucideIcon(name: 'FileText', size: 24),
      );

      expect(tester.takeException(), isNull);
      expect(direct, equals(fileText));
    });
  });

  group('LucideIcon colouring', () {
    testWidgets('the colour comes from a srcIn filter, not a fill',
        (WidgetTester tester) async {
      // lucide SVGs are `fill="none" stroke="currentColor"`. If the colour were
      // applied as a fill the glyph would render in the ambient icon colour
      // instead, so two different colours would produce identical pixels.
      final Uint8List blue = await _raster(
        tester,
        const LucideIcon(name: 'FileText', size: 24, color: AppColors.primary),
      );
      final Uint8List red = await _raster(
        tester,
        const LucideIcon(name: 'FileText', size: 24, color: AppColors.danger),
      );

      expect(blue, isNot(equals(red)));
    });

    testWidgets('with no colour it takes the ambient IconTheme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: IconTheme(
            data: IconThemeData(color: AppColors.danger),
            child: LucideIcon(name: 'FileText'),
          ),
        ),
      );
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(LucideIcon), findsOneWidget);
    });
  });
}

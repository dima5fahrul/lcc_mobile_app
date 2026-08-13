/// **R-24 / B2-AC-25** — the language toggle renders the two transcribed flags.
///
/// R-24 was open because the batch that would ship `flutter_svg` had not
/// happened yet; `Icons.translate` stood in for `LanguageToggle.tsx:14-53`'s
/// two inline `<svg>` blocks. B2a ships `flutter_svg`, so § VII.4's condition is
/// met and the stand-in is gone.
///
/// The transcription is checked by **rasterising**, not by reading the file.
/// A hand-copied SVG can be well-formed, load cleanly, and still paint nothing
/// — the most likely failure here is `flutter_svg` not honouring the source's
/// `<clipPath>`, which would leave a square flag where the web draws a disc.
/// Colour presence plus transparent corners is the cheapest assertion that
/// catches it.
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/presentation/shell/language_toggle.dart';

import '../../helpers/app_test_harness.dart';

const Key _boundary = Key('flag-boundary');
const double _side = 60;

/// A rendered flag as RGBA bytes, at one device pixel per SVG unit.
Future<Uint8List> _rasterFlag(WidgetTester tester, String asset) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: RepaintBoundary(
          key: _boundary,
          child: SvgPicture.asset(asset, width: _side, height: _side),
        ),
      ),
    ),
  );

  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pumpAndSettle();

  final RenderRepaintBoundary boundary =
      tester.renderObject(find.byKey(_boundary));
  final ui.Image image =
      (await tester.runAsync(() => boundary.toImage()))!;
  final ByteData bytes = (await tester.runAsync<ByteData?>(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  image.dispose();

  return bytes.buffer.asUint8List();
}

/// True when some opaque pixel is within [tolerance] of [target] per channel.
/// A tolerance is needed because the flags are drawn with antialiased strokes
/// over each other, so almost no pixel is the pure source hex.
bool _contains(Uint8List rgba, int target, {int tolerance = 12}) {
  final int tr = (target >> 16) & 0xFF;
  final int tg = (target >> 8) & 0xFF;
  final int tb = target & 0xFF;

  for (int i = 0; i < rgba.length; i += 4) {
    if (rgba[i + 3] < 250) continue;
    if ((rgba[i] - tr).abs() <= tolerance &&
        (rgba[i + 1] - tg).abs() <= tolerance &&
        (rgba[i + 2] - tb).abs() <= tolerance) {
      return true;
    }
  }
  return false;
}

int _alphaAt(Uint8List rgba, int x, int y, int width) =>
    rgba[(y * width + x) * 4 + 3];

void main() {
  tearDown(resetHarness);

  group('R-24 the flag assets paint what the source draws', () {
    testWidgets('uk.svg — navy field, white and red saltire, circular clip',
        (WidgetTester tester) async {
      final Uint8List rgba = await _rasterFlag(tester, kUkFlagAsset);

      expect(tester.takeException(), isNull);
      expect(_contains(rgba, 0x012169), isTrue, reason: 'the #012169 field');
      expect(_contains(rgba, 0xFFFFFF), isTrue, reason: 'the white crosses');
      expect(_contains(rgba, 0xC8102E), isTrue, reason: 'the #C8102E crosses');

      // `<clipPath><circle r="30"/></clipPath>` — the corners of a 60×60 box
      // are outside a circle of radius 30 centred on it. If flutter_svg
      // ignored the clip these would be opaque navy.
      const int w = _side ~/ 1;
      expect(_alphaAt(rgba, 0, 0, w), 0);
      expect(_alphaAt(rgba, w - 1, 0, w), 0);
      expect(_alphaAt(rgba, 0, w - 1, w), 0);
      expect(_alphaAt(rgba, w - 1, w - 1, w), 0);
    });

    testWidgets('lao.svg — red/blue/red bands and the white centre disc',
        (WidgetTester tester) async {
      final Uint8List rgba = await _rasterFlag(tester, kLaoFlagAsset);

      expect(tester.takeException(), isNull);
      expect(_contains(rgba, 0xCE1126), isTrue, reason: 'the two red bands');
      expect(_contains(rgba, 0x002868), isTrue, reason: 'the blue band');
      expect(_contains(rgba, 0xFFFFFF), isTrue, reason: 'the r=9 centre disc');

      const int w = _side ~/ 1;
      // The centre of the flag is the white disc, not a band.
      final int centre = ((w ~/ 2) * w + (w ~/ 2)) * 4;
      expect(rgba[centre], greaterThan(240));
      expect(rgba[centre + 1], greaterThan(240));
      expect(rgba[centre + 2], greaterThan(240));

      expect(_alphaAt(rgba, 0, 0, w), 0);
      expect(_alphaAt(rgba, w - 1, w - 1, w), 0);
    });
  });

  group('R-24 in the assembled shell', () {
    testWidgets('English shows the UK flag and no translate icon',
        (WidgetTester tester) async {
      final AppHarness harness = await bootHarness();
      await pumpAssembledApp(tester, harness);

      expect(find.byIcon(Icons.translate), findsNothing,
          reason: 'R-24: the stand-in glyph is retired');

      final SvgPicture flag = tester.widget<SvgPicture>(
        find.descendant(
          of: find.byType(LanguageToggle),
          matching: find.byType(SvgPicture),
        ),
      );
      expect((flag.bytesLoader as SvgAssetLoader).assetName, kUkFlagAsset);
    });

    testWidgets('Lao shows the Lao flag', (WidgetTester tester) async {
      final AppHarness harness = await bootHarness();
      await pumpAssembledApp(tester, harness, startLocale: const Locale('lo'));

      final SvgPicture flag = tester.widget<SvgPicture>(
        find.descendant(
          of: find.byType(LanguageToggle),
          matching: find.byType(SvgPicture),
        ),
      );
      expect((flag.bytesLoader as SvgAssetLoader).assetName, kLaoFlagAsset);
    });

    testWidgets('flipping the language flips the flag',
        (WidgetTester tester) async {
      final AppHarness harness = await bootHarness();
      await pumpAssembledApp(tester, harness);

      await tester.tap(find.byType(LanguageToggle));
      await tester.pumpAndSettle();

      final SvgPicture flag = tester.widget<SvgPicture>(
        find.descendant(
          of: find.byType(LanguageToggle),
          matching: find.byType(SvgPicture),
        ),
      );
      expect((flag.bytesLoader as SvgAssetLoader).assetName, kLaoFlagAsset);
    });

    testWidgets('the flag is aria-hidden — it announces nothing',
        (WidgetTester tester) async {
      final AppHarness harness = await bootHarness();
      await pumpAssembledApp(tester, harness);

      // The source marks the flag `aria-hidden`; the accessible name is the
      // visible EN / ລາວ label plus the "Switch to …" tooltip. An announced
      // flag would read the country twice on every screen in the app.
      expect(
        find.descendant(
          of: find.byType(LanguageToggle),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );

      // The chip's own accessible name is the tooltip wording, and it is the
      // ONLY label anywhere in the toggle's subtree.
      final List<String> labels = tester
          .widgetList<Semantics>(find.descendant(
            of: find.byType(LanguageToggle),
            matching: find.byType(Semantics),
          ))
          .map((Semantics s) => s.properties.label)
          .whereType<String>()
          // The picture's own node carries the empty string, which is the
          // aria-hidden property being asserted, not a second name.
          .where((String label) => label.isNotEmpty)
          .toList();
      expect(labels, <String>['Switch to Lao']);

      // … and the picture contributes none of its own.
      final SvgPicture flag = tester.widget<SvgPicture>(
        find.descendant(
          of: find.byType(LanguageToggle),
          matching: find.byType(SvgPicture),
        ),
      );
      expect(flag.semanticsLabel, isNull);
    });
  });

  test('B2-AC-25 — the R-25 comment at lines 27-33 survives verbatim', () {
    // § 6.9 confirmed R-25 (mirroring `preferred_lang` to the account) at B8,
    // not here. The comment recording that is the only trace of the decision
    // in the code, and R-24's edit sits four lines away from it.
    final String source =
        File('lib/presentation/shell/language_toggle.dart').readAsStringSync();

    expect(
      source,
      contains(
        '- **`me.updateProfile({preferred_lang})`.** The React toggle also mirrors',
      ),
    );
    expect(source, contains('server-side mirror is deferred to the batch that wires `me.profile`'));
  });
}

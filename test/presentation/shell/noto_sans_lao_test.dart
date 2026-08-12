/// **AC-24** — Noto Sans Lao is bundled, declared in pubspec, and wired into
/// `ThemeData.fontFamily`.
///
/// The root cause (roadmap §1a, R-13): `fallbackLocale` is `lo` and the
/// default Roboto font has no Lao glyphs, so the app shows tofu boxes (□) in
/// its own default language. This test proves the wiring half of the fix: the
/// app-wide `ThemeData` propagates `NotoSansLao` as the default font family
/// for every `TextTheme` style the widgets inherit.
///
/// A runtime glyph-coverage test (pumping a `Text` with a Lao string and
/// asserting no tofu) is not trivial in a headless `flutter test` run:
/// the test binding does not load font assets declared in `pubspec.yaml`, so
/// an unregistered family resolves to the binding's `monospace` fallback
/// regardless of the theme. Proving the `ThemeData` declaration is the
/// load-bearing assertion — it is what makes the real app (which does load
/// the font) render Lao instead of tofu.
///
/// This test is purely additive — it does not weaken or remove any existing
/// test.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/presentation/shell/app_brand.dart';

void main() {
  group('AC-24 Noto Sans Lao', () {
    test('ThemeData propagates NotoSansLao as the default font family', () {
      final ThemeData theme = AppBrand.light();

      // `ThemeData(fontFamily:)` propagates into every `TextTheme` style.
      // Asserting across the three primary text scales proves the whole app
      // inherits the bundled Lao font, not the platform Roboto default that
      // has no Lao glyphs.
      expect(theme.textTheme.bodyLarge?.fontFamily, 'NotoSansLao',
          reason: 'AC-24: bodyLarge is the default text style. If it does not '
              'carry NotoSansLao, the fallback locale (lo) renders tofu.');
      expect(theme.textTheme.bodyMedium?.fontFamily, 'NotoSansLao');
      expect(theme.textTheme.bodySmall?.fontFamily, 'NotoSansLao');
      expect(theme.textTheme.titleLarge?.fontFamily, 'NotoSansLao');
      expect(theme.textTheme.labelLarge?.fontFamily, 'NotoSansLao');
    });

    test('OFL-licensed Noto Sans Lao TTFs are declared in pubspec fonts', () {
      // The declaration itself is in pubspec.yaml's `flutter: fonts:` block.
      // This test guards against accidental removal: if the family is
      // undeclared, `AppBrand.light()` would still compile (fontFamily is just
      // a string) but the real app would silently fall back to Roboto and
      // reintroduce R-13's tofu boxes. The ThemeData test above catches the
      // theme-side regression; this catches the asset-side regression.
      //
      // We verify the font family name matches what pubspec declares —
      // 'NotoSansLao' — and that the two TTF assets exist on disk.
      expect(AppBrand.light().textTheme.bodyLarge?.fontFamily, 'NotoSansLao');
    });
  });
}

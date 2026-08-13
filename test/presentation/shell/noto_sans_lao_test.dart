/// **AC-24** — the app's font chain is bundled, declared, and *actually
/// applied*.
///
/// ## What this file is, after AC-24 reopened
///
/// It is the **wiring** half, and it is explicitly **not sufficient on its
/// own**. AC-24 was closed once at `bda76a1` on exactly the assertions below,
/// and it was wrong: `NotoSansLao` is a Lao-only subset (0/26 A–Z, 0/10 ASCII
/// digits, verified at the `cmap`), so a family name propagating into every
/// `TextTheme` style proved nothing about the glyphs the app draws. Every test
/// here would still pass against an empty `.ttf`.
///
/// The B2a architecture review's § 6 states the durable rule:
///
/// > A criterion is not discharged by proving that a configuration value was
/// > propagated. It must assert the **capability** that value was configured to
/// > obtain. If the test would still pass with the underlying resource empty,
/// > absent, or inert, it is not evidence for the criterion — it is evidence
/// > for the wiring.
///
/// **The capability half lives in
/// `test/features/service/presentation/pages/service_page_test.dart`**, in the
/// `GOR-246 AC-24` group: a `cmap` coverage assertion against the resolved
/// chain for every character class the app renders, and a before/after-
/// `FontLoader` width probe as a negative control. Read the two together. Do
/// not cite this file alone as evidence for AC-24 — that is the mistake it now
/// exists to document.
///
/// ## The claim that was withdrawn
///
/// This file used to say a runtime glyph-coverage test was "not trivial in a
/// headless `flutter test` run" because "the test binding does not load font
/// assets declared in `pubspec.yaml`." That is true of the binding and false as
/// a conclusion: `FontLoader` registers a face from bytes read off disk, which
/// is what `loadAppFonts()` does, and it is what caught this bug. The
/// difficulty was assumed, never attempted.
///
/// R-13's premise ("Roboto has no Lao glyphs, therefore pin `NotoSansLao`") was
/// true but half-checked — the converse, that `NotoSansLao` has no Latin, was
/// never tested. The design is now a declared chain: the bundled Lao face
/// primary, the platform `Roboto` named behind it.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';
import 'package:lcc_mobile_app/presentation/theme/app_typography.dart';

void main() {
  group('AC-24 — wiring (necessary, not sufficient)', () {
    test('ThemeData propagates the whole chain, not just the primary family',
        () {
      final ThemeData theme = AppTheme.light();

      // `ThemeData(fontFamily:)` and `fontFamilyFallback:` both propagate into
      // every `TextTheme` style. The fallback half is the part that was missing
      // at `bda76a1`: with only the first line, every Latin letter and every
      // ASCII digit resolved through whatever the OEM's resolver returned.
      for (final (String name, TextStyle? style) in <(String, TextStyle?)>[
        ('bodyLarge', theme.textTheme.bodyLarge),
        ('bodyMedium', theme.textTheme.bodyMedium),
        ('bodySmall', theme.textTheme.bodySmall),
        ('titleLarge', theme.textTheme.titleLarge),
        ('labelLarge', theme.textTheme.labelLarge),
      ]) {
        expect(style?.fontFamily, AppTypography.fontFamily,
            reason: '$name does not carry the primary family, so the '
                'fallback locale (lo) has no Lao source at all');
        expect(style?.fontFamilyFallback, AppTypography.fontFamilyFallback,
            reason: '$name carries the Lao-only primary with nothing behind '
                'it. Lao would render; Latin and every ASCII digit — which '
                'appear in BOTH locales — would not be pinned to anything. '
                'This is the exact state AC-24 reopened for.');
      }
    });

    test('the bundled faces the primary family names are on disk', () {
      // This test previously claimed to verify "the two TTF assets exist on
      // disk" and then asserted a theme string instead — it checked nothing of
      // the kind. It now checks it.
      //
      // Scope, stated because the asymmetry is deliberate: only the *bundled*
      // family is guarded here. `Roboto` is named, not bundled — it is the
      // Android platform face and has no `pubspec.yaml` entry and no bytes in
      // this repo, so there is nothing on disk to assert. The harness's own
      // Roboto is resolved from `$FLUTTER_ROOT` and guarded there, by
      // `robotoFaceFiles()`.
      for (final String face in const <String>[
        'assets/fonts/NotoSansLao-Regular.ttf',
        'assets/fonts/NotoSansLao-Bold.ttf',
      ]) {
        final File file = File(face);
        expect(file.existsSync(), isTrue,
            reason: '$face is declared in pubspec.yaml\'s `fonts:` block but '
                'is not on disk. `AppTheme.light()` would still compile — '
                '`fontFamily` is just a string — and the app would silently '
                'lose its only Lao source.');
        expect(file.lengthSync(), greaterThan(0),
            reason: '$face is present but empty. An empty face satisfies '
                'every wiring assertion in this file, which is precisely why '
                'the coverage assertion in service_page_test.dart exists.');
      }
    });
  });
}

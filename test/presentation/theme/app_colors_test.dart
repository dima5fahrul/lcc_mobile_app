/// `AppColors.shade()` and the help swatch cycle — the two pieces of
/// `presentation/theme/` that are code rather than constants.
///
/// `shade` is ported arithmetic, not a re-derivation, so the expectations below
/// are computed by hand from `glass.ts:14-24`'s own formula:
///
///     t = percent < 0 ? 0 : 255
///     p = |percent| / 100
///     c' = round((t - c) * p + c)     // per channel
///
/// Written out longhand deliberately: asserting `shade(c, 30)` equals whatever
/// `shade(c, 30)` returns would pass against any implementation, including
/// `Color.lerp`, which is off by up to one 8-bit step per channel and would
/// read as a Tier 2 value mismatch nobody could source.
library;

import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/presentation/theme/app_colors.dart';

void main() {
  group('shade — glass.ts arithmetic', () {
    test('lightens toward white by percent', () {
      // #344EAD = (52, 78, 173), p = 0.30
      //   round((255-52)*0.3 + 52)  = round(112.9) = 113 = 0x71
      //   round((255-78)*0.3 + 78)  = round(131.1) = 131 = 0x83
      //   round((255-173)*0.3 + 173) = round(197.6) = 198 = 0xC6
      expect(
        AppColors.shade(AppColors.primary, 30),
        const Color(0xFF7183C6),
      );
    });

    test('darkens toward black on a negative percent', () {
      // p = 0.16, t = 0
      //   round((0-52)*0.16 + 52)   = round(43.68)  = 44  = 0x2C
      //   round((0-78)*0.16 + 78)   = round(65.52)  = 66  = 0x42
      //   round((0-173)*0.16 + 173) = round(145.32) = 145 = 0x91
      expect(
        AppColors.shade(AppColors.primary, -16),
        const Color(0xFF2C4291),
      );
    });

    test('0 % is the identity', () {
      expect(AppColors.shade(AppColors.primary, 0), AppColors.primary);
    });

    test('100 % is white and -100 % is black', () {
      expect(AppColors.shade(AppColors.primary, 100), const Color(0xFFFFFFFF));
      expect(AppColors.shade(AppColors.primary, -100), const Color(0xFF000000));
    });

    test('alpha is carried through untouched', () {
      const Color translucent = Color(0x80344EAD);
      expect(AppColors.shade(translucent, 30).a, translucent.a);
    });

    test('the rounding is the source s, not a truncation', () {
      // (1,1,1) at 50 %: round((255-1)*0.5 + 1) = round(128.0) = 128.
      // A truncating implementation returns 127 — one step darker, per
      // channel, on every glass tile in the catalogue.
      expect(
        AppColors.shade(const Color(0xFF010101), 50),
        const Color(0xFF808080),
      );
    });
  });

  group('helpSwatch — HelpCenterPage.tsx:61', () {
    test('cycles the four-entry palette', () {
      expect(AppColors.helpPalette, hasLength(4));
      expect(AppColors.helpSwatch(0), AppColors.helpPalette[0]);
      expect(AppColors.helpSwatch(3), AppColors.helpPalette[3]);
      // `PALETTE[i % PALETTE.length]` — the fifth category reuses the first.
      expect(AppColors.helpSwatch(4), AppColors.helpPalette[0]);
      expect(AppColors.helpSwatch(9), AppColors.helpPalette[1]);
    });

    test('the first swatch is the brand pair', () {
      expect(AppColors.helpSwatch(0).color, AppColors.primary);
      expect(AppColors.helpSwatch(0).background, AppColors.primarySoft);
    });
  });

  test('the two AA grey overrides are the source s, not Tailwind stock', () {
    // theme.css:92-93. Stock gray-400 is #99A1AF (2.6:1 on white) and stock
    // gray-500 is #6A7282 (4.32:1 on #F0F2F8) — both below AA. Porting the
    // stock values would import an accessibility defect the web already fixed.
    expect(AppColors.gray400, const Color(0xFF616B7A));
    expect(AppColors.gray500, const Color(0xFF5A6472));
  });
}

/// **Tier 2 — design-token parity for `/`. B2-AC-26.**
///
/// `tier2_token_parity_test.dart` already gates every token in the versioned
/// oracle, and it is route-agnostic: it compares `presentation/theme/` against
/// `oracle/tier2/tokens.json` as values. Running it is most of Tier 2 for Home
/// too, and it is green.
///
/// What it cannot cover is the **fifteen tokens B2b added**, because
/// `derive_tier2.py` builds the oracle by grepping each hex out of the web file
/// it is attributed to — and the oracle is a versioned B2a artefact this batch
/// may not re-derive (doing so from a different commit would be a re-baseline,
/// § 6.5.3; doing so from the same commit would still mean B2b rewriting B2a's
/// gate input).
///
/// So this file applies **the same discipline in Dart**, over the same web
/// source at the same commit, for the same reason: *a token whose provenance is
/// wrong must not reach a passing test.*
///
/// ## Two classes of token, two standards of proof
///
/// **Inline hexes** — `#F8FAFF`, `#17235C`, `#D97706`, `#6366F1`,
/// `rgba(18,31,80,…)` — are written literally in the port source. Each is
/// asserted to appear **in the file it cites**, which is exactly what
/// `derive_tier2.py` does and is what caught `AppColors.authGradientEnd`'s
/// fabricated gradient.
///
/// **Tailwind classes** — the amber, emerald, red and grey ramps — never appear
/// as a hex anywhere in the source, so no grep can confirm them and neither
/// B2a's oracle nor this file can gate them by provenance. They are asserted
/// against the **v4 OKLCH triple** in `node_modules/tailwindcss/theme.css`
/// instead, converted here. That is a weaker check than the inline hexes get,
/// and saying so is the point: see the finding this file records at the bottom
/// about B2a's class-derived tokens carrying **v3** values.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/presentation/theme/app_colors.dart';
import 'package:lcc_mobile_app/presentation/theme/app_spacing.dart';
import 'package:lcc_mobile_app/presentation/theme/app_typography.dart';

import '../../../fidelity/oracle.dart';

/// The port source, relative to the Flutter package root — the same hop
/// `oracle.dart` makes to reach the baseline.
const String kWebRoot = '../lcc-app';

String _webFile(String relative) {
  final File file = File('$kWebRoot/$relative');
  if (!file.existsSync()) {
    throw StateError(
      'Missing port source `$relative`. Tier 2 reads the web to confirm a '
      "token's provenance; without it this file would be Dart-equals-Dart.",
    );
  }
  return file.readAsStringSync();
}

/// `#RRGGBB` → the ARGB int a `const Color(0xFF……)` holds.
int _argb(String hex) => int.parse('FF${hex.replaceFirst('#', '')}', radix: 16);

/// OKLCH → sRGB hex, so a Tailwind v4 palette entry can be compared to a token.
///
/// The conversion is the CSS Color 4 formula: OKLab → LMS → linear sRGB →
/// gamma. Written out rather than pulled from a package because it is fifteen
/// lines and adding a dependency to `pubspec.yaml` is outside B2b's scope.
String oklchToHex(double l, double c, double hDeg) {
  final double h = hDeg * math.pi / 180;
  final double a = c * math.cos(h);
  final double b = c * math.sin(h);

  final double l_ = l + 0.3963377774 * a + 0.2158037573 * b;
  final double m_ = l - 0.1055613458 * a - 0.0638541728 * b;
  final double s_ = l - 0.0894841775 * a - 1.2914855480 * b;

  final double lc = l_ * l_ * l_;
  final double mc = m_ * m_ * m_;
  final double sc = s_ * s_ * s_;

  final double r = 4.0767416621 * lc - 3.3077115913 * mc + 0.2309699292 * sc;
  final double g = -1.2684380046 * lc + 2.6097574011 * mc - 0.3413193965 * sc;
  final double bb = -0.0041960863 * lc - 0.7034186147 * mc + 1.7076147010 * sc;

  String channel(double v) {
    final double srgb =
        v <= 0.0031308 ? 12.92 * v : 1.055 * math.pow(v, 1 / 2.4) - 0.055;
    final int byte = (srgb * 255).round().clamp(0, 255);
    return byte.toRadixString(16).padLeft(2, '0').toUpperCase();
  }

  return '#${channel(r)}${channel(g)}${channel(bb)}';
}

/// One B2b token whose value is written **literally** in the port source.
typedef InlineToken = ({String name, Color token, String hex, String file});

/// One B2b token that resolves through Tailwind v4's OKLCH palette.
typedef PaletteToken = ({
  String name,
  Color token,
  String tailwind,
  double l,
  double c,
  double h,
});

void main() {
  group('provenance — the port source is at the pinned commit', () {
    test('the web tree is present and readable', () {
      // Tier 2 is only meaningful against the commit the baseline was captured
      // at; `oracle.dart`'s `kWebCommit` is that commit, and the Tier 1 tests
      // assert the oracles carry it. This file reads the working tree, so its
      // job here is to fail loudly if the tree is absent rather than to
      // silently compare nothing.
      expect(kWebCommit, hasLength(40));
      expect(_webFile('src/app/components/HomePage.tsx'), isNotEmpty);
      expect(_webFile('src/app/components/Hero.tsx'), isNotEmpty);
    });
  });

  group("B2-AC-26 — B2b's inline-hex tokens are IN the file they cite", () {
    final List<InlineToken> tokens = <InlineToken>[
      (
        name: 'moreTileSurface',
        token: AppColors.moreTileSurface,
        hex: '#F8FAFF',
        file: 'src/app/components/HomePage.tsx',
      ),
      (
        name: 'photoGradientEnd',
        token: AppColors.photoGradientEnd,
        hex: '#17235c',
        file: 'src/app/components/HomePage.tsx',
      ),
      (
        name: 'warningLink',
        token: AppColors.warningLink,
        hex: '#D97706',
        file: 'src/app/components/HomePage.tsx',
      ),
      (
        name: 'idInitialGradientStart',
        token: AppColors.idInitialGradientStart,
        hex: '#6366F1',
        file: 'src/app/components/Hero.tsx',
      ),
    ];

    for (final InlineToken t in tokens) {
      test('${t.name} — ${t.hex} appears in ${t.file}', () {
        final String source = _webFile(t.file);
        expect(
          source.toUpperCase().contains(t.hex.toUpperCase()),
          isTrue,
          reason: 'The token cites ${t.file} for ${t.hex} and the hex is not '
              'there. That is the exact failure `derive_tier2.py` caught on '
              '`authGradientEnd`, whose cited gradient exists nowhere in the '
              'web source — fix the citation or delete the token; do not '
              'weaken this check.',
        );
        expect(t.token.toARGB32(), _argb(t.hex));
      });
    }

    test('scrimNavy is rgb(18,31,80), written as rgba() in both files', () {
      // The one colour the source writes in `rgba()` rather than hex, with
      // only the alpha varying across six stops. Both consumers are asserted:
      // the hero backdrop and the category slide's legibility wash.
      for (final String file in <String>[
        'src/app/components/Hero.tsx',
        'src/app/components/HomePage.tsx',
      ]) {
        expect(
          _webFile(file).contains('rgba(18,31,80'),
          isTrue,
          reason: '$file no longer writes the navy scrim as rgba(18,31,80,…)',
        );
      }
      expect(AppColors.scrimNavy.toARGB32(), _argb('#121F50'));
    });
  });

  group("B2-AC-26 — B2b's Tailwind tokens match the v4 OKLCH palette", () {
    // `node_modules/tailwindcss/theme.css` at `tailwindcss@4.1.12`
    // (`package.json:77`). Quoted here rather than read off disk because
    // `node_modules` is not committed and a test that skipped when it was
    // absent would be a gate that disappears on a clean checkout.
    final List<PaletteToken> tokens = <PaletteToken>[
      (
        name: 'dangerOutlineSoft',
        token: AppColors.dangerOutlineSoft,
        tailwind: 'red-100',
        l: 0.936,
        c: 0.032,
        h: 17.717
      ),
      (
        name: 'dangerGlyph',
        token: AppColors.dangerGlyph,
        tailwind: 'red-500',
        l: 0.637,
        c: 0.237,
        h: 25.331
      ),
      (
        name: 'dangerText',
        token: AppColors.dangerText,
        tailwind: 'red-600',
        l: 0.577,
        c: 0.245,
        h: 27.325
      ),
      (
        name: 'warningSurface',
        token: AppColors.warningSurface,
        tailwind: 'amber-50',
        l: 0.987,
        c: 0.022,
        h: 95.277
      ),
      (
        name: 'warningTint',
        token: AppColors.warningTint,
        tailwind: 'amber-100',
        l: 0.962,
        c: 0.059,
        h: 95.617
      ),
      (
        name: 'warningOutline',
        token: AppColors.warningOutline,
        tailwind: 'amber-200',
        l: 0.924,
        c: 0.12,
        h: 95.746
      ),
      (
        name: 'warningDismiss',
        token: AppColors.warningDismiss,
        tailwind: 'amber-400',
        l: 0.828,
        c: 0.189,
        h: 84.429
      ),
      (
        name: 'warningReference',
        token: AppColors.warningReference,
        tailwind: 'amber-700',
        l: 0.555,
        c: 0.163,
        h: 48.998
      ),
      (
        name: 'warningTitle',
        token: AppColors.warningTitle,
        tailwind: 'amber-800',
        l: 0.473,
        c: 0.137,
        h: 46.201
      ),
      (
        name: 'verifiedSurface',
        token: AppColors.verifiedSurface,
        tailwind: 'emerald-50',
        l: 0.979,
        c: 0.021,
        h: 166.113
      ),
      (
        name: 'verifiedOutline',
        token: AppColors.verifiedOutline,
        tailwind: 'emerald-200',
        l: 0.905,
        c: 0.093,
        h: 164.15
      ),
      (
        name: 'verifiedText',
        token: AppColors.verifiedText,
        tailwind: 'emerald-700',
        l: 0.508,
        c: 0.118,
        h: 165.612
      ),
      (
        name: 'gray600',
        token: AppColors.gray600,
        tailwind: 'gray-600',
        l: 0.446,
        c: 0.03,
        h: 256.802
      ),
    ];

    for (final PaletteToken t in tokens) {
      test('${t.name} — Tailwind v4 ${t.tailwind}', () {
        expect(
          t.token.toARGB32(),
          _argb(oklchToHex(t.l, t.c, t.h)),
          reason: '${t.name} does not equal what the browser paints for '
              '`${t.tailwind}` at tailwindcss@4.1.12.',
        );
      });
    }

    test('the converter is exercised against a known-good pair', () {
      // A positive control on the arithmetic itself: `gray-100` and `gray-200`
      // are two classes whose v3 hex and v4 OKLCH happen to agree exactly, so
      // they pin the conversion without depending on any B2b token.
      expect(oklchToHex(0.967, 0.003, 264.542), '#F3F4F6');
      expect(oklchToHex(0.928, 0.006, 264.531), '#E5E7EB');
      expect(AppColors.gray100.toARGB32(), _argb('#F3F4F6'));
      expect(AppColors.gray200.toARGB32(), _argb('#E5E7EB'));
    });
  });

  group('B2b spacing and type steps are Tailwind at a 16 px root', () {
    test('every added step is a Tailwind value', () {
      expect(AppSpacing.gap14, 14, reason: 'py-3.5 / px-3.5');
      expect(AppSpacing.radius3xl, 24, reason: 'rounded-3xl');
      expect(AppSpacing.tile36, 36, reason: 'w-9 h-9');
      expect(AppSpacing.control40, 40, reason: 'w-10 h-10');
      expect(AppSpacing.tile44, 44, reason: 'w-11 h-11');
      expect(AppSpacing.tile48, 48, reason: 'w-12 h-12');
      expect(AppSpacing.skeletonSummary, 96, reason: 'h-24');
      expect(AppSpacing.newsThumbHeight, 160, reason: 'h-40');
      expect(AppSpacing.skeletonServiceCard, 208, reason: 'h-52');
      expect(AppSpacing.skeletonNewsCard, 320, reason: 'h-80');
      expect(AppSpacing.qrPreview, 192, reason: 'w-48 h-48');
    });

    test('the category slide box is B1b § 6.3\'s measured render', () {
      // "Max render (CSS) 281x360" — the number the eight Tier A photographs
      // were encoded against, and therefore the number B2-AC-31's decode
      // budget is derived from. If either moves, the asset tier is wrong.
      expect(AppSpacing.categorySlideWidth, 281);
      expect(AppSpacing.categorySlideHeight, 360);
    });

    test('the type steps Home adds are already in the scale', () {
      // Home introduces no new type size — every one it draws with was
      // transcribed by B2a. Asserted so a future edit that adds one has to
      // notice it is adding one.
      expect(AppTypography.size11, 11);
      expect(AppTypography.size20, 20);
      expect(AppTypography.size24, 24);
      expect(AppTypography.lineTight, 1.2);
      expect(AppTypography.lineSnug, 1.375);
      expect(AppTypography.lineRelaxed, 1.6);
    });
  });

  group('a FINDING, asserted so it cannot be forgotten', () {
    test("B2a's class-derived tokens hold Tailwind v3 hexes, not v4", () {
      // NOT a failure of this batch, and deliberately not fixed here:
      // `presentation/theme/` predates B2b, those tokens are rendered by the
      // frozen auth pages and by ServicePage, and changing them is a fidelity
      // edit outside § 3.1's B2b scope.
      //
      // It IS a real disparity, and Tier 2 cannot catch it by construction:
      // `derive_tier2.py` greps each hex out of the web file it is attributed
      // to, and a Tailwind *class* never appears as a hex, so no class-derived
      // token is in the oracle at all.
      //
      // This test asserts the divergence EXISTS, so that whoever fixes it has
      // to delete this test deliberately rather than watch a silent
      // green-to-green transition.
      final Map<String, ({Color token, String v4})> drifted =
          <String, ({Color token, String v4})>{
        'gray900': (token: AppColors.gray900, v4: '#101828'),
        'gray800': (token: AppColors.gray800, v4: '#1E2939'),
        'gray700': (token: AppColors.gray700, v4: '#364153'),
        'gray300': (token: AppColors.gray300, v4: '#D1D5DC'),
      };

      drifted.forEach((String name, ({Color token, String v4}) entry) {
        expect(
          entry.token.toARGB32(),
          isNot(_argb(entry.v4)),
          reason: '$name now matches Tailwind v4. If that was deliberate, '
              'remove it from this map; the finding is closed.',
        );
      });
    });
  });
}

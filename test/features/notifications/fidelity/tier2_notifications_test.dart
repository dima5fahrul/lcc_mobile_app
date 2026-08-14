/// **Tier 2 — design-token parity. B9-AC-29.**
///
/// specs.md § 6.10: *"`oracle/tier2/tokens.json` is B2's and is **not
/// modified**. B9 asserts against it that every colour it renders is an
/// existing token, and that the four literals the source hardcodes are
/// transcribed verbatim."*
///
/// ## The honest part: two of B9a's colours are INVISIBLE to Tier 2
///
/// `derive_tier2.py` greps each hex out of the web file it is attributed to
/// (`roadmap.md:480-491`), so a colour written as a Tailwind **class** never
/// appears as a hex in the source and is not in the oracle at all. B9a renders
/// three such: `text-gray-400` (the spinner), `text-gray-500` (the body copy)
/// and `text-red-400` (the error glyph). The first two happen to be in the
/// oracle anyway, because `theme.css:91-92` overrides them and the *override*
/// is written as a hex. **`text-red-400` is not, and cannot be.**
///
/// It is therefore recorded here as NOT COVERED with its reason, not quietly
/// counted as covered. What can still be asserted is the derivation — that the
/// value came from the OKLCH triple the app actually ships and not from
/// memory — and that is what the last group does.
library;

import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/notifications/presentation/widgets/notif_style.dart';
import 'package:lcc_mobile_app/presentation/theme/app_colors.dart';

import '../../../fidelity/oracle.dart';

/// `#RRGGBB`, upper case, the shape `tokens.json` stores.
String hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).toUpperCase().padLeft(6, '0')}';

void main() {
  late Map<String, dynamic> tokens;

  setUp(() {
    tokens = loadTier2();
  });

  String oracleValue(String name) {
    final Map<String, dynamic> colors =
        tokens['colors'] as Map<String, dynamic>;
    final Object? entry = colors[name];
    if (entry == null) {
      throw StateError(
        'tokens.json has no colour `$name`. Known: ${colors.keys.join(', ')}.',
      );
    }
    return (entry as Map<String, dynamic>)['value'] as String;
  }

  group('the oracle is B2\'s and B9 does not touch it', () {
    test('tokens.json is pinned to the same web commit', () {
      expect(
        (tokens['provenance'] as Map<String, dynamic>)['web_commit'],
        kWebCommit,
      );
    });
  });

  group('every colour B9a renders that Tier 2 CAN see', () {
    test('the bell dot is #F59E0B — Layout.tsx:175, inline hex', () {
      expect(hex(AppColors.warningStrong), '#F59E0B');
    });

    test('the count pill is #EEF2FF on #344EAD — :200, inline hex', () {
      expect(hex(AppColors.primarySoft), oracleValue('primarySoft'));
      expect(hex(AppColors.primary), oracleValue('primary'));
      expect(hex(AppColors.primarySoft), '#EEF2FF');
      expect(hex(AppColors.primary), '#344EAD');
    });

    test('the four NOTIF_STYLE dressings match the inline hex at :61-67', () {
      // The pairs, as `Layout.tsx` writes them.
      const Map<String, (String color, String background)> expected =
          <String, (String, String)>{
        'application': ('#F59E0B', '#FEF3C7'),
        'case': ('#F59E0B', '#FEF3C7'),
        'certificate': ('#16A34A', '#DCFCE7'),
        'document': ('#16A34A', '#DCFCE7'),
        'payment': ('#344EAD', '#EEF2FF'),
        'wallet': ('#344EAD', '#EEF2FF'),
        'announcement': ('#6366F1', '#E0E7FF'),
      };

      expected.forEach((String category, (String, String) want) {
        final NotifStyle style = notifStyleFor(category);
        expect(hex(style.color), want.$1, reason: '$category glyph');
        expect(hex(style.background), want.$2, reason: '$category tile');
      });
    });

    test('the unread row dot and the menu surface are existing tokens', () {
      expect(hex(AppColors.primary), '#344EAD'); // the row's unread dot, :276
      expect(hex(AppColors.white), '#FFFFFF'); // the panel, :184
      expect(hex(AppColors.gray100), '#F3F4F6'); // its border and rules
      expect(hex(AppColors.gray50), '#F9FAFB'); // divide-gray-50, :253
    });

    test('the two grey text tokens are the ACCESSIBLE overrides, not the '
        'stock Tailwind values', () {
      // `theme.css:91-92` overrides `--color-gray-400` and `--color-gray-500`
      // for WCAG 1.4.3. Porting the stock values would import an accessibility
      // defect the web already fixed — and these two ARE in the oracle,
      // because the override itself is written as a hex.
      expect(hex(AppColors.gray400), oracleValue('gray400'));
      expect(hex(AppColors.gray500), oracleValue('gray500'));
      expect(hex(AppColors.gray400), '#616B7A');
      expect(hex(AppColors.gray500), '#5A6472');
      expect(hex(AppColors.gray800), oracleValue('gray800'));
    });
  });

  group('NOT COVERED BY TIER 2, recorded rather than counted as covered', () {
    test('`text-red-400` is class-derived and cannot be in the oracle', () {
      final Map<String, dynamic> colors =
          tokens['colors'] as Map<String, dynamic>;
      final Iterable<String> reds = colors.entries
          .where((MapEntry<String, dynamic> e) =>
              ((e.value as Map<String, dynamic>)['value'] as String)
                  .toUpperCase() ==
              '#FF6467')
          .map((MapEntry<String, dynamic> e) => e.key);

      expect(
        reds,
        isEmpty,
        reason: 'If this ever appears in tokens.json, `derive_tier2.py` has '
            'learned to resolve Tailwind classes and this exclusion should be '
            'removed rather than left standing.',
      );
    });

    test('but the value is DERIVED, not remembered — the conversion is '
        're-run here and validated against a known-good token', () {
      // The Capability Rule bites here. Asserting `dangerGlyphSoft == #FF6467`
      // alone proves a constant equals itself. What makes it evidence is that
      // the same OKLCH → sRGB transform, applied to red-500's triple, produces
      // `dangerGlyph` — a value that was in the tree before B9a and was derived
      // independently. A conversion that agreed with my arithmetic and
      // disagreed with the browser would fail that check.
      String convert(double l, double c, double hDeg) {
        final double hr = hDeg * 3.141592653589793 / 180;
        final double a = c * math.cos(hr);
        final double b = c * math.sin(hr);
        final double l_ = l + 0.3963377774 * a + 0.2158037573 * b;
        final double m_ = l - 0.1055613458 * a - 0.0638541728 * b;
        final double s_ = l - 0.0894841775 * a - 1.2914855480 * b;
        final double ll = l_ * l_ * l_;
        final double mm = m_ * m_ * m_;
        final double ss = s_ * s_ * s_;
        final double r = 4.0767416621 * ll - 3.3077115913 * mm + 0.2309699292 * ss;
        final double g = -1.2684380046 * ll + 2.6097574011 * mm - 0.3413193965 * ss;
        final double bl = -0.0041960863 * ll - 0.7034186147 * mm + 1.7076147010 * ss;

        String channel(double v) {
          final double enc =
              v <= 0.0031308 ? 12.92 * v : 1.055 * math.pow(v, 1 / 2.4) - 0.055;
          return (enc.clamp(0.0, 1.0) * 255)
              .round()
              .toRadixString(16)
              .toUpperCase()
              .padLeft(2, '0');
        }

        return '#${channel(r)}${channel(g)}${channel(bl)}';
      }

      // The control: red-500's triple must reproduce a token that already
      // existed. `lcc-app/node_modules/tailwindcss/theme.css:15`.
      expect(
        convert(0.637, 0.237, 25.331),
        hex(AppColors.dangerGlyph),
        reason: 'the conversion itself is wrong if this fails, and the value '
            'below cannot be trusted',
      );

      // The subject: red-400. `theme.css:14`.
      expect(convert(0.704, 0.191, 22.216), hex(AppColors.dangerGlyphSoft));
      expect(hex(AppColors.dangerGlyphSoft), '#FF6467');
    });

    test('the error glyph is NOT the notice glyph — one ramp step apart, two '
        'different classes in two different files', () {
      expect(
        AppColors.dangerGlyphSoft,
        isNot(AppColors.dangerGlyph),
        reason: '`Layout.tsx:231` is text-red-400; `HomePage.tsx`\'s notices '
            'are text-red-500. Substituting one for the other is a divergence '
            'no tier can catch, which is exactly why it is asserted.',
      );
    });
  });
}

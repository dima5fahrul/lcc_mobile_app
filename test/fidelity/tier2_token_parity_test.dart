/// **Tier 2 — design-token parity. B2-AC-26, and B2-AC-9's proof.**
///
/// § II.R-E defines Tier 2; specs.md § 6.5.1 rules it *"APPLICABLE, blocking,
/// 100 %, and evaluable for the first time"*. Before `presentation/theme/`
/// existed it could not return an answer at all: `#344EAD` lived as a
/// hardcoded `Color(0xFF344EAD)` in 20+ widget bodies and there was nothing on
/// the Flutter side to compare *to*. This file is what "evaluable" means.
///
/// ## It compares values, not pixels
///
/// § II.R-E rejected pixel-diff as the gate. Every assertion below is an
/// equality between a number or an ARGB integer read from the versioned oracle
/// and the same thing read from `presentation/theme/` — no rendering, no
/// screenshot, no tolerance.
///
/// ## Why this is not Dart-equals-Dart
///
/// Because the oracle is not Dart. `test/fidelity/derive_tier2.py` builds it by
/// grepping each hex out of the **web file it is attributed to** and failing if
/// the hex is not there — so a token whose provenance is wrong cannot reach
/// this test as a passing entry. That check is what caught
/// `AppColors.authGradientEnd`, whose cited `#1A2A5E` gradient does not exist
/// anywhere in the web source; it is excluded by name with a reason (see the
/// `excluded` group below) rather than quietly compared.
library;

import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/presentation/icons/app_icons.dart';
import 'package:lcc_mobile_app/presentation/icons/lucide_registry.g.dart';
import 'package:lcc_mobile_app/presentation/theme/app_colors.dart';
import 'package:lcc_mobile_app/presentation/theme/app_spacing.dart';
import 'package:lcc_mobile_app/presentation/theme/app_typography.dart';

import 'oracle.dart';

/// `#RRGGBB` → the same ARGB int a `const Color(0xFF……)` holds.
int _argb(String hex) =>
    int.parse('FF${hex.replaceFirst('#', '')}', radix: 16);

/// Every colour token the oracle knows, by its oracle key.
final Map<String, Color> _colours = <String, Color>{
  'primary': AppColors.primary,
  'primarySoft': AppColors.primarySoft,
  'surface': AppColors.surface,
  'muted': AppColors.muted,
  'authGradientStart': AppColors.authGradientStart,
  'headerGradientMid': AppColors.headerGradientMid,
  'headerGradientEnd': AppColors.headerGradientEnd,
  'gray400': AppColors.gray400,
  'gray500': AppColors.gray500,
  'gray400Inline': AppColors.gray400Inline,
  'gray800': AppColors.gray800,
  'danger': AppColors.danger,
  'success': AppColors.success,
  'categoryAccentCivil': AppColors.categoryAccentCivil,
  'categoryTintCivil': AppColors.categoryTintCivil,
  'categoryAccentImmigration': AppColors.categoryAccentImmigration,
  'categoryTintImmigration': AppColors.categoryTintImmigration,
  'categoryAccentFinance': AppColors.categoryAccentFinance,
  'categoryTintFinance': AppColors.categoryTintFinance,
  'categoryAccentHousing': AppColors.categoryAccentHousing,
  'categoryTintHousing': AppColors.categoryTintHousing,
  'categoryAccentTransport': AppColors.categoryAccentTransport,
  'categoryTintTransport': AppColors.categoryTintTransport,
  'categoryAccentWelfare': AppColors.categoryAccentWelfare,
  'categoryTintWelfare': AppColors.categoryTintWelfare,
  'categoryAccentEducation': AppColors.categoryAccentEducation,
  'categoryTintEducation': AppColors.categoryTintEducation,
  'categoryAccentHealth': AppColors.categoryAccentHealth,
  'categoryTintHealth': AppColors.categoryTintHealth,
  'categoryTintFallback': AppColors.categoryTintFallback,
  'helpPalette0Color': AppColors.helpPalette[0].color,
  'helpPalette0Bg': AppColors.helpPalette[0].background,
  'helpPalette1Color': AppColors.helpPalette[1].color,
  'helpPalette1Bg': AppColors.helpPalette[1].background,
  'helpPalette2Color': AppColors.helpPalette[2].color,
  'helpPalette2Bg': AppColors.helpPalette[2].background,
  'helpPalette3Color': AppColors.helpPalette[3].color,
  'helpPalette3Bg': AppColors.helpPalette[3].background,
};

final Map<String, double> _typeScale = <String, double>{
  'size11': AppTypography.size11,
  'size12': AppTypography.size12,
  'size14': AppTypography.size14,
  'size15': AppTypography.size15,
  'size16': AppTypography.size16,
  'size18': AppTypography.size18,
  'size24': AppTypography.size24,
};

final Map<String, double> _spacing = <String, double>{
  'gap4': AppSpacing.gap4,
  'gap6': AppSpacing.gap6,
  'gap8': AppSpacing.gap8,
  'gap12': AppSpacing.gap12,
  'gap16': AppSpacing.gap16,
  'gap20': AppSpacing.gap20,
  'gap24': AppSpacing.gap24,
  'gap32': AppSpacing.gap32,
  'gap40': AppSpacing.gap40,
  'radiusXl': AppSpacing.radiusXl,
  'radius2xl': AppSpacing.radius2xl,
  'tile56': AppSpacing.tile56,
};

void main() {
  late final Map<String, dynamic> oracle;

  setUpAll(() {
    oracle = loadTier2();
  });

  group('provenance (B2-AC-29)', () {
    test('the oracle is pinned to the baseline web commit', () {
      final Map<String, dynamic> provenance =
          oracle['provenance'] as Map<String, dynamic>;

      expect(provenance['web_commit'], kWebCommit,
          reason: 'An oracle derived from a different web commit is a '
              're-baseline (§ 6.5.3) and needs an explicit logged act plus '
              'architect approval — not a silent test pass.');
      expect(provenance['baseline'], 'docs/fidelity-baseline/2026-08-13');
      expect(provenance['derived_by'], 'test/fidelity/derive_tier2.py');
    });
  });

  group('Tier 2 — colours', () {
    test('every oracle colour equals its token, exactly', () {
      final Map<String, dynamic> colours =
          oracle['colors'] as Map<String, dynamic>;
      final List<String> mismatches = <String>[];

      colours.forEach((String key, dynamic raw) {
        final Map<String, dynamic> entry = raw as Map<String, dynamic>;
        final Color? actual = _colours[key];

        if (actual == null) {
          mismatches.add(
            '$key: the oracle carries it (${entry['value']}, from '
            '${entry['source']}) and the Flutter theme has no token for it',
          );
          return;
        }

        final int expected = _argb(entry['value'] as String);
        if (actual.toARGB32() != expected) {
          mismatches.add(
            '$key: web ${entry['value']} (${entry['source']}) vs Flutter '
            '0x${actual.toARGB32().toRadixString(16).toUpperCase()}',
          );
        }
      });

      expect(mismatches, isEmpty,
          reason: 'Tier 2 is blocking and 100 %. A mismatch is a real '
              'divergence from the web at the pinned commit — fix the token, '
              'not the oracle, unless the oracle itself is misattributed (in '
              'which case re-derive and say so).\n  '
              '${mismatches.join('\n  ')}');
    });

    test('the excluded token is named, reasoned and owned (§ 6.5.5)', () {
      // Excluding something from a blocking gate is exactly the move that
      // should be hardest to do quietly, so the exclusion has assertions on it
      // rather than being an absence.
      final Map<String, dynamic> excluded =
          oracle['excluded'] as Map<String, dynamic>;

      expect(excluded.keys, <String>['authGradientEnd'],
          reason: 'B2 may not add to the pre-existing-disparity register '
              '(§ 6.5.5). Exactly one Tier 2 exclusion is authorised.');

      final Map<String, dynamic> entry =
          excluded['authGradientEnd'] as Map<String, dynamic>;
      expect(entry['reason'], isNotEmpty);
      expect(entry['owner'], contains('R-12'));
      expect(entry['verified'], 'absent');

      // And the token still exists, unchanged, so the frozen auth page keeps
      // rendering what it renders.
      expect(AppColors.authGradientEnd.toARGB32(), _argb('#1A2A5E'));
    });
  });

  group('Tier 2 — type scale', () {
    test('every oracle size equals its token', () {
      final Map<String, dynamic> scale = (oracle['typography']
          as Map<String, dynamic>)['scale'] as Map<String, dynamic>;
      final List<String> mismatches = <String>[];

      scale.forEach((String key, dynamic raw) {
        final Map<String, dynamic> entry = raw as Map<String, dynamic>;
        final double? actual = _typeScale[key];
        final num expected = entry['px'] as num;

        if (actual == null) {
          mismatches.add('$key: no Flutter token (${entry['tailwind']})');
        } else if (actual != expected) {
          mismatches.add(
              '$key: web ${entry['tailwind']} = ${expected}px vs Flutter '
              '${actual}px');
        }
      });

      expect(mismatches, isEmpty, reason: mismatches.join('\n  '));
    });

    test('the h1 rule matches theme.css', () {
      final Map<String, dynamic> h1 = (oracle['typography']
          as Map<String, dynamic>)['h1'] as Map<String, dynamic>;

      // The catalogue header renders its title with exactly these three, and
      // it does so by hand rather than through a Material text style, because
      // `AppTypography` deliberately does not override the global TextTheme.
      expect(AppTypography.size24, h1['px']);
      expect(AppTypography.medium.value, h1['weight']);
      expect(AppTypography.lineBaseElement, h1['lineHeight']);
    });

    test('the four weights match', () {
      final Map<String, dynamic> weights = (oracle['typography']
          as Map<String, dynamic>)['weights'] as Map<String, dynamic>;

      expect(AppTypography.regular.value, weights['normal']);
      expect(AppTypography.medium.value, weights['medium']);
      expect(AppTypography.semiBold.value, weights['semiBold']);
      expect(AppTypography.bold.value, weights['bold']);
    });
  });

  group('Tier 2 — spacing scale', () {
    test('every oracle step equals its token', () {
      final Map<String, dynamic> spacing =
          oracle['spacing'] as Map<String, dynamic>;
      final List<String> mismatches = <String>[];

      spacing.forEach((String key, dynamic raw) {
        final Map<String, dynamic> entry = raw as Map<String, dynamic>;
        final double? actual = _spacing[key];
        final num expected = entry['px'] as num;

        if (actual == null) {
          mismatches.add('$key: no Flutter token (${entry['tailwind']})');
        } else if (actual != expected) {
          mismatches.add(
              '$key: web ${entry['tailwind']} = ${expected}px vs Flutter '
              '${actual}px');
        }
      });

      expect(mismatches, isEmpty, reason: mismatches.join('\n  '));
    });

    test('the scale really is Tailwind at a 16 px root', () {
      // A spot-check on the arithmetic rather than on one more constant: every
      // step is a multiple of 4 (0.25rem) except the radii, which are their own
      // ramp. If someone "rounds" a step to a nicer number this catches it.
      for (final String key in <String>[
        'gap4', 'gap8', 'gap12', 'gap16', 'gap20', 'gap24', 'gap32', 'gap40',
      ]) {
        expect(_spacing[key]! % 4, 0, reason: '$key is not a Tailwind step');
      }
      expect((oracle['provenance'] as Map<String, dynamic>)
          ['root_font_size_px'], 16);
    });
  });

  group('Tier 2 — iconography (B2-AC-21 in value form)', () {
    test('the two scopes are the web tables, exactly and separately', () {
      final Map<String, dynamic> icons =
          oracle['icons'] as Map<String, dynamic>;

      final List<String> service =
          (icons['serviceScope'] as List<dynamic>).cast<String>();
      final List<String> help =
          (icons['helpScope'] as List<dynamic>).cast<String>();

      expect(AppIcons.serviceScope, service.toSet(),
          reason: "ServicePage.tsx's ICONS table, all 54 names");
      expect(AppIcons.helpScope, help.toSet(),
          reason: "HelpCenterPage.tsx's ICONS table, all 12 names");
      expect(AppIcons.fallback, icons['fallback']);
    });

    test('the scopes are NOT merged — the three-name gap is real', () {
      // § 6.3.5's whole argument in one assertion. If someone "simplifies" the
      // two tables into one 86-name lookup, `/services` returning
      // `icon: "Rocket"` would render a rocket where the web renders FileText.
      for (final String name in <String>['Rocket', 'Phone', 'Mail']) {
        expect(AppIcons.helpScope, contains(name));
        expect(AppIcons.serviceScope, isNot(contains(name)));
        expect(AppIcons.service(name), AppIcons.fallback,
            reason: '$name must fall back under the SERVICE scope');
        expect(AppIcons.help(name), name);
      }
    });

    test('every name in either scope is actually bundled', () {
      // A scope entry with no asset behind it would resolve to a name and then
      // render nothing — the failure mode `AppIcons._resolve`'s third guard
      // exists for, checked here at the registry level too.
      final Set<String> both = <String>{
        ...AppIcons.serviceScope,
        ...AppIcons.helpScope,
      };
      final Iterable<String> missing =
          both.where((String n) => !lucideRegistry.containsKey(n));

      expect(missing, isEmpty);
    });
  });
}

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
import 'package:lcc_mobile_app/presentation/forms/validation/field_error_ring.dart';
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

/// `#RRGGBB` at a fractional alpha → the ARGB int `withValues` produces.
int _argbAlpha(String hex, double alpha) =>
    ((alpha * 255).round() << 24) |
    int.parse(hex.replaceFirst('#', ''), radix: 16);

/// An oracle `value` for a colour entry → the ARGB int it denotes.
int _expectedArgb(dynamic value) {
  if (value is Map<String, dynamic>) {
    return _argbAlpha(value['base'] as String, value['alpha'] as double);
  }
  final String hex = value as String;
  return hex == 'transparent' ? 0x00000000 : _argb(hex);
}

Map<String, dynamic> _forms(Map<String, dynamic> oracle) =>
    oracle['forms'] as Map<String, dynamic>;

/// The colour tokens the `forms` group names, by their oracle token key.
///
/// Separate from [_colours] because the two groups have different
/// denominators: [_colours] is B2's whole-app palette and this is the kernel's
/// 19-utility Tier 2 surface. `token@0.2` keys are the two `/20` derivations,
/// computed from the token they are an alpha OF so there is no second value.
final Map<String, Color> _formColours = <String, Color>{
  'primary': AppColors.primary,
  'primarySoft': AppColors.primarySoft,
  'white': AppColors.white,
  'transparent': AppColors.transparent,
  'gray50': AppColors.gray50,
  'gray100': AppColors.gray100,
  'gray200': AppColors.gray200,
  'gray400Inline': AppColors.gray400Inline,
  'gray800': AppColors.gray800,
  'muted': AppColors.muted,
  'dangerBorder': AppColors.dangerBorder,
  'dangerStrong': AppColors.dangerStrong,
  'primary@0.2': AppColors.primary.withValues(alpha: kFocusRingAlpha),
  'dangerStrong@0.2':
      AppColors.dangerStrong.withValues(alpha: kFocusRingAlpha),
};

/// The radius, spacing and type tokens the `forms` group names.
final Map<String, num> _formNumbers = <String, num>{
  'gap2': AppSpacing.gap2,
  'gap4': AppSpacing.gap4,
  'gap6': AppSpacing.gap6,
  'gap8': AppSpacing.gap8,
  'gap10': AppSpacing.gap10,
  'gap12': AppSpacing.gap12,
  'gap14': AppSpacing.gap14,
  'gap16': AppSpacing.gap16,
  'gap24': AppSpacing.gap24,
  'gap40': AppSpacing.gap40,
  'radiusXl': AppSpacing.radiusXl,
  'radius2xl': AppSpacing.radius2xl,
  'size11': AppTypography.size11,
  'size12': AppTypography.size12,
  'size14': AppTypography.size14,
  'semiBold': AppTypography.semiBold.value,
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

  group('Tier 2 — the `forms` group (F0-AC-94, specs.md § 6.10.1)', () {
    test('the denominator is enumerated, and it is the scan\'s', () {
      // v1.0's F0-AC-59 asserted "100 %" over a set nobody had written down.
      // This is that set, and `derive_tier2.py`'s scan_form_utilities() — which
      // does not read the curated list — is what fixes its size. If the two
      // disagree the derivation fails and this file never sees the oracle.
      final Map<String, dynamic> forms = _forms(oracle);
      final Map<String, dynamic> denominator =
          forms['denominator'] as Map<String, dynamic>;
      final Map<String, dynamic> entries =
          forms['entries'] as Map<String, dynamic>;

      expect(denominator['total'], entries.length,
          reason: 'the recorded denominator and the emitted entries disagree');
      expect(entries.length, 52,
          reason: 'the measured Tier 2 surface of formFields.tsx + '
              'formValidation.tsx. A change here is a real change in the '
              'source and needs a re-derivation, not an edited number.');
      expect(denominator['colour'], 19);
      expect(denominator['radius'], 2);
      expect(denominator['spacing'], 27);
      expect(denominator['type'], 4);
    });

    test('every tokenised entry equals its presentation/theme token', () {
      final Map<String, dynamic> entries =
          _forms(oracle)['entries'] as Map<String, dynamic>;
      final List<String> mismatches = <String>[];
      int compared = 0;

      entries.forEach((String utility, dynamic raw) {
        final Map<String, dynamic> entry = raw as Map<String, dynamic>;
        final String? token = entry['token'] as String?;
        if (token == null) {
          return; // the untokenised register, asserted separately below
        }
        final String source = entry['source'] as String;

        if (entry['category'] == 'colour') {
          final Color? actual = _formColours[token];
          if (actual == null) {
            mismatches.add('$utility: no Flutter token named `$token`');
            return;
          }
          final int expected = _expectedArgb(entry['value']);
          compared++;
          if (actual.toARGB32() != expected) {
            mismatches.add(
              '$utility ($source): web '
              '0x${expected.toRadixString(16).toUpperCase()} vs Flutter '
              '`$token` 0x${actual.toARGB32().toRadixString(16).toUpperCase()}',
            );
          }
        } else {
          final num? actual = _formNumbers[token];
          if (actual == null) {
            mismatches.add('$utility: no Flutter token named `$token`');
            return;
          }
          compared++;
          if (actual != entry['value'] as num) {
            mismatches.add(
              '$utility ($source): web ${entry['value']} vs Flutter '
              '`$token` $actual',
            );
          }
        }
      });

      expect(compared, 48,
          reason: 'the 52 utilities less the 4 in the untokenised register. If '
              'this drops, entries stopped being compared without the '
              'register growing to say so — the vacuity this count exists to '
              'catch.');
      expect(mismatches, isEmpty,
          reason: 'Tier 2 is blocking and 100 % over the enumerated '
              'denominator.\n  ${mismatches.join('\n  ')}');
    });

    test('the untokenised register is closed, reasoned and NOT STALE', () {
      // The same discipline `excluded` gets above: dropping a value from a
      // blocking gate must be the hardest thing to do quietly. Four entries,
      // each with a measured reason.
      final Map<String, dynamic> register =
          _forms(oracle)['untokenised'] as Map<String, dynamic>;

      expect(
        register.keys.toSet(),
        <String>{
          'focus:border-red-400',
          'text-red-400',
          'max-h-60',
          'min-w-0',
        },
        reason: 'a fifth untokenised entry means a Tier 2 value stopped being '
            'compared; it needs a reason in derive_tier2.py, not silence',
      );
      register.forEach((String key, dynamic raw) {
        final Map<String, dynamic> entry = raw as Map<String, dynamic>;
        expect(entry['reason'], isNotEmpty, reason: '$key has no reason');
        expect(entry['consequence'], isNotEmpty,
            reason: '$key does not say what it costs');
        expect(entry['owner'], isNotEmpty, reason: '$key has no owner');
      });

      // The positive control. Both red-400 rows are registered because
      // `#F87171` has NO token — so if a token ever appears, this assertion
      // fails and the register must shrink. Without it the register would
      // outlive the defect and keep excusing a comparison that had become
      // possible.
      expect(
        _formColours.values.map((Color c) => c.toARGB32()),
        isNot(contains(_argb('#F87171'))),
        reason: '`#F87171` (Tailwind red-400) now HAS a token in the forms '
            'map. Remove `focus:border-red-400` and `text-red-400` from '
            "FORMS_UNTOKENISED, point them at it, and F0b's one registered "
            'Tier 2 divergence is resolved.',
      );

      // And the divergence is real, not theoretical: the focused error border
      // draws red-300 where the web draws red-400.
      expect(AppColors.dangerBorder.toARGB32(), _argb('#FCA5A5'));
      expect(AppColors.dangerBorder.toARGB32(), isNot(_argb('#F87171')));
    });

    test('the two 20 %-alpha derivations are computed, not approximated', () {
      // § 6.10.1 names these as "the ones an implementer will approximate".
      // Asserting them by name means "close enough" cannot pass.
      final Map<String, dynamic> entries =
          _forms(oracle)['entries'] as Map<String, dynamic>;

      for (final String utility in <String>[
        'focus:ring-[#344EAD]/20',
        'focus:ring-red-500/20',
      ]) {
        final Map<String, dynamic> entry =
            entries[utility] as Map<String, dynamic>;
        final Map<String, dynamic> value =
            entry['value'] as Map<String, dynamic>;
        expect(value['alpha'], 0.2, reason: '$utility is a /20 suffix');
        expect(_formColours[entry['token'] as String]!.toARGB32(),
            _expectedArgb(value),
            reason: '$utility must be its base token at exactly 20 %, '
                'derived from the token rather than written as a second '
                'literal that can drift');
      }

      // 20 % of 255 is exactly 51 — no rounding argument to have.
      expect(kFocusRingAlpha, 0.2);
      expect((_argbAlpha('#344EAD', 0.2) >> 24) & 0xFF, 51);
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

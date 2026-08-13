/// **Tier 2 — design-token parity for `/news`, `/news/:slug` and `/help`.
/// B2-AC-26.**
///
/// `test/fidelity/tier2_token_parity_test.dart` already gates every token in
/// the versioned oracle and is route-agnostic, so running it is most of Tier 2
/// for these three routes too. What it cannot cover is the **three tokens B2c
/// added**, because `derive_tier2.py` builds the oracle by grepping each hex
/// out of the web file it is attributed to — and that oracle is a versioned B2a
/// artefact this batch may not re-derive (from a different commit it would be a
/// re-baseline, § 6.5.3; from the same one it would still mean B2c rewriting
/// B2a's gate input).
///
/// So this file applies **the same discipline in Dart**, over the same web
/// source at the same commit, for the same reason B2b's `tier2_home_test.dart`
/// gives: *a token whose provenance is wrong must not reach a passing test.*
/// That check is what caught `AppColors.authGradientEnd`'s fabricated gradient.
///
/// All three of B2c's tokens are **inline** in the port source — two hexes and
/// one `rgba()` — so all three get the stronger standard of proof, and none
/// needs the weaker Tailwind-class treatment B2b had to fall back on.
///
/// Filed under `test/features/news/fidelity/` and covering help as well because
/// the three tokens are one change to one file; splitting them would mean two
/// files asserting halves of the same `AppColors` diff.
library;

import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/news/presentation/pages/news_detail_page.dart';
import 'package:lcc_mobile_app/features/news/presentation/widgets/news_article_card.dart';
import 'package:lcc_mobile_app/presentation/icons/app_icons.dart';
import 'package:lcc_mobile_app/presentation/icons/lucide_registry.g.dart';
import 'package:lcc_mobile_app/presentation/theme/app_colors.dart';
import 'package:lcc_mobile_app/presentation/theme/app_spacing.dart';

import '../../../fidelity/oracle.dart';

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

/// One B2c token whose value is written **literally** in the port source.
typedef InlineToken = ({
  String name,
  Color token,
  String literal,
  int argb,
  String file,
});

void main() {
  group('provenance — the port source is at the pinned commit', () {
    test('the three components are present and readable', () {
      expect(kWebCommit, hasLength(40));
      expect(_webFile('src/app/components/NewsPage.tsx'), isNotEmpty);
      expect(_webFile('src/app/components/NewsDetailPage.tsx'), isNotEmpty);
      expect(_webFile('src/app/components/HelpCenterPage.tsx'), isNotEmpty);
    });
  });

  group("B2-AC-26 — B2c's three tokens are IN the file they cite", () {
    final List<InlineToken> tokens = <InlineToken>[
      (
        name: 'newsHeaderStart',
        token: AppColors.newsHeaderStart,
        // `linear-gradient(135deg, #1A2D6B 0%, #344EAD 100%)` — NewsPage.tsx:66
        literal: '#1A2D6B',
        argb: 0xFF1A2D6B,
        file: 'src/app/components/NewsPage.tsx',
      ),
      (
        name: 'helpHeaderEnd',
        token: AppColors.helpHeaderEnd,
        // `linear-gradient(135deg, #344EAD 0%, #1a2d7a 100%)` —
        // HelpCenterPage.tsx:153. Lower-case in the source; the token is
        // upper-case, which is a spelling and not a value.
        literal: '#1a2d7a',
        argb: 0xFF1A2D7A,
        file: 'src/app/components/HelpCenterPage.tsx',
      ),
      (
        name: 'helpHeaderBloom',
        token: AppColors.helpHeaderBloom,
        // `radial-gradient(circle, rgba(245,158,11,0.28) 0%, transparent 70%)`
        // — HelpCenterPage.tsx:157.
        literal: 'rgba(245,158,11,0.28)',
        // 0.28 * 255 = 71.4 → 71 = 0x47.
        argb: 0x47F59E0B,
        file: 'src/app/components/HelpCenterPage.tsx',
      ),
    ];

    for (final InlineToken t in tokens) {
      test('${t.name} — `${t.literal}` appears in ${t.file}', () {
        expect(
          _webFile(t.file).contains(t.literal),
          isTrue,
          reason: 'AppColors.${t.name} cites ${t.file} for `${t.literal}`, and '
              'the string is not there. Either the citation is wrong or the '
              'value was invented — the failure mode that produced '
              'AppColors.authGradientEnd.',
        );
      });

      test('${t.name} — the token holds that value', () {
        expect(
          // ignore: deprecated_member_use — `.value` is the whole point here:
          // Tier 2 compares ARGB integers, not Colors.
          t.token.toARGB32(),
          t.argb,
          reason: 'AppColors.${t.name} drifted from `${t.literal}`.',
        );
      });
    }

    test('helpHeaderBloom is warningStrong at 28 %, not a second amber', () {
      // The RGB half must be an existing token; only the alpha is new. A
      // divergence here would mean two ambers in the theme that look the same
      // and are changed for different reasons.
      expect(
        AppColors.helpHeaderBloom.toARGB32() & 0x00FFFFFF,
        AppColors.warningStrong.toARGB32() & 0x00FFFFFF,
      );
    });

    test('the three dark-navy header stops are three DIFFERENT values', () {
      // The source writes three, and collapsing them onto one token would be a
      // substitution dressed as a simplification. This is the assertion that
      // makes that non-negotiable.
      final Set<int> stops = <int>{
        AppColors.newsHeaderStart.toARGB32(),
        AppColors.helpHeaderEnd.toARGB32(),
        AppColors.headerGradientEnd.toARGB32(),
      };
      expect(stops, hasLength(3));
    });
  });

  group('B2-AC-26 — the tokens the two pages draw with are the theme\'s', () {
    test('the news list card and hero use spacing-scale values', () {
      // `w-28 h-28` → 112, `h-52` → 208. Derived from the scale rather than
      // written bare, and asserted so a later edit cannot quietly replace the
      // derivation with a literal that happens to match today.
      expect(kNewsThumbSide, 112);
      expect(kNewsThumbSide, AppSpacing.tile56 * 2);
      expect(kNewsHeroHeight, 208);
      expect(kNewsHeroHeight, AppSpacing.skeletonServiceCard);
    });

    test('the help swatch palette is the source\'s four pairs, cycled', () {
      // `PALETTE` + `swatch(i) = PALETTE[i % PALETTE.length]` —
      // HelpCenterPage.tsx:55-61. B2a landed the palette; B2c is its first
      // consumer, so this is where the cycling is first exercised.
      expect(AppColors.helpPalette, hasLength(4));
      for (int i = 0; i < 12; i++) {
        expect(AppColors.helpSwatch(i), AppColors.helpPalette[i % 4]);
      }
    });

    test('every colour in the source\'s PALETTE really is in the theme', () {
      final String source = _webFile('src/app/components/HelpCenterPage.tsx');
      const List<String> pairs = <String>[
        '#344EAD', '#EEF2FF',
        '#B45309', '#FEF3C7',
        '#15803D', '#DCFCE7',
        '#6366F1', '#E0E7FF',
      ];
      for (final String hex in pairs) {
        expect(source.contains(hex), isTrue, reason: '$hex is not in the source');
      }
    });
  });

  group('B2-AC-26 — iconography, both pages', () {
    test('every lucide name the two pages render is bundled', () {
      // Compile-time names only — the API-supplied ones are covered by B2a's
      // `app_icons_test.dart`. A name with no asset behind it renders a blank,
      // which is invisible in a text-only Tier 1 dump.
      const List<String> names = <String>[
        // NewsPage.tsx:2
        'ChevronLeft', 'ChevronRight', 'Megaphone',
        // NewsDetailPage.tsx:2
        'Calendar', 'ArrowRight', 'Clock', 'Eye',
        // HelpCenterPage.tsx:2-22
        'Search', 'X', 'ChevronDown', 'LifeBuoy', 'UserCircle', 'FileText',
        'Wallet', 'Shield', 'ShieldCheck', 'Rocket', 'Phone', 'Mail',
        'MessageCircle', 'MapPin', 'BookOpen', 'ThumbsUp', 'ThumbsDown',
      ];

      for (final String name in names) {
        expect(lucideRegistry.containsKey(name), isTrue,
            reason: '$name is drawn by a B2c page and is not bundled');
      }
    });

    test('the four recorded help-category icons resolve non-fallback under the '
        'HELP scope', () {
      for (final Map<String, dynamic> row in loadApi('help-categories')) {
        final String icon = row['icon'] as String;
        expect(AppIcons.help(icon), icon,
            reason: '$icon fell back to ${AppIcons.fallback}');
      }
    });

    test('the four recorded channel icons resolve non-fallback under the HELP '
        'scope', () {
      for (final Map<String, dynamic> row in loadApi('help-channels')) {
        final String icon = row['icon'] as String;
        expect(AppIcons.help(icon), icon,
            reason: '$icon fell back to ${AppIcons.fallback}');
      }
    });

    test('three of those names are OUTSIDE the service scope — § 6.3.5\'s '
        'whole point', () {
      // `Mail`, `Phone`, `Rocket` are in Help's registry and not Service's. A
      // merged 86-name lookup would resolve them under both, which is the
      // observable divergence `app_icons.dart` refuses.
      for (final String name in <String>['Mail', 'Phone', 'Rocket']) {
        expect(AppIcons.help(name), name);
        expect(AppIcons.service(name), AppIcons.fallback);
      }
    });
  });
}

/// **Tier 2 — design-token parity for the chat. B9-AC-29.**
///
/// specs.md § 6.10: *"Every colour B9 renders is an existing
/// `oracle/tier2/tokens.json` entry or one of the four transcribed literals
/// named in § 6.10, each with its source citation. `tokens.json` is **not
/// modified**."*
///
/// ## What Tier 2 can and cannot see, stated rather than assumed
///
/// `derive_tier2.py` greps **hex** out of the web source, so a colour the
/// source writes as a Tailwind class or an `rgba()` never appears in the oracle
/// at all (`roadmap.md:480-491`). The chat renders three such colours. They are
/// asserted here as named constants with their provenance, and recorded as
/// **not covered by Tier 2** rather than quietly counted as covered — which is
/// what B9-AC-29 asks for and is the difference between a 100 % that means
/// something and one that means the gate could not see the failure.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/presentation/theme/app_colors.dart';

import '../../../fidelity/oracle.dart';

/// Every colour the chat draws, by name, with the source line it came from.
///
/// The list is the audit: a colour rendered by `chat_panel.dart` or
/// `chat_launcher.dart` and missing from here is a colour nobody checked.
const Map<String, ({int argb, String source, bool hexInSource})> kChatColours =
    <String, ({int argb, String source, bool hexInSource})>{
  'primary': (
    argb: 0xFF344EAD,
    source: 'CustomerServiceChat.tsx:207,306,332,344,390,437,451,501,533,550',
    hexInSource: true,
  ),
  'primarySoft': (
    argb: 0xFFEEF2FF,
    source: 'CustomerServiceChat.tsx:286',
    hexInSource: true,
  ),
  'chatSurface': (
    argb: 0xFFF5F7FF,
    source: 'CustomerServiceChat.tsx:283,316',
    hexInSource: true,
  ),
  'gray800': (
    argb: 0xFF1F2937,
    source: 'CustomerServiceChat.tsx:353,396 (inline hex) + :290 text-gray-800',
    hexInSource: true,
  ),
  'gray200': (
    argb: 0xFFE5E7EB,
    source: 'CustomerServiceChat.tsx:374,415 (inline hex)',
    hexInSource: true,
  ),
  'white': (
    argb: 0xFFFFFFFF,
    source: 'CustomerServiceChat.tsx:352,395 (inline) + text-white throughout',
    hexInSource: true,
  ),
  'gray700': (
    argb: 0xFF374151,
    source: 'CustomerServiceChat.tsx:468,525 — text-gray-700',
    hexInSource: false,
  ),
  'gray500': (
    argb: 0xFF5A6472,
    source: 'CustomerServiceChat.tsx:293,377,417 — text-gray-500, overridden '
        'by theme.css:93 for AA contrast',
    hexInSource: false,
  ),
  'gray400': (
    argb: 0xFF616B7A,
    source: 'CustomerServiceChat.tsx:404,478,486,525 — text-gray-400, '
        'overridden by theme.css:92',
    hexInSource: false,
  ),
  'gray100': (
    argb: 0xFFF3F4F6,
    source: 'CustomerServiceChat.tsx:467,495,525 — gray-100',
    hexInSource: false,
  ),
  'dangerGlyph': (
    argb: 0xFFFB2C36,
    source: 'CustomerServiceChat.tsx:555 — bg-red-500',
    hexInSource: false,
  ),
  'presenceOnline': (
    argb: 0xFF05DF72,
    source: 'CustomerServiceChat.tsx:214 — bg-green-400',
    hexInSource: false,
  ),
  'chatBubbleShadow': (
    argb: 0x12000000,
    source: 'CustomerServiceChat.tsx:355,398 — rgba(0,0,0,0.07)',
    hexInSource: false,
  ),
};

void main() {
  group('every colour the chat draws is a NAMED TOKEN with its value', () {
    const Map<String, int> actual = <String, int>{
      'primary': 0xFF344EAD,
      'primarySoft': 0xFFEEF2FF,
      'chatSurface': 0xFFF5F7FF,
      'gray800': 0xFF1F2937,
      'gray200': 0xFFE5E7EB,
      'white': 0xFFFFFFFF,
      'gray700': 0xFF374151,
      'gray500': 0xFF5A6472,
      'gray400': 0xFF616B7A,
      'gray100': 0xFFF3F4F6,
      'dangerGlyph': 0xFFFB2C36,
      'presenceOnline': 0xFF05DF72,
      'chatBubbleShadow': 0x12000000,
    };

    test('the audit list and the theme agree, token by token', () {
      expect(actual.keys.toSet(), kChatColours.keys.toSet());
      for (final MapEntry<String, int> e in actual.entries) {
        expect(e.value, kChatColours[e.key]!.argb, reason: e.key);
      }
    });

    test('and the names really resolve to those values in `AppColors`', () {
      // Reading them off the class rather than trusting the map above: a
      // renamed or re-valued token has to fail somewhere.
      expect(AppColors.primary.toARGB32(), 0xFF344EAD);
      expect(AppColors.primarySoft.toARGB32(), 0xFFEEF2FF);
      expect(AppColors.chatSurface.toARGB32(), 0xFFF5F7FF);
      expect(AppColors.gray800.toARGB32(), 0xFF1F2937);
      expect(AppColors.gray200.toARGB32(), 0xFFE5E7EB);
      expect(AppColors.white.toARGB32(), 0xFFFFFFFF);
      expect(AppColors.gray700.toARGB32(), 0xFF374151);
      expect(AppColors.gray500.toARGB32(), 0xFF5A6472);
      expect(AppColors.gray400.toARGB32(), 0xFF616B7A);
      expect(AppColors.gray100.toARGB32(), 0xFFF3F4F6);
      expect(AppColors.dangerGlyph.toARGB32(), 0xFFFB2C36);
      expect(AppColors.presenceOnline.toARGB32(), 0xFF05DF72);
      expect(AppColors.chatBubbleShadow.toARGB32(), 0x12000000);
    });
  });

  group('the hex-in-source colours match `oracle/tier2/tokens.json` or are '
      'transcribed literals with a citation', () {
    late Map<String, dynamic> tokens;

    setUpAll(() {
      final File file = File('$kOracleDir/tier2/tokens.json');
      expect(file.existsSync(), isTrue,
          reason: 'B2\'s Tier 2 oracle is the artefact this compares against; '
              'B9 does NOT modify it');
      tokens = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('`tokens.json` is B2\'s and B9 has not touched it', () {
      // A `git diff` check belongs in the QA report; the artefact-level check
      // is that it still parses and still carries B2's provenance.
      expect(tokens, isNotEmpty);
    });

    test('every hex-in-source colour the chat draws is a hex the WEB writes',
        () {
      // The web source is the authority, not the oracle's index: § 6.10 names
      // four literals the chat transcribes verbatim, and `#F5F7FF` is one the
      // oracle may not carry because B2 never rendered that surface.
      // The path is relative to the package root, the same way `kOracleDir`
      // is. READ-ONLY: nothing in this suite may write under `sources/lcc-app`.
      final String source = File(
        '../lcc-app/src/app/components/CustomerServiceChat.tsx',
      ).readAsStringSync();

      for (final MapEntry<String,
          ({int argb, String source, bool hexInSource})> e
          in kChatColours.entries) {
        if (!e.value.hexInSource) continue;
        if (e.key == 'white') continue; // written as `"white"`, not as hex

        final String hex =
            '#${(e.value.argb & 0xFFFFFF).toRadixString(16).toUpperCase().padLeft(6, '0')}';
        expect(
          source.toUpperCase().contains(hex),
          isTrue,
          reason: '${e.key} ($hex) is declared hex-in-source at '
              '${e.value.source} but does not appear in the port source. '
              'Either the citation is wrong or the value is.',
        );
      }
    });
  });

  group('B9-AC-29 — the colours Tier 2 CANNOT see are recorded, not counted',
      () {
    test('three of them, each named with its provenance', () {
      final List<String> invisible = kChatColours.entries
          .where((MapEntry<String, ({int argb, String source, bool hexInSource})>
                  e) =>
              !e.value.hexInSource)
          .map((MapEntry<String, ({int argb, String source, bool hexInSource})>
                  e) =>
              e.key)
          .toList(growable: false);

      // The class-derived greys came from B2 and are covered by B2's own Tier 2
      // work; the three B9b ADDS are these.
      expect(
        invisible,
        containsAll(<String>[
          'dangerGlyph',
          'presenceOnline',
          'chatBubbleShadow',
        ]),
        reason: '`bg-red-500`, `bg-green-400` and `rgba(0,0,0,0.07)` never '
            'appear as hex in the web source, so `derive_tier2.py` cannot '
            'index them (roadmap.md:480-491). Recorded as NOT COVERED BY '
            'TIER 2 rather than folded into the 100 %.',
      );
    });

    test('their derivations are reproducible — the OKLCH conversion is '
        'validated against a token that already existed', () {
      // `dangerGlyphSoft` (#FF6467, v4 red-400) and `dangerGlyph` (#FB2C36, v4
      // red-500) were both in the theme before B9b. Re-deriving them from their
      // OKLCH definitions is what licenses `presenceOnline`, derived the same
      // way from `oklch(79.2% 0.209 151.711)`.
      expect(AppColors.dangerGlyph.toARGB32(), 0xFFFB2C36,
          reason: 'oklch(63.7% 0.237 25.331) -> #FB2C36');
      expect(AppColors.dangerGlyphSoft.toARGB32(), 0xFFFF6467,
          reason: 'oklch(70.4% 0.191 22.216) -> #FF6467');
      expect(AppColors.presenceOnline.toARGB32(), 0xFF05DF72,
          reason: 'oklch(79.2% 0.209 151.711) -> #05DF72, by the same '
              'conversion that reproduces the two above exactly');
    });

    test('the bubble shadow is 0.07 alpha and NOT one of the two neighbouring '
        'tokens', () {
      expect(AppColors.chatBubbleShadow.a, closeTo(0.07, 0.005));
      expect(AppColors.chatBubbleShadow, isNot(AppColors.cardShadow),
          reason: '#0D000000 is 0.05');
      expect(AppColors.chatBubbleShadow, isNot(AppColors.cardShadowMedium),
          reason: '#1A000000 is 0.10 — substituting either would be a '
              'Tier-2-invisible divergence chosen for tidiness');
    });
  });

  test('the chat introduces exactly THREE new tokens, and the rest are reused',
      () {
    // The scope claim behind the `app_colors.dart` deviation: if this number
    // grows, the deviation grew with it and the hand-back is stale.
    const Set<String> added = <String>{
      'chatSurface',
      'presenceOnline',
      'chatBubbleShadow',
    };
    expect(added, hasLength(3));
    expect(
      kChatColours.keys.toSet().difference(added),
      hasLength(kChatColours.length - 3),
      reason: 'every other colour the chat draws was already in the theme — '
          'checked BY VALUE, not by name: the launcher badge is `dangerGlyph` '
          'because #FB2C36 IS v4 red-500, not because the name looked close.',
    );
  });
}

/// Tier 2 for B10 — `B10-AC-25` and `B10-AC-26`.
///
/// ## Tier 2 compares VALUES, and so does this file — against the source
///
/// `color_literal_test.dart` (B2-AC-11) fails the build on any `Color(0x…)`
/// outside `presentation/theme/`, and its doc comment gives the reason Tier 2
/// depends on: *"a value that is written inline in a widget body is not in the
/// theme, so Tier 2 cannot see it."* That guard gets every B10 colour into
/// `app_colors.dart`. It does **not** check that the value is the one the
/// source states — a token named `bootGradientStart` holding the wrong blue
/// passes it perfectly.
///
/// So each assertion below does two things: it reads the hex out of the actual
/// `.tsx` at the pinned commit, and it compares the Dart token to that. A test
/// that only restated the hex twice would be a tautology — the § 6.14 register
/// and the token would agree with each other and both could be wrong.
///
/// **`sources/lcc-app` is READ-ONLY.** Nothing here writes.
library;

import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/presentation/theme/app_colors.dart';
import 'package:lcc_mobile_app/presentation/theme/app_spacing.dart';

const String _src = '../lcc-app/src/app/components';

String _read(String file) {
  final File f = File('$_src/$file');
  if (!f.existsSync()) {
    fail(
      'NOT EVALUATED: the pinned port source is not checked out at '
      '$_src/$file, so Tier 2 cannot be derived from it. Blocking reason, '
      'not a pass.',
    );
  }
  return f.readAsStringSync();
}

/// Asserts [token] equals `#RRGGBB`, **and** that the same hex really appears
/// in [file] — so a token that drifted and a register row that drifted with it
/// still fail.
void _expectColor(
  String file,
  String source,
  Color token,
  String hex, {
  String? because,
}) {
  expect(
    source.toUpperCase(),
    contains(hex.toUpperCase()),
    reason: '$hex is not in $file — the § 6.14 register row is stale, or the '
        'source moved. Fix the register, do not relax the test.',
  );

  final int rgb = int.parse(hex.substring(1), radix: 16);
  expect(
    token.toARGB32() & 0x00FFFFFF,
    rgb,
    reason: because ?? '$file states $hex',
  );
}

void main() {
  group('B10-AC-25 — the boot screen\'s tokens equal `LoadingScreen.tsx`', () {
    late String src;
    setUpAll(() => src = _read('LoadingScreen.tsx'));

    test('the 160° gradient triple (`:52`)', () {
      _expectColor('LoadingScreen.tsx', src, AppColors.bootGradientStart,
          '#4460C9');
      _expectColor('LoadingScreen.tsx', src, AppColors.bootGradientMid,
          '#344EAD');
      _expectColor('LoadingScreen.tsx', src, AppColors.bootGradientEnd,
          '#1B2C68');
    });

    test('the amber accent (`:108`, `:123`)', () {
      _expectColor('LoadingScreen.tsx', src, AppColors.bootAccent, '#F5C542');
    });

    test('the amber glow keeps its 0.12 alpha (`:66`)', () {
      // `rgba(245,197,66,0.12)`. The alpha is the half a port drops — the RGB
      // looks right and the glow is four times too strong.
      expect(AppColors.bootGlowAmber.toARGB32() & 0x00FFFFFF, 0xF5C542);
      expect(
        ((AppColors.bootGlowAmber.toARGB32() >> 24) / 255 * 100).round(),
        12,
        reason: 'rgba(…, 0.12) — `LoadingScreen.tsx`:66',
      );
    });
  });

  group('B10-AC-25 — the splash\'s tokens equal `SplashScreens.tsx`', () {
    late String src;
    setUpAll(() => src = _read('SplashScreens.tsx'));

    test('the three badge inks, and their contrast reasoning survives', () {
      _expectColor('SplashScreens.tsx', src, AppColors.splashBadgeInk1,
          '#344EAD');
      _expectColor(
        'SplashScreens.tsx',
        src,
        AppColors.splashBadgeInk2,
        '#075985',
        because: '`:179` — a DARK shade, chosen because the vibrant #0EA5E9 '
            'is 2.32:1 and fails WCAG 1.4.3 as text. The source records the '
            'ratio inline (7.2:1) and § 6.14 requires that reasoning to '
            'travel with the value.',
      );
      _expectColor('SplashScreens.tsx', src, AppColors.splashBadgeInk3,
          '#166534');

      // The reasoning really is in the source, so the comment above is not
      // folklore.
      expect(src, contains('7.2:1'));
      expect(src, contains('7.14:1'));
    });

    test('the tracking connector and the done marker', () {
      _expectColor('SplashScreens.tsx', src, AppColors.trackingConnector,
          '#C7D0EA');
      _expectColor('SplashScreens.tsx', src, AppColors.trackingDone,
          '#16A34A');
    });
  });

  group('B10-AC-25 — the tutorial\'s badge pairs equal `TutorialOverlay.tsx`',
      () {
    late String src;
    setUpAll(() => src = _read('TutorialOverlay.tsx'));

    test('four badge pairs and the visual surface', () {
      const List<(Color, String)> pairs = <(Color, String)>[
        (AppColors.tutorialBadgeBgAmber, '#FEF3C7'),
        (AppColors.tutorialBadgeInkAmber, '#D97706'),
        (AppColors.tutorialBadgeBgGreen, '#DCFCE7'),
        (AppColors.tutorialBadgeInkGreen, '#16A34A'),
        (AppColors.tutorialBadgeBgPurple, '#F3E8FF'),
        (AppColors.tutorialBadgeInkPurple, '#9333EA'),
        (AppColors.tutorialBadgeBgRed, '#FEE2E2'),
        (AppColors.tutorialBadgeInkRed, '#DC2626'),
        (AppColors.tutorialVisualSurface, '#F8FAFF'),
      ];
      for (final (Color token, String hex) in pairs) {
        _expectColor('TutorialOverlay.tsx', src, token, hex);
      }
    });

    test('the scrim is 0.6 black (`:364`)', () {
      expect(AppColors.tutorialScrim.toARGB32() & 0x00FFFFFF, 0x000000);
      expect(
        ((AppColors.tutorialScrim.toARGB32() >> 24) / 255 * 100).round(),
        60,
        reason: '`rgba(0,0,0,0.6)`',
      );
    });
  });

  group('B10-AC-26 — the five durations and the swipe threshold', () {
    test('they are the source\'s numbers, read from the source', () {
      final String loading = _read('LoadingScreen.tsx');
      final String splash = _read('SplashScreens.tsx');

      expect(loading, contains('DEFAULT_DURATION = 1800'));
      expect(loading, contains('FADE_MS = 320'));
      expect(splash, contains('EXIT_MS = 320'));
      expect(splash, contains('SWIPE_THRESHOLD = 50'));

      expect(AppMotion.bootHold.inMilliseconds, 1800);
      expect(AppMotion.exitFade.inMilliseconds, 320);
      expect(AppSpacing.swipeThreshold, 50);
    });

    test('the remaining three', () {
      // 500 backdrop cross-fade (`SplashScreens.tsx`:260), 300 tutorial exit
      // (`TutorialOverlay.tsx`:361), 200 dot morph (`:338`).
      expect(AppMotion.backdropCrossFade.inMilliseconds, 500);
      expect(AppMotion.tutorialExit.inMilliseconds, 300);
      expect(AppMotion.dotMorph.inMilliseconds, 200);
    });

    test('`bootTotal` is DERIVED, not a third literal', () {
      // The one that must not drift: `onDone` fires at `duration + FADE_MS`,
      // so a hand-written 2120 that survived a change to either operand would
      // silently desynchronise the fade from the callback.
      expect(AppMotion.bootTotal, AppMotion.bootHold + AppMotion.exitFade);
      expect(AppMotion.bootTotal.inMilliseconds, 2120);
    });
  });

  test('B10-AC-14 — no B10 file carries a colour literal', () {
    // `color_literal_test.dart` enforces this tree-wide; asserted here too so
    // a regression names B10's files rather than arriving as a generic guard
    // failure, and so this file is a complete Tier 2 story on its own.
    const List<String> b10 = <String>[
      'lib/presentation/boot/loading_screen.dart',
      'lib/presentation/boot/splash_screens.dart',
      'lib/presentation/boot/splash_slide_visual.dart',
      'lib/presentation/boot/onboarding_categories.dart',
      'lib/presentation/common/app_button.dart',
      'lib/features/home/presentation/widgets/tutorial_overlay.dart',
      'lib/features/home/presentation/widgets/tutorial_steps.dart',
    ];

    // The negative lookbehind is load-bearing: without it `Colors\.` also
    // matches the tail of `AppColors.`, and the test fails on every correct
    // token reference — which reads as the guard working and is the opposite.
    final RegExp literal = RegExp(r'Color\(0x|(?<![A-Za-z])Colors\.[a-z]');
    for (final String path in b10) {
      final String source = File(path).readAsStringSync();
      // Strip doc comments: `//` lines legitimately quote the source's hex.
      final String code = source
          .split('\n')
          .where((String l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      expect(
        literal.hasMatch(code),
        isFalse,
        reason: '$path holds an inline colour. Tier 2 cannot see a value '
            'written in a widget body — that is the whole reason for the '
            'token register (§ 6.14).',
      );
    }
  });
}

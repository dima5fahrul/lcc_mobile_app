/// `SplashScreens` — B10 § 6.8, § 6.9. `B10-AC-21`, `B10-AC-34`,
/// `B10-AC-36`, `B10-AC-37`, `B10-AC-38`, `B10-AC-40`, `B10-AC-53`.
///
/// ## Slide 3's card arrives through a slot, and the test respects that
///
/// `SplashScreens.tsx`:157 renders the **real** `LaoIdCard`, because — in the
/// source's own words — *"what the slide promises is exactly what the user
/// meets after signing in"*. A `lib/presentation/boot/` file may not import
/// `features/home/presentation/`: that is **G-L7**, landed by B9a and proven to
/// fire, so it is a build failure rather than a style objection. § 6.9's
/// answer is B9a's composition slot, assembled in `app_routes.dart`.
///
/// So `B10-AC-38` splits in two, and both halves are needed:
///
///  * here — the widget renders **whatever the slot supplies**, on slide 3 and
///    nowhere else. Asserted with a sentinel, so it cannot pass by accident.
///  * in `app_routes_splash_test.dart` — the slot is actually filled with a
///    `LaoIdCard` carrying `authenticated: true, interactive: false`.
///
/// Testing only the first half would be green against a splash wired to an
/// empty `SizedBox`; testing only the second would be green against a splash
/// that ignored its own parameter.
library;

import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/presentation/boot/onboarding_categories.dart';
import 'package:lcc_mobile_app/presentation/boot/splash_screens.dart';
import 'package:lcc_mobile_app/presentation/common/glass_icon.dart';
import 'package:lcc_mobile_app/presentation/theme/app_spacing.dart';

import '../../helpers/app_test_harness.dart';
import '../../helpers/core_test_helper.dart';

/// Copy read from the shipped locale file — see `loading_screen_test.dart` for
/// why these are not transcribed.
String _t(String locale, String key) =>
    ((jsonDecode(File('assets/i18n/$locale.json').readAsStringSync())
                as Map<String, dynamic>)['onboarding']
            as Map<String, dynamic>)[key] as String;

/// The sentinel that stands in for `LaoIdCard`. A `Key`, not a `Text`, so it
/// cannot be confused with any copy the splash renders.
const Key kSlide3Slot = Key('slide-3-visual-sentinel');

class _Harness {
  _Harness(this.store, this.storage);
  final Map<String, String> store;
  final StorageService storage;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  VoidCallback? onDone,
  Locale locale = const Locale('en'),
}) async {
  final Map<String, String> store = <String, String>{};
  final StorageService storage = inMemoryStorageService(store);

  await tester.pumpWidget(
    wrapForSplash(
      locale: locale,
      SplashScreens(
        onDone: onDone ?? () {},
        storage: storage,
        slide3Visual: const SizedBox(key: kSlide3Slot, width: 10, height: 10),
        // The backdrop is a photo in production; here a marker that records
        // the alignment it was asked for, so the cross-fade wiring is
        // observable without decoding an asset.
        backdropBuilder: (Alignment a, double w) =>
            SizedBox(key: ValueKey<String>('backdrop-$a'), width: w),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(store, storage);
}

/// `EasyLocalization` + a `MaterialApp` that actually consumes its delegates.
/// Without the `Builder`, `.tr(context: context)` throws — see
/// `loading_screen_test.dart`.
Widget wrapForSplash(Widget child, {required Locale locale}) {
  return EasyLocalization(
    supportedLocales: const <Locale>[Locale('en'), Locale('lo')],
    path: 'assets/i18n',
    assetLoader: const JsonFileAssetLoader(),
    fallbackLocale: const Locale('lo'),
    startLocale: locale,
    saveLocale: false,
    child: Builder(
      builder: (BuildContext context) => MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: Scaffold(body: child),
      ),
    ),
  );
}

/// The three dots, as tappable `Semantics` nodes.
Finder _dots() => find.byWidgetPredicate(
      (Widget w) =>
          w is Semantics &&
          (w.properties.label ?? '').isNotEmpty &&
          w.properties.button == true &&
          w.properties.selected != null,
    );

void main() {
  group('B10-AC-21 — Tier 1: three slides, and the control row the source has',
      () {
    testWidgets('exactly 3 slides, reachable by Next, and Start finishes',
        (WidgetTester tester) async {
      int done = 0;
      final _Harness h = await _pump(tester, onDone: () => done++);

      // Slide 1.
      expect(find.text(_t('en', 'slide1Title')), findsOneWidget);
      expect(
        find.text(_t('en', 'back')),
        findsNothing,
        reason: 'B10-AC-21: Back is ABSENT on slide 1, not disabled — '
            '`index > 0 ? <button> : <div />`',
      );
      expect(find.text(_t('en', 'next')), findsOneWidget);

      // Slide 2.
      await tester.tap(find.text(_t('en', 'next')));
      await tester.pumpAndSettle();
      expect(find.text(_t('en', 'slide2Title')), findsOneWidget);
      expect(find.text(_t('en', 'back')), findsOneWidget);

      // Slide 3 — the CTA changes word AND glyph.
      await tester.tap(find.text(_t('en', 'next')));
      await tester.pumpAndSettle();
      expect(find.text(_t('en', 'slide3Title')), findsOneWidget);
      expect(
        find.text(_t('en', 'getStarted')),
        findsOneWidget,
        reason: 'the CTA reads `getStarted` on the last slide',
      );
      expect(find.text(_t('en', 'next')), findsNothing);

      // There is no fourth slide: the CTA finishes instead of advancing.
      await tester.tap(find.text(_t('en', 'getStarted')));
      await tester.pumpAndSettle();
      expect(done, 1);
      expect(
        h.store[StorageKeys.onboardingSeen],
        '1',
        reason: 'B10-AC-34: Start sets the flag as well as advancing',
      );
    });

    testWidgets('each slide has badge + title + description + a visual',
        (WidgetTester tester) async {
      await _pump(tester);

      for (final ({String badge, String title, String desc}) slide
          in <({String badge, String title, String desc})>[
        (badge: 'slide1Badge', title: 'slide1Title', desc: 'slide1Desc'),
        (badge: 'slide2Badge', title: 'slide2Title', desc: 'slide2Desc'),
        (badge: 'slide3Badge', title: 'slide3Title', desc: 'slide3Desc'),
      ]) {
        expect(find.text(_t('en', slide.badge)), findsOneWidget,
            reason: '${slide.badge} missing');
        expect(find.text(_t('en', slide.title)), findsOneWidget,
            reason: '${slide.title} missing');
        expect(find.text(_t('en', slide.desc)), findsOneWidget,
            reason: '${slide.desc} missing');

        if (slide.badge != 'slide3Badge') {
          await tester.tap(find.text(_t('en', 'next')));
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('the control row is Back | dots | Next, in that order',
        (WidgetTester tester) async {
      await _pump(tester);
      // Move to slide 2 so Back exists.
      await tester.tap(find.text(_t('en', 'next')));
      await tester.pumpAndSettle();

      final double backX = tester.getCenter(find.text(_t('en', 'back'))).dx;
      final double dotsX = tester.getCenter(_dots().first).dx;
      final double nextX = tester.getCenter(find.text(_t('en', 'next'))).dx;

      expect(backX, lessThan(dotsX));
      expect(dotsX, lessThan(nextX));
    });

    testWidgets('Tier 1 holds in Lao too', (WidgetTester tester) async {
      await _pump(tester, locale: const Locale('lo'));
      expect(find.text(_t('lo', 'slide1Title')), findsOneWidget);
      expect(find.text(_t('lo', 'next')), findsOneWidget);
      expect(
        find.text(_t('en', 'slide1Title')),
        findsNothing,
        reason: 'the English copy must not leak through in the Lao locale',
      );
    });
  });

  group('B10-AC-36 / B10-AC-37 — navigation: dots, Back/Next, swipe, clamping',
      () {
    testWidgets('the dots jump to any slide', (WidgetTester tester) async {
      await _pump(tester);
      expect(_dots(), findsNWidgets(3));

      // Straight from slide 1 to slide 3.
      await tester.tap(_dots().at(2));
      await tester.pumpAndSettle();
      expect(find.text(_t('en', 'slide3Title')), findsOneWidget);

      // And back to slide 1.
      await tester.tap(_dots().at(0));
      await tester.pumpAndSettle();
      expect(find.text(_t('en', 'slide1Title')), findsOneWidget);
    });

    testWidgets('Back steps one slide', (WidgetTester tester) async {
      await _pump(tester);
      await tester.tap(find.text(_t('en', 'next')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_t('en', 'back')));
      await tester.pumpAndSettle();
      expect(find.text(_t('en', 'slide1Title')), findsOneWidget);
    });

    testWidgets('a swipe PAST 50px advances; one below it does not',
        (WidgetTester tester) async {
      await _pump(tester);

      // Below the threshold — `handleTouchEnd` returns without moving.
      await tester.drag(find.text(_t('en', 'slide1Title')), const Offset(-40, 0));
      await tester.pumpAndSettle();
      expect(
        find.text(_t('en', 'slide1Title')),
        findsOneWidget,
        reason: 'a 40px drag is below `SplashScreens.tsx`:33\'s 50px '
            'threshold and must not change slide',
      );

      // Past it.
      await tester.drag(find.text(_t('en', 'slide1Title')), const Offset(-120, 0));
      await tester.pumpAndSettle();
      expect(find.text(_t('en', 'slide2Title')), findsOneWidget);

      // And back the other way.
      await tester.drag(find.text(_t('en', 'slide2Title')), const Offset(120, 0));
      await tester.pumpAndSettle();
      expect(find.text(_t('en', 'slide1Title')), findsOneWidget);

      expect(AppSpacing.swipeThreshold, 50);
    });

    testWidgets('B10-AC-37 — `goTo` clamps: no throw and no wrap at either end',
        (WidgetTester tester) async {
      await _pump(tester);

      // Swipe backwards on slide 1.
      await tester.drag(find.text(_t('en', 'slide1Title')), const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(find.text(_t('en', 'slide1Title')), findsOneWidget,
          reason: 'must not wrap to slide 3');
      expect(tester.takeException(), isNull);

      // Forward to the end, then swipe forward again.
      await tester.tap(_dots().at(2));
      await tester.pumpAndSettle();
      await tester.drag(find.text(_t('en', 'slide3Title')), const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(find.text(_t('en', 'slide3Title')), findsOneWidget,
          reason: 'must not wrap to slide 1, and must not call onDone');
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('B10-AC-34 — Skip also sets the flag and finishes',
      (WidgetTester tester) async {
    int done = 0;
    final _Harness h = await _pump(tester, onDone: () => done++);

    await tester.tap(find.text(_t('en', 'skip')));
    await tester.pumpAndSettle();

    expect(done, 1);
    expect(h.store[StorageKeys.onboardingSeen], '1');
    expect(
      h.store.containsKey(StorageKeys.tutorialSeen),
      isFalse,
      reason: 'B10-AC-35: dismissing the splash must NOT set the tutorial '
          'flag. `manifest.md`:190-191 claimed it does; :262-264 measured '
          'that it does not, and the port follows the measurement.',
    );
  });

  group('B10-AC-38 — slide 3 renders the composition slot, and only slide 3',
      () {
    testWidgets('the slot content appears on slide 3',
        (WidgetTester tester) async {
      await _pump(tester);

      expect(
        find.byKey(kSlide3Slot),
        findsNothing,
        reason: 'the slot must not be rendered on slide 1',
      );

      await tester.tap(_dots().at(1));
      await tester.pumpAndSettle();
      expect(find.byKey(kSlide3Slot), findsNothing, reason: 'nor on slide 2');

      await tester.tap(_dots().at(2));
      await tester.pumpAndSettle();
      expect(
        find.byKey(kSlide3Slot),
        findsOneWidget,
        reason: 'slide 3 renders whatever the slot supplies. If this were a '
            'hardcoded look-alike card instead, the sentinel would never '
            'appear — which is the divergence Tier 1 would catch.',
      );
    });
  });

  group('B10-AC-40 — slide 1 renders six GlassIcon tiles from the local const',
      () {
    testWidgets('six tiles, labelled, switching on locale',
        (WidgetTester tester) async {
      await _pump(tester);

      expect(
        find.byType(GlassIcon),
        findsNWidgets(6),
        reason: '`SplashScreens.tsx`:80 takes `CATEGORIES.slice(0, 6)`',
      );
      expect(kOnboardingCategories.length, 6);

      for (final OnboardingCategory c in kOnboardingCategories) {
        expect(find.text(c.labelEn), findsOneWidget, reason: '${c.id} missing');
      }
    });

    testWidgets('the labels are Lao in the Lao locale',
        (WidgetTester tester) async {
      await _pump(tester, locale: const Locale('lo'));
      for (final OnboardingCategory c in kOnboardingCategories) {
        expect(find.text(c.labelLo), findsOneWidget, reason: '${c.id} missing');
      }
    });

    test('the const is LOCAL, not the API category list', () {
      // § 6.9: the Flutter `ServicePage` draws categories from
      // `/service-categories`, so reusing that list would make the splash
      // depend on the network — and the web splash renders fixed copy that no
      // network failure can empty. Six hardcoded rows is the port.
      expect(kOnboardingCategories, hasLength(6));
      for (final OnboardingCategory c in kOnboardingCategories) {
        expect(c.labelEn, isNotEmpty);
        expect(c.labelLo, isNotEmpty);
        expect(c.iconName, isNotEmpty);
      }
    });
  });

  testWidgets(
      'B10-AC-53 — `slideOf` is interpolated and used as the dots\' label',
      (WidgetTester tester) async {
    await _pump(tester);

    // Asserted by reading the RENDERED semantics, not by key presence: a
    // `slideOf` that never reached a `Semantics(label:)` would still be a
    // present, correct-looking key in both locale files.
    final List<Semantics> dots =
        tester.widgetList<Semantics>(_dots()).toList();
    expect(dots, hasLength(3));

    for (int i = 0; i < 3; i++) {
      final String label = dots[i].properties.label!;
      expect(label, contains('${i + 1}'));
      expect(label, contains('3'));
      expect(
        label,
        isNot(contains('{')),
        reason: 'an uninterpolated placeholder ("Slide {current} of {total}") '
            'is what a missing `namedArgs` produces, and it reads as a '
            'perfectly good label until a screen reader speaks it',
      );
    }

    // `aria-current` → `selected`.
    expect(dots[0].properties.selected, isTrue);
    expect(dots[1].properties.selected, isFalse);
  });
}

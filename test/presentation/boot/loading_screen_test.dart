/// `LoadingScreen` — B10 § 6.8, `B10-AC-23` and `B10-AC-32`.
///
/// ## `B10-AC-32` is the whole point of this file
///
/// `LoadingScreen.tsx`:36-37 fires the fade at `duration` and `onDone` at
/// **`duration + FADE_MS`**. "Fires at 1800" is the plausible-looking wrong
/// answer — it is what you get if you port `setTimeout(onDone, duration)` and
/// treat the fade as decoration. The test below pumps to 1800 + a frame and
/// asserts `onDone` has **not** fired yet, then pumps the remaining 320 ms and
/// asserts it has. Asserting only the second half would pass against the wrong
/// implementation.
library;

import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/presentation/boot/loading_screen.dart';
import 'package:lcc_mobile_app/presentation/theme/app_spacing.dart';

import '../../helpers/app_test_harness.dart';

/// The expected copy, READ FROM the shipped locale file rather than restated.
///
/// Two reasons, and the second is the one that bit during authoring. First, a
/// transcribed Lao literal is a second source of truth that silently rots.
/// Second, Lao has combining characters that are easy to get subtly wrong by
/// eye — `ກຳລັງໂຫຼດ…` and `ກຳລັງໂຫລດ…` differ by one code point and render
/// near-identically, so a hand-typed expectation fails for a reason that looks
/// like a port defect and is not.
String _copy(String locale, String key) =>
    ((jsonDecode(File('assets/i18n/$locale.json').readAsStringSync())
                as Map<String, dynamic>)['onboarding']
            as Map<String, dynamic>)[key] as String;

final String _appName = _copy('en', 'appName');
final String _appSub = _copy('en', 'appSub');
final String _loading = _copy('en', 'loading');
final String _issuedBy = _copy('en', 'issuedBy');

Future<void> _pump(
  WidgetTester tester, {
  required VoidCallback onDone,
  Locale locale = const Locale('en'),
  Duration? duration,
}) async {
  await tester.pumpWidget(
    wrapWithLocalization(
      startLocale: locale,
      // The `Builder` is load-bearing, not ceremony: `.tr(context: context)`
      // resolves `Localization.of(context)!`, which only exists once
      // `EasyLocalization`'s delegates are attached to the `MaterialApp`
      // BELOW it. A bare `MaterialApp` here throws "Null check operator used
      // on a null value" inside `build` — and since D-3's whole fix is
      // context-bound `.tr()`, every B10 widget test needs this wiring.
      Builder(
        builder: (BuildContext context) => MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: Scaffold(
            body: duration == null
                ? LoadingScreen(onDone: onDone)
                : LoadingScreen(onDone: onDone, duration: duration),
          ),
        ),
      ),
    ),
  );
  // Deliberately NOT `pumpAndSettle`: the halo pulse and the progress sweep
  // run for the whole hold, so settling would advance past the very timing
  // `B10-AC-32` exists to assert. Two frames is enough for the async delegate.
  await tester.pump();
  await tester.pump();
}

/// The vertical position of the first match, for the order assertion.
double _dy(WidgetTester tester, Finder f) => tester.getTopLeft(f.first).dy;

/// Runs the two `Future.delayed` timers out.
///
/// `LoadingScreen` arms a fade timer at `duration` and an `onDone` timer at
/// `duration + FADE_MS`. Both are `mounted`-guarded, so they are safe in
/// production — but `flutter_test` asserts `!timersPending` at teardown, so a
/// test that asserts on the FIRST frame and stops leaves the binding to throw
/// *"A Timer is still pending even after the widget tree was disposed"*. That
/// failure looks like a leak in the widget and is not one; draining is the
/// correct fix, and suppressing the assertion would hide a real leak later.
Future<void> _drain(WidgetTester tester) async {
  await tester.pump(AppMotion.bootTotal + const Duration(milliseconds: 100));
}

void main() {
  testWidgets('B10-AC-23 — every element is present, in the source\'s '
      'vertical order (`LoadingScreen.tsx`:72-130)',
      (WidgetTester tester) async {
    await _pump(tester, onDone: () {});

    // Presence.
    final Finder logo = find.byType(Image);
    final Finder appName = find.text(_appName);
    final Finder appSub = find.text(_appSub);
    final Finder progress = find.byType(FractionallySizedBox);
    final Finder loading = find.text(_loading);
    final Finder star = find.byIcon(Icons.star);
    final Finder issuedBy = find.text(_issuedBy);

    for (final MapEntry<String, Finder> e in <String, Finder>{
      'logo': logo,
      'appName': appName,
      'appSub': appSub,
      'progress bar': progress,
      'loading label': loading,
      'star glyph': star,
      'issuedBy': issuedBy,
    }.entries) {
      expect(e.value, findsWidgets, reason: '${e.key} is missing');
    }

    // Order. Asserted as positions rather than as tree order: a `Column` whose
    // children were reordered would still contain all seven, and Tier 1 cares
    // where they are.
    final List<double> ys = <double>[
      _dy(tester, logo),
      _dy(tester, appName),
      _dy(tester, appSub),
      _dy(tester, progress),
      _dy(tester, loading),
      _dy(tester, star),
      _dy(tester, issuedBy),
    ];
    for (int i = 1; i < ys.length; i++) {
      expect(
        ys[i],
        greaterThan(ys[i - 1]),
        reason: 'element $i sits at ${ys[i]}, above element ${i - 1} at '
            '${ys[i - 1]} — the vertical order does not match the source',
      );
    }

    await _drain(tester);
  });

  testWidgets('B10-AC-23 — the copy is localised, not hardcoded English',
      (WidgetTester tester) async {
    await _pump(tester, onDone: () {}, locale: const Locale('lo'));
    // `appName`/`appSub` SWAP between locales, exactly like `layout.brand`.
    // Asserting only presence would be green either way, so this reads the
    // Lao-specific `loading` string instead.
    expect(find.text(_loading), findsNothing);
    expect(find.text(_copy('lo', 'loading')), findsOneWidget);
    await _drain(tester);
  });

  group('B10-AC-32 — `onDone` fires at duration + FADE_MS, not at duration',
      () {
    testWidgets('2120 ms, and NOT 1800', (WidgetTester tester) async {
      int done = 0;
      await _pump(tester, onDone: () => done++);

      expect(AppMotion.bootHold, const Duration(milliseconds: 1800));
      expect(AppMotion.exitFade, const Duration(milliseconds: 320));
      expect(
        AppMotion.bootTotal,
        AppMotion.bootHold + AppMotion.exitFade,
        reason: 'the token must be the SUM, not a third independent literal '
            'that could drift from the two it is derived from',
      );

      // Just past the hold: the fade has started, `onDone` has not fired.
      await tester.pump(const Duration(milliseconds: 1801));
      expect(
        done,
        0,
        reason: 'B10-AC-32: firing at 1800 is the plausible wrong answer — it '
            'is what a port of `setTimeout(onDone, duration)` produces, and '
            'it cuts the 320ms fade off mid-way',
      );

      // The fade is genuinely running, so "not fired yet" is not simply
      // "nothing is happening".
      final AnimatedOpacity fading =
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first);
      expect(fading.opacity, 0, reason: 'the exit fade should have begun');

      await tester.pump(const Duration(milliseconds: 320));
      expect(done, 1, reason: 'fires at 2120');

      // And exactly once — a rebuild must not re-arm the timer.
      await tester.pump(const Duration(milliseconds: 2000));
      expect(done, 1);
    });

    testWidgets('a caller-supplied duration is honoured, +320 on top',
        (WidgetTester tester) async {
      int done = 0;
      await _pump(
        tester,
        onDone: () => done++,
        duration: const Duration(milliseconds: 500),
      );

      await tester.pump(const Duration(milliseconds: 501));
      expect(done, 0, reason: 'still inside the 320ms fade');
      await tester.pump(const Duration(milliseconds: 320));
      expect(done, 1);
    });
  });

  testWidgets('the progress bar and the logo are decorative in semantics',
      (WidgetTester tester) async {
    // `LoadingScreen.tsx`:10-14: the wait is a fixed timer, not a measure of
    // work, so a real progressbar role would be a lying one. A port that
    // exposed it would be MORE informative than the source — the R-25 class of
    // invisible divergence, and § 6.8's reason for porting timing as data.
    await _pump(tester, onDone: () {});
    expect(find.byType(ExcludeSemantics), findsWidgets);
    expect(
      find.bySemanticsLabel(RegExp('progress', caseSensitive: false)),
      findsNothing,
    );
    await _drain(tester);
  });
}

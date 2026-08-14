/// `AppButton` — B10 § 6.5, `B10-AC-24`, `B10-AC-43`, `B10-AC-44`,
/// `B10-AC-45`.
///
/// ## Why every assertion here renders
///
/// `Button.tsx`:6-19 exists because the source's earlier CTAs had only
/// happy-path states, and the three it added — `loading`, `disabled`, `error` —
/// are precisely the three a port loses by *accepting the parameter and doing
/// nothing with it*. A test that constructed `AppButton(error: 'x')` and
/// asserted `widget.error == 'x'` would pass against a widget whose `build`
/// ignored the field entirely. That is the Capability Rule's "evidence for the
/// wiring, not the criterion".
///
/// So: the error test looks for the **message on screen** and the **border
/// colour**, the loading test looks for a **spinner widget** and counts
/// **taps actually delivered**, and the disabled test reads the **`Opacity`
/// factor** in the tree.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/presentation/common/app_button.dart';
import 'package:lcc_mobile_app/presentation/theme/app_colors.dart';

/// Pumps [button] with no localization — `AppButton` renders a caller-supplied
/// `child` and never calls `.tr()` itself, so a bare `MaterialApp` is honest
/// here rather than a shortcut.
Future<void> _pump(WidgetTester tester, Widget button) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: Center(child: button))),
  );
}

/// The `BorderSide.color` the button actually resolved, read off the rendered
/// `TextButton`'s style rather than recomputed.
Color _borderColorOf(WidgetTester tester) {
  final TextButton b = tester.widget<TextButton>(find.byType(TextButton));
  final OutlinedBorder shape = b.style!.shape!.resolve(<WidgetState>{})!;
  return shape.side.color;
}

void main() {
  group('B10-AC-24 — every variant and size builds, and the three states '
      'render rather than merely being accepted', () {
    testWidgets('all 5 variants × 3 sizes build', (WidgetTester tester) async {
      for (final AppButtonVariant v in AppButtonVariant.values) {
        for (final AppButtonSize s in AppButtonSize.values) {
          await _pump(
            tester,
            AppButton(
              variant: v,
              size: s,
              onPressed: () {},
              child: Text('${v.name}-${s.name}'),
            ),
          );
          expect(
            find.text('${v.name}-${s.name}'),
            findsOneWidget,
            reason: '$v at $s failed to build',
          );
          expect(tester.takeException(), isNull);
        }
      }

      // 5 × 3 — stated so a variant or size silently dropped from either enum
      // shrinks the matrix instead of quietly reducing coverage.
      expect(AppButtonVariant.values.length, 5);
      expect(AppButtonSize.values.length, 3);
    });

    testWidgets('loading renders a spinner AND suppresses both icons '
        '(`Button.tsx`:103-109)', (WidgetTester tester) async {
      await _pump(
        tester,
        AppButton(
          loading: true,
          onPressed: () {},
          leadingIcon: const Icon(Icons.arrow_back, key: Key('lead')),
          trailingIcon: const Icon(Icons.arrow_forward, key: Key('trail')),
          child: const Text('Save'),
        ),
      );

      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
        reason: 'the spinner is the visible half of `loading`',
      );
      expect(
        find.byKey(const Key('lead')),
        findsNothing,
        reason: '`{loading ? <Loader2/> : leadingIcon}` — the spinner takes '
            'the leading slot, it does not sit beside it',
      );
      expect(
        find.byKey(const Key('trail')),
        findsNothing,
        reason: '`{!loading && trailingIcon}` — `Button.tsx`:109',
      );
    });

    testWidgets('disabled renders at 50% opacity and does not fire',
        (WidgetTester tester) async {
      int taps = 0;
      // `onPressed: null` IS the source's `disabled` — an omitted handler on a
      // `<button>` is inert and Material agrees.
      await _pump(tester, const AppButton(child: Text('Save')));

      final Finder opacity = find.ancestor(
        of: find.byType(TextButton),
        matching: find.byType(Opacity),
      );
      expect(opacity, findsOneWidget, reason: '`opacity-50` wraps the control');
      expect(tester.widget<Opacity>(opacity).opacity, 0.5);

      await tester.tap(find.byType(TextButton), warnIfMissed: false);
      await tester.pump();
      expect(taps, 0, reason: 'a disabled CTA must not fire');

      // The converse, so the assertion above is not vacuously true of every
      // AppButton: with a handler there is no Opacity wrapper at all.
      await _pump(
        tester,
        AppButton(onPressed: () => taps++, child: const Text('Save')),
      );
      expect(
        find.ancestor(
          of: find.byType(TextButton),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
      await tester.tap(find.byType(TextButton));
      await tester.pump();
      expect(taps, 1);
    });
  });

  testWidgets(
      'B10-AC-45 — loading ignores taps but stays enabled (focusable). '
      '`Button.tsx`:91 swallows the click WITHOUT setting disabled',
      (WidgetTester tester) async {
    int taps = 0;
    await _pump(
      tester,
      AppButton(
        loading: true,
        onPressed: () => taps++,
        child: const Text('Save'),
      ),
    );

    await tester.tap(find.byType(TextButton));
    await tester.pump();
    expect(taps, 0, reason: 'half one: the click is swallowed');

    // Half two, and the half a port drops: `null`-ing `onPressed` would also
    // swallow the tap — and would take the control out of the tab order,
    // stranding a screen-reader user mid-traversal. So the button must still
    // report itself ENABLED.
    final TextButton b = tester.widget<TextButton>(find.byType(TextButton));
    expect(
      b.onPressed,
      isNotNull,
      reason: 'half two: a null handler is what makes a Material button '
          'unfocusable — that is `disabled` behaviour, not `loading`',
    );
    expect(b.enabled, isTrue);

    // And it is not dimmed: `loading` is not `disabled`.
    expect(
      find.ancestor(
        of: find.byType(TextButton),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
  });

  group('B10-AC-44 — `error` renders a message, a live region and a danger '
      'border, asserted by rendering', () {
    testWidgets('all three, together', (WidgetTester tester) async {
      await _pump(
        tester,
        AppButton(
          error: 'Could not save',
          onPressed: () {},
          child: const Text('Save'),
        ),
      );

      // 1. The message is on screen — not merely stored on the widget.
      expect(find.text('Could not save'), findsOneWidget);

      // 2. It is a live region (`role="alert"`, `Button.tsx`:111-120). Without
      //    this the text looks identical and is never announced.
      final Finder live = find.byWidgetPredicate(
        (Widget w) => w is Semantics && w.properties.liveRegion == true,
      );
      expect(
        live,
        findsWidgets,
        reason: 'a rendered-but-unannounced error is the half-port this AC '
            'exists to catch',
      );
      expect(
        find.descendant(of: live, matching: find.text('Could not save')),
        findsOneWidget,
        reason: 'the live region must contain the MESSAGE, not merely exist '
            'somewhere in the tree',
      );

      // 3. The border switched — `borderColor: error ? "#DC2626" : v.border`.
      expect(_borderColorOf(tester), AppColors.danger);
    });

    testWidgets('no error: no message, and the variant keeps its own border',
        (WidgetTester tester) async {
      await _pump(
        tester,
        AppButton(
          variant: AppButtonVariant.secondary,
          onPressed: () {},
          child: const Text('Save'),
        ),
      );

      expect(find.text('Could not save'), findsNothing);
      expect(
        _borderColorOf(tester),
        AppColors.trackingConnector,
        reason: 'secondary is #C7D0EA (`Button.tsx`:45); if the danger colour '
            'appeared here the AC above would be passing for the wrong reason',
      );
    });

    testWidgets('an EMPTY error string is "no error", matching JSX falsiness',
        (WidgetTester tester) async {
      await _pump(
        tester,
        AppButton(error: '', onPressed: () {}, child: const Text('Save')),
      );
      expect(_borderColorOf(tester), AppColors.primary);
    });
  });

  testWidgets(
      'NEGATIVE CONTROL — the AC-44 assertions reject an inert `error`',
      (WidgetTester tester) async {
    // The Capability Rule's demand, discharged without mutating `lib/`: a
    // regression test that has never been red is not evidence. Rather than
    // breaking `app_button.dart` to watch the test above fail — this tree has
    // concurrent writers and a late restore is how the last round nearly lost
    // work — the discriminating power is proved against a **local fixture**
    // that is exactly the half-port AC-44 exists to catch: it accepts `error`,
    // stores it, and renders nothing.
    await _pump(tester, const _InertErrorButton(error: 'Could not save'));

    expect(
      find.text('Could not save'),
      findsNothing,
      reason: 'the message assertion must fail against a widget that only '
          'STORES the error — if this found the text, AC-44 would be passing '
          'on parameter presence',
    );
    expect(
      find.byWidgetPredicate(
        (Widget w) => w is Semantics && w.properties.liveRegion == true,
      ),
      findsNothing,
      reason: 'the live-region assertion must also discriminate',
    );
    expect(
      _borderColorOf(tester),
      isNot(AppColors.danger),
      reason: 'and the border assertion must discriminate too — an inert '
          '`error` leaves the variant border in place',
    );
  });

  test('B10-AC-25 — the variant table equals `Button.tsx`:44-50 by value', () {
    // Read as values, not by inspection: this is the Tier 2 assertion for the
    // five rows the source states together.
    expect(AppButton.colorsFor(AppButtonVariant.primary), (
      bg: const Color(0xFF344EAD),
      fg: const Color(0xFFFFFFFF),
      border: const Color(0xFF344EAD),
    ));
    expect(AppButton.colorsFor(AppButtonVariant.secondary), (
      bg: const Color(0xFFFFFFFF),
      fg: const Color(0xFF344EAD),
      border: const Color(0xFFC7D0EA),
    ));
    expect(
      AppButton.colorsFor(AppButtonVariant.amber),
      (
        bg: const Color(0xFFF59E0B),
        fg: const Color(0xFF1F2937),
        border: const Color(0xFFF59E0B),
      ),
      reason: 'amber MUST keep its dark #1F2937 ink. White on #F59E0B is '
          '2.15:1 and fails WCAG 1.4.3 — `Button.tsx`:24-25. This assertion '
          'is what stops the value being "tidied" back to white.',
    );
    expect(AppButton.colorsFor(AppButtonVariant.danger), (
      bg: const Color(0xFFDC2626),
      fg: const Color(0xFFFFFFFF),
      border: const Color(0xFFDC2626),
    ));
    expect(AppButton.colorsFor(AppButtonVariant.ghost), (
      bg: const Color(0x00000000),
      fg: const Color(0xFF4B5563),
      border: const Color(0x00000000),
    ));
  });

  test('B10-AC-26 — `SIZES` resolves Tailwind to the source\'s pixels', () {
    // `sm: px-3 py-2 text-xs rounded-lg gap-1.5` at the 16px root.
    final AppButtonMetrics sm = AppButton.metricsFor(AppButtonSize.sm);
    expect(<double>[sm.px, sm.py, sm.fontSize, sm.gap], <double>[12, 8, 12, 6]);

    // `md: px-5 py-2.5 text-sm rounded-xl gap-2`
    final AppButtonMetrics md = AppButton.metricsFor(AppButtonSize.md);
    expect(<double>[md.px, md.py, md.fontSize, md.gap], <double>[20, 10, 14, 8]);

    // `lg: px-6 py-3.5 text-sm rounded-xl gap-2`
    final AppButtonMetrics lg = AppButton.metricsFor(AppButtonSize.lg);
    expect(<double>[lg.px, lg.py, lg.fontSize, lg.gap], <double>[24, 14, 14, 8]);

    // rounded-lg = 8, rounded-xl = 12.
    expect(<double>[sm.radius, md.radius, lg.radius], <double>[8, 12, 12]);
  });

  testWidgets('fullWidth stretches the control (`Button.tsx`\'s span wrapper)',
      (WidgetTester tester) async {
    await _pump(
      tester,
      AppButton(fullWidth: true, onPressed: () {}, child: const Text('Save')),
    );
    final Size size = tester.getSize(find.byType(TextButton));
    expect(size.width, 800, reason: 'the default test surface is 800 wide');
  });
}

/// The half-port `B10-AC-44` exists to catch: `error` is accepted, stored, and
/// never rendered. Used only by the negative control above.
class _InertErrorButton extends StatelessWidget {
  const _InertErrorButton({required this.error});

  // ignore: unreachable_from_main
  final String error;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: AppColors.primary),
          ),
        ),
        child: const Text('Save'),
      );
}

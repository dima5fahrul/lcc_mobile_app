/// The eleven `formValidation.tsx` exports, **exercised** —
/// `F0-AC-96`'s named behaviours plus the server-error path.
///
/// `F0-AC-96` closes the `AC-24` shape: v1.0's *"exists / enumerated in
/// `qa-report.md`"* was satisfied by declaration alone, leaving all eleven of
/// these with no behavioural assertion anywhere. Each group below is one of the
/// behaviours it names.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/presentation/forms/validation/field_error.dart';
import 'package:lcc_mobile_app/presentation/forms/validation/field_error_ring.dart';
// Aliased, not renamed at the source: `isEmpty` is `formValidation.tsx:89`'s
// own export name and the kernel keeps it, but `package:matcher` exports an
// `isEmpty` MATCHER, so the two collide in any test file that uses both. F1
// will hit the same collision in its page tests; aliasing at the import is the
// answer, and renaming the kernel export to dodge it would be a divergence
// from the source for a test-only reason.
import 'package:lcc_mobile_app/presentation/forms/validation/is_empty.dart'
    as validation;
import 'package:lcc_mobile_app/presentation/forms/validation/scroll_to_first_error.dart';
import 'package:lcc_mobile_app/presentation/forms/validation/step_of_first_error.dart';
import 'package:lcc_mobile_app/presentation/forms/validation/validation_scope.dart';
import 'package:lcc_mobile_app/presentation/theme/app_colors.dart';

import '../../helpers/app_test_harness.dart';

Future<void> pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    wrapWithLocalization(
      Builder(
        builder: (BuildContext context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('isEmpty — over its measured input set', () {
    test('null is empty', () => expect(validation.isEmpty(null), isTrue));

    test('a blank or whitespace-only String is empty', () {
      expect(validation.isEmpty(''), isTrue);
      expect(validation.isEmpty('   '), isTrue);
      expect(validation.isEmpty('\t\n '), isTrue);
    });

    test('a String with content is not', () {
      expect(validation.isEmpty('a'), isFalse);
      expect(validation.isEmpty(' a '), isFalse);
    });

    test('a NON-STRING is never empty — the third line of the source', () {
      // `formValidation.tsx:92` — `return false;`. A Dart port that reached for
      // `value.isEmpty` on a collection would reject forms the web accepts.
      expect(validation.isEmpty(<String>[]), isFalse);
      expect(validation.isEmpty(<String, String>{}), isFalse);
      expect(validation.isEmpty(0), isFalse);
      expect(validation.isEmpty(false), isFalse);
    });
  });

  group('stepOfFirstError — the EARLIEST step, and unknown paths are skipped',
      () {
    const Map<String, int> steps = <String, int>{
      'applicant.citizen_name': 1,
      'purpose.purpose': 3,
      'address.village': 2,
    };

    test('returns the earliest step among the reported paths', () {
      expect(
        stepOfFirstError(<String>['purpose.purpose', 'address.village'], steps),
        2,
      );
      expect(
        stepOfFirstError(
          <String>['purpose.purpose', 'applicant.citizen_name'],
          steps,
        ),
        1,
      );
    });

    test('order of the reported paths does not matter', () {
      expect(
        stepOfFirstError(<String>['address.village', 'purpose.purpose'], steps),
        stepOfFirstError(<String>['purpose.purpose', 'address.village'], steps),
      );
    });

    test('a path the map does not know is SKIPPED, not treated as step 0', () {
      // `formValidation.tsx:179` — `if (step === undefined) continue;`. This is
      // why a page with a gappy FIELD_STEP silently fails to route rather than
      // routing to the wrong step, which is D-G — and D-G is the PAGE's defect,
      // not this function's (§ 6.3.6).
      expect(stepOfFirstError(<String>['nope.nope'], steps), isNull);
      expect(
        stepOfFirstError(<String>['nope.nope', 'purpose.purpose'], steps),
        3,
      );
    });

    test('an empty complaint list yields null', () {
      expect(stepOfFirstError(const <String>[], steps), isNull);
      expect(stepOfFirstError(const <String>[], const <String, int>{}), isNull);
    });
  });

  group('fieldErrorRing — toggling, and both branches` six values', () {
    test('it TOGGLES: the two states are different objects', () {
      expect(fieldErrorRing(true), isNot(fieldErrorRing(false)));
      expect(fieldErrorRing(true), kFieldErrorRing);
      expect(fieldErrorRing(false), kFieldRestingRing);
    });

    test('the resting branch is border-gray-200 / #344EAD / #344EAD-at-20 %',
        () {
      expect(kFieldRestingRing.border, AppColors.gray200);
      expect(kFieldRestingRing.focusedBorder, AppColors.primary);
      expect(
        kFieldRestingRing.focusRing,
        AppColors.primary.withValues(alpha: 0.2),
      );
      // The alpha is COMPUTED from the token it is an alpha of, so there is no
      // second value to drift.
      expect(kFieldRestingRing.focusRing.a, closeTo(0.2, 0.001));
      expect(kFieldRestingRing.focusRing.r, AppColors.primary.r);
    });

    test('the error branch is border-red-300 and red-500-at-20 %', () {
      expect(kFieldErrorRing.border, AppColors.dangerBorder);
      expect(
        kFieldErrorRing.focusRing,
        AppColors.dangerStrong.withValues(alpha: 0.2),
      );
    });

    test('TIER-2 GAP, recorded as a test rather than only as a comment: '
        'focus:border-red-400 has no token', () {
      // #F87171 is not in `presentation/theme/`, and that file is outside
      // F0b's § 3.1 scope, so the focused error border currently repeats the
      // unfocused one. This assertion exists so the gap is visible in a test
      // run and not only in a doc comment — when a `red-400` token lands, this
      // test goes red and names what to change.
      expect(
        kFieldErrorRing.focusedBorder,
        AppColors.dangerBorder,
        reason: 'UNRESOLVED: should be red-400 #F87171. Adding the token means '
            'editing lib/presentation/theme/app_colors.dart, which is not in '
            "§ 3.1's F0b table and is named in § 4.1's out-of-scope list.",
      );
      expect(kFieldErrorRing.focusedBorder, isNot(const Color(0xFFF87171)));
    });
  });

  group('the ValidationScope surface', () {
    testWidgets('with no scope at all, every accessor answers its default',
        (WidgetTester tester) async {
      // The kernel is used by `PaymentSection`, which provides no scope. A hard
      // `of()` would make it unusable there and unpumpable in a test.
      late BuildContext ctx;
      await pump(tester, Builder(builder: (BuildContext c) {
        ctx = c;
        return const SizedBox.shrink();
      }));

      expect(ValidationScope.maybeOf(ctx), isNull);
      expect(ValidationScope.showErrorsOf(ctx), isFalse);
      expect(ValidationScope.serverErrorsOf(ctx), isEmpty);
      expect(ValidationScope.serverErrorOf(ctx, 'a.b'), isNull);
      // …and the clear callback is callable rather than null.
      ValidationScope.clearServerErrorOf(ctx)('a.b');
    });

    testWidgets('a required-and-blank field complains only once showErrors',
        (WidgetTester tester) async {
      late BuildContext ctx;
      Widget probe({required bool showErrors}) => ValidationScope(
            showErrors: showErrors,
            child: Builder(builder: (BuildContext c) {
              ctx = c;
              return const SizedBox.shrink();
            }),
          );

      await pump(tester, probe(showErrors: false));
      expect(
        ValidationScope.fieldErrorOf(ctx, required: true, value: '').hasError,
        isFalse,
      );

      await pump(tester, probe(showErrors: true));
      expect(
        ValidationScope.fieldErrorOf(ctx, required: true, value: '').hasError,
        isTrue,
      );
      // A filled field never complains.
      expect(
        ValidationScope.fieldErrorOf(ctx, required: true, value: 'x').hasError,
        isFalse,
      );
      // Nor does a non-required one.
      expect(
        ValidationScope.fieldErrorOf(ctx, value: '').hasError,
        isFalse,
      );
    });

    testWidgets('a DISABLED control never complains locally', (WidgetTester t) async {
      late BuildContext ctx;
      await pump(
        t,
        ValidationScope(
          showErrors: true,
          child: Builder(builder: (BuildContext c) {
            ctx = c;
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(
        ValidationScope.fieldErrorOf(
          ctx,
          required: true,
          value: '',
          disabled: true,
        ).hasError,
        isFalse,
        reason: 'a district with no province yet is not the citizen`s fault',
      );
    });

    testWidgets('…but a disabled control DOES show a server error — the early '
        'return happens first', (WidgetTester t) async {
      late BuildContext ctx;
      await pump(
        t,
        ValidationScope(
          showErrors: false,
          serverErrors: const <String, String>{'a.b': 'Server says no'},
          child: Builder(builder: (BuildContext c) {
            ctx = c;
            return const SizedBox.shrink();
          }),
        ),
      );
      final FieldErrorState s = ValidationScope.fieldErrorOf(
        ctx,
        path: 'a.b',
        required: true,
        value: 'filled',
        disabled: true,
      );
      expect(s.hasError, isTrue);
      expect(s.message, 'Server says no');
    });

    testWidgets('a server message WINS over the local blank check',
        (WidgetTester t) async {
      late BuildContext ctx;
      await pump(
        t,
        ValidationScope(
          showErrors: true,
          serverErrors: const <String, String>{'a.b': 'Must be a valid UIN'},
          child: Builder(builder: (BuildContext c) {
            ctx = c;
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(
        ValidationScope.fieldErrorOf(ctx, path: 'a.b', required: true, value: '')
            .message,
        'Must be a valid UIN',
      );
      // A path with no server entry falls through to the local check, message
      // null — the renderer supplies `common.fieldRequired`.
      final FieldErrorState local =
          ValidationScope.fieldErrorOf(ctx, path: 'c.d', required: true, value: '');
      expect(local.hasError, isTrue);
      expect(local.message, isNull);
    });
  });

  group('FieldErrorText renders — and only when it should', () {
    testWidgets('show: false renders nothing at all', (WidgetTester t) async {
      await pump(t, const FieldErrorText(show: false));
      expect(find.byType(FieldErrorMarker), findsNothing);
    });

    testWidgets('show: true with no message falls back to common.fieldRequired',
        (WidgetTester t) async {
      await pump(t, const FieldErrorText(show: true));
      expect(find.text('This field is required'), findsOneWidget);
      expect(find.byType(FieldErrorMarker), findsOneWidget);
    });

    testWidgets('a supplied message replaces the fallback',
        (WidgetTester t) async {
      await pump(t, const FieldErrorText(show: true, message: 'Nope'));
      expect(find.text('Nope'), findsOneWidget);
      expect(find.text('This field is required'), findsNothing);
    });
  });

  group('scrollToFirstError — it locates the FIRST marker in document order',
      () {
    testWidgets('and focuses the control that marker carries',
        (WidgetTester tester) async {
      final FocusNode second = FocusNode();
      final FocusNode third = FocusNode();
      late BuildContext ctx;

      await pump(
        tester,
        SingleChildScrollView(
          child: Builder(builder: (BuildContext c) {
            ctx = c;
            return Column(
              children: <Widget>[
                const SizedBox(height: 2000, child: Text('filler')),
                // First VALID field — no marker.
                const SizedBox(height: 400, child: Text('valid')),
                Focus(
                  focusNode: second,
                  child: const FieldErrorText(
                    show: true,
                    message: 'first invalid',
                  ),
                ),
                Focus(
                  focusNode: third,
                  child: const FieldErrorText(
                    show: true,
                    message: 'second invalid',
                  ),
                ),
              ],
            );
          }),
        ),
      );

      // `firstErrorMarker` is exposed precisely so "it scrolled somewhere" and
      // "it scrolled to the FIRST invalid field" can be told apart.
      final Element? marker = firstErrorMarker(ctx);
      expect(marker, isNotNull);
      final FieldErrorMarker found = marker!.widget as FieldErrorMarker;
      expect(found.focusNode, isNull,
          reason: 'the marker under a Focus does not itself carry the node; '
              'the field passes it in — see the DateField case below');

      second.dispose();
      third.dispose();
    });

    testWidgets('it returns false when there is nothing to scroll to',
        (WidgetTester tester) async {
      late BuildContext ctx;
      await pump(
        tester,
        SingleChildScrollView(
          child: Builder(builder: (BuildContext c) {
            ctx = c;
            return const SizedBox(height: 100, child: Text('all valid'));
          }),
        ),
      );
      expect(firstErrorMarker(ctx), isNull);

      // `scrollToFirstErrorNow`, not `scrollToFirstError`: the wrapper returns
      // `void` because the source does, and the decision lives in the
      // synchronous half precisely so it can be asserted (see that file's
      // "Why this is two functions and not one `Future`"). The `Future<bool>`
      // this test previously awaited was a shape neither the source nor the
      // port has.
      expect(scrollToFirstErrorNow(ctx), isFalse);
    });

    testWidgets('it scrolls the first marker into view, centres it and focuses',
        (WidgetTester tester) async {
      final FocusNode node = FocusNode();
      final ScrollController controller = ScrollController();
      late BuildContext ctx;

      await pump(
        tester,
        SingleChildScrollView(
          controller: controller,
          child: Builder(builder: (BuildContext c) {
            ctx = c;
            return Column(
              children: <Widget>[
                const SizedBox(height: 2000),
                // The node is attached to a real `Focus`, as it is on a page —
                // `FieldErrorMarker` only *carries* the node (it renders its
                // child and nothing else, `field_error.dart:51`), so a bare
                // detached `FocusNode` can never take focus and the assertion
                // below would be unfalsifiable.
                Focus(
                  focusNode: node,
                  child: FieldErrorMarker(
                    focusNode: node,
                    child: const SizedBox(height: 20, child: Text('the error')),
                  ),
                ),
                const SizedBox(height: 2000),
              ],
            );
          }),
        ),
      );

      expect(controller.offset, 0,
          reason: 'precondition: the marker is off-screen below');

      expect(scrollToFirstErrorNow(ctx), isTrue);
      await tester.pumpAndSettle();

      // The capability, not the return value: it really moved the viewport.
      expect(controller.offset, greaterThan(0));

      // `block: "center"` → `alignment: 0.5`. Asserting the marker ends up at
      // the viewport's centre is what distinguishes "it scrolled somewhere"
      // from the ported behaviour.
      final double markerCentre = tester.getCenter(find.text('the error')).dy;
      final double viewportCentre =
          tester.getSize(find.byType(SingleChildScrollView)).height / 2;
      expect((markerCentre - viewportCentre).abs(), lessThan(1.0));

      expect(node.hasFocus, isTrue,
          reason: '`control?.focus({preventScroll: true})` — the second half '
              'of the source behaviour, and the half a "did it scroll?" '
              'assertion misses');

      node.dispose();
      controller.dispose();
    });

    testWidgets('the wrapper waits a frame, and that wait is load-bearing',
        (WidgetTester tester) async {
      // Behaviour 1 of the three the port names: `requestAnimationFrame` lets
      // the newly-revealed error rows commit before they are looked for. The
      // source calls this immediately after `setShowErrors(true)`, so the
      // marker does **not** exist in the built tree at the moment of the call
      // — which is exactly what makes the frame-wait necessary rather than
      // decorative. [_RevealHost] reproduces that sequence.
      final GlobalKey<_RevealHostState> key = GlobalKey<_RevealHostState>();
      final ScrollController controller = ScrollController();

      await pump(tester, _RevealHost(key: key, controller: controller));
      expect(find.text('the error'), findsNothing);

      // The negative control, and the reason this test has teeth: run the
      // SYNCHRONOUS half at the same instant the page calls the wrapper. The
      // rebuild is queued but not yet built, so there is no marker to find and
      // it reports false. A wrapper that skipped `addPostFrameCallback` would
      // do exactly this and silently never scroll.
      key.currentState!.revealSynchronously();
      expect(
        key.currentState!.syncResult,
        isFalse,
        reason: 'at call time the marker does not exist yet — this is the '
            'failure the frame-wait exists to prevent',
      );
      await tester.pumpAndSettle();
      expect(controller.offset, 0,
          reason: 'the synchronous half found nothing, so nothing scrolled');

      // Now the real wrapper, driven the same way.
      key.currentState!.reset();
      await tester.pumpAndSettle();
      expect(controller.offset, 0);

      key.currentState!.reveal();
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(0),
          reason: 'the post-frame callback ran after the marker committed, '
              'found it, and scrolled');

      controller.dispose();
    });
  });
}

/// Reproduces the source call sequence: flip `showErrors`, then ask to scroll —
/// with the marker only entering the tree on the rebuild that flip schedules.
class _RevealHost extends StatefulWidget {
  const _RevealHost({super.key, required this.controller});

  final ScrollController controller;

  @override
  State<_RevealHost> createState() => _RevealHostState();
}

class _RevealHostState extends State<_RevealHost> {
  bool _show = false;
  late BuildContext _inner;

  /// What [scrollToFirstErrorNow] reported when called without the frame wait.
  bool? syncResult;

  void reveal() {
    setState(() => _show = true);
    scrollToFirstError(_inner);
  }

  void revealSynchronously() {
    setState(() => _show = true);
    syncResult = scrollToFirstErrorNow(_inner);
  }

  void reset() => setState(() => _show = false);

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        controller: widget.controller,
        child: Builder(builder: (BuildContext c) {
          _inner = c;
          return Column(
            children: <Widget>[
              const SizedBox(height: 2000),
              if (_show)
                const FieldErrorMarker(
                  child: SizedBox(height: 20, child: Text('the error')),
                ),
              const SizedBox(height: 2000),
            ],
          );
        }),
      );
}

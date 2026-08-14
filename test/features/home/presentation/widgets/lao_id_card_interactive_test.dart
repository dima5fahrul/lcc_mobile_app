/// `LaoIdCard.interactive` — B10 § 6.9, `B10-AC-38` (the second half) and
/// `B10-AC-39`.
///
/// ## Why the parameter had to be additive
///
/// `lao_id_card.dart` belongs to B2b. B10 needed one new argument for splash
/// slide 3, and § 8.2(4) makes "cannot accept `interactive` additively without
/// changing existing behaviour" a **BLOCKED** condition rather than something
/// to negotiate. `interactive = true` is what discharges it: every call site
/// that existed before B10 is byte-identical in behaviour, and the default is
/// asserted below rather than assumed, because a default flipped to `false`
/// would silently disarm the UIN reveal and the QR dialog on the real Home
/// card and no existing test names the parameter.
///
/// ## What `interactive: false` must actually suppress
///
/// `Hero.tsx` gates three things on it — the UIN reveal eye (`:263`), the QR
/// **button** (`:287`) and the QR dialog (`:316`). The QR *tile* still draws:
/// with `interactive` it is a `<button>`, without it an `aria-hidden` `<div>`
/// with byte-identical styling. Asserting the tile disappears would be wrong,
/// and is the mistake a "hide everything interactive" port makes — slide 3
/// exists to show the citizen the card they will meet after signing in, so
/// removing its QR block would break the one thing the slide promises.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/home/presentation/widgets/lao_id_card.dart';
import 'package:lcc_mobile_app/utils/routes/app_routes.dart';

import '../../../../helpers/app_test_harness.dart';

Future<void> _pump(WidgetTester tester, Widget card) async {
  await tester.pumpWidget(
    wrapWithLocalization(
      Builder(
        builder: (BuildContext context) => MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: Scaffold(
            body: SingleChildScrollView(child: card),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The UIN reveal eye — the only `IconButton` the card draws.
Finder _revealEye() => find.byType(IconButton);

/// The QR control, as a control: a `Semantics(button: true)` around the tile.
Finder _qrButton() => find.byWidgetPredicate(
      (Widget w) => w is Semantics && w.properties.button == true,
    );

void main() {
  test('B10-AC-39 — the default is `true`, so B2b\'s call sites are unchanged',
      () {
    // A compile-time-visible default, asserted as a value. This is the whole
    // basis of the "additive" claim in § 3.1.
    const LaoIdCard card = LaoIdCard(authenticated: true);
    expect(card.interactive, isTrue);
  });

  group('B10-AC-39 — with `interactive: false` the three controls are gone',
      () {
    testWidgets('the UIN reveal eye is absent', (WidgetTester tester) async {
      await _pump(
        tester,
        const LaoIdCard(
          authenticated: true,
          name: 'Bounmy Sisavath',
          interactive: false,
        ),
      );
      expect(_revealEye(), findsNothing);
    });

    testWidgets('the QR is not a button — but the TILE still draws',
        (WidgetTester tester) async {
      await _pump(
        tester,
        const LaoIdCard(
          authenticated: true,
          name: 'Bounmy Sisavath',
          interactive: false,
        ),
      );

      expect(
        _qrButton(),
        findsNothing,
        reason: '`interactive ? <button> : <div aria-hidden>` — Hero.tsx:287',
      );
      expect(
        find.byType(ExcludeSemantics),
        findsWidgets,
        reason: 'the non-interactive branch is an `aria-hidden` picture, so '
            'the tile must still be in the tree — removing it would break '
            'what slide 3 promises',
      );
    });

    testWidgets('and the dialog cannot be opened by tapping the tile',
        (WidgetTester tester) async {
      await _pump(
        tester,
        const LaoIdCard(
          authenticated: true,
          name: 'Bounmy Sisavath',
          interactive: false,
        ),
      );

      expect(find.byType(InkWell), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('B10-AC-39 — with the default, all three are present', () {
    testWidgets('the eye and the QR button are there, and the QR dialog opens',
        (WidgetTester tester) async {
      await _pump(
        tester,
        const LaoIdCard(authenticated: true, name: 'Bounmy Sisavath'),
      );

      expect(
        _revealEye(),
        findsOneWidget,
        reason: 'the converse of the suppression tests — without this they '
            'would pass against a card that never draws an eye at all',
      );
      expect(_qrButton(), findsWidgets);

      // Target the QR tile specifically. The card draws two `InkWell`s and
      // several `Semantics(button:)` nodes, so both of the obvious finders are
      // ambiguous; the QR one is the branch labelled `hero.idTapVerify`.
      final Finder qrInk = find.descendant(
        of: find.bySemanticsLabel('hero.idTapVerify'.tr()),
        matching: find.byType(InkWell),
      );
      expect(qrInk, findsOneWidget);
      await tester.tap(qrInk);
      await tester.pumpAndSettle();

      expect(
        find.byType(AlertDialog),
        findsOneWidget,
        reason: 'Hero.tsx:316 — the verification dialog, via `showDialog`. '
            '§ 6.3: this is why `DialogShell` is out of scope — the framework '
            'supplies the barrier, the focus trap and Escape.',
      );
    });

    testWidgets('signed OUT, the eye is absent even when interactive — '
        '`authenticated && interactive`', (WidgetTester tester) async {
      await _pump(tester, const LaoIdCard(authenticated: false));
      expect(_revealEye(), findsNothing);
    });
  });

  group('B10-AC-38 — the composition slot really is a non-interactive LaoIdCard',
      () {
    testWidgets('`AppRoutes.splashSlide3Visual` builds the real card with '
        'authenticated: true, interactive: false',
        (WidgetTester tester) async {
      // The second half of AC-38. `splash_screens_test.dart` proves the splash
      // renders whatever the slot supplies; this proves what the slot supplies
      // is the REAL `LaoIdCard` and not a look-alike. Neither half is
      // sufficient alone.
      await tester.pumpWidget(
        wrapWithLocalization(
          Builder(
            builder: (BuildContext context) => MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Builder(
                    builder: (BuildContext inner) =>
                        AppRoutes.splashSlide3Visual(inner),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Finder cardFinder = find.byType(LaoIdCard);
      expect(cardFinder, findsOneWidget);

      final LaoIdCard card = tester.widget<LaoIdCard>(cardFinder);
      expect(card.authenticated, isTrue);
      expect(card.interactive, isFalse);
      expect(
        card.name,
        'onboarding.idHolderValue'.tr(),
        reason: 'the name comes from the onboarding namespace, resolved at the '
            'composition layer — `SplashScreens.tsx`:157',
      );
      expect(
        card.name,
        isNot(contains('onboarding.')),
        reason: 'a raw key here would mean the `.tr()` never resolved, which '
            'renders as literal "onboarding.idHolderValue" on the slide',
      );

      // And the suppression actually took effect in the rendered tree.
      expect(_revealEye(), findsNothing);
    });
  });
}

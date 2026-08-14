/// **BLOCKER-1** (`GOR-245-b9-chat-notifications/architecture-review.md` § 2) —
/// the panel must stay on the display when the soft keyboard is up.
///
/// ## Why the existing tests passed over the defect
///
/// This file exists because three tests that look like they cover this do not,
/// and the difference between them and this one is the specification:
///
/// 1. `pumpChatPanel` (`chat_test_helper.dart:313`) pumps at **390 × 1400** — a
///    viewport no handset has — and mounts the panel in `Scaffold(body:)`. The
///    body is not the slot production uses, and 1400 dp is enough room that no
///    computation of the origin can go wrong.
/// 2. `chat_launcher_test.dart:279-298` asserts `shell.floatingActionButton` is
///    non-null. That is the **wiring**; it would pass with a `SizedBox.shrink()`
///    in the slot. FACTORY-RULES' Capability Rule names exactly this shape: a
///    criterion is not discharged by proving a value propagated.
/// 3. No test anywhere applied a `viewInsets.bottom`, so the one input that
///    makes `FloatingActionButtonLocation.endFloat` move was never supplied.
///
/// So this file mounts through the **real seam** — `AppShell.floatingAction`,
/// which is `Scaffold.floatingActionButton` (`app_shell.dart:129`) — at real
/// handset sizes, with real keyboard insets, and asserts the **geometry**.
///
/// ## The one case that must NOT be "fixed"
///
/// 360 × 640 with no keyboard puts the panel's top at **y = 24**, 32 dp under a
/// 56 dp `AppBar`. A 640 px web viewport computes the same top of 24
/// (`CustomerServiceChat.tsx:199-202` — `fixed bottom-24`, `max-h-520`), so the
/// overlap is **faithful** and is pinned below precisely so a later
/// "improvement" trips this file. A port that is better than its source is a
/// divergence no fidelity tier can see.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:lcc_mobile_app/features/chat/presentation/widgets/chat_panel.dart';
import 'package:lcc_mobile_app/presentation/shell/app_shell.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

import '../../../helpers/app_test_harness.dart';
import '../../../helpers/core_test_helper.dart';
import '../chat_test_helper.dart';

/// The two handsets the review measured. Neither is 390 × 1400.
const Size kPixelClass = Size(390, 844);
const Size kSmallClass = Size(360, 640);

/// The insets the review measured — a Pixel-class and a small-class soft
/// keyboard respectively.
const double kPixelKeyboard = 336;
const double kSmallKeyboard = 300;

void main() {
  late ChatBloc bloc;

  /// Mounts an **open** panel in `AppShell.floatingAction` at [surface], with
  /// [keyboard] logical pixels of `viewInsets.bottom`.
  ///
  /// The real `AppShell` and not a bare `Scaffold`: the 56 dp `AppTopBar` and
  /// the 80 dp `AppBottomNav` are both inputs to
  /// `FloatingActionButtonLocation.endFloat`'s `contentBottom`, so a stand-in
  /// would compute a different origin from the one the app computes.
  ///
  /// [signedIn] defaults true, because the defect is in the app's central
  /// interaction — typing a message, which is what raises the keyboard — and
  /// the composer only exists in that state. The signed-out branch has its own
  /// group below and is not a variation for symmetry's sake: it is the branch
  /// with no flexible region, and it is where the first attempt at this fix
  /// overflowed.
  Future<void> pumpPanelInShell(
    WidgetTester tester, {
    required Size surface,
    required double keyboard,
    bool signedIn = true,
  }) async {
    bloc = chatBlocOver(FakeChatRepository());
    addTearDown(bloc.close);

    // dpr 1.0 so physical and logical pixels coincide and the numbers below
    // are the numbers the review's table reports.
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = surface;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrapWithLocalization(
        Builder(
          builder: (BuildContext context) => MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: AppShell(
              location: AppNameRoutes.home,
              storage: inMemoryStorageService(<String, String>{}),
              // THE SEAM. `app_routes.dart:335` hands
              // `BlocProvider<ChatBloc>(child: ChatLauncher())` here and
              // `ChatLauncher` renders `ChatPanel` while `state.open`
              // (`chat_launcher.dart:92-93`); the launcher's ternary is
              // `chat_launcher_test.dart`'s claim, the slot's geometry is this
              // file's.
              floatingAction: BlocProvider<ChatBloc>.value(
                value: bloc,
                child: const ChatPanel(),
              ),
              // A REAL scrolling page, not `SizedBox.shrink()`.
              //
              // Every shell route renders one, and it is load-bearing for the
              // panel's own scrollers: `ScrollController`'s primary attaches to
              // vertical scrollables on mobile, so a panel scroller that forgot
              // `primary: false` would take a second position on the SAME
              // controller and throw. With an empty body there is no first
              // position, nothing competes, and the test cannot see the bug —
              // which is how `pumpChatPanel`'s bare `Scaffold(body:)` misses it
              // too.
              child: ListView.builder(
                itemCount: 40,
                itemBuilder: (BuildContext context, int i) =>
                    SizedBox(height: 48, child: Text('row $i')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Pumped first, then driven — `chat_panel_test.dart` records why: a BLoC
    // driven outside `testWidgets`' FakeAsync zone accepts events it never
    // handles.
    if (signedIn) {
      bloc.add(const ChatAuthChanged(true));
      for (int i = 0; i < 3; i++) {
        await tester.pump();
      }
    }
    bloc.add(const ChatOpened());
    for (int i = 0; i < 5; i++) {
      await tester.pump();
    }
  }

  /// An open panel holds a live 4,000 ms `Timer.periodic` and `flutter_test`
  /// fails a test that completes with one pending. That is B9-AC-17's mechanism
  /// working.
  Future<void> shutdown(WidgetTester tester) async {
    if (!bloc.isClosed) {
      bloc.add(const ChatDismissed());
      await tester.pump();
      await tester.pump();
    }
  }

  /// Every combination shares these three claims.
  void assertOnScreen(WidgetTester tester, {required Size surface}) {
    final Rect panel = tester.getRect(find.byType(ChatPanel));

    expect(
      panel.top,
      greaterThanOrEqualTo(0),
      reason: 'BLOCKER-1. `endFloat` participates in `resizeToAvoidBottomInset`, '
          'so a child taller than the space left over gets a NEGATIVE origin '
          'and the panel HEADER — close, minimise, endConversation '
          '(`chat_panel.dart:179-216`) — leaves the display. Nothing throws and '
          'no scroll recovers it. Measured rect: $panel on $surface.',
    );

    // The bottom is allowed to be off — that half IS the web's behaviour
    // (`position: fixed` keeps the layout viewport, the keyboard covers the
    // panel's bottom). The top is not.
    expect(
      panel.left,
      greaterThanOrEqualTo(0),
      reason: 'the horizontal inset is `calc(100vw - 2rem)` (`:200`) and does '
          'not depend on the keyboard; if this moved, the width computation '
          'in `chat_panel.dart:73-76` changed. Measured: $panel',
    );

    final Rect close = tester.getRect(find.byIcon(Icons.close));
    expect(
      close.top,
      greaterThanOrEqualTo(0),
      reason: 'the close control itself is off the top of the display. '
          'Measured close-icon rect: $close, panel: $panel',
    );
    expect(
      close.bottom,
      lessThanOrEqualTo(surface.height),
      reason: 'measured close-icon rect: $close',
    );
  }

  /// Asserts that a real pointer at [finder]'s centre would land ON it.
  ///
  /// `tester.getRect(...).top >= 0` is not this claim: a widget can be inside
  /// the display and still be under something, or outside its parent's clip.
  /// This dispatches the binding's own hit test and requires the widget's
  /// render object to be on the resulting path.
  void expectHittable(WidgetTester tester, Finder finder) {
    final RenderObject target = tester.renderObject(finder);
    final Offset centre = tester.getCenter(finder);
    final HitTestResult result = tester.hitTestOnBinding(centre);
    expect(
      result.path.map((HitTestEntry<HitTestTarget> entry) => entry.target),
      contains(target),
      reason: 'a pointer at $centre does not reach '
          '${finder.describeMatch(Plurality.one)} (rect '
          '${tester.getRect(finder)}). An unreachable control is not a '
          'control.',
    );
  }

  /// Hittability, asserted by hitting it — not by reading its rect twice.
  ///
  /// A rect can be on screen and still be unreachable; the capability claim is
  /// that the tap reaches the BLoC.
  Future<void> assertCloseIsHittable(WidgetTester tester) async {
    expect(bloc.state.open, isTrue, reason: 'precondition');
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump();
    expect(
      bloc.state.open,
      isFalse,
      reason: 'the close control did not receive the tap — `ChatDismissed` '
          'never reached the BLoC (`chat_panel.dart:215`). An off-screen '
          'control is not a control.',
    );
  }

  group('BLOCKER-1 — the panel stays on screen with the keyboard up', () {
    testWidgets('390 x 844, keyboard 336 — was LTRB(16, -28, 374, 492)',
        (WidgetTester tester) async {
      await pumpPanelInShell(
        tester,
        surface: kPixelClass,
        keyboard: kPixelKeyboard,
      );

      assertOnScreen(tester, surface: kPixelClass);
      await assertCloseIsHittable(tester);
      await shutdown(tester);
    });

    testWidgets('360 x 640, keyboard 300 — was LTRB(16, -196, 344, 324), '
        'the worst measured case', (WidgetTester tester) async {
      await pumpPanelInShell(
        tester,
        surface: kSmallClass,
        keyboard: kSmallKeyboard,
      );

      assertOnScreen(tester, surface: kSmallClass);
      await assertCloseIsHittable(tester);
      await shutdown(tester);
    });
  });

  group('the keyboard-down cases are unchanged — do NOT "improve" these', () {
    testWidgets('390 x 844, no keyboard — LTRB(16, 228, 374, 748), the full '
        '520 dp cap', (WidgetTester tester) async {
      await pumpPanelInShell(tester, surface: kPixelClass, keyboard: 0);

      final Rect panel = tester.getRect(find.byType(ChatPanel));
      expect(
        panel,
        // `rectMoreOrLessEquals`, not `equals`: the view's dpr scaling leaves
        // the coordinates a few ulps off the integers — the measured top here
        // is 227.99999999999994, and exact equality fails while PRINTING
        // `228.0`, which is a false negative that costs an hour.
        rectMoreOrLessEquals(const Rect.fromLTRB(16, 228, 374, 748),
            epsilon: 0.01),
        reason: 'the 520 dp cap (`chat_panel.dart:53`, `:202`) is preserved '
            'wherever 520 dp exists. If this moved, the fix stopped being a '
            'clamp and started being a redesign.',
      );
      expect(panel.height, moreOrLessEquals(kChatPanelMaxHeight, epsilon: 0.01));

      assertOnScreen(tester, surface: kPixelClass);
      await shutdown(tester);
    });

    testWidgets('360 x 640, no keyboard — top is 24 and the 32 dp AppBar '
        'overlap is FAITHFUL', (WidgetTester tester) async {
      await pumpPanelInShell(tester, surface: kSmallClass, keyboard: 0);

      final Rect panel = tester.getRect(find.byType(ChatPanel));
      expect(
        panel,
        rectMoreOrLessEquals(const Rect.fromLTRB(16, 24, 344, 544),
            epsilon: 0.01),
        reason: 'A 640 px WEB viewport computes the same top of 24 from '
            '`fixed bottom-24` + `max-h-520` (`CustomerServiceChat.tsx:199-202`) '
            'against a 56 dp bar, so the 32 dp overlap is the SOURCE\'s '
            'behaviour. Pinned so a future "improvement" trips here. If you are '
            'reading this because you made the overlap go away, you introduced '
            'a divergence no fidelity tier can see — see '
            'architecture-review.md § 2 BLOCKER-1.',
      );
      expect(panel.height, moreOrLessEquals(kChatPanelMaxHeight, epsilon: 0.01));
      await shutdown(tester);
    });
  });

  group('the minimised panel is unaffected — `:202`\'s 64 px branch', () {
    testWidgets('the header\'s own 60 dp at 360 x 640 with the keyboard up',
        (WidgetTester tester) async {
      await pumpPanelInShell(
        tester,
        surface: kSmallClass,
        keyboard: kSmallKeyboard,
      );
      bloc.add(const ChatMinimizeToggled());
      await tester.pump();
      await tester.pump();

      final Rect panel = tester.getRect(find.byType(ChatPanel));
      // MEASURED, and it corrects a premise worth stating: the minimised panel
      // is **60 dp, not 64**. `kChatPanelMinimizedHeight` is a `maxHeight` on a
      // `Column(mainAxisSize: min)` whose only child is the 60 dp header
      // (12 + 36 avatar + 12 padding), so the 64 px cap at `:202` is NOT the
      // binding constraint here and never was. Pinning 64 would have pinned a
      // number the tree has never produced.
      expect(panel.height, moreOrLessEquals(60, epsilon: 0.01),
          reason: '`maxHeight: minimized ? "64px" : "520px"` — `:202` — is a '
              'CAP; the header is shorter than it. The keyboard clamp must not '
              'reach down and shrink this branch further.');
      expect(panel.height, lessThanOrEqualTo(kChatPanelMinimizedHeight));
      expect(panel.top, greaterThanOrEqualTo(0), reason: '$panel');
      await shutdown(tester);
    });
  });

  group('the SIGNED-OUT branch survives the clamp', () {
    // This group is not symmetry. The first attempt at the BLOCKER-1 fix
    // clamped the height and stopped there, and this branch — header 60 dp +
    // a 304 dp `ChatSignInPrompt`, with NO flexible child between them —
    // overflowed by exactly 40 dp at 360 x 640 / 300. That would have traded a
    // panel that goes off screen for a panel that paints yellow stripes: a
    // different defect, not a fix. `chat_panel.dart` now makes the prompt the
    // give-way region, and this is what holds it there.
    //
    // Reachable in production: a citizen with the keyboard already up from a
    // field on the page behind taps the launcher while signed out.
    testWidgets('360 x 640, keyboard 300 — no overflow, and the sign-in '
        'button is still reachable', (WidgetTester tester) async {
      await pumpPanelInShell(
        tester,
        surface: kSmallClass,
        keyboard: kSmallKeyboard,
        signedIn: false,
      );

      // A `RenderFlex` overflow throws in debug, so reaching this line at all
      // is half the claim; `flutter_test` would have failed the test already.
      expect(find.byType(ChatSignInPrompt), findsOneWidget);
      assertOnScreen(tester, surface: kSmallClass);

      final Rect panel = tester.getRect(find.byType(ChatPanel));
      expect(panel.bottom, lessThanOrEqualTo(kSmallClass.height),
          reason: 'clamped to the space above the keyboard: $panel');

      // The state's entire purpose. Scrolled to if need be, but present and
      // hittable — clipping it would leave a panel whose only affordance is
      // under the fold.
      //
      // The clamp DOES hide part of it before the scroll: the prompt is 304 dp
      // and only 264 remain under the 60 dp header, so 40 dp — the button's
      // lower half — starts off the bottom. That is what the scroller is for.
      await tester.scrollUntilVisible(
        find.byType(FilledButton),
        60,
        // The scroller wraps the prompt, so it is an ancestor of it; scoped to
        // the panel because the page behind has scrollables of its own.
        scrollable: find.descendant(
          of: find.byType(ChatPanel),
          matching: find.byType(Scrollable),
        ),
      );

      // Hit-tested rather than tapped. `ChatSignInPrompt`'s `onPressed` runs
      // `context.go(AppNameRoutes.signin)` (`:378`) and there is no router in
      // this tree — tapping would assert the absence of a `GoRouter`, not the
      // reachability of the button. The hit test is the capability claim
      // without the navigation.
      expectHittable(tester, find.byType(FilledButton));
      await shutdown(tester);
    });

    testWidgets('390 x 844, no keyboard — the prompt is its natural height and '
        'does NOT scroll', (WidgetTester tester) async {
      // The scroller must be layout-neutral where the room exists, or the fix
      // has changed the signed-out panel everywhere to solve a case that only
      // occurs with the keyboard up.
      await pumpPanelInShell(
        tester,
        surface: kPixelClass,
        keyboard: 0,
        signedIn: false,
      );

      final Rect prompt = tester.getRect(find.byType(ChatSignInPrompt));
      // 286 at 390 wide, 304 at 360 wide — the body copy wraps to one fewer
      // line on the wider surface, so the number is width-dependent and the
      // 304 the signed-out clamp case reasons about is the 360 figure.
      expect(prompt.height, moreOrLessEquals(286, epsilon: 0.01),
          reason: 'unchanged by the fix — the scroller shrink-wraps');

      final ScrollableState scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(ChatPanel),
          matching: find.byType(Scrollable),
        ),
      );
      expect(scrollable.position.maxScrollExtent, 0,
          reason: 'the `SingleChildScrollView` shrink-wraps where there is '
              'room, so it adds a scroller with nothing to scroll — the '
              'signed-out panel is byte-for-byte what it was');
      await shutdown(tester);
    });
  });

  group('why MediaQuery and not LayoutBuilder — the premise, measured', () {
    testWidgets('a LayoutBuilder in the FAB slot is handed the WHOLE screen '
        'height, keyboard or not', (WidgetTester tester) async {
      // `chat_panel.dart`'s `chatPanelAvailableHeight` doc claims this, and a
      // claim in a doc comment is worth what it is measured at. If Flutter ever
      // changes `_ScaffoldLayout` to lay the FAB slot out against the *inset*
      // constraints, this test goes red and the simpler `LayoutBuilder` form
      // becomes available.
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = kPixelClass;
      tester.view.viewInsets = const FakeViewPadding(bottom: kPixelKeyboard);
      addTearDown(tester.view.reset);

      late BoxConstraints seen;
      await tester.pumpWidget(
        wrapWithLocalization(
          Builder(
            builder: (BuildContext context) => MaterialApp(
              theme: AppTheme.light(),
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: AppShell(
                location: AppNameRoutes.home,
                storage: inMemoryStorageService(<String, String>{}),
                floatingAction: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    seen = constraints;
                    return const SizedBox(width: 56, height: 56);
                  },
                ),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(seen.maxHeight, moreOrLessEquals(kPixelClass.height, epsilon: 0.01),
          reason: '`_ScaffoldLayout` lays the FAB slot out with '
              '`BoxConstraints.loose(<the whole Scaffold size>)`, so the 336 dp '
              'keyboard is INVISIBLE here — 844, not 508. A `LayoutBuilder` '
              'clamp would have computed the same 520 dp the defect computes. '
              'Only `MediaQuery.viewInsetsOf` carries the inset.');
      expect(seen.maxHeight, isNot(moreOrLessEquals(
          kPixelClass.height - kPixelKeyboard, epsilon: 0.01)));
    });
  });
}

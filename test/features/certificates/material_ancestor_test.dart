/// **GOR-267** — the assertion that would have caught it, and the four gaps the
/// first attempt at this file left open.
///
/// ## The defect
///
/// Three full-frame render roots on two citizen-facing routes composed no
/// `Material` ancestor and no `SafeArea`:
/// `_ResidentCertificatePageState.build`, `FamilyBookFrame.build` and
/// `FamilyBookSuccess.build`. Every `Text` beneath them inherited
/// `WidgetsApp._errorTextStyle` — 48px red monospace with a **yellow double
/// underline**, whose own `debugLabel` reads *"fallback style; consider putting
/// your text in a Material"* — and their content drew under the status bar. In
/// an assert-enabled build the same absence also made every
/// `debugCheckHasMaterial` control on the Resident route **throw instead of
/// build**: fifteen `ResidentInputField` sites across steps 2-6, the
/// nationality/purpose `DropdownButton`s, and the payment step's bank selector,
/// card fields and method `InkWell`.
///
/// ## Why 3,501 tests passed over it
///
/// **The suite was asserting against its own harness.** Every widget test for
/// these pages pumps them under a `MaterialApp` — usually with a `Scaffold` —
/// that the test supplies. The running app does not: `MaterialApp.router` gives
/// `Theme`, `Directionality`, `MediaQuery` and `Localizations`, but **not** a
/// `Material`, and the route builders are `BlocProvider` → `Builder` → page
/// with nothing in between. The harness manufactured the exact ancestor whose
/// absence was the defect, so a page test cannot catch this **by
/// construction** — which is why this file exists rather than an extra `expect`
/// in a page test.
///
/// ## What this file does differently
///
/// It mounts through **`AppRoutes.build`'s real route builder under a real
/// router**, with **no `Scaffold` supplied by the test**, and it anchors
/// navigation on `find.byType(Navigator).first` rather than
/// `find.byType(Scaffold).first` — the latter throws before reaching the
/// assertion on exactly the two broken routes, hiding the defect a second time.
///
/// **It runs over all six routes, not the two that were broken.** Birth, death,
/// marriage and divorce are the control: they prove the assertion is capable of
/// passing, so a green result over the two fixed ones is evidence rather than an
/// artefact of a test that can only pass. Without them this file would be
/// indistinguishable from one that asserts nothing — the same standard
/// `test/architecture/guard_selftest_test.dart` holds the guard suite to.
///
/// ## The four things a Material-above-`Text.first` check does NOT cover
///
/// A `Material` above the page's first `Text` is a *local* claim. It says
/// nothing about a control in a sibling subtree, nothing about a render root
/// that only appears mid-boot, nothing about a branch `pumpAndSettle` never
/// reaches, and nothing about the safe-area half of the same fault. Each is a
/// separate test below:
///
/// * **T-2** — `app_routes.dart:1050-1084` renders `FamilyBookFrame`
///   **directly** in the `SessionStatus.initial | loading` branch, before
///   `FamilyBookPage` is ever constructed. `go()` + `pumpAndSettle()` only ever
///   observes the settled state, so that render root is otherwise never
///   asserted — and a fix sited in `family_book_page.dart` instead of in
///   `FamilyBookFrame` would leave it broken.
/// * **T-3** — `FamilyBookSuccess` is the one family-book path that bypasses the
///   frame (`family_book_page.dart:141`). `showsSuccess` needs a non-null `book`
///   *and* a `submitted`, and `GET /me/family-book` answers 404 on every account
///   this programme has, so it is unreachable in practice. An explicit test is
///   the only thing that can hold it.
/// * **T-4** — **the discriminator.** A `DefaultTextStyle`-only "fix" closes the
///   reported symptom completely and leaves every `debugCheckHasMaterial`
///   control still throwing. This test asserts a real control **builds without
///   throwing** on the production ambient, at the control, not above the first
///   `Text`.
/// * **T-5** — the missing `SafeArea` is the *other half of the same fault*. A
///   fix passing T-1…T-4 and not T-5 has not installed the page-chrome idiom the
///   six correct siblings use.
///
/// T-6 is not a coverage gap — it is the validation GOR-267-AC-6 asks for of the
/// one behavioural side effect the fix produces that nobody requested: a
/// `Scaffold`'s `resizeToAvoidBottomInset` now applies to the Resident payment
/// step's card fields.
///
/// ## What this file does NOT assert
///
/// That the pages look right. Only that their text is not rendered in the
/// framework's deliberate-eyesore fallback, that their content is inset below
/// system chrome, and that their Material-requiring controls can build. Pixel
/// fidelity is Tier 3's.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/session/bloc/session_bloc.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_certificate_page.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_form_cubit.dart';
import 'package:lcc_mobile_app/features/family_book/presentation/pages/family_book_page.dart';
import 'package:lcc_mobile_app/features/family_book/presentation/widgets/family_book_chrome.dart';
import 'package:lcc_mobile_app/features/family_book/presentation/widgets/family_book_success.dart';
import 'package:lcc_mobile_app/presentation/payment/payment_draft.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

import '../../helpers/app_test_harness.dart';
import '../../helpers/core_test_helper.dart';
import '../../helpers/session_test_helper.dart';
import '../family_book/family_book_test_helper.dart';

/// Every route B12 mounted, with the two that were broken flagged so a reader
/// can see at a glance which four are the control.
const Map<String, bool> _routes = <String, bool>{
  AppNameRoutes.residentCertificate: true, // GOR-267 — was broken
  AppNameRoutes.familyBook: true, //          GOR-267 — was broken
  AppNameRoutes.birthDeclaration: false, //   control
  AppNameRoutes.deathDeclaration: false, //   control
  AppNameRoutes.marriageCertificate: false, // control
  AppNameRoutes.divorceCertificate: false, // control
};

/// A non-zero top inset, in **physical** pixels at the test view's default
/// device pixel ratio of 3 — i.e. 44 logical pixels, an iPhone-class notch.
///
/// T-5's behavioural variant needs the view to actually *have* a safe-area
/// inset: the widget-test view reports zero padding by default, under which
/// `SafeArea` is a no-op and its presence proves nothing about what a device
/// would render.
const double _kTopPaddingPhysical = 132.0;
const double _kTopPaddingLogical = 44.0;

/// The signed-in warm boot the six routes need: they are all in
/// `AppRoutes._protectedPaths`, so an unauthenticated citizen is redirected to
/// `/signin` and every assertion below would be about `AuthPage`.
Future<AppHarness> _bootSignedIn() async {
  final AppHarness harness = await bootHarness(
    seed: <String, String>{StorageKeys.accessToken: 'access-abc'},
  );
  harness.adapter.onGet(
    ApiEndpoint.meProfile,
    (dynamic server) => server.reply(200, okEnvelope(tCitizenProfileJson())),
  );
  stubCertificateEndpoints(harness.adapter);
  return harness;
}

/// The router, reached through `Navigator` and never through `Scaffold` — see
/// the library doc.
GoRouter _routerOf(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Navigator).first));

String _locationOf(WidgetTester tester) =>
    _routerOf(tester).routerDelegate.currentConfiguration.uri.path;

/// The `BuildContext` of the first rendered `Text` — the element every
/// inheritance question below is asked from.
BuildContext _firstTextContext(WidgetTester tester) =>
    tester.element(find.byType(Text).first);

void main() {
  tearDown(resetHarness);

  // ── T-1 — the reported symptom, on all six routes ─────────────────────────
  group('T-1 (GOR-267-AC-1) a Material ancestor above the page text', () {
    for (final MapEntry<String, bool> entry in _routes.entries) {
      final String route = entry.key;
      final String kind = entry.value ? 'was broken' : 'control';

      testWidgets('$route ($kind)', (WidgetTester tester) async {
        final AppHarness harness = await _bootSignedIn();

        // The real app: `main.dart`'s `App` → `MaterialApp.router` →
        // `AppRoutes.build`'s builders. Nothing here supplies a Scaffold.
        await pumpAssembledApp(tester, harness);
        _routerOf(tester).go(route);
        await tester.pumpAndSettle();

        expect(_locationOf(tester), route,
            reason: 'the navigation never landed, so everything below would '
                'be asserted against the previous route');
        expect(find.byType(Text), findsWidgets,
            reason: '$route rendered no Text at all, so this assertion would '
                'pass vacuously');

        // The claim: the first Text found on this page sits beneath a
        // `Material`. `Scaffold` inserts one; a bare `ColoredBox`/`Column`
        // does not.
        expect(
          find.ancestor(
            of: find.byType(Text).first,
            matching: find.byType(Material),
          ),
          findsWidgets,
          reason: 'No Material ancestor above the first Text on $route. Every '
              'Text on this page therefore inherits WidgetsApp._errorTextStyle '
              '— 48px red monospace, yellow double underline — in RELEASE as '
              'well as debug. The fix is a Scaffold in the page, matching the '
              'four siblings and the four other full-frame routes. It is NOT a '
              'ShellRoute re-parent: Layout.tsx:300 + :388 show the source '
              'renders all six full-frame, so re-parenting would add a brand '
              'bar, a bottom nav and a chat FAB the source hides — an ssd.md '
              'section 11.2 L-10 regression (GOR-267 root-cause.md section '
              '7.4).',
        );

        // The same claim, stated the other way, because it is the one a reader
        // recognises: the inherited style must not be the framework's fallback.
        final TextStyle inherited =
            DefaultTextStyle.of(_firstTextContext(tester)).style;
        expect(
          inherited.decoration,
          isNot(TextDecoration.underline),
          reason: 'the inherited DefaultTextStyle on $route is '
              'WidgetsApp._errorTextStyle, whose debugLabel is literally '
              '"fallback style; consider putting your text in a Material"',
        );
        expect(inherited.debugLabel ?? '', isNot(contains('fallback style')));
      });
    }
  });

  // ── T-5 — the other half of the same fault ────────────────────────────────
  group('T-5 (GOR-267-AC-5) the top safe-area inset', () {
    for (final MapEntry<String, bool> entry in _routes.entries) {
      final String route = entry.key;
      final String kind = entry.value ? 'was broken' : 'control';

      testWidgets('$route ($kind)', (WidgetTester tester) async {
        // Behavioural, not merely structural: a `SafeArea` under a view with
        // zero padding is indistinguishable from no `SafeArea` at all, so the
        // notch is given to the view first and the assertion is that something
        // consumed it.
        tester.view.padding = const FakeViewPadding(top: _kTopPaddingPhysical);
        addTearDown(tester.view.reset);

        final AppHarness harness = await _bootSignedIn();
        await pumpAssembledApp(tester, harness);
        _routerOf(tester).go(route);
        await tester.pumpAndSettle();

        expect(_locationOf(tester), route);
        expect(find.byType(Text), findsWidgets,
            reason: 'no Text on $route, so the offset assertion would be '
                'vacuous');

        // Structural: the idiom is installed at all.
        expect(
          find.ancestor(
            of: find.byType(Text).first,
            matching: find.byType(SafeArea),
          ),
          findsWidgets,
          reason: 'No SafeArea ancestor above the page content on $route. The '
              'missing SafeArea is the other half of GOR-267 — one omission '
              'with two symptoms — and a fix that installs a Material without '
              'it has not installed the page-chrome idiom the six correct '
              'siblings use.',
        );

        // Behavioural: the inset was actually consumed. `SafeArea` wraps its
        // child in `MediaQuery.removePadding`, so a page whose text still sees
        // the notch is a page nothing inset.
        expect(
          MediaQuery.paddingOf(_firstTextContext(tester)).top,
          0.0,
          reason: 'the ${_kTopPaddingLogical}px top inset reaches the page '
              'content unconsumed on $route — its text draws under the status '
              'bar and the notch',
        );

        // And the content really moved: everything below the SafeArea starts
        // below the inset.
        expect(
          tester.getTopLeft(find.byType(Text).first).dy,
          greaterThanOrEqualTo(_kTopPaddingLogical),
          reason: 'the first Text on $route paints inside the '
              '${_kTopPaddingLogical}px system-chrome band',
        );
      });
    }
  });

  // ── T-2 — the render root that only exists mid-boot ───────────────────────
  testWidgets(
      'T-2 (GOR-267-AC-2) the session-loading branch of the family-book route '
      'builder renders FamilyBookFrame with a Material ancestor',
      (WidgetTester tester) async {
    // `app_routes.dart:1059` returns a `FamilyBookFrame` **directly** while
    // `SessionStatus` is `initial` or `loading`, before `FamilyBookPage` is
    // constructed at all. `_redirect` deliberately holds rather than redirects
    // during that window, so this is a real render root a citizen reaches on
    // every cold deep link — and `pumpAndSettle` never observes it.
    tester.view.padding = const FakeViewPadding(top: _kTopPaddingPhysical);
    addTearDown(tester.view.reset);

    final AppHarness harness = await bootHarness(
      seed: <String, String>{StorageKeys.accessToken: 'access-abc'},
    );
    stubCertificateEndpoints(harness.adapter);
    // A slow profile call widens the boot window so the hold is observable
    // rather than raced away by an instant in-memory reply.
    harness.adapter.onGet(
      ApiEndpoint.meProfile,
      (dynamic server) => server.reply(
        200,
        okEnvelope(tCitizenProfileJson()),
        delay: const Duration(milliseconds: 300),
      ),
    );

    // One frame, deliberately not settled.
    await mountAssembledApp(tester, harness);
    await tester.pump();

    _routerOf(tester).go(AppNameRoutes.familyBook);
    // Two pumps, the second advancing time *inside* the 300 ms window: one
    // frame leaves the route transition unfinished, and every finder below
    // would then be empty for a reason that has nothing to do with GOR-267.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The premise. Without this the test could pass against the settled state
    // and never touch the branch it exists for.
    expect(
      harness.sessionBloc.state.status,
      anyOf(SessionStatus.initial, SessionStatus.loading),
      reason: 'the boot hold closed before the branch could be observed',
    );
    expect(_locationOf(tester), AppNameRoutes.familyBook);
    expect(find.byType(FamilyBookFrame), findsOneWidget);
    expect(find.byType(FamilyBookPage), findsNothing,
        reason: 'this must be the route builder\'s own FamilyBookFrame, not '
            'the one FamilyBookPage renders — siting the fix in '
            'family_book_page.dart would leave THIS render root broken');

    final Finder frameText = find.descendant(
      of: find.byType(FamilyBookFrame),
      matching: find.byType(Text),
    );
    expect(frameText, findsWidgets);
    expect(
      find.ancestor(of: frameText.first, matching: find.byType(Material)),
      findsWidgets,
      reason: 'app_routes.dart:1059 renders a FamilyBookFrame with no Material '
          'above it: the defect reappears for as long as the session is '
          'resolving',
    );
    expect(
      find.ancestor(of: frameText.first, matching: find.byType(SafeArea)),
      findsWidgets,
    );
    expect(MediaQuery.paddingOf(tester.element(frameText.first)).top, 0.0);

    // Drain the 300 ms profile call. Without this the boot window is still open
    // when the tree is disposed and the binding fails the test on a pending
    // timer — a failure about the test's own bookkeeping, not about GOR-267.
    await tester.pumpAndSettle();
  });

  // ── T-3 — the branch pumpAndSettle can never reach ────────────────────────
  testWidgets(
      'T-3 (GOR-267-AC-4) FamilyBookSuccess has a Material ancestor above its '
      'text', (WidgetTester tester) async {
    // **Mechanism: direct mount under the production ambient**, the minimum
    // acceptable substitute specs.md section 7.1 names for T-3, taken and
    // recorded rather than skipped. `showsSuccess` needs a non-null `book` AND
    // a `submitted`, and `GET /me/family-book` answers 404 on every account
    // this programme has (`family_book_remote_datasource.dart:26`), so the
    // route-level path would have to stub a household the programme has never
    // seen and drive three steps plus a write to reach one render root.
    //
    // What is mounted here is exactly what `family_book_page.dart:141` returns,
    // under exactly what `MaterialApp.router` supplies — `Theme`,
    // `Directionality`, `MediaQuery`, `Localizations`, and **no `Material`**.
    // No `Scaffold` is supplied by this test.
    tester.view.padding = const FakeViewPadding(top: _kTopPaddingPhysical);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrapWithLocalization(
        Builder(
          builder: (BuildContext context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: FamilyBookSuccess(
              book: householdFixture(),
              submitted: applicationRowFixture(),
              onBack: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FamilyBookSuccess), findsOneWidget);
    expect(find.byType(Text), findsWidgets);
    expect(
      find.ancestor(
        of: find.byType(Text).first,
        matching: find.byType(Material),
      ),
      findsWidgets,
      reason: 'FamilyBookSuccess is the one family-book render path that does '
          'not go through FamilyBookFrame, so it needs its own page chrome for '
          'the same reason',
    );
    final TextStyle inherited =
        DefaultTextStyle.of(_firstTextContext(tester)).style;
    expect(inherited.decoration, isNot(TextDecoration.underline));
    expect(inherited.debugLabel ?? '', isNot(contains('fallback style')));
    expect(
      find.ancestor(
        of: find.byType(Text).first,
        matching: find.byType(SafeArea),
      ),
      findsWidgets,
    );
    expect(MediaQuery.paddingOf(_firstTextContext(tester)).top, 0.0);
  });

  // ── T-4 — the discriminator ───────────────────────────────────────────────
  testWidgets(
      'T-4 (GOR-267-AC-3) a Material-asserting Resident control builds without '
      'throwing on the real route', (WidgetTester tester) async {
    // **This is the criterion that distinguishes the fix from a
    // `DefaultTextStyle`-only one.** T-1 is a local claim about the first
    // `Text`; it says nothing about a control in a sibling subtree, and a
    // styling-only fix passes it while every `debugCheckHasMaterial` control on
    // this route still throws. The assertion has to be made **at the control**.
    //
    // Mechanism: route-level — the page is mounted through `AppRoutes.build`'s
    // real builder under the real router, exactly as T-1 mounts it. The step is
    // advanced by writing the cubit's state rather than by tapping the CTA
    // because `next()` gates on `residentCanProceed`, which step 1 satisfies
    // only after four real file picks; the wizard subtree under test is the
    // same either way, and this keeps the test deterministic. The idiom is
    // `resident_page_widget_test.dart:265`'s.
    final AppHarness harness = await _bootSignedIn();
    await pumpAssembledApp(tester, harness);
    _routerOf(tester).go(AppNameRoutes.residentCertificate);
    await tester.pumpAndSettle();

    expect(_locationOf(tester), AppNameRoutes.residentCertificate);
    expect(find.byType(ResidentCertificatePage), findsOneWidget);

    // Step 2 is where QA's executed `FlutterError` fired: the nationality
    // `ReferenceSelectView` (`reference_select_view.dart:211`, a raw
    // `DropdownButton<String>`) and two `ResidentInputField` text fields mount
    // there.
    final ResidentFormCubit cubit =
        tester.widget<ResidentCertificatePage>(
      find.byType(ResidentCertificatePage),
    ).cubit;
    cubit.emit(cubit.state.copyWith(step: 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Half the claim: nothing threw. On the unfixed tree
    // `debugCheckHasMaterial` throws *"No Material widget found.
    // DropdownButton<String> widgets require a Material widget ancestor"*
    // before the control can build at all.
    expect(
      tester.takeException(),
      isNull,
      reason: 'a Material-asserting control on Resident step 2 threw while '
          'building under the production ambient — the fix supplies styling '
          'but not a real Material (fix-plan.md Option B)',
    );

    // The other half: the controls are actually there, under a Material. A
    // route that silently rendered none would make the first half vacuous.
    expect(find.byType(DropdownButton<String>), findsWidgets,
        reason: 'step 2 mounts no DropdownButton, so takeException() being '
            'null proves nothing');
    expect(
      find.ancestor(
        of: find.byType(DropdownButton<String>).first,
        matching: find.byType(Material),
      ),
      findsWidgets,
    );
    expect(find.byType(TextField), findsWidgets,
        reason: 'step 2 mounts ResidentInputField, the resident form\'s base '
            'text input — fifteen call sites across steps 2-6');
    expect(
      find.ancestor(
        of: find.byType(TextField).first,
        matching: find.byType(Material),
      ),
      findsWidgets,
    );
  });

  // ── T-6 — GOR-267-AC-6: the one unasked-for behavioural delta ─────────────
  testWidgets(
      'T-6 (GOR-267-AC-6) the soft keyboard reflows the Resident payment step '
      'and leaves the card fields usable', (WidgetTester tester) async {
    // `Scaffold.resizeToAvoidBottomInset` defaults to true, so the fix makes
    // `MediaQuery.viewInsets` — previously unconsumed on this route — shrink
    // the body when the soft keyboard rises. That is a behaviour change on the
    // payment step, and `fix-plan.md` section A7 delta 4 hands it here to be
    // validated rather than assumed.
    //
    // **The affected control, corrected.** `root-cause.md` section 6.2 item 2,
    // `fix-plan.md` A7 delta 4 and `specs.md` GOR-267-AC-6 all call
    // `draft_payment_section.dart:908` "the bank-account TextField". It is not:
    // line 908 is inside `_CardInputState.build`, the shared input backing the
    // **card** panel's four fields — number, cardholder name, expiry and CVV
    // (`draft_payment_section.dart:617-676`). `_BankPanel` contains no
    // `TextField` at all; bank selection is a `DropdownButton`, which raises no
    // keyboard. Corrected by the GOR-267 Stage 6 security review, section 3.1.
    final AppHarness harness = await _bootSignedIn();
    await pumpAssembledApp(tester, harness);
    _routerOf(tester).go(AppNameRoutes.residentCertificate);
    await tester.pumpAndSettle();

    final ResidentFormCubit cubit =
        tester.widget<ResidentCertificatePage>(
      find.byType(ResidentCertificatePage),
    ).cubit;
    cubit.emit(cubit.state.copyWith(step: 6));
    // `method` defaults to `qr`; the card panel is the one that mounts
    // `TextField`s.
    cubit.setPayment(
      cubit.state.form.payment.copyWith(method: DraftPaymentMethod.cc),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsWidgets,
        reason: 'the card panel mounts four _CardInput TextFields');

    final double bodyHeightNoKeyboard =
        tester.getSize(find.byType(SafeArea).first).height;

    // Raise the soft keyboard.
    tester.view.viewInsets = const FakeViewPadding(bottom: 600.0); // 200 dp
    addTearDown(tester.view.reset);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull,
        reason: 'raising the soft keyboard on the payment step overflowed or '
            'threw');

    final double bodyHeightWithKeyboard =
        tester.getSize(find.byType(SafeArea).first).height;
    expect(
      bodyHeightWithKeyboard,
      lessThan(bodyHeightNoKeyboard),
      reason: 'the body did not reflow: resizeToAvoidBottomInset is not in '
          'effect, so the keyboard overlays the card fields instead of '
          'shrinking the form around them',
    );

    // Interaction still works with the keyboard up — the field accepts input
    // and the draft records it, unchanged by the reflow.
    await tester.enterText(find.byType(TextField).first, '4111111111111111');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(cubit.state.form.payment.cardNumber, '4111 1111 1111 1111',
        reason: 'the card-number field still captures and formats input while '
            'the keyboard is up');
  });
}

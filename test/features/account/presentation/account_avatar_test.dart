/// **B8b's control and its state machine — B8-AC-53, B8-AC-54, B8-AC-55, and
/// the two ported-as-measured weaknesses GG-7 and GG-8.**
///
/// Split from `account_header_test.dart` rather than appended to it: that file
/// is B8a's and its subject is the *render* (V-16/V-17, the initial tile, the
/// gradient). This one's subject is the *control*, which is a different batch
/// with a different gate.
///
/// ## What each case would look like if the thing it names were absent
///
/// The Capability Rule, applied case by case, because three of these are easy
/// to write vacuously:
///
/// * A tap-target case that only asserts `find.byType(GestureDetector)` passes
///   on any avatar — so the case below **taps** and asserts the picker ran.
/// * A badge case that only counts `LucideIcon`s passes with the wrong glyph,
///   because `AppIcons.assetFor` silently substitutes `FileText` for an
///   unbundled name. So the cases below assert the resolved **asset path**.
/// * A re-pick case that picks two *different* files passes against an
///   implementation that deduplicates by content. So the case below picks the
///   **same** file twice and asserts two uploads.
///
/// ## Fixtures are synthetic — B8-AC-35
///
/// `tPickedAvatar()` and `tAccount()` from `account_test_helper.dart`. No real
/// citizen, and no photograph of anybody.
library;

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/usecase/usecase.dart';
import 'package:lcc_mobile_app/features/account/domain/entities/picked_avatar.dart';
import 'package:lcc_mobile_app/features/account/domain/usecases/account_usecases.dart';
import 'package:lcc_mobile_app/features/account/presentation/bloc/account_profile_bloc.dart';
import 'package:lcc_mobile_app/features/account/presentation/widgets/account_header.dart';
import 'package:lcc_mobile_app/presentation/icons/app_icons.dart';
import 'package:lcc_mobile_app/presentation/icons/lucide_icon.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';

import '../../../helpers/app_test_harness.dart';
import '../account_test_helper.dart';

/// The asset a badge glyph must resolve to, by lucide name.
String _asset(String name) => AppIcons.assetFor(name);

/// Every [LucideIcon] currently in the tree, by the asset it will actually
/// paint — **not** by the `name` it was handed.
///
/// The distinction is the point: `LucideIcon(name: 'Camera')` with `Camera`
/// unbundled renders `FileText`, and a test reading `.name` would never know.
/// Scoped to the **badge**, deliberately: the header also renders a
/// `CheckCircle` inside the "Verified Citizen" chip below the name, so an
/// unscoped read cannot tell the badge's tick from the chip's.
List<String> _badgeAssets(WidgetTester tester) => tester
    .widgetList<LucideIcon>(
      find.descendant(of: _badge, matching: find.byType(LucideIcon)),
    )
    .map((LucideIcon i) => _asset(i.name))
    .toList();

/// Pumps the header **without settling**.
///
/// `pumpAccountWidget` ends in `pumpAndSettle`, which never returns once the
/// badge's `animate-spin` is on screen — an infinite `AnimationController`
/// has no settled state. So this file owns its pump: three frames, enough for
/// `EasyLocalization` to load `assets/i18n` and for the tree to build, and no
/// more. Same delegate wiring as the shared helper, and load-bearing for the
/// same reason: without it `.tr()` answers the raw key and
/// `find.bySemanticsLabel('Change photo')` would be comparing against
/// `"account.photoHint"`.
Future<void> _pumpHeader(
  WidgetTester tester, {
  required bool uploading,
  required bool verified,
  required VoidCallback onPick,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(390, 1400);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(wrapWithLocalization(
    Builder(
      builder: (BuildContext context) => MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: Scaffold(
          body: AccountHeader(
            account: tAccount(verified: verified),
            loading: false,
            uploading: uploading,
            onPickAvatar: onPick,
          ),
        ),
      ),
    ),
  ));
  for (int i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Yields to the event loop until [done] holds, or gives up.
///
/// Preferred over a fixed `Future.delayed`: the BLoC's work is all microtask-
/// scheduled here, so this finishes in a few turns and cannot flake on a slow
/// machine the way a hard-coded delay can.
Future<void> _until(bool Function() done, {int maxTurns = 200}) async {
  for (int i = 0; i < maxTurns && !done(); i++) {
    await Future<void>.delayed(Duration.zero);
  }
  if (!done()) throw StateError('condition never held after \$maxTurns turns');
}

/// Lets any follow-on work (the post-upload refetch) drain.
Future<void> _settle() async {
  for (int i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// The avatar's transparent button — `AccountPage.tsx:333-340`.
Finder get _tapTarget => find.descendant(
      of: find.byType(AccountHeader),
      matching: find.byType(GestureDetector),
    );

/// The badge's own `AbsorbPointer`, scoped to the header.
///
/// Unscoped, `find.byType(AbsorbPointer)` also matches the one `ModalRoute`
/// puts above every route's child, and the finder reports two.
Finder get _badge => find.descendant(
      of: find.byType(AccountHeader),
      matching: find.byType(AbsorbPointer),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(NoParams());
    registerFallbackValue(UploadAvatarParams(tPickedAvatar()));
  });

  // ── B8-AC-53 — the photo IS the control ───────────────────────────────────

  group('B8-AC-53 — the avatar is the upload control', () {
    testWidgets('tapping the avatar runs the picker — asserted by the picker '
        'actually running, not by a widget being present', (WidgetTester t) async {
      int taps = 0;
      await _pumpHeader(t, uploading: false, verified: false,
          onPick: () => taps++);

      expect(taps, 0);
      // The disc, not the header's centre — `tap(find.byType(AccountHeader))`
      // lands on the name text and would report 0 for the right reason.
      await t.tap(_tapTarget);
      await t.pump();

      expect(taps, 1, reason: 'the disc is the tap target (`:333-340`)');
    });

    testWidgets('the tap target carries Semantics(button: true) labelled '
        'photoHint — the port of aria-label / title / sr-only',
        (WidgetTester t) async {
      // Disposed inline, not via `addTearDown`: the framework verifies no
      // handle is live *before* tear-downs run.
      final SemanticsHandle handle = t.ensureSemantics();
      await _pumpHeader(t, uploading: false, verified: false, onPick: () {});

      // `Change photo` is `en.json`'s `account.photoHint`, itself the port of
      // `AccountPage.tsx:73`'s COPY entry. Asserting the resolved string and
      // not the key: a header pumped without the localisation delegates would
      // otherwise "pass" on the raw key.
      // The RENDERED semantics node for the tap target, not the `Semantics`
      // widget's declared properties — the two differ once the framework has
      // merged the `GestureDetector`'s own annotations in, and it is the
      // rendered node that a screen reader announces.
      final SemanticsNode node = t.getSemantics(_tapTarget);

      // **The first line, and the reason is a measured divergence worth
      // stating.** The rendered label is `"Change photo\nS"`: because the disc
      // is *inside* the tap target, Flutter merges the initial tile's letter
      // into the button's node. In the DOM the button is an overlaying sibling
      // and the image is announced separately, so the web reads "Change photo,
      // button" and then "Profile, image".
      //
      // Not restructured. Making the two match would mean either
      // `ExcludeSemantics` around the disc — which deletes the initial from the
      // accessibility tree, a loss against B8a's current behaviour — or
      // rebuilding the control as a sibling overlay, which is a bigger change
      // than the difference warrants. Recorded in `b8b-code-review.md` as an
      // observation rather than silently normalised by a loose matcher.
      expect(node.label.split('\n').first, 'Change photo',
          reason: '`account.photoHint`, resolved — aria-label, title and the '
              'sr-only span all carry it (`:335`, `:336`, `:339`). Comparing '
              'the resolved string and not the key: a header pumped without '
              'the localisation delegates would otherwise pass against '
              '"account.photoHint".');
      // `flagsCollection`, not `hasFlag` (deprecated) and not `isSemantics`
      // (which asserts every *unlisted* property is at its default and so
      // fails on the merged label above).
      final SemanticsData data = node.getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue,
          reason: 'B8-AC-53 — `<button>`, announced as a button');
      expect(data.hasAction(SemanticsAction.tap), isTrue,
          reason: 'and actually tappable, not a decorative role');

      handle.dispose();
    });

    testWidgets('there is NO separate visible camera button beside the avatar '
        '— the badge is a badge, not a control', (WidgetTester t) async {
      int taps = 0;
      await _pumpHeader(t, uploading: false, verified: false,
          onPick: () => taps++);

      // The source's badge is a sibling `<div>` after the button, so a click on
      // it hits a div with no handler. `AbsorbPointer` reproduces that; without
      // it the tap would fall through to the GestureDetector beneath.
      expect(_badge, findsOneWidget);
      await t.tap(_badge, warnIfMissed: false);
      await t.pump();
      expect(taps, 0,
          reason: 'tapping the green badge does nothing in the web, because '
              'the badge div has no onClick and covers the button');
    });
  });

  // ── B8-AC-55 — the three-way badge, always green ──────────────────────────

  group('B8-AC-55 — the badge is three-way and stays green in all three', () {
    testWidgets('not uploading, not verified -> Camera, and it is really '
        'Camera and not the FileText fallback', (WidgetTester t) async {
      await _pumpHeader(t, uploading: false, verified: false, onPick: () {});

      expect(_badgeAssets(t), contains(_asset('Camera')));
      expect(
        _asset('Camera'),
        isNot(_asset(AppIcons.fallback)),
        reason: 'Camera must be BUNDLED. `AppIcons.assetFor` substitutes '
            'FileText for an unbundled name, so before B8b added Camera to the '
            'registry this branch rendered a document glyph on a citizen '
            "avatar — and a `find.byType(LucideIcon)` assertion could not see "
            'it. This is the guard on that.',
      );
    });

    testWidgets('not uploading, verified -> CheckCircle', (WidgetTester t) async {
      await _pumpHeader(t, uploading: false, verified: true, onPick: () {});

      expect(_badgeAssets(t), contains(_asset('CheckCircle')));
      expect(_badgeAssets(t), isNot(contains(_asset('Camera'))));
    });

    testWidgets('uploading beats verified — a VERIFIED citizen mid-upload '
        'shows the spinner, not the tick', (WidgetTester t) async {
      // The discriminating case. `{pending ? spinner : verified ? tick : camera}`
      // — a port that tested `verified` first passes every other case in this
      // group and fails only this one.
      await _pumpHeader(t, uploading: true, verified: true, onPick: () {});
      // `pump`, never `pumpAndSettle`: the spinner repeats forever.
      await t.pump();

      expect(_badgeAssets(t), contains(_asset('RefreshCw')));
      expect(_badgeAssets(t), isNot(contains(_asset('CheckCircle'))));
      expect(
        find.descendant(of: _badge, matching: find.byType(RotationTransition)),
        findsOneWidget,
        reason: '`animate-spin` — the glyph rotates. Scoped to the badge: '
            "MaterialApp's route machinery contributes one of its own.",
      );
    });

    testWidgets('the badge is green in ALL THREE states, camera included',
        (WidgetTester t) async {
      // `bg-green-400` is on the container, not on the branch — the source
      // styles the disc once and swaps only the glyph. A port that greened only
      // the verified badge would look right in the state most fixtures use.
      Color badgeColour(WidgetTester t) {
        final Container c = t.widget<Container>(
          find.descendant(
            of: _badge,
            matching: find.byType(Container),
          ),
        );
        return (c.decoration! as BoxDecoration).color!;
      }

      await _pumpHeader(t, uploading: false, verified: false, onPick: () {});
      final Color camera = badgeColour(t);

      await _pumpHeader(t, uploading: false, verified: true, onPick: () {});
      final Color tick = badgeColour(t);

      await _pumpHeader(t, uploading: true, verified: false, onPick: () {});
      await t.pump();
      final Color spinner = badgeColour(t);

      expect(camera, tick);
      expect(tick, spinner);
    });
  });

  // ── The BLoC path — B8-AC-54, GG-7, GG-8, and the two refreshes ───────────

  group('AccountProfileBloc — the upload', () {
    late MockGetProfileUseCase getProfile;
    late MockUpdateProfileUseCase updateProfile;
    late MockChangePassword changePassword;
    late MockUploadAvatar uploadAvatar;

    setUp(() {
      getProfile = MockGetProfileUseCase();
      updateProfile = MockUpdateProfileUseCase();
      changePassword = MockChangePassword();
      uploadAvatar = MockUploadAvatar();
      when(() => getProfile(any())).thenAnswer((_) async => ok(tProfile()));
    });

    AccountProfileBloc build() => AccountProfileBloc(
          getProfile: getProfile,
          updateProfile: updateProfile,
          changePassword: changePassword,
          uploadAvatar: uploadAvatar,
        );

    test('B8-AC-54 — the SAME file picked twice fires TWO uploads', () async {
      // The analogue of `e.target.value = ""` running before the early return
      // (`:236`). A memoising implementation — or an `UploadAvatarParams` with
      // value equality on bytes — passes a two-different-files test and fails
      // this one.
      when(() => uploadAvatar(any())).thenAnswer((_) async => ok('u'));
      final AccountProfileBloc bloc = build();
      addTearDown(bloc.close);

      final PickedAvatar same = tPickedAvatar();
      bloc.add(AccountAvatarPicked(same));
      await bloc.stream.firstWhere(
          (AccountProfileState s) => s.avatarOutcome == AvatarOutcome.uploaded);
      bloc.add(AccountAvatarPicked(same));
      await bloc.stream.firstWhere(
          (AccountProfileState s) => s.avatarOutcome == AvatarOutcome.uploaded);

      verify(() => uploadAvatar(any())).called(2);
    });

    test('success -> uploading clears, avatarOutcome flips, and the profile '
        'is REFETCHED (`profileQuery.refetch()`, `:240`)', () async {
      when(() => uploadAvatar(any())).thenAnswer((_) async => ok('u'));
      final AccountProfileBloc bloc = build();
      addTearDown(bloc.close);

      final List<bool> pending = <bool>[];
      final sub = bloc.stream
          .listen((AccountProfileState s) => pending.add(s.uploadingAvatar));

      bloc.add(AccountAvatarPicked(tPickedAvatar()));
      await bloc.stream.firstWhere(
          (AccountProfileState s) => s.avatarOutcome == AvatarOutcome.uploaded);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(pending.first, isTrue, reason: 'the spinner comes up');
      expect(bloc.state.uploadingAvatar, isFalse);
      // The refetch, asserted by invocation and not by a state field: a BLoC
      // that flipped the flag and never re-read would pass on state alone.
      verify(() => getProfile(any())).called(1);
    });

    test('avatarOutcome RESETS before each attempt, so a second upload '
        're-fires the page listener', () async {
      // A latching `bool` passes a single-upload test and silently stops
      // refreshing the session from the second upload onward — invisible
      // unless a test uploads twice and watches the edge.
      int calls = 0;
      when(() => uploadAvatar(any())).thenAnswer((_) async {
        calls++;
        return ok('u');
      });
      final AccountProfileBloc bloc = build();
      addTearDown(bloc.close);

      final List<AvatarOutcome> seen = <AvatarOutcome>[];
      final StreamSubscription<AccountProfileState> sub = bloc.stream
          .listen((AccountProfileState s) => seen.add(s.avatarOutcome));

      // **Not `firstWhere(uploaded)` between the two adds.** After attempt 1
      // succeeds the BLoC refetches, and every state that refetch emits still
      // carries `uploaded` — so a second `firstWhere` resolves on attempt 1's
      // own trailing state and the test cancels before attempt 2 has run. Wait
      // on the invocation count instead, which only the upload moves.
      bloc.add(AccountAvatarPicked(tPickedAvatar()));
      await _until(() => calls == 1);
      await _settle();
      bloc.add(AccountAvatarPicked(tPickedAvatar()));
      await _until(() => calls == 2);
      await _settle();
      await sub.cancel();

      // Collapse runs of equal values: the refetch re-emits `uploaded` several
      // times and the count is not the claim. The claim is the SHAPE.
      final List<AvatarOutcome> transitions = <AvatarOutcome>[];
      for (final AvatarOutcome o in seen) {
        if (transitions.isEmpty || transitions.last != o) transitions.add(o);
      }

      expect(
        transitions,
        <AvatarOutcome>[
          AvatarOutcome.none,
          AvatarOutcome.uploaded,
          AvatarOutcome.none,
          AvatarOutcome.uploaded,
        ],
        reason: 'two rising edges. A latching flag gives '
            '[none, uploaded] and the page would refresh the session after the '
            'first upload of a session and never again',
      );
    });

    test('GG-7 — a FAILED upload shows nothing at all, and the profile is NOT '
        'refetched', () async {
      // `catch { /* uploadAvatar.error carries the message */ }` — and
      // `uploadAvatar.error` is never rendered anywhere in the 749-line source.
      // The comment is false; the behaviour is silence, and silence is what is
      // ported (security-review-b8b.md `B8b-4`).
      when(() => uploadAvatar(any()))
          .thenAnswer((_) async => err<String>('ApiException(500, …)'));
      final AccountProfileBloc bloc = build();
      addTearDown(bloc.close);

      bloc.add(AccountAvatarPicked(tPickedAvatar()));
      await bloc.stream
          .firstWhere((AccountProfileState s) => !s.uploadingAvatar);

      expect(bloc.state.uploadingAvatar, isFalse,
          reason: '`finally { setPending(false) }` is the only visible effect');
      expect(bloc.state.avatarOutcome, AvatarOutcome.none);

      // Nothing the citizen can read changed. These four are every user-visible
      // error slot the state has; if a future edit routes the upload failure to
      // one of them, this fails and names GG-7.
      expect(bloc.state.saveError, isNull);
      expect(bloc.state.errorMessage, isNull);
      expect(bloc.state.passwordServerError, isNull);
      expect(bloc.state.hasFailed, isFalse);

      // …and no refetch, because the source refetches only on success.
      verifyNever(() => getProfile(any()));
    });

    test("GG-8 — there is NO in-flight guard: a second pick during an upload "
        'starts a SECOND concurrent upload', () async {
      // `security-review-b8b.md` `B8b-5`. The source's button has no `disabled`
      // and `handleAvatar` has no pending check, so last-writer-wins on a face
      // is the measured behaviour. Ported, and asserted so that a future
      // "obvious" hardening trips a test that explains why it is not wanted.
      final List<Completer<void>> gates = <Completer<void>>[];
      when(() => uploadAvatar(any())).thenAnswer((_) async {
        final Completer<void> gate = Completer<void>();
        gates.add(gate);
        await gate.future;
        return ok('u');
      });

      final AccountProfileBloc bloc = build();
      addTearDown(bloc.close);

      bloc.add(AccountAvatarPicked(tPickedAvatar()));
      await bloc.stream
          .firstWhere((AccountProfileState s) => s.uploadingAvatar);
      bloc.add(AccountAvatarPicked(tPickedAvatar()));
      await Future<void>.delayed(Duration.zero);

      expect(gates, hasLength(2),
          reason: 'both uploads are in flight at once — a guard would make '
              'this 1, which is a behaviour the web does not have');

      for (final Completer<void> gate in gates) {
        gate.complete();
      }
      await bloc.stream.firstWhere(
          (AccountProfileState s) => s.avatarOutcome == AvatarOutcome.uploaded);
    });
  });
}

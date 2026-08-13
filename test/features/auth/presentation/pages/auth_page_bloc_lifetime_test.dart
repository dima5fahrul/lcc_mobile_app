/// **SSD § 6.4, verification #3** — the `AuthBloc` is closed exactly once on
/// `/signin` teardown.
///
/// CR-1 moved the BLoC's acquisition out of `AuthPage.initState` and into the
/// `/signin` route builder, which now wraps the page in
/// `BlocProvider<AuthBloc>(create: (_) => authInjection<AuthBloc>())`. That
/// swap moves an *obligation*, not just a call site, and § 6.4 flags it as the
/// one part of R3 that is easy to get wrong in either direction:
///
/// - `BlocProvider.value` (what the page used) does **not** dispose what it is
///   given, which is why the page had to `close()` in `dispose`.
/// - `BlocProvider(create:)` **does** dispose what its callback returned.
///
/// Keep both and the OTP state machine is closed twice; keep neither and it
/// leaks, holding a half-typed password and an unverified challenge for the
/// rest of the process's life. Neither mistake is visible to the analyzer, and
/// neither throws: `BlocBase.close()` (bloc 9.2.1) calls
/// `_blocObserver.onClose(this)` and then closes an already-closed
/// `StreamController`, which is a silent no-op. So a double close is not an
/// exception to catch — it is a *count* to measure, which is what
/// [_AuthBlocLifetimeObserver] does.
///
/// The tests drive the assembled app from `app_test_harness.dart`, so the
/// object doing the closing is the real `BlocProvider` in the real route table,
/// not a stand-in.
library;

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lcc_mobile_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lcc_mobile_app/features/auth/presentation/pages/auth_page.dart';
import 'package:lcc_mobile_app/features/home/presentation/pages/home_page.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

import '../../../../helpers/app_test_harness.dart';

/// Counts `AuthBloc` construction and every `close()` call, in order.
///
/// `onClose` is invoked unconditionally at the top of `BlocBase.close()` with
/// no `isClosed` guard, so a second close appends a second entry rather than
/// being swallowed — which is exactly the failure this file exists to catch.
/// `SessionBloc` also flows through this observer; it is filtered out by type.
class _AuthBlocLifetimeObserver extends BlocObserver {
  final List<AuthBloc> created = <AuthBloc>[];
  final List<AuthBloc> closed = <AuthBloc>[];

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    if (bloc is AuthBloc) created.add(bloc);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    if (bloc is AuthBloc) closed.add(bloc);
  }
}

GoRouter _routerOf(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));

/// Navigate, then let any `close()` started by an unmounting provider finish.
///
/// **`pumpAndSettle` is not enough here, and the reason is worth writing down.**
/// `BlocProvider`'s dispose hook calls `bloc.close()` during
/// `finalizeTree`, but `Bloc.close()` awaits `_eventController.close()` and its
/// in-flight emitters *before* it reaches `BlocBase.close()`, which is the line
/// that notifies `BlocObserver.onClose`. Those awaits complete on the real
/// event loop, not on the `FakeAsync` zone that `pump`, `pumpAndSettle` and
/// `idle` drain — measured: after `pumpAndSettle`, then `idle()`, then another
/// `pump()`, the observer had still seen nothing; a single
/// `runAsync(() async {})` produced the close.
///
/// Left out, this test would have reported "0 closes — the BLoC leaked" on a
/// codebase that closes it correctly. That is the worst kind of red: it points
/// at the production change and invites someone to "fix" it by putting the
/// page's `close()` back, which is the actual double-close bug.
Future<void> _goTo(WidgetTester tester, String path) async {
  _routerOf(tester).go(path);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {});
  await tester.pump();
}

void main() {
  tearDown(resetHarness);

  /// Boots the app unauthenticated with the lifetime observer installed.
  Future<_AuthBlocLifetimeObserver> observedApp(WidgetTester tester) async {
    final AppHarness harness = await bootHarness();
    final _AuthBlocLifetimeObserver observer = _AuthBlocLifetimeObserver();
    final BlocObserver previous = Bloc.observer;
    Bloc.observer = observer;
    addTearDown(() => Bloc.observer = previous);

    await pumpAssembledApp(tester, harness);
    return observer;
  }

  testWidgets('mounting /signin creates exactly one AuthBloc, and nothing '
      'closes it while the page is on screen', (WidgetTester tester) async {
    final _AuthBlocLifetimeObserver observer = await observedApp(tester);

    expect(observer.created, isEmpty,
        reason: 'the route builder is lazy — booting on / must not construct '
            'an AuthBloc');

    await _goTo(tester, AppNameRoutes.signin);

    expect(find.byType(AuthPage), findsOneWidget);
    expect(observer.created, hasLength(1),
        reason: 'one visit to /signin resolves one AuthBloc from the '
            '`registerFactory` registration');
    expect(observer.closed, isEmpty,
        reason: 'the BLoC is in use; closing it here would break the form '
            'mid-attempt');
  });

  testWidgets('leaving /signin closes that AuthBloc exactly once',
      (WidgetTester tester) async {
    final _AuthBlocLifetimeObserver observer = await observedApp(tester);

    await _goTo(tester, AppNameRoutes.signin);
    final AuthBloc bloc = observer.created.single;

    await _goTo(tester, AppNameRoutes.home);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(AuthPage), findsNothing);

    // The assertion § 6.4 verification #3 asks for. `hasLength(1)` is doing
    // two jobs: >1 means `AuthPage` kept a `close()` it no longer owns
    // (double close), 0 means the `.value` → `create:` swap dropped the
    // obligation entirely (leak).
    expect(observer.closed, hasLength(1),
        reason: 'exactly one close() for one mount — not zero (leaked), not '
            'two (page and provider both closing it)');
    expect(identical(observer.closed.single, bloc), isTrue,
        reason: 'the instance closed is the instance the route builder created');
    expect(bloc.isClosed, isTrue);
    expect(observer.created, hasLength(1),
        reason: 'navigating away must not resolve a replacement');
  });

  testWidgets('each visit to /signin gets its own AuthBloc, and each one is '
      'closed once', (WidgetTester tester) async {
    final _AuthBlocLifetimeObserver observer = await observedApp(tester);

    await _goTo(tester, AppNameRoutes.signin);
    await _goTo(tester, AppNameRoutes.home);
    await _goTo(tester, AppNameRoutes.signin);
    await _goTo(tester, AppNameRoutes.home);

    expect(observer.created, hasLength(2));
    expect(observer.closed, hasLength(2));
    expect(identical(observer.created[0], observer.created[1]), isFalse,
        reason: 'AuthBloc is a `registerFactory`: a second visit must not '
            'reuse the first attempt\'s state machine, or a stale '
            'AuthStatus.success would replay into the new BlocListener');
    expect(
      observer.closed.map((AuthBloc b) => identityHashCode(b)).toSet(),
      observer.created.map((AuthBloc b) => identityHashCode(b)).toSet(),
      reason: 'the set closed is the set created — no instance closed twice, '
          'none left open',
    );
  });
}

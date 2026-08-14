/// The bell button — **B9-AC-34**'s three cases, and the session wiring.
///
/// The dot is a colour-and-geometry claim, so it is asserted structurally here
/// (present / absent, and its colour) rather than through Tier 1's text dump,
/// which by construction sees nothing in this widget.
library;

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/session/bloc/session_bloc.dart';
import 'package:lcc_mobile_app/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:lcc_mobile_app/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:lcc_mobile_app/features/notifications/presentation/widgets/notification_menu_sheet.dart';
import 'package:lcc_mobile_app/presentation/theme/app_colors.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

import '../../../helpers/app_test_harness.dart';
import '../notification_test_helper.dart';

/// A `SessionBloc` double that can be put into a state without a container, a
/// token store or a network.
///
/// `SessionBloc`'s real constructor needs `StorageService`, `GetProfile` and
/// `SessionRepository`; the bell reads exactly one thing off it —
/// `state.status` — so standing the real one up would be three dependencies
/// bought to observe one enum.
class _StubSessionBloc extends Bloc<SessionEvent, SessionState>
    implements SessionBloc {
  _StubSessionBloc(super.initialState);

  void put(SessionStatus status) => emit(state.copyWith(status: status));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  /// Finds the amber dot by its decoration, which is the only thing that
  /// distinguishes it from any other small box in the bar.
  Finder dotFinder() => find.byWidgetPredicate((Widget w) {
        if (w is! Container) return false;
        final Object? d = w.decoration;
        return d is BoxDecoration &&
            d.shape == BoxShape.circle &&
            d.color == AppColors.warningStrong;
      });

  Future<({NotificationsBloc bloc, _StubSessionBloc session})> pumpBell(
    WidgetTester tester, {
    required SessionStatus status,
    FakeNotificationRepository? repo,
  }) async {
    final FakeNotificationRepository repository =
        repo ?? FakeNotificationRepository();
    final NotificationsBloc bloc = notificationsBlocOver(repository);
    final _StubSessionBloc session =
        _StubSessionBloc(SessionState(status: status));
    addTearDown(bloc.close);
    addTearDown(session.close);

    await tester.pumpWidget(
      wrapWithLocalization(
        Builder(
          builder: (BuildContext context) => MaterialApp.router(
            theme: AppTheme.light(),
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            routerConfig: GoRouter(
              initialLocation: AppNameRoutes.home,
              routes: <RouteBase>[
                GoRoute(
                  path: AppNameRoutes.home,
                  builder: (_, __) => Scaffold(
                    appBar: AppBar(
                      actions: <Widget>[
                        BlocProvider<SessionBloc>.value(
                          value: session,
                          child: BlocProvider<NotificationsBloc>.value(
                            value: bloc,
                            child: const NotificationBell(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GoRoute(
                  path: AppNameRoutes.history,
                  builder: (_, __) => const Scaffold(body: Text('history')),
                ),
                GoRoute(
                  path: AppNameRoutes.account,
                  builder: (_, __) => const Scaffold(body: Text('account')),
                ),
                GoRoute(
                  path: AppNameRoutes.wallet,
                  builder: (_, __) => const Scaffold(body: Text('wallet')),
                ),
                GoRoute(
                  path: AppNameRoutes.service,
                  builder: (_, __) => const Scaffold(body: Text('service')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return (bloc: bloc, session: session);
  }

  group('B9-AC-34 — the bell renders a NUMBERLESS dot, in three cases', () {
    testWidgets('signed OUT: the dot is shown', (WidgetTester tester) async {
      await pumpBell(tester, status: SessionStatus.unauthenticated);

      expect(
        dotFinder(),
        findsOneWidget,
        reason: '`(!isAuthenticated || unreadCount > 0)` — Layout.tsx:172. '
            'This reads like a defect and is not: it is visible in the frozen '
            'baseline at en/02-service.png, en/04-wallet.png and the top crop '
            'of en/06-help.png, all signed-out captures. Hiding it would fail '
            'Tier 3 against a reference that already exists.',
      );
    });

    testWidgets('signed in WITH unread: the dot is shown',
        (WidgetTester tester) async {
      await pumpBell(tester, status: SessionStatus.authenticated);
      expect(dotFinder(), findsOneWidget);
    });

    testWidgets('signed in with NOTHING unread: the dot is hidden',
        (WidgetTester tester) async {
      final FakeNotificationRepository repo = FakeNotificationRepository()
        ..count = const Right<Failure, int>(0);
      await pumpBell(
        tester,
        status: SessionStatus.authenticated,
        repo: repo,
      );
      expect(dotFinder(), findsNothing);
    });

    testWidgets('the dot carries NO NUMBER, ever — the launcher\'s idiom is '
        'the other one', (WidgetTester tester) async {
      // § 2.2 Finding B: two idioms for `unread` in one shell. The bell is a
      // 2×2 amber dot with no count; B9b's chat launcher is a red circle WITH
      // the number. Unifying them is the mistake this asserts against, and it
      // is invisible in a colour-blind text diff.
      await pumpBell(tester, status: SessionStatus.authenticated);

      expect(
        find.descendant(
          of: find.byType(NotificationBell),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
      expect(find.text('3'), findsNothing);
    });
  });

  group('the session wiring — dispatched on MOUNT as well as on change', () {
    testWidgets('a bell mounted against an ALREADY-authenticated session '
        'fetches the count', (WidgetTester tester) async {
      // The gap `home_page.dart`'s header records, and it is not theoretical:
      // the BLoC is a `registerFactory` behind `BlocProvider(create:)`, so a
      // shell rebuild starts a fresh one at `isAuthenticated: false` against a
      // `SessionBloc` that will not transition again. A listener alone would
      // leave the badge permanently empty for a signed-in citizen.
      final FakeNotificationRepository repo = FakeNotificationRepository();
      await pumpBell(
        tester,
        status: SessionStatus.authenticated,
        repo: repo,
      );
      expect(repo.countCalls, 1);
    });

    testWidgets('an unresolved session is HELD, not treated as signed out',
        (WidgetTester tester) async {
      // The same boot hold `AppRoutes._redirect` respects. Treating `initial`
      // as signed out would flash the sign-in prompt at a warm-booted citizen
      // whose token had simply not been read yet.
      final FakeNotificationRepository repo = FakeNotificationRepository();
      final ({NotificationsBloc bloc, _StubSessionBloc session}) rig =
          await pumpBell(tester, status: SessionStatus.initial, repo: repo);

      expect(repo.countCalls, 0);
      expect(rig.bloc.state.isAuthenticated, isFalse);

      rig.session.put(SessionStatus.authenticated);
      await tester.pump();
      await tester.pump();
      expect(repo.countCalls, 1);
    });

    testWidgets('signing out is picked up by the listener',
        (WidgetTester tester) async {
      final ({NotificationsBloc bloc, _StubSessionBloc session}) rig =
          await pumpBell(tester, status: SessionStatus.authenticated);
      expect(rig.bloc.state.isAuthenticated, isTrue);

      rig.session.put(SessionStatus.unauthenticated);
      await tester.pump();
      await tester.pump();
      expect(rig.bloc.state.isAuthenticated, isFalse);
    });
  });

  group('the menu overlay', () {
    testWidgets('tapping the bell opens the panel; tapping again closes it',
        (WidgetTester tester) async {
      await pumpBell(tester, status: SessionStatus.authenticated);
      expect(find.byType(NotificationMenuSheet), findsNothing);

      await tester.tap(find.byType(NotificationBell));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationMenuSheet), findsOneWidget);

      await tester.tap(find.byType(NotificationBell));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationMenuSheet), findsNothing);
    });

    testWidgets('opening a notice navigates by CATEGORY, not by action_url',
        (WidgetTester tester) async {
      // `openNotification` reads `NOTIF_STYLE[item.category]?.tab` (:131).
      // `action_url` is on the wire and is never consulted (B9-AC-44) — the
      // first fixture row carries `/history/RC-2026-004821`, and the
      // destination below is `/history` because that is `application`'s tab,
      // not because the URL happens to start with it.
      await pumpBell(tester, status: SessionStatus.authenticated);

      await tester.tap(find.byType(NotificationBell));
      await tester.pumpAndSettle();

      // Row 5 — `payment` — routes to /wallet. Its action_url is absent
      // entirely, so nothing but the category can be driving this.
      //
      // Scrolled into view first: the panel caps at 320 px (`max-h-80`,
      // `:253`) and this row is below the fold. A bare `tap` on an off-screen
      // widget lands on the barrier and closes the menu, which then fails as
      // "did not navigate" and sends a reader hunting in the wrong place.
      await tester.dragUntilVisible(
        find.text('Payment received'),
        find.byType(NotificationMenuSheet),
        const Offset(0, -60),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Payment received'));
      await tester.pumpAndSettle();

      expect(find.text('wallet'), findsOneWidget);
      expect(find.byType(NotificationMenuSheet), findsNothing);
    });

    testWidgets('an unrecognised category navigates to the FALLBACK tab — '
        'B9-AC-33, the destination half', (WidgetTester tester) async {
      await pumpBell(tester, status: SessionStatus.authenticated);
      await tester.tap(find.byType(NotificationBell));
      await tester.pumpAndSettle();

      // The `maintenance` row. `:131`'s `?? NOTIF_FALLBACK.tab` sends it to
      // `announcement`'s destination, `/service`. A port that fell back for the
      // ICON and not the TAB would render correctly and navigate nowhere.
      await tester.dragUntilVisible(
        find.text('Scheduled maintenance on Sunday'),
        find.byType(NotificationMenuSheet),
        const Offset(0, -60),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scheduled maintenance on Sunday'));
      await tester.pumpAndSettle();

      expect(find.text('service'), findsOneWidget);
    });

    testWidgets('"View all activity" goes to /history and closes the menu',
        (WidgetTester tester) async {
      await pumpBell(tester, status: SessionStatus.authenticated);
      await tester.tap(find.byType(NotificationBell));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(
        of: find.byType(NotificationMenuFooter),
        matching: find.text('View all activity'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('history'), findsOneWidget);
      expect(find.byType(NotificationMenuSheet), findsNothing);
    });

    testWidgets('the signed-out prompt goes to /account — :216',
        (WidgetTester tester) async {
      await pumpBell(tester, status: SessionStatus.unauthenticated);
      await tester.tap(find.byType(NotificationBell));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('account'), findsOneWidget);
    });
  });
}

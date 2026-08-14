/// The launcher FAB — **B9-AC-34** (the launcher half), **B9-AC-41**, and the
/// composition seam with a second consumer on it.
///
/// The seam half is the payoff B9a's § 6.4 promised and § 8.1(2) requires: the
/// launcher is composed into `AppShell.floatingAction` by the `ShellRoute`
/// builder, and **no file under `lib/presentation/**` names it**. The
/// structural proof is `layering_test.dart`'s G-L7; the behavioural proof is
/// here — the launcher appears on the five shell routes and on none of the
/// others, with no `isSubPage` flag anywhere in the tree.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:lcc_mobile_app/features/chat/presentation/widgets/chat_launcher.dart';
import 'package:lcc_mobile_app/features/chat/presentation/widgets/chat_panel.dart';
import 'package:lcc_mobile_app/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:lcc_mobile_app/presentation/theme/app_colors.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

import '../../../helpers/app_test_harness.dart';
import '../chat_test_helper.dart';

/// Pumps just the button, with no BLoC and no session — which is possible only
/// because the badge arrives as a number rather than being read from a locator.
Future<void> pumpButton(
  WidgetTester tester,
  int unread, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    wrapWithLocalization(
      startLocale: locale,
      Builder(
        builder: (BuildContext context) => MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: Scaffold(
            body: Center(
              child: ChatLauncherButton(unread: unread, onPressed: () {}),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // ── B9-AC-34 (the launcher half) — the NUMERIC red badge ──────────────────

  group('B9-AC-34 — the launcher badge is NUMERIC and red', () {
    testWidgets('no badge at zero — `{unread > 0 && …}` (`:553`)', (
      WidgetTester tester,
    ) async {
      await pumpButton(tester, 0);

      expect(find.byType(ChatLauncherButton), findsOneWidget);
      expect(find.byType(Text), findsNothing,
          reason: 'the closed launcher renders an icon and no text at all — '
              'which is what makes the badge case below discriminating');
    });

    testWidgets('a badge WITH THE NUMBER IN IT at seven', (
      WidgetTester tester,
    ) async {
      await pumpButton(tester, 7);

      expect(find.text('7'), findsOneWidget,
          reason: 'THE ASYMMETRY WITH THE BELL. `Layout.tsx:172-177` renders a '
              '2 x 2 amber dot with NO number, and this renders a red circle '
              'WITH one. Two idioms for two different numbers in one shell, '
              'and § 2.2 Finding B rules that they must not be unified.');
    });

    testWidgets('the badge is `red-500`, not the bell\'s amber', (
      WidgetTester tester,
    ) async {
      await pumpButton(tester, 3);

      final Iterable<Container> containers =
          tester.widgetList<Container>(find.byType(Container));
      final Iterable<Color?> colours = containers
          .map((Container c) => (c.decoration as BoxDecoration?)?.color);

      expect(colours, contains(AppColors.dangerGlyph),
          reason: '`bg-red-500` = oklch(63.7% 0.237 25.331) = #FB2C36, which is '
              'already in the theme as `dangerGlyph`');
      expect(colours, isNot(contains(AppColors.warningStrong)),
          reason: '#F59E0B is the BELL\'s dot (`Layout.tsx:175`)');
    });

    testWidgets('the FAB is brand blue and carries the openChat label in both '
        'locales', (WidgetTester tester) async {
      for (final Locale locale in <Locale>[Locale('en'), Locale('lo')]) {
        await pumpButton(tester, 0, locale: locale);

        final Material material = tester.widget<Material>(
          find
              .descendant(
                of: find.byType(ChatLauncherButton),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(material.color, AppColors.primary,
            reason: '`backgroundColor: "#344EAD"` — inline hex at `:550`');

        final Semantics semantics = tester.widget<Semantics>(
          find
              .descendant(
                of: find.byType(ChatLauncherButton),
                matching: find.byType(Semantics),
              )
              .first,
        );
        expect(semantics.properties.label, isNotNull);
        expect(semantics.properties.label, isNot(contains('chat.')),
            reason: 'a raw key here means the namespace did not resolve — the '
                'failure mode a key-presence test cannot see (locale '
                '${locale.languageCode})');
      }
    });
  });

  // ── The launcher/panel mutual exclusion ───────────────────────────────────

  group('the button and the panel are mutually exclusive — `:197` / `:544`', () {
    testWidgets('closed shows the button and no panel; open shows the panel '
        'and no button', (WidgetTester tester) async {
      final ChatBloc bloc = chatBlocOver(FakeChatRepository());
      addTearDown(bloc.close);

      await tester.pumpWidget(
        wrapWithLocalization(
          Builder(
            builder: (BuildContext context) => MaterialApp(
              theme: AppTheme.light(),
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: BlocProvider<SessionBlocStub>.value(
                value: SessionBlocStub(),
                child: Scaffold(
                  body: BlocProvider<ChatBloc>.value(
                    value: bloc,
                    child: BlocBuilder<ChatBloc, ChatState>(
                      builder: (BuildContext context, ChatState state) =>
                          state.open
                              ? const ChatPanel()
                              : ChatLauncherButton(
                                  unread: state.unread,
                                  onPressed: () =>
                                      bloc.add(const ChatOpened()),
                                ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ChatLauncherButton), findsOneWidget);
      expect(find.byType(ChatPanel), findsNothing);

      await tester.tap(find.byType(ChatLauncherButton));
      await tester.pump();
      await tester.pump();

      expect(find.byType(ChatLauncherButton), findsNothing);
      expect(find.byType(ChatPanel), findsOneWidget);

      bloc.add(const ChatDismissed());
      await tester.pump();
      await tester.pump();
    });
  });

  // ── B9-AC-41 — main tabs only, STRUCTURALLY ───────────────────────────────

  group('B9-AC-41 — the launcher is on the five main tabs and nowhere else', () {
    late AppHarness harness;

    setUp(() {
      // `bootHarness` must be awaited from inside the test body — see the
      // harness's hazard 3 — so this only holds the reference.
    });

    tearDown(resetHarness);

    testWidgets('it renders on every one of the five shell routes', (
      WidgetTester tester,
    ) async {
      // Seeded, because `/history` and `/account` are in
      // `AppRoutes._protectedPaths`: a signed-out citizen is redirected to
      // `/signin`, which is outside the shell, and the test would then be
      // asserting the auth gate rather than the launcher. The `/me/*` reads
      // this triggers are absorbed by the repository guards.
      harness = await bootHarness(
        seed: <String, String>{StorageKeys.accessToken: 'access-abc'},
      );
      await pumpAssembledApp(tester, harness);

      for (final String path in <String>[
        AppNameRoutes.home,
        AppNameRoutes.service,
        AppNameRoutes.history,
        AppNameRoutes.wallet,
        AppNameRoutes.account,
      ]) {
        tester
            .state<NavigatorState>(find.byType(Navigator).first)
            .context
            .go(path);
        await tester.pumpAndSettle();

        expect(find.byType(ChatLauncher), findsOneWidget,
            reason: 'missing on $path');
        // …and the bell, which is the other consumer of the same seam.
        expect(find.byType(NotificationBell), findsOneWidget,
            reason: 'the bell should still be there on $path');
      }
    });

    testWidgets('it is ABSENT on a sub-page — no flag, no route list', (
      WidgetTester tester,
    ) async {
      harness = await bootHarness();
      await pumpAssembledApp(tester, harness);
      expect(find.byType(ChatLauncher), findsOneWidget, reason: 'on `/`');

      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .context
          .go(AppNameRoutes.help);
      await tester.pumpAndSettle();

      expect(find.byType(ChatLauncher), findsNothing,
          reason: '`Layout.tsx:385`\'s `{!isSubPage && …}`, and slot 06 of the '
              'frozen baseline confirms the FAB is absent on /help. In Flutter '
              'this needs no condition: /help is mounted OUTSIDE the ShellRoute '
              'and simply never builds the widget (§ 6.3).');
      expect(find.byType(NotificationBell), findsNothing,
          reason: 'the whole shell is gone, not just the launcher');

      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .context
          .go(AppNameRoutes.home);
      await tester.pumpAndSettle();
      expect(find.byType(ChatLauncher), findsOneWidget, reason: 'and it comes '
          'back on the way in');
    });

    testWidgets('it is absent on /signin too', (WidgetTester tester) async {
      harness = await bootHarness();
      await pumpAssembledApp(tester, harness);

      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .context
          .go(AppNameRoutes.signin);
      await tester.pumpAndSettle();

      expect(find.byType(ChatLauncher), findsNothing);
    });

    testWidgets('the shell hands it to `floatingAction`, so the FAB slot is '
        'where it lands', (WidgetTester tester) async {
      harness = await bootHarness();
      await pumpAssembledApp(tester, harness);

      final Scaffold shell = tester.widget<Scaffold>(
        find
            .ancestor(
              of: find.byType(ChatLauncher),
              matching: find.byType(Scaffold),
            )
            .first,
      );
      expect(shell.floatingActionButton, isNotNull);
      expect(shell.floatingActionButtonLocation, isNull,
          reason: 'the default `endFloat` IS the port of '
              '`fixed bottom-24 right-4` above the bottom bar (`:549`) — '
              'setting one would be re-deciding what the default already gets '
              'right');
    });
  });
}

/// A stand-in so the mutual-exclusion test can pump `ChatPanel` without the
/// real `SessionBloc`. `ChatPanel` reads no session — only `ChatLauncher`
/// does — so this is never actually resolved; it exists to make the provider
/// tree in the test read like the production one.
class SessionBlocStub extends Cubit<int> {
  SessionBlocStub() : super(0);
}

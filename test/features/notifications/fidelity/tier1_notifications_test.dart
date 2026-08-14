/// **Tier 1 — structural parity for the notification bell. B9-AC-27 /
/// B9-AC-28.**
///
/// specs.md § 6.10: *"PASS, 100 %, per surface per locale, against the new
/// versioned oracles, over **every** state § 6.10 enumerates. A state omitted
/// from the oracle is NOT EVALUATED, not absent."*
///
/// ## These are OVERLAY oracles, not route oracles
///
/// Every Tier 1 oracle before this one keys on a `route`
/// (`oracle/tier1/help.en.json`'s `"route": "/help"`). B9's surfaces are shell
/// chrome with no route of their own (§ 6.1: *"Neither gets a route"*), so
/// these key on a `surface` and are asserted by **pumping the widget, not the
/// page** — which is only possible because the panel is a feature widget
/// composed into the chrome rather than written into `lib/presentation/shell/`.
///
/// ## The clock is pinned, and that is what keeps the timestamps gated
///
/// Each row's third line is `relativeTime(it.sent_at, …)`, a function of "now".
/// Without a pinnable clock those eight strings would be a moving target and
/// the `cardMeta` nodes would have to be dropped from the oracle — taking the
/// one state-bearing string per row out of the gate. `NotificationMenuSheet`
/// therefore accepts a `now`, and the oracle records the instant in its own
/// `provenance.clock`.
///
/// The `lo` run of the `data` view is where the ±2-day Lao auto form is gated:
/// row 5 renders `2 days ago` in English and `ມື້ກ່ອນ` in Lao, so an
/// implementation that special-cased ±1 only would pass `en` here and fail
/// `lo`.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:lcc_mobile_app/features/notifications/presentation/widgets/notification_menu_sheet.dart';

import '../../../fidelity/oracle.dart';
import '../../../fidelity/text_dump.dart';
import '../../news/fidelity/tier1_news_test.dart' show expectParity;
import '../notification_test_helper.dart';

const List<Locale> kLocales = <Locale>[Locale('en'), Locale('lo')];

/// The surface the oracle is keyed on, used in failure messages where the other
/// Tier 1 tests print a route.
const String kSurface = 'notifications.menu';

void main() {
  group('the oracle is the versioned artefact, pinned to 62f8a529', () {
    for (final Locale locale in kLocales) {
      test('notifications.${locale.languageCode} carries the commit', () {
        final Map<String, dynamic> oracle =
            loadTier1('notifications', locale.languageCode);
        expect(
          (oracle['provenance'] as Map<String, dynamic>)['web_commit'],
          kWebCommit,
        );
      });

      test('notifications.${locale.languageCode} declares SURFACE keying, not '
          'route — B9-AC-28', () {
        final Map<String, dynamic> oracle =
            loadTier1('notifications', locale.languageCode);
        expect(oracle['surface'], kSurface);
        expect(
          oracle.containsKey('route'),
          isFalse,
          reason: 'A `route` key here would make this look like a page oracle '
              'and invite someone to pump a route that does not exist.',
        );
        expect(
          (oracle['provenance'] as Map<String, dynamic>)['keying'],
          contains('SURFACE'),
        );
      });

      test('notifications.${locale.languageCode} names its NOT EVALUATED '
          'regions rather than omitting them — B9-AC-31', () {
        final Map<String, dynamic> notEvaluated =
            ((loadTier1('notifications', locale.languageCode)['provenance']
                    as Map<String, dynamic>)['not_evaluated'])
                as Map<String, dynamic>;
        expect(
          notEvaluated.keys,
          contains('notifications.menu.tier3'),
          reason: 'Tier 3 for the OPEN menu has no reference in either '
              'manifest. NOT EVALUATED is reported by name per CLAUDE.md '
              '§ Gate Status Reporting, never rounded up and never omitted.',
        );
        expect(
          notEvaluated['notifications.menu.tier3'] as String,
          contains('SMS'),
          reason: 'the reason has to survive, not just the label',
        );
      });

      test('notifications.${locale.languageCode} pins the clock its cardMeta '
          'nodes were derived against', () {
        expect(
          (loadTier1('notifications', locale.languageCode)['provenance']
              as Map<String, dynamic>)['clock'],
          kNotificationsOracleClock.toUtc().toIso8601String(),
        );
      });
    }
  });

  for (final Locale locale in kLocales) {
    final String lang = locale.languageCode;

    group('Tier 1 — notifications.menu — $lang', () {
      late Map<String, dynamic> oracle;

      setUp(() => oracle = loadTier1('notifications', lang));

      /// Built **inside the test body**: `setUp` runs outside `testWidgets`'
      /// `FakeAsync` zone, so a BLoC constructed there owns an event queue
      /// `tester.pump()` never drains. `tier1_news_test.dart` records the run
      /// that proved it.
      ({FakeNotificationRepository repository, NotificationsBloc bloc})
          subject() {
        final FakeNotificationRepository repository =
            FakeNotificationRepository();
        final NotificationsBloc bloc = notificationsBlocOver(repository);
        addTearDown(bloc.close);
        return (repository: repository, bloc: bloc);
      }

      void parity(WidgetTester tester, String view) => expectParity(
            oracle,
            view,
            dumpText(tester, find.byType(NotificationMenuSheet)),
            route: kSurface,
            locale: lang,
          );

      // ── signedOut — Layout.tsx:209-222 ─────────────────────────────────────

      testWidgets('signedOut — the prompt, and NO footer',
          (WidgetTester tester) async {
        final (repository: _, :NotificationsBloc bloc) = subject();
        await pumpNotificationMenu(tester, bloc, locale: locale);

        // No auth event at all: the BLoC's initial state is signed out, which
        // is also what a shell rebuild starts from.
        parity(tester, 'signedOut');

        // The negative half of `footer.viewAll`. `:283-289` sits INSIDE the
        // authenticated fragment, so the signed-out panel has no footer — and
        // `expectParity` already fails on an EXTRA node, so this is belt and
        // braces on the one view where an extra node would be a real defect.
        expect(find.byType(NotificationMenuFooter), findsNothing);
      });

      // ── loading — :226-228 ─────────────────────────────────────────────────

      testWidgets('loading — header and footer only, no copy',
          (WidgetTester tester) async {
        final (:FakeNotificationRepository repository, :NotificationsBloc bloc) =
            subject();
        repository.latency = const Duration(milliseconds: 200);
        await pumpNotificationMenu(tester, bloc, locale: locale);

        bloc.add(const NotificationsAuthChanged(true));
        await tester.pump();
        bloc.add(const NotificationsMenuToggled());
        await tester.pump();

        // Snapshot BEFORE draining, then drain, then assert.
        //
        // The order matters and it is not fussiness: this is the one test that
        // holds a stub open, and if the assertion threw first the drain would
        // never run. A test that ends with a live `Future.delayed` inside
        // `FakeAsync` wedges the runner rather than failing it — measured, an
        // earlier draft of this file sat for 7m23s and then died with
        // "Cannot close sink while adding stream", which names nothing useful.
        // Draining first turns that into an ordinary red test.
        final List<DumpNode> snapshot =
            dumpText(tester, find.byType(NotificationMenuSheet));
        await tester.pump(const Duration(milliseconds: 400));

        // A spinner contributes no text. That is the assertion: a port that
        // wrote "Loading…" here would add a node the web does not have.
        expectParity(oracle, 'loading', snapshot,
            route: kSurface, locale: lang);
      });

      // ── data — :253-281 ────────────────────────────────────────────────────

      testWidgets('data — eight rows, title / body / time, in order',
          (WidgetTester tester) async {
        final (:FakeNotificationRepository repository, :NotificationsBloc bloc) =
            subject();
        // unreadCount 0 so the header controls are absent: this view is the
        // rows, and `header.markAllRead` is the view that gates the controls.
        repository.count = const Right<Failure, int>(0);
        await pumpNotificationMenu(
          tester,
          bloc,
          locale: locale,
          clock: kNotificationsOracleClock,
        );

        bloc.add(const NotificationsAuthChanged(true));
        await tester.pump();
        bloc.add(const NotificationsMenuToggled());
        await tester.pump();
        await tester.pump();

        parity(tester, 'data');
      });

      // ── empty — :242-251 ───────────────────────────────────────────────────

      testWidgets('empty — the "all caught up" panel, with the footer',
          (WidgetTester tester) async {
        final (:FakeNotificationRepository repository, :NotificationsBloc bloc) =
            subject();
        repository
          ..emptyList()
          ..count = const Right<Failure, int>(0);
        await pumpNotificationMenu(tester, bloc, locale: locale);

        bloc.add(const NotificationsAuthChanged(true));
        await tester.pump();
        bloc.add(const NotificationsMenuToggled());
        await tester.pump();
        await tester.pump();

        parity(tester, 'empty');
      });

      // ── error — :230-240 + the footer. B9-AC-37 ────────────────────────────

      testWidgets('error — "View all activity" TWICE, which is the defect the '
          'source has and this port reproduces', (WidgetTester tester) async {
        final (:FakeNotificationRepository repository, :NotificationsBloc bloc) =
            subject();
        repository
          ..failEverything()
          ..count = const Right<Failure, int>(0);
        await pumpNotificationMenu(tester, bloc, locale: locale);

        bloc.add(const NotificationsAuthChanged(true));
        await tester.pump();
        bloc.add(const NotificationsMenuToggled());
        await tester.pump();
        await tester.pump();

        // `Layout.tsx:238` labels the RETRY control `t("notifViewAll")` while
        // its onClick is `inbox.refetch()` (`:234`) — wrong copy on a right
        // action (§ 2.2 Finding K(1)). The footer at `:288` carries the same
        // label doing something else. So the string appears twice, and a port
        // that "fixed" the retry to read "Try again" would fail this view.
        parity(tester, 'error');
      });

      // ── header.markAllRead — :189-205 ──────────────────────────────────────

      testWidgets('header.markAllRead — the control and the count pill appear '
          'together', (WidgetTester tester) async {
        final (repository: _, :NotificationsBloc bloc) = subject();
        await pumpNotificationMenu(tester, bloc, locale: locale);

        bloc.add(const NotificationsAuthChanged(true));
        await tester.pump();
        await tester.pump();

        // Scoped to the header rather than the sheet: this view is about the
        // three nodes in that bar, and dumping the whole panel would drag the
        // body's state in with it.
        expectParity(
          oracle,
          'header.markAllRead',
          dumpText(tester, find.byType(NotificationMenuHeader)),
          route: kSurface,
          locale: lang,
        );
      });

      // ── footer.viewAll — :283-289 ──────────────────────────────────────────

      testWidgets('footer.viewAll', (WidgetTester tester) async {
        final (:FakeNotificationRepository repository, :NotificationsBloc bloc) =
            subject();
        repository.count = const Right<Failure, int>(0);
        await pumpNotificationMenu(tester, bloc, locale: locale);

        bloc.add(const NotificationsAuthChanged(true));
        await tester.pump();
        bloc.add(const NotificationsMenuToggled());
        await tester.pump();
        await tester.pump();

        expectParity(
          oracle,
          'footer.viewAll',
          dumpText(tester, find.byType(NotificationMenuFooter)),
          route: kSurface,
          locale: lang,
        );
      });
    });
  }

  // ── notifications.bell — three states, all of them TEXTLESS ────────────────

  group('Tier 1 — notifications.bell', () {
    // The bell renders an icon and, conditionally, a 2×2 dot. It contributes
    // ZERO text nodes in all three states, and asserting that is not vacuous:
    // it is the assertion that nobody put a NUMBER in the badge. The chat
    // launcher's badge (B9b) IS numeric, the two live in the same shell, and
    // § 2.2 Finding B rules that the idioms must not be unified. A count that
    // leaked into the bell would show up here as an EXTRA node and nowhere
    // else in Tier 1.
    //
    // The dot's presence/absence itself is a colour-and-geometry claim, which
    // is Tier 2's and Tier 3's; `notification_bell_test.dart` asserts the three
    // branches structurally.
    testWidgets('the bell carries no text in any dot state',
        (WidgetTester tester) async {
      final Map<String, dynamic> oracle = loadTier1('notifications', 'en');
      for (final String view in <String>[
        'bell.dot.signedOut',
        'bell.dot.unread',
        'bell.dot.none',
      ]) {
        expect(
          () => tier1View(oracle, view),
          returnsNormally,
          reason: 'the oracle must declare `$view` rather than leave the state '
              'undescribed — an absent view is NOT EVALUATED, not a pass',
        );
        expect(
          tier1View(oracle, view),
          isEmpty,
          reason: 'the bell is an icon and a dot; a text node here is a number '
              'in the badge, which is the chat launcher\'s idiom and not this '
              "one's (§ 2.2 Finding B)",
        );
      }
    });
  });
}

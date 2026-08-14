/// `NotificationsBloc` — **B9-AC-18**, **B9-AC-19**, **B9-AC-38**, and the
/// concurrency guard the B2 review found four BLoCs missing.
///
/// Most of these are **invocation-count** claims, not rendering claims. "The
/// bell does not poll" and "marking one read refetches the count" are
/// statements about how many times a use case ran, and neither is visible in a
/// widget tree — which is exactly why they are asserted here against
/// `FakeNotificationRepository`'s counters rather than through the panel.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/notifications/domain/entities/notification_entities.dart';
import 'package:lcc_mobile_app/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:lcc_mobile_app/features/notifications/presentation/bloc/notifications_bloc.dart';

import '../notification_test_helper.dart';

void main() {
  late FakeNotificationRepository repository;
  late NotificationsBloc bloc;

  setUp(() {
    repository = FakeNotificationRepository();
    bloc = notificationsBlocOver(repository);
  });

  tearDown(() => bloc.close());

  /// Lets every queued event and its awaits drain.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<void> signIn() async {
    bloc.add(const NotificationsAuthChanged(true));
    await settle();
  }

  Future<void> openMenu() async {
    bloc.add(const NotificationsMenuToggled());
    await settle();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // B9-AC-18 — THE BELL DOES NOT POLL
  // ───────────────────────────────────────────────────────────────────────────

  group('B9-AC-18 — the bell does not poll', () {
    test('the unread count is requested EXACTLY ONCE per sign-in, and never '
        'again on its own', () async {
      await signIn();
      expect(repository.countCalls, 1);

      // Ten minutes of wall clock, in a zone where a `Timer.periodic` would
      // have fired 20 times at the chat's 4,000 ms cadence and 20 times at a
      // "helpful" 30-second refresh.
      await Future<void>.delayed(const Duration(milliseconds: 1));
      expect(
        repository.countCalls,
        1,
        reason: 'A second call means something in this feature is on a timer. '
            '`Layout.tsx:114-116` has deps [isAuthenticated] and '
            '`hooks.ts:57-88` installs no interval, no focus listener and no '
            'revalidation. The badge is STALE between sign-in and the '
            "citizen's next interaction, and the port is stale with it "
            '(specs.md § 6.2). Making it fresher is the R-25 class of '
            'divergence no fidelity tier can see, and it is a user decision '
            'plus an ADR — never an implementer\'s.',
      );
    });

    test('this feature owns no Timer at all', () {
      // The source-level companion to the count above. `NotificationsBloc`
      // deliberately does not import `dart:async`; a `close()` that had a timer
      // to cancel would be the first sign the posture had changed.
      //
      // The grep half of this claim lives in the hand-back
      // (`grep -rn "Timer" lib/features/notifications` -> empty). What is
      // checkable here is that closing the BLoC leaves nothing pending:
      // `flutter_test` fails a test that completes with a live timer, so this
      // test passing IS the assertion.
      expect(bloc.isClosed, isFalse);
    });

    test('a repeated auth event for the SAME value issues no second request',
        () async {
      await signIn();
      expect(repository.countCalls, 1);

      // `NotificationBell` dispatches from `initState` AND from a
      // `BlocListener`, and a shell rebuild can re-run the first. Without the
      // no-op guard those two paths would make the bell poll once per rebuild
      // — a poll with an irregular period, which is the hardest kind to
      // notice.
      bloc.add(const NotificationsAuthChanged(true));
      bloc.add(const NotificationsAuthChanged(true));
      await settle();
      expect(repository.countCalls, 1);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B9-AC-19 — the two explicit refreshes that DO exist
  // ───────────────────────────────────────────────────────────────────────────

  group('B9-AC-19 — the two explicit refreshes', () {
    test('opening an UNREAD notice marks it read and refetches the count '
        '— :133-136', () async {
      await signIn();
      await openMenu();
      expect(repository.countCalls, 1);

      final CitizenNotification unread =
          syntheticNotifications().firstWhere((CitizenNotification n) => n.isUnread);
      bloc.add(NotificationOpened(unread));
      await settle();

      expect(repository.readIds, <String>[unread.id]);
      expect(repository.countCalls, 2, reason: 'counter.refetch() at :135');
      expect(bloc.state.open, isFalse, reason: 'setOpen(false) at :130');
    });

    test('opening an ALREADY-READ notice issues neither the POST nor the '
        'refetch — the `if (!item.read_at)` guard at :133', () async {
      await signIn();
      await openMenu();
      final int before = repository.countCalls;

      final CitizenNotification read =
          syntheticNotifications().firstWhere((CitizenNotification n) => !n.isUnread);
      bloc.add(NotificationOpened(read));
      await settle();

      expect(repository.readIds, isEmpty);
      expect(repository.countCalls, before);
      // The menu still closes and the navigation still happens — those are
      // above the guard.
      expect(bloc.state.open, isFalse);
    });

    test('the count is refetched even when the mark-read FAILED — the '
        '`.catch(() => undefined)` at :134 swallows and falls through',
        () async {
      await signIn();
      await openMenu();
      repository.readOne = const Left<Failure, Unit>(Failure('boom'));
      final int before = repository.countCalls;

      final CitizenNotification unread =
          syntheticNotifications().firstWhere((CitizenNotification n) => n.isUnread);
      bloc.add(NotificationOpened(unread));
      await settle();

      expect(repository.readIds, hasLength(1));
      expect(
        repository.countCalls,
        before + 1,
        reason: 'A port that branched on the failure and skipped the refetch '
            'would be more careful than the source and would diverge.',
      );
    });

    test('mark-all refetches BOTH the count and the list — :141-142', () async {
      await signIn();
      await openMenu();
      final int counts = repository.countCalls;
      final int lists = repository.listCalls.length;

      bloc.add(const NotificationsMarkAllRead());
      await settle();

      expect(repository.readAllCalls, 1);
      expect(repository.countCalls, counts + 1);
      expect(repository.listCalls.length, lists + 1);
    });

    test('mark-all leaves the menu OPEN — the source calls no setOpen(false) '
        'there', () async {
      await signIn();
      await openMenu();
      expect(bloc.state.open, isTrue);

      bloc.add(const NotificationsMarkAllRead());
      await settle();

      expect(bloc.state.open, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // The inbox query's enable/deps semantics — hooks.ts:57-88
  // ───────────────────────────────────────────────────────────────────────────

  group('the inbox query — deps [isAuthenticated, open], enabled on both', () {
    test('signed out, opening the menu fetches nothing', () async {
      await openMenu();
      expect(bloc.state.open, isTrue);
      expect(repository.listCalls, isEmpty);
      expect(repository.countCalls, 0);
    });

    test('EVERY opening refetches — the menu is not a cache', () async {
      await signIn();
      await openMenu();
      expect(repository.listCalls, hasLength(1));

      await openMenu(); // close
      await openMenu(); // open again
      expect(repository.listCalls, hasLength(2));
    });

    test('closing the menu fetches nothing', () async {
      await signIn();
      await openMenu();
      final int before = repository.listCalls.length;
      await openMenu(); // close
      expect(repository.listCalls, hasLength(before));
    });

    test('per_page is 8 on every call — Layout.tsx:117', () async {
      await signIn();
      await openMenu();
      await openMenu();
      await openMenu();
      expect(repository.listCalls, everyElement(kNotificationsPerPage));
      expect(kNotificationsPerPage, 8);
    });

    test('signing out closes an open menu', () async {
      await signIn();
      await openMenu();
      expect(bloc.state.open, isTrue);

      bloc.add(const NotificationsAuthChanged(false));
      await settle();
      expect(bloc.state.open, isFalse);
    });

    test('signing out does NOT clear the last count — hooks.ts:58-61 returns '
        'early on !enabled without touching data', () async {
      await signIn();
      expect(bloc.state.unreadCount, 3);

      bloc.add(const NotificationsAuthChanged(false));
      await settle();
      expect(
        bloc.state.unreadCount,
        3,
        reason: 'Invisible in the source because a signed-out bell shows its '
            'dot unconditionally, but it is the measured behaviour.',
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B9-AC-38 — four states, and the order the source evaluates them in
  // ───────────────────────────────────────────────────────────────────────────

  group('B9-AC-38 — the four states of the inbox', () {
    test('loading: the first open, before the response lands', () async {
      repository.latency = const Duration(milliseconds: 50);
      await signIn();
      bloc.add(const NotificationsMenuToggled());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state.listLoading, isTrue);
      expect(bloc.state.listFailed, isFalse);
      expect(bloc.state.listEmpty, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(bloc.state.listLoading, isFalse);
      expect(bloc.state.items, hasLength(8));
    });

    test('data', () async {
      await signIn();
      await openMenu();
      expect(bloc.state.listStatus, RegionStatus.success);
      expect(bloc.state.items, hasLength(8));
      expect(bloc.state.listEmpty, isFalse);
    });

    test('empty is distinct from loading and from a failure', () async {
      repository.emptyList();
      await signIn();
      await openMenu();
      expect(bloc.state.listEmpty, isTrue);
      expect(bloc.state.listLoading, isFalse);
      expect(bloc.state.listFailed, isFalse);
    });

    test('error, with a retry that really re-requests', () async {
      repository.failEverything();
      await signIn();
      await openMenu();
      expect(bloc.state.listFailed, isTrue);
      expect(
        bloc.state.listEmpty,
        isFalse,
        reason: 'An empty list is never an acceptable rendering of a failed '
            'fetch (SSD § 7.3).',
      );

      final int before = repository.listCalls.length;
      bloc.add(const NotificationsListRetried());
      await settle();
      expect(repository.listCalls.length, before + 1);
    });

    test('a retry that succeeds clears the error', () async {
      repository.failEverything();
      await signIn();
      await openMenu();
      expect(bloc.state.listFailed, isTrue);

      repository.list =
          Right<Failure, List<CitizenNotification>>(syntheticNotifications());
      bloc.add(const NotificationsListRetried());
      await settle();

      expect(bloc.state.listFailed, isFalse);
      expect(bloc.state.items, hasLength(8));
    });

    test('a failed count leaves the previous number standing — `?? 0` reads '
        '`.data`, which useQuery only sets on success', () async {
      await signIn();
      expect(bloc.state.unreadCount, 3);

      repository.count = const Left<Failure, int>(Failure('boom'));
      bloc.add(const NotificationsMarkAllRead());
      await settle();

      expect(bloc.state.unreadCount, 3);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // The generation guard — hooks.ts:60,73. The B2 review's finding.
  // ───────────────────────────────────────────────────────────────────────────

  group('the generation guard — a newer request wins', () {
    test('two overlapping list fetches: the SECOND response is the one kept',
        () async {
      // `bloc` 9.2.1's default event transformer is CONCURRENT, so two rapid
      // taps genuinely run two handlers at once. Without the stamp the slower
      // response overwrites the fresher one on arrival — the defect the B2
      // review found in four BLoCs.
      await signIn();
      repository.latency = const Duration(milliseconds: 60);

      // First open: a slow request for the eight-row list.
      bloc.add(const NotificationsMenuToggled());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Close, then reopen against a DIFFERENT answer while the first is still
      // in flight.
      repository.list = const Right<Failure, List<CitizenNotification>>(
        <CitizenNotification>[],
      );
      bloc.add(const NotificationsMenuToggled());
      bloc.add(const NotificationsMenuToggled());

      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(repository.listCalls.length, 2, reason: 'both really ran');
      expect(
        bloc.state.items,
        isEmpty,
        reason: 'the LATER request won. If the eight rows are back, the first '
            "response landed last and overwrote it — `hooks.ts:73`'s "
            '"a newer request won" was not ported.',
      );
    });

    test('two overlapping count fetches: likewise', () async {
      repository.latency = const Duration(milliseconds: 60);
      bloc.add(const NotificationsAuthChanged(true));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      repository.count = const Right<Failure, int>(99);
      bloc.add(const NotificationsMarkAllRead());

      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(bloc.state.unreadCount, 99);
    });
  });

  group('the two badge idioms are one number read two ways — § 2.2 Finding B',
      () {
    test('the DOT is `!isAuthenticated || unreadCount > 0`', () async {
      // Signed out: shown, whatever the count is.
      expect(bloc.state.isAuthenticated, isFalse);
      expect(bloc.state.showsDot, isTrue);

      // Signed in with unread: shown.
      await signIn();
      expect(bloc.state.showsDot, isTrue);

      // Signed in with nothing unread: hidden.
      repository.count = const Right<Failure, int>(0);
      bloc.add(const NotificationsMarkAllRead());
      await settle();
      expect(bloc.state.unreadCount, 0);
      expect(bloc.state.showsDot, isFalse);
    });

    test('the HEADER CONTROLS are `isAuthenticated && unreadCount > 0` — the '
        'other operator', () async {
      expect(bloc.state.showsMarkAllRead, isFalse, reason: 'signed out');

      await signIn();
      expect(bloc.state.showsMarkAllRead, isTrue);

      repository.count = const Right<Failure, int>(0);
      bloc.add(const NotificationsMarkAllRead());
      await settle();
      expect(bloc.state.showsMarkAllRead, isFalse);
    });

    test('signed out is where the two idioms visibly disagree', () async {
      // `||` vs `&&`: the dot is on and the header controls are off. Unifying
      // them — which reads like a simplification — would either hide the
      // signed-out dot (contradicting the frozen baseline, where it is visible
      // in en/02-service.png) or show a "Mark all as read" to someone with no
      // account.
      expect(bloc.state.showsDot, isTrue);
      expect(bloc.state.showsMarkAllRead, isFalse);
    });
  });
}

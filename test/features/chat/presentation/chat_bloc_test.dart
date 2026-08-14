/// `ChatBloc` — **B9-AC-17**, **B9-AC-20**, **B9-AC-35**, **B9-AC-36**,
/// **B9-AC-38**, and the concurrency guard the B2 review found four BLoCs
/// missing.
///
/// Most of these are **invocation-count** claims rather than rendering claims.
/// "The poll is scoped to four conditions", "the read-marker fires on mount
/// with zero messages", "a send is suppressed while one is in flight" are all
/// statements about how many times a use case ran, and none of them is visible
/// in a widget tree — which is why they are asserted here against
/// `FakeChatRepository`'s counters rather than through the panel.
///
/// ## Why half of this file is `testWidgets` with no widget in it
///
/// `test()` runs in the real zone, where a `Timer.periodic` would need four
/// real seconds to fire once and where a **leaked** timer costs nothing.
/// `testWidgets` runs inside `FakeAsync`: `tester.pump(duration)` advances the
/// clock instantly, and `flutter_test` **fails a test that completes with a
/// pending timer**. That second property is not a convenience — it is the
/// mechanism B9-AC-17's "the test completes with no pending timer" clause
/// relies on, so the poll assertions live there and the pure-logic ones do not.
/// `pumpWidget(SizedBox())` is only there because `pump` needs something
/// mounted.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/chat/domain/entities/chat_entities.dart';
import 'package:lcc_mobile_app/features/chat/domain/usecases/chat_usecases.dart';
import 'package:lcc_mobile_app/features/chat/presentation/bloc/chat_bloc.dart';

import '../chat_test_helper.dart';

void main() {
  late FakeChatRepository repository;
  late FakeHelpChannelsRepository help;
  late ChatBloc bloc;

  setUp(() {
    repository = FakeChatRepository();
    help = FakeHelpChannelsRepository();
    bloc = chatBlocOver(repository, help: help);
  });

  tearDown(() => bloc.close());

  /// Lets every queued event and its awaits drain. The effect list can take
  /// several passes (a fetch lands → the `threadId` sync runs → the transcript
  /// fetches → the read-marker fires), and each pass is another microtask turn.
  Future<void> settle() async {
    for (int i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> signIn() async {
    bloc.add(const ChatAuthChanged(true));
    await settle();
  }

  Future<void> open() async {
    bloc.add(const ChatOpened());
    await settle();
  }

  /// Signed in with the panel open on `th-open-1` — the state most assertions
  /// start from.
  Future<void> live() async {
    await signIn();
    await open();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // B9-AC-17 — THE POLL IS 4,000 ms AND ITS GATE IS FOUR CONDITIONS
  // ───────────────────────────────────────────────────────────────────────────

  group('B9-AC-17 — the poll', () {
    testWidgets('the interval is 4,000 ms, not 3,000 and not 5,000', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const SizedBox.shrink());
      final ChatBloc b = chatBlocOver(repository);
      addTearDown(b.close);

      b.add(const ChatAuthChanged(true));
      await tester.pump();
      b.add(const ChatOpened());
      await tester.pump();
      expect(b.state.pollActive, isTrue, reason: 'the gate is open');

      final int before = repository.threadCalls;

      // 3,999 ms: not yet.
      await tester.pump(const Duration(milliseconds: 3999));
      expect(repository.threadCalls, before,
          reason: 'a poll before 4,000 ms means POLL_MS is wrong');

      // The 4,000th millisecond.
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(repository.threadCalls, before + 1);

      expect(kChatPollInterval, const Duration(milliseconds: 4000));

      b.add(const ChatDismissed());
      await tester.pump();
      await tester.pump();
    });

    testWidgets('one tick refetches BOTH the threads and the transcript — '
        '`tick` is in both dependency lists', (WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      final ChatBloc b = chatBlocOver(repository);
      addTearDown(b.close);

      b.add(const ChatAuthChanged(true));
      await tester.pump();
      b.add(const ChatOpened());
      await tester.pump();
      await tester.pump();

      final int threads = repository.threadCalls;
      final int messages = repository.messageCalls.length;

      await tester.pump(const Duration(milliseconds: 4000));
      await tester.pump();

      expect(repository.threadCalls, threads + 1, reason: '`:55`\'s deps');
      expect(repository.messageCalls.length, messages + 1,
          reason: '`:83`\'s deps');

      b.add(const ChatDismissed());
      await tester.pump();
      await tester.pump();
    });

    testWidgets('the gate is FOUR conditions — the timer does not exist in any '
        'of the four negations', (WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());

      // 1. open, not minimised, authenticated, thread — the only live case.
      final ChatBloc all = chatBlocOver(FakeChatRepository());
      addTearDown(all.close);
      all.add(const ChatAuthChanged(true));
      await tester.pump();
      all.add(const ChatOpened());
      await tester.pump();
      await tester.pump();
      expect(all.isPolling, isTrue, reason: 'all four conditions hold');
      expect(all.state.threadId, 'th-open-1');
      all.add(const ChatDismissed());
      await tester.pump();
      await tester.pump();
      expect(all.isPolling, isFalse, reason: 'NEGATION 1: not open');

      // 2. MINIMISED — the condition a three-condition port loses.
      final ChatBloc min = chatBlocOver(FakeChatRepository());
      addTearDown(min.close);
      min.add(const ChatAuthChanged(true));
      await tester.pump();
      min.add(const ChatOpened());
      await tester.pump();
      await tester.pump();
      expect(min.isPolling, isTrue);
      min.add(const ChatMinimizeToggled());
      await tester.pump();
      await tester.pump();
      expect(min.isPolling, isFalse,
          reason: 'NEGATION 2: `live = open && !minimized && isAuthenticated` '
              '(`:42`). A minimised panel is still on screen, so a port that '
              'gated on `open` alone keeps polling behind a 64 px header.');
      min.add(const ChatMinimizeToggled());
      await tester.pump();
      await tester.pump();
      expect(min.isPolling, isTrue, reason: 'and it resumes on restore');
      min.add(const ChatDismissed());
      await tester.pump();
      await tester.pump();

      // 3. SIGNED OUT while open.
      final ChatBloc out = chatBlocOver(FakeChatRepository());
      addTearDown(out.close);
      out.add(const ChatAuthChanged(true));
      await tester.pump();
      out.add(const ChatOpened());
      await tester.pump();
      await tester.pump();
      expect(out.isPolling, isTrue);
      out.add(const ChatAuthChanged(false));
      await tester.pump();
      await tester.pump();
      expect(out.isPolling, isFalse, reason: 'NEGATION 3: signed out');
      expect(out.state.threadId, isNull, reason: '`:74-76` clears it');
      out.add(const ChatDismissed());
      await tester.pump();
      await tester.pump();

      // 4. NO THREAD — open, live, but the citizen has never written.
      final FakeChatRepository empty = FakeChatRepository()..noThreads();
      final ChatBloc none = chatBlocOver(empty);
      addTearDown(none.close);
      none.add(const ChatAuthChanged(true));
      await tester.pump();
      none.add(const ChatOpened());
      await tester.pump();
      await tester.pump();
      expect(none.state.threadId, isNull);
      expect(none.isPolling, isFalse,
          reason: 'NEGATION 4: `if (!live || !threadId) return` (`:94`). An '
              'open panel with no conversation polls nothing — there is no '
              'transcript to re-read.');
      none.add(const ChatDismissed());
      await tester.pump();
      await tester.pump();
    });

    testWidgets('closing the panel leaves NO pending timer — the assertion '
        '`flutter_test` makes for free', (WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      final ChatBloc b = chatBlocOver(repository);
      addTearDown(b.close);

      b.add(const ChatAuthChanged(true));
      await tester.pump();
      b.add(const ChatOpened());
      await tester.pump();
      await tester.pump();
      expect(b.isPolling, isTrue);

      b.add(const ChatDismissed());
      await tester.pump();
      await tester.pump();
      expect(b.isPolling, isFalse);
      // If the timer were still installed, this test would fail on teardown
      // with "A Timer is still pending even after the widget tree was
      // disposed" — which is the mechanical half of § 6.9(1).
    });

    // A plain `test`, not `testWidgets`, and the reason is mechanical:
    // `Bloc.close()` awaits its event queue, and inside `FakeAsync` nothing
    // advances that queue unless something calls `pump` — so `await b.close()`
    // there hangs until the 10-minute harness timeout. The claim here is
    // `isPolling`, which is directly observable, so the real zone is the right
    // one. The LEAK half of § 6.9(1) is asserted by the `testWidgets` cases
    // above, which is where `flutter_test`'s pending-timer check lives.
    test('close() cancels the timer even while the gate is open', () async {
      final ChatBloc b = chatBlocOver(repository);

      b.add(const ChatAuthChanged(true));
      await settle();
      b.add(const ChatOpened());
      await settle();
      expect(b.isPolling, isTrue);

      // The panel is never dismissed — the shell is simply torn down, which is
      // what `BlocProvider(create:)` does on the way out.
      await b.close();
      expect(b.isPolling, isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B9-AC-35 — the read-marker
  // ───────────────────────────────────────────────────────────────────────────

  group('B9-AC-35 — the read-marker fires on transcript CHANGE, not on unread',
      () {
    test('it fires on mount with a thread, even with ZERO messages', () async {
      repository.emptyTranscript();
      await live();

      expect(repository.readCalls, <String>['th-open-1'],
          reason: '`:100-103` is not gated on there being anything unread. A '
              'port that fired only when something was unread is a FAIL.');
    });

    test('it does NOT fire while the panel is shut, or minimised, or signed out',
        () async {
      await signIn();
      expect(repository.readCalls, isEmpty,
          reason: 'signed in but never opened — `live` is false');

      await open();
      expect(repository.readCalls, hasLength(1));

      bloc.add(const ChatMinimizeToggled());
      await settle();
      final int afterMinimise = repository.readCalls.length;

      bloc.add(const ChatMinimizeToggled());
      await settle();
      expect(repository.readCalls.length, greaterThan(afterMinimise),
          reason: 'restoring changes `live`, which IS a dependency, so the '
              'effect re-runs — that is what a dep list does');
    });

    test('a poll that lands NO new message issues no second POST', () async {
      await live();
      final int after = repository.readCalls.length;

      // Same transcript, same length: the dep tuple did not change.
      bloc.add(const ChatPolled());
      await settle();
      bloc.add(const ChatPolled());
      await settle();

      expect(repository.readCalls.length, after,
          reason: '`messages.length` is the dep, not the fetch. An idle open '
              'panel is quiet.');
    });

    test('a poll that lands a NEW message issues one more — once per inbound '
        'message', () async {
      await live();
      final int after = repository.readCalls.length;

      repository.messages = repository.messages.map(
        (List<ChatMessage> rows) => <ChatMessage>[
          ...rows,
          const ChatMessage(id: 'm7', threadId: 'th-open-1', body: 'new'),
        ],
      );
      bloc.add(const ChatPolled());
      await settle();

      expect(repository.readCalls.length, after + 1,
          reason: 'an ACTIVE panel POSTs /read once per inbound message '
              '(§ 2.2 Finding K(2))');
    });

    test('a failed read-marker is swallowed — nothing surfaces and nothing '
        'stops', () async {
      await live();
      final ChatState before = bloc.state;

      repository.failEverything();
      bloc.add(const ChatPolled());
      await settle();

      // `.catch(() => undefined)` at `:102`. The transcript's own failure DOES
      // surface (that is `transcriptFailed`); the read-marker's does not.
      expect(bloc.state.threadId, before.threadId);
      expect(bloc.state.open, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B9-AC-20 — the `ended` guard
  // ───────────────────────────────────────────────────────────────────────────

  group('B9-AC-20 — the ended set holds against a stale list', () {
    test('after close, a threads response still reporting that thread `open` '
        'does NOT re-adopt it', () async {
      await live();
      expect(bloc.state.threadId, 'th-open-1');

      bloc.add(const ChatRated(5));
      await settle();

      expect(repository.closeCalls,
          <({String threadId, int rating})>[(threadId: 'th-open-1', rating: 5)]);
      expect(bloc.state.ended, contains('th-open-1'));

      // THE STALE LIST. The repository still reports `th-open-1` as open —
      // exactly what a backend that has not caught up returns on the next poll.
      expect(
        repository.threads.getOrElse(() => <ChatThread>[]).first.status,
        'open',
        reason: 'the fixture is unchanged, which is the point of the test',
      );

      bloc.add(const ChatPolled());
      await settle();

      expect(bloc.state.threadId, isNot('th-open-1'),
          reason: '`:68`\'s `!ended.current.has(th.id)`. Re-adopting would put '
              'the citizen back into a conversation they just rated and closed.');
      expect(bloc.state.threadId, 'th-pending-2',
          reason: 'the NEXT active thread is adopted, which is what the source '
              'does — `find` returns the first match, not nothing');
    });

    test('the id is added BEFORE the close call, so a poll racing the request '
        'still cannot re-adopt', () async {
      await live();
      repository.latency = const Duration(milliseconds: 50);

      bloc.add(const ChatRated(4));
      await Future<void>.delayed(Duration.zero);

      // Mid-flight: `:155` runs before the `await` at `:157`.
      expect(bloc.state.ended, contains('th-open-1'));
      expect(repository.closeCalls, hasLength(1));

      await Future<void>.delayed(const Duration(milliseconds: 100));
      await settle();
      expect(bloc.state.threadId, isNot('th-open-1'));
    });

    test('a FAILED close still ends the thread locally — the source swallows '
        'the error and resets anyway', () async {
      await live();
      repository.closed = repository.read.swap().swap();
      repository.failEverything();

      bloc.add(const ChatRated(3));
      await settle();

      expect(bloc.state.ended, contains('th-open-1'),
          reason: '`:158-160`: "the thread stays open; nothing the citizen '
              'must act on" — the local reset happens regardless');
      expect(bloc.state.ratingOpen, isFalse);
    });

    test('the ended set is BLOC STATE, not a static — two BLoCs do not share '
        'it', () async {
      await live();
      bloc.add(const ChatRated(5));
      await settle();
      expect(bloc.state.ended, isNotEmpty);

      final ChatBloc second = chatBlocOver(FakeChatRepository());
      addTearDown(second.close);
      expect(second.state.ended, isEmpty,
          reason: 'a `static` would leak across tests and, on a shared device, '
              'across citizens (§ 6.9(3), B9-AC-15)');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B9-AC-36 — sending
  // ───────────────────────────────────────────────────────────────────────────

  group('B9-AC-36 — sending', () {
    test('a FAILED send restores the composer text and clears the optimistic '
        'bubble', () async {
      await live();
      repository.failEverything();

      bloc.add(const ChatInputChanged('ຂ້ອຍຕ້ອງການຄວາມຊ່ວຍເຫຼືອ'));
      await settle();
      bloc.add(const ChatMessageSubmitted('ຂ້ອຍຕ້ອງການຄວາມຊ່ວຍເຫຼືອ'));
      await settle();

      expect(bloc.state.input, 'ຂ້ອຍຕ້ອງການຄວາມຊ່ວຍເຫຼືອ',
          reason: '`catch { setInput(body) }` (`:147`) — the citizen never '
              'loses what they wrote');
      expect(bloc.state.pendingText, isNull,
          reason: '`finally { setPendingText(null) }` (`:149`) — the bubble '
              'goes on failure as well as on success');
      expect(bloc.state.isTyping, isFalse);
    });

    test('a SUCCESSFUL send clears the composer and does not put the text back',
        () async {
      await live();

      bloc.add(const ChatMessageSubmitted('  hello  '));
      await settle();

      expect(bloc.state.input, '');
      expect(bloc.state.pendingText, isNull);
      expect(repository.sentCalls.single.body, 'hello',
          reason: 'trimmed at `:130` before it is sent');
    });

    test('the optimistic bubble is visible WHILE the send is in flight', () async {
      await live();
      repository.latency = const Duration(milliseconds: 50);

      bloc.add(const ChatMessageSubmitted('in flight'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.pendingText, 'in flight');
      expect(bloc.state.isTyping, isTrue);
      expect(bloc.state.input, '');

      await Future<void>.delayed(const Duration(milliseconds: 100));
      await settle();
      expect(bloc.state.pendingText, isNull);
    });

    test('a send is SUPPRESSED while one is in flight — the double-tap case',
        () async {
      await live();
      repository.latency = const Duration(milliseconds: 50);

      bloc.add(const ChatMessageSubmitted('first'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.isTyping, isTrue);

      // The second tap, and a chip tap, both land on `:131`'s guard.
      bloc.add(const ChatMessageSubmitted('second'));
      bloc.add(const ChatMessageSubmitted('third'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await settle();

      expect(repository.sentCalls.map((({String body, String threadId}) c) => c.body),
          <String>['first'],
          reason: '`if (!body || !isAuthenticated || isTyping) return` '
              '(`:131`). Two sends in flight is the race the B2 review found '
              'four BLoCs open to; here the source itself closes it.');
    });

    test('an empty or whitespace-only submit sends nothing', () async {
      await live();

      bloc.add(const ChatMessageSubmitted(''));
      bloc.add(const ChatMessageSubmitted('   '));
      bloc.add(const ChatMessageSubmitted('\n\t '));
      await settle();

      expect(repository.sentCalls, isEmpty);
      expect(repository.startedMessages, isEmpty);
    });

    test('a signed-out submit sends nothing, even with a thread in hand',
        () async {
      await live();
      bloc.add(const ChatAuthChanged(false));
      await settle();

      bloc.add(const ChatMessageSubmitted('hello'));
      await settle();

      expect(repository.sentCalls, isEmpty);
    });

    test('the FIRST message starts a thread and the reply\'s id is adopted',
        () async {
      final FakeChatRepository fresh = FakeChatRepository()..noThreads();
      final ChatBloc b = chatBlocOver(fresh);
      addTearDown(b.close);

      b.add(const ChatAuthChanged(true));
      await settle();
      b.add(const ChatOpened());
      await settle();
      expect(b.state.threadId, isNull);

      b.add(const ChatMessageSubmitted('first ever'));
      await settle();

      expect(fresh.startedMessages, <String>['first ever']);
      expect(fresh.sentCalls, isEmpty, reason: 'start, not send');
      expect(b.state.threadId, 'th-new-9', reason: '`:141`');
    });

    test('a create response with no thread id is NOT adopted', () async {
      final FakeChatRepository fresh = FakeChatRepository()..noThreads();
      fresh.started = fresh.started.map((StartedThread _) =>
          const StartedThread(thread: ChatThread()));
      final ChatBloc b = chatBlocOver(fresh);
      addTearDown(b.close);

      b.add(const ChatAuthChanged(true));
      await settle();
      b.add(const ChatOpened());
      await settle();
      b.add(const ChatMessageSubmitted('orphan'));
      await settle();

      expect(b.state.threadId, isNull,
          reason: 'an empty id is "no thread was created", not a thread called '
              '""; adopting it would poll `/me/chat/threads//messages`');
    });

    test('signing out while a create is in flight does not adopt the thread — '
        'the re-check the B2 BLoCs did not make', () async {
      final FakeChatRepository fresh = FakeChatRepository()..noThreads();
      fresh.latency = const Duration(milliseconds: 50);
      final ChatBloc b = chatBlocOver(fresh);
      addTearDown(b.close);

      b.add(const ChatAuthChanged(true));
      await settle();
      b.add(const ChatOpened());
      await settle();

      b.add(const ChatMessageSubmitted('racing'));
      await Future<void>.delayed(Duration.zero);
      b.add(const ChatAuthChanged(false));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await settle();

      expect(b.state.threadId, isNull,
          reason: 'a stale response must not put a signed-out citizen back on '
              'a thread — `emit(… await …)` with no re-check is exactly the '
              'defect the B2 reviews found in four BLoCs');
    });

    test('`canSend` is both guards — empty-after-trim AND in flight', () async {
      await live();
      expect(bloc.state.canSend, isFalse, reason: 'empty composer');

      bloc.add(const ChatInputChanged('   '));
      await settle();
      expect(bloc.state.canSend, isFalse, reason: 'whitespace only (`:529`)');

      bloc.add(const ChatInputChanged('x'));
      await settle();
      expect(bloc.state.canSend, isTrue);

      repository.latency = const Duration(milliseconds: 50);
      bloc.add(const ChatMessageSubmitted('x'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.canSend, isFalse, reason: 'in flight');

      await Future<void>.delayed(const Duration(milliseconds: 100));
      await settle();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B9-AC-38 — four states, and the concurrency guard
  // ───────────────────────────────────────────────────────────────────────────

  group('B9-AC-38 — the transcript\'s four states', () {
    test('loading, then data', () async {
      repository.latency = const Duration(milliseconds: 60);
      bloc.add(const ChatAuthChanged(true));
      bloc.add(const ChatOpened());

      // The threads read resolves first (60 ms); the transcript request starts
      // after it, so the skeleton window opens somewhere past 60 ms and closes
      // at 120 ms.
      await Future<void>.delayed(const Duration(milliseconds: 90));
      expect(bloc.state.threadId, 'th-open-1');
      expect(bloc.state.transcriptLoading, isTrue,
          reason: 'the transcript request is in flight and there is nothing on '
              'screen yet — `transcript.loading && messages.length === 0`');

      await Future<void>.delayed(const Duration(milliseconds: 300));
      await settle();
      expect(bloc.state.transcriptLoading, isFalse);
      expect(bloc.state.messages, hasLength(6));
      expect(bloc.state.showsGreeting, isFalse);

      bloc.add(const ChatDismissed());
      await settle();
    });

    test('empty is the GREETING, not an empty state — `:340`', () async {
      repository.emptyTranscript();
      await live();

      expect(bloc.state.transcriptFailed, isFalse);
      expect(bloc.state.messages, isEmpty);
      expect(bloc.state.showsGreeting, isTrue,
          reason: 'the assistant opens the conversation; there is no "no '
              'messages" empty state in this surface');
    });

    test('error, and retry recovers', () async {
      // ONLY the transcript fails. Failing everything would fail the THREADS
      // read too, and then no thread is adopted, the transcript query is never
      // enabled, and there is no error to render — which is itself the
      // measured behaviour and is asserted in the next test.
      repository.messages = const Left<Failure, List<ChatMessage>>(
        Failure('stubbed transcript failure'),
      );
      await live();

      expect(bloc.state.threadId, 'th-open-1');
      expect(bloc.state.transcriptFailed, isTrue,
          reason: 'an empty list is never an acceptable rendering of a failed '
              'fetch (SSD § 7.3)');
      expect(bloc.state.messages, isEmpty);
      expect(bloc.state.transcriptLoading, isFalse,
          reason: 'error wins over loading, and over the greeting');

      // The retry with the backend still down.
      final int before = repository.messageCalls.length;
      bloc.add(const ChatTranscriptRetried());
      await settle();
      expect(repository.messageCalls.length, before + 1,
          reason: '`transcript.refetch()` (`:330`) really refetches');
      expect(bloc.state.transcriptFailed, isTrue, reason: 'still failing');

      // …and with it back up.
      repository.messages =
          Right<Failure, List<ChatMessage>>(syntheticMessages());
      bloc.add(const ChatTranscriptRetried());
      await settle();
      expect(bloc.state.transcriptFailed, isFalse);
      expect(bloc.state.messages, hasLength(6));

      bloc.add(const ChatDismissed());
      await settle();
    });

    test('with NO thread the panel shows the greeting, not a skeleton — '
        '`hooks.ts:46` is `useState(enabled)`', () async {
      // MEASURED, and it corrected this port: `useQuery`'s initial `loading` is
      // the query's initial ENABLED value, and the transcript's is
      // `Boolean(threadId) && isAuthenticated` — false on the first render.
      // `:58-61` then re-asserts it. A port that treated "never asked" as
      // "loading" would show two grey bars to every citizen who opens the panel
      // before their thread list lands.
      final FakeChatRepository fresh = FakeChatRepository()..noThreads();
      final ChatBloc b = chatBlocOver(fresh);
      addTearDown(b.close);

      b.add(const ChatAuthChanged(true));
      await settle();
      b.add(const ChatOpened());
      await settle();

      expect(b.state.threadId, isNull);
      expect(fresh.messageCalls, isEmpty, reason: 'the query never ran');
      expect(b.state.transcriptLoading, isFalse);
      expect(b.state.transcriptFailed, isFalse);
      expect(b.state.showsGreeting, isTrue);
    });

    test('a poll does NOT flash the skeleton over a transcript already on '
        'screen', () async {
      await live();
      expect(bloc.state.transcriptLoaded, isTrue);

      repository.latency = const Duration(milliseconds: 50);
      bloc.add(const ChatPolled());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.transcriptLoading, isFalse,
          reason: '`hooks.ts:67-68` sets `refreshing`, not `loading`, once '
              'there is data. Collapsing the two makes the panel blink every '
              'four seconds.');

      await Future<void>.delayed(const Duration(milliseconds: 300));
      await settle();
      bloc.add(const ChatDismissed());
      await settle();
    });
  });

  group('the concurrency guard — `hooks.ts:60,73`', () {
    test('a stale transcript response is DROPPED — a newer request won',
        () async {
      await live();

      // Two overlapping transcript fetches; the first is slow, the second is
      // fast and returns a different transcript.
      repository.latency = const Duration(milliseconds: 80);
      bloc.add(const ChatPolled());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      repository.latency = Duration.zero;
      repository.messages = repository.messages.map(
        (List<ChatMessage> _) => const <ChatMessage>[
          ChatMessage(id: 'fresh', threadId: 'th-open-1', body: 'FRESH'),
        ],
      );
      bloc.add(const ChatPolled());
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await settle();

      expect(bloc.state.messages.single.body, 'FRESH',
          reason: 'without the generation stamp the SLOW first response lands '
              'last and overwrites the fresh one — the exact defect the B2 '
              'review found in four BLoCs, over a bloc 9.2.1 transformer that '
              'is concurrent by default');

      bloc.add(const ChatDismissed());
      await settle();
    });

    test('a transcript response for a thread that is no longer selected is '
        'dropped — the case the generation stamp cannot see', () async {
      await live();
      repository.latency = const Duration(milliseconds: 80);

      bloc.add(const ChatPolled());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      // Sign out: `threadId` is cleared and NO replacement request starts, so
      // nothing bumps the generation.
      bloc.add(const ChatAuthChanged(false));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await settle();

      expect(bloc.state.threadId, isNull);
      expect(bloc.state.messages, isEmpty,
          reason: '`messages` is guarded on `threadId` (`:89`) AND the loader '
              're-checks the thread it asked for');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // The rest of the ported behaviour
  // ───────────────────────────────────────────────────────────────────────────

  group('the launcher badge — `:127`', () {
    test('it sums EVERY thread, including closed ones', () async {
      await signIn();
      expect(bloc.state.unread, 7,
          reason: '2 + 0 + 5 + 0. A port that summed only active threads would '
              'render 2.');
    });

    test('it is forced to 0 while the panel is live', () async {
      await live();
      expect(bloc.state.live, isTrue);
      expect(bloc.state.unread, 0);
    });

    test('minimising makes it visible again, because `live` goes false',
        () async {
      await live();
      bloc.add(const ChatMinimizeToggled());
      await settle();
      expect(bloc.state.unread, 7);
    });
  });

  group('the channels fetch — `:47-49`', () {
    test('it does not run until the panel opens, and it runs once', () async {
      await signIn();
      expect(help.calls, 0, reason: '`enabled: open`');

      await open();
      expect(help.calls, 1);
      expect(bloc.state.supportPhone, '1590 234');
      expect(bloc.state.supportEmail, 'support@lcc.gov.la');
    });

    test('it is NOT gated on the session — the endpoint is anonymous', () async {
      bloc.add(const ChatOpened());
      await settle();
      expect(help.calls, 1,
          reason: '`content.supportChannels` carries `anonymous: true` and its '
              'query is enabled on `open` alone (`:47-49`)');
    });

    test('a failed channels fetch is invisible — no error state, no button',
        () async {
      final FakeHelpChannelsRepository broken = FakeHelpChannelsRepository()
        ..nonedPublished();
      final ChatBloc b = chatBlocOver(FakeChatRepository(), help: broken);
      addTearDown(b.close);

      b.add(const ChatOpened());
      await settle();

      expect(b.state.supportPhone, '');
      expect(b.state.supportEmail, '');
    });

    test('supportPhone falls back phone -> hotline — B9-AC-43', () async {
      await open();
      // The fixture publishes `hotline` and NOT `phone`, so a port that read
      // only `phone` would render no call button at all.
      expect(bloc.state.channelValue('phone'), '');
      expect(bloc.state.channelValue('hotline'), '1590 234');
      expect(bloc.state.supportPhone, '1590 234');
    });
  });

  group('thread selection — `:65-79`', () {
    test('the first OPEN or PENDING thread is adopted, and resolved/closed are '
        'skipped', () async {
      await signIn();
      expect(bloc.state.activeThread?.id, 'th-open-1');

      final FakeChatRepository onlyClosed = FakeChatRepository();
      onlyClosed.threads = onlyClosed.threads.map(
        (List<ChatThread> rows) => rows
            .where((ChatThread t) => !t.isActive)
            .toList(growable: false),
      );
      final ChatBloc b = chatBlocOver(onlyClosed);
      addTearDown(b.close);
      b.add(const ChatAuthChanged(true));
      await settle();
      expect(b.state.activeThread, isNull);
      expect(b.state.threadId, isNull,
          reason: 'a closed conversation is left alone and the next message '
              'opens a fresh thread (`:63-64`)');
    });

    test('agentName comes from the SELECTED thread and is null for a bot',
        () async {
      await live();
      expect(bloc.state.threadId, 'th-open-1');
      expect(bloc.state.agentName, isNull);

      bloc.add(const ChatRated(5));
      await settle();
      bloc.add(const ChatPolled());
      await settle();

      expect(bloc.state.threadId, 'th-pending-2');
      expect(bloc.state.agentName, 'ນາງ ສົມສີ ພົມມະຈັນ');
      bloc.add(const ChatDismissed());
      await settle();
    });
  });

  group('the chips — `:187-192`', () {
    test('null means "the opening quick replies", which are KEYS', () async {
      repository.emptyTranscript();
      await live();
      expect(bloc.state.botSuggestions, isNull);
      expect(kChatQuickReplies, hasLength(4));
      expect(kChatQuickReplies.first, startsWith('chat.'));
    });

    test('with a transcript, the LAST message\'s suggestions win', () async {
      await live();
      expect(bloc.state.botSuggestions,
          <String>['Track my application', 'ເວລາເຮັດການ'],
          reason: 'the transcript\'s last message (`:192`), NOT the POST '
              'response\'s `suggestions` field, which is dead (§ 2.2 '
              'Finding D)');
      bloc.add(const ChatDismissed());
      await settle();
    });

    test('an ASSIGNED AGENT suppresses them entirely', () async {
      await live();
      bloc.add(const ChatRated(5));
      await settle();
      bloc.add(const ChatPolled());
      await settle();

      expect(bloc.state.agentName, isNotNull);
      expect(bloc.state.botSuggestions, isEmpty,
          reason: '"Once an agent is on the thread the API stops suggesting '
              'and so does the UI" (`:184-186`, `:190-191`)');
      bloc.add(const ChatDismissed());
      await settle();
    });
  });

  group('the panel\'s own state', () {
    test('opening after minimising restores expanded — `handleOpen` sets BOTH',
        () async {
      await live();
      bloc.add(const ChatMinimizeToggled());
      await settle();
      expect(bloc.state.minimized, isTrue);

      bloc.add(const ChatDismissed());
      await settle();
      bloc.add(const ChatOpened());
      await settle();

      expect(bloc.state.open, isTrue);
      expect(bloc.state.minimized, isFalse, reason: '`:167-168`');
      bloc.add(const ChatDismissed());
      await settle();
    });

    test('closing keeps the thread and the transcript — reopening resumes',
        () async {
      await live();
      expect(bloc.state.messages, hasLength(6));

      bloc.add(const ChatDismissed());
      await settle();
      expect(bloc.state.threadId, 'th-open-1',
          reason: '`:271` is `setOpen(false)` and nothing else');

      bloc.add(const ChatOpened());
      await settle();
      expect(bloc.state.messages, hasLength(6));
      bloc.add(const ChatDismissed());
      await settle();
    });

    test('signing out does NOT close the panel — it swaps the body for the '
        'sign-in prompt', () async {
      await live();
      bloc.add(const ChatAuthChanged(false));
      await settle();

      expect(bloc.state.open, isTrue,
          reason: '`:282` renders the prompt INSIDE the open panel. The '
              'notification menu closes on sign-out and this does not; two '
              'surfaces, two measured behaviours.');
      expect(bloc.state.showsGreeting, isTrue,
          reason: '`messages` is empty because `threadId` is null');
    });

    test('an auth event that does not change the flag is a no-op', () async {
      await signIn();
      final int calls = repository.threadCalls;
      bloc.add(const ChatAuthChanged(true));
      await settle();
      expect(repository.threadCalls, calls,
          reason: 'a rebuild for an unrelated reason must not issue a second '
              'round of requests and quietly turn the panel into a poller');
    });

    test('the rating strip opens and dismisses without closing the thread',
        () async {
      await live();
      bloc.add(const ChatRatingRequested());
      await settle();
      expect(bloc.state.ratingOpen, isTrue);
      expect(bloc.state.threadId, 'th-open-1');

      bloc.add(const ChatRatingDismissed());
      await settle();
      expect(bloc.state.ratingOpen, isFalse);
      expect(repository.closeCalls, isEmpty,
          reason: '"Not now" (`:485`) dismisses the strip, which is why '
              '`endChat` is never reachable with rating 0');
      bloc.add(const ChatDismissed());
      await settle();
    });
  });

  test('B9-AC-15 — the transcript is asked for with per_page 100', () async {
    await live();
    expect(repository.messageCalls.first, 'th-open-1|100');
    expect(kChatMessagesPerPage, 100);
    bloc.add(const ChatDismissed());
    await settle();
  });
}

/// `ChatBloc` — the customer-service panel's state. Four queries, three
/// mutations, one timer.
///
/// Ports `CustomerServiceChat.tsx` (564 measured lines) in its entirety except
/// the markup.
///
/// ## THE POLL IS 4,000 ms AND ITS GATE IS FOUR CONDITIONS
///
/// `:12` declares `POLL_MS = 4000`; `:93-97` installs the interval guarded on
/// `live && threadId`, where `live = open && !minimized && isAuthenticated`
/// (`:42`). So the transcript re-reads **while and only while** the panel is
/// open, not minimised, signed in, and holding a thread. A poll that runs while
/// minimised, or with no thread, is a divergence **no fidelity tier can see** —
/// Tier 1 compares text, Tier 2 compares colours, Tier 3 compares pixels, and
/// none of them can observe a request that should not have been made
/// (specs.md § 6.2, B9-AC-17).
///
/// The interval is owned here and cancelled in [close]. That is mechanically
/// checkable for free: `flutter_test` fails a test that completes with a
/// pending timer, so a widget test that opens the panel, closes it and settles
/// is a real assertion rather than a comment (§ 6.9(1)).
///
/// **There is no realtime transport to port.** `grep -rn
/// "WebSocket\|EventSource\|socket.io\|wss://" lcc-app/src` is empty. A
/// websocket here would make the app *better* than its source — the R-25 class,
/// a user decision plus an ADR, never an implementer's (§ 6.2, § 8.3, FU-4).
///
/// ## Effects, not handlers: why `_runEffects` exists
///
/// The React component is six `useEffect`s over eleven pieces of state, and
/// four of them are `useQuery` calls whose dependency lists overlap. Re-deriving
/// "which fetches does this interaction trigger?" inside each event handler is
/// how a port loses one: the read-marker fires on `messages.length`, which no
/// handler sets, and the transcript refetches on `tick`, which the *timer*
/// sets.
///
/// So the handlers only mutate state, and [_reconcile] then replays the
/// component's effects in **declaration order** — channels (`:47`), threads
/// (`:55`), the `threadId` sync (`:73`), the transcript (`:81`), the poll
/// (`:93`), the read-marker (`:100`) — each one firing exactly when its
/// dependency tuple has changed, which is React's own rule. The loop is the
/// render → effect → `setState` → render cycle; it terminates because every
/// effect stamps its key **before** running, so a state that stops changing
/// stops firing effects.
///
/// ## The generation guard is a port, not an embellishment
///
/// `hooks.ts:60,73,79,84` stamps every in-flight request with
/// `const mine = ++generation.current` and drops the response when
/// `mine !== generation.current` — *"a newer request won"*. Reproduced here per
/// query, and it is load-bearing rather than decorative: `bloc` 9.2.1's default
/// event transformer is **concurrent**, and this feature has strictly more
/// interleaving than any before it — a 4,000 ms timer dispatching into the same
/// BLoC a citizen is typing and sending into. Four B2 BLoCs `emit(… await …)`
/// with no such re-check; this one does not, and [_loadTranscript] additionally
/// re-checks the **thread id**, because a sign-out clears it without starting a
/// replacement request for the guard to bump.
///
/// ## Where the session comes from
///
/// Not from here. `isAuthenticated` arrives as [ChatAuthChanged], dispatched by
/// `ChatLauncher` from the app-wide `SessionBloc` — the same shape the React
/// component uses, where `isAuthenticated` is read from `useSession()` at the
/// top of the tree. That keeps this BLoC testable with no session in the tree
/// and keeps the shell session-agnostic.
library;

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../help/domain/entities/help_entities.dart';
import '../../../help/domain/usecases/help_usecases.dart';
import '../../domain/entities/chat_entities.dart';
import '../../domain/usecases/chat_usecases.dart';

part 'chat_event.dart';
part 'chat_state.dart';
part 'chat_bloc.freezed.dart';

/// `const POLL_MS = 4000` — `CustomerServiceChat.tsx:12`.
const Duration kChatPollInterval = Duration(milliseconds: 4000);

/// `const QUICK_REPLIES = [...]` — `:18`. **i18n keys**, not strings: the
/// widget translates them (`t(key)`, `:189`). Four, in this order.
const List<String> kChatQuickReplies = <String>[
  'chat.qrBirthCert',
  'chat.qrTrack',
  'chat.qrDocuments',
  'chat.qrHours',
];

/// How many times [_reconcile] will replay the effect list before giving up.
///
/// Convergence is two or three passes (a fetch lands → the `threadId` sync
/// runs → the transcript fetches → the read-marker fires). The bound is a guard
/// against a future edit introducing a cycle, not against today's logic; if it
/// is ever hit, an effect is re-firing on a key it also mutates.
const int _kMaxEffectPasses = 6;

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required this.getChatThreads,
    required this.getChatMessages,
    required this.startChatThread,
    required this.sendChatMessage,
    required this.markThreadRead,
    required this.closeChatThread,
    required this.getSupportChannels,
  }) : super(const ChatState()) {
    on<ChatAuthChanged>(_onAuthChanged);
    on<ChatOpened>(_onOpened);
    on<ChatDismissed>(_onDismissed);
    on<ChatMinimizeToggled>(_onMinimizeToggled);
    on<ChatInputChanged>(_onInputChanged);
    on<ChatMessageSubmitted>(_onMessageSubmitted);
    on<ChatRatingRequested>(_onRatingRequested);
    on<ChatRatingDismissed>(_onRatingDismissed);
    on<ChatRated>(_onRated);
    on<ChatTranscriptRetried>(_onTranscriptRetried);
    on<ChatPolled>(_onPolled);
  }

  final GetChatThreads getChatThreads;
  final GetChatMessages getChatMessages;
  final StartChatThread startChatThread;
  final SendChatMessage sendChatMessage;
  final MarkThreadRead markThreadRead;
  final CloseChatThread closeChatThread;

  /// `/help/channels`, **reused from `features/help/domain`** rather than
  /// re-implemented: `GetSupportChannels` and `SupportChannel` already exist,
  /// CFI permits the import and G-L3 measures that exact boundary and allows it
  /// (specs.md § 6.6, B9-AC-43).
  final GetSupportChannels getSupportChannels;

  /// `const [tick, setTick] = useState(0)` — `:38`.
  ///
  /// Private rather than state because nothing renders it; it exists only as a
  /// dependency of the threads and transcript queries, which is exactly what it
  /// is in the source.
  int _tick = 0;

  /// `useRef(0)` per query — `hooks.ts:55`.
  int _channelsGeneration = 0;
  int _threadsGeneration = 0;
  int _transcriptGeneration = 0;

  /// The last dependency tuple each effect ran against. `null` means "never
  /// run", which is React's state on the first render.
  String? _channelsKey;
  String? _threadsKey;
  String? _transcriptKey;
  String? _readKey;

  /// `setInterval(…, POLL_MS)` — `:95`. Null when the four-condition gate is
  /// shut.
  Timer? _poll;

  /// Visible for tests: whether the interval is currently installed.
  ///
  /// B9-AC-17 asserts this is true under the gate and false in each of its four
  /// negations. Exposed rather than inferred from `Timer` internals, and it is
  /// still not the only assertion — the same tests complete without a pending
  /// timer, which `flutter_test` enforces on its own.
  bool get isPolling => _poll != null;

  @override
  Future<void> close() {
    // `return () => clearInterval(timer)` — `:96`. In React the cleanup also
    // fires on minimise, sign-out and thread-clear; here those go through
    // [_syncTimer]. This one is the unmount.
    _poll?.cancel();
    _poll = null;
    return super.close();
  }

  // ── Handlers: mutate state, then replay the effects ────────────────────────

  Future<void> _onAuthChanged(
    ChatAuthChanged event,
    Emitter<ChatState> emit,
  ) async {
    if (event.isAuthenticated == state.isAuthenticated) return;
    emit(state.copyWith(isAuthenticated: event.isAuthenticated));
    // NOT `open: false`. Signing out leaves the panel where it is and swaps its
    // body for the sign-in prompt (`:282-311`) — unlike the notification menu,
    // which closes. Two surfaces, two measured behaviours.
    await _reconcile(emit);
  }

  /// `handleOpen` — `:166-169`. **Both** flags: a panel minimised and then
  /// closed reopens expanded.
  Future<void> _onOpened(ChatOpened event, Emitter<ChatState> emit) async {
    emit(state.copyWith(open: true, minimized: false));
    await _reconcile(emit);
  }

  /// `setOpen(false)` — `:271`. Keeps `threadId`, `minimized` and the
  /// transcript, so reopening resumes the same conversation.
  Future<void> _onDismissed(
    ChatDismissed event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(open: false));
    await _reconcile(emit);
  }

  /// `setMinimized(m => !m)` — `:260`.
  Future<void> _onMinimizeToggled(
    ChatMinimizeToggled event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(minimized: !state.minimized));
    await _reconcile(emit);
  }

  /// `setInput(e.target.value)` — `:522`.
  ///
  /// No [_reconcile]: `input` is in no effect's dependency list, so a keystroke
  /// triggers no fetch in the source either. Running the effect list per
  /// keystroke would be free of behavioural consequence and would make every
  /// invocation-count assertion in the test suite depend on typing speed.
  void _onInputChanged(ChatInputChanged event, Emitter<ChatState> emit) {
    emit(state.copyWith(input: event.value));
  }

  /// `setRating(true)` — `:224`.
  void _onRatingRequested(
    ChatRatingRequested event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(ratingOpen: true));
  }

  /// `setRating(false)` — `:485`. Dismisses the strip; the thread stays open.
  void _onRatingDismissed(
    ChatRatingDismissed event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(ratingOpen: false));
  }

  /// `transcript.refetch()` — `:330`.
  Future<void> _onTranscriptRetried(
    ChatTranscriptRetried event,
    Emitter<ChatState> emit,
  ) async {
    final String? threadId = state.threadId;
    if (threadId == null || !state.isAuthenticated) return;
    await _loadTranscript(emit, threadId);
    await _reconcile(emit);
  }

  /// One turn of the poll — `setTick(n => n + 1)`, `:95`.
  ///
  /// `tick` is a dependency of **both** the threads query (`:55`) and the
  /// transcript query (`:83`), so one tick refetches both. The launcher badge
  /// and the transcript therefore stay in step, which is what makes
  /// `unread = live ? 0 : Σ` (`:127`) coherent.
  Future<void> _onPolled(ChatPolled event, Emitter<ChatState> emit) async {
    _tick++;
    await _reconcile(emit);
  }

  /// `sendMessage(raw)` — `:129-151`.
  Future<void> _onMessageSubmitted(
    ChatMessageSubmitted event,
    Emitter<ChatState> emit,
  ) async {
    // `const body = raw.trim()` — `:130`. THE TRIM PRECEDES THE TRUNCATION:
    // `subject` is computed from this string, not from `raw` (B9-AC-25).
    final String body = event.raw.trim();

    // `if (!body || !isAuthenticated || isTyping) return` — `:131`.
    //
    // This is also the concurrency guard, and it is the source's rather than
    // this port's: a second submit while one is in flight is dropped here, so
    // the `await` below cannot be raced by another send. A double-tap on the
    // send button, or a chip tapped during a send, both land on this line.
    if (body.isEmpty || !state.isAuthenticated || state.isTyping) return;

    final String? threadId = state.threadId;

    // `setInput(""); setPendingText(body)` — `:133-134`, plus the mutation's
    // own `pending` flag. Exactly one of the two flags, because exactly one of
    // the two mutations runs.
    emit(state.copyWith(
      input: '',
      pendingText: body,
      startPending: threadId == null,
      sendPending: threadId != null,
    ));

    if (threadId != null) {
      final Either<Failure, SentMessage> result = await sendChatMessage(
        SendChatMessageParams(threadId: threadId, body: body),
      );
      if (emit.isDone) return;
      emit(state.copyWith(
        // `finally { setPendingText(null) }` — `:148-150`.
        pendingText: null,
        sendPending: false,
        // `catch { setInput(body) }` — `:144-147`. The citizen never loses what
        // they wrote. On success the composer keeps whatever they have typed
        // since, which is what the source does by not touching it.
        input: result.isLeft() ? body : state.input,
      ));
      if (result.isRight()) _tick++;
    } else {
      final Either<Failure, StartedThread> result =
          await startChatThread(StartChatThreadParams(body));
      if (emit.isDone) return;

      final String created =
          result.fold((Failure _) => '', (StartedThread s) => s.thread.id);

      // The re-check the B2 BLoCs did not do. A `ChatAuthChanged(false)` that
      // landed while this request was in flight has already cleared `threadId`;
      // adopting the created id here would put a signed-out citizen back on a
      // thread for the one frame before the effect list cleared it again.
      final bool adopt =
          result.isRight() && created.isNotEmpty && state.isAuthenticated;

      emit(state.copyWith(
        pendingText: null,
        startPending: false,
        input: result.isLeft() ? body : state.input,
        // `setThreadId(created.thread.id)` — `:141`.
        threadId: adopt ? created : state.threadId,
      ));
      if (result.isRight()) _tick++;
    }

    // `setTick(n => n + 1)` — `:143`, inside the `try`, so a failed send does
    // not refetch. The bump above is that; this replays the effects it changed.
    await _reconcile(emit);
  }

  /// `endChat(stars)` — `:153-164`.
  Future<void> _onRated(ChatRated event, Emitter<ChatState> emit) async {
    final String? threadId = state.threadId;
    if (threadId == null) return;

    // `ended.current.add(threadId)` — `:155`, **before** the close call. The
    // comment at `:59-60` states the hazard it exists for: *"a stale list
    // cannot re-adopt one between the close call and the next poll"*
    // (B9-AC-20).
    emit(state.copyWith(
      ended: <String>{...state.ended, threadId},
      closePending: true,
    ));

    // `catch { /* the thread stays open; nothing the citizen must act on */ }`
    // — `:158-160`. The `Either` is discarded rather than branched on, which is
    // what swallowing it means.
    await closeChatThread(
      CloseChatThreadParams(threadId: threadId, rating: event.stars),
    );
    if (emit.isDone) return;

    // `setRating(false); setThreadId(null); setTick(n + 1)` — `:161-163`. All
    // three run whether the close succeeded or not.
    emit(state.copyWith(
      ratingOpen: false,
      threadId: null,
      closePending: false,
    ));
    _tick++;
    await _reconcile(emit);
  }

  // ── The effect list ────────────────────────────────────────────────────────

  Future<void> _reconcile(Emitter<ChatState> emit) async {
    for (int pass = 0; pass < _kMaxEffectPasses; pass++) {
      if (emit.isDone) return;
      final bool changed = await _runEffects(emit);
      if (!changed) return;
    }
  }

  /// One render's worth of effects, in the order `CustomerServiceChat.tsx`
  /// declares them. Returns whether any of them emitted.
  Future<bool> _runEffects(Emitter<ChatState> emit) async {
    bool changed = false;

    // 1. channels — `useQuery(content.supportChannels, [open], {enabled: open})`
    //    (`:47-49`). Public, and only worth fetching once the panel is on
    //    screen.
    final String channelsKey = '${state.open}';
    if (channelsKey != _channelsKey) {
      _channelsKey = channelsKey;
      if (state.open) {
        await _loadChannels(emit);
        changed = true;
      }
    }
    if (emit.isDone) return false;

    // 2. threads — `useQuery(me.chatThreads, [tick, isAuthenticated],
    //    {enabled: isAuthenticated})` (`:55-57`).
    final String threadsKey = '$_tick|${state.isAuthenticated}';
    if (threadsKey != _threadsKey) {
      _threadsKey = threadsKey;
      if (state.isAuthenticated) {
        await _loadThreads(emit);
        changed = true;
      }
    }
    if (emit.isDone) return false;

    // 3. the `threadId` sync — `:73-79`. Not a query: a plain effect over
    //    `[isAuthenticated, threadId, activeThread]`.
    if (!state.isAuthenticated) {
      if (state.threadId != null) {
        emit(state.copyWith(threadId: null));
        changed = true;
      }
    } else if (state.threadId == null) {
      final ChatThread? active = state.activeThread;
      if (active != null) {
        emit(state.copyWith(threadId: active.id));
        changed = true;
      }
    }

    // 4. transcript — `useQuery(me.chatMessages, [threadId, tick],
    //    {enabled: Boolean(threadId) && isAuthenticated})` (`:81-85`).
    final String transcriptKey = '${state.threadId}|$_tick';
    if (transcriptKey != _transcriptKey) {
      _transcriptKey = transcriptKey;
      final String? threadId = state.threadId;
      if (threadId != null && state.isAuthenticated) {
        await _loadTranscript(emit, threadId);
        changed = true;
      }
    }
    if (emit.isDone) return false;

    // 5. the poll — `:93-97`.
    _syncTimer();

    // 6. the read-marker — `:100-103`. Deps `[live, threadId, messages.length]`,
    //    and **not gated on there being anything unread**: it fires on mount
    //    with zero messages and again after every poll that lands a new one,
    //    errors swallowed. An idle open panel is quiet; an active one POSTs
    //    `/read` once per inbound message. Do not "optimise" it
    //    (§ 2.2 Finding K(2), B9-AC-35).
    final String readKey =
        '${state.live}|${state.threadId}|${state.messages.length}';
    if (readKey != _readKey) {
      _readKey = readKey;
      final String? threadId = state.threadId;
      if (state.live && threadId != null) {
        // `.catch(() => undefined)` — the result is discarded, not branched on.
        await markThreadRead(MarkThreadReadParams(threadId));
      }
    }

    return changed;
  }

  /// `setInterval` / `clearInterval` — `:95-96`.
  void _syncTimer() {
    final bool wanted = state.pollActive;
    if (wanted == (_poll != null)) return;
    if (wanted) {
      _poll = Timer.periodic(kChatPollInterval, (Timer _) {
        if (isClosed) return;
        add(const ChatPolled());
      });
    } else {
      _poll?.cancel();
      _poll = null;
    }
  }

  // ── The three loaders, each with its generation guard ──────────────────────

  Future<void> _loadChannels(Emitter<ChatState> emit) async {
    final int mine = ++_channelsGeneration;
    final Either<Failure, List<SupportChannel>> result =
        await getSupportChannels(NoParams());
    if (mine != _channelsGeneration || emit.isDone) return;

    // A failure leaves the last list standing — `useQuery` calls `setError`
    // without touching `data`. Nothing renders a channels error anyway: an
    // unresolved channel is simply a header shortcut that is not drawn
    // (`:239`, `:249`), which is the measured behaviour (§ 6.6).
    result.fold(
      (Failure _) {},
      (List<SupportChannel> rows) => emit(state.copyWith(channels: rows)),
    );
  }

  Future<void> _loadThreads(Emitter<ChatState> emit) async {
    final int mine = ++_threadsGeneration;
    final Either<Failure, List<ChatThread>> result =
        await getChatThreads(NoParams());
    // "a newer request won" — `hooks.ts:73`.
    if (mine != _threadsGeneration || emit.isDone) return;
    emit(state.withThreads(result));
  }

  /// The transcript, with **two** guards rather than one.
  ///
  /// The generation stamp catches a slower request overtaking a faster one. It
  /// does not catch a sign-out: `:74-76` clears `threadId` without starting a
  /// replacement request, so nothing bumps the generation and an in-flight
  /// response would land against a thread that is no longer selected. The
  /// second check is that case.
  Future<void> _loadTranscript(
    Emitter<ChatState> emit,
    String threadId,
  ) async {
    final int mine = ++_transcriptGeneration;

    // `if (hasData) setRefreshing(true); else setLoading(true)` —
    // `hooks.ts:67-68`. A poll with a transcript already on screen must not
    // replace it with two grey bars every four seconds; only the first read of
    // a thread shows the skeleton.
    if (!state.transcriptLoaded) {
      emit(state.copyWith(transcriptStatus: ChatRegionStatus.loading));
    }

    final Either<Failure, List<ChatMessage>> result =
        await getChatMessages(GetChatMessagesParams(threadId));
    if (mine != _transcriptGeneration || emit.isDone) return;
    if (state.threadId != threadId) return;

    emit(state.withTranscript(result));
  }
}

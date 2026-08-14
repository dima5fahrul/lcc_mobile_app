part of 'chat_bloc.dart';

/// One region's position in the four-state contract (SSD § 7.3). Same four
/// members as `HelpState`'s and `NotificationsState`'s, declared per feature
/// because Cross-Feature Isolation forbids importing another feature's
/// `presentation/` (SSD § 4.3, G-L3).
///
/// `initial` is distinct from `loading` for the same reason it is there: "the
/// panel has never been opened" and "we asked and are waiting" are different
/// screens.
enum ChatRegionStatus { initial, loading, success, failure }

/// Every piece of `CustomerServiceChat`'s state, and nothing else.
///
/// The React component holds seven `useState`s, one `useRef<Set<string>>` and
/// four query results. All twelve are here, because all twelve are either
/// rendered or gate something that is — and because the `ended` set in
/// particular **must not** be a `static` or a module-level variable: it would
/// leak across tests and, on a shared device, across citizens (§ 6.9(3),
/// B9-AC-15).
@freezed
abstract class ChatState with _$ChatState {
  const factory ChatState({
    /// The `isAuthenticated` prop — `:30`.
    @Default(false) bool isAuthenticated,

    /// `const [open, setOpen] = useState(false)` — `:32`.
    @Default(false) bool open,

    /// `:33`. Minimised means the panel is on screen at 64 px showing only its
    /// header; it is **not** closed, and the distinction is what makes [live]
    /// four conditions rather than three.
    @Default(false) bool minimized,

    /// `:34`. Null means "no conversation yet"; the next message starts one.
    String? threadId,

    /// `:35` — the composer's contents. See [ChatInputChanged].
    @Default('') String input,

    /// `:36` — the optimistic bubble's text while a send is in flight
    /// (`:411-428`). Cleared in the `finally`, so it disappears on success and
    /// on failure alike; on failure [input] gets the text back instead
    /// (§ 6.9(4)).
    String? pendingText,

    /// `:37` — whether the rate-and-close strip is showing. Not the rating
    /// itself: the stars are tapped, not held.
    @Default(false) bool ratingOpen,

    /// `threads.data ?? []` — `:67`.
    @Default(<ChatThread>[]) List<ChatThread> threads,
    @Default(ChatRegionStatus.initial) ChatRegionStatus threadsStatus,

    /// `transcript.data?.data ?? []` — `:89`, **before** the `threadId` guard.
    /// Read through [messages], never directly.
    @Default(<ChatMessage>[]) List<ChatMessage> transcript,
    @Default(ChatRegionStatus.initial) ChatRegionStatus transcriptStatus,

    /// `hasData` — `hooks.ts:56`. True once a transcript request has
    /// **succeeded**, and never false again. It is what distinguishes the first
    /// open (spinner) from a poll (no spinner) — `:317`'s
    /// `transcript.loading && messages.length === 0`.
    @Default(false) bool transcriptLoaded,

    /// `channels.data ?? []` — `:51`. Fetched only while the panel is open
    /// (`enabled: open`, `:48`).
    ///
    /// **No status field.** The source renders neither a loading nor an error
    /// state for it: an unresolved channel simply means no button (`:239`,
    /// `:249`). A status nothing can render would be state a test could assert
    /// and a citizen could never see.
    @Default(<SupportChannel>[]) List<SupportChannel> channels,

    /// `start.pending` — `:115`.
    @Default(false) bool startPending,

    /// `sendOne.pending` — `:115`.
    @Default(false) bool sendPending,

    /// `closeThread.pending` — `:476`, which disables the stars mid-close.
    @Default(false) bool closePending,

    /// `const ended = useRef<Set<string>>(new Set())` — `:61`.
    ///
    /// Threads closed in this session. The id is added **before** the close
    /// call (`:155`) so *"a stale list cannot re-adopt one between the close
    /// call and the next poll"* (`:59-60`). BLoC state, not a `static`
    /// (§ 6.9(3), B9-AC-20).
    @Default(<String>{}) Set<String> ended,
  }) = _ChatState;

  const ChatState._();

  // ── The four-condition gate ────────────────────────────────────────────────

  /// `const live = open && !minimized && isAuthenticated` — `:42`.
  bool get live => open && !minimized && isAuthenticated;

  /// The poll's guard — `if (!live || !threadId) return;` (`:94`).
  ///
  /// **Four conditions, not one.** A poll that runs while minimised, or with no
  /// thread, is a divergence no fidelity tier can see (§ 6.2). B9-AC-17 asserts
  /// the timer exists here and does not exist in each of the four negations.
  bool get pollActive => live && threadId != null;

  /// `const isTyping = start.pending || sendOne.pending` — `:115`.
  ///
  /// Both, not one: a first message goes through `start` and every later one
  /// through `sendOne`, and the typing indicator and the send guard have to
  /// cover both.
  bool get isTyping => startPending || sendPending;

  // ── Derived views ──────────────────────────────────────────────────────────

  /// `const messages = threadId ? (transcript.data?.data ?? []) : []` — `:89`.
  ///
  /// The guard is the source's and it is commented there: *"a closed thread
  /// leaves its last transcript in the query cache, and that must not linger
  /// behind a fresh conversation"* (`:87-88`).
  List<ChatMessage> get messages =>
      threadId == null ? const <ChatMessage>[] : transcript;

  /// `:65-71` — the conversation to continue.
  ///
  /// The first `open` or `pending` thread that was not closed in this session.
  /// A `resolved` or `closed` one is left alone and the next message opens a
  /// fresh thread (`:63-64`).
  ChatThread? get activeThread {
    for (final ChatThread thread in threads) {
      if (thread.isActive && !ended.contains(thread.id)) return thread;
    }
    return null;
  }

  /// `threads.data?.find(th => th.id === threadId)?.assigned_name` — `:182`.
  ///
  /// Null while a bot is answering. It selects the header title (`:217`) and it
  /// **suppresses the suggestion chips** (`:190-191`).
  String? get agentName {
    if (threadId == null) return null;
    for (final ChatThread thread in threads) {
      if (thread.id == threadId) return thread.assignedName;
    }
    return null;
  }

  /// `const unread = live ? 0 : Σ th.unread_citizen` — `:127`.
  ///
  /// Forced to zero while the panel is live, because a citizen looking at the
  /// transcript has by definition read it. A **numeric red badge**, and
  /// deliberately not the same idiom as the notification bell's numberless
  /// amber dot — two idioms for two different numbers in one shell, and § 2.2
  /// Finding B rules that they must not be unified.
  int get unread {
    if (live) return 0;
    int total = 0;
    for (final ChatThread thread in threads) {
      total += thread.unreadCitizen;
    }
    return total;
  }

  /// `channelValue(kind)` — `:50-51`. `""` when the channel is not published.
  String channelValue(String kind) {
    for (final SupportChannel channel in channels) {
      if (channel.kind == kind) return channel.value;
    }
    return '';
  }

  /// `channelValue("phone") || channelValue("hotline")` — `:52`. The fallback
  /// order is the source's and B9-AC-43 gates it.
  String get supportPhone {
    final String phone = channelValue('phone');
    return phone.isNotEmpty ? phone : channelValue('hotline');
  }

  /// `channelValue("email")` — `:53`.
  String get supportEmail => channelValue('email');

  // ── The transcript's four states, in `:317-337`'s own order ────────────────

  /// `transcript.loading && messages.length === 0` — `:317`.
  ///
  /// **`initial` does NOT count, and that is measured rather than assumed.**
  /// `hooks.ts:46` is `useState(enabled)` — the initial `loading` value is the
  /// query's initial *enabled* value, and the transcript's is
  /// `Boolean(threadId) && isAuthenticated`, which is **false** on the first
  /// render because no thread has been adopted yet. `hooks.ts:58-61` then
  /// re-asserts it: a disabled query calls `setLoading(false)` and returns.
  ///
  /// So a signed-in citizen who has just opened the panel sees the assistant's
  /// **greeting**, not a skeleton, for the window before the threads list
  /// lands — and `NotificationsState.listLoading`'s opposite disposition is
  /// correct for the bell and wrong here, because the bell's query is enabled
  /// the moment its menu opens and this one is not.
  ///
  /// The `messages.length === 0` half is what stops a poll from replacing a
  /// visible transcript with two grey bars every four seconds.
  bool get transcriptLoading =>
      transcriptStatus == ChatRegionStatus.loading && messages.isEmpty;

  /// `transcript.error` — `:326`. Checked after loading and before the rows.
  bool get transcriptFailed => transcriptStatus == ChatRegionStatus.failure;

  /// `messages.length === 0` — `:340`, reached only past loading and error.
  /// The assistant's greeting bubble, not an empty state.
  bool get showsGreeting => messages.isEmpty;

  // ── The composer ───────────────────────────────────────────────────────────

  /// `disabled={!input.trim() || isTyping}` — `:529`.
  ///
  /// Both guards, and they are **not** the same as `sendMessage`'s own
  /// `if (!body || !isAuthenticated || isTyping) return` (`:131`). The source
  /// carries both; a chip tap (`:499`) bypasses the button entirely, so the
  /// handler-side guard is the one that must hold (§ 6.9(5)).
  bool get canSend => input.trim().isNotEmpty && !isTyping;

  /// The chips — `:187-192`.
  ///
  /// The opening quick replies until the citizen writes, then whatever the bot
  /// suggested with its **latest** reply. Once an agent is on the thread the API
  /// stops suggesting and so does the UI.
  ///
  /// Returns null for the opening case, because those four are i18n keys the
  /// widget must translate and the API's are literal strings. Collapsing the two
  /// into one `List<String>` here would mean either translating in the BLoC or
  /// shipping raw keys to the API.
  List<String>? get botSuggestions {
    if (messages.isEmpty) return null;
    if (agentName != null) return const <String>[];
    return messages.last.suggestions ?? const <String>[];
  }

  // ── Folding ────────────────────────────────────────────────────────────────

  /// Folds a threads response in.
  ///
  /// A failure keeps the rows, because `useQuery` calls `setError` without
  /// touching `data` (`hooks.ts:74-79`). Nothing renders a threads error — the
  /// list feeds only the badge, the active-thread pick and the agent name — so
  /// discarding them would blank the badge on one flaky poll, which the source
  /// does not do.
  ChatState withThreads(Either<Failure, List<ChatThread>> response) =>
      response.fold(
        (Failure _) => copyWith(threadsStatus: ChatRegionStatus.failure),
        (List<ChatThread> rows) => copyWith(
          threadsStatus: ChatRegionStatus.success,
          threads: rows,
        ),
      );

  /// Folds a transcript response in. Same disposition, and here the error
  /// **is** rendered (`:326-336`).
  ChatState withTranscript(Either<Failure, List<ChatMessage>> response) =>
      response.fold(
        (Failure _) => copyWith(transcriptStatus: ChatRegionStatus.failure),
        (List<ChatMessage> rows) => copyWith(
          transcriptStatus: ChatRegionStatus.success,
          transcriptLoaded: true,
          transcript: rows,
        ),
      );
}

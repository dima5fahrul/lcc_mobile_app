part of 'chat_bloc.dart';

/// Ten events, each one a named interaction in `CustomerServiceChat.tsx`.
/// Plain sealed classes, matching `notifications_event.dart` and
/// `help_event.dart`; only the *state* is freezed.
sealed class ChatEvent {
  const ChatEvent();
}

/// The `isAuthenticated` prop changed — `:30`, and a dependency of three of the
/// component's six effects.
///
/// Dispatched by `ChatLauncher` on mount and on every `SessionBloc` transition,
/// the same shape `NotificationBell` uses. The handler is a no-op when the flag
/// has not actually moved, so a rebuild for an unrelated reason cannot issue a
/// second round of requests.
final class ChatAuthChanged extends ChatEvent {
  const ChatAuthChanged(this.isAuthenticated);

  final bool isAuthenticated;
}

/// The launcher FAB was tapped — `handleOpen`, `:166-169`:
/// `setOpen(true); setMinimized(false)`. **Both**, so a panel minimised and
/// then closed reopens expanded.
final class ChatOpened extends ChatEvent {
  const ChatOpened();
}

/// The header's ✕ — `setOpen(false)`, `:271`.
///
/// Note what it does *not* do: it does not clear `threadId`, `minimized` or the
/// transcript. Reopening resumes the same conversation.
final class ChatDismissed extends ChatEvent {
  const ChatDismissed();
}

/// The header's chevron — `setMinimized(m => !m)`, `:260`.
final class ChatMinimizeToggled extends ChatEvent {
  const ChatMinimizeToggled();
}

/// Every keystroke in the composer — `onChange={e => setInput(e.target.value)}`
/// (`:522`).
///
/// A controlled input on the web, so a controlled input here: the send button's
/// disabled state is `!input.trim() || isTyping` (`:529`) and the failure branch
/// writes the text back (`:147`), neither of which a widget-local controller
/// could express to a test.
final class ChatInputChanged extends ChatEvent {
  const ChatInputChanged(this.value);

  final String value;
}

/// `sendMessage(raw)` — `:129`. Dispatched by the send button (`:528`), by
/// Enter (`:523`) and by a suggestion chip (`:499`).
///
/// Carries the raw text because the trim is the source's first statement
/// (`:130`) and B9-AC-25 gates that it precedes the truncation.
final class ChatMessageSubmitted extends ChatEvent {
  const ChatMessageSubmitted(this.raw);

  final String raw;
}

/// The header's ✓✓ — `setRating(true)`, `:224`. Shows the rating strip; the
/// thread is still open at this point.
final class ChatRatingRequested extends ChatEvent {
  const ChatRatingRequested();
}

/// "Not now" — `setRating(false)`, `:485`. Dismisses the strip **without**
/// closing the thread, which is why `endChat` is not reachable with `rating: 0`.
final class ChatRatingDismissed extends ChatEvent {
  const ChatRatingDismissed();
}

/// A star was tapped — `endChat(n)`, `:475`. 1-5.
final class ChatRated extends ChatEvent {
  const ChatRated(this.stars);

  final int stars;
}

/// The transcript error branch's retry — `transcript.refetch()`, `:330`.
final class ChatTranscriptRetried extends ChatEvent {
  const ChatTranscriptRetried();
}

/// One turn of the 4,000 ms poll — `setTick(n => n + 1)`, `:95`.
///
/// **Only the timer dispatches this.** `tick` is a dependency of *both* the
/// threads query (`:55`) and the transcript query (`:83`), so one tick refetches
/// both — which is why the launcher badge and the transcript stay in step.
final class ChatPolled extends ChatEvent {
  const ChatPolled();
}

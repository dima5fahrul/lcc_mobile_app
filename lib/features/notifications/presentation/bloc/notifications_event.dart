part of 'notifications_bloc.dart';

/// Six events, each one a named interaction in `Layout.tsx`'s
/// `NotificationMenu` (`:96-296`). Plain sealed classes, matching
/// `help_event.dart` and `home_event.dart`; only the *state* is freezed.
sealed class NotificationsEvent {
  const NotificationsEvent();
}

/// The `isAuthenticated` prop changed — `Layout.tsx:114`'s dependency list.
///
/// Dispatched by `NotificationBell` on mount and on every `SessionBloc`
/// transition. The handler is a no-op when the flag has not actually moved, so
/// a rebuild for an unrelated reason cannot issue a second count request and
/// quietly turn the bell into a poller.
final class NotificationsAuthChanged extends NotificationsEvent {
  const NotificationsAuthChanged(this.isAuthenticated);

  final bool isAuthenticated;
}

/// The bell was tapped — `setOpen((v) => !v)`, `Layout.tsx:165`.
final class NotificationsMenuToggled extends NotificationsEvent {
  const NotificationsMenuToggled();
}

/// The menu was dismissed by an outside tap or Escape —
/// `Layout.tsx:146-160`'s `mousedown` / `keydown` listeners.
final class NotificationsMenuDismissed extends NotificationsEvent {
  const NotificationsMenuDismissed();
}

/// The error branch's retry — `inbox.refetch()`, `Layout.tsx:234`.
final class NotificationsListRetried extends NotificationsEvent {
  const NotificationsListRetried();
}

/// A row was tapped — `openNotification(it)`, `Layout.tsx:262`.
///
/// Carries the whole entity rather than an id because the handler branches on
/// `read_at` (`:133`) and the widget has the row in hand anyway.
final class NotificationOpened extends NotificationsEvent {
  const NotificationOpened(this.item);

  final CitizenNotification item;
}

/// The header's "Mark all as read" — `Layout.tsx:192`.
final class NotificationsMarkAllRead extends NotificationsEvent {
  const NotificationsMarkAllRead();
}

part of 'account_preferences_bloc.dart';

/// Which of the three notification switches was moved.
///
/// An enum rather than the raw wire key (`"in_app"` / `"email"` / `"sms"`),
/// because a string key travelling from a widget to a merge function is a
/// typo away from a silent no-op — the merge would leave every field
/// unchanged and the `PUT` would look successful. The wire names live in
/// `account_wire.dart` and nowhere else (CFI).
enum NotificationChannel { inApp, email, sms }

sealed class AccountPreferencesEvent {
  const AccountPreferencesEvent();
}

/// `useQuery(me.preferences, [])` on mount — `AccountPage.tsx:191`.
final class AccountPreferencesRequested extends AccountPreferencesEvent {
  const AccountPreferencesRequested();
}

/// `prefsQuery.refetch()` — the panel's retry button, `AccountPage.tsx:576`.
final class AccountPreferencesRetried extends AccountPreferencesEvent {
  const AccountPreferencesRetried();
}

/// `updatePrefs({ notifications: { ...prefs.notifications, [key]: next } })` —
/// `AccountPage.tsx:594`.
final class AccountNotificationToggled extends AccountPreferencesEvent {
  const AccountNotificationToggled(this.channel, {required this.enabled});

  final NotificationChannel channel;
  final bool enabled;
}

/// `updatePrefs({ biometric_login: next })` — `AccountPage.tsx:668`.
final class AccountBiometricToggled extends AccountPreferencesEvent {
  const AccountBiometricToggled({required this.enabled});

  final bool enabled;
}

/// `updatePrefs({ language: code })` — `AccountPage.tsx:622`. R-25's second
/// mirror; see the handler's comment.
final class AccountLanguageSelected extends AccountPreferencesEvent {
  const AccountLanguageSelected(this.code);

  /// `"lo"` or `"en"` — `AccountPage.tsx:615`'s tuple.
  final String code;
}

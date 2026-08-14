/// `CitizenPreferences` — `GET` / `PUT /me/preferences`.
///
/// Ported verbatim from `lcc-app/src/app/api/types.ts:335-339`:
///
/// ```ts
/// export interface CitizenPreferences {
///   language: Lang;
///   notifications: { in_app: boolean; email: boolean; sms: boolean };
///   biometric_login: boolean;
/// }
/// ```
///
/// ## `notifications` is a value object, NOT a flattened trio
///
/// specs.md § 5 rules this and it is not stylistic. `updatePrefs`
/// (`AccountPage.tsx:252-256`) merges the nested object **separately** from the
/// outer one:
///
/// ```tsx
/// const next = { ...prefs, ...patch,
///   notifications: { ...prefs.notifications, ...(patch.notifications ?? {}) } };
/// ```
///
/// and the endpoint is a **`PUT`** (`endpoints.ts:123`), so the whole shape
/// goes back every time. Flattening the three booleans onto this class would
/// make a shallow `copyWith` look correct while dropping the two untouched
/// values — server-side, invisibly, because the UI refetches and redraws what
/// it just reset. B8-AC-33 is the gate; [merge] below is the ported transform.
///
/// ## `language` is a plain `String`
///
/// The TS type is `Lang` (`"en" | "lo"`), but the value arrives from the server
/// and the app must not crash on a third one. `lib/i18n/i18n.dart`'s `Lang`
/// enum is the *reader's* language, chosen locally; this is what the account
/// record says. They are compared, never conflated — see `LanguagePanel`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'citizen_preferences.freezed.dart';

/// The nested `notifications` object — `types.ts:337`.
@freezed
abstract class NotificationPreferences with _$NotificationPreferences {
  const factory NotificationPreferences({
    required bool inApp,
    required bool email,
    required bool sms,
  }) = _NotificationPreferences;
}

@freezed
abstract class CitizenPreferences with _$CitizenPreferences {
  const factory CitizenPreferences({
    required String language,
    required NotificationPreferences notifications,
    required bool biometricLogin,
  }) = _CitizenPreferences;

  const CitizenPreferences._();

  /// `updatePrefs`'s two-level spread — `AccountPage.tsx:252-256`.
  ///
  /// Every parameter is nullable and "not supplied" means "keep what `prefs`
  /// has", which is what a JavaScript spread of an absent key does. The three
  /// notification booleans are supplied **individually**, not as a
  /// [NotificationPreferences], because that is how the three call sites use
  /// it (`:594` sets one key, `:622` sets `language`, `:668` sets
  /// `biometric_login`) — and because a caller handing over a whole
  /// [NotificationPreferences] built from somewhere other than `prefs` is the
  /// exact mistake the nested spread exists to prevent.
  CitizenPreferences merge({
    String? language,
    bool? inApp,
    bool? email,
    bool? sms,
    bool? biometricLogin,
  }) =>
      CitizenPreferences(
        language: language ?? this.language,
        // `notifications: { ...prefs.notifications, ...(patch.notifications ?? {}) }`
        // — the SECOND merge. A single `copyWith` on the outer object would
        // replace the whole nested value and lose the two untouched booleans.
        notifications: NotificationPreferences(
          inApp: inApp ?? notifications.inApp,
          email: email ?? notifications.email,
          sms: sms ?? notifications.sms,
        ),
        biometricLogin: biometricLogin ?? this.biometricLogin,
      );
}

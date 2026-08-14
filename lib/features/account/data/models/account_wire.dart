/// The account surface's wire ↔ entity mapping. **The only file in
/// `features/account/` that knows a snake_case field name** (CFI, `ssd.md`
/// § 4.3).
///
/// ## Why the readers below are re-declared rather than imported
///
/// `features/notifications/data/models/notification_wire.dart` and
/// `features/help/data/models/help_wire.dart` already hold byte-identical
/// `stringAt` / `nullableStringAt` / `bilingualAt`. Importing either would be a
/// `features/account → features/<other>/data/**` edge, which CFI forbids and
/// **G-L3 measures and fails**. `ssd.md` § 4.3 names this exact trade in as
/// many words: *"wire-format duplication is the accepted cost"*.
///
/// This is **not** the same call as `text(Bilingual?, Lang)`. That one lives in
/// `lib/i18n/i18n.dart`, which is neither a feature nor `data/`; it is imported
/// by the presentation layer, not re-implemented. Four B2 features
/// re-implemented it locally citing G-L3, which has nothing to say about
/// `lib/i18n/`.
///
/// ## The `PUT` body is here too, and that is the point of § 6.9 leaf 2
///
/// [preferencesBody] is the **whole object**, always — `endpoints.ts:123` is
/// `api.put<CitizenPreferences>("/me/preferences", body)` and `updatePrefs`
/// hands it a fully merged `CitizenPreferences` (`AccountPage.tsx:252-258`).
/// Toggling one notification switch therefore transmits `language`,
/// `biometric_login` and **all three** notification booleans. A port that sent
/// only the changed field would silently reset the other two server-side and
/// the UI would still look right, because it refetches. B8-AC-33.
library;

import '../../../session/domain/entities/bilingual.dart';
import '../../domain/entities/citizen_document.dart';
import '../../domain/entities/citizen_preferences.dart';

// ── Readers ──────────────────────────────────────────────────────────────────

/// A string field, or `''`.
String stringAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  return raw is String ? raw : '';
}

/// A string field, or **null** when absent, not a string, or empty.
///
/// Empty collapses to null here where [nullableStringAt] elsewhere in the tree
/// keeps it, because every consumer of these three fields — `issued_at`,
/// `expires_at`, `file_url` — tests them for JavaScript truthiness, under which
/// `""` and `undefined` behave identically (`AccountPage.tsx:427,451,454`).
/// Preserving a distinction the source cannot observe would invite a caller to
/// branch on it.
String? optionalStringAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is! String || raw.isEmpty) return null;
  return raw;
}

/// A boolean field, or [fallback].
///
/// Tolerates the string forms a PHP/Laravel backend sometimes emits for a
/// boolean column; anything else takes the fallback rather than throwing, for
/// the reason the whole file is defensive — one odd field must cost that field,
/// not the card.
bool boolAt(Map<String, dynamic> json, String key, {bool fallback = false}) {
  final Object? raw = json[key];
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  if (raw is String) {
    if (raw == 'true' || raw == '1') return true;
    if (raw == 'false' || raw == '0') return false;
  }
  return fallback;
}

/// `{en, lo}`, a plain string on both sides, or an empty pair.
///
/// The plain-string branch is carried for the reason `help_wire.dart` records:
/// at least one `/help/*` endpoint was measured sending a bare string where the
/// type says `Bilingual`. **No recording of `/me/documents` exists for any
/// account** (specs.md § 6.5, GG-2), so the tolerant reader is kept rather than
/// narrowed on an assumption.
Bilingual bilingualAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is String) return Bilingual(en: raw, lo: raw);
  if (raw is Map<String, dynamic>) {
    return Bilingual(
      en: raw['en'] is String ? raw['en'] as String : '',
      lo: raw['lo'] is String ? raw['lo'] as String : '',
    );
  }
  return const Bilingual(en: '', lo: '');
}

// ── Entities ─────────────────────────────────────────────────────────────────

/// One row of `GET /me/documents` — `types.ts:343-355`.
CitizenDocument citizenDocumentFrom(Map<String, dynamic> json) =>
    CitizenDocument(
      id: stringAt(json, 'id'),
      type: stringAt(json, 'type'),
      title: bilingualAt(json, 'title'),
      number: stringAt(json, 'number'),
      // Not `json['status'] as String` — an absent status parses to
      // `DocumentStatus.unknown`, which renders as `missing`, which is what the
      // source's final `else` already does (B8-AC-26).
      status: DocumentStatus.parse(stringAt(json, 'status')),
      issuedAt: optionalStringAt(json, 'issued_at'),
      expiresAt: optionalStringAt(json, 'expires_at'),
      authority: stringAt(json, 'authority'),
      available: boolAt(json, 'available'),
      fileUrl: optionalStringAt(json, 'file_url'),
      verifyCode: optionalStringAt(json, 'verify_code'),
    );

/// `GET /me/preferences` — `types.ts:335-339`.
///
/// **Every field has a fallback and none of them is a guess about the
/// citizen.** `language` falls back to `''`, which `LanguagePanel` reads as
/// "the server has no opinion, highlight the locale the reader is already in"
/// — the `prefs?.language ?? lang` at `AccountPage.tsx:616`. The four booleans
/// fall back to `false`, matching what JavaScript renders for an absent key in
/// `checked={prefs.notifications[key]}`.
CitizenPreferences citizenPreferencesFrom(Map<String, dynamic> json) {
  final Object? rawNotifications = json['notifications'];
  final Map<String, dynamic> notifications =
      rawNotifications is Map<String, dynamic>
          ? rawNotifications
          : const <String, dynamic>{};

  return CitizenPreferences(
    language: stringAt(json, 'language'),
    notifications: NotificationPreferences(
      inApp: boolAt(notifications, 'in_app'),
      email: boolAt(notifications, 'email'),
      sms: boolAt(notifications, 'sms'),
    ),
    biometricLogin: boolAt(json, 'biometric_login'),
  );
}

// ── The one request body ─────────────────────────────────────────────────────

/// `PUT /me/preferences`'s body — the **whole** `CitizenPreferences`.
///
/// Key order is `{language, notifications:{in_app, email, sms},
/// biometric_login}`, which is `types.ts:335-339`'s declaration order and
/// therefore the order `JSON.stringify` emits for the object literal
/// `AccountPage.tsx:252-256` builds. Dart `Map` literals preserve insertion
/// order and `jsonEncode` respects it, so writing them in this order gates key
/// order for free (F0 § 6.2.3's disposition, followed by B9b).
///
/// There is no "partial" variant of this function and there must not be: the
/// endpoint is a `PUT`, and the absence of a partial form is what makes
/// B8-AC-33 unfailable by omission.
Map<String, dynamic> preferencesBody(CitizenPreferences preferences) =>
    <String, dynamic>{
      'language': preferences.language,
      'notifications': <String, dynamic>{
        'in_app': preferences.notifications.inApp,
        'email': preferences.notifications.email,
        'sms': preferences.notifications.sms,
      },
      'biometric_login': preferences.biometricLogin,
    };

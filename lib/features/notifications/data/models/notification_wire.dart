/// The notification inbox's wire → entity parsing.
///
/// ## Why the four readers below are re-declared rather than imported
///
/// `features/help/data/models/help_wire.dart` already holds byte-identical
/// `stringAt` / `bilingualAt` helpers. Importing them would be a
/// `features/notifications → features/help/data/**` edge, which Cross-Feature
/// Isolation forbids (SSD § 4.3) and **G-L3 measures and fails**. SSD § 4.3
/// names this exact trade in as many words — *"wire-format duplication is the
/// accepted cost"* — because a shared wire reader welds two features' release
/// cycles to one parsing decision.
///
/// This is **not** the same call as `text(Bilingual?, Lang)`. That one lives in
/// `lib/i18n/i18n.dart`, which is neither a feature nor `data/`; importing it
/// crosses no guard and it is imported, not re-implemented. Four features in
/// B2 re-implemented it locally citing G-L3, and G-L3 has nothing to say about
/// `lib/i18n/`.
///
/// ## The unread count is an object, and that is the batch's one fixture defect
///
/// `endpoints.ts:137` types the endpoint `api.get<{ unread: number }>`. The
/// baseline fixture shipped `"data": []` — an array — and its own provenance
/// note recorded why nobody noticed: *"it feeds no Tier 0 leaf"*, true until
/// this batch deserialised it for real (specs.md § 2.2 Finding H).
/// [unreadCountFrom] therefore reads the object and, like the source's
/// `counter.data?.unread ?? 0` (`Layout.tsx:122`), answers 0 for anything else
/// rather than throwing — a malformed count must cost the badge, not the shell.
library;

import '../../../session/domain/entities/bilingual.dart';
import '../../domain/entities/notification_entities.dart';

/// A string field, or `''`.
String stringAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  return raw is String ? raw : '';
}

/// A string field, or **null** when absent or not a string.
///
/// Distinct from [stringAt] because for `read_at` the difference is the whole
/// meaning: `null` is unread and a timestamp is read (`Layout.tsx:257`).
String? nullableStringAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  return raw is String ? raw : null;
}

/// `{en, lo}`, a plain string on both sides, or an empty pair.
///
/// The plain-string branch is carried for the reason `help_wire.dart` records:
/// § 5 measured at least one `/help/*` endpoint sending a bare string where the
/// type says `Bilingual`. No `/me/notifications` recording exists to confirm or
/// refute the same for this endpoint (specs.md § 2.2 Finding I), so the
/// tolerant reader is kept rather than narrowed on an assumption.
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

/// One row of `GET /me/notifications` — `types.ts:752-767`.
CitizenNotification citizenNotificationFrom(Map<String, dynamic> json) =>
    CitizenNotification(
      id: stringAt(json, 'id'),
      template: nullableStringAt(json, 'template'),
      title: bilingualAt(json, 'title'),
      body: bilingualAt(json, 'body'),
      channel: stringAt(json, 'channel'),
      category: stringAt(json, 'category'),
      severity: stringAt(json, 'severity'),
      refType: nullableStringAt(json, 'ref_type'),
      refId: nullableStringAt(json, 'ref_id'),
      actionUrl: nullableStringAt(json, 'action_url'),
      readAt: nullableStringAt(json, 'read_at'),
      sentAt: stringAt(json, 'sent_at'),
    );

/// The `data` of `GET /me/notifications/unread-count` — `{"unread": <int>}`.
///
/// Accepts a `double` for the reason `help_wire.dart`'s `intAt` does: JSON has
/// one number type, and a backend serialising `3.0` is sending an integer.
int unreadCountFrom(Object? data) {
  if (data is! Map<String, dynamic>) return 0;
  final Object? raw = data['unread'];
  if (raw is int) return raw;
  if (raw is double) return raw.round();
  if (raw is String) return int.tryParse(raw) ?? 0;
  return 0;
}

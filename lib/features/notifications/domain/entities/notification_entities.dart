/// The notification inbox's one entity.
///
/// Port of `types.ts:752-767`'s `Notification`.
///
/// ## Why `CitizenNotification` and not `Notification`
///
/// `Notification` is a class in `package:flutter/widgets.dart` (the base of
/// `NotificationListener`). A domain type of that name would collide in every
/// widget file that renders one, and the usual fix — an import prefix or a
/// `hide` — would put the workaround in the widgets rather than in the name.
/// `Citizen*` is also this tree's existing prefix for a `/me/*` entity
/// (`CitizenProfile`, `CitizenSession`), so this is the house convention
/// rather than a rename to dodge a collision.
///
/// ## The mixed wire shape is the trap (specs.md § 5)
///
/// `title` and `body` arrive as `{en, lo}` and are rendered through
/// `text(it.title, lang)` (`Layout.tsx:269-270`). **Every other field is a
/// plain `String`** — including `severity` and `channel`, which read like
/// enums and are not modelled as one, because the source treats them as opaque
/// strings and never switches on either.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/bilingual.dart';

part 'notification_entities.freezed.dart';

/// One row of `GET /me/notifications`.
@freezed
abstract class CitizenNotification with _$CitizenNotification {
  const factory CitizenNotification({
    @Default('') String id,

    /// `types.ts:754` — optional, and **never rendered**. On the wire, modelled
    /// here, read by nothing.
    String? template,

    /// `types.ts:757` — `{en, lo}`. `Layout.tsx:269`, `text(it.title, lang)`.
    @Default(Bilingual(en: '', lo: '')) Bilingual title,

    /// `types.ts:758` — `{en, lo}`. `Layout.tsx:270`.
    @Default(Bilingual(en: '', lo: '')) Bilingual body,

    /// `types.ts:759`. On the wire, never rendered.
    @Default('') String channel,

    /// `types.ts:760`. **The one field the UI switches on** — it picks the
    /// row's icon, tint and destination tab through `kNotifStyle`
    /// (`Layout.tsx:60-70`, `:131`, `:255`), with `announcement` as the
    /// fallback for anything unrecognised.
    @Default('') String category,

    /// `types.ts:761`. On the wire, never rendered.
    @Default('') String severity,

    /// `types.ts:762-763`. On the wire, never rendered.
    String? refType,
    String? refId,

    /// `types.ts:764` — **on the wire and deliberately not consumed.**
    /// `openNotification` (`Layout.tsx:129-137`) navigates by `category`, never
    /// by `action_url`. Modelled because the field exists; routing by it would
    /// be a behaviour the source does not have (specs.md § 6.15, B9-AC-44).
    String? actionUrl,

    /// `types.ts:765`. **Null means unread** — `const unread = !it.read_at`
    /// (`Layout.tsx:257`), and it is what gates both the row's blue dot
    /// (`:275`) and whether opening the row issues a mark-read POST (`:133`).
    String? readAt,

    /// `types.ts:766`. An ISO timestamp rendered through `relativeTime`
    /// (`Layout.tsx:272`). Kept as the raw `String` the wire sends rather than
    /// a `DateTime`: the source's formatter returns `""` for an unparseable
    /// value instead of throwing (`:76`), and parsing at the edge would move
    /// that decision to a place that cannot express it.
    @Default('') String sentAt,
  }) = _CitizenNotification;

  const CitizenNotification._();

  /// `!it.read_at` — `Layout.tsx:257`. An empty string counts as unread for the
  /// same reason `null` does: neither is a timestamp, and JavaScript's `!`
  /// treats them identically.
  bool get isUnread => readAt == null || readAt!.isEmpty;
}

/// `CaseEvent` — one entry in a case's trail of who did what.
///
/// Ported field-for-field from `lcc-app/src/app/api/types.ts:462-474`
/// (**11 fields, 7 of them optional**).
///
/// ## `to_status` is required and `status_label` is not — and that asymmetry
/// is what the render depends on
///
/// `HistoryDetailPage.tsx:572` is `text(event.status_label, lang) || event.to_status`:
/// the human label when the API sends one, **the raw wire status otherwise**
/// (`B7-AC-66`). `text()` returns `""` for an absent `Bilingual`
/// (`i18n.dart:90`, the port of `types.ts:17-22`), and `||` on `""` is falsy,
/// so the fallback is reached by emptiness rather than by null. [labelOr]
/// reproduces exactly that and is why [statusLabel] is nullable here rather
/// than defaulted to an empty pair.
///
/// The raw status is rendered as its **wire** spelling — `under-review`, not
/// `underReview` — because that is the string the web prints. [CaseStatus.wire]
/// is the only place that mapping lives.
///
/// ## `bucketOf(event.to_status)` decides the row's whole treatment
///
/// `:544` — an event landing in the rejected bucket renders the red `XCircle`
/// dot **and breaks the green connector** (`B7-AC-64`). That is a pure function
/// of `to_status`, so it is on the entity rather than in the timeline widget.
///
/// ## Not modelled: `from_status`, `actor_id`, `actor_role`, `reason_code`
///
/// They are parsed — `application_row.dart`'s every-field-the-wire-carries rule
/// — but no current surface draws them. `from_status` in particular is a
/// [CaseStatus] the web never reads; carrying it costs one parse and saves B4
/// from discovering a half-modelled event.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/bilingual.dart';
import 'case_status.dart';

part 'case_event.freezed.dart';

@freezed
abstract class CaseEvent with _$CaseEvent {
  const factory CaseEvent({
    required String id,
    required String action,
    CaseStatus? fromStatus,
    required CaseStatus toStatus,

    /// Nullable, and the nullability is rendered — see the library doc.
    Bilingual? statusLabel,
    String? actorId,
    String? actorName,
    String? actorRole,
    String? reasonCode,
    String? note,
    required String occurredAt,
  }) = _CaseEvent;

  const CaseEvent._();

  /// `bucketOf(event.to_status) === "rejected"` — `HistoryDetailPage.tsx:544`.
  bool get isError => bucketOf(toStatus) == StatusBucket.rejected;

  /// `text(event.status_label, lang) || event.to_status` — `:572`.
  ///
  /// [resolvedLabel] is the already-localised label the caller read out of
  /// [statusLabel]; passing it in keeps `Lang` and the frozen `text()` helper
  /// in the presentation layer where they belong, while the **fallback rule**
  /// stays here where it can be tested without a widget.
  String labelOr(String resolvedLabel) =>
      resolvedLabel.isNotEmpty ? resolvedLabel : toStatus.wire;

  /// `[event.actor_name, event.note].filter(Boolean).join(" · ")` — `:577`.
  ///
  /// Empty when both are absent, in which case `:575`'s guard means the line
  /// does not render at all (`B7-AC-67`). Falsy-on-empty again: an
  /// `actor_name: ""` contributes nothing rather than a leading separator.
  String get actorAndNote {
    final List<String> parts = <String>[
      if (actorName != null && actorName!.isNotEmpty) actorName!,
      if (note != null && note!.isNotEmpty) note!,
    ];
    return parts.join(' · ');
  }
}

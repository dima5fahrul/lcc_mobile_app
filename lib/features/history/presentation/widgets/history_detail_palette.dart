/// `STATUS_THEME` and the timeline's colours — `HistoryDetailPage.tsx:111-133`,
/// `:544-547`.
///
/// ## This is a *different* table from `history_palette.dart`'s, and the
/// difference is one value
///
/// The list has `STATUS_CONFIG` (`HistoryPage.tsx:42-46`) — `{bg, text, ring,
/// icon}`. The detail has `STATUS_THEME` — `{color, bg, headlineKey, subKey,
/// icon}`. They agree on `bg` for all three buckets and on `color`/`text` for
/// two of them, and they **disagree on approved**: the list's chip text is
/// `#15803D` (green-700, [AppColors.success]) and the detail's hero is
/// `#16A34A` (green-600, [AppColors.categoryAccentFinance]).
///
/// One shared table would have to pick one, and picking either is a silent Tier
/// 2 miss on the other page. Two tables, therefore, with this paragraph so the
/// next reader does not "fix" the duplication. `B7-AC-55` reads the detail's
/// values; `tier2_history_test.dart` already reads the list's.
///
/// `ring` has **no counterpart here** — `STATUS_THEME` has no such field. See
/// `history_palette.dart`'s note on why the list's is carried and not rendered.
///
/// ## Two icon divergences, recorded rather than absorbed
///
/// `assets/icons/**` is out of B7's scope (§ 4.1) and B7 may not add an SVG.
/// Of the source's two hero glyphs, `Clock` is in the shipped lucide set and
/// two are not:
///
/// * **`CheckCircle2` → lucide `CheckCircle`.** Lucide ships both; only the
///   first is in `assets/icons/lucide/`. They are the same check-in-a-circle at
///   different stroke weights.
/// * **`XCircle` → Material `cancel_outlined`.** No lucide X-in-a-circle is
///   present. This is `history_palette.dart`'s disposition for the same glyph on
///   the list, and `chat_panel.dart`'s for its six.
///
/// Both are invisible to Tier 1 (text) and Tier 2 (tokens), which is exactly the
/// class of gap § 8.5 exists to catch, so they are written down here.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../application/domain/entities/case_status.dart';
import 'history_labels.dart';

/// One bucket's hero theme — `{color, bg, headlineKey, subKey}`.
///
/// The icon is **not** a field: two of the three cannot be named as a lucide
/// asset (see the library doc), so the glyph is resolved by
/// [historyDetailHeroIcon] rather than carried as a string that would be a lie
/// for `rejected`.
class HistoryDetailTheme {
  const HistoryDetailTheme({
    required this.color,
    required this.background,
    required this.headlineKey,
    required this.subKey,
  });

  final Color color;
  final Color background;

  /// The i18n key, not the resolved string — the widget resolves it with the
  /// page's `BuildContext` so the language toggle can see it (§ 6.11).
  final String headlineKey;
  final String subKey;
}

/// `approved: {color #16A34A, bg #DCFCE7, approvedHeadline, approvedSub}`.
const HistoryDetailTheme kDetailThemeApproved = HistoryDetailTheme(
  color: AppColors.categoryAccentFinance, // #16A34A — green-600, NOT the
  // list chip's #15803D. See the library doc.
  background: AppColors.categoryTintFinance, // #DCFCE7
  headlineKey: '$kHistoryNs.approvedHeadline',
  subKey: '$kHistoryNs.approvedSub',
);

/// `rejected: {color #DC2626, bg #FEE2E2, rejectedHeadline, rejectedSub}`.
const HistoryDetailTheme kDetailThemeRejected = HistoryDetailTheme(
  color: AppColors.danger, // #DC2626
  background: AppColors.categoryTintHealth, // #FEE2E2
  headlineKey: '$kHistoryNs.rejectedHeadline',
  subKey: '$kHistoryNs.rejectedSub',
);

/// `pending: {color #D97706, bg #FEF3C7, pendingHeadline, pendingSub}`.
const HistoryDetailTheme kDetailThemePending = HistoryDetailTheme(
  color: AppColors.warningLink, // #D97706
  background: AppColors.categoryTintTransport, // #FEF3C7
  headlineKey: '$kHistoryNs.pendingHeadline',
  subKey: '$kHistoryNs.pendingSub',
);

/// `STATUS_THEME[bucket]` — `:243`.
HistoryDetailTheme historyDetailThemeFor(StatusBucket bucket) {
  switch (bucket) {
    case StatusBucket.approved:
      return kDetailThemeApproved;
    case StatusBucket.rejected:
      return kDetailThemeRejected;
    case StatusBucket.pending:
      return kDetailThemePending;
  }
}

/// The hero glyph — `theme.icon` (`:244`).
///
/// Returns a lucide **asset name** where one exists and `null` where the
/// caller must fall back to [kDetailRejectedFallbackIcon]. A `String?` rather
/// than two parallel maps so a bucket cannot be present in one and missing from
/// the other.
const Map<StatusBucket, String> kDetailHeroLucideIcon = <StatusBucket, String>{
  StatusBucket.approved: 'CheckCircle', // source: CheckCircle2
  StatusBucket.pending: 'Clock',
};

/// Material's stand-in for the absent `XCircle.svg`, used by the hero and by
/// every rejected timeline dot.
const IconData kDetailRejectedFallbackIcon = Icons.cancel_outlined;

/// Material's stand-in for the absent `MessageSquare.svg` (`:418`).
///
/// Lucide ships `MessageCircle` in this repo's set and it is the same glyph
/// family one corner-radius apart, so it is preferred to a Material
/// substitution — recorded because it is still not the source's asset.
const String kDetailContactOfficerIcon = 'MessageCircle';

/// Material's stand-in for the absent `Paperclip.svg` (`:591`). No lucide
/// analog is present in the shipped set.
const IconData kDetailAttachmentsIcon = Icons.attach_file;

// ── The timeline — `HistoryDetailPage.tsx:544-570` ───────────────────────────

/// `dotColor = isError ? "#DC2626" : "#16A34A"` — `:546`.
const Color kTimelineDotError = AppColors.danger;
const Color kTimelineDotOk = AppColors.categoryAccentFinance;

/// `lineColor = isError ? "#E5E7EB" : "#16A34A"` — `:547`.
///
/// **The error line is grey, not red**, and that is the whole point of the
/// field: a rejected event *breaks* the green connector rather than continuing
/// it in another colour (`B7-AC-64`). A reader expecting symmetry with
/// [kTimelineDotError] would write `danger` here and the rendered trail would
/// still look plausible.
const Color kTimelineLineError = AppColors.gray200; // #E5E7EB
const Color kTimelineLineOk = AppColors.categoryAccentFinance; // #16A34A

/// The dot's own fill — `backgroundColor: isError ? "#FEE2E2" : "#DCFCE7"`
/// (`:557`).
const Color kTimelineDotBgError = AppColors.categoryTintHealth;
const Color kTimelineDotBgOk = AppColors.categoryTintFinance;

/// `boxShadow: 0 0 0 4px rgba(52,78,173,0.15)` — `:558`, the current-event ring.
const Color kTimelineCurrentRing = AppColors.primary;
const double kTimelineCurrentRingOpacity = 0.15;
const double kTimelineCurrentRingWidth = 4;

/// The event's label colour — `isError ? "#DC2626" : "#1F2937"` (`:570`).
const Color kTimelineTextError = AppColors.danger;
const Color kTimelineTextOk = AppColors.gray800;

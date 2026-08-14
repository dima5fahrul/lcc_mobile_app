/// The literal colours `HistoryPage.tsx` writes as inline `style={{}}` values.
///
/// **Tier 2 sees these.** Unlike B9's two Tailwind classes, every colour on
/// this surface is an inline hex in the component, so design-token parity is
/// fully binding for the list (specs.md § 6.10) and
/// `test/features/history/fidelity/tier2_history_test.dart` reads them back out
/// of the pinned TSX rather than out of a transcription.
///
/// ## Every value here is an `AppColors` reference — and the claim that they
/// could not be was false (B7a)
///
/// This file used to say the status palettes and tile pairs *"have no
/// `AppColors` entry and … B7 may not add one for"* them, and on that basis
/// wrote fifteen `Color(0xFF……)` literals. Both halves were wrong, and the
/// first half was checkable: of the fifteen distinct values, **fourteen already
/// had a named token** with the identical value. They were duplication, and the
/// justification for it did not survive a `grep`. `color_literal_test.dart`
/// (`B2-AC-11`) is the mechanism that caught it, which is what it is for.
///
/// The fifteenth, `#86EFAC` (`STATUS_CONFIG.approved.ring`), genuinely had no
/// entry. It is now `AppColors.successRing`, appended under B7's § 3.1
/// operation-A scope row for `app_colors.dart` — the same row B10 § 3.1 line
/// 284 carries and B6a was granted for five tokens. `B7-AC-12`'s freeze on
/// `lib/presentation/**` is what made this look like an unresolvable conflict
/// with `B2-AC-11`; the append-only grant is the resolution, and fourteen of
/// the fifteen never needed it.
///
/// **Six of the fourteen reference a token named for another surface** —
/// `categoryTintFinance`, `categoryTintHealth`, `categoryTintTransport`,
/// `categoryAccentFinance`, `warningLink`, `tutorialSearchOutline`. That
/// coupling is real and it is deliberate: `wallet_quick_actions.dart:100-152`
/// (B6a) and `notif_style.dart:107-116` (B9a) already read those same
/// `categoryTint*` washes for these same three values, so a history-local
/// synonym would be a fourth name for one colour — the mistake
/// `AppColors.categoryAccentFallback`'s own doc apologises for. If those
/// values should ever diverge per surface, the split belongs in `AppColors`,
/// not here.
///
/// The header gradient's three stops were already imported rather than
/// restated (`AppColors.primary` `#344EAD`, `.headerGradientMid` `#2A3F99`,
/// `.headerGradientEnd` `#1E3070`) and are unchanged.
///
/// ## The catalogue's own colours are ignored, deliberately (§ 6.9)
///
/// `GET /status-catalogue` carries a `color` and a `background` per status.
/// **Both components discard them** in favour of the hardcoded 3-bucket
/// palette below (`HistoryPage.tsx:42-46`) and the detail's `STATUS_THEME`
/// (`HistoryDetailPage.tsx:111-133`). Rendering the API's colours would be a
/// visible divergence, so `StatusPipeline` does not even carry them.
library;

import 'package:flutter/painting.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../application/domain/entities/case_status.dart';

// ── The header gradient — `HistoryPage.tsx:139-141` ─────────────────────────
//
// `linear-gradient(135deg, #344EAD 0%, #2A3F99 60%, #1E3070 100%)`. The three
// stops are `AppColors.primary` / `.headerGradientMid` / `.headerGradientEnd`,
// which is why this file imports none of its own for them — see the library
// doc.

/// `60%` — the middle stop's position, which a two-stop `LinearGradient` would
/// silently lose.
const double kHistoryHeaderMidStop = 0.6;

// ── `STATUS_CONFIG` — `HistoryPage.tsx:42-46` ────────────────────────────────

/// One bucket's chip triple: `{bg, text, ring}`.
///
/// `ring` is the `border-2 border-white` badge's fill on the row icon; it is a
/// distinct value from `bg` in the source for all three buckets, so collapsing
/// the pair would be a Tier 2 miss that no rendered text would show.
class StatusChipStyle {
  const StatusChipStyle({
    required this.background,
    required this.foreground,
    required this.ring,
  });

  final Color background;
  final Color foreground;
  final Color ring;
}

/// `approved: {bg #DCFCE7, text #15803D, ring #86EFAC, icon CheckCircle}`.
const StatusChipStyle kStatusApproved = StatusChipStyle(
  background: AppColors.categoryTintFinance, // #DCFCE7
  foreground: AppColors.success, // #15803D
  ring: AppColors.successRing, // #86EFAC
);

/// `rejected: {bg #FEE2E2, text #DC2626, ring #FCA5A5, icon XCircle}`.
const StatusChipStyle kStatusRejected = StatusChipStyle(
  background: AppColors.categoryTintHealth, // #FEE2E2
  foreground: AppColors.danger, // #DC2626
  ring: AppColors.dangerBorder, // #FCA5A5
);

/// `pending: {bg #FEF3C7, text #D97706, ring #FCD34D, icon Clock}`.
const StatusChipStyle kStatusPending = StatusChipStyle(
  background: AppColors.categoryTintTransport, // #FEF3C7
  foreground: AppColors.warningLink, // #D97706
  ring: AppColors.tutorialSearchOutline, // #FCD34D
);

/// `STATUS_CONFIG[bucketOf(item.status)]` — `HistoryPage.tsx:288-289`.
StatusChipStyle statusChipStyleFor(StatusBucket bucket) {
  switch (bucket) {
    case StatusBucket.approved:
      return kStatusApproved;
    case StatusBucket.rejected:
      return kStatusRejected;
    case StatusBucket.pending:
      return kStatusPending;
  }
}

/// The bucket's glyph — `STATUS_CONFIG[…].icon`.
///
/// **A recorded icon divergence.** `rejected` is `XCircle` in the source and
/// there is no `XCircle.svg` in `assets/icons/lucide/`; `assets/icons/**` is
/// out of B7's scope (§ 4.1) and B7 may not add one. The Flutter row therefore
/// renders Material's `cancel_outlined` for that bucket only — the closest
/// X-in-a-circle in the shipped set — the same disposition `chat_panel.dart`
/// takes for its six Material glyphs. Recorded rather than absorbed: it is
/// invisible to Tier 1 (text) and Tier 2 (tokens), which is exactly the class
/// of gap § 8.5 exists to catch.
///
/// `approved` (`CheckCircle`) and `pending` (`Clock`) are both in the lucide
/// set and are rendered as lucide.
const Map<StatusBucket, String> kStatusLucideIcon = <StatusBucket, String>{
  StatusBucket.approved: 'CheckCircle',
  StatusBucket.pending: 'Clock',
};

// ── The four tiles — `HistoryPage.tsx:166-169` ───────────────────────────────

/// One tile's `{color, bg}` pair. `bg` is set on the tile's dot-free
/// background in the source's data table but the rendered card is white
/// (`:174`); the pair is carried whole so Tier 2 can see both.
class StatTileStyle {
  const StatTileStyle({required this.color, required this.background});

  final Color color;
  final Color background;
}

/// `{label: statTotal, color: #344EAD, bg: #EEF2FF}`.
const StatTileStyle kTileTotal = StatTileStyle(
  color: AppColors.primary, // #344EAD
  background: AppColors.primarySoft, // #EEF2FF
);

/// `{statApproved, #16A34A, #DCFCE7}`.
const StatTileStyle kTileApproved = StatTileStyle(
  color: AppColors.categoryAccentFinance, // #16A34A
  background: AppColors.categoryTintFinance, // #DCFCE7
);

/// `{statInReview, #D97706, #FEF3C7}`.
const StatTileStyle kTileInReview = StatTileStyle(
  color: AppColors.warningLink, // #D97706
  background: AppColors.categoryTintTransport, // #FEF3C7
);

/// `{statRejected, #DC2626, #FEE2E2}`.
const StatTileStyle kTileRejected = StatTileStyle(
  color: AppColors.danger, // #DC2626
  background: AppColors.categoryTintHealth, // #FEE2E2
);

// ── The progress bar — `HistoryPage.tsx:346-352` ─────────────────────────────

/// `bucket === "rejected" ? "#DC2626" : bucket === "approved" ? "#16A34A" : "#344EAD"`.
///
/// Note the approved green here is **`#16A34A`**, which is *not* the
/// `#15803D` of the status chip's text — two different greens on the same row,
/// in the source (`B7-AC-31`).
Color progressBarColour(StatusBucket bucket) {
  switch (bucket) {
    case StatusBucket.rejected:
      return AppColors.danger; // #DC2626
    case StatusBucket.approved:
      return AppColors.categoryAccentFinance; // #16A34A
    case StatusBucket.pending:
      return AppColors.primary; // #344EAD
  }
}

/// `bg-gray-100` on the bar's track — `#F3F4F6`, `AppColors.gray100`.
const Color kProgressTrack = AppColors.gray100;

// ── `paymentChipStyle` — `HistoryDetailPage.tsx:78-83` ───────────────────────

/// One payment chip's `{backgroundColor, color}`.
class PaymentChipStyle {
  const PaymentChipStyle({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

/// `paymentChipStyle(state)`, all five states plus the shared default.
///
/// ```ts
/// if (state === "paid")    return {#DCFCE7, #15803D};
/// if (state === "pending") return {#FEF3C7, #B45309};
/// if (state === "failed")  return {#FEE2E2, #DC2626};
/// return {#F3F4F6, #6B7280};            // refunded, free — and anything else
/// ```
///
/// The fourth line is a **shared default for two states**, not a case each;
/// `B7-AC-43` asserts `refunded` and `free` land on the same pair, which a
/// table with five distinct entries would pass while meaning something else.
/// `PaymentState.unknown` reaches it too, matching the source's `?? ["—","—"]`
/// label fallback having a rendered inhabitant.
///
/// Note `pending`'s foreground is **`#B45309`**, not the `#D97706` of the
/// pending *status* chip. Two ambers on one row, again the source's.
PaymentChipStyle paymentChipStyleFor(PaymentState state) {
  switch (state) {
    case PaymentState.paid:
      return const PaymentChipStyle(
        background: AppColors.categoryTintFinance, // #DCFCE7
        foreground: AppColors.success, // #15803D
      );
    case PaymentState.pending:
      return const PaymentChipStyle(
        background: AppColors.categoryTintTransport, // #FEF3C7
        foreground: AppColors.warning, // #B45309
      );
    case PaymentState.failed:
      return const PaymentChipStyle(
        background: AppColors.categoryTintHealth, // #FEE2E2
        foreground: AppColors.danger, // #DC2626
      );
    case PaymentState.refunded:
    case PaymentState.free:
    case PaymentState.unknown:
      return const PaymentChipStyle(
        background: AppColors.gray100, // #F3F4F6
        foreground: AppColors.muted, // #6B7280
      );
  }
}

// ── The SLA chip — `HistoryPage.tsx:365-370` ─────────────────────────────────

/// `is_overdue ? {#FEE2E2, #DC2626} : {#F3F4F6, #6B7280}`.
PaymentChipStyle slaChipStyle({required bool isOverdue}) => isOverdue
    ? const PaymentChipStyle(
        background: AppColors.categoryTintHealth, // #FEE2E2
        foreground: AppColors.danger, // #DC2626
      )
    : const PaymentChipStyle(
        background: AppColors.gray100, // #F3F4F6
        foreground: AppColors.muted, // #6B7280
      );

/// `NOTIF_STYLE` — how a notification's category is dressed and where tapping
/// it lands.
///
/// Port of `Layout.tsx:60-70`, including the comment at `:55-58` that explains
/// why it is a front-end table at all: *"The API gives each notice a category
/// string; the icon, tint and destination tab are a front-end concern, so they
/// are mapped here rather than sent over the wire. Anything unrecognised falls
/// back to the announcement styling."*
///
/// Seven entries and one fallback, unchanged. The **unrecognised-category path
/// is a mandatory acceptance criterion** (B9-AC-33) for the reason B2-AC-14
/// applied to the unknown-icon fallback: the API can add a category tomorrow
/// and the app must not blank the row or crash.
///
/// ## Colours
///
/// All four distinct pairs are inline hex in the source, so Tier 2 sees them.
/// Three resolve to tokens that already exist with exactly those values; the
/// fourth (`announcement`) needed two new ones — see `app_colors.dart`'s B9a
/// block for why they are named separately rather than aliased onto
/// numerically-equal neighbours.
///
/// ## Icons
///
/// Lucide names on the web (`Clock`, `FileCheck2`, `CreditCard`, `Megaphone`),
/// mapped to their nearest Material glyph here. This does **not** go through
/// `AppIcons`: that registry resolves *wire-supplied* lucide names for the
/// service catalogue and the help centre, where the string comes from the API.
/// These four are compile-time constants in the front-end table, so routing
/// them through a runtime resolver would add a lookup that can miss for a value
/// that cannot change.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../utils/routes/app_name_routes.dart';

/// One row of `NOTIF_STYLE` — `{ icon, color, bg, tab }`.
@immutable
class NotifStyle {
  const NotifStyle({
    required this.icon,
    required this.color,
    required this.background,
    required this.tab,
  });

  final IconData icon;

  /// The glyph tint.
  final Color color;

  /// The tile behind the glyph (`bg` in the source).
  final Color background;

  /// The destination the row navigates to — a main-tab path.
  final String tab;
}

/// `Layout.tsx:61-67`. Seven categories, four distinct dressings.
const Map<String, NotifStyle> kNotifStyle = <String, NotifStyle>{
  // `{ icon: Clock, color: "#F59E0B", bg: "#FEF3C7", tab: "history" }` — :61,62
  'application': _pending,
  'case': _pending,

  // `{ icon: FileCheck2, color: "#16A34A", bg: "#DCFCE7", tab: "account" }`
  // — :63,64
  'certificate': _issued,
  'document': _issued,

  // `{ icon: CreditCard, color: "#344EAD", bg: "#EEF2FF", tab: "wallet" }`
  // — :65,66
  'payment': _money,
  'wallet': _money,

  // `{ icon: Megaphone, color: "#6366F1", bg: "#E0E7FF", tab: "service" }` — :67
  'announcement': _announcement,
};

/// `const NOTIF_FALLBACK = NOTIF_STYLE.announcement` — `Layout.tsx:70`.
///
/// Used at `:131` (the destination tab) and `:255` (the row's dressing). Both
/// call sites fall back to the *same* row, which is why this is one constant
/// and not two.
const NotifStyle kNotifFallback = _announcement;

/// `NOTIF_STYLE[category] ?? NOTIF_FALLBACK` — `Layout.tsx:255`, and `?.tab ??`
/// at `:131`.
NotifStyle notifStyleFor(String category) =>
    kNotifStyle[category] ?? kNotifFallback;

// ── The four dressings ───────────────────────────────────────────────────────
//
// Private consts rather than four inline literals so that `application` and
// `case` are visibly the *same* row, as they are in the source, instead of two
// that happen to agree today.

const NotifStyle _pending = NotifStyle(
  // lucide `Clock`.
  icon: Icons.schedule_outlined,
  // `#F59E0B` — Tailwind amber-500, written inline at `Layout.tsx:61`.
  color: AppColors.warningStrong,
  // `#FEF3C7` — inline at `:61`. Same value as the Transport category's seed
  // tint; that name is `ServicePage.tsx`'s and this is `Layout.tsx`'s, so the
  // citation rather than the name is what makes it checkable.
  background: AppColors.categoryTintTransport,
  tab: AppNameRoutes.history,
);

const NotifStyle _issued = NotifStyle(
  // lucide `FileCheck2`.
  icon: Icons.task_outlined,
  /// `#16A34A` / `#DCFCE7` — inline at `Layout.tsx:63`.
  color: AppColors.categoryAccentFinance,
  background: AppColors.categoryTintFinance,
  tab: AppNameRoutes.account,
);

const NotifStyle _money = NotifStyle(
  // lucide `CreditCard`.
  icon: Icons.credit_card_outlined,
  // `#344EAD` / `#EEF2FF` — inline at `Layout.tsx:65`.
  color: AppColors.primary,
  background: AppColors.primarySoft,
  tab: AppNameRoutes.wallet,
);

const NotifStyle _announcement = NotifStyle(
  // lucide `Megaphone`.
  icon: Icons.campaign_outlined,
  // `#6366F1` / `#E0E7FF` — inline at `Layout.tsx:67`.
  color: AppColors.notifAccentAnnouncement,
  background: AppColors.notifTintAnnouncement,
  tab: AppNameRoutes.service,
);

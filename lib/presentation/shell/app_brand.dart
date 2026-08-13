/// The shell's brand surface.
///
/// ## What moved, and where to
///
/// This file used to be the app's entire design system: four colour literals
/// and the whole `ThemeData`, sitting inside `presentation/shell/` — the folder
/// that owns the header bar. SSD § 10.1 moved that out, because fidelity
/// Tier 2 and B2's five new features all have to read the tokens, and none of
/// them is shell chrome:
///
/// | Was here                  | Now                                          |
/// |---------------------------|----------------------------------------------|
/// | `AppBrand.light()`'s body | `presentation/theme/app_theme.dart`           |
/// | the four colour literals  | `presentation/theme/app_colors.dart`          |
/// | `topBarHeight`            | `presentation/theme/app_spacing.dart`         |
///
/// ## Why [AppBrand] still exists
///
/// SSD § 10.1 says this file is "reduced to the brand **widget**". There is no
/// brand widget to reduce it to — the brand mark is rendered inline inside
/// `app_top_bar.dart`'s `AppBar.title`, and extracting it is not one of the two
/// changes (`ThemeData` sourcing, R-24) B2a's § 3.1 scope permits in that file.
/// Recorded as a spec defect rather than papered over.
///
/// So what remains is a **shell-scoped alias surface**, not a second token
/// layer: every member below forwards to `presentation/theme/`, holds no
/// literal of its own, and exists only so the call sites this batch may not
/// touch keep compiling. `tab_placeholder.dart` reads three of these and is
/// outside B2a's scope (§ 3.1 lists it in no sub-batch), so deleting the names
/// is not available to this ticket.
///
/// **New code must import `presentation/theme/` directly.** This file is a
/// migration seam with a scheduled end, not an API.
library;

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Brand tokens as the shell's pre-B2a call sites named them.
///
/// Every member forwards. See the library doc for why the indirection exists
/// and when it goes away.
abstract final class AppBrand {
  /// Forwards to [AppColors.primary] — `#344EAD`.
  static const primary = AppColors.primary;

  /// Forwards to [AppColors.primarySoft] — `#EEF2FF`.
  static const primarySoft = AppColors.primarySoft;

  /// Forwards to [AppColors.surface] — `#F0F2F8`.
  static const surface = AppColors.surface;

  /// Forwards to [AppColors.muted] — `#6B7280`.
  static const muted = AppColors.muted;

  /// Forwards to [AppSpacing.topBarHeight] — 64.
  static const topBarHeight = AppSpacing.topBarHeight;
}

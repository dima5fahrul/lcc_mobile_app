/// `formValidation.tsx:116-120` — the border and focus-ring a field wears in
/// each of its two states.
///
/// ```ts
/// export function fieldErrorRing(hasError: boolean): string {
///   return hasError
///     ? "border-red-300 focus:border-red-400 focus:ring-red-500/20"
///     : "border-gray-200 focus:border-[#344EAD] focus:ring-2 focus:ring-[#344EAD]/20";
/// }
/// ```
///
/// Six Tailwind utilities, six values, and every one of them is Tier 2's to
/// compare (specs.md § 6.10.1). They are returned as a value object rather than
/// as an `InputDecoration` so a test can assert the **colours** without pumping
/// a widget, which is what makes Tier 2's comparison mechanical.
///
/// ## The two 20 %-alpha derivations are computed, not approximated
///
/// `red-500/20` and `#344EAD/20` have no token, and § 6.10.1 names them as
/// *"the ones an implementer will approximate"* — "close enough" is invisible
/// in review and invisible to a grep for raw literals. They are computed here
/// from the tokens they are alphas **of**, so there is no second value to drift.
///
/// ## `focus:border-red-400` (#F87171) HAS NO TOKEN, and F0b cannot add one
///
/// This is a scope defect in the spec, reported rather than worked around.
/// § 6.10.1 enumerates the kernel's new Tier 2 surface and names only the two
/// alpha derivations as untokenised; measured, **`red-400` has no token at all**
/// (`grep -rn '0xFFF87171' lib/presentation/theme/` → empty). Resolving it means
/// adding a token to `lib/presentation/theme/app_colors.dart`, and that file is
/// **not in § 3.1's F0b table** and is named in § 4.1's out-of-scope list, so
/// editing it is an automatic `F0-AC-66` FAIL. Writing `Color(0xFFF87171)` here
/// instead is an automatic `F0-AC-59` / `B2-AC-11` FAIL.
///
/// So [errorFocusedBorder] holds [AppColors.dangerBorder] — red-300, the same
/// value as the **unfocused** error border — and that is a **registered
/// divergence from the web, not a resolution**: on the web a focused errored
/// field darkens its border one step and here it does not. It is recorded in
/// this doc, in `qa-report.md`, and it is the one Tier 2 entry F0b reports as
/// FAIL rather than quietly rounding to PASS.
library;

import 'dart:ui';

import '../../theme/app_colors.dart';

/// The alpha Tailwind's `/20` suffix means.
const double kFocusRingAlpha = 0.2;

/// One state's worth of `fieldErrorRing`.
class FieldRing {
  const FieldRing({
    required this.border,
    required this.focusedBorder,
    required this.focusRing,
  });

  /// `border-red-300` / `border-gray-200`.
  final Color border;

  /// `focus:border-red-400` / `focus:border-[#344EAD]`.
  final Color focusedBorder;

  /// `focus:ring-red-500/20` / `focus:ring-[#344EAD]/20`. Both sides carry
  /// `focus:ring-2`, so the width is shared and is not part of the colour.
  final Color focusRing;

  @override
  bool operator ==(Object other) =>
      other is FieldRing &&
      other.border == border &&
      other.focusedBorder == focusedBorder &&
      other.focusRing == focusRing;

  @override
  int get hashCode => Object.hash(border, focusedBorder, focusRing);
}

/// `focus:ring-2` — the width both branches share.
const double kFocusRingWidth = 2;

/// `border-red-300` → `#FCA5A5` → [AppColors.dangerBorder].
final FieldRing kFieldErrorRing = FieldRing(
  border: AppColors.dangerBorder,
  // TIER-2 GAP — see the library doc. Should be `red-400` #F87171; no token
  // exists and `presentation/theme/` is outside F0b's § 3.1 scope.
  focusedBorder: AppColors.dangerBorder,
  // `red-500/20` → `#EF4444` at 20 %.
  focusRing: AppColors.dangerStrong.withValues(alpha: kFocusRingAlpha),
);

/// `border-gray-200` → `#E5E7EB` → [AppColors.gray200];
/// `focus:border-[#344EAD]` → [AppColors.primary]; `focus:ring-[#344EAD]/20`.
final FieldRing kFieldRestingRing = FieldRing(
  border: AppColors.gray200,
  focusedBorder: AppColors.primary,
  focusRing: AppColors.primary.withValues(alpha: kFocusRingAlpha),
);

/// The function itself. Kept as a function rather than two constants so the
/// call sites read like the source's `fieldErrorRing(hasError)`.
FieldRing fieldErrorRing(bool hasError) =>
    hasError ? kFieldErrorRing : kFieldRestingRing;

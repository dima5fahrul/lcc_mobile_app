/// `formFields.tsx:49-50` — `fieldBase`, the class string every text-shaped
/// control in the kernel splices `fieldErrorRing()` into.
///
/// ```ts
/// const fieldBase =
///   "w-full bg-white border rounded-2xl px-4 py-3.5 text-sm text-gray-800 placeholder:text-gray-400 focus:outline-none focus:ring-2 transition-all";
/// ```
///
/// Eight values, all of them Tier 2's (specs.md § 6.10.1). They are resolved to
/// theme tokens **once, here**, rather than at each of the four call sites,
/// because § 6.10.1's denominator is *"every distinct colour, radius, spacing
/// and type value appearing in the two source files"* and a value written four
/// times is four chances to write it differently.
///
/// `focus:outline-none` has no Flutter analogue (there is no default outline to
/// remove) and `transition-all` is the browser's implicit animation of the
/// border/ring change; both are recorded here as intentionally not ported
/// rather than left unmentioned.
library;

import 'package:flutter/widgets.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../validation/field_error_ring.dart';

/// `px-4 py-3.5`.
const EdgeInsets kFieldPadding = EdgeInsets.symmetric(
  horizontal: AppSpacing.gap16,
  vertical: AppSpacing.gap14,
);

/// `rounded-2xl`.
const BorderRadius kFieldRadius =
    BorderRadius.all(Radius.circular(AppSpacing.radius2xl));

/// `text-sm text-gray-800`.
const TextStyle kFieldTextStyle = TextStyle(
  fontSize: AppTypography.size14,
  color: AppColors.gray800,
);

/// `placeholder:text-gray-400`. Tailwind's gray-400 is `#9CA3AF`, which is
/// [AppColors.gray400Inline] — **not** `AppColors.gray400` (`#616B7A`), which
/// is a screenshot-measured value under the same number. Getting these two the
/// wrong way round is invisible in review and visible to Tier 2.
const TextStyle kFieldPlaceholderStyle = TextStyle(
  fontSize: AppTypography.size14,
  color: AppColors.gray400Inline,
);

/// `bg-white` — and `bg-gray-100` for a disabled control
/// (`formFields.tsx:160`, `:312`).
const Color kFieldFill = AppColors.white;
const Color kFieldDisabledFill = AppColors.gray100;

/// The border a control wears given its error state and whether it is focused.
///
/// `focus:ring-2` is drawn as a second, outer stroke — Flutter has no ring
/// primitive, so the ring is a `BoxShadow` with zero blur and a
/// [kFocusRingWidth] spread, which renders as a concentric band of the ring
/// colour and is what a `ring` is.
BoxDecoration fieldDecoration({
  required bool hasError,
  bool focused = false,
  bool disabled = false,
}) {
  final FieldRing ring = fieldErrorRing(hasError);
  return BoxDecoration(
    color: disabled ? kFieldDisabledFill : kFieldFill,
    borderRadius: kFieldRadius,
    border: Border.all(
      color: disabled
          ? AppColors.gray200
          : (focused ? ring.focusedBorder : ring.border),
    ),
    boxShadow: focused && !disabled
        ? <BoxShadow>[
            BoxShadow(color: ring.focusRing, spreadRadius: kFocusRingWidth),
          ]
        : null,
  );
}

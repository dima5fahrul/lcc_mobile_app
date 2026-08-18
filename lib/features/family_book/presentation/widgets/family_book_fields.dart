/// `ReadField` and `SectionLabel` — `FamilyBookPage.tsx:105-122`.
///
/// ## `FieldLabel` is REUSED from the kernel; `ReadField` is NOT
///
/// `ssd.md` § 14 F-3 says *"FamilyBook uses none of the shared widgets. Do not
/// normalise."* Read as written that forbids all reuse. Its own subject is the
/// **lookup** widgets — `ReferenceSelect`, `LocationFields`, `SearchableSelect`
/// — and two candidates need a ruling. They resolve in opposite directions, and
/// the grounds are a byte comparison (`specs.md` § 6.7).
///
/// **`FieldLabel` — reuse.** `FamilyBookPage.tsx:95-101` and
/// `formFields.tsx:40-47` carry the **identical** class string:
///
/// ```
/// block text-xs font-semibold text-gray-500 mb-1.5 uppercase tracking-wide
/// ```
///
/// The only difference is that FamilyBook's copy omits the `required` prop, and
/// FamilyBook never passes one. `FieldLabel(required: false)` therefore renders
/// the same pixels. Porting it a second time would create two implementations
/// to keep in step and put this feature on the wrong side of the next token
/// change. This is the **one** kernel import in the whole feature
/// (`F4-AC-11`).
///
/// **`ReadField` — do not reuse.** `:105-114` renders
///
/// ```
/// w-full bg-white border border-gray-200 rounded-2xl px-4 py-3.5 text-sm text-gray-800
/// ```
///
/// against the kernel's `fieldBase` (`formFields.tsx:50`)
///
/// ```
/// w-full bg-white border rounded-2xl px-4 py-3.5 text-sm text-gray-800 placeholder:text-gray-400 focus:outline-none focus:ring-2 transition-all
/// ```
///
/// `ReadField` pins `border-gray-200` and has **no placeholder colour, no focus
/// ring and no transition** — because it is a `<div>`, not an `<input>`, and
/// cannot be focused. Reusing a field base that carries focus affordances on a
/// non-interactive element would give the port an affordance the web does not
/// have. It is also the `value || "—"` site (`:110`), which no kernel widget
/// has.
library;

import 'package:flutter/widgets.dart';

import '../../../../presentation/forms/widgets/field_label.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/family_book_derivations.dart';

/// `FamilyBookPage.tsx:105-114`.
///
/// A registry value the citizen reads and cannot edit, in the same box as the
/// inputs it replaces, so the cover keeps its familiar shape.
class FamilyBookReadField extends StatelessWidget {
  const FamilyBookReadField({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;

  /// Rendered through [orDash] — `{value || "—"}`, `:110`. An **empty string**
  /// becomes the dash; a whitespace-only string does not, because `"  "` is
  /// truthy in JavaScript.
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FieldLabel(label: Text(label)),
        Container(
          // `px-4 py-3.5`
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gap16,
            vertical: AppSpacing.gap14,
          ),
          decoration: const BoxDecoration(
            // `bg-white border border-gray-200 rounded-2xl`
            color: AppColors.white,
            borderRadius:
                BorderRadius.all(Radius.circular(AppSpacing.radius2xl)),
            border: Border.fromBorderSide(
              BorderSide(color: AppColors.gray200),
            ),
          ),
          child: Text(
            orDash(value),
            // `text-sm text-gray-800`
            style: const TextStyle(
              fontSize: AppTypography.size14,
              color: AppColors.gray800,
            ),
          ),
        ),
      ],
    );
  }
}

/// `FamilyBookPage.tsx:116-122`.
///
/// ```tsx
/// <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider pt-1">
/// ```
///
/// **`tracking-wider`, not `tracking-wide`** — `0.05em` against `FieldLabel`'s
/// `0.025em`. Two labels, one screen, two letter-spacings; collapsing them is
/// the sort of thing a Tier 2 comparison catches and a reviewer does not.
class FamilyBookSectionLabel extends StatelessWidget {
  const FamilyBookSectionLabel({super.key, required this.text});

  final String text;

  /// `tracking-wider` is `0.05em`; at `text-xs` that is 12 × 0.05.
  static const double tracking = AppTypography.size12 * 0.05;

  @override
  Widget build(BuildContext context) => Padding(
        // `pt-1`
        padding: const EdgeInsets.only(top: AppSpacing.gap4),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: AppTypography.size12,
            fontWeight: AppTypography.semiBold,
            color: AppColors.muted,
            letterSpacing: tracking,
          ),
        ),
      );
}

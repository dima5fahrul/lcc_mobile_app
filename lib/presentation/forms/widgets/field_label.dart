/// `formFields.tsx:40-47` — the small uppercase label above every field.
///
/// ```tsx
/// <label className="block text-xs font-semibold text-gray-500 mb-1.5 uppercase tracking-wide">
///   {children}
///   {required && <span className="text-red-400 ml-0.5">*</span>}
/// </label>
/// ```
///
/// **`text-red-400` (#F87171) has no token and F0b may not add one** — see
/// `../validation/field_error_ring.dart`'s library doc for the full reasoning.
/// The asterisk therefore renders [AppColors.dangerBorder] (red-300), which is
/// a registered Tier 2 divergence, not a resolution. Two sites share the one
/// missing token: here and the focused error border.
library;

import 'package:flutter/widgets.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// `tracking-wide` is `0.025em`; at `text-xs` that is 12 × 0.025.
const double kFieldLabelTracking = AppTypography.size12 * 0.025;

class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.label, this.required = false});

  /// `children` in the source. A `Widget` rather than a `String` because three
  /// call sites pass a composed node, not a sentence.
  final Widget label;

  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // `mb-1.5`
      padding: const EdgeInsets.only(bottom: AppSpacing.gap6),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          // `text-xs font-semibold text-gray-500 tracking-wide`
          fontSize: AppTypography.size12,
          fontWeight: AppTypography.semiBold,
          color: AppColors.muted,
          letterSpacing: kFieldLabelTracking,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(child: _Uppercase(child: label)),
            if (required)
              const Padding(
                // `ml-0.5`
                padding: EdgeInsets.only(left: AppSpacing.gap2),
                // TIER-2 GAP: should be red-400 #F87171; no token exists.
                child: Text('*', style: TextStyle(color: AppColors.dangerBorder)),
              ),
          ],
        ),
      ),
    );
  }
}

/// CSS `text-transform: uppercase` applied to whatever the caller passed.
///
/// It cannot be done in a `TextStyle`, so it is done where the string is: a
/// plain `Text` child is uppercased, and anything else is passed through
/// untouched rather than guessed at.
class _Uppercase extends StatelessWidget {
  const _Uppercase({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Widget c = child;
    if (c is Text && c.data != null) {
      return Text(
        c.data!.toUpperCase(),
        style: c.style,
        maxLines: c.maxLines,
        overflow: c.overflow,
      );
    }
    return c;
  }
}

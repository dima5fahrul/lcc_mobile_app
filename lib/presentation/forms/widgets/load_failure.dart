/// `formFields.tsx:52-69` — the "Couldn't load — Retry" row, in the same inline
/// style as a field error.
///
/// ```tsx
/// <p data-field-error className="flex items-center gap-1.5 text-xs text-red-500 mt-1.5">
///   <AlertCircle className="w-3.5 h-3.5 flex-shrink-0" />
///   {text(LOAD_FAILED, lang)}
///   <button type="button" onClick={onRetry} className="… font-semibold underline underline-offset-2 …">
///     <RefreshCw className="w-3 h-3" />
///     {text(RETRY, lang)}
///   </button>
/// </p>
/// ```
///
/// ## It is `private` in the source and public here
///
/// `LoadFailure` is not exported from `formFields.tsx`. In Dart, privacy is
/// **per library**, and the four widgets that render this row live in four
/// files, so `_LoadFailure` would have to be copied four times — which is the
/// duplication the closed kernel list exists to prevent. It is public, it lives
/// in its own file, and its source privacy is recorded here (specs.md § 6.3.2).
///
/// ## It carries the error marker
///
/// The source puts `data-field-error` on this `<p>` too, so `scrollToFirstError`
/// treats a failed list as an invalid field. Reproduced by wrapping in
/// [FieldErrorMarker] — the fourth row of § 6.3.4's table turns on this row's
/// presence, so it is not incidental.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../../icons/lucide_icon.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../validation/field_error.dart';
import 'field_sentences.dart';

class LoadFailure extends StatelessWidget {
  const LoadFailure({super.key, required this.onRetry, this.focusNode});

  /// Required, and non-null — `formFields.tsx:223` renders this row only when
  /// **both** `failed` and `onRetry` are truthy, so a `LoadFailure` with
  /// nothing to retry is a state the source cannot reach.
  final VoidCallback onRetry;

  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    const TextStyle base = TextStyle(
      // `text-xs text-red-500`
      fontSize: AppTypography.size12,
      color: AppColors.dangerStrong,
    );

    return FieldErrorMarker(
      focusNode: focusNode,
      child: Padding(
        // `mt-1.5`
        padding: const EdgeInsets.only(top: AppSpacing.gap6),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          // `gap-1.5`
          spacing: AppSpacing.gap6,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // `w-3.5 h-3.5 flex-shrink-0`
                const LucideIcon(
                  name: 'AlertCircle',
                  size: AppSpacing.gap14,
                  color: AppColors.dangerStrong,
                ),
                const SizedBox(width: AppSpacing.gap6),
                Text(kLoadFailedKey.tr(context: context), style: base),
              ],
            ),
            _RetryButton(onRetry: onRetry, style: base),
          ],
        ),
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.onRetry, required this.style});

  final VoidCallback onRetry;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    // A real `Semantics(button: true)` node with a tap target — the source's
    // `<button type="button">`. `GestureDetector` alone would be tappable and
    // invisible to a screen reader.
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onRetry,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // `w-3 h-3`
            const LucideIcon(
              name: 'RefreshCw',
              size: AppSpacing.gap12,
              color: AppColors.dangerStrong,
            ),
            // `gap-1`
            const SizedBox(width: AppSpacing.gap4),
            Text(
              kRetryKey.tr(context: context),
              style: style.copyWith(
                // `font-semibold underline underline-offset-2`
                fontWeight: AppTypography.semiBold,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.dangerStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

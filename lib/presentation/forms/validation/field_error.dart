/// `formValidation.tsx:124-139` — the inline "this field is required" row, and
/// the marker that lets [scrollToFirstError] find it.
///
/// ```tsx
/// <p data-field-error className="flex items-center gap-1 text-xs text-red-500 mt-1.5">
///   <AlertCircle className="w-3.5 h-3.5 flex-shrink-0" />
///   {message ?? t("fieldRequired")}
/// </p>
/// ```
///
/// ## `data-field-error` becomes [FieldErrorMarker]
///
/// The web finds the first invalid field with
/// `document.querySelector("[data-field-error]")` — an attribute on the
/// rendered node, in document order. Flutter has no attributes, so the marker
/// is a widget, and "document order" is depth-first pre-order over the element
/// tree, which is the same order.
///
/// The marker also carries the field's [FocusNode], because the web's next step
/// is `field.querySelectorAll("input, select, …").find(visible && !disabled)`
/// — a DOM query with no Flutter analogue. Threading the node explicitly is
/// parameter-driven, testable, and cannot pick the wrong control.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../../icons/lucide_icon.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Marks the subtree as "this field is currently showing an error".
///
/// Rendered by [FieldErrorText] and by `LoadFailure` — **both**, exactly as the
/// source puts `data-field-error` on both `<p>`s (`formValidation.tsx:134`,
/// `formFields.tsx:56`). A load failure is a thing the citizen has to act on,
/// so it is a scroll target.
class FieldErrorMarker extends StatelessWidget {
  const FieldErrorMarker({super.key, this.focusNode, required this.child});

  /// The control [scrollToFirstError] should focus once it has scrolled here.
  /// Null when the field has no focusable control (a load-failure row on a
  /// select whose button is the control is still focusable; a purely
  /// informational row is not).
  final FocusNode? focusNode;

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// `FieldError` — renders only when [show] is true, exactly as
/// `if (!show) return null;` at `formValidation.tsx:132`.
///
/// Named `FieldErrorText` and not `FieldError` because
/// `lib/core/network/envelope.dart` already declares a **wire** `FieldError`
/// (the 422 entry this widget renders). Two types with one name in one app is
/// how an import gets aliased at nine call sites and then aliased wrongly at
/// the tenth. The source name is recorded here; the Dart name disambiguates.
class FieldErrorText extends StatelessWidget {
  const FieldErrorText({
    super.key,
    required this.show,
    this.message,
    this.focusNode,
  });

  final bool show;

  /// The server's sentence. Null falls back to `common.fieldRequired`, which
  /// already exists in both locale assets and is unchanged by F0.
  final String? message;

  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    return FieldErrorMarker(
      focusNode: focusNode,
      child: Padding(
        // `mt-1.5`
        padding: const EdgeInsets.only(top: AppSpacing.gap6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // `w-3.5 h-3.5 flex-shrink-0`
            const LucideIcon(
              name: 'AlertCircle',
              size: AppSpacing.gap14,
              color: AppColors.dangerStrong,
            ),
            // `gap-1`
            const SizedBox(width: AppSpacing.gap4),
            Flexible(
              child: Text(
                message ?? 'common.fieldRequired'.tr(context: context),
                // `text-xs text-red-500`
                style: const TextStyle(
                  fontSize: AppTypography.size12,
                  color: AppColors.dangerStrong,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

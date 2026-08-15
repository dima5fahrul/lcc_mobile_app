/// `formFields.tsx:282-337` — a plain `<select>` fed by a reference list the
/// page already holds.
///
/// It is the widget that was **already** parameter-driven in the source
/// (`source: ReferenceOptions`), which is why § 6.3.7 calls it *"the shape all
/// of them take"*.
///
/// ## Its failure surface is the kernel's strongest, and that is measured
///
/// `:328-334` is a three-way branch, not the two-way one `SearchableSelect`
/// has:
///
/// ```tsx
/// {failed ? <LoadFailure onRetry={retry} />
///   : empty ? <p className="text-xs text-gray-400 mt-1.5">{text(NOTHING_YET, lang)}</p>
///   : <FieldError show={hasError} message={message} />}
/// ```
///
/// So this consumer reaches **both** `LOAD_FAILED`+`RETRY` **and**
/// `NOTHING_YET`, and its empty message is a row *under* the control rather
/// than a line inside a dropdown. That is row 1 of § 6.3.4's four-row table and
/// `F0-AC-27` clause (i).
///
/// Note `empty` is `!loading && !failed && options.length === 0` (`:301`) — a
/// list that failed is never also "empty", which is L-8 (*"a failed fetch
/// renders LoadFailure + Retry, never an empty dropdown"*) expressed in the
/// source itself.
///
/// And note the control is disabled while **loading**, not only when the caller
/// disables it (`:309` `disabled={disabled || loading}`), and shows
/// `fields.loading` in the placeholder slot while it is (`:315`).
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../icons/lucide_icon.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../validation/field_error.dart';
import '../validation/validation_scope.dart';
import 'field_base.dart';
import 'field_label.dart';
import 'field_sentences.dart';
import 'load_failure.dart';
import 'option.dart';
import 'reference_field_state.dart';

class ReferenceSelectView extends StatefulWidget {
  const ReferenceSelectView({
    super.key,
    required this.label,
    required this.source,
    required this.value,
    required this.placeholder,
    required this.onChanged,
    this.required = false,
    this.path,
    this.disabled = false,
  });

  final Widget label;

  /// The state the page's BLoC holds. **Never fetched here.**
  final ReferenceFieldState source;

  final String value;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final bool required;
  final String? path;
  final bool disabled;

  @override
  State<ReferenceSelectView> createState() => _ReferenceSelectViewState();
}

class _ReferenceSelectViewState extends State<ReferenceSelectView> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ReferenceFieldState s = widget.source;
    // `:309` — loading disables the control.
    final bool inert = widget.disabled || s.loading;

    final FieldErrorState error = ValidationScope.fieldErrorOf(
      context,
      path: widget.path,
      required: widget.required,
      value: widget.value,
      disabled: widget.disabled,
    );
    // `:300`
    final bool outlined = error.hasError || s.failed;
    // `:301` — a failed list is never "empty".
    final bool empty = !s.loading && !s.failed && s.options.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FieldLabel(label: widget.label, required: widget.required),
        Container(
          width: double.infinity,
          padding: kFieldPadding.copyWith(right: AppSpacing.gap40),
          decoration: fieldDecoration(
            hasError: outlined,
            focused: false,
            disabled: inert,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Focus(
                focusNode: _focusNode,
                canRequestFocus: !inert,
                child: _dropdown(context, s, inert),
              ),
              Positioned(
                right: -AppSpacing.gap24,
                top: 0,
                bottom: 0,
                child: Center(
                  child: s.loading
                      // `:319-321` — the spinner replaces the chevron.
                      // Flutter's indicator: `Loader2` is not a bundled glyph
                      // and `assets/icons/**` is byte-frozen (see
                      // `searchable_select.dart`).
                      ? const SizedBox(
                          width: AppSpacing.gap16,
                          height: AppSpacing.gap16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.gray400Inline,
                            ),
                          ),
                        )
                      : const LucideIcon(
                          name: 'ChevronDown',
                          size: AppSpacing.gap16,
                          color: AppColors.gray400Inline,
                        ),
                ),
              ),
            ],
          ),
        ),
        // `:328-334` — the three-way branch, in order.
        if (s.failed && s.retry != null)
          LoadFailure(onRetry: s.retry!, focusNode: _focusNode)
        else if (s.failed)
          // `:329` passes `retry` unconditionally, and `ReferenceFieldState`
          // makes it nullable so the same widget serves a caller that models no
          // retry. With no callback there is no retry affordance to draw, so
          // the failure degrades to the error row rather than to a dead link.
          FieldErrorText(
            show: true,
            message: error.message,
            focusNode: _focusNode,
          )
        else if (empty)
          Padding(
            // `text-xs text-gray-400 mt-1.5`
            padding: const EdgeInsets.only(top: AppSpacing.gap6),
            child: Text(
              kNothingYetKey.tr(context: context),
              style: const TextStyle(
                fontSize: AppTypography.size12,
                color: AppColors.gray400Inline,
              ),
            ),
          )
        else
          FieldErrorText(
            show: error.hasError,
            message: error.message,
            focusNode: _focusNode,
          ),
      ],
    );
  }

  /// `DropdownButton` asserts that EXACTLY ONE item carries `value`
  /// (`dropdown.dart:1028`); the blank row at `:315` always carries `''`, so
  /// falling back to it is total. This mirrors React's own resolution:
  /// `updateOptions` (`react-dom@18.3.1`, `react-dom.development.js:2133-2155`)
  /// selects the first non-disabled option — the blank row — when nothing
  /// matches, and fires no `change`, so the held value survives.
  ///
  /// `length == 1` rather than `isNotEmpty` because the assert fails on *zero
  /// or 2 or more*: a list serving the same code twice is its other arm, which
  /// no zero-match framing reaches. RULING 14, § 6.3.9.
  static String _selectableValue(String value, List<Option> options) {
    if (value.isEmpty) return '';
    return options.where((Option o) => o.value == value).length == 1
        ? value
        : '';
  }

  Widget _dropdown(BuildContext context, ReferenceFieldState s, bool inert) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectableValue(widget.value, s.options),
        isExpanded: true,
        isDense: true,
        icon: const SizedBox.shrink(),
        style: inert ? kFieldPlaceholderStyle : kFieldTextStyle,
        onChanged: inert
            ? null
            : (String? v) {
                if (v == null) return;
                ValidationScope.clearServerErrorOf(context)(widget.path);
                widget.onChanged(v);
              },
        items: <DropdownMenuItem<String>>[
          // `:315` — the blank first option, whose text is the loading
          // sentence while the list is in flight.
          DropdownMenuItem<String>(
            value: '',
            child: Text(
              s.loading
                  ? 'fields.loading'.tr(context: context)
                  : widget.placeholder,
              overflow: TextOverflow.ellipsis,
              style: kFieldPlaceholderStyle,
            ),
          ),
          for (final Option o in s.options)
            DropdownMenuItem<String>(
              value: o.value,
              child: Text(o.label, overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    );
  }
}

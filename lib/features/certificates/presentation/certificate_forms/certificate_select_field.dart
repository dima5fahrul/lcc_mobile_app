/// `SelectField` — Marriage `:223-255`, Divorce `:232-264`, byte-identical.
/// **This is the widget § 6.3 RULING 2(i) turns on.**
///
/// ## It is a native `<select>`, and it renders NONE of the kernel's four states
///
/// | state | kernel `ReferenceSelectView` | this |
/// | --- | --- | --- |
/// | loading | spinner + `fields.loading` | **nothing** |
/// | loaded-empty | `NOTHING_YET` | **nothing** — a `<select>` holding only its placeholder |
/// | failed | `LoadFailure` + Retry + error ring | **nothing** |
/// | server 422 | routed by `path` | routed by an already-resolved `serverError` string (`:229`) |
///
/// Three states collapse into one indistinguishable render, and that is the
/// **measured** behaviour of the shipped app (`fsd.md` D-H, disposition USER,
/// default REPRODUCE). Mounting `ReferenceSelectView` here would add four
/// states the web does not have — `L-10`(b), on the exact page where "but the
/// kernel already does it properly" is most tempting. `F3-AC-24` greps for it.
///
/// The mechanism is upstream of this file and worth naming: `useRefList`
/// (`certificate_ref_list.dart`) exposes `{options, loading}` and **no
/// `failed`**, so a failed list is literally indistinguishable from an empty
/// one before it reaches here. There is nothing to render even if this widget
/// wanted to.
///
/// ## What it does have
///
/// A placeholder `<option value="">` that is always present and always first
/// (`:241`), the options in server order, an error ring driven by
/// `hasError`, and a `FieldError` row. The ring and the row are the source's —
/// `fieldErrorRing(hasError)` at `:239` and `<FieldError show={hasError}>` at
/// `:250`. Reproducing the *absence* of a load-failure row does not mean
/// reproducing the absence of a validation row.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/forms/validation/field_error.dart';
import '../../../../presentation/forms/validation/is_empty.dart';
import '../../../../presentation/forms/validation/validation_scope.dart';
import '../../../../presentation/forms/widgets/field_base.dart';
import '../../../../presentation/forms/widgets/option.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import 'certificate_field_label.dart';

class CertificateSelectField extends StatelessWidget {
  const CertificateSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.placeholder,
    required this.onChanged,
    this.required = false,
    this.serverError,
  });

  final String label;
  final String value;

  /// The list, however it got here. **No `loading` and no `failed`
  /// parameter** — see the library comment; adding either would be adding a
  /// state.
  final List<Option> options;

  final String placeholder;
  final ValueChanged<String> onChanged;
  final bool required;
  final String? serverError;

  @override
  Widget build(BuildContext context) {
    // `:231` — server first, then the revealed blank check.
    final bool hasError = (serverError != null && serverError!.isNotEmpty) ||
        (ValidationScope.showErrorsOf(context) && required && isEmpty(value));

    // A `<select>` whose `value` matches no `<option>` renders blank; Dart's
    // `DropdownButton` asserts instead. Falling back to the placeholder is the
    // closest reachable render and cannot crash a citizen out of the form.
    final bool known = options.any((Option o) => o.value == value);
    final String selected = known ? value : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CertificateFieldLabel(label: Text(label), required: required),
        Container(
          decoration: fieldDecoration(hasError: hasError),
          padding: kFieldPadding,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              key: const Key('certificateSelectField.dropdown'),
              value: selected,
              isExpanded: true,
              isDense: true,
              // `:245-247` — the caller's own chevron, `w-4 h-4 text-gray-400`.
              icon: const LucideIcon(
                name: 'ChevronDown',
                size: AppSpacing.gap16,
                color: AppColors.gray400Inline,
              ),
              style: kFieldTextStyle,
              // `:241` — `<option value="">{placeholder}</option>`, always
              // present, always first, selectable back to blank.
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: '',
                  child: Text(placeholder, style: kFieldPlaceholderStyle),
                ),
                for (final Option o in options)
                  DropdownMenuItem<String>(
                    value: o.value,
                    child: Text(
                      o.label,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: kFieldTextStyle,
                    ),
                  ),
              ],
              onChanged: (String? v) => onChanged(v ?? ''),
            ),
          ),
        ),
        FieldErrorText(show: hasError, message: serverError),
      ],
    );
  }
}

/// `DatedField` — Marriage `:256-268`, Divorce `:265-277`, byte-identical.
///
/// ```tsx
/// <DateField label={label} value={value} onChange={onChange} required={required} />
/// <FieldError show={Boolean(serverError)} message={serverError} />
/// ```
///
/// **A wrapper, not a date control.** The kernel `DateField` is mounted
/// unchanged and unedited (`F3-AC-13`); this adds the *second* error row the
/// two pages want because their server errors arrive as resolved strings
/// rather than through a `path` (see `certificate_input_field.dart`).
///
/// ## Two rows can show at once, and that is the source's behaviour
///
/// `DateField` carries its own `<FieldError>` driven by `useFieldError`
/// (`formFields.tsx:88`), and this appends another. With `required` set,
/// `showErrors` on and a server message present, the web renders **two** error
/// rows — the kernel's generic one and this one. Collapsing them would be
/// tidier and would change what the citizen sees.
///
/// **`path` is never passed to the kernel field** — the two pages do not pass
/// one (`:264`), so the kernel's own row can only ever be the generic
/// "required" sentence, never a routed 422.
library;

import 'package:flutter/widgets.dart';

import '../../../../presentation/forms/validation/field_error.dart';
import '../../../../presentation/forms/widgets/date_field.dart';

class CertificateDatedField extends StatelessWidget {
  const CertificateDatedField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.serverError,
    this.onPickRequested,
  });

  final String label;

  /// `yyyy-MM-dd`, or `''`.
  final String value;

  final ValueChanged<String> onChanged;
  final bool required;
  final String? serverError;

  /// Threaded through so a widget test can drive the picker without a platform
  /// dialog. The source has no analogue — a browser `<input type="date">` opens
  /// its own — and it changes no value the wire sees.
  final Future<String?> Function(BuildContext context, String current)?
      onPickRequested;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DateField(
          label: Text(label),
          value: value,
          onChanged: onChanged,
          required: required,
          onPickRequested: onPickRequested,
        ),
        FieldErrorText(
          show: serverError != null && serverError!.isNotEmpty,
          message: serverError,
        ),
      ],
    );
  }
}

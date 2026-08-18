/// `InputField` — Marriage `:197-221`, Divorce `:183-207`, byte-identical.
///
/// ```tsx
/// const hasError = Boolean(serverError) || (showErrors && Boolean(required) && isEmpty(value));
/// ```
///
/// ## The error rule is the page's, not `ValidationScope`'s
///
/// The kernel resolves a field's error from a **path** —
/// `ValidationScope.fieldErrorOf(path: …)` looks the server message up itself.
/// Marriage and Divorce do not: every call site passes `serverError` as an
/// already-resolved **string** (`serverErrors["spouses.name"]`,
/// Marriage `:482`). Same outcome, different mechanic, and the mechanic is
/// observable at exactly one place — `:206` reads `Boolean(serverError)`
/// **before** `showErrors`, so a server message outlines a field the citizen
/// has not yet tried to submit.
///
/// [ValidationScope.showErrorsOf] is still read, because `showErrors` genuinely
/// is ambient on both pages (`<ValidationProvider showErrors={showErrors}>`,
/// Marriage `:1085`). Only the server lookup is the caller's.
///
/// ## `inputMode`
///
/// `"numeric"` on two Marriage fields (`:1333`). It selects a soft keyboard and
/// changes nothing on the wire; `TextInputType.number` is the analogue. The
/// digits-only coercion a numeric field appears to imply is **not** here — it
/// is `v.replace(/\D/g, "")` at the call site (`:1334`), and only on
/// `bridePriceCash`.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/forms/validation/field_error.dart';
import '../../../../presentation/forms/validation/is_empty.dart';
import '../../../../presentation/forms/validation/validation_scope.dart';
import '../../../../presentation/forms/widgets/field_base.dart';
import 'certificate_field_label.dart';

/// `inputMode` — the three the two pages can produce.
enum CertificateInputMode { text, numeric }

class CertificateInputField extends StatefulWidget {
  const CertificateInputField({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onChanged,
    this.required = false,
    this.inputMode = CertificateInputMode.text,
    this.serverError,
  });

  final String label;
  final String value;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final bool required;
  final CertificateInputMode inputMode;

  /// Already resolved by the caller out of its `serverErrors` map — see the
  /// library comment.
  final String? serverError;

  @override
  State<CertificateInputField> createState() => _CertificateInputFieldState();
}

class _CertificateInputFieldState extends State<CertificateInputField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void didUpdateWidget(CertificateInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A controlled input: the page owns the value. Only overwrite when the
    // incoming value really differs, or the caret jumps on every keystroke.
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // `:206` — the server's message wins outright, before `showErrors`.
    final bool hasError = (widget.serverError != null &&
            widget.serverError!.isNotEmpty) ||
        (ValidationScope.showErrorsOf(context) &&
            widget.required &&
            isEmpty(widget.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CertificateFieldLabel(
          label: Text(widget.label),
          required: widget.required,
        ),
        Container(
          decoration: fieldDecoration(
            hasError: hasError,
            focused: _focusNode.hasFocus,
          ),
          padding: kFieldPadding,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            keyboardType: widget.inputMode == CertificateInputMode.numeric
                ? TextInputType.number
                : TextInputType.text,
            style: kFieldTextStyle,
            decoration: InputDecoration.collapsed(
              hintText: widget.placeholder,
              hintStyle: kFieldPlaceholderStyle,
            ),
          ),
        ),
        FieldErrorText(
          show: hasError,
          message: widget.serverError,
          focusNode: _focusNode,
        ),
      ],
    );
  }
}

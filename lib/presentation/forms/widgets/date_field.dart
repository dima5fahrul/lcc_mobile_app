/// `formFields.tsx:71-95` — the native date picker.
///
/// ```tsx
/// <input type="date" value={value} min={min} max={max}
///        onChange={(e) => { clearServerError(path); onChange(e.target.value); }}
///        className={`${fieldBase} ${fieldErrorRing(hasError)}`} />
/// <FieldError show={hasError} message={message} />
/// ```
///
/// ## The value is a `yyyy-MM-dd` STRING, not a `DateTime`
///
/// `<input type="date">`'s `value` is an ISO date string and that string is
/// what reaches `form_data`. Modelling it as a `DateTime` here would mean
/// formatting it back at every payload site — five pages, ~20 date keys — and
/// every one of those is a chance to format it in UTC, which is the exact
/// defect ADR-0005 exists to remove. The string never leaves string form.
///
/// ## The picker is a Material date picker, and that is a recorded divergence
///
/// The browser renders a native, platform-specific date UI; Flutter has no
/// "native date input". `showDatePicker` is the closest analogue and is what
/// [onPickRequested] defaults to. It is Tier 3's business, F0 renders no route,
/// and no Tier 0/1/2 assertion can see it — the *value* it produces is
/// identical.
///
/// **No `DateTime.now()` and no `toUtc()` appear here.** A date field with a
/// default of "today" would be reading the ambient clock inside the widget
/// tree, which is exactly what `SubmissionClock` exists to stop (ADR-0005 O-4).
/// [firstDate] / [lastDate] are the `min` / `max` attributes and are the
/// caller's.
library;

import 'package:flutter/material.dart';

import '../validation/field_error.dart';
import '../validation/validation_scope.dart';
import 'field_base.dart';
import 'field_label.dart';

class DateField extends StatefulWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.path,
    this.min,
    this.max,
    this.onPickRequested,
  });

  final Widget label;

  /// `yyyy-MM-dd`, or `''` for empty.
  final String value;

  final ValueChanged<String> onChanged;

  final bool required;

  /// `form_data` key, so a server-side error can land on this field.
  /// `formFields.tsx:75-76`.
  final String? path;

  /// `min` / `max`, as `yyyy-MM-dd` strings.
  final String? min;
  final String? max;

  /// Injected so a test can drive the field without a platform dialog, and so
  /// a page can substitute its own picker. Returns the chosen `yyyy-MM-dd`, or
  /// null when the citizen dismissed it.
  final Future<String?> Function(BuildContext context, String current)?
      onPickRequested;

  @override
  State<DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<DateField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final void Function(String?) clearServerError =
        ValidationScope.clearServerErrorOf(context);
    final String? picked = widget.onPickRequested != null
        ? await widget.onPickRequested!(context, widget.value)
        : await _defaultPicker();
    if (picked == null) return;
    clearServerError(widget.path);
    widget.onChanged(picked);
  }

  Future<String?> _defaultPicker() async {
    final DateTime? initial = _parse(widget.value);
    final DateTime first = _parse(widget.min) ?? DateTime(1900);
    final DateTime last = _parse(widget.max) ?? DateTime(2100);
    if (!mounted) return null;
    final DateTime? chosen = await showDatePicker(
      context: context,
      initialDate: initial ?? first,
      firstDate: first,
      lastDate: last,
    );
    return chosen == null ? null : _format(chosen);
  }

  static DateTime? _parse(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }

  /// Local, hand-padded — the same rule and the same reason as
  /// `SubmissionClock.todayLocal`.
  static String _format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final FieldErrorState error = ValidationScope.fieldErrorOf(
      context,
      path: widget.path,
      required: widget.required,
      value: widget.value,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FieldLabel(label: widget.label, required: widget.required),
        Semantics(
          button: true,
          child: GestureDetector(
            onTap: _pick,
            behavior: HitTestBehavior.opaque,
            child: Focus(
              focusNode: _focusNode,
              child: Container(
                width: double.infinity,
                padding: kFieldPadding,
                decoration: fieldDecoration(
                  hasError: error.hasError,
                  focused: _focusNode.hasFocus,
                ),
                child: Text(
                  widget.value,
                  style: widget.value.isEmpty
                      ? kFieldPlaceholderStyle
                      : kFieldTextStyle,
                ),
              ),
            ),
          ),
        ),
        FieldErrorText(
          show: error.hasError,
          message: error.message,
          focusNode: _focusNode,
        ),
      ],
    );
  }
}

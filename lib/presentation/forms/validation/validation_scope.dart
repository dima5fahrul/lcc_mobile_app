/// `formValidation.tsx:25-113` — the shared validation surface, as one
/// `InheritedWidget` instead of two React contexts.
///
/// ## The pattern, ported as-is
///
/// The Continue / Submit button is **always enabled**. When the citizen taps it
/// on an incomplete step the form flips [showErrors] and does **not** advance;
/// every required-but-empty field then renders an inline message and a red
/// outline by reading this scope.
///
/// The same surface carries **server-side** errors. `POST
/// /applications/{id}/submit` answers 422 with one entry per missing mandatory
/// field, keyed by its form path (`"applicant.citizen_name"`). The page hands
/// that map over as [serverErrors]; a field that knows its own path renders the
/// server's sentence instead of the generic "this field is required", so every
/// offending field is highlighted at once rather than one per round trip.
///
/// ## One widget where the source has two contexts
///
/// `formValidation.tsx` splits `ShowErrorsContext` from `ServerErrorsContext`
/// so a `showErrors` flip does not re-render fields that only read server
/// errors. Flutter's [InheritedWidget] has [updateShouldNotify], which
/// expresses the same optimisation without a second widget — and no fidelity
/// tier can observe a rebuild count. Merging them is therefore an internal
/// structure decision (`fsd.md` § 9 D-S: *"Where they live is internal
/// structure, which fidelity does not govern"*), not a behaviour change.
///
/// ## Nothing here reaches the network
///
/// [onClearServerError] is an **injected callback**. This file resolves nothing
/// from a locator and holds no state a network call produced — the rule
/// `F0-AC-78` scans for and `F0-AC-77` proves as a capability.
library;

import 'package:flutter/widgets.dart';

import 'is_empty.dart';

/// The error state of a single field: the server's complaint if there is one,
/// otherwise the local "you left this blank" check once errors are revealed.
class FieldErrorState {
  const FieldErrorState({required this.hasError, this.message});

  final bool hasError;

  /// The server's sentence, or null — in which case the renderer falls back to
  /// `common.fieldRequired`.
  final String? message;

  @override
  bool operator ==(Object other) =>
      other is FieldErrorState &&
      other.hasError == hasError &&
      other.message == message;

  @override
  int get hashCode => Object.hash(hasError, message);

  @override
  String toString() => 'FieldErrorState(hasError: $hasError, message: $message)';
}

/// `formValidation.tsx:41-65`'s `ValidationProvider`.
class ValidationScope extends InheritedWidget {
  const ValidationScope({
    super.key,
    required this.showErrors,
    this.serverErrors = const <String, String>{},
    this.onClearServerError,
    required super.child,
  });

  /// True once the citizen has tried to advance past an incomplete step.
  /// `formValidation.tsx:68-70`.
  final bool showErrors;

  /// Field errors from the API, keyed by `"section.field"`.
  /// `formValidation.tsx:73-75`.
  final Map<String, String> serverErrors;

  /// Called when the citizen edits a field that carried a server error.
  /// `formValidation.tsx:84-86`. Null is the source's `noop` at `:34`.
  final void Function(String? path)? onClearServerError;

  /// The nearest scope, or null.
  ///
  /// Nullable on purpose: `SearchableSelect` and `DateField` are used inside
  /// the certificate wizards, which always provide one, **and** by
  /// `PaymentSection`, which does not. A hard `of()` would make the kernel
  /// unusable outside a wizard and unpumpable in a widget test — which is the
  /// shape `F0-AC-77` exists to prevent.
  static ValidationScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ValidationScope>();

  /// `useShowErrors()`. False with no scope — nothing has been revealed.
  static bool showErrorsOf(BuildContext context) =>
      maybeOf(context)?.showErrors ?? false;

  /// `useServerErrors()`.
  static Map<String, String> serverErrorsOf(BuildContext context) =>
      maybeOf(context)?.serverErrors ?? const <String, String>{};

  /// `useServerError(path)` — the server's message for one path, if it sent
  /// one. A null [path] never matches, exactly as `path ? errors[path] :
  /// undefined` at `formValidation.tsx:80`.
  static String? serverErrorOf(BuildContext context, String? path) {
    if (path == null) return null;
    return maybeOf(context)?.serverErrors[path];
  }

  /// `useClearServerError()`. Always returns a callable; with no scope, or with
  /// no handler supplied, it is the source's `noop`.
  static void Function(String? path) clearServerErrorOf(BuildContext context) =>
      maybeOf(context)?.onClearServerError ?? _noop;

  static void _noop(String? _) {}

  /// `useFieldError({path, required, value, disabled})` —
  /// `formValidation.tsx:99-113`.
  ///
  /// Order is load-bearing: **a server message wins outright**, and only in its
  /// absence is the local blank check consulted. A disabled control (a district
  /// with no province yet) never complains locally — but it still shows a
  /// server error, because the early return happens first.
  static FieldErrorState fieldErrorOf(
    BuildContext context, {
    String? path,
    bool required = false,
    Object? value,
    bool disabled = false,
  }) {
    final String? serverMessage = serverErrorOf(context, path);
    if (serverMessage != null) {
      return FieldErrorState(hasError: true, message: serverMessage);
    }
    final bool local =
        showErrorsOf(context) && required && !disabled && isEmpty(value);
    return FieldErrorState(hasError: local);
  }

  @override
  bool updateShouldNotify(ValidationScope oldWidget) =>
      oldWidget.showErrors != showErrors ||
      !identical(oldWidget.serverErrors, serverErrors) ||
      !_sameErrors(oldWidget.serverErrors, serverErrors) ||
      oldWidget.onClearServerError != onClearServerError;

  static bool _sameErrors(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final MapEntry<String, String> e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}

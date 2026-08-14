/// The change-password form — `AccountPage.tsx:673-706`.
///
/// Three password inputs, two client-side rules, one submit. **The whole
/// client-side policy is `length >= 8` and equality** (`:276-277`); whether the
/// server enforces anything stronger is NOT EVALUATED and unmeasurable without
/// an authenticated write (specs.md § 6.8 item 1, GG-4).
///
/// ## Four measured properties of the source, ported rather than repaired
///
/// specs.md § 6.8 rules that this endpoint needs review beyond the batch floor,
/// on four grounds that are properties of the oracle:
///
/// 1. All validation is client-side and thin (above).
/// 2. **A successful change invalidates no session, locally or remotely.** No
///    token clear, no re-auth, no "sign out other devices" — the old access and
///    refresh tokens stay valid in `FlutterSecureStorage`. If the password was
///    changed *because* it was compromised, that is the case where it matters.
///    GG-5, on the security review's agenda (B8-AC-59 item 2).
/// 3. The error path surfaces the **raw server message** (`:284`). Ported.
/// 4. Three passwords transit immutable, non-zeroable Dart `String`s. Not
///    fixable in Flutter; GG-8, recorded.
///
/// All four are **ported as measured**. Changing any of them would be an
/// R-25-class invisible improvement.
///
/// ## Nothing here is logged — B8-AC-45
///
/// No `print`, no `debugPrint`, no `toString` of a controller. The three values
/// leave this widget exactly once, as `AccountPasswordSubmitted`, and
/// `ChangePasswordParams` never sets `stringify`, so even an `expect` failure
/// prints the type and not the passwords.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../bloc/account_profile_bloc.dart';
import 'account_primitives.dart';

class PasswordForm extends StatefulWidget {
  const PasswordForm({
    super.key,
    required this.pending,
    required this.errorKey,
    required this.serverError,
    required this.changed,
    required this.onSubmit,
  });

  /// `changePassword.pending` — `:703`.
  final bool pending;

  /// The i18n key of whichever client rule failed
  /// (`account.passwordShort` / `account.passwordMismatch`), or null. A key,
  /// not a string, for the reason `PasswordError`'s doc gives.
  final String? errorKey;

  /// `setPwError((err as Error).message)` — the **server's** text, verbatim.
  final String? serverError;

  /// `pwNote` — true after a success, which is also the cue to clear the three
  /// controllers (`setPw({current:"", next:"", confirm:""})`, `:281`).
  final bool changed;

  final void Function(String current, String next, String confirm) onSubmit;

  @override
  State<PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<PasswordForm> {
  final TextEditingController _current = TextEditingController();
  final TextEditingController _next = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  @override
  void didUpdateWidget(covariant PasswordForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The clear at `:281`, driven by the state transition rather than by the
    // callback, so a rebuild between the two cannot lose it.
    if (widget.changed && !oldWidget.changed) {
      _current.clear();
      _next.clear();
      _confirm.clear();
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // `<p className="text-xs font-semibold text-gray-500 uppercase
        // tracking-wider">{c("changePassword")}</p>` — `:674-676`.
        Text(
          'account.changePassword'.tr().toUpperCase(),
          style: const TextStyle(
            color: AppColors.gray500,
            fontSize: AppTypography.size12,
            fontWeight: AppTypography.semiBold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.gap12),

        // The three inputs carry **placeholders**, not labels — `:681`, `:689`,
        // `:697`. The profile editor above uses labels; the two are different
        // in the source and are different here.
        AccountTextField(
          controller: _current,
          obscureText: true,
          hintText: 'account.currentPassword'.tr(),
          autofillHints: const <String>[AutofillHints.password],
        ),
        const SizedBox(height: AppSpacing.gap12),
        AccountTextField(
          controller: _next,
          obscureText: true,
          hintText: 'account.newPassword'.tr(),
          autofillHints: const <String>[AutofillHints.newPassword],
        ),
        const SizedBox(height: AppSpacing.gap12),
        AccountTextField(
          controller: _confirm,
          obscureText: true,
          hintText: 'account.confirmPassword'.tr(),
          autofillHints: const <String>[AutofillHints.newPassword],
        ),

        // `{pwError && …}` — `:701`. One slot in the source, fed by both the
        // client rules and the server message; two nullable inputs here, and at
        // most one is ever set (the BLoC clears the other before setting
        // either).
        if (widget.errorKey != null || widget.serverError != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.gap12),
            child: Text(
              widget.errorKey?.tr() ?? widget.serverError!,
              style: const TextStyle(
                color: AppColors.dangerGlyph,
                fontSize: AppTypography.size12,
              ),
            ),
          ),

        // `{pwNote && …}` — `:702`.
        if (widget.changed)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.gap12),
            child: Text(
              'account.passwordChanged'.tr(),
              style: const TextStyle(
                color: AppColors.green600,
                fontSize: AppTypography.size12,
              ),
            ),
          ),

        const SizedBox(height: AppSpacing.gap12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AccountButton(
            // The button's label is the same string as the heading above it —
            // `c("changePassword")` at both `:675` and `:704`. Two nodes, one
            // key; Tier 1 sees both.
            label: 'account.changePassword'.tr(),
            loading: widget.pending,
            onPressed: () =>
                widget.onSubmit(_current.text, _next.text, _confirm.text),
          ),
        ),
      ],
    );
  }
}

/// Maps the BLoC's client-rule enum to its i18n key.
///
/// Here rather than in the state for the reason `PasswordError`'s doc gives:
/// the resolution must happen at render time, in the reader's locale.
String? passwordErrorKey(PasswordError error) => switch (error) {
      PasswordError.none => null,
      // `if (pw.next.length < 8) { setPwError(c("passwordShort")); return; }`
      PasswordError.tooShort => 'account.passwordShort',
      // `if (pw.next !== pw.confirm) { setPwError(c("passwordMismatch")); … }`
      PasswordError.mismatch => 'account.passwordMismatch',
    };

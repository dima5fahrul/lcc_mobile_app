/// `LoginForm` — the sign-in form.
///
/// Ported from `AuthPage.tsx`'s login branch. Fields: loginId (phone/email),
/// password, math captcha (a+b, regenerates on wrong answer), show/hide
/// password toggle. Buttons: Sign In (submit), "Sign in with SMS code" (OTP
/// flow), "Forgot password?" (reset flow), Register link.
///
/// On submit → `AuthEvent.loginStarted`. On success the shell's
/// `BlocListener` reads the session and hands it to SessionBloc. On failure
/// the form surfaces `AuthState.fieldErrors` per-field.
///
/// ## The public-verification door (user decision, 2026-10-22)
///
/// The form's last control is a secondary text button into the public
/// certificate-verification entry page ([AppNameRoutes.verify]) — see
/// [_VerifyEntryAction] at the foot of this file. It is the **second** of the
/// slice's two in-app doors; the first is the account page's
/// (`account_page.dart`, review C-1), and that one is unreachable to exactly
/// the citizen who needs verification most: `/account` is in
/// `AppRoutes._protectedPaths` while the verification routes are public, so a
/// signed-OUT citizen who opens the app to check someone else's certificate
/// is redirected here and, before this, had no way onward at all. The guide
/// opens its § Public verification endpoints with *"Two endpoints work
/// without login"*, and that citizen is its first use case.
///
/// Every colour, size and gap in the new control is an
/// `AppColors`/`AppTypography`/`AppSpacing` token, not a literal. This file is
/// on `color_literal_test.dart`'s closed grandfather list for the literals it
/// already carries; that exemption covers what is here, and new code in an
/// exempt file still has none.
library;

import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../../utils/routes/app_name_routes.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/api_notice.dart';
import '../widgets/cta_button.dart';
import '../widgets/field_error.dart';
import '../widgets/field_label.dart';

typedef OtpRequestedCallback = void Function(String phone);
typedef ResetRequestedCallback = void Function(String phone);

class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    required this.onSwitchToRegister,
    required this.onOtpRequested,
    required this.onResetRequested,
  });

  final VoidCallback onSwitchToRegister;
  final OtpRequestedCallback onOtpRequested;
  final ResetRequestedCallback onResetRequested;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mathController = TextEditingController();

  bool _showPassword = false;
  Map<String, String> _errors = const {};
  String? _formError;

  late _MathChallenge _math;

  @override
  void initState() {
    super.initState();
    _math = _generateMath();
  }

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    _mathController.dispose();
    super.dispose();
  }

  /// The API takes a bare phone number; the field accepts spaces and dashes.
  /// Port of `normalizePhone` in AuthPage.tsx.
  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'[\s()-]'), '').trim();
  }

  bool _isEmail(String v) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v);
  bool _isPhone(String v) => RegExp(r'^\+?\d{7,15}$').hasMatch(v.replaceAll(RegExp(r'\s'), ''));

  String? _loginIdError(String v) {
    final value = v.trim();
    if (value.isEmpty) return 'auth.errLoginIdRequired'.tr();
    if (value.contains('@')) return _isEmail(value) ? null : 'auth.errEmailInvalid'.tr();
    return _isPhone(value) ? null : 'auth.errPhoneInvalid'.tr();
  }

  Map<String, String> _validate() {
    final errs = <String, String>{};
    final idErr = _loginIdError(_loginIdController.text);
    if (idErr != null) errs['loginId'] = idErr;
    if (_passwordController.text.isEmpty) {
      errs['loginPass'] = 'auth.errPasswordRequired'.tr();
    }
    final mathInput = _mathController.text.trim();
    if (mathInput.isEmpty) {
      errs['math'] = 'auth.errSecurityRequired'.tr();
    } else if (int.tryParse(mathInput) != _math.answer) {
      errs['math'] = 'auth.errSecurityIncorrect'.tr();
      setState(() {
        _math = _generateMath();
        _mathController.clear();
      });
    }
    return errs;
  }

  void _submit() {
    final errs = _validate();
    if (errs.isNotEmpty) {
      setState(() {
        _errors = errs;
      });
      return;
    }
    setState(() {
      _errors = const {};
      _formError = null;
    });
    context.read<AuthBloc>().add(AuthEvent.loginStarted(
          phone: _normalizePhone(_loginIdController.text),
          password: _passwordController.text,
        ));
  }

  void _handleOtpLogin() {
    final id = _normalizePhone(_loginIdController.text);
    if (id.isEmpty) {
      setState(() {
        _errors = {..._errors, 'loginId': 'auth.errLoginIdRequired'.tr()};
        _formError = 'auth.phoneNeeded'.tr();
      });
      return;
    }
    setState(() {
      _formError = null;
    });
    context.read<AuthBloc>().add(AuthEvent.otpRequested(
          phone: id,
          purpose: 'login',
        ));
    // The shell moves to the OTP step once the challenge arrives — but the
    // request-otp usecase is fire-and-forget here; the parent listens for the
    // success and calls onOtpRequested. For a direct login-OTP entry, we
    // optimistically hand the phone to the parent so the OTP form can render.
    widget.onOtpRequested(id);
  }

  void _handleForgotPassword() {
    final id = _normalizePhone(_loginIdController.text);
    if (id.isEmpty) {
      setState(() {
        _errors = {..._errors, 'loginId': 'auth.errLoginIdRequired'.tr()};
        _formError = 'auth.phoneNeeded'.tr();
      });
      return;
    }
    setState(() {
      _formError = null;
    });
    context.read<AuthBloc>().add(AuthEvent.otpRequested(
          phone: id,
          purpose: 'forgot',
        ));
    widget.onResetRequested(id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, next) =>
          prev.status != next.status ||
          prev.errorMessage != next.errorMessage ||
          prev.fieldErrors != next.fieldErrors,
      builder: (context, state) {
        final loading = state.status == AuthStatus.loading;
        // Merge server-side field errors with local ones (server wins).
        final errors = {..._errors, ...state.fieldErrors};
        final formError = state.errorMessage ?? _formError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'auth.welcomeBack'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'auth.welcomeBackSub'.tr(),
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 14),
            if (formError != null) ...[
              ApiNotice(message: formError),
              const SizedBox(height: 12),
            ],
            FieldLabel(text: 'auth.loginIdLabel'.tr()),
            TextField(
              controller: _loginIdController,
              keyboardType: TextInputType.text,
              autofillHints: const [AutofillHints.username],
              decoration: _inputDecoration(
                hint: 'auth.loginIdPlaceholder'.tr(),
                error: errors['loginId'],
              ),
              onChanged: (_) {
                if (_errors.containsKey('loginId')) {
                  setState(() {
                    _errors = {..._errors}..remove('loginId');
                  });
                }
              },
            ),
            FieldError(message: errors['loginId']),
            const SizedBox(height: 12),
            FieldLabel(text: 'auth.passwordLabel'.tr()),
            TextField(
              controller: _passwordController,
              obscureText: !_showPassword,
              autofillHints: const [AutofillHints.password],
              decoration: _inputDecoration(
                hint: 'auth.passwordPlaceholder'.tr(),
                error: errors['loginPass'],
                suffix: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: const Color(0xFF9CA3AF),
                  ),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                  tooltip: _showPassword
                      ? 'auth.hidePassword'.tr()
                      : 'auth.showPassword'.tr(),
                ),
              ),
            ),
            FieldError(message: errors['loginPass']),
            const SizedBox(height: 12),
            // Math captcha.
            FieldLabel(text: 'auth.securityCheckLabel'.tr()),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_math.a} + ${_math.b} = ?',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF344EAD),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _mathController,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    textAlign: TextAlign.center,
                    decoration: _inputDecoration(
                      hint: 'auth.answerPlaceholder'.tr(),
                      error: errors['math'],
                      counter: false,
                    ),
                    onChanged: (_) {
                      if (_errors.containsKey('math')) {
                        setState(() {
                          _errors = {..._errors}..remove('math');
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'auth.newQuestion'.tr(),
                  onPressed: () {
                    setState(() {
                      _math = _generateMath();
                      _mathController.clear();
                    });
                  },
                ),
              ],
            ),
            FieldError(message: errors['math']),
            const SizedBox(height: 16),
            CtaButton(
              label: 'auth.signIn'.tr(),
              loading: loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 14),
            // OTP-by-SMS alternative.
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: loading ? null : _handleOtpLogin,
                icon: const Icon(Icons.sms_outlined, size: 18),
                label: Text('auth.otpSignIn'.tr()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: loading ? null : _handleForgotPassword,
                  child: Text(
                    'auth.forgotPassword'.tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF344EAD),
                    ),
                  ),
                ),
                Text(
                  'auth.noAccount'.tr(),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: widget.onSwitchToRegister,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${'auth.noAccount'.tr()} ',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF9CA3AF)),
                      ),
                      TextSpan(
                        text: 'auth.register'.tr(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF344EAD),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const _VerifyEntryAction(),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    String? error,
    Widget? suffix,
    bool counter = false,
  }) {
    final hasError = error != null && error.isNotEmpty;
    return InputDecoration(
      hintText: hint,
      counterText: counter ? null : '',
      suffixIcon: suffix,
      filled: true,
      fillColor: hasError ? const Color(0xFFFEF2F2) : Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError ? const Color(0xFFFCA5A5) : const Color(0xFFE5E7EB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError ? const Color(0xFFFCA5A5) : const Color(0xFF344EAD),
          width: 2,
        ),
      ),
    );
  }
}

/// The sign-in screen's door into the **public** certificate-verification
/// slice — user decision, 2026-10-22. See this file's library doc for why a
/// second door was needed at all.
///
/// ## Shape
///
/// A hint line over a secondary text button, which is both what the existing
/// account-page door does (`account_page.dart`'s `_VerifyEntryAction`, same
/// two keys, so the two doors read identically) and what this screen already
/// does one control up: the register switch is a centred [TextButton] with a
/// grey caption and a brand-blue action in the same column position. Nothing
/// is invented — the caption takes the grey the `auth.noAccount` caption
/// beside it uses ([AppColors.gray400Inline] is that exact value as a token)
/// and the action takes the weight and colour `auth.forgotPassword` uses.
///
/// ## The two keys are REUSED, not duplicated
///
/// `verify.openAction` / `verify.openActionHint` already exist in both
/// locales for the account-page door and say exactly the right thing here
/// ("Verify a certificate" / "Check any certificate by its code or QR code.").
/// A near-duplicate pair would be two strings to keep in step for one fact,
/// so this round adds **no** i18n key in either file — the en/lo key sets are
/// untouched and therefore still identical.
///
/// ## `.tr(context: context)`
///
/// Both reads pass `context:` (G-L8). The surrounding form's bare `.tr()`
/// calls are pre-existing and allowlisted; `tr_allowlist.yaml` is a ceiling
/// and new code never joins it.
class _VerifyEntryAction extends StatelessWidget {
  const _VerifyEntryAction();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.gap8),
      child: Column(
        children: <Widget>[
          Text(
            'verify.openActionHint'.tr(context: context),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppTypography.size11,
              color: AppColors.gray400Inline,
            ),
          ),
          TextButton(
            // The verification entry is **public** — it is not one of
            // `AppRoutes._protectedPaths` — so this is a plain `go` with no
            // auth gate to cross, and no `?from=` to carry: the citizen is
            // not trying to sign in, they are trying to check a document.
            // Deliberately `.go`, not `.push`: `AppBackPolicy` records it as
            // an ordinary forward visit, which is what makes Back return
            // here. `back_policy_guard_test.dart` counts this call site.
            onPressed: () => context.go(AppNameRoutes.verify),
            child: Text(
              'verify.openAction'.tr(context: context),
              style: const TextStyle(
                fontSize: AppTypography.size12,
                fontWeight: AppTypography.semiBold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple math challenge: a + b = answer. Port of `generateMath`.
class _MathChallenge {
  const _MathChallenge(this.a, this.b, this.answer);
  final int a;
  final int b;
  final int answer;
}

_MathChallenge _generateMath() {
  final rng = Random();
  final a = rng.nextInt(9) + 1;
  final b = rng.nextInt(9) + 1;
  return _MathChallenge(a, b, a + b);
}

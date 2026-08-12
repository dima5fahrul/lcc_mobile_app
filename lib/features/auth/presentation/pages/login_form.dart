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
library;

import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

/// `RegisterForm` — the registration form.
///
/// Ported from `AuthPage.tsx`'s register branch. Fields: fullName, phone,
/// email?, password, confirmPassword, agreed checkbox. Password strength
/// meter (4 bars + label). On submit → `AuthEvent.registerStarted`; on
/// success the shell advances to the OTP step with the returned challenge.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../widgets/api_notice.dart';
import '../widgets/cta_button.dart';
import '../widgets/field_error.dart';
import '../widgets/field_label.dart';
import '../widgets/password_strength.dart';

typedef RegisterSuccessCallback = void Function(String phone);

class RegisterForm extends StatefulWidget {
  const RegisterForm({
    super.key,
    required this.onSwitchToLogin,
    required this.onRegisterSuccess,
  });

  final VoidCallback onSwitchToLogin;
  final RegisterSuccessCallback onRegisterSuccess;

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _showPass = false;
  bool _showConfirm = false;
  bool _agreed = false;
  Map<String, String> _errors = const {};

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _normalizePhone(String value) =>
      value.replaceAll(RegExp(r'[\s()-]'), '').trim();

  bool _isEmail(String v) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v);
  bool _isPhone(String v) =>
      RegExp(r'^\+?\d{7,15}$').hasMatch(v.replaceAll(RegExp(r'\s'), ''));

  Map<String, String> _validate() {
    final errs = <String, String>{};
    if (_fullNameController.text.trim().isEmpty) {
      errs['fullName'] = 'auth.errFullNameRequired'.tr();
    }
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      errs['phone'] = 'auth.errPhoneRequired'.tr();
    } else if (!_isPhone(phone)) {
      errs['phone'] = 'auth.errPhoneInvalid'.tr();
    }
    final email = _emailController.text.trim();
    if (email.isNotEmpty && !_isEmail(email)) {
      errs['regEmail'] = 'auth.errEmailInvalid'.tr();
    }
    final password = _passwordController.text;
    if (password.isEmpty) {
      errs['password'] = 'auth.errPasswordRequired'.tr();
    } else if (password.length < 8) {
      errs['password'] = 'auth.errPasswordMin'.tr();
    }
    final confirm = _confirmController.text;
    if (confirm.isEmpty) {
      errs['confirmPassword'] = 'auth.errConfirmRequired'.tr();
    } else if (password != confirm) {
      errs['confirmPassword'] = 'auth.errPasswordMismatch'.tr();
    }
    if (!_agreed) {
      errs['agreed'] = 'auth.errMustAgree'.tr();
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
    });
    context.read<AuthBloc>().add(AuthEvent.registerStarted(
          phone: _normalizePhone(_phoneController.text),
          name: _fullNameController.text.trim(),
          password: _passwordController.text,
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
        ));
    // Advance to OTP on success — handled by the shell's BlocListener, but
    // we also hand the phone so the OTP form can display it. The shell calls
    // onRegisterSuccess once the challenge arrives.
    widget.onRegisterSuccess(_normalizePhone(_phoneController.text));
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
        // The API's field names differ slightly; the repository rethrows
        // ApiException so the bloc surfaces them via fieldErrors. Map the
        // server's `name` → `fullName`, `email` → `regEmail` here.
        final serverErrors = <String, String>{};
        state.fieldErrors.forEach((key, value) {
          final mapped = switch (key) {
            'name' => 'fullName',
            'email' => 'regEmail',
            _ => key,
          };
          serverErrors[mapped] = value;
        });
        final errors = {..._errors, ...serverErrors};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'auth.createAccount'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'auth.createAccountSub'.tr(),
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 14),
            if (state.errorMessage != null) ...[
              ApiNotice(message: state.errorMessage),
              const SizedBox(height: 12),
            ],
            FieldLabel(text: 'auth.fullNameLabel'.tr()),
            TextField(
              controller: _fullNameController,
              decoration: _inputDecoration(
                hint: 'auth.fullNamePlaceholder'.tr(),
                error: errors['fullName'],
              ),
            ),
            FieldError(message: errors['fullName']),
            const SizedBox(height: 12),
            FieldLabel(text: 'auth.phoneLabel'.tr()),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration(
                hint: 'auth.phonePlaceholder'.tr(),
                error: errors['phone'],
              ),
            ),
            FieldError(message: errors['phone']),
            const SizedBox(height: 12),
            FieldLabel(text: '${'auth.emailLabel'.tr()} ${'auth.optional'.tr()}'),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(
                hint: 'auth.emailPlaceholder'.tr(),
                error: errors['regEmail'],
              ),
            ),
            FieldError(message: errors['regEmail']),
            const SizedBox(height: 12),
            FieldLabel(text: 'auth.passwordLabel'.tr()),
            TextField(
              controller: _passwordController,
              obscureText: !_showPass,
              autofillHints: const [AutofillHints.newPassword],
              decoration: _inputDecoration(
                hint: 'auth.registerPasswordPlaceholder'.tr(),
                error: errors['password'],
                suffix: IconButton(
                  icon: Icon(
                    _showPass ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: const Color(0xFF9CA3AF),
                  ),
                  onPressed: () {
                    setState(() {
                      _showPass = !_showPass;
                    });
                  },
                  tooltip: _showPass
                      ? 'auth.hidePassword'.tr()
                      : 'auth.showPassword'.tr(),
                ),
              ),
            ),
            PasswordStrength(password: _passwordController.text),
            FieldError(message: errors['password']),
            const SizedBox(height: 12),
            FieldLabel(text: 'auth.confirmPasswordLabel'.tr()),
            TextField(
              controller: _confirmController,
              obscureText: !_showConfirm,
              autofillHints: const [AutofillHints.newPassword],
              decoration: _inputDecoration(
                hint: 'auth.confirmPasswordPlaceholder'.tr(),
                error: errors['confirmPassword'],
                suffix: IconButton(
                  icon: Icon(
                    _showConfirm ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: const Color(0xFF9CA3AF),
                  ),
                  onPressed: () {
                    setState(() {
                      _showConfirm = !_showConfirm;
                    });
                  },
                  tooltip: _showConfirm
                      ? 'auth.hidePassword'.tr()
                      : 'auth.showPassword'.tr(),
                ),
              ),
            ),
            FieldError(message: errors['confirmPassword']),
            const SizedBox(height: 12),
            // Terms checkbox.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _agreed,
                  onChanged: (v) {
                    setState(() {
                      _agreed = v ?? false;
                      _errors = {..._errors}..remove('agreed');
                    });
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
                        children: [
                          TextSpan(text: '${'auth.agreePrefix'.tr()} '),
                          TextSpan(
                            text: 'auth.termsOfService'.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF344EAD),
                            ),
                          ),
                          TextSpan(text: ' ${'auth.and'.tr()} '),
                          TextSpan(
                            text: 'auth.privacyPolicy'.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF344EAD),
                            ),
                          ),
                          TextSpan(text: ' ${'auth.agreeSuffix'.tr()}'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            FieldError(message: errors['agreed']),
            const SizedBox(height: 12),
            CtaButton(
              label: 'auth.createAccount'.tr(),
              loading: loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: widget.onSwitchToLogin,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${'auth.haveAccount'.tr()} ',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF9CA3AF)),
                      ),
                      TextSpan(
                        text: 'auth.login'.tr(),
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
  }) {
    final hasError = error != null && error.isNotEmpty;
    return InputDecoration(
      hintText: hint,
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

/// `ResetForm` — the password reset form.
///
/// Ported from `AuthPage.tsx`'s reset branch. Reuses the 6-digit OTP input
/// pattern, adds new password + confirm fields. On submit →
/// `AuthEvent.passwordReset`; on success the shell returns to the login form
/// and surfaces the "resetDone" notice.
library;

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../widgets/api_notice.dart';
import '../widgets/cta_button.dart';
import '../widgets/field_error.dart';
import '../widgets/field_label.dart';

class ResetForm extends StatefulWidget {
  const ResetForm({
    super.key,
    required this.pendingPhone,
    required this.onBack,
  });

  final String pendingPhone;
  final VoidCallback onBack;

  @override
  State<ResetForm> createState() => _ResetFormState();
}

class _ResetFormState extends State<ResetForm> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _showNewPass = false;
  String? _resetError;
  String? _notice;
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _countdown = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_countdown <= 1) {
          _countdown = 0;
          t.cancel();
        } else {
          _countdown -= 1;
        }
      });
    });
  }

  String _code() => _otpControllers.map((c) => c.text).join();

  void _onOtpChanged(int i, String val) {
    if (!RegExp(r'^\d*$').hasMatch(val)) return;
    _otpControllers[i].text = val.length > 1 ? val.substring(0, 1) : val;
    setState(() {});
    if (val.isNotEmpty && i < 5) {
      _focusNodes[i + 1].requestFocus();
    }
  }

  void _submit() {
    final code = _code();
    if (code.length < 6) {
      setState(() {
        _resetError = 'auth.errOtpIncomplete'.tr();
      });
      return;
    }
    if (_newPassController.text.length < 8) {
      setState(() {
        _resetError = 'auth.errPasswordMin'.tr();
      });
      return;
    }
    if (_newPassController.text != _confirmPassController.text) {
      setState(() {
        _resetError = 'auth.errPasswordMismatch'.tr();
      });
      return;
    }
    setState(() {
      _resetError = null;
    });
    context.read<AuthBloc>().add(AuthEvent.passwordReset(
          phone: widget.pendingPhone,
          code: code,
          newPassword: _newPassController.text,
        ));
    // On success, the shell returns to login. The BlocBuilder below surfaces
    // the resetDone notice once the state flips to success.
    if (mounted) {
      setState(() {
        _notice = 'auth.resetDone'.tr();
      });
      widget.onBack();
    }
  }

  String _maskContact(String v) {
    if (v.contains('@')) {
      return v.replaceAll(RegExp(r'(.{1,2}).*(@.+)'), r'$1••••$2');
    }
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 5) return v;
    return '${digits.substring(0, 3)} •••• ${digits.substring(digits.length - 2)}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, next) =>
          prev.status != next.status ||
          prev.errorMessage != next.errorMessage,
      builder: (context, state) {
        final loading = state.status == AuthStatus.loading;
        final error = state.errorMessage ?? _resetError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.mark_email_read_outlined,
                        size: 28, color: Color(0xFF344EAD)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'auth.resetTitle'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'auth.resetSub'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _maskContact(widget.pendingPhone),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 6-digit OTP row.
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  return Container(
                    width: 44,
                    height: 52,
                    margin: EdgeInsets.only(right: i < 5 ? 8 : 0),
                    child: Focus(
                      focusNode: _focusNodes[i],
                      child: TextField(
                        controller: _otpControllers[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF344EAD),
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: _otpControllers[i].text.isNotEmpty
                              ? const Color(0xFFEEF2FF)
                              : const Color(0xFFF9FAFB),
                          contentPadding: EdgeInsets.zero,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB), width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF344EAD), width: 2),
                          ),
                        ),
                        onChanged: (val) => _onOtpChanged(i, val),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            FieldLabel(text: 'auth.newPassword'.tr()),
            TextField(
              controller: _newPassController,
              obscureText: !_showNewPass,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                hintText: 'auth.registerPasswordPlaceholder'.tr(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showNewPass ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: const Color(0xFF9CA3AF),
                  ),
                  onPressed: () {
                    setState(() {
                      _showNewPass = !_showNewPass;
                    });
                  },
                  tooltip: _showNewPass
                      ? 'auth.hidePassword'.tr()
                      : 'auth.showPassword'.tr(),
                ),
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF344EAD), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FieldLabel(text: 'auth.confirmNewPassword'.tr()),
            TextField(
              controller: _confirmPassController,
              obscureText: !_showNewPass,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                hintText: 'auth.confirmPasswordPlaceholder'.tr(),
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF344EAD), width: 2),
                ),
              ),
            ),
            FieldError(message: error),
            const SizedBox(height: 12),
            if (_notice != null) ...[
              ApiNotice(message: _notice, tone: ApiNoticeTone.success),
              const SizedBox(height: 12),
            ],
            CtaButton(
              label: 'auth.savePassword'.tr(),
              loading: loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            Center(
              child: _countdown > 0
                  ? Text(
                      'auth.resendIn'.tr(namedArgs: {'seconds': _countdown.toString()}),
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF9CA3AF)),
                    )
                  : TextButton(
                      onPressed: () {
                        _startCountdown();
                        context.read<AuthBloc>().add(
                              AuthEvent.otpRequested(
                                phone: widget.pendingPhone,
                                purpose: 'forgot',
                              ),
                            );
                      },
                      child: Text(
                        'auth.resendOtp'.tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF344EAD),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: widget.onBack,
                child: Text(
                  'auth.back'.tr(),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF344EAD)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

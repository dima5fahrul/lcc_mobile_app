/// `OtpForm` — the 6-digit OTP verification form.
///
/// Ported from `AuthPage.tsx`'s OTP branch. Six `TextField`s with auto-advance
/// focus, paste support, auto-submit when 6 digits entered, and a 60s resend
/// countdown. On verify → `AuthEvent.otpVerified`; on success the shell's
/// `BlocListener` reads the session and hands it to SessionBloc.
library;

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import 'auth_page.dart' show OtpPurpose;
import '../widgets/api_notice.dart';
import '../widgets/cta_button.dart';

class OtpForm extends StatefulWidget {
  const OtpForm({
    super.key,
    required this.pendingPhone,
    required this.purpose,
    required this.onBack,
  });

  /// The phone the challenge was issued for, exactly as the API normalised it.
  final String pendingPhone;

  /// Which OTP flow this screen serves (login or register).
  final OtpPurpose purpose;

  final VoidCallback onBack;

  @override
  State<OtpForm> createState() => _OtpFormState();
}

class _OtpFormState extends State<OtpForm> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  String? _otpError;
  bool _otpResent = false;
  bool _resending = false;
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Auto-focus the first box on entry.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
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

  String _code() => _controllers.map((c) => c.text).join();

  void _onChanged(int i, String val) {
    if (!RegExp(r'^\d*$').hasMatch(val)) return;
    final next = List<TextEditingController>.from(_controllers);
    next[i].text = val.length > 1 ? val.substring(0, 1) : val;
    setState(() {});
    if (val.isNotEmpty && i < 5) {
      _focusNodes[i + 1].requestFocus();
    }
    // Auto-submit when all 6 digits are present.
    if (_code().length == 6) {
      _verify();
    }
  }

  void _onKeyDown(int i, KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[i].text.isEmpty &&
        i > 0) {
      _focusNodes[i - 1].requestFocus();
    }
  }

  void _onPaste() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text == null) return;
    final digits = data!.text!.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 6) {
      for (var i = 0; i < 6; i++) {
        _controllers[i].text = digits[i];
      }
      _focusNodes.last.requestFocus();
      _verify();
    }
  }

  void _verify() {
    final code = _code();
    if (code.length < 6) {
      setState(() {
        _otpError = 'auth.errOtpIncomplete'.tr();
      });
      return;
    }
    setState(() {
      _otpError = null;
    });
    context.read<AuthBloc>().add(AuthEvent.otpVerified(
          phone: widget.pendingPhone,
          code: code,
          purpose: widget.purpose == OtpPurpose.login ? 'login' : 'register',
        ));
  }

  void _resend() {
    if (_countdown > 0 || _resending) return;
    setState(() {
      _otpError = null;
      _resending = true;
    });
    for (final c in _controllers) {
      c.clear();
    }
    final purpose = widget.purpose == OtpPurpose.login ? 'login' : 'register';
    context.read<AuthBloc>().add(AuthEvent.otpRequested(
          phone: widget.pendingPhone,
          purpose: purpose,
        ));
    setState(() {
      _otpResent = true;
      _resending = false;
    });
    _startCountdown();
    _focusNodes.first.requestFocus();
  }

  /// Masks the contact for display: first 3 + last 2 digits for a phone.
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
        final error = state.errorMessage ?? _otpError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
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
              'auth.otpVerification'.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'auth.otpSentTo'.tr(),
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
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
            const SizedBox(height: 16),
            if (_otpResent) ...[
              ApiNotice(
                message: 'auth.otpResent'.tr(),
                tone: ApiNoticeTone.success,
              ),
              const SizedBox(height: 12),
            ],
            // 6-digit row with paste support.
            GestureDetector(
              onLongPress: _onPaste,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  return Container(
                    width: 44,
                    height: 52,
                    margin: EdgeInsets.only(right: i < 5 ? 8 : 0),
                    child: KeyboardListener(
                      focusNode: _focusNodes[i],
                      onKeyEvent: (e) => _onKeyDown(i, e),
                      child: TextField(
                        controller: _controllers[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: error != null
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF344EAD),
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: _controllers[i].text.isNotEmpty
                              ? const Color(0xFFEEF2FF)
                              : const Color(0xFFF9FAFB),
                          contentPadding: EdgeInsets.zero,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: error != null
                                  ? const Color(0xFFFCA5A5)
                                  : const Color(0xFFE5E7EB),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF344EAD),
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (val) => _onChanged(i, val),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            if (error != null) ...[
              ApiNotice(message: error),
              const SizedBox(height: 12),
            ],
            CtaButton(
              label: loading ? 'common.loading'.tr() : 'auth.verifyCode'.tr(),
              loading: loading,
              onPressed: _verify,
            ),
            const SizedBox(height: 16),
            if (_countdown > 0)
              Text(
                'auth.resendIn'.tr(namedArgs: {'seconds': _countdown.toString()}),
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF9CA3AF)),
              )
            else
              TextButton.icon(
                onPressed: _resending ? null : _resend,
                icon: Icon(Icons.refresh,
                    size: 16,
                    color: _resending
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF344EAD)),
                label: Text(
                  'auth.resendOtp'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _resending
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF344EAD),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: widget.onBack,
              child: Text(
                'auth.back'.tr(),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF344EAD)),
              ),
            ),
          ],
        );
      },
    );
  }
}

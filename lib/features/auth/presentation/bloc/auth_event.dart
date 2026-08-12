part of 'auth_bloc.dart';

@freezed
sealed class AuthEvent with _$AuthEvent {
  /// Login: phone + password (TS `auth.login`).
  const factory AuthEvent.loginStarted({
    required String phone,
    required String password,
  }) = AuthEventLoginStarted;

  /// Register: phone, name, password, optional email (TS `auth.register`).
  const factory AuthEvent.registerStarted({
    required String phone,
    required String name,
    required String password,
    String? email,
  }) = AuthEventRegisterStarted;

  /// Request an OTP for a phone/purpose (TS `auth.requestOTP`).
  const factory AuthEvent.otpRequested({
    required String phone,
    required String purpose,
  }) = AuthEventOtpRequested;

  /// Verify an OTP, returning a session (TS `auth.verifyOTP`).
  const factory AuthEvent.otpVerified({
    required String phone,
    required String code,
    required String purpose,
  }) = AuthEventOtpVerified;

  /// Reset password: phone, code, new password (TS `auth.resetPassword`).
  const factory AuthEvent.passwordReset({
    required String phone,
    required String code,
    required String newPassword,
  }) = AuthEventPasswordReset;

  /// Reset the bloc to its initial state (used when leaving the auth flow).
  const factory AuthEvent.resetState() = AuthEventResetState;
}

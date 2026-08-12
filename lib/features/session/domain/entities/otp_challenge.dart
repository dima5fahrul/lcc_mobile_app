/// `OTPChallenge` — the server's response to an OTP request.
///
/// Ported verbatim from `lcc-app/src/app/api/types.ts`:
///   `interface OTPChallenge { phone: string; purpose: string; expires_at?: string; expires_in?: number; resend_after?: number; dev_code?: string; }`
///
/// `dev_code` is only present in non-production builds (the server gates it);
/// the UI must treat it as optional and never render it unconditionally.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'otp_challenge.freezed.dart';

@freezed
abstract class OTPChallenge with _$OTPChallenge {
  const factory OTPChallenge({
    required String phone,
    required String purpose,
    @JsonKey(name: 'expires_at') String? expiresAt,
    @JsonKey(name: 'expires_in') int? expiresIn,
    @JsonKey(name: 'resend_after') int? resendAfter,
    @JsonKey(name: 'dev_code') String? devCode,
  }) = _OTPChallenge;
}

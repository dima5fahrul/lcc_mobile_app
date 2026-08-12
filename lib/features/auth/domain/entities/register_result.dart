/// `RegisterResult` — the response to a registration request.
///
/// Ported from `lcc-app/src/app/api/types.ts`:
///   `interface RegisterResult { citizen_id: string; challenge: OTPChallenge; }`
///
/// Registration returns the new account id alongside the OTP challenge that
/// verifies the phone number — the UI advances to the OTP step with the
/// challenge's `dev_code` (non-production) so the citizen can confirm.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/otp_challenge.dart';

part 'register_result.freezed.dart';

@freezed
abstract class RegisterResult with _$RegisterResult {
  const factory RegisterResult({
    @JsonKey(name: 'citizen_id') required String citizenId,
    required OTPChallenge challenge,
  }) = _RegisterResult;
}

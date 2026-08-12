/// `OtpChallengeModel` — wire-shape mirror of [OTPChallenge].
///
/// The session feature exposes the [OTPChallenge] entity but no model; this
/// thin model owns the `fromJson` / `toEntity` surface so the auth datasource
/// can parse the challenge returned by request-otp / forgot-password /
/// register without reaching into the session data layer.
///
/// Ported from `lcc-app/src/app/api/types.ts` `OTPChallenge`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/otp_challenge.dart';

part 'otp_challenge_model.freezed.dart';
part 'otp_challenge_model.g.dart';

@freezed
abstract class OtpChallengeModel with _$OtpChallengeModel {
  const factory OtpChallengeModel({
    required String phone,
    required String purpose,
    @JsonKey(name: 'expires_at') String? expiresAt,
    @JsonKey(name: 'expires_in') int? expiresIn,
    @JsonKey(name: 'resend_after') int? resendAfter,
    @JsonKey(name: 'dev_code') String? devCode,
  }) = _OtpChallengeModel;

  factory OtpChallengeModel.fromJson(Map<String, dynamic> json) =>
      _$OtpChallengeModelFromJson(json);
}

extension OtpChallengeModelX on OtpChallengeModel {
  OTPChallenge toEntity() => OTPChallenge(
        phone: phone,
        purpose: purpose,
        expiresAt: expiresAt,
        expiresIn: expiresIn,
        resendAfter: resendAfter,
        devCode: devCode,
      );
}

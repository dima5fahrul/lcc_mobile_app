// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_challenge_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OtpChallengeModel _$OtpChallengeModelFromJson(Map<String, dynamic> json) =>
    _OtpChallengeModel(
      phone: json['phone'] as String,
      purpose: json['purpose'] as String,
      expiresAt: json['expires_at'] as String?,
      expiresIn: (json['expires_in'] as num?)?.toInt(),
      resendAfter: (json['resend_after'] as num?)?.toInt(),
      devCode: json['dev_code'] as String?,
    );

Map<String, dynamic> _$OtpChallengeModelToJson(_OtpChallengeModel instance) =>
    <String, dynamic>{
      'phone': instance.phone,
      'purpose': instance.purpose,
      'expires_at': instance.expiresAt,
      'expires_in': instance.expiresIn,
      'resend_after': instance.resendAfter,
      'dev_code': instance.devCode,
    };

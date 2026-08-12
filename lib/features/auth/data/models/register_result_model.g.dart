// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RegisterResultModel _$RegisterResultModelFromJson(Map<String, dynamic> json) =>
    _RegisterResultModel(
      citizenId: json['citizen_id'] as String,
      challenge: OtpChallengeModel.fromJson(
        json['challenge'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$RegisterResultModelToJson(
  _RegisterResultModel instance,
) => <String, dynamic>{
  'citizen_id': instance.citizenId,
  'challenge': instance.challenge,
};

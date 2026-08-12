// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'citizen_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CitizenProfileModel _$CitizenProfileModelFromJson(Map<String, dynamic> json) =>
    _CitizenProfileModel(
      account: CitizenAccountModel.fromJson(
        json['account'] as Map<String, dynamic>,
      ),
      place: json['place'] == null
          ? null
          : PlaceNamesModel.fromJson(json['place'] as Map<String, dynamic>),
      householdNo: json['household_no'] as String?,
      registry: json['registry'] as Map<String, dynamic>?,
      household: json['household'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$CitizenProfileModelToJson(
  _CitizenProfileModel instance,
) => <String, dynamic>{
  'account': instance.account,
  'place': instance.place,
  'household_no': instance.householdNo,
  'registry': instance.registry,
  'household': instance.household,
};

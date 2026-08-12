// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_names_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlaceNamesModel _$PlaceNamesModelFromJson(Map<String, dynamic> json) =>
    _PlaceNamesModel(
      province: json['province'] == null
          ? null
          : BilingualModel.fromJson(json['province'] as Map<String, dynamic>),
      district: json['district'] == null
          ? null
          : BilingualModel.fromJson(json['district'] as Map<String, dynamic>),
      village: json['village'] == null
          ? null
          : BilingualModel.fromJson(json['village'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PlaceNamesModelToJson(_PlaceNamesModel instance) =>
    <String, dynamic>{
      'province': instance.province,
      'district': instance.district,
      'village': instance.village,
    };

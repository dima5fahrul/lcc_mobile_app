// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jurisdiction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JurisdictionModel _$JurisdictionModelFromJson(Map<String, dynamic> json) =>
    _JurisdictionModel(
      provinceId: json['province_id'] as String?,
      provinceName: json['province_name'] as String?,
      districtId: json['district_id'] as String?,
      districtName: json['district_name'] as String?,
      villageId: json['village_id'] as String?,
      villageName: json['village_name'] as String?,
    );

Map<String, dynamic> _$JurisdictionModelToJson(_JurisdictionModel instance) =>
    <String, dynamic>{
      'province_id': instance.provinceId,
      'province_name': instance.provinceName,
      'district_id': instance.districtId,
      'district_name': instance.districtName,
      'village_id': instance.villageId,
      'village_name': instance.villageName,
    };

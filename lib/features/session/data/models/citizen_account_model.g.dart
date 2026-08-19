// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'citizen_account_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CitizenAccountModel _$CitizenAccountModelFromJson(Map<String, dynamic> json) =>
    _CitizenAccountModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      preferredLang: json['preferred_lang'] as String,
      verified: json['verified'] as bool,
      eidVerified: json['eid_verified'] as bool,
      active: json['active'] as bool,
      createdAt: json['created_at'] as String,
      uin: json['uin'] as String?,
      nationalIdNo: json['national_id_no'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      householdNo: json['household_no'] as String?,
      address: json['address'] as String?,
      jurisdiction: json['jurisdiction'] == null
          ? null
          : JurisdictionModel.fromJson(
              json['jurisdiction'] as Map<String, dynamic>,
            ),
      avatarUrl: json['avatar_url'] as String?,
      lastLoginAt: json['last_login_at'] as String?,
    );

Map<String, dynamic> _$CitizenAccountModelToJson(
  _CitizenAccountModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'phone': instance.phone,
  'email': instance.email,
  'preferred_lang': instance.preferredLang,
  'verified': instance.verified,
  'eid_verified': instance.eidVerified,
  'active': instance.active,
  'created_at': instance.createdAt,
  'uin': instance.uin,
  'national_id_no': instance.nationalIdNo,
  'date_of_birth': instance.dateOfBirth,
  'gender': instance.gender,
  'household_no': instance.householdNo,
  'address': instance.address,
  'jurisdiction': instance.jurisdiction,
  'avatar_url': instance.avatarUrl,
  'last_login_at': instance.lastLoginAt,
};

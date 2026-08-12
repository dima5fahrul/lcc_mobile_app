// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'citizen_account_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CitizenAccountModel _$CitizenAccountModelFromJson(Map<String, dynamic> json) =>
    _CitizenAccountModel(
      id: json['id'] as String,
      uin: json['uin'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      nationalIdNo: json['national_id_no'] as String,
      dateOfBirth: json['date_of_birth'] as String,
      gender: json['gender'] as String,
      avatarUrl: json['avatar_url'] as String?,
      preferredLang: json['preferred_lang'] as String,
      jurisdiction: json['jurisdiction'] as String,
      householdNo: json['household_no'] as String,
      address: json['address'] as String,
      verified: json['verified'] as bool,
      eidVerified: json['eid_verified'] as bool,
      active: json['active'] as bool,
      lastLoginAt: json['last_login_at'] as String?,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$CitizenAccountModelToJson(
  _CitizenAccountModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'uin': instance.uin,
  'name': instance.name,
  'phone': instance.phone,
  'email': instance.email,
  'national_id_no': instance.nationalIdNo,
  'date_of_birth': instance.dateOfBirth,
  'gender': instance.gender,
  'avatar_url': instance.avatarUrl,
  'preferred_lang': instance.preferredLang,
  'jurisdiction': instance.jurisdiction,
  'household_no': instance.householdNo,
  'address': instance.address,
  'verified': instance.verified,
  'eid_verified': instance.eidVerified,
  'active': instance.active,
  'last_login_at': instance.lastLoginAt,
  'created_at': instance.createdAt,
};

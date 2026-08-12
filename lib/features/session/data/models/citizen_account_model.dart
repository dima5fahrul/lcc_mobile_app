/// `CitizenAccountModel` — wire-shape mirror of [CitizenAccount].
///
/// Ported from `lcc-app/src/app/api/types.ts` `CitizenAccount`. Nested inside
/// [CitizenProfileModel] and [CitizenSessionModel].
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/citizen_account.dart';

part 'citizen_account_model.freezed.dart';
part 'citizen_account_model.g.dart';

@freezed
abstract class CitizenAccountModel with _$CitizenAccountModel {
  const factory CitizenAccountModel({
    required String id,
    required String uin,
    required String name,
    required String phone,
    required String email,
    @JsonKey(name: 'national_id_no') required String nationalIdNo,
    @JsonKey(name: 'date_of_birth') required String dateOfBirth,
    required String gender,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'preferred_lang') required String preferredLang,
    required String jurisdiction,
    @JsonKey(name: 'household_no') required String householdNo,
    required String address,
    required bool verified,
    @JsonKey(name: 'eid_verified') required bool eidVerified,
    required bool active,
    @JsonKey(name: 'last_login_at') String? lastLoginAt,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _CitizenAccountModel;

  factory CitizenAccountModel.fromJson(Map<String, dynamic> json) =>
      _$CitizenAccountModelFromJson(json);
}

extension CitizenAccountModelX on CitizenAccountModel {
  CitizenAccount toEntity() => CitizenAccount(
        id: id,
        uin: uin,
        name: name,
        phone: phone,
        email: email,
        nationalIdNo: nationalIdNo,
        dateOfBirth: dateOfBirth,
        gender: gender,
        avatarUrl: avatarUrl,
        preferredLang: preferredLang,
        jurisdiction: jurisdiction,
        householdNo: householdNo,
        address: address,
        verified: verified,
        eidVerified: eidVerified,
        active: active,
        lastLoginAt: lastLoginAt,
        createdAt: createdAt,
      );
}

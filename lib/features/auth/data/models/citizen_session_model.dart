/// `CitizenSessionModel` — wire-shape mirror of [CitizenSession].
///
/// Ported from `lcc-app/src/app/api/types.ts`:
///   `interface CitizenSession { actor: "citizen"; citizen: CitizenAccount; tokens: AuthTokens; }`
///
/// The model holds the **domain entities** [CitizenAccount] / [AuthTokens]
/// directly and owns the parse of their nested JSON objects through this
/// file's own private mapping functions. `auth` therefore depends on the
/// session feature's domain layer only — never on its data layer (CR-4).
///
/// NOTE: This model is hand-written (not `json_serializable`-generated). The
/// domain entities carry `@JsonKey` annotations for documentation, but no
/// generator runs over them, so the snake_case wire keys are mapped
/// explicitly below. The wire contract is unchanged from the previous
/// delegating implementation.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/auth_tokens.dart';
import '../../../session/domain/entities/citizen_account.dart';
import '../../../session/domain/entities/citizen_session.dart';
import '../../../session/domain/entities/jurisdiction.dart';

part 'citizen_session_model.freezed.dart';

@freezed
abstract class CitizenSessionModel with _$CitizenSessionModel {
  const factory CitizenSessionModel({
    required String actor,
    required CitizenAccount citizen,
    required AuthTokens tokens,
  }) = _CitizenSessionModel;

  /// Hand-written `fromJson`. The nested `citizen` / `tokens` objects are
  /// parsed by this file's private path, not by another feature's data layer.
  factory CitizenSessionModel.fromJson(Map<String, dynamic> json) {
    return CitizenSessionModel(
      actor: json['actor'] as String,
      citizen: _citizenAccountFromJson(
        json['citizen'] as Map<String, dynamic>,
      ),
      tokens: _authTokensFromJson(
        json['tokens'] as Map<String, dynamic>,
      ),
    );
  }
}

/// File-private wire mapping for the nested `citizen` object.
CitizenAccount _citizenAccountFromJson(Map<String, dynamic> json) {
  return CitizenAccount(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
    email: json['email'] as String,
    preferredLang: json['preferred_lang'] as String,
    verified: json['verified'] as bool,
    eidVerified: json['eid_verified'] as bool,
    active: json['active'] as bool,
    createdAt: json['created_at'] as String,
    // The seven below are absent or differently-typed on a real staging
    // payload — see `citizen_account.dart`'s library doc for the measurement
    // and the divergence it records.
    uin: json['uin'] as String?,
    nationalIdNo: json['national_id_no'] as String?,
    dateOfBirth: json['date_of_birth'] as String?,
    gender: json['gender'] as String?,
    householdNo: json['household_no'] as String?,
    address: json['address'] as String?,
    jurisdiction: _jurisdictionFromJson(json['jurisdiction']),
    avatarUrl: json['avatar_url'] as String?,
    lastLoginAt: json['last_login_at'] as String?,
  );
}

/// `jurisdiction` — an **object** in `types.ts`, and `{}` on staging.
///
/// Takes `Object?` rather than `Map<String, dynamic>?` deliberately. The field
/// was typed `String` in this port until 2026-08-19 and a cast is what broke
/// login; accepting the raw value and testing it here means a server that
/// starts sending a string, or a number, degrades to `null` instead of throwing
/// on a screen the citizen cannot get past. What the wire sends is a fact to be
/// measured, not an assumption to cast on.
Jurisdiction? _jurisdictionFromJson(Object? raw) {
  if (raw is! Map<String, dynamic>) return null;
  return Jurisdiction(
    provinceId: raw['province_id'] as String?,
    provinceName: raw['province_name'] as String?,
    districtId: raw['district_id'] as String?,
    districtName: raw['district_name'] as String?,
    villageId: raw['village_id'] as String?,
    villageName: raw['village_name'] as String?,
  );
}

/// File-private wire mapping for the nested `tokens` object.
AuthTokens _authTokensFromJson(Map<String, dynamic> json) {
  return AuthTokens(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    tokenType: json['token_type'] as String?,
    expiresAt: json['expires_at'] as String?,
  );
}

extension CitizenSessionModelX on CitizenSessionModel {
  CitizenSession toEntity() => CitizenSession(
        actor: actor,
        citizen: citizen,
        tokens: tokens,
      );
}

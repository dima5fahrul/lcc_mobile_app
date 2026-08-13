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

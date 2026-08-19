/// `CitizenAccountModel` — wire-shape mirror of [CitizenAccount].
///
/// Ported from `lcc-app/src/app/api/types.ts` `CitizenAccount`. Nested inside
/// [CitizenProfileModel] and [CitizenSessionModel].
///
/// ## Nullability corrected 2026-08-19 — the same defect, a second time
///
/// This model carried the identical seven-field problem `citizen_account.dart`
/// documents: six `String`s the server does not send, and `jurisdiction` typed
/// `String` where the wire sends an **object**. It was found while fixing the
/// hand-written parse in `auth/data/models/citizen_session_model.dart`, and it
/// had not fired yet only because it serves `GET /me/profile` rather than the
/// login path — the same crash was waiting on the first profile read.
///
/// Unlike that one, this parse is `json_serializable`-generated, so the cast
/// lives in `citizen_account_model.g.dart` and the fix is the annotation here.
/// See `citizen_account.dart` for the measurement and the divergence record.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/citizen_account.dart';
import 'jurisdiction_model.dart';

part 'citizen_account_model.freezed.dart';
part 'citizen_account_model.g.dart';

@freezed
abstract class CitizenAccountModel with _$CitizenAccountModel {
  const factory CitizenAccountModel({
    required String id,
    required String name,
    required String phone,
    required String email,
    @JsonKey(name: 'preferred_lang') required String preferredLang,
    required bool verified,
    @JsonKey(name: 'eid_verified') required bool eidVerified,
    required bool active,
    @JsonKey(name: 'created_at') required String createdAt,
    // Absent on a real staging payload — see the library doc.
    String? uin,
    @JsonKey(name: 'national_id_no') String? nationalIdNo,
    @JsonKey(name: 'date_of_birth') String? dateOfBirth,
    String? gender,
    @JsonKey(name: 'household_no') String? householdNo,
    String? address,
    /// An object on the wire (`types.ts` `interface Jurisdiction`), never a
    /// string. `json_serializable` builds the nested parse from this type.
    JurisdictionModel? jurisdiction,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'last_login_at') String? lastLoginAt,
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
        jurisdiction: jurisdiction?.toEntity(),
        householdNo: householdNo,
        address: address,
        verified: verified,
        eidVerified: eidVerified,
        active: active,
        lastLoginAt: lastLoginAt,
        createdAt: createdAt,
      );
}

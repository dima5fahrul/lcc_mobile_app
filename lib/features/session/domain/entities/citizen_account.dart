/// `CitizenAccount` — the signed-in citizen's identity record.
///
/// Ported verbatim from `lcc-app/src/app/api/types.ts` `CitizenAccount`. Every
/// snake_case wire field is mapped to a camelCase Dart field via `@JsonKey`.
///
/// `jurisdiction` is kept as a plain `String` for P0 — the full
/// `Jurisdiction` union (province/district/village codes) lands in a later
/// stage when the registry feature is ported.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'citizen_account.freezed.dart';

@freezed
abstract class CitizenAccount with _$CitizenAccount {
  const factory CitizenAccount({
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
  }) = _CitizenAccount;
}

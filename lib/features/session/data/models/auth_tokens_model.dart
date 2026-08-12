/// `AuthTokensModel` — wire-shape mirror of [AuthTokens].
///
/// Ported from `lcc-app/src/app/api/types.ts` `AuthTokens`. The model owns the
/// `fromJson` / `toEntity` surface; the domain [AuthTokens] entity stays
/// framework-agnostic. Returned by `POST /auth/refresh`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/auth_tokens.dart';

part 'auth_tokens_model.freezed.dart';
part 'auth_tokens_model.g.dart';

@freezed
abstract class AuthTokensModel with _$AuthTokensModel {
  const factory AuthTokensModel({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    @JsonKey(name: 'token_type') String? tokenType,
    @JsonKey(name: 'expires_at') String? expiresAt,
  }) = _AuthTokensModel;

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensModelFromJson(json);
}

extension AuthTokensModelX on AuthTokensModel {
  AuthTokens toEntity() => AuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        tokenType: tokenType,
        expiresAt: expiresAt,
      );
}

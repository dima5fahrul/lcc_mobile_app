/// `AuthTokens` — the access/refresh token pair returned by the auth flow.
///
/// Ported verbatim from `lcc-app/src/app/api/types.ts`:
///   `interface AuthTokens { access_token: string; refresh_token: string; token_type?: string; expires_at?: string; }`
///
/// Domain entity (no `fromJson` — the data layer's [AuthTokensModel] handles
/// wire parsing).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_tokens.freezed.dart';

@freezed
abstract class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    @JsonKey(name: 'token_type') String? tokenType,
    @JsonKey(name: 'expires_at') String? expiresAt,
  }) = _AuthTokens;
}

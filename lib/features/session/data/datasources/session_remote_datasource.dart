/// `SessionRemoteDatasource` — the session feature's HTTP boundary.
///
/// Ported from `lcc-app/src/app/api/endpoints.ts` (`me.profile`, `auth.logout`,
/// `auth.refresh`). The abstract keeps the call sites testable; the impl is
/// the only place that touches [ApiClient].
///
/// `ApiClient.request<T>` returns the envelope's `data` field cast to `T`.
/// For typed model responses we call `get<Map<String, dynamic>>` / `post<...>`
/// and then parse via the model's `fromJson`, so the wire-map → typed-model
/// boundary stays inside the datasource (not scattered across repositories).
library;

import '../../../../core/constant/api_endpoint.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/profile_update.dart';
import '../models/auth_tokens_model.dart';
import '../models/citizen_profile_model.dart';
import '../models/profile_update_body.dart';

abstract class SessionRemoteDatasource {
  /// `GET /me/profile` — the signed-in citizen's full profile (authenticated).
  Future<CitizenProfileModel> getProfile();

  /// `PATCH /me/profile` — the dirty-field diff (authenticated).
  ///
  /// Sits beside the `GET` it shares a path with, per specs.md § 6.3. The body
  /// is built by [profileUpdateBody], which is the only place that knows the
  /// snake_case field names.
  Future<CitizenProfileModel> updateProfile(ProfileUpdate update);

  /// `POST /auth/logout` — revoke the refresh token (authenticated).
  Future<void> logout(String refreshToken);

  /// `POST /auth/refresh` — exchange a refresh token for a new pair (anonymous).
  Future<AuthTokensModel> refreshTokens(String refreshToken);
}

class SessionRemoteDatasourceImpl implements SessionRemoteDatasource {
  const SessionRemoteDatasourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<CitizenProfileModel> getProfile() async {
    final data = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoint.meProfile,
    );
    return CitizenProfileModel.fromJson(data);
  }

  @override
  Future<CitizenProfileModel> updateProfile(ProfileUpdate update) async {
    final data = await apiClient.patch<Map<String, dynamic>>(
      ApiEndpoint.meProfile,
      body: profileUpdateBody(update),
    );
    return CitizenProfileModel.fromJson(data);
  }

  @override
  Future<void> logout(String refreshToken) async {
    await apiClient.post<void>(
      ApiEndpoint.authLogout,
      body: <String, dynamic>{'refresh_token': refreshToken},
    );
  }

  @override
  Future<AuthTokensModel> refreshTokens(String refreshToken) async {
    final data = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoint.authRefresh,
      body: <String, dynamic>{'refresh_token': refreshToken},
      anonymous: true,
    );
    return AuthTokensModel.fromJson(data);
  }
}

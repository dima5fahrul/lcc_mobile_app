/// `AuthRemoteDatasource` — the auth feature's HTTP boundary.
///
/// Ported from `lcc-app/src/app/api/endpoints.ts` (`auth` object, lines 61-89).
/// Every auth endpoint is anonymous (no Authorization header), so each method
/// passes `anonymous: true` to [ApiClient.post]. The abstract keeps the call
/// sites testable; the impl is the only place that touches [ApiClient].
///
/// `ApiClient.post<T>` returns the envelope's `data` field cast to `T`. For
/// typed model responses we call `post<Map<String, dynamic>>` and then parse
/// via the model's `fromJson`, so the wire-map → typed-model boundary stays
/// inside the datasource (mirroring the session datasource pattern).
library;

import '../../../../core/constant/api_endpoint.dart';
import '../../../../core/network/api_client.dart';
import '../models/citizen_session_model.dart';
import '../models/otp_challenge_model.dart';
import '../models/register_result_model.dart';

abstract class AuthRemoteDatasource {
  /// `POST /auth/citizen/register` — create account + issue verify OTP.
  Future<RegisterResultModel> register({
    required String phone,
    required String name,
    required String password,
    String? email,
  });

  /// `POST /auth/citizen/request-otp` — request an OTP.
  Future<OtpChallengeModel> requestOtp({
    required String phone,
    required String purpose,
  });

  /// `POST /auth/citizen/verify-otp` — verify an OTP, returning a session.
  Future<CitizenSessionModel> verifyOtp({
    required String phone,
    required String code,
    required String purpose,
  });

  /// `POST /auth/citizen/login` — phone + password login.
  Future<CitizenSessionModel> login({
    required String phone,
    required String password,
  });

  /// `POST /auth/citizen/forgot-password` — issue a reset OTP.
  Future<OtpChallengeModel> forgotPassword({required String phone});

  /// `POST /auth/citizen/reset-password` — spend a reset OTP on a new password.
  Future<bool> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  });

  /// `POST /auth/change-password` — B8a, and **the one authenticated call on
  /// this datasource.**
  ///
  /// Every other method here passes `anonymous: true`; this one must not. The
  /// endpoint sits in the `auth` object (`endpoints.ts:88`) but has no
  /// `{ anonymous: true }` option, so it goes out with whatever token the
  /// interceptor chain attaches — a signed-out citizen has no route to it
  /// (`AccountPage` is behind `_protectedPaths`).
  ///
  /// Body is exactly `{current_password, new_password}` in that order
  /// (`AccountPage.tsx:280`). `confirm` is a client-side check and is **never
  /// transmitted** — B8-AC-34.
  ///
  /// **Recorded, not repaired** (specs.md § 6.8, GG-4/GG-5/GG-8): the source
  /// validates only `length >= 8` and equality, a success invalidates no
  /// session anywhere, and the three passwords transit immutable Dart
  /// `String`s. All four are properties of the ADR-0001 oracle; changing them
  /// here would be an R-25-class invisible divergence.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  const AuthRemoteDatasourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<RegisterResultModel> register({
    required String phone,
    required String name,
    required String password,
    String? email,
  }) async {
    final body = <String, dynamic>{
      'phone': phone,
      'name': name,
      'password': password,
      if (email != null && email.isNotEmpty) 'email': email,
    };
    final data = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoint.authRegister,
      body: body,
      anonymous: true,
    );
    return RegisterResultModel.fromJson(data);
  }

  @override
  Future<OtpChallengeModel> requestOtp({
    required String phone,
    required String purpose,
  }) async {
    final data = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoint.authRequestOtp,
      body: <String, dynamic>{'phone': phone, 'purpose': purpose},
      anonymous: true,
    );
    return OtpChallengeModel.fromJson(data);
  }

  @override
  Future<CitizenSessionModel> verifyOtp({
    required String phone,
    required String code,
    required String purpose,
  }) async {
    final data = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoint.authVerifyOtp,
      body: <String, dynamic>{
        'phone': phone,
        'code': code,
        'purpose': purpose,
      },
      anonymous: true,
    );
    return CitizenSessionModel.fromJson(data);
  }

  @override
  Future<CitizenSessionModel> login({
    required String phone,
    required String password,
  }) async {
    final data = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoint.authLogin,
      body: <String, dynamic>{'phone': phone, 'password': password},
      anonymous: true,
    );
    return CitizenSessionModel.fromJson(data);
  }

  @override
  Future<OtpChallengeModel> forgotPassword({required String phone}) async {
    final data = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoint.authForgotPassword,
      body: <String, dynamic>{'phone': phone},
      anonymous: true,
    );
    return OtpChallengeModel.fromJson(data);
  }

  @override
  Future<bool> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    final data = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoint.authResetPassword,
      body: <String, dynamic>{
        'phone': phone,
        'code': code,
        'new_password': newPassword,
      },
      anonymous: true,
    );
    // The server answers `{ reset: bool }` — read it defensively.
    return (data['reset'] as bool?) ?? true;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // No `anonymous: true` — see the abstract's doc. The response is typed
    // `unknown` in the source and its value is discarded, so `dynamic` rather
    // than `Map<String, dynamic>`: an endpoint that answers `"data": null`
    // would throw on the cast and surface as a failed password change that
    // actually succeeded.
    await apiClient.post<dynamic>(
      ApiEndpoint.authChangePassword,
      body: <String, dynamic>{
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }
}

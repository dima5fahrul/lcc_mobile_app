/// The public verification slice's transport — the two ANONYMOUS endpoints of
/// MOBILE-API-E-CERTIFICATES.md (2026-10), § Public verification endpoints:
///
/// * `GET /verify/{code}` — after a QR scan or a typed code;
/// * `POST /verify/document-hash` — `{"hash": "<64 hex SHA-256>"}`, to check
///   a PDF file the user holds (Task 7's consumer).
///
/// **Both are anonymous, and that is the load-bearing property here.** The
/// guide: "Two endpoints work without login." Every call passes
/// `anonymous: true` so the `AuthInterceptor` attaches no `Authorization`
/// header even when a session exists — a stale bearer to a public endpoint
/// would trigger a refresh round trip a request that never needed one (the
/// `/payment-methods` precedent, `api_endpoint.dart`'s B6a block). A citizen
/// verifying a certificate is very possibly signed out, or verifying someone
/// else's certificate; neither may require a token.
///
/// **An unknown code or hash is not an HTTP error** (§ Errors): it answers
/// 200 with `status: "not-found"` and `valid: false`, which parses through
/// `verification_wire.dart` into a normal [VerificationResult] — a Right at
/// the repository, never a Failure.
library;

import '../../../../core/constant/api_endpoint.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/verification_result.dart';
import '../models/verification_wire.dart';

abstract class VerifyRemoteDatasource {
  /// `GET /verify/{code}` — the [code] as extracted by
  /// `certificateCodeFromScanned`, sent as typed (the server normalises).
  Future<VerificationResult> verifyByCode(String code);

  /// `POST /verify/document-hash` with exactly `{"hash": <hash>}` — the
  /// device-computed SHA-256 of the user's PDF, 64 lower-case hex characters
  /// (the hashing itself is Task 7's surface).
  Future<VerificationResult> verifyDocumentHash(String hash);
}

class VerifyRemoteDatasourceImpl implements VerifyRemoteDatasource {
  const VerifyRemoteDatasourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<VerificationResult> verifyByCode(String code) async {
    final dynamic data = await apiClient.get<dynamic>(
      ApiEndpoint.verifyByCode(code),
      // Anonymous: no bearer, no refresh round trip, works signed out.
      anonymous: true,
    );
    return verificationResultFrom(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  @override
  Future<VerificationResult> verifyDocumentHash(String hash) async {
    final dynamic data = await apiClient.post<dynamic>(
      ApiEndpoint.verifyDocumentHash,
      body: <String, dynamic>{'hash': hash},
      // Anonymous, exactly as the code path above.
      anonymous: true,
    );
    return verificationResultFrom(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }
}

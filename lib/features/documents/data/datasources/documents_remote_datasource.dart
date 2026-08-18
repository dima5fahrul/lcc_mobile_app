/// The collection slice's transport — **two GETs and nothing else**.
///
/// `me.certificates()` (`endpoints.ts:131`) and `me.certificate(id)` (`:132`).
/// Both are `/me/*`, so **both are authenticated**: neither carries
/// `anonymous: true` in the source, and both go out through the root
/// [ApiClient]'s Auth/Refresh interceptor chain (see
/// `documents_datasource_injection.dart`).
///
/// There is no write method here and there must not be one (`B5-AC-25`): B5
/// sends no payload, which is why the fidelity instrument reports Tier 0 as
/// *N/A — no write path* rather than PASS.
///
/// **The QR sub-path is deliberately absent.** `endpoints.ts:133` defines it
/// and nothing calls it — a grep of `lcc-app/src` for its symbol returns line
/// 133 and nothing else — and the payload the card draws comes from the
/// `Certificate` object itself (`types.ts:638-639`, rendered at
/// `HistoryDetailPage.tsx:483`). Under `ADR-0001` an endpoint the shipped
/// client never calls has an empty oracle in all four fidelity tiers
/// (specs.md Finding B, `B5-AC-7`). The symbol is written out in specs.md
/// § 2.2 rather than here, because `B5-AC-7` greps `lib/` for it.
library;

import '../../../../core/constant/api_endpoint.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/issued_certificate.dart';
import '../models/certificate_wire.dart';

abstract class DocumentsRemoteDatasource {
  Future<List<IssuedCertificate>> getCertificates();

  Future<IssuedCertificate> getCertificate(String id);
}

class DocumentsRemoteDatasourceImpl implements DocumentsRemoteDatasource {
  const DocumentsRemoteDatasourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<IssuedCertificate>> getCertificates() async {
    final dynamic data =
        await apiClient.get<dynamic>(ApiEndpoint.meCertificates);
    // `api.get<Certificate[]>` — a **plain array**, not paged. A body that is
    // not a list at all yields the empty list and therefore the card's
    // "not available yet" note, not a crash; and `whereType` costs one
    // malformed row rather than the whole card. The disposition
    // `account_remote_datasource.dart:77-86` and
    // `notification_remote_datasource.dart:76-79` already take (`B5-AC-30`).
    if (data is! List<dynamic>) return const <IssuedCertificate>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(issuedCertificateFrom)
        .toList(growable: false);
  }

  @override
  Future<IssuedCertificate> getCertificate(String id) async {
    final dynamic data =
        await apiClient.get<dynamic>(ApiEndpoint.meCertificate(id));
    return issuedCertificateFrom(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }
}

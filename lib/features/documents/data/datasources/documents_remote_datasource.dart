/// The collection slice's transport — the two B5 GETs plus the two v2
/// sub-path GETs the 2026-10 MOBILE-API-E-CERTIFICATES guide added (file,
/// QR). All four are `/me/*`, so **all four are authenticated**: none is
/// anonymous, and all go out through the root [ApiClient]'s Auth/Refresh
/// interceptor chain (see `documents_datasource_injection.dart`).
///
/// There is still no write method here and there must not be one
/// (`B5-AC-25`): B5 sends no payload, which is why the fidelity instrument
/// reports Tier 0 as *N/A — no write path* rather than PASS. The two v2
/// additions are GETs; the no-write invariant is unchanged.
///
/// **The QR sub-path's original absence is superseded.** The B5 adjudication
/// (specs.md Finding B, `B5-AC-7`) refused `endpoints.ts:133` because the
/// shipped web client never called it; the backend's 2026-10 guide now
/// serves `GET /me/certificates/{id}/qr` as a live citizen endpoint with a
/// documented payload, and drawing it on screen is the product requirement.
/// [getCertificateQr] consumes it.
///
/// **The file endpoint is the app's first binary transport.** The guide:
/// PDF file endpoints "return the raw PDF bytes, not JSON" (§ Overview), so
/// the download rides `ApiClient.getBytes`/`getResponse` (`ResponseType.
/// bytes`), and the filename + integrity hash arrive as **response headers**
/// (`Content-Disposition`, `X-Content-SHA256`), parsed below. The bearer
/// token rides the `Authorization` header the interceptor attaches — never
/// the URL (§ Citizen endpoints, File: "Download with the bearer header (no
/// token in the URL)").
library;

import 'dart:typed_data';

import 'package:dio/dio.dart' show Response;

import '../../../../core/constant/api_endpoint.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/certificate_file_download.dart';
import '../../domain/entities/certificate_qr.dart';
import '../../domain/entities/issued_certificate.dart';
import '../models/certificate_wire.dart';

abstract class DocumentsRemoteDatasource {
  /// [applicationId] is the endpoint's own `?application_id=…` filter
  /// (§ Citizen endpoints, List). Null or empty sends **no query key at all**,
  /// so the unfiltered call goes out byte-identical to what it was before the
  /// parameter existed.
  Future<List<IssuedCertificate>> getCertificates({String? applicationId});

  Future<IssuedCertificate> getCertificate(String id);

  /// `GET /me/certificates/{id}/qr` — the QR payload fixed at issue.
  Future<CertificateQr> getCertificateQr(String id);

  /// `GET /me/certificates/{id}/file` — the raw PDF bytes with the two
  /// headers the server sends beside them. [inline] appends
  /// `disposition=inline` (view rather than download); the filename and hash
  /// headers are read either way.
  Future<CertificateFileDownload> downloadCertificateFile(
    String id, {
    required String layout,
    bool inline = false,
  });
}

class DocumentsRemoteDatasourceImpl implements DocumentsRemoteDatasource {
  const DocumentsRemoteDatasourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<IssuedCertificate>> getCertificates({
    String? applicationId,
  }) async {
    // An absent or empty filter sends `query: null`, not `{}` — dio appends a
    // `?` for an empty map, and the unfiltered request has to stay the exact
    // URL it was before this parameter existed.
    final String? filter = applicationId;
    final Map<String, dynamic>? query =
        (filter == null || filter.isEmpty)
            ? null
            : <String, dynamic>{'application_id': filter};
    final dynamic data = await apiClient.get<dynamic>(
      ApiEndpoint.meCertificates,
      query: query,
    );
    return _certificateRows(data)
        .map(issuedCertificateFrom)
        .toList(growable: false);
  }

  /// The keys a wrapped list body could plausibly carry its rows under, in
  /// the order they are tried. See [_certificateRows].
  static const List<String> _kRowKeys = <String>[
    'items',
    'data',
    'rows',
    'certificates',
  ];

  /// The certificate rows of a `GET /me/certificates` body — **whichever of
  /// the two wire shapes the server actually sends**.
  ///
  /// ## Why this is permissive, and why it must stay permissive
  ///
  /// **DO NOT "simplify" this back into a single-shape parse.** The live shape
  /// is *unconfirmed*: no token for this endpoint has ever been available to
  /// this programme, so nothing here has been observed against a real
  /// response (the same limitation `documents_test_helper.dart` records for
  /// the fixtures).
  ///
  /// Two shapes are therefore both credible and both are accepted:
  ///
  /// * **A plain array.** `api.get<Certificate[]>` in the old web client, which
  ///   is where this datasource's original `data is! List` assumption came
  ///   from.
  /// * **An object wrapping the rows.** The guide's own envelope
  ///   (MOBILE-API-E-CERTIFICATES.md § Overview) puts `data` and `meta` as
  ///   **siblings** — `{ "success": …, "data": { }, "meta": { }, … }`, with
  ///   `meta` appearing "only on paginated lists" — so for this endpoint the
  ///   guide's own shape has `data` itself *be* the bare array, with `meta`
  ///   beside it. That sibling shape is what the code reads first; it is the
  ///   wrapped-object branch below that is **unconfirmed**, not the
  ///   documented one.
  ///
  /// The wrapped branch exists purely as insurance: no token for this
  /// endpoint has ever been available to this programme, so nothing here has
  /// been checked against a real server, and a paginated backend may still
  /// nest the rows under `data` despite what the guide says. If it does, a
  /// parser that only ever reads the bare-array shape returns the **empty
  /// list** silently — no exception, no `Failure`, just the card's "not
  /// available yet" note on an account that has certificates, every
  /// certificate gone with no error anywhere. Accepting both shapes costs one
  /// `Map` lookup.
  ///
  /// ## The lenient disposition is unchanged (`B5-AC-30`)
  ///
  /// A shape that matches **nothing** yields the empty list rather than
  /// throwing, and `whereType<Map<String, dynamic>>()` still costs one
  /// malformed row rather than the whole list — the disposition
  /// `account_remote_datasource.dart:77-86` and
  /// `notification_remote_datasource.dart:76-79` already take.
  ///
  /// ## Why not `ApiClient.requestPaged`
  ///
  /// `requestPaged` reads `envelope['data']` and keeps it only when it
  /// `is List` (`api_client.dart:188-190`), so it has the *same* blind spot
  /// this helper exists to close — it would answer the empty list for a
  /// wrapped body too. It would also change this method's return type to
  /// `Paged<…>` and push a `PageMeta` nobody renders through the repository
  /// and use case. Nothing on the surface pages this list today; when
  /// something does, `requestPaged` is the right instrument for the `meta`
  /// half and this helper is still the right instrument for the rows.
  static List<Map<String, dynamic>> _certificateRows(dynamic data) {
    if (data is List<dynamic>) {
      return data.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    if (data is Map<String, dynamic>) {
      for (final String key in _kRowKeys) {
        final dynamic rows = data[key];
        if (rows is List<dynamic>) {
          return rows.whereType<Map<String, dynamic>>().toList(growable: false);
        }
      }
    }
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<IssuedCertificate> getCertificate(String id) async {
    final dynamic data =
        await apiClient.get<dynamic>(ApiEndpoint.meCertificate(id));
    return issuedCertificateFrom(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  @override
  Future<CertificateQr> getCertificateQr(String id) async {
    // Through the envelope (`apiClient.get`), like the two reads above: the
    // QR endpoint answers JSON, not bytes.
    final dynamic data =
        await apiClient.get<dynamic>(ApiEndpoint.meCertificateQr(id));
    return certificateQrFrom(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  @override
  Future<CertificateFileDownload> downloadCertificateFile(
    String id, {
    required String layout,
    bool inline = false,
  }) async {
    // The query map carries the layout choice; `disposition=inline` is
    // appended as a query value only when viewing. The layout is never a
    // path segment and the token is never in the URL — the interceptor
    // chain attaches the bearer header.
    final Map<String, dynamic> query = <String, dynamic>{
      'layout': layout,
      if (inline) 'disposition': 'inline',
    };
    final Response<Uint8List> response = await apiClient.getResponse(
      ApiEndpoint.meCertificateFile(id),
      query: query,
    );

    return CertificateFileDownload(
      bytes: response.data ?? Uint8List(0),
      fileName: _filenameFrom(response),
      sha256Header: _headerValue(response, 'x-content-sha256'),
    );
  }

  /// `Content-Disposition: attachment; filename="LA-MAR-2026-000652-booklet.
  /// pdf"` → `LA-MAR-2026-000652-booklet.pdf`. Null when the header is
  /// absent or carries no `filename=` parameter — Task 6 falls back to
  /// `<certificate_no>-<layout>.pdf`.
  static String? _filenameFrom(Response<Uint8List> response) {
    final String? disposition =
        _headerValue(response, 'content-disposition');
    if (disposition == null) return null;
    final RegExpMatch? match =
        RegExp(r'filename\s*=\s*"([^"]*)"').firstMatch(disposition) ??
            RegExp(r'filename\s*=\s*([^;\s]+)').firstMatch(disposition);
    return match?.group(1);
  }

  /// One header value, case-insensitively — dio's header map is
  /// case-insensitive but returns a *list* per name, and `Headers.value`
  /// throws when a server ever sends the header twice, which is not this
  /// datasource's problem to crash on. First value wins.
  static String? _headerValue(Response<Uint8List> response, String name) {
    final List<String>? values = response.headers[name];
    if (values == null || values.isEmpty) return null;
    return values.first;
  }
}

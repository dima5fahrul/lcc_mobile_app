/// `CertificateFile` — one entry of a certificate's `files[]`, the per-layout
/// PDF the v2 API sends.
///
/// From MOBILE-API-E-CERTIFICATES.md § Certificate model: each entry is
/// `{"layout": "card" | "booklet", "url": "...", "sha256": "<64 hex>"}` — one
/// per layout, so a marriage row carries a `card` and a `booklet` and divorce
/// copies A and B carry their booklet alone.
///
/// ## `layout` is a plain `String`, deliberately
///
/// The spec's table names two layouts today, but it is the *certificate's
/// type* that decides the set (`Layouts per row` column), and the spec grows
/// layouts by adding rows to that table. An enum would turn a new layout into
/// a parse failure on every row that carries it — the exact failure mode
/// `issued_certificate.dart` § `status` records for status strings. The same
/// argument applies to [url] and [sha256]: all three are opaque wire strings,
/// and `sha256` is *empty* for an old certificate whose file was never hashed,
/// so `bool`-coercing it here would lose the spec's own absence marker.
///
/// ## The URL is kept relative
///
/// The spec's `files[].url` is a path (`/api/v1/me/certificates/<id>/file…`),
/// and the download endpoint is bearer-authenticated — a token must never ride
/// in a URL (`G-AC` envelope). Keeping the path verbatim leaves the join with
/// the API base and the attachment of the auth header to the download
/// datasource, where both belong.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'certificate_file.freezed.dart';

@freezed
abstract class CertificateFile with _$CertificateFile {
  const factory CertificateFile({
    required String layout,
    required String url,
    required String sha256,
  }) = _CertificateFile;
}

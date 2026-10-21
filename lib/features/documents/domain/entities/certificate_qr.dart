/// `CertificateQr` — the QR payload endpoint's answer, `GET
/// /me/certificates/{id}/qr` (MOBILE-API-E-CERTIFICATES.md, 2026-10,
/// § Citizen endpoints, QR paragraph).
///
/// `data` = `{certificate_id, certificate_no, verify_code, verify_url,
/// payload, document_hash, status, valid, issued_at}` — all nine keys, per
/// `application_row.dart`'s standing rule that every field the wire sends is
/// parsed, rendered or not.
///
/// ## `payload` is what the screen draws
///
/// The guide: "Draw `payload` as the QR on screen: it is the link printed in
/// the certificate's own QR, **fixed at issue**. `verify_url` is the same
/// link built from the server's current setting; the two differ only for a
/// certificate issued under an older verification address." The two fields
/// are therefore kept distinct rather than collapsed — collapsing would
/// silently retarget an old certificate's QR at the current host.
///
/// ## Lenient shapes, matching the certificate mapper's dispositions
///
/// * `status` is a plain `String` — the open set argument of
///   `issued_certificate.dart` (public verification adds `expired` and
///   `not-found` beside the four `/me` statuses).
/// * `valid` is a nullable `bool` — a non-bool wire value means *unknown*,
///   which `false` would misreport (`certificate_wire.dart` `_nullableBoolAt`).
/// * `payload`/`documentHash` are nullable — a legacy row can have no stored
///   file and hence no hash, and an absent payload is a *screen* decision
///   (draw nothing), not a crash.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'certificate_qr.freezed.dart';

@freezed
abstract class CertificateQr with _$CertificateQr {
  const factory CertificateQr({
    required String certificateId,
    required String certificateNo,
    required String verifyCode,
    String? verifyUrl,
    String? payload,
    String? documentHash,
    required String status,
    bool? valid,
    required String issuedAt,
  }) = _CertificateQr;
}

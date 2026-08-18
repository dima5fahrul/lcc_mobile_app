/// The issued-certificate card — `HistoryDetailPage.tsx:456-494`.
///
/// This fills B7b's `certificatePanel` seam. The **card chrome** (`bg-white
/// rounded-2xl p-5 border-gray-100`, `:457`) is B7b's `HistoryDetailCard` and
/// is applied at the call site in `history_detail_page.dart`; what this widget
/// draws is the card's *contents*: the header line, up to four rows, and the
/// conditional note.
///
/// ## Four rows, two of them conditional (`:465-484`)
///
/// | Row | Glyph | Value | Rendered when |
/// | --- | --- | --- | --- |
/// | Certificate number | `Hash` | `certificate?.certificate_no ?? detail.certificate_no ?? "—"` | always |
/// | Issued on | `Calendar` | `formatDate(certificate?.issued_at ?? detail.issued_at, lang)` | always |
/// | Verification code | `ShieldCheck` | `certificate.verify_code` | the code is non-empty |
/// | QR payload | `QrCode` | `certificate.qr_payload` | the payload is non-empty |
///
/// The last two gate on **JavaScript truthiness**, so an empty string behaves
/// as absent (`B5-AC-84`).
///
/// ## The note is a THREE-state gate, not two
///
/// `:486` is `!certificate && !certListQuery.loading` — while the list is still
/// in flight the note is **absent**, and only once the list has answered
/// without a match does it appear. Collapsing that to `certificate == null`
/// would show *"not available yet"* during a load, which is a sentence the
/// source does not render at that moment (`B5-AC-49`).
///
/// ## The row widget is restated here, and that is a recorded cost
///
/// `history_detail_cards.dart:281-284` made `HistoryDetailInfoRow` public
/// specifically for this card, with the note *"a private copy there would
/// drift from this one"*. **G-L7 forbids `lib/presentation/** →
/// features/*/presentation/**`**, so the import B7b anticipated is illegal and
/// the copy it warned about is the only remaining shape. The drift is not left
/// to discipline: `issued_certificate_card_test.dart` pumps both widgets and
/// asserts their tile size, tint, glyph colour and both text styles are equal,
/// so the two cannot diverge silently. Recorded in `architecture-review.md`,
/// and FU-7 proposes the row move to `lib/presentation/common/`.
library;

import 'package:flutter/material.dart';

import '../../features/application/domain/application_formatting.dart';
import '../../features/application/domain/entities/application_detail.dart';
import '../../features/documents/domain/entities/issued_certificate.dart';
import '../../i18n/i18n.dart';
import '../icons/lucide_icon.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// `w-9 h-9` — the glyph tile, the same 36 px `history_detail_cards.dart:38`
/// resolves `kInfoRowTile` to.
const double kCertificateRowTile = AppSpacing.tile36;

class IssuedCertificateCard extends StatelessWidget {
  const IssuedCertificateCard({
    super.key,
    required this.detail,
    required this.certificate,
    required this.certificateLoading,
    required this.headingLabel,
    required this.certificateNumberLabel,
    required this.issuedOnLabel,
    required this.verificationCodeLabel,
    required this.qrPayloadLabel,
    required this.notAvailableLabel,
    required this.lang,
  });

  final ApplicationDetail detail;
  final IssuedCertificate? certificate;

  /// `certListQuery.loading` — a **separate** parameter, not folded into a
  /// nullable certificate. See the library doc.
  final bool certificateLoading;

  /// The six strings, resolved by the caller. Passing them in rather than
  /// calling `.tr()` here keeps this widget pumpable without an
  /// `EasyLocalization` ancestor, which is how every other seam widget in this
  /// tree is written.
  final String headingLabel;
  final String certificateNumberLabel;
  final String issuedOnLabel;
  final String verificationCodeLabel;
  final String qrPayloadLabel;
  final String notAvailableLabel;

  final Lang lang;

  @override
  Widget build(BuildContext context) {
    final IssuedCertificate? cert = certificate;
    final String languageCode = lang == Lang.lo ? kLaoCode : 'en';

    // `certificate?.certificate_no ?? detail.certificate_no ?? "—"` — `:468`.
    // Nullish, not `||`: an empty string on either side is kept, not skipped.
    final String number =
        cert?.certificateNo ?? detail.row.certificateNo ?? kAbsentDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const LucideIcon(
              name: 'ShieldCheck',
              size: AppSpacing.gap16,
              // `#16A34A` — `:459`. `trackingDone` carries exactly that value
              // (`app_colors.dart:772`) and is the tree's token for a completed
              // step, which is what an issued certificate is.
              color: AppColors.trackingDone,
            ),
            const SizedBox(width: AppSpacing.gap8),
            Flexible(
              child: Text(
                headingLabel,
                style: const TextStyle(
                  fontSize: AppTypography.size14,
                  fontWeight: AppTypography.semiBold,
                  color: AppColors.gray800,
                ),
              ),
            ),
          ],
        ),
        // `mb-4` — `:458`.
        const SizedBox(height: AppSpacing.gap16),

        // `grid-cols-1 sm:grid-cols-2 gap-4`. One column at a phone width, so
        // the rows stack with the grid's own `gap-4` between them.
        CertificateInfoRow(
          glyph: 'Hash',
          label: certificateNumberLabel,
          value: number,
        ),
        const SizedBox(height: AppSpacing.gap16),
        CertificateInfoRow(
          glyph: 'Calendar',
          label: issuedOnLabel,
          // `formatDate(certificate?.issued_at ?? detail.issued_at, lang)` —
          // `:473`.
          value: formatApplicationDate(
            cert?.issuedAt ?? detail.row.issuedAt,
            languageCode,
          ),
        ),
        if (cert != null && cert.hasVerifyCode) ...<Widget>[
          const SizedBox(height: AppSpacing.gap16),
          CertificateInfoRow(
            glyph: 'ShieldCheck',
            label: verificationCodeLabel,
            value: cert.verifyCode,
          ),
        ],
        if (cert != null && cert.hasQrPayload) ...<Widget>[
          const SizedBox(height: AppSpacing.gap16),
          CertificateInfoRow(
            glyph: 'QrCode',
            label: qrPayloadLabel,
            value: cert.qrPayload!,
          ),
        ],

        // `!certificate && !certListQuery.loading` — `:486`.
        if (cert == null && !certificateLoading) ...<Widget>[
          // `mt-3` — `:487`.
          const SizedBox(height: AppSpacing.gap12),
          Text(
            notAvailableLabel,
            style: const TextStyle(
              fontSize: AppTypography.size12,
              color: AppColors.gray400Inline,
            ),
          ),
        ],
      ],
    );
  }
}

/// `InfoRow` — `HistoryDetailPage.tsx:662-685`.
///
/// A restatement of `HistoryDetailInfoRow`, forced by G-L7; see the library
/// doc. Every token below is the same one that widget uses, and a test holds
/// the two together.
class CertificateInfoRow extends StatelessWidget {
  const CertificateInfoRow({
    super.key,
    required this.glyph,
    required this.label,
    required this.value,
  });

  final String glyph;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: kCertificateRowTile,
          height: kCertificateRowTile,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: LucideIcon(
            name: glyph,
            size: AppSpacing.gap16,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.gap12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppTypography.size12,
                  color: AppColors.muted,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: AppTypography.size14,
                  fontWeight: AppTypography.medium,
                  height: AppTypography.lineSnug,
                  color: AppColors.gray800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

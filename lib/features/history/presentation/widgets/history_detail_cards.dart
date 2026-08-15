/// The three remaining B7-owned regions — the rejection note (`:441-453`), the
/// attachments card (`:589-628`) and the application-info card (`:631-643`).
///
/// ## The attachment ROWS are not shipped, and that is § 10's decision, not mine
///
/// § 6.14 put three options to § 10: add `url_launcher` and open `file_url`
/// externally; render rows with an inert tap; or omit the rows and keep the
/// empty state. It recommended the first and ruled the second out by name as a
/// silent divergence — *"visually identical, functionally dead, invisible to
/// all four tiers"*.
///
/// **§ 10 did not approve `url_launcher`.** Its "What this approval is not"
/// paragraph names it: the approval *"does not authorise … `url_launcher`
/// (decision 2 above)"*, and the three-decision list above it records decision 2
/// as unanswered. § 6.14's instruction for that outcome is explicit — B7b takes
/// **the third option**, and *"the implementer may not choose between these"*.
///
/// So: [HistoryDetailAttachments] renders the card, the heading and the empty
/// copy unconditionally, and renders **no rows at all** even when the payload
/// carries attachments. That is a visible, deliberate gap, reported as
/// `B7-AC-71` NOT EVALUATED with this reason rather than passed. It is not the
/// inert-row option wearing a different hat: an inert row would *look* complete.
///
/// `Attachment.displayName` and `Attachment.sizeKb` (the `max(1, …)` clamp) are
/// already built and unit-tested on the entity, so B5 or a follow-up adds the
/// rows without re-deriving either.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import 'history_detail_palette.dart';
import 'history_panels.dart';

/// `w-9 h-9` — the info-row glyph tile (`:674`).
const double kInfoRowTile = AppSpacing.tile36;

/// The shared white card chrome — `bg-white rounded-2xl p-5 border-gray-100`.
class HistoryDetailCard extends StatelessWidget {
  const HistoryDetailCard({
    super.key,
    required this.child,
    this.borderColour = AppColors.gray100,
    this.padded = true,
  });

  final Widget child;

  /// The rejection card is the one exception — `border-red-100` (`:442`).
  final Color borderColour;

  /// The rejection card draws its own header band edge-to-edge, so it opts out
  /// of the card's own padding.
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padded ? const EdgeInsets.all(AppSpacing.gap20) : null,
      clipBehavior: padded ? Clip.none : Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        border: Border.all(color: borderColour),
      ),
      child: child,
    );
  }
}

/// `bucket === "rejected" && detail.reason_note` — `:441-453`.
///
/// **Both halves are the caller's** (`ApplicationDetail.showsRejectionNote`),
/// including the falsy-on-empty second one: a `reason_note: ""` renders no card
/// rather than an empty red panel (`B7-AC-59`).
class HistoryDetailRejection extends StatelessWidget {
  const HistoryDetailRejection({
    super.key,
    required this.title,
    required this.reason,
  });

  /// `t("whyRejected")`.
  final String title;

  /// `detail.reason_note`, verbatim.
  final String reason;

  @override
  Widget build(BuildContext context) {
    return HistoryDetailCard(
      // `border-red-100` — Tailwind v3 `red-100` is `#FEE2E2`, the same value
      // the rejected bucket's tint carries. NOT `dangerBorder` (`#FCA5A5`,
      // `red-300`), which is the list badge's ring and one ramp step darker.
      borderColour: AppColors.categoryTintHealth,
      padded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // `px-5 py-3 bg-[#FEF2F2]` (`:443`).
          Container(
            width: double.infinity,
            color: AppColors.dangerSoft,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gap20,
              vertical: AppSpacing.gap12,
            ),
            child: Row(
              children: <Widget>[
                const LucideGlyph(
                  name: 'AlertOctagon',
                  size: AppSpacing.gap16,
                  colour: AppColors.danger,
                ),
                const SizedBox(width: AppSpacing.gap8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppTypography.size14,
                      fontWeight: AppTypography.semiBold,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gap20),
            child: Text(
              reason,
              style: const TextStyle(
                fontSize: AppTypography.size14,
                height: AppTypography.lineRelaxed,
                color: AppColors.gray700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The attachments card — `:589-628`, **empty state only**. See the library doc.
class HistoryDetailAttachments extends StatelessWidget {
  const HistoryDetailAttachments({
    super.key,
    required this.title,
    required this.emptyLabel,
  });

  /// The lifted `attachments` key (§ 6.11).
  final String title;

  /// The lifted `attachmentsEmpty` key — `"No files are attached to this
  /// case."` / `"ບໍ່ມີເອກະສານແນບໃນຄຳຮ້ອງນີ້."` (`:598`).
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return HistoryDetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              // `Paperclip` has no asset — `history_detail_palette.dart`.
              const Icon(
                kDetailAttachmentsIcon,
                size: AppSpacing.gap16,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.gap8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTypography.size14,
                    fontWeight: AppTypography.semiBold,
                    color: AppColors.gray800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.gap16),
          Text(
            emptyLabel,
            style: const TextStyle(
              fontSize: AppTypography.size14,
              color: AppColors.gray400Inline,
            ),
          ),
        ],
      ),
    );
  }
}

/// The application-info card — `:631-643`. Four rows, all always present.
class HistoryDetailInfo extends StatelessWidget {
  const HistoryDetailInfo({
    super.key,
    required this.title,
    required this.referenceLabel,
    required this.referenceValue,
    required this.submittedLabel,
    required this.submittedValue,
    required this.officeLabel,
    required this.officeValue,
    required this.feeLabel,
    required this.feeValue,
  });

  final String title;
  final String referenceLabel;
  final String referenceValue;
  final String submittedLabel;

  /// `formatDateTime(detail.submitted_at ?? detail.created_at, lang)` — `:638`.
  final String submittedValue;
  final String officeLabel;

  /// `[district_name, province_name].filter(Boolean).join(" · ") || "—"` —
  /// `:252-253`, resolved on the entity so the `"—"` fallback has one home.
  final String officeValue;
  final String feeLabel;

  /// `formatLak(detail.fee_lak, lang)` — `:641`.
  final String feeValue;

  @override
  Widget build(BuildContext context) {
    return HistoryDetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: AppTypography.size14,
              fontWeight: AppTypography.semiBold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: AppSpacing.gap16),
          HistoryDetailInfoRow(
            glyph: 'Hash',
            label: referenceLabel,
            value: referenceValue,
          ),
          const SizedBox(height: AppSpacing.gap16),
          HistoryDetailInfoRow(
            glyph: 'Calendar',
            label: submittedLabel,
            value: submittedValue,
          ),
          const SizedBox(height: AppSpacing.gap16),
          HistoryDetailInfoRow(
            glyph: 'Building2',
            label: officeLabel,
            value: officeValue,
          ),
          const SizedBox(height: AppSpacing.gap16),
          HistoryDetailInfoRow(
            glyph: 'Coins',
            label: feeLabel,
            value: feeValue,
          ),
        ],
      ),
    );
  }
}

/// `InfoRow` — `:662-685`. A 36 px glyph tile, a small grey label and the value.
///
/// Public because the B5 `certificatePanel` seam's four rows are the same
/// widget (`:465-484`), and a private copy there would drift from this one.
class HistoryDetailInfoRow extends StatelessWidget {
  const HistoryDetailInfoRow({
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
          width: kInfoRowTile,
          height: kInfoRowTile,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: LucideGlyph(
            name: glyph,
            size: AppSpacing.gap16,
            colour: AppColors.primary,
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

/// The *View document* / *Download document* pair —
/// `HistoryDetailPage.tsx:379-397`.
///
/// This is what fills B7b's `documentActions` seam. It arrives at the hero as
/// **one** `Widget` because that is the shape B7b declared
/// (`history_detail_hero.dart:109`, `:183`), so the two buttons are a `Wrap`
/// with the hero's own `gap-2` spacing and the source's order is preserved
/// inside it: *View · Download*, then B6's *Pay*, then *Refresh* and
/// *Contact officer* (`B5-AC-48`).
///
/// ## It builds its own `DocSpec`, and that is why the seam is a builder
///
/// `:247` is `docSpecFromApplication(detail, certificate, lang)` — a function
/// of the payload. A pre-built `Widget?` could not see `detail`, which is
/// specs.md Finding J and the reason § 6.7 retypes the two B5 seams. The
/// builder in `app_routes.dart` supplies `detail` and `certificate`; the
/// `lang` comes from the ambient locale here, where a widget can watch it.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../features/application/domain/entities/application_detail.dart';
import '../../features/documents/domain/doc_spec_mappers.dart';
import '../../features/documents/domain/entities/doc_spec.dart';
import '../../features/documents/domain/entities/issued_certificate.dart';
import '../../i18n/i18n.dart';
import '../icons/lucide_icon.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'document_page_painter.dart' show renderDocumentPdf;
import 'document_viewer.dart';

/// The `history` namespace, written out rather than imported.
///
/// `kHistoryNs` lives in `features/history/presentation/widgets/history_labels.dart`
/// and **G-L7 forbids `lib/presentation/** → features/*/presentation/**`**, so
/// importing it here is not an option. The two keys below are B5's own
/// additions to that namespace (specs.md § 6.12) and `B5-AC-89` asserts the
/// namespace gains exactly them.
const String _historyNs = 'history';

class DocumentActionsRow extends StatelessWidget {
  const DocumentActionsRow({
    super.key,
    required this.detail,
    required this.certificate,
    this.saveFile = saveDocumentFile,
  });

  /// The open case. Supplied by the builder, because the spec below is a
  /// function of it.
  final ApplicationDetail detail;

  /// `certFromList ?? certOneQuery.data` — null until the third query resolves,
  /// and permanently null when neither source has one.
  final IssuedCertificate? certificate;

  /// Threaded through to the viewer and used by *Download* directly, so a
  /// widget test can drive a completed and a cancelled save (`B5-AC-83`).
  final DocumentSaver saveFile;

  /// `${serviceName} · ${detail.reference_no}` — `:246`.
  String _title(Lang lang) =>
      '${text(detail.row.serviceName, lang)} · ${detail.row.referenceNo}';

  /// `${detail.reference_no}.pdf` — `:259` and `:652`, the same string on both
  /// the button and the viewer (`B5-AC-81`).
  String get _downloadName => '${detail.row.referenceNo}.pdf';

  /// `handleDownload` — `:255-265`. The web creates an object URL, clicks a
  /// synthetic `<a download>` and revokes after 4 s; the mobile counterpart is
  /// the platform save dialog. It renders **nothing** on either outcome,
  /// because the browser renders nothing (`B5-AC-83`, GG-4).
  Future<void> _download(Lang lang) async {
    final DocSpec spec = docSpecFromApplication(detail, certificate, lang);
    await saveFile(fileName: _downloadName, bytes: await renderDocumentPdf(spec));
  }

  @override
  Widget build(BuildContext context) {
    final Lang lang = Lang.fromCode(context.locale.languageCode);
    final DocSpec spec = docSpecFromApplication(detail, certificate, lang);

    return Wrap(
      spacing: AppSpacing.gap8,
      runSpacing: AppSpacing.gap8,
      children: <Widget>[
        // `bg-[#344EAD] text-white font-semibold` — `:381-388`.
        _PrimaryButton(
          label: '$_historyNs.viewDocument'.tr(context: context),
          glyph: 'Eye',
          onTap: () => showDocumentViewer(
            context,
            title: _title(lang),
            spec: spec,
            downloadName: _downloadName,
            verifyCode: certificate?.verifyCode,
            qrPayload: certificate?.qrPayload,
            saveFile: saveFile,
          ),
        ),
        // `border border-gray-200 text-gray-700 font-medium` — `:389-395`. The
        // same chrome `history_detail_hero.dart`'s `_SecondaryButton` draws for
        // *Refresh* and *Contact officer*; that one is private to B7b's widget
        // file and G-L7 puts it out of reach, so the shape is restated here and
        // `document_actions_row_test.dart` pins the tokens against it.
        _SecondaryButton(
          label: '$_historyNs.downloadDocument'.tr(context: context),
          glyph: 'Download',
          onTap: () => _download(lang),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.glyph,
    required this.onTap,
  });

  final String label;
  final String glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gap16,
          vertical: AppSpacing.gap10,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LucideIcon(
              name: glyph,
              size: AppSpacing.gap16,
              color: AppColors.white,
            ),
            const SizedBox(width: AppSpacing.gap8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppTypography.size14,
                  fontWeight: AppTypography.semiBold,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.glyph,
    required this.onTap,
  });

  final String label;
  final String glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gap16,
          vertical: AppSpacing.gap10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LucideIcon(
              name: glyph,
              size: AppSpacing.gap16,
              color: AppColors.gray700,
            ),
            const SizedBox(width: AppSpacing.gap8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppTypography.size14,
                  fontWeight: AppTypography.medium,
                  color: AppColors.gray700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

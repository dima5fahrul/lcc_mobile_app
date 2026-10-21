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

// `hide State` — dartz's State monad would shadow Flutter's and break the
// `extends State<CertificateFileActions>` below.
import 'package:dartz/dartz.dart' hide State;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/error/failure.dart';
import '../../features/application/domain/entities/application_detail.dart';
import '../../features/documents/domain/certificate_pdf_io.dart';
import '../../features/documents/domain/doc_spec_mappers.dart';
import '../../features/documents/domain/entities/certificate_file.dart';
import '../../features/documents/domain/entities/certificate_file_download.dart';
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

    // The v2 mount — Task 6: when the certificate carries `files[]`, the
    // server-PDF pair renders beneath the legacy faux-PDF pair. Legacy rows
    // (no `files[]`) render nothing here and the row above is byte-identical
    // to what B5 shipped; `history_detail_page.dart` is untouched because the
    // certificate is already in scope at this seam.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
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
        ),
        CertificateFileActions(certificate: certificate),
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

/// The **server-PDF** actions — one *View* / *Download* pair per entry of the
/// certificate's `files[]` (MOBILE-API-E-CERTIFICATES.md, 2026-10, § Citizen
/// endpoints, File).
///
/// ## Why it lives in this file, not its own
///
/// `B5-AC-17` pins `lib/presentation/documents/` at **exactly four files** and
/// `documents_scope_test.dart` is another task's surface this round — so the
/// fifth widget is co-located here as a distinct public class with its own
/// test file. The deviation is recorded in the task report.
///
/// ## The gate is `hasStoredFile`, and the legacy path stays
///
/// Legacy rows send no `files[]`; for them this renders nothing and the
/// faux-PDF pair above keeps working exactly as B5 shipped it
/// (`renderDocumentPdf`/`DocSpec` untouched). A v2 row gets BOTH: the legacy
/// pair (the painter's rendering of the case) and this pair (the server's own
/// PDF), because the two answer different questions and neither subsumes the
/// other.
///
/// ## Every edge is injected, with the production default in the domain file
///
/// `fetchStoredFile` defaults to `fetchStoredCertificateFile` (Task 2's
/// `DownloadCertificateFile` through the documents container — resolved in
/// `certificate_pdf_io.dart`, because this widget is G-L5-blind to every
/// locator), `openPdf`/`savePdf` to `openPdfBytes`/`savePdfBytes`. Tests
/// inject recorders; no platform channel ever starts.
///
/// ## The integrity gate
///
/// Before either sink runs: `sha256Header` non-empty and different from the
/// downloaded bytes → `verify.integrityFailed` snackbar, and **nothing** is
/// opened or saved. An empty header is absence (a legacy fingerprint), not
/// mismatch, and passes. A fetch `Failure` surfaces the server's own sentence
/// the same way — the guide's 404 "certificate file not found" is copy, not a
/// crash.
class CertificateFileActions extends StatefulWidget {
  const CertificateFileActions({
    super.key,
    required this.certificate,
    this.fetchStoredFile = fetchStoredCertificateFile,
    this.openPdf = openPdfBytes,
    this.savePdf = savePdfBytes,
  });

  final IssuedCertificate? certificate;

  final CertificateFileFetcher fetchStoredFile;
  final CertificatePdfOpener openPdf;
  final CertificatePdfSaver savePdf;

  @override
  State<CertificateFileActions> createState() => CertificateFileActionsState();
}

class CertificateFileActionsState extends State<CertificateFileActions> {
  bool _busy = false;

  Future<void> _run({
    required CertificateFile file,
    required bool inline,
  }) async {
    if (_busy) return;
    _busy = true;
    // Both strings are resolved BEFORE the first await: `context` is never
    // read across an async gap (use_build_context_synchronously), and the
    // messenger is captured for the same reason.
    final String integrityFailed =
        'verify.integrityFailed'.tr(context: context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final Either<Failure, CertificateFileDownload> result =
          await widget.fetchStoredFile(
        id: widget.certificate!.id,
        layout: file.layout,
        inline: inline,
      );

      final CertificateFileDownload? download = result.fold(
        (Failure failure) {
          messenger.showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
          return null;
        },
        (CertificateFileDownload d) => d,
      );
      if (download == null) return;

      // The integrity gate — before ANY sink. `sha256Matches` already treats
      // an empty header as absence.
      if (!sha256Matches(download.bytes, download.sha256Header)) {
        messenger.showSnackBar(
          SnackBar(content: Text(integrityFailed)),
        );
        return;
      }

      // The Content-Disposition filename, with the guide's fallback.
      final String fileName = (download.fileName != null &&
              download.fileName!.isNotEmpty)
          ? download.fileName!
          : '${widget.certificate!.certificateNo}-${file.layout}.pdf';

      if (inline) {
        await widget.openPdf(download.bytes, fileName);
      } else {
        await widget.savePdf(download.bytes, fileName);
      }
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final IssuedCertificate? cert = widget.certificate;
    if (cert == null || !cert.hasStoredFile) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < cert.files.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.gap8),
          Wrap(
            spacing: AppSpacing.gap8,
            runSpacing: AppSpacing.gap8,
            children: <Widget>[
              _PrimaryButton(
                // The history namespace's own pair — the same copy the
                // legacy row renders, now bound to the server PDF.
                label: '$_historyNs.viewDocument'.tr(context: context),
                glyph: 'Eye',
                onTap: () =>
                    _run(file: cert.files[i], inline: true),
              ),
              _SecondaryButton(
                label: '$_historyNs.downloadDocument'.tr(context: context),
                glyph: 'Download',
                onTap: () =>
                    _run(file: cert.files[i], inline: false),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

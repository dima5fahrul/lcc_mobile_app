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
    this.certificates = const <IssuedCertificate>[],
    this.saveFile = saveDocumentFile,
  });

  /// The open case. Supplied by the builder, because the spec below is a
  /// function of it.
  final ApplicationDetail detail;

  /// `certFromList ?? certOneQuery.data` — null until the third query resolves,
  /// and permanently null when neither source has one.
  final IssuedCertificate? certificate;

  /// **Every** certificate of this application, in the server's list order —
  /// review I-2, 2026-10-22. A divorce issues three (joint card, booklet A,
  /// booklet B) and [certificate] can name only one of them.
  ///
  /// Defaults to empty and falls back to `[certificate]` in [_rows], so a
  /// caller that knows about one certificate only — every pre-I-2 call site,
  /// and both widget tests — behaves exactly as it did.
  final List<IssuedCertificate> certificates;

  /// Threaded through to the viewer and used by *Download* directly, so a
  /// widget test can drive a completed and a cancelled save (`B5-AC-83`).
  final DocumentSaver saveFile;

  /// The rows whose server PDFs this widget offers.
  ///
  /// [certificates] when the caller supplied it; otherwise the singular
  /// [certificate], as a one-row list, which is the pre-I-2 behaviour exactly.
  List<IssuedCertificate> get _rows {
    if (certificates.isNotEmpty) return certificates;
    final IssuedCertificate? one = certificate;
    return one == null ? const <IssuedCertificate>[] : <IssuedCertificate>[one];
  }

  /// Whether the server holds a PDF for **any** row of this case.
  ///
  /// The gate that suppresses the legacy faux-PDF pair — review I-1. The spec
  /// is unambiguous about which file is authoritative (§ Overview: *"The app
  /// never draws a certificate itself; it shows or downloads the server's
  /// file, so the file's SHA-256 always matches what verification reports"*),
  /// so when a server file exists the painter's rendering must not be offered
  /// beside it under the same two labels.
  bool get _hasServerFile =>
      _rows.any((IssuedCertificate c) => c.hasStoredFile);

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
    // A local, so the null check below promotes for the certificate-bearing
    // viewer call (fields do not promote).
    final IssuedCertificate? cert = certificate;

    // ── The two mounts, and they are now EXCLUSIVE ────────────────────────
    //
    // **Review I-1, 2026-10-22.** Task 6 mounted the server-PDF pair *beneath*
    // the legacy faux-PDF pair, both reading the same two i18n keys. A
    // marriage certificate (card + booklet) therefore rendered **three**
    // identically-labelled *View document* buttons and three *Download
    // document* buttons, and the first of each was the painter's own drawing
    // of the case. A citizen who tapped the legacy *Download* got an
    // app-painted PDF; running the app's own *Check a PDF file* flow on it
    // answered `not-found`, i.e. the app told them a file it had just produced
    // was "not an issued document, or it was changed".
    //
    // So: when the server holds a file for any row of this case, that file is
    // the only one offered (§ Overview makes the server's PDF the single
    // source of truth), and the legacy pair is gone. A legacy certificate — no
    // `files[]`, the file endpoint answers 404 — keeps the painter pair,
    // byte-identical to what B5 shipped, because it is the only document that
    // case has.
    if (_hasServerFile) {
      return CertificateFileActions(
        certificate: certificate,
        certificates: _rows,
      );
    }

    return Wrap(
      spacing: AppSpacing.gap8,
      runSpacing: AppSpacing.gap8,
      children: <Widget>[
        // `bg-[#344EAD] text-white font-semibold` — `:381-388`. When a
        // certificate is in scope, the viewer's verification strip is
        // mounted through `CertificateQrPanel`: the v2 list item may carry
        // no `qr_payload`, and the panel conditionally fetches the
        // endpoint's payload instead of silently rendering nothing.
        _PrimaryButton(
          label: '$_historyNs.viewDocument'.tr(context: context),
          glyph: 'Eye',
          onTap: () => cert == null
              ? showDocumentViewer(
                  context,
                  title: _title(lang),
                  spec: spec,
                  downloadName: _downloadName,
                  saveFile: saveFile,
                )
              : showDocumentViewerWithCertificateQr(
                  context,
                  title: _title(lang),
                  spec: spec,
                  downloadName: _downloadName,
                  certificate: cert,
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
/// Legacy rows send no `files[]`; for them this renders nothing and
/// [DocumentActionsRow] falls back to the faux-PDF pair, exactly as B5 shipped
/// it (`renderDocumentPdf`/`DocSpec` untouched).
///
/// **Review I-1, 2026-10-22 — a v2 row no longer gets both.** It used to, on
/// the reasoning that the painter's drawing of the case and the server's PDF
/// "answer different questions". They do not answer different questions to a
/// citizen looking at two buttons with the same words on them, and the
/// painter's file fails the app's own document-hash check (§ Checking a PDF on
/// the device). The server's file is the only one offered when it exists; see
/// [DocumentActionsRow.build].
///
/// ## Every button says WHICH document it is
///
/// One pair per `files[]` entry was already right; what was missing was any
/// way to tell the pairs apart. Each button now carries its layout —
/// *View document · Card*, *View document · Booklet* — from the
/// `verify.fileCheck.layout*` keys that already exist in both locales for the
/// PDF-check screen's own layout line. And when a case has more than one
/// certificate **row** (a divorce: joint card, booklet A, booklet B), each
/// row's block is headed by its `document_type` and `copy`, which is the
/// spec's own labelling instruction (§ Divorce, and the implementation
/// checklist's first item). A single-row case renders no heading, because
/// there is nothing to distinguish it from.
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
    this.certificates = const <IssuedCertificate>[],
    this.fetchStoredFile = fetchStoredCertificateFile,
    this.openPdf = openPdfBytes,
    this.savePdf = savePdfBytes,
  });

  final IssuedCertificate? certificate;

  /// Every certificate row of the case — review I-2. Empty means "just
  /// [certificate]", which is every pre-I-2 call site and both widget tests.
  final List<IssuedCertificate> certificates;

  final CertificateFileFetcher fetchStoredFile;
  final CertificatePdfOpener openPdf;
  final CertificatePdfSaver savePdf;

  /// The rows this widget renders, in the server's list order.
  List<IssuedCertificate> get rows {
    if (certificates.isNotEmpty) return certificates;
    final IssuedCertificate? one = certificate;
    return one == null ? const <IssuedCertificate>[] : <IssuedCertificate>[one];
  }

  @override
  State<CertificateFileActions> createState() => CertificateFileActionsState();
}

class CertificateFileActionsState extends State<CertificateFileActions> {
  bool _busy = false;

  Future<void> _run({
    required IssuedCertificate certificate,
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
        id: certificate.id,
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
          : '${certificate.certificateNo}-${file.layout}.pdf';

      if (inline) {
        await widget.openPdf(download.bytes, fileName);
      } else {
        await widget.savePdf(download.bytes, fileName);
      }
    } finally {
      _busy = false;
    }
  }

  /// `card` → *Card*, `booklet` → *Booklet*, anything else → the server's own
  /// word.
  ///
  /// The two keys are `verify.fileCheck.layoutCard` / `layoutBooklet`, already
  /// in both locales for `verify_file_check_page.dart`'s layout line — the
  /// same fact ("which of this certificate's files this is") read on a
  /// different screen, so the same words. The `layout` set is open (§
  /// Certificate model's table grows by row), hence the verbatim fallback
  /// rather than a `default:` label that would mislabel a new layout.
  String _layoutLabel(BuildContext context, String layout) {
    switch (layout) {
      case 'card':
        return 'verify.fileCheck.layoutCard'.tr(context: context);
      case 'booklet':
        return 'verify.fileCheck.layoutBooklet'.tr(context: context);
      default:
        return layout;
    }
  }

  /// `document_type` + `copy`, as the spec labels a divorce's three documents:
  /// *"`""` joint card, `A` husband's booklet, `B` wife's booklet"*
  /// (§ Divorce).
  ///
  /// Empty when there is nothing to say — no `document_type` and no `copy`, as
  /// on every legacy row — and the caller then renders no heading at all
  /// rather than an empty line.
  String _rowLabel(BuildContext context, IssuedCertificate certificate) {
    final List<String> parts = <String>[
      if (certificate.documentType.isNotEmpty) certificate.documentType,
      switch (certificate.copy) {
        'A' => 'verify.copy.a'.tr(context: context),
        'B' => 'verify.copy.b'.tr(context: context),
        // `''` is the joint card, but ONLY when there is a sibling row to be
        // joint with — a single-row case never reaches this method.
        '' => 'verify.copy.joint'.tr(context: context),
        // The open set again: a copy marker this build has not been told
        // about is shown as the server wrote it.
        final String other => other,
      },
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final List<IssuedCertificate> rows = widget.rows
        .where((IssuedCertificate c) => c.hasStoredFile)
        .toList(growable: false);
    if (rows.isEmpty) return const SizedBox.shrink();

    // One heading per row only when there is more than one row to tell apart
    // (review I-2). A single-document application renders exactly what it did
    // before this change.
    final bool heading = rows.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int r = 0; r < rows.length; r++) ...<Widget>[
          if (r > 0) const SizedBox(height: AppSpacing.gap12),
          if (heading) ...<Widget>[
            Text(
              _rowLabel(context, rows[r]),
              style: const TextStyle(
                fontSize: AppTypography.size12,
                fontWeight: AppTypography.semiBold,
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(height: AppSpacing.gap4),
          ],
          for (int i = 0; i < rows[r].files.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.gap8),
            Wrap(
              spacing: AppSpacing.gap8,
              runSpacing: AppSpacing.gap8,
              children: <Widget>[
                _PrimaryButton(
                  // The history namespace's own pair, qualified by which of
                  // this row's files it opens — review I-1. Without the
                  // layout a marriage row drew two buttons a citizen could
                  // not choose between.
                  label: '${'$_historyNs.viewDocument'.tr(context: context)}'
                      ' · ${_layoutLabel(context, rows[r].files[i].layout)}',
                  glyph: 'Eye',
                  onTap: () => _run(
                    certificate: rows[r],
                    file: rows[r].files[i],
                    inline: true,
                  ),
                ),
                _SecondaryButton(
                  label:
                      '${'$_historyNs.downloadDocument'.tr(context: context)}'
                      ' · ${_layoutLabel(context, rows[r].files[i].layout)}',
                  glyph: 'Download',
                  onTap: () => _run(
                    certificate: rows[r],
                    file: rows[r].files[i],
                    inline: false,
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

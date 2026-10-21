/// `DocumentViewer` — `lcc-app/src/app/components/DocumentViewer.tsx` (174
/// lines), of which **two of five render branches survive** (specs.md § 6.4).
///
/// ## What is NOT here, and why each absence is deliberate
///
/// `useQuery` with `enabled: false` initialises `loading` to `false`
/// (`hooks.ts:46`) and its effect returns before issuing anything (`:58-61`).
/// Neither mount site passes `documentId`, so in the shipped web app `loading`
/// is permanently false, `error` permanently undefined and `url` never empty.
/// Three of the component's five branches therefore **cannot render**:
///
/// | Branch | Source | Ported? |
/// | --- | --- | --- |
/// | Skeleton + `tc("loading")` | `:111-120` | **no** — `B5-AC-77` |
/// | Error card + *Try again* | `:121-134` | **no** — `B5-AC-78` |
/// | The document itself | `:135-136` | yes |
/// | "not available to view yet" | `:137-146` | **no** — `B5-AC-79` |
/// | Verification-code footer | `:150-171` | yes, gated as the source gates it |
///
/// Under `ssd.md` § 11.2 L-10 corollary (b) — *a port must not degrade better
/// than the source either* — porting any of the three would be a MAJOR fidelity
/// defect, not thoroughness.
///
/// It also performs **no network call and holds no BLoC** (`B5-AC-80`): it is a
/// pure function of its parameters. The `documentId` prop and the
/// single-document query behind it (`endpoints.ts:116`) are dead in the source
/// (Finding D), and the eighth prop — the pre-existing-asset URL, whose only
/// caller is `features/account/`'s deferred `openable` branch — is not ported
/// either, because porting a parameter with no call site is the same defect as
/// porting a dead endpoint (§ 6.11, `B5-AC-12`; the symbol is named in
/// specs.md § 6.4, not here, because that criterion greps for it).
///
/// ## Modality
///
/// `DialogShell` is **not** ported: B10 § 6.3 ruled it OUT OF SCOPE as a web
/// a11y polyfill whose whole payload (`role`, `aria-modal`, focus trap, scroll
/// lock, Escape, focus restore) is native to `showDialog`, and
/// `lao_id_card.dart:547-556` already shipped that disposition. The source's
/// overlay is `fixed inset-0 z-[100] flex flex-col bg-black/60` — **full
/// screen, not a centred card** — so [showDocumentViewer] opens a zero-inset
/// dialog over a `black/60` barrier (`B5-AC-85`).
///
/// Tap-outside-to-dismiss (`DialogShell.tsx:28`) is not reproduced and that is
/// not a divergence: when the dialog fills the viewport the source's own
/// barrier has zero exposed area.
///
/// ## The browser's PDF chrome has no counterpart, and none is invented
///
/// `<iframe src="blob:…pdf">` (`:136`) renders **Chrome's built-in PDF viewer**
/// — its own page navigation, print and download controls. Flutter has no such
/// chrome, so the body is a scroll view with pinch-zoom and nothing else: no
/// page counter, no print button, no second download affordance (GG-3).
library;

import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../features/documents/domain/certificate_pdf_io.dart';
import '../../features/documents/domain/entities/doc_spec.dart';
import '../../features/documents/domain/entities/issued_certificate.dart';
import '../icons/lucide_icon.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'document_page_painter.dart';

/// The `documents` i18n namespace — B5's own copy (specs.md § 6.12).
const String kDocumentsNs = 'documents';

/// Saving `bytes` under `fileName`, as a parameter.
///
/// **Null means the citizen cancelled**, and the port must then render nothing
/// — no snackbar, no toast, no "saved!" confirmation — because the web has no
/// cancel state at all: the browser simply writes the file and shows nothing
/// either way (`B5-AC-83`). The same typedef seam `ResidentFilePicker`
/// (`resident_fields.dart:50`) uses, and for the same reason: it is what lets a
/// widget test drive both outcomes without a device.
typedef DocumentSaver = Future<String?> Function({
  required String fileName,
  required Uint8List bytes,
});

/// The default sink: `file_picker`, already in the tree (F1's one dependency),
/// which **requires** `bytes` on Android and iOS and invokes the platform
/// `"save"` channel with them (`file_picker_io.dart:140-161`). B5 adds no
/// dependency for this (specs.md Finding M, § 6.10).
///
/// **Neither of the two type-filter arguments is passed** — `F1-AC-44` bans
/// them repo-wide for the picker and `B5-AC-82` keeps that grep empty (which is
/// why they are not spelled out here either); there is no reason to hand a save
/// dialog an extension filter.
Future<String?> saveDocumentFile({
  required String fileName,
  required Uint8List bytes,
}) =>
    FilePicker.platform.saveFile(fileName: fileName, bytes: bytes);

/// Opens the viewer as the full-screen dialog § 6.4 rules.
Future<void> showDocumentViewer(
  BuildContext context, {
  required String title,
  required DocSpec spec,
  required String downloadName,
  String? verifyCode,
  String? qrPayload,
  DocumentSaver saveFile = saveDocumentFile,
}) =>
    showDialog<void>(
      context: context,
      // `bg-black/60` — `DocumentViewer.tsx:85`.
      barrierColor: AppColors.black.withValues(alpha: 0.6),
      builder: (BuildContext dialogContext) => Dialog(
        // `fixed inset-0` — no inset, no rounding, no card (`B5-AC-85`).
        insetPadding: EdgeInsets.zero,
        backgroundColor: AppColors.white,
        shape: const RoundedRectangleBorder(),
        clipBehavior: Clip.antiAlias,
        child: DocumentViewer(
          title: title,
          spec: spec,
          downloadName: downloadName,
          verifyCode: verifyCode,
          qrPayload: qrPayload,
          onClose: () => Navigator.of(dialogContext).pop(),
          saveFile: saveFile,
        ),
      ),
    );

/// I-1 — the certificate-bearing mount. Identical dialog chrome, but the
/// verification strip is the **conditional** [CertificateQrPanel]: when the
/// wire row carried no `qr_payload`, the panel fetches the QR endpoint's
/// payload instead of silently rendering nothing. The plain
/// [showDocumentViewer] stays for the no-certificate caller and every
/// existing test surface.
Future<void> showDocumentViewerWithCertificateQr(
  BuildContext context, {
  required String title,
  required DocSpec spec,
  required String downloadName,
  required IssuedCertificate certificate,
  DocumentSaver saveFile = saveDocumentFile,
}) =>
    showDialog<void>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.6),
      builder: (BuildContext dialogContext) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: AppColors.white,
        shape: const RoundedRectangleBorder(),
        clipBehavior: Clip.antiAlias,
        child: _CertificateViewer(
          title: title,
          spec: spec,
          downloadName: downloadName,
          certificate: certificate,
          onClose: () => Navigator.of(dialogContext).pop(),
          saveFile: saveFile,
        ),
      ),
    );

class DocumentViewer extends StatelessWidget {
  const DocumentViewer({
    super.key,
    required this.title,
    required this.spec,
    required this.downloadName,
    required this.onClose,
    this.verifyCode,
    this.qrPayload,
    this.saveFile = saveDocumentFile,
  });

  /// `${serviceName} · ${referenceNo}` — resolved by the caller (`:246`).
  final String title;

  /// **Required and non-null.** The source's `spec?` optionality existed only
  /// to arbitrate against the two omitted props, neither of which is ported
  /// (§ 6.4).
  final DocSpec spec;

  /// `${detail.reference_no}.pdf` — `:259`, `:652`. Observable, so exact
  /// (`B5-AC-81`).
  final String downloadName;

  final VoidCallback onClose;

  /// `certificate?.verify_code` — `:653`. Empty behaves as absent, because the
  /// source's gate at `:150` is JavaScript truthiness (`B5-AC-84`).
  final String? verifyCode;

  /// `certificate?.qr_payload` — `:654`.
  final String? qrPayload;

  /// Injected so a test can drive both a completed and a cancelled save.
  final DocumentSaver saveFile;

  bool get _hasCode => verifyCode != null && verifyCode!.isNotEmpty;

  bool get _hasPayload => qrPayload != null && qrPayload!.isNotEmpty;

  Future<void> _download() async {
    final Uint8List bytes = await renderDocumentPdf(spec);
    // The return value is deliberately discarded: a completed save renders
    // nothing and a cancelled one renders nothing, because the browser renders
    // nothing in either case (`B5-AC-83`).
    await saveFile(fileName: downloadName, bytes: bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        _Header(
          title: title,
          downloadLabel: 'common.download'.tr(context: context),
          closeLabel: 'common.close'.tr(context: context),
          onDownload: _download,
          onClose: onClose,
        ),
        // `flex-1 overflow-auto bg-gray-200 flex items-center justify-center`
        // — `:110`.
        Expanded(
          child: ColoredBox(
            color: AppColors.gray200,
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: FittedBox(
                  child: SizedBox(
                    width: kDocImgW,
                    height: kDocImgH,
                    child: CustomPaint(
                      painter: DocumentPagePainter(spec: spec),
                      // Labelled so a widget test can assert the page is on
                      // screen without reaching for a private type.
                      child: Semantics(
                        label: 'document-page',
                        container: true,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_hasCode)
          _VerificationStrip(
            label: '$kDocumentsNs.verificationCode'.tr(context: context),
            code: verifyCode!,
            // `payload &&` — `:164`. No label is invented for it: the source
            // renders the value beside an icon and nothing else (`B5-AC-88`).
            payload: _hasPayload ? qrPayload : null,
          ),
      ],
    );
  }
}

/// I-1 — the certificate-bearing viewer: `DocumentViewer`'s own body with
/// the conditional [CertificateQrPanel] below it. The panel renders nothing
/// when there is no code and no payload, so the "neither: no footer at all"
/// behaviour (`B5-AC-84`) is the panel's, not a second gate here.
class _CertificateViewer extends StatelessWidget {
  const _CertificateViewer({
    required this.title,
    required this.spec,
    required this.downloadName,
    required this.certificate,
    required this.onClose,
    this.saveFile = saveDocumentFile,
  });

  final String title;
  final DocSpec spec;
  final String downloadName;
  final IssuedCertificate certificate;
  final VoidCallback onClose;
  final DocumentSaver saveFile;

  Future<void> _download() async {
    final Uint8List bytes = await renderDocumentPdf(spec);
    await saveFile(fileName: downloadName, bytes: bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        _Header(
          title: title,
          downloadLabel: 'common.download'.tr(context: context),
          closeLabel: 'common.close'.tr(context: context),
          onDownload: _download,
          onClose: onClose,
        ),
        Expanded(
          child: ColoredBox(
            color: AppColors.gray200,
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: FittedBox(
                  child: SizedBox(
                    width: kDocImgW,
                    height: kDocImgH,
                    child: CustomPaint(
                      painter: DocumentPagePainter(spec: spec),
                      child: Semantics(
                        label: 'document-page',
                        container: true,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        CertificateQrPanel(
          certificate: certificate,
          // The wire payload, when the row carried one — the fast path that
          // keeps the common case fetch-free.
          qrPayload: certificate.qrPayload,
        ),
      ],
    );
  }
}

/// `:89-108` — the `#344EAD` band, the *Download* button, the close button.
class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.downloadLabel,
    required this.closeLabel,
    required this.onDownload,
    required this.onClose,
  });

  final String title;
  final String downloadLabel;
  final String closeLabel;
  final Future<void> Function() onDownload;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        color: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gap16,
          vertical: AppSpacing.gap12,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppTypography.size14,
                  fontWeight: AppTypography.semiBold,
                  color: AppColors.white,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.gap8),
            // `bg-white/15 border border-white/20 rounded-lg` — `:95`.
            InkWell(
              onTap: onDownload,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gap12,
                  vertical: AppSpacing.gap6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const LucideIcon(
                      name: 'Download',
                      size: AppSpacing.gap14,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: AppSpacing.gap6),
                    Text(
                      downloadLabel,
                      style: const TextStyle(
                        fontSize: AppTypography.size12,
                        fontWeight: AppTypography.medium,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.gap8),
            // `w-8 h-8 rounded-lg` — `:103`.
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Container(
                width: AppSpacing.gap32,
                height: AppSpacing.gap32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: LucideIcon(
                  name: 'X',
                  size: AppSpacing.gap16,
                  color: AppColors.white,
                  // `aria-label={tc("close")}` — `:102`.
                  semanticsLabel: closeLabel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `:150-171` — the verification-code strip. Rendered **only** when a code
/// exists, with the QR payload to its right **only** when one exists.
/// Named `_VerificationStrip`, not `_Footer`: `b10_scope_test.dart`'s
/// `B10-AC-47` greps `lib/**` for the identifier `Footer` and B10 § 6.2 ruled
/// the web's page `Footer` OUT OF SCOPE as unreachable on a handset. This
/// widget is the source's `:150-171` verification bar and has nothing to do
/// with that; renaming it is cheaper than widening a guard whose whole value is
/// that it is unconditional.
class _VerificationStrip extends StatelessWidget {
  const _VerificationStrip({
    required this.label,
    required this.code,
    required this.payload,
  });

  final String label;
  final String code;
  final String? payload;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gap16,
          vertical: AppSpacing.gap12,
        ),
        // `bg-white border-t border-gray-100` — `:151`. One `decoration`, not
        // a `color:` beside it: `Container` asserts when given both.
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.gray100)),
        ),
        child: Row(
          children: <Widget>[
            // `w-9 h-9 rounded-xl bg-[#EEF2FF]` — `:152-157`.
            Container(
              width: AppSpacing.tile36,
              height: AppSpacing.tile36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: const LucideIcon(
                name: 'ShieldCheck',
                size: AppSpacing.gap16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.gap12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label,
                    // `text-[11px] text-gray-500` — `:159`. Tailwind's
                    // `gray-500` is `#6B7280`, which this tree names
                    // `AppColors.muted`; `AppColors.gray500` is `#5A6472`, a
                    // measured runtime value and not this token.
                    style: const TextStyle(
                      fontSize: AppTypography.size11,
                      color: AppColors.muted,
                    ),
                  ),
                  Text(
                    code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppTypography.size14,
                      fontWeight: AppTypography.semiBold,
                      color: AppColors.gray800,
                    ),
                  ),
                ],
              ),
            ),
            if (payload != null) ...<Widget>[
              const SizedBox(width: AppSpacing.gap8),
              // `ml-auto` — pushed to the trailing edge (`:165`). The web
              // rendered the payload as TEXT beside a decorative QrCode icon;
              // the 2026-10 guide (§ Citizen endpoints, QR) upgrades the
              // certificate's own QR to the real thing — "Draw `payload` as
              // the QR on screen" — so the icon becomes a scannable
              // `QrImageView` of exactly that payload, with the text kept
              // (B5-AC-88 pins the payload text beside the mark). Payment's
              // QrPlaceholder stays decorative and untouched.
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    QrImageView(
                      data: payload!,
                      size: AppSpacing.gap40,
                      padding: EdgeInsets.zero,
                      backgroundColor: AppColors.white,
                    ),
                    const SizedBox(width: AppSpacing.gap6),
                    Flexible(
                      child: Text(
                        payload!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: AppTypography.size11,
                          color: AppColors.gray400Inline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// I-1 — the viewer's QR panel, as a **conditional** widget.
///
/// ## Why a fetch exists at all
///
/// Task 6's first cut drew `certificate.qrPayload` and nothing else. Review
/// round 1 (I-1) measured the v2 wire: the **list item**'s field
/// enumeration (`MOBILE-API-E-CERTIFICATES.md` § Citizen endpoints, List)
/// does not name `qr_payload`, so a list-sourced certificate can carry
/// `qrPayload == null` forever and the QR silently never renders. The guide's
/// own checklist says to show the certificate's QR from
/// `GET /me/certificates/{id}/qr (payload)` — Task 2 registered that use
/// case for exactly this.
///
/// The three-state gate, in order:
///
/// 1. `qrPayload` present → render it, **no fetch** (the fast path; the wire
///    row's payload is the same value the endpoint serves).
/// 2. absent but `verifyCode` non-empty → one fetch per certificate id
///    (cached in [kCertificateQrCache]), the endpoint's `payload` rendered.
/// 3. neither → nothing (the strip only ever existed beside a code).
///
/// The fetch default resolves `GetCertificateQr` from the domain file's
/// production default (`fetchCertificateQrPayload`) for the same G-L5
/// reason `CertificateFileActions` does; tests inject. A null answer draws
/// nothing — it never errors.
///
/// ## Where it mounts
///
/// `DocumentActionsRow.View` passes the whole certificate and this panel
/// renders the strip's payload branch; `DocumentViewer`'s own `_hasPayload`
/// branch (text beside the QR mark) stays byte-identical for callers that
/// hand a payload string directly.
class CertificateQrPanel extends StatefulWidget {
  const CertificateQrPanel({
    super.key,
    required this.certificate,
    this.qrPayload,
    this.fetchQr = fetchCertificateQrPayload,
  });

  /// The certificate whose QR this is — its id keys the cache, its
  /// [IssuedCertificate.hasQrPayload] is the fast path.
  final IssuedCertificate certificate;

  /// The wire payload, when the caller has one on hand.
  final String? qrPayload;

  final CertificateQrFetcher fetchQr;

  @override
  State<CertificateQrPanel> createState() => _CertificateQrPanelState();
}

/// One answer per certificate id, per app run — the payload is "fixed at
/// issue" (guide § QR), so there is nothing to invalidate. Static: the
/// cache's lifetime is the process, which a per-visit state object cannot
/// outlive usefully anyway.
final Map<String, String> kCertificateQrCache = <String, String>{};

class _CertificateQrPanelState extends State<CertificateQrPanel> {
  String? _payload;

  @override
  void initState() {
    super.initState();
    final String? wire = widget.qrPayload;
    if (wire != null && wire.isNotEmpty) {
      _payload = wire;
    } else if (widget.certificate.hasVerifyCode) {
      final String id = widget.certificate.id;
      final String? cached = kCertificateQrCache[id];
      if (cached != null) {
        _payload = cached;
      } else {
        _fetch(id);
      }
    }
  }

  Future<void> _fetch(String id) async {
    String? payload;
    try {
      payload = await widget.fetchQr(id);
    } catch (_) {
      // The QR is supplementary: a failed fetch draws nothing, it never
      // takes the viewer down (measured: an unregistered container in a
      // test tree threw out of initState and crashed the whole dialog).
      payload = null;
    }
    if (!mounted) return;
    if (payload != null) kCertificateQrCache[id] = payload;
    setState(() => _payload = payload);
  }

  @override
  Widget build(BuildContext context) {
    final String? payload = _payload;
    // `:150` gates the WHOLE footer on the code — "no code means no payload
    // either" (`B5-AC-84`). The fetch above already requires a code; this
    // gate covers the wire fast path too.
    if (payload == null || !widget.certificate.hasVerifyCode) {
      return const SizedBox.shrink();
    }
    return _VerificationStrip(
      label: '$kDocumentsNs.verificationCode'.tr(context: context),
      code: widget.certificate.verifyCode,
      // The payload IS non-null here; the strip renders the text beside the
      // QR mark exactly as the source's `:164-169` does.
      payload: payload,
    );
  }
}

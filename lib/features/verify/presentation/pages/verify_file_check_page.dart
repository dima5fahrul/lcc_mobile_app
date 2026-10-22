/// `VerifyFileCheckPage` — the on-device PDF check, § Checking a PDF on the
/// device, read as a UI contract for the four answer branches:
///
/// 1. "`status` is not `not-found` and `verify_code` equals the code being
///    viewed → 'This file matches the issued document.' `layout` tells which
///    file matched."
/// 2. "Found, but with a different `verify_code` → the file is a genuine but
///    different certificate; show its number."
/// 3. "`not-found` → 'This file is not an issued document, or it was
///    changed.'"
/// 4. "A found file whose `status` is `revoked`, `superseded` or `expired`
///    matches, but must not be accepted: show the status screen."
///
/// Branch 4 WINS over branch 1 — a revoked/superseded/expired certificate's
/// own file still hashes to its issued fingerprint (nothing about the bytes
/// changed), so the code comparison alone would call it a match; [_body]
/// checks the status set before it checks anything else, and
/// `_statusWinsOverMatch`'s three members are the guide's own three words.
///
/// "Compare by `verify_code`, not by `document_hash`: for a matched booklet
/// the response still carries the card's `document_hash`" — this file never
/// reads [VerificationResult.documentHash] at all, for exactly that reason;
/// the only field compared against [viewedVerifyCode] is `verify_code`.
///
/// ## The file never leaves the phone
///
/// [pickFile] hands back bytes already resident in memory (`file_picker`'s
/// `withData: true`); [sha256HexOfBytes] runs on them locally and only the
/// resulting 64-hex digest is given to [verifyDocumentHash]. No multipart
/// body, no file upload — "hash it on the device and send only the hash" (§
/// Checking a PDF on the device, opening sentence).
///
/// ## No type filter on the picker (R-21 / F1-AC-44)
///
/// `FileType.custom` and `allowedExtensions` are banned repo-wide
/// (`resident_fields.dart`'s own citation); a citizen who points this picker
/// at a `.jpg` is not stopped by the client — the server's hash lookup is
/// the only judge of whether the bytes are an issued certificate.
///
/// ## No locator read (G-L5)
///
/// [pickFile] and [verifyDocumentHash] are constructor parameters with
/// production defaults — `pickVerifyFile` here (a plain `file_picker` call,
/// not a locator) and `verifyDocumentHashByHash` from
/// `verify_document_hash_io.dart` (which resolves `verifyInjection` from
/// `domain/`, where G-L5 does not reach). Nothing in this file imports
/// `di/` or names a locator.
library;

import 'dart:typed_data';

import 'package:dartz/dartz.dart' show Either;
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../../utils/routes/app_name_routes.dart';
import '../../domain/entities/verification_result.dart';
import '../../domain/verify_document_hash_io.dart';
import '../../../home/domain/home_formatting.dart' show formatDate;

/// Picking a file and getting its bytes back, as a parameter — the
/// `ResidentFilePicker` / `AvatarFilePicker` idiom (`resident_fields.dart`,
/// `avatar_picker.dart`), hoisted so a widget test can drive the whole check
/// without a platform channel. Null means the citizen cancelled: nothing
/// happens, the same as every other picker in this tree.
typedef VerifyFilePicker = Future<Uint8List?> Function();

/// The default picker: `file_picker`, **no type filter at all** (R-21).
/// `withData: true` because the hash needs the bytes, not a path — the same
/// reason `pickResidentFile` sets it for its multipart upload.
Future<Uint8List?> pickVerifyFile() async {
  final FilePickerResult? result =
      await FilePicker.platform.pickFiles(withData: true);
  return result?.files.singleOrNull?.bytes;
}

/// `status` values whose screen wins over a code match (§ Checking a PDF on
/// the device, 4th bullet) — the guide's three words, verbatim.
const Set<String> _statusWinsOverMatch = <String>{
  'revoked',
  'superseded',
  'expired',
};

class VerifyFileCheckPage extends StatefulWidget {
  const VerifyFileCheckPage({
    super.key,
    required this.viewedVerifyCode,
    this.pickFile = pickVerifyFile,
    this.verifyDocumentHash = verifyDocumentHashByHash,
  });

  /// The `verify_code` of the certificate the citizen was looking at when
  /// they tapped "Check a PDF file" — `VerifyResultPage`'s button carries it
  /// here through the route's query parameter.
  final String viewedVerifyCode;

  final VerifyFilePicker pickFile;
  final VerifyDocumentHashFetcher verifyDocumentHash;

  @override
  State<VerifyFileCheckPage> createState() => _VerifyFileCheckPageState();
}

class _VerifyFileCheckPageState extends State<VerifyFileCheckPage> {
  bool _checking = false;
  VerificationResult? _result;
  bool _notFound = false;
  String? _error;

  Future<void> _pickAndCheck() async {
    final Uint8List? bytes = await widget.pickFile();
    // Cancelled — render nothing, matching every other picker in this tree
    // (`AvatarFilePicker`'s own rule).
    if (bytes == null) return;

    setState(() {
      _checking = true;
      _result = null;
      _notFound = false;
      _error = null;
    });

    // Step 1-2 of § Checking a PDF on the device: hash the exact bytes on
    // the device. Step 3: send only the hex.
    final String hash = sha256HexOfBytes(bytes);
    final Either<Failure, VerificationResult> answer =
        await widget.verifyDocumentHash(hash);
    if (!mounted) return;

    answer.fold(
      (Failure failure) => setState(() {
        _checking = false;
        _error = failure.message;
      }),
      (VerificationResult result) => setState(() {
        _checking = false;
        if (result.status == 'not-found') {
          _notFound = true;
        } else {
          _result = result;
        }
      }),
    );
  }

  void _goBack() {
    final String code = widget.viewedVerifyCode;
    context.go(code.isEmpty
        ? AppNameRoutes.verify
        : '${AppNameRoutes.verify}/$code');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const LucideIcon(name: 'ChevronLeft'),
          onPressed: _goBack,
        ),
        title: Text(
          'verify.checkPdf'.tr(context: context),
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontFamilyFallback: AppTypography.fontFamilyFallback,
            fontSize: AppTypography.size18,
            fontWeight: AppTypography.semiBold,
            color: AppColors.gray900,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.gap16),
          children: <Widget>[
            Text(
              'verify.fileCheck.body'.tr(context: context),
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontFamilyFallback: AppTypography.fontFamilyFallback,
                fontSize: AppTypography.size14,
                color: AppColors.gray600,
              ),
            ),
            SizedBox(height: AppSpacing.gap16),
            FilledButton.icon(
              onPressed: _checking ? null : _pickAndCheck,
              icon: const LucideIcon(name: 'FileCheck2'),
              label: Text('verify.fileCheck.pick'.tr(context: context)),
            ),
            SizedBox(height: AppSpacing.gap16),
            _ResultArea(
              checking: _checking,
              error: _error,
              notFound: _notFound,
              result: _result,
              viewedVerifyCode: widget.viewedVerifyCode,
            ),
          ],
        ),
      ),
    );
  }
}

/// The part of the body that varies with the check's outcome — kept as its
/// own widget (rather than a method returning different literals inline) so
/// each branch is a `Key`-free subtree a widget test can find by its text,
/// the same granularity `VerifyResultPage`'s private status widgets have.
class _ResultArea extends StatelessWidget {
  const _ResultArea({
    required this.checking,
    required this.error,
    required this.notFound,
    required this.result,
    required this.viewedVerifyCode,
  });

  final bool checking;
  final String? error;
  final bool notFound;
  final VerificationResult? result;
  final String viewedVerifyCode;

  @override
  Widget build(BuildContext context) {
    if (checking) return const _CheckingBody();
    final String? message = error;
    if (message != null) return _ErrorBody(message: message);
    if (notFound) return const _NotIssuedBody();

    final VerificationResult? answer = result;
    if (answer == null) return const SizedBox.shrink();

    final bool sameCode = answer.verifyCode == viewedVerifyCode;
    // Branch 4 — checked FIRST, so it wins over branch 1 even though a
    // revoked/superseded/expired certificate's own file still hashes to its
    // issued fingerprint.
    if (sameCode && _statusWinsOverMatch.contains(answer.status)) {
      return _StatusWinsBody(result: answer);
    }
    if (sameCode) {
      return _MatchBody(result: answer);
    }
    // Found, different `verify_code` — branch 2.
    return _DifferentCertificateBody(result: answer);
  }
}

class _CheckingBody extends StatelessWidget {
  const _CheckingBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.gap24),
        child: Column(
          children: <Widget>[
            const CircularProgressIndicator(),
            SizedBox(height: AppSpacing.gap16),
            Text(
              // Reuses the typed-code result page's own loading copy — same
              // meaning, "a verification request is in flight".
              'verify.checking'.tr(context: context),
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontFamilyFallback: AppTypography.fontFamilyFallback,
                fontSize: AppTypography.size16,
                color: AppColors.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Branch 1, accepted: "This file matches the issued document." plus which
/// `layout` matched.
class _MatchBody extends StatelessWidget {
  const _MatchBody({required this.result});

  final VerificationResult result;

  @override
  Widget build(BuildContext context) {
    final String layoutLabel = result.layout == 'booklet'
        ? 'verify.fileCheck.layoutBooklet'.tr(context: context)
        : result.layout == 'card'
            ? 'verify.fileCheck.layoutCard'.tr(context: context)
            : result.layout; // the open set, as its own word
    return _Card(
      borderColor: AppColors.successBorder,
      backgroundColor: AppColors.successSoft,
      children: <Widget>[
        Row(
          children: <Widget>[
            const LucideIcon(name: 'BadgeCheck', color: AppColors.success),
            SizedBox(width: AppSpacing.gap8),
            Expanded(
              child: Text(
                'verify.fileCheck.matchTitle'.tr(context: context),
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontFamilyFallback: AppTypography.fontFamilyFallback,
                  fontSize: AppTypography.size16,
                  fontWeight: AppTypography.bold,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.gap8),
        Text(
          '${'verify.fileCheck.layoutLabel'.tr(context: context)}: $layoutLabel',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontFamilyFallback: AppTypography.fontFamilyFallback,
            fontSize: AppTypography.size14,
            color: AppColors.gray900,
          ),
        ),
      ],
    );
  }
}

/// Branch 2: found, genuine, but a different certificate — show its number.
class _DifferentCertificateBody extends StatelessWidget {
  const _DifferentCertificateBody({required this.result});

  final VerificationResult result;

  @override
  Widget build(BuildContext context) {
    return _Card(
      borderColor: AppColors.warningOutline,
      backgroundColor: AppColors.warningSurface,
      children: <Widget>[
        Row(
          children: <Widget>[
            const LucideIcon(name: 'AlertTriangle', color: AppColors.warning),
            SizedBox(width: AppSpacing.gap8),
            Expanded(
              child: Text(
                'verify.fileCheck.differentTitle'.tr(context: context),
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontFamilyFallback: AppTypography.fontFamilyFallback,
                  fontSize: AppTypography.size16,
                  fontWeight: AppTypography.bold,
                  color: AppColors.warningTitle,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.gap8),
        Text(
          'verify.fileCheck.differentBody'.tr(
            context: context,
            namedArgs: <String, String>{'no': result.certificateNo},
          ),
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontFamilyFallback: AppTypography.fontFamilyFallback,
            fontSize: AppTypography.size14,
            color: AppColors.gray900,
          ),
        ),
      ],
    );
  }
}

/// Branch 3: `not-found` — "This file is not an issued document, or it was
/// changed."
class _NotIssuedBody extends StatelessWidget {
  const _NotIssuedBody();

  @override
  Widget build(BuildContext context) {
    return _Card(
      borderColor: AppColors.gray300,
      backgroundColor: AppColors.gray50,
      children: <Widget>[
        Row(
          children: <Widget>[
            const LucideIcon(name: 'AlertCircle', color: AppColors.gray600),
            SizedBox(width: AppSpacing.gap8),
            Expanded(
              child: Text(
                'verify.fileCheck.notIssuedTitle'.tr(context: context),
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontFamilyFallback: AppTypography.fontFamilyFallback,
                  fontSize: AppTypography.size16,
                  fontWeight: AppTypography.bold,
                  color: AppColors.gray900,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.gap8),
        Text(
          'verify.fileCheck.notIssuedBody'.tr(context: context),
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontFamilyFallback: AppTypography.fontFamilyFallback,
            fontSize: AppTypography.size14,
            color: AppColors.gray600,
          ),
        ),
      ],
    );
  }
}

/// Branch 4: a found file whose code matches but whose `status` is
/// `revoked`, `superseded` or `expired` — the status screen, not the match
/// message. Reuses `VerifyResultPage`'s own `verify.status.*` /
/// `verify.detail.*` copy (same words for the same fact, read on a
/// different screen), and its colour/icon-per-status lookup, copied rather
/// than imported for the standing G-L3 reason `verification_wire.dart`
/// records: the pair is small, and importing a private widget across files
/// is not an option here (`_StatusHeader` is private to
/// `verify_result_page.dart`).
class _StatusWinsBody extends StatelessWidget {
  const _StatusWinsBody({required this.result});

  final VerificationResult result;

  static ({String titleKey, String icon, Color ink, Color soft, Color border})
      _lookOf(String status) {
    switch (status) {
      case 'revoked':
        return (
          titleKey: 'verify.status.revoked',
          icon: 'Shield',
          ink: AppColors.danger,
          soft: AppColors.dangerSoft,
          border: AppColors.dangerBorder,
        );
      case 'superseded':
        return (
          titleKey: 'verify.status.superseded',
          icon: 'RefreshCw',
          ink: AppColors.danger,
          soft: AppColors.dangerSoft,
          border: AppColors.dangerBorder,
        );
      default: // 'expired' — the only other member of `_statusWinsOverMatch`
        return (
          titleKey: 'verify.status.expired',
          icon: 'FileClock',
          ink: AppColors.warning,
          soft: AppColors.warningSurface,
          border: AppColors.warningOutline,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String lang =
        Localizations.localeOf(context).languageCode == 'lo' ? 'lo' : 'en';
    final ({String titleKey, String icon, Color ink, Color soft, Color border})
        look = _lookOf(result.status);

    final List<Widget> detailRows = <Widget>[
      if (result.status == 'revoked') ...<Widget>[
        if (result.revokedAt.isNotEmpty)
          _DetailLine(
            label: 'verify.detail.revokedAt'.tr(context: context),
            value: formatDate(result.revokedAt, lang),
          ),
        if (result.revokeReason.isNotEmpty)
          _DetailLine(
            label: 'verify.detail.revokeReason'.tr(context: context),
            value: result.revokeReason,
          ),
      ],
      if (result.status == 'superseded' &&
          result.replacedByCertificateNo.isNotEmpty)
        _DetailLine(
          label: 'verify.detail.replacedBy'.tr(context: context),
          value: result.replacedByCertificateNo,
        ),
      if (result.status == 'expired' &&
          result.validUntil != null &&
          result.validUntil!.isNotEmpty)
        _DetailLine(
          label: 'verify.detail.validUntil'.tr(context: context),
          value: formatDate(result.validUntil, lang),
        ),
    ];

    return _Card(
      borderColor: look.border,
      backgroundColor: look.soft,
      children: <Widget>[
        Text(
          'verify.fileCheck.statusWinsIntro'.tr(
            context: context,
            namedArgs: <String, String>{'no': result.certificateNo},
          ),
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontFamilyFallback: AppTypography.fontFamilyFallback,
            fontSize: AppTypography.size14,
            color: AppColors.gray600,
          ),
        ),
        SizedBox(height: AppSpacing.gap12),
        Row(
          children: <Widget>[
            LucideIcon(name: look.icon, color: look.ink),
            SizedBox(width: AppSpacing.gap8),
            Expanded(
              child: Text(
                look.titleKey.tr(context: context),
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontFamilyFallback: AppTypography.fontFamilyFallback,
                  fontSize: AppTypography.size18,
                  fontWeight: AppTypography.bold,
                  color: look.ink,
                ),
              ),
            ),
          ],
        ),
        for (final Widget row in detailRows) ...<Widget>[
          SizedBox(height: AppSpacing.gap8),
          row,
        ],
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _Card(
      borderColor: AppColors.dangerBorder,
      backgroundColor: AppColors.dangerSoft,
      children: <Widget>[
        Row(
          children: <Widget>[
            const LucideIcon(name: 'AlertCircle', color: AppColors.danger),
            SizedBox(width: AppSpacing.gap8),
            Expanded(
              child: Text(
                'verify.fileCheck.errorTitle'.tr(context: context),
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontFamilyFallback: AppTypography.fontFamilyFallback,
                  fontSize: AppTypography.size16,
                  fontWeight: AppTypography.bold,
                  color: AppColors.danger,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.gap8),
        // The server's own sentence, verbatim — `VerifyResultPage`'s
        // `_FailureBody` convention.
        Text(
          message,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontFamilyFallback: AppTypography.fontFamilyFallback,
            fontSize: AppTypography.size14,
            color: AppColors.gray600,
          ),
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      style: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontFamilyFallback: AppTypography.fontFamilyFallback,
        fontSize: AppTypography.size14,
        color: AppColors.gray900,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.children,
    required this.borderColor,
    required this.backgroundColor,
  });

  final List<Widget> children;
  final Color borderColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.gap16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppSpacing.gap12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

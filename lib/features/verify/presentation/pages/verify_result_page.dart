/// `VerifyResultPage` — the five status screens of § Public verification
/// endpoints, one body.
///
/// ## The screen router is the guide's own table, read literally
///
/// "Which screen to show (from `status`; `valid` is true only for `issued`)":
///
/// | `status` | Screen | Also show |
/// |---|---|---|
/// | `issued` | VALID | type, number, masked holder, issued date, `valid_until` when set, issuing office |
/// | `expired` | EXPIRED | the `valid_until` date |
/// | `revoked` | REVOKED — do not accept | `revoked_at`, `revoke_reason` |
/// | `superseded` | REPLACED — do not accept | `replaced_by_certificate_no` |
/// | `not-found` | NOT FOUND | invite to rescan or type the code |
///
/// `status` is a plain String and an **open set** (the entity's standing
/// argument): a status the guide does not name yet renders as its own word as
/// the title — not "unknown", not a crash — with the details block and the
/// checks below it, exactly as `issued` renders. `valid` is NOT consulted for
/// the title: the table routes on `status` alone, and `valid` may be
/// non-bool on a malformed answer (the entity reads it `bool?` for exactly
/// that reason).
///
/// ## "Checks, worded honestly" is enforced by what this file never says
///
/// * `signature.status: 'recorded'` renders "An officer's signature is on
///   file". The word "verified" appears nowhere in this file, and
///   `verify_result_page_test.dart` greps the rendered tree for it.
/// * `ca` / `format` / `timestamp` render only when non-empty — they "stay
///   empty until the national CA is connected".
/// * `record_hash`: `mismatch` warns and offers the PDF check; `missing`
///   explains the absence and HIDES the button ("Offer this check only when
///   `checks.record_hash.status` is not `missing`", § Checking a PDF on the
///   device); `match` states the fact and still offers the check (the guide's
///   offer rule is about `record_hash`, not about the warn).
/// * On `not-found` the checks section is not rendered at all — the answer's
///   `revocation.status` is `not-found`, which is a fact about the LOOKUP,
///   not about a certificate, and "Checks" over nothing would read as a
///   verdict.
///
/// ## Privacy
///
/// Holder names arrive masked server-side and are rendered as-is. Nothing
/// here pads, splits or restyles them: "do not try to show more" (§ Privacy).
///
/// ## No locator read (G-L5)
///
/// The bloc arrives through a `BlocProvider` the route builder created; the
/// PDF-check button navigates by path, not by resolving anything.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../i18n/i18n.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../../utils/routes/app_name_routes.dart';
import '../../domain/entities/verification_result.dart';
import '../../verify_routes.dart' show kVerifyFileCheckCodeParam;
import '../bloc/verify_bloc.dart';
// `formatDate` is the app's shared date formatter, re-exported through
// `home_formatting.dart`, which is domain-layer and therefore importable from
// a page (G-L1/G-L3 hold: this is `features/home/domain/`, not data, not
// another feature's presentation).
import '../../../home/domain/home_formatting.dart' show formatDate;

/// The `Lang` the page renders [Bilingual] fields with — the page's own
/// expression, matching the five certificate pages'
/// `Localizations.localeOf(context).languageCode == 'lo' ? Lang.lo : Lang.en`.
Lang _langOf(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'lo' ? Lang.lo : Lang.en;

class VerifyResultPage extends StatelessWidget {
  const VerifyResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: BlocConsumer<VerifyBloc, VerifyState>(
          listener: (BuildContext context, VerifyState state) {},
          builder: (BuildContext context, VerifyState state) {
            final VerificationResult? result = state.result;
            if (result != null) {
              return _ResultBody(result: result);
            }
            if (state.isLoading) {
              return _CheckingBody();
            }
            if (state.isTooManyRequests) {
              return _TooManyRequestsBody();
            }
            final String? failure = state.failure;
            if (failure != null) {
              return _FailureBody(message: failure);
            }
            return _InitialBody();
          },
        ),
      ),
    );
  }
}

// ── The five status screens ──────────────────────────────────────────────────

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.result});

  final VerificationResult result;

  @override
  Widget build(BuildContext context) {
    final bool notFound = result.status == 'not-found';
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.gap16),
      children: <Widget>[
        _StatusHeader(result: result),
        if (!notFound) ...<Widget>[
          _DetailsCard(result: result),
          SizedBox(height: AppSpacing.gap16),
          _ChecksCard(result: result),
          // The PDF-check offer: gated on record_hash != 'missing' (§ Checking
          // a PDF on the device). Task 7's page is the destination; the
          // viewed certificate's `verify_code` rides along as a query param
          // (`kVerifyFileCheckCodeParam`) so the next page can tell a match
          // from a different-certificate answer — "Compare by verify_code,
          // not by document_hash" is a comparison the destination page makes,
          // and it needs this code to make it.
          if (result.checks.recordHash.status != 'missing') ...<Widget>[
            SizedBox(height: AppSpacing.gap16),
            FilledButton.tonalIcon(
              onPressed: () => context.go(
                '${AppNameRoutes.verifyFileCheck}'
                '?$kVerifyFileCheckCodeParam='
                '${Uri.encodeComponent(result.verifyCode)}',
              ),
              icon: const LucideIcon(name: 'FileCheck2'),
              label: Text('verify.checkPdf'.tr(context: context)),
            ),
          ],
        ] else ...<Widget>[
          SizedBox(height: AppSpacing.gap16),
          // NOT FOUND's "also show": the invite to rescan or retype.
          _NotFoundCard(),
        ],
      ],
    );
  }
}

/// The status header — colour and copy per screen.
class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.result});

  final VerificationResult result;

  static ({Color ink, Color soft, Color border, String icon, String titleKey})
      _lookOf(String status) {
    switch (status) {
      case 'issued':
        return (
          ink: AppColors.success,
          soft: AppColors.successSoft,
          border: AppColors.successBorder,
          icon: 'BadgeCheck',
          titleKey: 'verify.status.issued',
        );
      case 'expired':
        return (
          ink: AppColors.warning,
          soft: AppColors.warningSurface,
          border: AppColors.warningOutline,
          icon: 'FileClock',
          titleKey: 'verify.status.expired',
        );
      case 'revoked':
        return (
          ink: AppColors.danger,
          soft: AppColors.dangerSoft,
          border: AppColors.dangerBorder,
          icon: 'Shield',
          titleKey: 'verify.status.revoked',
        );
      case 'superseded':
        return (
          ink: AppColors.danger,
          soft: AppColors.dangerSoft,
          border: AppColors.dangerBorder,
          icon: 'RefreshCw',
          titleKey: 'verify.status.superseded',
        );
      case 'not-found':
        return (
          ink: AppColors.gray600,
          soft: AppColors.gray50,
          border: AppColors.gray300,
          icon: 'AlertCircle',
          titleKey: 'verify.status.notFound',
        );
      default:
        // The open set: an unnamed status renders as its word, with the
        // neutral look — never "unknown", never a crash.
        return (
          ink: AppColors.gray600,
          soft: AppColors.gray50,
          border: AppColors.gray300,
          icon: 'FileText',
          titleKey: 'verify.status.generic',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ({Color ink, Color soft, Color border, String icon,
            String titleKey}) look = _lookOf(result.status);
    final String title = look.titleKey == 'verify.status.generic'
        ? result.status
        : look.titleKey.tr(context: context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.gap16),
      decoration: BoxDecoration(
        color: look.soft,
        border: Border.all(color: look.border),
        borderRadius: BorderRadius.circular(AppSpacing.gap12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              LucideIcon(name: look.icon, color: look.ink),
              SizedBox(width: AppSpacing.gap8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontFamilyFallback: AppTypography.fontFamilyFallback,
                    fontSize: AppTypography.size24,
                    fontWeight: AppTypography.bold,
                    color: look.ink,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.gap8),
          Text(
            result.verifyCode,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontFamilyFallback: AppTypography.fontFamilyFallback,
              fontSize: AppTypography.size16,
              fontWeight: AppTypography.medium,
              color: AppColors.gray900,
            ),
          ),
        ],
      ),
    );
  }
}

/// The details card — each row rendered only when its value exists.
class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.result});

  final VerificationResult result;

  @override
  Widget build(BuildContext context) {
    final Lang lang = _langOf(context);
    final List<Widget> rows = <Widget>[
      _DetailRow(
        label: 'verify.detail.service'.tr(context: context),
        value: text(result.service, lang),
      ),
      _DetailRow(
        label: 'verify.detail.certificateNo'.tr(context: context),
        value: result.certificateNo,
      ),
      _DetailRow(
        label: 'verify.detail.holder'.tr(context: context),
        value: result.holderName,
      ),
      _DetailRow(
        label: 'verify.detail.issuedAt'.tr(context: context),
        value: formatDate(result.issuedAt, lang == Lang.lo ? 'lo' : 'en'),
      ),
      // `valid_until` — "when set" on VALID, "the valid_until date" on
      // EXPIRED. `''` IS absence (the wire reader's `_nullableDateAt`), so
      // the row disappears on both.
      if (result.validUntil != null && result.validUntil!.isNotEmpty)
        _DetailRow(
          label: 'verify.detail.validUntil'.tr(context: context),
          value: formatDate(result.validUntil, lang == Lang.lo ? 'lo' : 'en'),
        ),
      if (result.issuingOffice != null)
        _DetailRow(
          label: 'verify.detail.issuingOffice'.tr(context: context),
          value: text(result.issuingOffice, lang),
        ),
      // REVOKED's "also show": `revoked_at` and `revoke_reason`.
      if (result.revokedAt.isNotEmpty)
        _DetailRow(
          label: 'verify.detail.revokedAt'.tr(context: context),
          value: formatDate(result.revokedAt, lang == Lang.lo ? 'lo' : 'en'),
        ),
      if (result.revokeReason.isNotEmpty)
        _DetailRow(
          label: 'verify.detail.revokeReason'.tr(context: context),
          value: result.revokeReason,
        ),
      // REPLACED's "also show": `replaced_by_certificate_no`.
      if (result.replacedByCertificateNo.isNotEmpty)
        _DetailRow(
          label: 'verify.detail.replacedBy'.tr(context: context),
          value: result.replacedByCertificateNo,
        ),
    ];

    final List<Widget> visible = rows
        .where((Widget w) => w is! _DetailRow || w.hasValue)
        .toList();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < visible.length; i++) ...<Widget>[
            if (i > 0) SizedBox(height: AppSpacing.gap12),
            visible[i],
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  bool get hasValue => value.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!hasValue) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontFamilyFallback: AppTypography.fontFamilyFallback,
            fontSize: AppTypography.size12,
            fontWeight: AppTypography.medium,
            color: AppColors.gray500,
          ),
        ),
        SizedBox(height: AppSpacing.gap2),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontFamilyFallback: AppTypography.fontFamilyFallback,
            fontSize: AppTypography.size16,
            color: AppColors.gray900,
          ),
        ),
      ],
    );
  }
}

/// The checks card — "Checks, worded honestly", verbatim.
class _ChecksCard extends StatelessWidget {
  const _ChecksCard({required this.result});

  final VerificationResult result;

  @override
  Widget build(BuildContext context) {
    final Lang lang = _langOf(context);
    final SignatureCheck signature = result.checks.signature;
    final RecordHashCheck recordHash = result.checks.recordHash;
    final RevocationCheck revocation = result.checks.revocation;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'verify.checks.title'.tr(context: context),
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontFamilyFallback: AppTypography.fontFamilyFallback,
              fontSize: AppTypography.size18,
              fontWeight: AppTypography.semiBold,
              color: AppColors.gray900,
            ),
          ),
          SizedBox(height: AppSpacing.gap12),

          // ── signature ────────────────────────────────────────────────────
          _CheckRow(
            icon: 'FileCheck2',
            value: signature.status,
            // HONEST WORDING: `recorded` = an officer's signature is on file.
            // Never "verified", never "valid" — the guide forbids both words
            // for this check.
            label: signature.status == 'recorded'
                ? 'verify.checks.signatureRecorded'.tr(context: context)
                : signature.status == 'missing'
                    ? 'verify.checks.signatureMissing'.tr(context: context)
                    : signature.status, // the open set, as its word
            detail: <String>[
              if (signature.signerName.isNotEmpty) signature.signerName,
              if (signature.signerTitle != null)
                text(signature.signerTitle, lang),
            ].where((String s) => s.isNotEmpty).join(' · '),
          ),
          // `ca` / `format` / `timestamp` — "show them only when non-empty".
          if (signature.ca.isNotEmpty)
            _DetailRow(
              label: 'verify.checks.ca'.tr(context: context),
              value: signature.ca,
            ),
          if (signature.format.isNotEmpty)
            _DetailRow(
              label: 'verify.checks.format'.tr(context: context),
              value: signature.format,
            ),
          if (signature.timestamp.isNotEmpty)
            _DetailRow(
              label: 'verify.checks.timestamp'.tr(context: context),
              value: signature.timestamp,
            ),

          SizedBox(height: AppSpacing.gap12),

          // ── record_hash ───────────────────────────────────────────────────
          _CheckRow(
            icon: 'ShieldCheck',
            value: recordHash.status,
            label: recordHash.status == 'match'
                ? 'verify.checks.hashMatch'.tr(context: context)
                : recordHash.status == 'mismatch'
                    ? 'verify.checks.hashMismatch'.tr(context: context)
                    : recordHash.status == 'missing'
                        ? 'verify.checks.hashMissing'.tr(context: context)
                        : recordHash.status, // the open set, as its word
            detail: recordHash.algorithm,
          ),
          // The mismatch warn — "warn, and offer the PDF check". The offer
          // itself (the button) lives in `_ResultBody`, gated the same way.
          if (recordHash.status == 'mismatch')
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.gap8),
              child: _WarnBox(
                message: 'verify.checks.hashMismatchWarn'.tr(context: context),
              ),
            ),

          SizedBox(height: AppSpacing.gap12),

          // ── revocation ────────────────────────────────────────────────────
          _CheckRow(
            icon: 'BadgeCheck',
            value: revocation.status,
            label: revocation.status == 'not-revoked'
                ? 'verify.checks.notRevoked'.tr(context: context)
                : revocation.status == 'revoked'
                    ? 'verify.checks.revoked'.tr(context: context)
                    : revocation.status == 'superseded'
                        ? 'verify.checks.superseded'.tr(context: context)
                        : revocation.status, // the open set, as its word
            detail: '',
          ),
        ],
      ),
    );
  }
}

/// The NOT FOUND affordances — "invite to rescan or type the code".
class _NotFoundCard extends StatelessWidget {
  const _NotFoundCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'verify.notFound.body'.tr(context: context),
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontFamilyFallback: AppTypography.fontFamilyFallback,
              fontSize: AppTypography.size14,
              color: AppColors.gray600,
            ),
          ),
          SizedBox(height: AppSpacing.gap16),
          // No dedicated scan route exists yet — Task 5 wires the camera.
          // Until then this returns to the entry page, which carries the
          // Scan button placeholder.
          OutlinedButton.icon(
            onPressed: () => context.go(AppNameRoutes.verify),
            icon: const LucideIcon(name: 'QrCode'),
            label: Text('verify.notFound.rescan'.tr(context: context)),
          ),
          SizedBox(height: AppSpacing.gap8),
          OutlinedButton.icon(
            onPressed: () => context.go(AppNameRoutes.verify),
            icon: const LucideIcon(name: 'Hash'),
            label: Text('verify.notFound.retype'.tr(context: context)),
          ),
        ],
      ),
    );
  }
}

// ── The non-result states ────────────────────────────────────────────────────

class _CheckingBody extends StatelessWidget {
  const _CheckingBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const CircularProgressIndicator(),
          SizedBox(height: AppSpacing.gap16),
          Text(
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
    );
  }
}

/// 429 — "Please wait a minute"; never retry in a loop". No button: a retry
/// affordance is exactly what the guide forbids wiring here.
class _TooManyRequestsBody extends StatelessWidget {
  const _TooManyRequestsBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gap24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const LucideIcon(name: 'Clock', size: 48, color: AppColors.warning),
            SizedBox(height: AppSpacing.gap16),
            Text(
              'verify.tooManyRequests.title'.tr(context: context),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontFamilyFallback: AppTypography.fontFamilyFallback,
                fontSize: AppTypography.size20,
                fontWeight: AppTypography.semiBold,
                color: AppColors.gray900,
              ),
            ),
            SizedBox(height: AppSpacing.gap8),
            Text(
              'verify.tooManyRequests.body'.tr(context: context),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontFamilyFallback: AppTypography.fontFamilyFallback,
                fontSize: AppTypography.size14,
                color: AppColors.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A generic failure — the server's own sentence, verbatim.
class _FailureBody extends StatelessWidget {
  const _FailureBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gap24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const LucideIcon(
                name: 'AlertCircle', size: 48, color: AppColors.danger),
            SizedBox(height: AppSpacing.gap16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontFamilyFallback: AppTypography.fontFamilyFallback,
                fontSize: AppTypography.size14,
                color: AppColors.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The state the page is built in when no submission has happened — the
/// `/verify/:code` route dispatches from its builder, so this renders only
/// for a mounted-but-undispatched bloc (and in tests).
class _InitialBody extends StatelessWidget {
  const _InitialBody();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

// ── Shared chrome ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.gap16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.gap12),
      ),
      child: child,
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.icon,
    required this.value,
    required this.label,
    required this.detail,
  });

  final String icon;
  final String value;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LucideIcon(name: icon, size: 20),
        SizedBox(width: AppSpacing.gap8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontFamilyFallback: AppTypography.fontFamilyFallback,
                  fontSize: AppTypography.size14,
                  fontWeight: AppTypography.medium,
                  color: AppColors.gray900,
                ),
              ),
              if (detail.isNotEmpty) ...<Widget>[
                SizedBox(height: AppSpacing.gap2),
                Text(
                  detail,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontFamilyFallback: AppTypography.fontFamilyFallback,
                    fontSize: AppTypography.size12,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WarnBox extends StatelessWidget {
  const _WarnBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.gap12),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        border: Border.all(color: AppColors.warningOutline),
        borderRadius: BorderRadius.circular(AppSpacing.gap8),
      ),
      child: Row(
        children: <Widget>[
          const LucideIcon(name: 'AlertTriangle', color: AppColors.warning),
          SizedBox(width: AppSpacing.gap8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontFamilyFallback: AppTypography.fontFamilyFallback,
                fontSize: AppTypography.size13,
                color: AppColors.warningTitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

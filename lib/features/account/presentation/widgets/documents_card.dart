/// The "My Documents" card — `AccountPage.tsx:392-490`, 99 of the source
/// page's 749 lines.
///
/// **Absent from `roadmap.md` § B8's endpoint list and from the B8 dispatch**
/// (specs.md § 2.2 Finding B): `me.documents()` (`endpoints.ts:115`) backs the
/// whole block and omitting it would have shipped B8 missing its second-largest
/// surface.
///
/// ## FU-2 — View, Download and `DocumentViewer` are DEFERRED, not forgotten
///
/// The source's `openable` branch (`:461-480`) renders two buttons and opens a
/// `DocumentViewer` modal. **B8 renders the non-openable branch's
/// `c("notReady")` for every row instead**, and this is the one place B8 is not
/// a complete port of `AccountPage`. specs.md § 6.6 rules it on four cumulative
/// grounds:
///
/// 1. `DocumentViewer.tsx:3` requires `DialogShell`, which `ssd.md` § 4.4
///    assigns to `lib/presentation/common/` in **B10** — being implemented
///    concurrently with this batch. A modal shell is not something to hand-roll
///    privately and then have B10 duplicate (unlike a button; see
///    `account_primitives.dart`).
/// 2. It needs a **PDF renderer**. The web uses an `<iframe>`
///    (`DocumentViewer.tsx:136`); Flutter has none. That is a second new
///    dependency for a surface with no verified data behind it.
/// 3. It is **shared with B7** — `HistoryDetailPage.tsx:24` is the other
///    consumer, and B7 is being specified in parallel. Two batches
///    independently porting one 174-line component into two homes is how CR-3
///    and CR-4 happened.
/// 4. **No AC could verify it.** The viewer is reachable only from a row with
///    `available && file_url`, and the only test citizen has no verified
///    documents (GG-2).
///
/// [CitizenDocument.openable] **is** ported, and [DocumentRow] evaluates it —
/// so the deferral is a choice made at one render site against a working
/// predicate, not a predicate that was never written. FU-2's owner turns the
/// branch on; they do not re-derive it. B8-AC-29 requires this comment to
/// exist and requires that **no dead button is rendered**.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../i18n/i18n.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/entities/citizen_document.dart';
import 'account_date.dart';
import 'account_primitives.dart';

class DocumentsCard extends StatelessWidget {
  const DocumentsCard({
    super.key,
    required this.loading,
    required this.failed,
    required this.errorMessage,
    required this.documents,
    required this.onRetry,
  });

  final bool loading;
  final bool failed;

  /// `docsQuery.error.message` — see [_Error] for the precedence rule.
  final String? errorMessage;

  final List<CitizenDocument> documents;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.gap4,
            bottom: AppSpacing.gap8,
          ),
          child: Text(
            'account.myDocuments'.tr().toUpperCase(),
            style: const TextStyle(
              color: AppColors.gray400,
              fontSize: AppTypography.size12,
              letterSpacing: 0.5,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
            border: Border.all(color: AppColors.gray100),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: AppColors.cardShadow, blurRadius: 2),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
            child: _body(context),
          ),
        ),
      ],
    );
  }

  /// The four states, **in the order `:398-423` evaluates them**. `ssd.md`
  /// § 7.3 makes all four mandatory, not optional.
  Widget _body(BuildContext context) {
    if (loading) return const _Skeletons();
    if (failed) return _Error(message: errorMessage, onRetry: onRetry);
    if (documents.isEmpty) return const _Empty();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < documents.length; i++)
          DocumentRow(
            document: documents[i],
            // `i < documents.length - 1` — a hairline **between** rows and not
            // after the last (`:431`).
            divider: i < documents.length - 1,
          ),
      ],
    );
  }
}

/// `{[0,1,2].map(…)}` — three `h-16` pulse blocks in a `p-5 space-y-3`
/// container (`:399-403`). **Three, not one and not "some"**: the number is
/// the source's and a different one changes what a citizen sees.
class _Skeletons extends StatelessWidget {
  const _Skeletons();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(AppSpacing.gap20),
        child: Column(
          children: <Widget>[
            AccountSkeleton(height: 64),
            SizedBox(height: AppSpacing.gap12),
            AccountSkeleton(height: 64),
            SizedBox(height: AppSpacing.gap12),
            AccountSkeleton(height: 64),
          ],
        ),
      );
}

/// `:406-417`.
class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // `docsQuery.error.message || c("docsError")` — `:409`. **The API's own
    // message wins**; the local string is the fallback for an error with no
    // message, not the other way round. Getting this backwards would hide every
    // server explanation behind one generic sentence.
    final String text = (message == null || message!.isEmpty)
        ? 'account.docsError'.tr()
        : message!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.gap20),
      child: Column(
        children: <Widget>[
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.gray600,
              fontSize: AppTypography.size14,
            ),
          ),
          const SizedBox(height: AppSpacing.gap12),
          AccountButton(
            label: 'account.retry'.tr(),
            secondary: true,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

/// `:419-421` — `px-5 py-6 text-gray-400 text-sm text-center`.
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gap20,
          vertical: AppSpacing.gap24,
        ),
        child: Text(
          'account.docsEmpty'.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.gray400,
            fontSize: AppTypography.size14,
          ),
        ),
      );
}

/// One row — `:428-487`.
class DocumentRow extends StatelessWidget {
  const DocumentRow({
    super.key,
    required this.document,
    required this.divider,
  });

  final CitizenDocument document;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final Lang lang = Lang.fromCode(Localizations.localeOf(context).languageCode);
    final _DocBadge badge = _DocBadge.of(document.status);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: divider
            ? const Border(bottom: BorderSide(color: AppColors.gray50))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gap20,
          vertical: AppSpacing.gap16,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: AppSpacing.control40,
              height: AppSpacing.control40,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: const Center(
                child: LucideIcon(
                  name: 'FileText',
                  size: AppSpacing.gap20,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.gap16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.gap8,
                    runSpacing: AppSpacing.gap4,
                    children: <Widget>[
                      Text(
                        // `text(doc.title, lang)` — `:442`. The **imported**
                        // helper from `lib/i18n/i18n.dart`, not a local
                        // re-implementation: four B2 features re-implemented it
                        // citing G-L3, and G-L3 has nothing to say about
                        // `lib/i18n/`.
                        text(document.title, lang),
                        style: const TextStyle(
                          color: AppColors.gray800,
                          fontSize: AppTypography.size14,
                          fontWeight: AppTypography.medium,
                        ),
                      ),
                      badge.build(),
                    ],
                  ),
                  // `{doc.number && …}` — `:450`.
                  if (document.number.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.gap2),
                      child: Text(
                        document.number,
                        style: const TextStyle(
                          color: AppColors.gray400,
                          fontSize: AppTypography.size12,
                        ),
                      ),
                    ),
                  _DateLine(document: document, lang: lang),
                  // ── FU-2 ──────────────────────────────────────────────────
                  //
                  // `openable ? <View/><Download/> : <p>{c("notReady")}</p>` —
                  // `:461-483`. **B8 ships only the second branch**, for every
                  // row, deferred per specs.md § 6.6. See the library doc for
                  // the four grounds and for why
                  // `CitizenDocument.openable` is ported anyway.
                  //
                  // Rendering `notReady` for an actually-openable document is
                  // the honest failure mode: it under-promises. Rendering two
                  // buttons that do nothing would be the dead affordance
                  // B8-AC-29 forbids.
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.gap10),
                    child: Text(
                      'account.notReady'.tr(),
                      style: const TextStyle(
                        color: AppColors.gray400,
                        fontSize: AppTypography.size12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `{(doc.expires_at || doc.issued_at) && …}` — `:451-459`.
///
/// A real three-part conditional that is easy to flatten wrongly:
///
/// * rendered **only** when one of the two dates is present;
/// * the **label** is `t("validUntil")` when `expires_at` is present, else
///   `c("issued")` — note it keys off `expires_at`, not off which date is used;
/// * the **value** is `formatDate(doc.expires_at ?? doc.issued_at, lang)`.
///
/// The two happen to agree, but they are separate expressions in the source and
/// separating them here keeps a future edit from collapsing them.
class _DateLine extends StatelessWidget {
  const _DateLine({required this.document, required this.lang});

  final CitizenDocument document;
  final Lang lang;

  @override
  Widget build(BuildContext context) {
    if (document.expiresAt == null && document.issuedAt == null) {
      return const SizedBox.shrink();
    }

    final String label = document.expiresAt != null
        ? 'account.validUntil'.tr()
        : 'account.issued'.tr();
    final String value = formatAccountDate(
      document.expiresAt ?? document.issuedAt,
      lang,
    );

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.gap4),
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: label,
              style: const TextStyle(color: AppColors.gray400),
            ),
            // The `{" "}` between the two spans at `:455` — a real text node in
            // the source's output.
            const TextSpan(text: ' '),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: AppTypography.medium),
            ),
          ],
        ),
        style: const TextStyle(
          color: AppColors.gray500,
          fontSize: AppTypography.size12,
        ),
      ),
    );
  }
}

/// `docStatus` — `AccountPage.tsx:297-302`.
///
/// **The label comes from two different i18n sources** and the Flutter port
/// unifies where they live without changing the strings (specs.md § 6.5):
///
/// | `status` | Label | Source |
/// |---|---|---|
/// | `valid` | `t("verified")` | the `account` namespace |
/// | `expired` | `c("expired")` | the component-local `COPY` object |
/// | anything else | `c("missing")` | `COPY` |
///
/// Both now live under `account.*` in the Flutter dictionary, because Flutter
/// has no analogue of a component-local bilingual `COPY`.
class _DocBadge {
  const _DocBadge({
    required this.labelKey,
    required this.background,
    required this.border,
    required this.foreground,
    required this.showsCheck,
  });

  final String labelKey;
  final Color background;
  final Color border;
  final Color foreground;

  /// `status.icon` — only the `valid` badge carries a `CheckCircle` (`:446`).
  final bool showsCheck;

  /// `DocumentStatus.unknown` takes the same branch as `missing`, which is what
  /// the source's final `else` already does for an unrecognised string.
  /// B8-AC-26 asserts that an unknown status does not crash.
  static _DocBadge of(DocumentStatus status) => switch (status) {
        DocumentStatus.valid => const _DocBadge(
            labelKey: 'account.verified',
            background: AppColors.successSoft,
            border: AppColors.successBorder,
            foreground: AppColors.success,
            showsCheck: true,
          ),
        DocumentStatus.expired => const _DocBadge(
            labelKey: 'account.expired',
            background: AppColors.dangerSoft,
            border: AppColors.dangerOutline,
            foreground: AppColors.danger,
            showsCheck: false,
          ),
        DocumentStatus.missing || DocumentStatus.unknown => const _DocBadge(
            labelKey: 'account.missing',
            background: AppColors.gray50,
            border: AppColors.gray200,
            foreground: AppColors.gray500,
            showsCheck: false,
          ),
      };

  Widget build() => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gap8,
          vertical: AppSpacing.gap2,
        ),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (showsCheck) ...<Widget>[
              LucideIcon(
                name: 'CheckCircle',
                size: AppSpacing.gap12,
                color: foreground,
              ),
              const SizedBox(width: AppSpacing.gap4),
            ],
            Text(
              labelKey.tr(),
              style: TextStyle(
                color: foreground,
                fontSize: AppTypography.size12,
              ),
            ),
          ],
        ),
      );
}

/// The success screen — `FamilyBookPage.tsx:340-388`.
///
/// **It abandons the frame entirely**, and that is the single most likely
/// structural mistake in this port. No header, no back chevron, no title, no
/// subtitle, no step indicator, no bottom CTA bar: the whole screen is
/// `min-h-full flex flex-col items-center justify-center p-6` with its own
/// full-width button inside the centred column (`:378`). Wrapping it in
/// [FamilyBookFrame] would render four strings the web does not show there and
/// would be a Tier 1 structural failure (`F4-AC-37`).
///
/// It is reachable only after a successful `POST …/request-copy`, which needs a
/// household, which no account this programme has. Every value on it is
/// server-derived, so it is `F4-NV-2` — NOT EVALUATED, and its widget test
/// claims structure only.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../i18n/i18n.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../application/domain/entities/application_row.dart';
import '../../domain/entities/family_book.dart';
import '../../domain/family_book_derivations.dart';

class FamilyBookSuccess extends StatelessWidget {
  const FamilyBookSuccess({
    super.key,
    required this.book,
    required this.submitted,
    required this.onBack,
  });

  /// Non-null by construction: `:339`'s check comes **after** `:326`'s
  /// `if (!book)`, which is why `:358` can fall back to `household_no`.
  final FamilyBook book;

  final ApplicationRow submitted;

  /// `onBack()` — `:379`. The same callback the frame's chevron takes, wired
  /// here to a full-width primary button instead.
  final VoidCallback onBack;

  String _t(BuildContext context, String key) =>
      '$kFamilyBookNamespace.$key'.tr(context: context);

  @override
  Widget build(BuildContext context) {
    final Lang lang = Localizations.localeOf(context).languageCode == 'lo'
        ? Lang.lo
        : Lang.en;

    // `text(submitted.status_label, lang) || t("statusSubmitted")` — `:362`.
    final String statusText = text(submitted.statusLabel, lang);

    // ── GOR-267 — the one family-book path that bypasses the frame ───────────
    //
    // The success state is reached from `family_book_page.dart:141` *instead
    // of* `FamilyBookFrame`, never inside it, so it needs its own page chrome
    // for exactly the reason the frame does — see `family_book_chrome.dart`'s
    // `FamilyBookFrame.build` for the full note. Without it every `Text` below
    // renders in `WidgetsApp._errorTextStyle`, the yellow-double-underlined
    // fallback, in release as well as debug, and the content draws under the
    // status bar.
    //
    // There is no nesting conflict with the frame's `Scaffold`: the two are
    // alternatives, never ancestors of one another.
    //
    // This branch is unreachable in practice — `showsSuccess` needs a non-null
    // `book` *and* a `submitted`, and `GET /me/family-book` answers 404 on
    // every account this programme has — which is why
    // `test/features/certificates/material_ancestor_test.dart`'s T-3 mounts it
    // explicitly rather than driving to it.
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          // `p-6`
          padding: const EdgeInsets.all(AppSpacing.gap24),
          child: Center(
            child: ConstrainedBox(
              // `max-w-sm`
              constraints: const BoxConstraints(maxWidth: 384),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    // `w-24 h-24 rounded-full shadow-xl`
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      // `linear-gradient(135deg, #344EAD 0%, #1a2d7a 100%)`
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          AppColors.primary,
                          AppColors.brandGradientEnd,
                        ],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.cardShadowMedium,
                          blurRadius: 25,
                          offset: Offset(0, 20),
                        ),
                      ],
                    ),
                    child: const LucideIcon(
                      // `w-12 h-12 text-white strokeWidth={3}`
                      name: 'Check',
                      size: 48,
                      color: AppColors.white,
                    ),
                  ),
                  // `gap-5`
                  const SizedBox(height: AppSpacing.gap20),
                  Text(
                    _t(context, 'successTitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: AppTypography.size18,
                      fontWeight: AppTypography.semiBold,
                      color: AppColors.gray900,
                    ),
                  ),
                  // `mb-2`
                  const SizedBox(height: AppSpacing.gap8),
                  Text(
                    _t(context, 'successBody'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: AppTypography.size14,
                      height: AppTypography.lineRelaxed,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gap20),
                  _Card(
                    rows: <_Row>[
                      _Row(
                        label: _t(context, 'successHead'),
                        // `{book.head_name || "—"}` — `:357`.
                        value: orDash(book.headName),
                      ),
                      _Row(
                        label: _t(context, 'familyBookNo'),
                        // `{submitted.reference_no || book.household_no}` —
                        // `:358`. **No dash on this one**: the fallback is the
                        // household number, and if that is empty too the row
                        // renders empty (`F4-AC-72`).
                        value: submitted.referenceNo.isNotEmpty
                            ? submitted.referenceNo
                            : book.householdNo,
                      ),
                      _Row(
                        label: _t(context, 'successMembers'),
                        value: '$kFamilyBookNamespace.peopleSummary'.tr(
                          context: context,
                          namedArgs: <String, String>{
                            'total': '${totalMembersOf(book)}',
                            'men': '${menCountOf(book)}',
                            'women': '${womenCountOf(book)}',
                          },
                        ),
                      ),
                      _Row(
                        label: _t(context, 'statusLabel'),
                        value: statusText.isNotEmpty
                            ? statusText
                            : _t(context, 'statusSubmitted'),
                        isStatus: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.gap20),
                  Semantics(
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onBack,
                      child: Container(
                        width: double.infinity,
                        // `py-4 rounded-2xl shadow-lg`
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.gap16,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radius2xl),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: AppColors.cardShadowMedium,
                              blurRadius: 15,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Text(
                          _t(context, 'backToHome'),
                          style: const TextStyle(
                            fontSize: AppTypography.size14,
                            fontWeight: AppTypography.semiBold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gap20),
                  Text(
                    _t(context, 'trackHint'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: AppTypography.size12,
                      color: AppColors.gray400Inline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One `label / value` line of the success card — `:366-375`.
class _Row {
  const _Row({
    required this.label,
    required this.value,
    this.isStatus = false,
  });

  final String label;
  final String value;

  /// The one row rendered as an amber pill rather than as plain right-aligned
  /// text (`:368-374`).
  final bool isStatus;
}

/// `w-full bg-white rounded-3xl p-5 text-left space-y-3 shadow-sm border
/// border-gray-100` — `:355`.
class _Card extends StatelessWidget {
  const _Card({required this.rows});

  final List<_Row> rows;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.gap20),
        decoration: BoxDecoration(
          color: AppColors.white,
          // `rounded-3xl`
          borderRadius: BorderRadius.circular(AppSpacing.radius3xl),
          border: Border.all(color: AppColors.gray100),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: AppColors.cardShadow, blurRadius: 2),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int i = 0; i < rows.length; i++) ...<Widget>[
              // `space-y-3`
              if (i > 0) const SizedBox(height: AppSpacing.gap12),
              Row(
                children: <Widget>[
                  Text(
                    rows[i].label,
                    style: const TextStyle(
                      fontSize: AppTypography.size14,
                      color: AppColors.muted,
                    ),
                  ),
                  // `gap-3`
                  const SizedBox(width: AppSpacing.gap12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: rows[i].isStatus
                          ? Container(
                              // `px-2.5 py-1 rounded-full bg-amber-50`
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.gap10,
                                vertical: AppSpacing.gap4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warningSurface,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull,
                                ),
                              ),
                              child: Text(
                                rows[i].value,
                                style: const TextStyle(
                                  fontSize: AppTypography.size12,
                                  fontWeight: AppTypography.semiBold,
                                  color: AppColors.warningLink,
                                ),
                              ),
                            )
                          : Text(
                              rows[i].value,
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: AppTypography.size14,
                                fontWeight: AppTypography.semiBold,
                                color: AppColors.gray800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
}

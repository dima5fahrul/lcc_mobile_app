/// Steps 1-3 — the household's three screens (`:397-434`, `:438-502`,
/// `:505-567`).
///
/// **Everything these render is a raw server field, and there is no oracle for
/// any of it.** `specs.md` § 6.4: `GET /me/family-book` answers 404 on every
/// account this programme has, so these three views — and the success card —
/// are `F4-NV-2`, NOT EVALUATED. Their widget tests assert *structure*: which
/// field appears, in which order, under which label. Per the Capability Rule
/// those tests would pass with the wrong values, so they are never reported as
/// fidelity.
///
/// What *is* gated is the derivable part, and it lives in
/// `family_book_derivations.dart`: the two registry maps, the three counts, the
/// address line, the step-3 sub-line and the fee format. Every one of them is
/// called from here rather than re-expressed, so the tested function is the
/// rendered function.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/entities/family_book.dart';
import '../../domain/entities/household_member.dart';
import '../../domain/family_book_copy.dart';
import '../../domain/family_book_derivations.dart';
import 'family_book_fields.dart';
import 'family_book_palette.dart';
import 'family_book_states.dart';

/// `familyBook.<key>`, resolved against the widget's own context so the string
/// repaints when the citizen flips the toggle (D-3 / G-L8).
String _t(BuildContext context, String key) =>
    '$kFamilyBookNamespace.$key'.tr(context: context);

/// [labelOf]'s translator, bound to this context.
FamilyBookTranslate _translator(BuildContext context) =>
    (String key) => _t(context, key);

/// `grid grid-cols-2 gap-3` — two equal columns, 12 px apart (`:414`, `:421`,
/// `:483`, `:488`).
class _Pair extends StatelessWidget {
  const _Pair({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: left),
          const SizedBox(width: AppSpacing.gap12),
          Expanded(child: right),
        ],
      );
}

/// The small grey pill at `:404`, `:470` — `text-[10px] font-medium
/// text-gray-400 bg-gray-100 px-2 py-1 rounded-full`.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    this.fill = AppColors.gray100,
    this.ink = AppColors.gray400Inline,
  });

  final String text;
  final Color fill;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gap8,
          vertical: AppSpacing.gap4,
        ),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: kFbSize10,
            fontWeight: AppTypography.medium,
            color: ink,
          ),
        ),
      );
}

/// `flex items-center justify-between p-4 rounded-2xl bg-white border
/// border-gray-100` — the two banner rows at `:399` and `:440`, and the blue
/// one at `:426` with its own fill.
class _BannerRow extends StatelessWidget {
  const _BannerRow({
    required this.left,
    required this.right,
    this.fill = AppColors.white,
    this.outline = AppColors.gray100,
  });

  final Widget left;
  final Widget right;
  final Color fill;
  final Color outline;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.gap16),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
          border: Border.all(color: outline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[Flexible(child: left), right],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — cover and household head (`:397-434`)
// ─────────────────────────────────────────────────────────────────────────────

/// The ten body children of step 1, in source order.
///
/// **`head_name` is rendered twice** — once as the cover holder (`:409`,
/// `holderNameLabel`) and once as the head (`:412`, `nameAndSurname`). That is
/// the source's own duplication and deleting either is a Tier 1 failure.
///
/// **The address rows read province, district, village** (`:420-424`) — the
/// *reverse* of [addressLineOf]'s order on step 3. Both are the source.
List<Widget> familyBookStep1(BuildContext context, FamilyBook book) {
  final FamilyBookTranslate t = _translator(context);
  return <Widget>[
    _BannerRow(
      left: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            _t(context, 'familyBookNo').toUpperCase(),
            // `text-[11px] font-semibold text-gray-400 uppercase tracking-wide`
            style: const TextStyle(
              fontSize: AppTypography.size11,
              fontWeight: AppTypography.semiBold,
              letterSpacing: AppTypography.size11 * 0.025,
              color: AppColors.gray400Inline,
            ),
          ),
          const SizedBox(height: AppSpacing.gap2),
          Text(
            // `{book.household_no || "—"}` — `:402`.
            orDash(book.householdNo),
            style: const TextStyle(
              fontSize: AppTypography.size14,
              fontWeight: AppTypography.semiBold,
              color: AppColors.gray800,
            ),
          ),
        ],
      ),
      right: _Pill(text: _t(context, 'autoGenerated')),
    ),
    FamilyBookReadField(
      label: _t(context, 'holderNameLabel'),
      value: book.headName,
    ),
    FamilyBookSectionLabel(text: _t(context, 'householdHead')),
    FamilyBookReadField(
      label: _t(context, 'nameAndSurname'),
      value: book.headName,
    ),
    FamilyBookReadField(
      label: _t(context, 'idCardNo'),
      // `{book.head_id_no ?? ""}` — `:413`.
      value: book.headIdNo ?? '',
    ),
    _Pair(
      left: FamilyBookReadField(
        label: _t(context, 'unit'),
        value: book.unit,
      ),
      right: FamilyBookReadField(
        label: _t(context, 'group'),
        value: book.group,
      ),
    ),
    FamilyBookSectionLabel(text: _t(context, 'address')),
    FamilyBookReadField(
      // `tf("province")` — the `fields` namespace, which already carries all
      // three keys. F4 adds nothing to it (`F4-AC-58`).
      label: 'fields.province'.tr(context: context),
      value: book.jurisdiction?.provinceName ?? '',
    ),
    _Pair(
      left: FamilyBookReadField(
        label: 'fields.district'.tr(context: context),
        value: book.jurisdiction?.districtName ?? '',
      ),
      right: FamilyBookReadField(
        label: 'fields.village'.tr(context: context),
        value: book.jurisdiction?.villageName ?? '',
      ),
    ),
    _BannerRow(
      fill: kFbBlue50,
      outline: kFbBlue100,
      left: Text(
        _t(context, 'dateOfIssue'),
        // `text-xs font-medium` at `#344EAD`
        style: const TextStyle(
          fontSize: AppTypography.size12,
          fontWeight: AppTypography.medium,
          color: AppColors.primary,
        ),
      ),
      right: _Pill(
        // `{book.issued_at || book.registered_at || t("setOnIssuance")}` —
        // `:431`. **Step 3 ends this same chain with `"—"` instead**
        // (`:529`); both are reproduced (`F4-AC-71`).
        text: _fallbackChain(
          <String?>[book.issuedAt, book.registeredAt],
          () => t('setOnIssuance'),
        ),
        fill: AppColors.white,
        ink: AppColors.primary,
      ),
    ),
  ];
}

/// `a || b || <last>` over a list of possibly-empty strings, JavaScript's
/// falsy rule: an empty string does **not** stop the chain.
String _fallbackChain(List<String?> candidates, String Function() last) {
  for (final String? c in candidates) {
    if (c != null && c.isNotEmpty) return c;
  }
  return last();
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — members (`:438-502`)
// ─────────────────────────────────────────────────────────────────────────────

/// The body children of step 2: the count banner, then either the "no members"
/// card or one card per member.
List<Widget> familyBookStep2(BuildContext context, FamilyBook book) {
  final List<HouseholdMember> members = membersOf(book);
  final int total = totalMembersOf(book);
  final int men = menCountOf(book);
  final int women = womenCountOf(book);

  return <Widget>[
    _BannerRow(
      left: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const LucideIcon(
            name: 'Users2',
            size: AppSpacing.gap16,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.gap8),
          Flexible(
            child: Text(
              // `{total} {total === 1 ? t("person") : t("people")}` — `:444`.
              //
              // **In Lao both arms are the byte-identical `ຄົນ`**
              // (`familyBook.ts:173-174`), so this branch is observable only in
              // English. That is a source fact to reproduce, not a defect to
              // fix, and it is why `F4-AC-45` asserts the branch in `en`.
              '$total ${_t(context, total == 1 ? 'person' : 'people')}',
              // `text-sm font-medium text-gray-700`
              style: const TextStyle(
                fontSize: AppTypography.size14,
                fontWeight: AppTypography.medium,
                color: AppColors.gray700,
              ),
            ),
          ),
        ],
      ),
      right: Text(
        // `{t("menCount", {n: men})} · {t("womenCount", {n: women})}` — `:447`.
        '${'$kFamilyBookNamespace.menCount'.tr(context: context, namedArgs: <String, String>{'n': '$men'})} '
        '· '
        '${'$kFamilyBookNamespace.womenCount'.tr(context: context, namedArgs: <String, String>{'n': '$women'})}',
        style: const TextStyle(
          fontSize: AppTypography.size12,
          color: AppColors.gray400Inline,
        ),
      ),
    ),
    if (members.isEmpty)
      FamilyBookCard(
        child: Text(
          '$kFamilyBookPageNamespace.noMembers'.tr(context: context),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: AppTypography.size14,
            height: AppTypography.lineRelaxed,
            color: AppColors.muted,
          ),
        ),
      )
    else
      for (int i = 0; i < members.length; i++)
        FamilyBookMemberCard(member: members[i], index: i),
  ];
}

/// One member card — `:458-497`.
class FamilyBookMemberCard extends StatelessWidget {
  const FamilyBookMemberCard({
    super.key,
    required this.member,
    required this.index,
  });

  final HouseholdMember member;

  /// Zero-based; the source renders `i + 1`.
  final int index;

  @override
  Widget build(BuildContext context) {
    final FamilyBookTranslate t = _translator(context);
    final bool isHead = isHeadRelation(member.relation ?? '');
    final String photoUrl = member.photoUrl ?? '';

    return FamilyBookCard(
      padding: const EdgeInsets.all(AppSpacing.gap16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (isHead)
                      // NOT BUNDLED — renders `FileText`. F4-DIV-2, see
                      // `family_book_states.dart`.
                      const LucideIcon(
                        name: 'Crown',
                        size: AppSpacing.gap16,
                        color: AppColors.primary,
                      )
                    else
                      Text(
                        // `#{i + 1}` — `:464`.
                        '#${index + 1}',
                        style: const TextStyle(
                          fontSize: AppTypography.size12,
                          fontWeight: AppTypography.semiBold,
                          color: AppColors.gray400Inline,
                        ),
                      ),
                    const SizedBox(width: AppSpacing.gap8),
                    Flexible(
                      child: Text(
                        '$kFamilyBookNamespace.memberN'.tr(
                          context: context,
                          namedArgs: <String, String>{'n': '${index + 1}'},
                        ).toUpperCase(),
                        style: TextStyle(
                          fontSize: AppTypography.size12,
                          fontWeight: AppTypography.semiBold,
                          letterSpacing:
                              FamilyBookSectionLabel.tracking,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // `{m.status || "—"}` — `:471`, **raw**. No lookup map.
              _Pill(text: orDash(member.status)),
            ],
          ),
          // `space-y-3`
          const SizedBox(height: AppSpacing.gap12),
          // `{m.photo_url && <img …/>}` — `:475-481`. Falsy means **no element
          // at all**, not an empty box (`F4-AC-49`).
          if (photoUrl.isNotEmpty) ...<Widget>[
            _MemberPhoto(url: photoUrl),
            const SizedBox(height: AppSpacing.gap12),
          ],
          FamilyBookReadField(
            label: t('nameAndSurname'),
            value: member.name,
          ),
          const SizedBox(height: AppSpacing.gap12),
          _Pair(
            left: FamilyBookReadField(
              label: t('gender'),
              value: labelOf(kGenderKey, member.gender ?? '', t),
            ),
            right: FamilyBookReadField(
              label: t('dateOfBirth'),
              value: member.dateOfBirth ?? '',
            ),
          ),
          const SizedBox(height: AppSpacing.gap12),
          FamilyBookReadField(
            label: t('relationshipToHead'),
            value: labelOf(kRelationKey, member.relation ?? '', t),
          ),
          const SizedBox(height: AppSpacing.gap12),
          _Pair(
            // `{m.nationality ?? ""}` — `:489`, **raw**. The six `nat*` labels
            // sit in the namespace and the page does not use them; mapping
            // them here would render `Lao` where the web renders `lao`, which
            // is L-10 corollary (b) (`F4-AC-54`).
            left: FamilyBookReadField(
              label: t('nationality'),
              value: member.nationality ?? '',
            ),
            right: FamilyBookReadField(
              label: '$kFamilyBookPageNamespace.status'.tr(context: context),
              value: member.status ?? '',
            ),
          ),
          // `pt-0.5`
          const SizedBox(height: AppSpacing.gap12),
          Row(
            children: <Widget>[
              const LucideIcon(
                name: 'Hash',
                size: 12,
                color: AppColors.gray400Inline,
              ),
              // `gap-1.5`
              const SizedBox(width: AppSpacing.gap6),
              Flexible(
                child: Text(
                  // `{say("uin")}: {m.uin || "—"}` — `:495`.
                  '${'$kFamilyBookPageNamespace.uin'.tr(context: context)}: '
                  '${orDash(member.uin)}',
                  style: const TextStyle(
                    fontSize: AppTypography.size12,
                    color: AppColors.gray400Inline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `<img src={m.photo_url} alt="" className="w-16 h-20 object-cover rounded-xl
/// border border-gray-200"/>` — `:475-481`.
///
/// **The `errorBuilder` is mandatory and what it draws is NOT VERIFIED.**
///
/// Mandatory, because a bare `Image.network` on a dead URL surfaces a Flutter
/// error widget — a red box in debug — where the web surfaces nothing at all
/// for a broken `<img alt="">`. That is an added failure mode, which L-10
/// forbids outright (`F4-AC-50`).
///
/// What it draws is `F4-NV-4`. Measuring it needs a populated household with a
/// dead photo URL and neither exists. The two precedents in this tree disagree
/// — `news_cover.dart:88` and `news_slider.dart:160` return
/// `SizedBox.shrink()`, `lao_id_card.dart:390` returns a sized fallback — and
/// neither was measured against *this* element, whose CSS box (`w-16 h-20`,
/// border, rounding) is on the `<img>` itself. Pending measurement this draws
/// **the box and nothing in it**, which keeps the layout the loaded image would
/// have had. That choice is provisional and is recorded as provisional
/// (`F4-AC-51`); it is not a measurement.
///
/// No caching-image package (§ 4.3). `Image.network` is what this tree already
/// uses and what `news_cover.dart:10-14` documents as the deliberate choice.
class _MemberPhoto extends StatelessWidget {
  const _MemberPhoto({required this.url});

  final String url;

  /// `w-16 h-20`
  static const double width = 64;
  static const double height = 80;

  @override
  Widget build(BuildContext context) => ClipRRect(
        // `rounded-xl`
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Image.network(
            url,
            width: width,
            height: height,
            // `object-cover`
            fit: BoxFit.cover,
            errorBuilder: (BuildContext _, Object __, StackTrace? ___) =>
                const SizedBox(width: width, height: height),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — review (`:505-567`)
// ─────────────────────────────────────────────────────────────────────────────

/// The body children of step 3.
///
/// [submitFailure] is `requestCopy.error?.message` (`:514-519`) — rendered
/// **inline, here, above the review card**, and nowhere else. A failed request
/// does not navigate, toast or reset the step (`F4-AC-39`).
List<Widget> familyBookStep3(
  BuildContext context,
  FamilyBook book, {
  required int copyFee,
  required String? submitFailure,
}) {
  final FamilyBookTranslate t = _translator(context);
  final List<HouseholdMember> members = membersOf(book);
  final String languageCode = Localizations.localeOf(context).languageCode;

  final List<(String, String)> rows = <(String, String)>[
    (t('familyBookNo'), orDash(book.householdNo)),
    (t('holder'), orDash(book.headName)),
    (t('idCardNo'), orDash(book.headIdNo)),
    // `` `${book.unit || "—"} / ${book.group || "—"}` `` — `:527`. A template
    // literal, so the dash is per side and the slash always renders.
    (t('unitGroup'), '${orDash(book.unit)} / ${orDash(book.group)}'),
    (t('address'), addressLineOf(book)),
    // Same chain as `:431`, ending in `"—"` instead of `t("setOnIssuance")`.
    (
      t('dateOfIssue'),
      _fallbackChain(<String?>[book.issuedAt, book.registeredAt], () => kEmDash),
    ),
    (
      t('peopleLabel'),
      '$kFamilyBookNamespace.peopleSummary'.tr(
        context: context,
        namedArgs: <String, String>{
          'total': '${totalMembersOf(book)}',
          'men': '${menCountOf(book)}',
          'women': '${womenCountOf(book)}',
        },
      ),
    ),
    // `formatLak(copyFee, lang)` — `:534`. The grouping is `en-US` in BOTH
    // locales (`serviceConfig.ts:41`); only the currency word changes.
    (t('fee'), formatLak(copyFee, languageCode)),
  ];

  return <Widget>[
    _Notice(
      fill: AppColors.warningSurface,
      outline: kFbAmber100,
      glyph: AppColors.warningLink,
      ink: AppColors.warning,
      text: t('reviewNotice'),
    ),
    if (submitFailure != null)
      _Notice(
        fill: AppColors.dangerSoft,
        outline: kFbRed100,
        glyph: AppColors.dangerStrong,
        ink: AppColors.danger,
        text: submitFailure,
      ),
    FamilyBookCard(
      padding: const EdgeInsets.all(AppSpacing.gap16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _CardHeading(text: t('household')),
          for (final (String label, String value) row in rows) ...<Widget>[
            // `space-y-2.5`
            const SizedBox(height: AppSpacing.gap10),
            _ReviewRow(label: row.$1, value: row.$2),
          ],
        ],
      ),
    ),
    FamilyBookCard(
      padding: const EdgeInsets.all(AppSpacing.gap16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _CardHeading(text: t('members')),
          // `mb-2`
          const SizedBox(height: AppSpacing.gap8),
          if (members.isEmpty)
            Padding(
              // `py-2`
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.gap8),
              child: Text(
                '$kFamilyBookPageNamespace.noMembers'.tr(context: context),
                style: const TextStyle(
                  fontSize: AppTypography.size14,
                  color: AppColors.muted,
                ),
              ),
            )
          else
            for (int i = 0; i < members.length; i++)
              _ReviewMemberRow(
                member: members[i],
                index: i,
                isLast: i == members.length - 1,
              ),
        ],
      ),
    ),
  ];
}

/// `:507-512` and `:515-519` — the amber notice and the red one. One shape,
/// two palettes.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.fill,
    required this.outline,
    required this.glyph,
    required this.ink,
    required this.text,
  });

  final Color fill;
  final Color outline;
  final Color glyph;
  final Color ink;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.gap16),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
          border: Border.all(color: outline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              // `mt-0.5`
              padding: const EdgeInsets.only(top: AppSpacing.gap2),
              child: LucideIcon(
                name: 'AlertCircle',
                size: AppSpacing.gap16,
                color: glyph,
              ),
            ),
            // `gap-2.5`
            const SizedBox(width: AppSpacing.gap10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: AppTypography.size12,
                  height: AppTypography.lineRelaxed,
                  color: ink,
                ),
              ),
            ),
          ],
        ),
      );
}

/// `text-xs font-semibold text-gray-500 uppercase tracking-wider` — `:522`,
/// `:544`.
class _CardHeading extends StatelessWidget {
  const _CardHeading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: AppTypography.size12,
          fontWeight: AppTypography.semiBold,
          letterSpacing: FamilyBookSectionLabel.tracking,
          color: AppColors.muted,
        ),
      );
}

/// One `label / value` line of the household card — `:536-539`.
class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: AppTypography.size14,
              color: AppColors.muted,
            ),
          ),
          // `gap-3`
          const SizedBox(width: AppSpacing.gap12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: AppTypography.size14,
                fontWeight: AppTypography.medium,
                color: AppColors.gray800,
              ),
            ),
          ),
        ],
      );
}

/// One member line of the review card — `:550-561`.
class _ReviewMemberRow extends StatelessWidget {
  const _ReviewMemberRow({
    required this.member,
    required this.index,
    required this.isLast,
  });

  final HouseholdMember member;
  final int index;

  /// `last:border-0` — `:550`.
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final FamilyBookTranslate t = _translator(context);
    return Container(
      // `py-1.5`
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.gap6),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.gray50),
              ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  // `{m.name || t("memberN", {n: i + 1})}` — `:552`. The
                  // fallback is the member's ordinal, NOT the dash.
                  member.name.isNotEmpty
                      ? member.name
                      : '$kFamilyBookNamespace.memberN'.tr(
                          context: context,
                          namedArgs: <String, String>{'n': '${index + 1}'},
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppTypography.size14,
                    fontWeight: AppTypography.medium,
                    color: AppColors.gray800,
                  ),
                ),
                Text(
                  // P-8. A blank relation contributes NOTHING here, while the
                  // same blank renders `—` in step 2's `ReadField`. Both are
                  // the source (`F4-AC-48`).
                  memberSubLine(member, t),
                  style: const TextStyle(
                    fontSize: AppTypography.size12,
                    color: AppColors.gray400Inline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.gap12),
          Text(
            // `{m.status || "—"}` — `:560`, raw again.
            orDash(member.status),
            style: const TextStyle(
              fontSize: AppTypography.size12,
              color: AppColors.gray400Inline,
            ),
          ),
        ],
      ),
    );
  }
}

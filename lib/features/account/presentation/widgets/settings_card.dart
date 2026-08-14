/// The three settings groups and the rows inside them — `AccountPage.tsx`'s
/// `Row` component (`:131-176`) and the `<div>` wrapper each group repeats
/// (`:493-497`, `:559-563`, `:648-652`).
///
/// ## The accordion is single-open, and `openPanel` is ONE nullable key
///
/// `:186` is `useState<string | null>(null)` and `:304` is
/// `toggle = (key) => setOpenPanel(cur => cur === key ? null : key)`.
/// **Opening one panel closes any other**, across all three groups — the four
/// keys (`profile`, `notifications`, `language`, `security`) share one slot,
/// not one boolean each. B8-AC-43. That state lives on `AccountPage` and is
/// passed down as [SettingsRow.open]; a per-row `bool` here would make
/// four-open-at-once representable, which is the bug this note exists to
/// prevent.
///
/// ## Three row shapes, and the third is a source quirk
///
/// | Row | `onClick` | Chevron | Behaviour |
/// |---|---|---|---|
/// | `personalInfo`, `notifications`, `language`, `privacySecurity` | toggles | `ChevronDown`, rotates 180° when open | opens a panel |
/// | `phoneNumber`, `emailAddress`, `paymentMethods` | **none** | `ChevronRight` | inert |
/// | `helpSupport` | `navigateTo("help")` | **`ChevronDown`** | navigates |
///
/// `Row`'s chevron branch is `onClick ? <ChevronDown/> : <ChevronRight/>`
/// (`:165-171`) — it keys off *having a handler*, not off *being a panel*. So
/// `helpSupport` (`:709-715`) renders a down-chevron while behaving like a
/// link. **That is ported, not corrected** (B8-AC-44), and it is why
/// [SettingsRow] takes `onTap` and `open` as independent parameters rather than
/// inferring one from the other: an AC that merely checked the row is tappable
/// would pass with either behaviour.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

/// One group: an uppercase label and a white rounded card.
///
/// `text-xs text-gray-400 uppercase tracking-wider mb-2 px-1` over
/// `bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden`.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.label, required this.children});

  final String label;
  final List<Widget> children;

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
            // `uppercase` is a CSS transform, so the *rendered* text differs
            // from the i18n value. Applied here for the same reason the web
            // applies it in CSS: the dictionary holds the sentence-case string.
            //
            // `toUpperCase()` is a no-op for Lao script, which has no case —
            // so the Lao column renders the dictionary value unchanged, in both
            // the web and here. Tier 1 compares what is rendered, and that is
            // why the transform lives at the render site.
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.gray400,
              fontSize: AppTypography.size12,
              letterSpacing: 0.5, // `tracking-wider` = 0.05em at 12 px
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

/// `Row` — `AccountPage.tsx:131-176`.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    required this.desc,
    required this.divider,
    this.open = false,
    this.onTap,
    this.child,
  });

  /// A lucide component name. All six on this page — `User`, `Phone`, `Mail`,
  /// `Bell`, `Globe`, `CreditCard`, `Shield`, `HelpCircle` — are page chrome,
  /// **not** API-supplied, so they are passed to [LucideIcon] directly rather
  /// than resolved through `AppIcons.service` / `.help`. The scoping rule
  /// exists for names the catalogue sends; see `lucide_icon.dart`'s note.
  final String icon;

  final String label;

  /// `desc` — the grey second line. For `phoneNumber` and `emailAddress` it is
  /// **the citizen's own value**, not a description (`:553-554`).
  final String desc;

  /// `divider` — `border-b border-gray-50` on all but the last row of a card.
  final bool divider;

  /// `open` — drives the chevron's 180° rotation and whether [child] renders.
  /// Meaningless when [onTap] is null; see the library doc's third row shape.
  final bool open;

  /// `onClick`. **Null means inert AND `ChevronRight`** — the two are one
  /// branch in the source (`:165`).
  final VoidCallback? onTap;

  /// The panel body. Rendered only when `open && children` (`:173`).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: divider
            ? const Border(bottom: BorderSide(color: AppColors.gray50))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Material(
            color: AppColors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                // `px-5 py-4` — `:153`.
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gap20,
                  vertical: AppSpacing.gap16,
                ),
                child: Row(
                  children: <Widget>[
                    // `w-10 h-10 rounded-xl bg-[#EEF2FF]` with a `w-5 h-5`
                    // `#344EAD` glyph — `:155-160`.
                    Container(
                      width: AppSpacing.control40,
                      height: AppSpacing.control40,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXl),
                      ),
                      child: Center(
                        child: LucideIcon(
                          name: icon,
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
                          Text(
                            label,
                            style: const TextStyle(
                              color: AppColors.gray800,
                              fontSize: AppTypography.size14,
                              fontWeight: AppTypography.medium,
                            ),
                          ),
                          Text(
                            desc,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis, // `truncate`
                            style: const TextStyle(
                              color: AppColors.gray400,
                              fontSize: AppTypography.size12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.gap16),
                    // `onClick ? <ChevronDown rotate-180 when open/> :
                    // <ChevronRight/>` — see the library doc.
                    if (onTap != null)
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 150),
                        turns: open ? 0.5 : 0,
                        child: const LucideIcon(
                          name: 'ChevronDown',
                          size: AppSpacing.gap16,
                          color: AppColors.gray300,
                        ),
                      )
                    else
                      const LucideIcon(
                        name: 'ChevronRight',
                        size: AppSpacing.gap16,
                        color: AppColors.gray300,
                      ),
                  ],
                ),
              ),
            ),
          ),
          // `{open && children && <div className="px-5 pb-5 -mt-1">…}` —
          // `:173`. **Both conditions**, so an open row with no body renders
          // nothing rather than an empty box.
          if (open && child != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gap20,
                0,
                AppSpacing.gap20,
                AppSpacing.gap20,
              ),
              child: child,
            ),
        ],
      ),
    );
  }
}

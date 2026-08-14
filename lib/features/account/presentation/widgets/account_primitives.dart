/// The four small controls `AccountPage` draws that `lib/presentation/common/`
/// does not own yet: the toggle switch, the text input, the button and the
/// skeleton block.
///
/// ## Why these are hand-rolled inside the feature (specs.md § 6.6 ground 1)
///
/// `AccountPage.tsx:25` imports `Button` from `./Button`, and `ssd.md` § 4.4
/// assigns `Button` — with `DialogShell`, `GlassIcon`, `LoadingScreen` and
/// `Footer` — to `lib/presentation/common/`, landing in **B10**, which is being
/// implemented concurrently with this batch. Reaching for a primitive that is
/// mid-flight in another agent's working tree is how two batches end up
/// disagreeing about one widget's API.
///
/// So [AccountButton] is B8's own, scoped to
/// `features/account/presentation/widgets/`, and it is a **deliberate
/// duplicate with a stated expiry**: when B10's `AppButton` lands and settles,
/// FU-2's follow-up replaces this. § 6.6 draws the line explicitly — a *button*
/// is worth hand-rolling privately for one page, a *modal shell* is not, which
/// is why `DocumentViewer` is deferred instead.
///
/// [AccountTextField] is not shared with anyone: `inputBase`
/// (`AccountPage.tsx:77-78`) is a class string local to this component.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

/// `Toggle` — `AccountPage.tsx:102-128`.
///
/// `w-11 h-6 rounded-full p-0.5` with a `w-5 h-5` white knob that translates by
/// `translate-x-5` when on; track `#344EAD` when checked and `#E5E7EB` when
/// not (`:119`).
///
/// **Not a Material `Switch`.** Material's switch is a different size, a
/// different shape and carries its own theme-driven colours; matching the
/// source's 44×24 track with a 20 px knob means drawing it. `role="switch"` +
/// `aria-checked` + `aria-label` (`:114-116`) become `Semantics(toggled:,
/// label:)`, which is what a screen reader announces as a switch.
class AccountToggle extends StatelessWidget {
  const AccountToggle({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;

  /// `aria-label={label}` — `:116`. The same string the visible row shows,
  /// which is what the source passes.
  final String label;

  final ValueChanged<bool> onChanged;

  /// `w-11` = 44 px, `h-6` = 24 px, `p-0.5` = 2 px, knob `w-5 h-5` = 20 px.
  /// `translate-x-5` = 20 px. B8-AC-38 asserts the track dimensions.
  static const double trackWidth = 44;
  static const double trackHeight = 24;
  static const double knobSize = 20;
  static const double trackPadding = 2;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: label,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: trackWidth,
          height: trackHeight,
          padding: const EdgeInsets.all(trackPadding),
          decoration: BoxDecoration(
            color: value ? AppColors.primary : AppColors.gray200,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 150),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: knobSize,
              height: knobSize,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(color: AppColors.cardShadowMedium, blurRadius: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `inputBase` — `AccountPage.tsx:77-78`.
///
/// `w-full px-4 py-2.5 rounded-xl border border-gray-200 bg-gray-50
/// text-gray-800 text-sm` with a `#344EAD` focus border and a gray-400
/// placeholder.
class AccountTextField extends StatelessWidget {
  const AccountTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
  });

  final TextEditingController controller;

  /// `placeholder` — only the three password inputs have one (`:681`, `:689`,
  /// `:697`); the profile editor's three carry a `<label>` above instead
  /// (`:508`, `:521`, `:535`), which is [FieldLabel]'s job.
  final String? hintText;

  final bool obscureText;
  final TextInputType? keyboardType;

  /// `autoComplete="current-password"` / `"new-password"` — `:680`, `:688`,
  /// `:696`. Ported so a password manager behaves the same way it does on the
  /// web.
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    const OutlineInputBorder resting = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusXl)),
      borderSide: BorderSide(color: AppColors.gray200),
    );

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      style: const TextStyle(
        color: AppColors.gray800,
        fontSize: AppTypography.size14,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.gray50,
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.gray400,
          fontSize: AppTypography.size14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gap16,
          vertical: AppSpacing.gap10,
        ),
        border: resting,
        enabledBorder: resting,
        // `focus:bg-white focus:border-[#344EAD] focus:ring-2` — the ring is a
        // 2 px outer glow in CSS; a 2 px border is the closest Material
        // analogue and is what `auth`'s fields already do.
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusXl)),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

/// The `<label className="block text-xs font-medium text-gray-600 mb-1.5">`
/// above each profile input — `AccountPage.tsx:508-510`.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.gap6),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.gray600,
            fontSize: AppTypography.size12,
            fontWeight: AppTypography.medium,
          ),
        ),
      );
}

/// `Button` — `AccountPage.tsx:25`, hand-rolled for this page only. See the
/// library doc.
///
/// Two variants are used on this page: the default (`size="md"`, brand fill —
/// `:548`, `:703`) and `variant="secondary" size="sm"` for the three retry
/// buttons (`:386`, `:412`, `:576`).
class AccountButton extends StatelessWidget {
  const AccountButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.secondary = false,
  });

  final String label;

  /// Null disables. `Button`'s own `loading` prop also disables, which is why
  /// [loading] gates `onPressed` below rather than only swapping the child.
  final VoidCallback? onPressed;

  final bool loading;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !loading;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: secondary ? AppColors.white : AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: secondary ? Border.all(color: AppColors.gray200) : null,
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: secondary ? AppSpacing.gap12 : AppSpacing.gap16,
              vertical: secondary ? AppSpacing.gap6 : AppSpacing.gap10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (loading) ...<Widget>[
                  const SizedBox(
                    width: AppSpacing.gap12,
                    height: AppSpacing.gap12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gap8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: secondary ? AppColors.gray700 : AppColors.white,
                    fontSize: secondary
                        ? AppTypography.size12
                        : AppTypography.size14,
                    fontWeight: AppTypography.medium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `animate-pulse` grey block — `AccountPage.tsx:401` (`h-16 rounded-xl
/// bg-gray-100`) and `:572` (`h-20`).
///
/// Static, not animated. The pulse is a CSS keyframe; a `ticker` here would run
/// a repeating animation in every widget test that renders a loading state and
/// wedge `pumpAndSettle`, which is a cost this project has already paid once
/// (`tier1_chat_test.dart`'s drain note). A skeleton contributes no text, which
/// is what Tier 1 measures.
class AccountSkeleton extends StatelessWidget {
  const AccountSkeleton({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
      );
}

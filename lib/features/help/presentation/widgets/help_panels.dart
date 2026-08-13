/// The help centre's shared chrome: skeleton, `ErrorBlock`, primary button.
///
/// [HelpErrorBlock] is the direct port of `HelpCenterPage.tsx:70-83`'s
/// `ErrorBlock`, which the source itself factors out and uses at four call
/// sites (`:269`, `:404`, `:441`, `:477`). § 6.6 names it as *"the pattern to
/// port"*.
///
/// The **message is the app's own fixed sentence**, not `error.message`: the
/// source prints the backend's, and `ServicePage.tsx:227-232` (the branch B2a
/// ported) does not. A server sentence on a citizen-facing page leaks backend
/// detail.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

/// `py-10` — 40 CSS px, `ErrorBlock`'s vertical padding.
const double kHelpErrorPaddingY = AppSpacing.gap40;

/// `py-14` — 56 CSS px, the no-results block's.
const double kHelpEmptyPaddingY = AppSpacing.tile56;

/// A grey block. Static rather than animated, for the reason
/// `news_panels.dart` gives: a running `animate-pulse` equivalent makes a
/// widget test either never settle or assert on a random frame.
class HelpSkeleton extends StatelessWidget {
  const HelpSkeleton({
    super.key,
    required this.height,
    this.width,
    this.radius = AppSpacing.radiusLg,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// `HelpCenterPage.tsx:70-83` — `text-center py-10`, message, `Try again`.
class HelpErrorBlock extends StatelessWidget {
  const HelpErrorBlock({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.verticalPadding = kHelpErrorPaddingY,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Column(
        children: <Widget>[
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.gray800,
              fontSize: AppTypography.size14,
              fontWeight: AppTypography.semiBold,
            ),
          ),
          const SizedBox(height: AppSpacing.gap16),
          HelpPrimaryButton(label: retryLabel, onPressed: onRetry),
        ],
      ),
    );
  }
}

/// `px-5 py-2.5 rounded-xl text-white text-sm font-semibold` on `#344EAD`.
class HelpPrimaryButton extends StatelessWidget {
  const HelpPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailing,
  });

  final String label;
  final VoidCallback onPressed;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gap20,
          vertical: AppSpacing.gap10,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        textStyle: const TextStyle(
          fontSize: AppTypography.size14,
          fontWeight: AppTypography.semiBold,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // `Flexible`, not a bare `Text` — B2-AC-15. The Lao labels are wider
          // than their English counterparts and an unflexible `Text` inside a
          // `mainAxisSize.min` `Row` takes its intrinsic width and reports a
          // RenderFlex overflow; `ຕິດຕໍ່ຝ່າຍຊ່ວຍເຫຼືອ` plus its chevron runs 22 px
          // past the width the "Still need help?" card leaves at 390. Caught by
          // the Lao half of the Tier 1 suite.
          Flexible(child: Text(label)),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: AppSpacing.gap8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

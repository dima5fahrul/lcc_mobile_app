/// The four-state chrome both news pages share: skeleton, error, empty.
///
/// § 6.6 is binding — *every* network-backed surface renders loading · data ·
/// empty · error-with-retry, and a missing state is a **Tier 1** failure, not
/// polish. These are the three that are not "data".
///
/// Deliberately a news-local file rather than a reach into
/// `features/home/presentation/widgets/home_panels.dart`: G-L3 forbids that
/// import, and the two are not the same widgets anyway — Home's error notice is
/// an inline red strip inside a section, and news' is `text-center py-12` with
/// a filled primary button (`NewsPage.tsx:139-149`).
library;

import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

/// `py-12` — 48 CSS px, the vertical padding on both news panels
/// (`NewsPage.tsx:140,151`).
///
/// Derived from the scale rather than written as `48`, and **not** added to
/// `AppSpacing` as a `gap48`: `lib/presentation/theme/**` is B2a's and is not in
/// B2c's § 3.1 modify list, so adding a step there would be an out-of-scope
/// path (B2-AC-38). Expressed as an arithmetic over two existing steps so the
/// value stays traceable to the scale instead of becoming the bare literal
/// `AppSpacing`'s own doc warns about.
const double kNewsPanelPaddingY = AppSpacing.gap24 * 2;

/// A grey pulse block. Static rather than animated: `animate-pulse` is a
/// Tailwind opacity keyframe, and a widget test that pumps a running animation
/// either settles forever or asserts on a random frame.
class NewsSkeleton extends StatelessWidget {
  const NewsSkeleton({
    super.key,
    required this.height,
    this.width,
    this.radius = AppSpacing.radiusLg,
    this.color = AppColors.gray100,
  });

  final double height;
  final double? width;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// `text-center py-12` + message + a filled primary "Try again".
///
/// Ports `NewsPage.tsx:139-149`. The **message is the app's own fixed
/// sentence**, not `list.error.message`: the source prints the backend's
/// sentence, and `ServicePage.tsx:227-232` (the branch B2a ported) does not.
/// Printing a server string on a citizen-facing page is how backend detail
/// leaks into the UI.
class NewsErrorBlock extends StatelessWidget {
  const NewsErrorBlock({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.verticalPadding = kNewsPanelPaddingY,
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
          NewsPrimaryButton(label: retryLabel, onPressed: onRetry),
        ],
      ),
    );
  }
}

/// `text-center text-gray-500 text-sm py-12` — `NewsPage.tsx:151`.
class NewsEmptyBlock extends StatelessWidget {
  const NewsEmptyBlock({
    super.key,
    required this.message,
    this.verticalPadding = kNewsPanelPaddingY,
  });

  final String message;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.gray500,
            fontSize: AppTypography.size14,
          ),
        ),
      );
}

/// `px-5 py-2.5 rounded-xl text-white text-sm font-semibold` on `#344EAD` —
/// the source's one filled control, used by the error blocks and by the
/// detail page's "Open service".
class NewsPrimaryButton extends StatelessWidget {
  const NewsPrimaryButton({
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
    return Align(
      // `inline-flex` — the button hugs its label instead of filling the row.
      alignment: Alignment.center,
      child: ElevatedButton(
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
            // `Flexible`, not a bare `Text` — B2-AC-15. An unflexible `Text`
            // inside a `mainAxisSize.min` `Row` takes its intrinsic width and
            // reports a RenderFlex overflow on the wider Lao labels; the same
            // defect in help's copy of this button was caught by the Lao half
            // of the Tier 1 suite and is fixed here before it can fire.
            Flexible(child: Text(label)),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: AppSpacing.gap8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

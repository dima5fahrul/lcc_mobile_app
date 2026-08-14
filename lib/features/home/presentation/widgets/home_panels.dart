/// The three shapes every network-backed region on Home takes when it has no
/// data: **skeleton**, **error-with-retry**, **empty**.
///
/// § 6.6 makes four states mandatory per surface and B2-AC-16 asserts each one.
/// Home has five such surfaces, and the source draws the same three panels for
/// all of them with only the sentence changing (`HomePage.tsx:325-335`,
/// `:465-479`, `:629-643`, `:745-749`). Writing them once is not a refactor of
/// the port — it is the port: the markup is literally repeated.
///
/// ## Why the skeleton does not pulse
///
/// `animate-pulse` is a CSS opacity keyframe that runs forever. Ported as an
/// `AnimationController` it would make `pumpAndSettle` **time out on every test
/// that lands on `/`** — and `/` is `initialLocation`, so that is every
/// assembled-app flow test in `test/app/` and every shell test in
/// `test/presentation/shell/`, not just Home's own. B2a hit the same wall on
/// `ServicePage` and worked around it by never settling in that file's tests;
/// that option is not available here, because the pages asserting on Home's
/// route are not Home's tests and cannot be asked to stop settling.
///
/// So the skeleton is a static tile. It is a deliberate mechanism divergence
/// with no fidelity consequence a gate can see — Tier 1 compares text (a
/// skeleton has none), Tier 2 compares token values (the fill is
/// [AppColors.gray100] either way), and Tier 3 compares a single captured
/// frame. It is recorded here rather than discovered as "why is Home's
/// skeleton flat".
library;

import 'package:flutter/material.dart';

import '../../../../presentation/common/app_button.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

/// One grey placeholder tile — `bg-gray-100 rounded-2xl animate-pulse`, minus
/// the pulse (see the library doc).
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({
    super.key,
    required this.height,
    this.width,
    this.radius = AppSpacing.radius2xl,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// The red notice with a "Try again" button.
///
/// `HomePage.tsx:326-334`: `AlertCircle` glyph, the message, and a small
/// secondary `Button` bound to that query's `refetch`.
///
/// [message] is the **fixed bilingual sentence**, never the server's words.
/// The source writes `{summary.error.message || c("summaryError")}` and prefers
/// the backend's text when there is any; this does not, for the reason
/// `home_repository_impl.dart` records — a server sentence rendered on a page
/// that also prints a citizen's UIN is backend detail leaking onto an
/// authenticated surface, and `ServicePage.tsx:227-232` (the page B2a ported)
/// already shows only the fixed copy.
class HomeErrorNotice extends StatelessWidget {
  const HomeErrorNotice({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      // `flex items-center gap-3 p-4 rounded-2xl border border-red-100
      //  bg-red-50`
      padding: const EdgeInsets.all(AppSpacing.gap16),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        border: Border.all(color: AppColors.dangerOutlineSoft),
      ),
      child: Row(
        children: <Widget>[
          const LucideIcon(
            name: 'AlertCircle',
            size: AppSpacing.gap20,
            color: AppColors.dangerGlyph,
          ),
          const SizedBox(width: AppSpacing.gap12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.dangerText,
                fontSize: AppTypography.size14,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.gap12),
          // `<Button size="sm" variant="secondary" onClick={…refetch}>` —
          // `HomePage.tsx`:331, :471, :635. **These three are the Flutter home
          // of the source's three retry buttons**, and B10 § 6.5 requires
          // `AppButton` to ship wired into them rather than as speculative
          // infrastructure (`B10-AC-43`).
          //
          // B2b wrote this as a hand-styled `OutlinedButton` because
          // `Button.tsx` was B10's to port and did not exist yet. Its comment
          // said *"white fill, grey hairline, grey-700 label"* — and that was
          // a **divergence from the source it was describing**: `Button.tsx`'s
          // `secondary` row (:45) is `{ bg: "#FFFFFF", fg: "#344EAD",
          // border: "#C7D0EA" }`, i.e. a *primary-blue* label over a
          // *periwinkle* hairline, not grey over grey. Routing through
          // `AppButton` corrects both to the measured values; that colour
          // change is the visible half of this wiring and is stated in the
          // batch report rather than left for Tier 2 to discover.
          AppButton(
            onPressed: onRetry,
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.sm,
            child: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}

/// The centred grey sentence a region shows when it fetched successfully and
/// got nothing — `HomePage.tsx:478`, `:642`, `:746`.
///
/// `text-gray-400`, which is `theme.css:92`'s accessible override rather than
/// the stock value, because the source writes it as a *class* here and not as
/// an inline hex (contrast `ServicePage.tsx:465`, which is why
/// [AppColors.gray400Inline] exists).
class HomeEmptyNotice extends StatelessWidget {
  const HomeEmptyNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // `text-center py-10`
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.gap40),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.gray400,
          fontSize: AppTypography.size14,
        ),
      ),
    );
  }
}

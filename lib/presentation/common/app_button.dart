/// Port of `lcc-app/src/app/components/Button.tsx` (123 lines) — the web's
/// single source of truth for CTA states.
///
/// ## What the source is for, in its own words
///
/// `Button.tsx`:6-19 records that the UI/UX evaluation scored *"Component
/// Visual Polish"* at 8.5 because only happy-path states existed, and it
/// enumerates the full set it added:
///
/// | STATE | TRIGGER | BEHAVIOUR |
/// |---|---|---|
/// | default | — | solid brand fill |
/// | hover | `:hover` | 90 % opacity, no layout shift |
/// | focus | `:focus-visible` | 3 px ring |
/// | loading | `loading` | spinner + `aria-busy`, clicks ignored |
/// | disabled | `disabled` | 50 % opacity, **not** focusable |
/// | error | `error="message"` | danger border + inline live message |
///
/// The last three are the reason this widget exists, and they are the three a
/// port loses by accident: a `loading` flag that is accepted and never
/// rendered, or an `error` string that switches nothing, passes any "the
/// widget builds" assertion. `B10-AC-24`, `B10-AC-44` and `B10-AC-45` assert
/// them by *rendering*, not by parameter presence.
///
/// ## B10 does not retrofit the ten ad-hoc buttons already in this tree
///
/// § 6.5. `CtaButton`, `ChatLauncherButton`, `NewsPrimaryButton`,
/// `HelpPrimaryButton`, `_HeaderButton`, `_PillButton`, `_BellButton`,
/// `_LinkButton` and two `_PagerButton`s live in six features owned by B2, B9
/// and F0. Three reasons not to touch them, in order of weight:
///
/// 1. Rewriting them is a non-additive, cross-batch refactor against four
///    concurrently-authored specs.
/// 2. They are not all the same widget. A pager arrow and a notification bell
///    are not CTAs, and collapsing them into this one would be a design change
///    with no source — which ADR-0003 forbids.
/// 3. **The web itself does not use `Button` everywhere.** Measured: exactly
///    two files import it, `HomePage.tsx`:22 and `AccountPage.tsx`:25. A
///    Flutter tree where `AppButton` were universal would be *more* consistent
///    than the source — the R-25 class of invisible divergence.
///
/// It does ship with real consumers rather than as speculative infrastructure:
/// `HomeErrorNotice` (`features/home/presentation/widgets/home_panels.dart`)
/// is the Flutter home of the source's three `<Button size="sm"
/// variant="secondary">` retry buttons, and it now renders this widget. See
/// the batch report for the § 3.1 scope note that wiring carries.
///
/// ## Two Flutter mechanisms worth naming
///
/// **`loading` keeps the control focusable.** `Button.tsx`:89-91 swallows the
/// click *without* setting `disabled`, so a screen-reader user is not stranded
/// mid-tab-order. The port therefore passes a **non-null no-op** `onPressed`
/// while loading rather than `null` — `null` is what makes a Material button
/// unfocusable, which is the `disabled` behaviour, not this one.
///
/// **`opacity-50` is an [Opacity] wrapper, not a colour blend.** The source
/// dims the whole control including its border and its label; recolouring the
/// fill alone would leave a full-strength border around a dimmed label.
library;

import 'package:flutter/material.dart';

import '../icons/lucide_icon.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// `Button.tsx`:28's `ButtonVariant`.
enum AppButtonVariant { primary, secondary, amber, danger, ghost }

/// `Button.tsx`:29's `ButtonSize`.
enum AppButtonSize { sm, md, lg }

/// One row of `Button.tsx`:44-50's `VARIANTS` table.
///
/// A record rather than three parallel maps: the source states the three
/// colours together because they are chosen together, and the amber row's
/// dark foreground is only defensible when read beside its fill.
typedef AppButtonColors = ({Color bg, Color fg, Color border});

/// `Button.tsx`:52-56's `SIZES`, resolved from Tailwind to logical pixels.
typedef AppButtonMetrics = ({
  double px,
  double py,
  double fontSize,
  double radius,
  double gap,
});

/// The shared CTA.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.loading = false,
    this.error,
    this.fullWidth = false,
    this.leadingIcon,
    this.trailingIcon,
  });

  /// `children` — the label. A widget rather than a `String` because the
  /// source accepts arbitrary `ReactNode`.
  final Widget child;

  /// `onClick`. Null is the source's `disabled`: an omitted handler on a `<button>`
  /// is inert, and Material's convention is the same, so the two agree.
  final VoidCallback? onPressed;

  final AppButtonVariant variant;
  final AppButtonSize size;

  /// Spinner + `aria-busy`; clicks ignored, focus retained. See the library doc.
  final bool loading;

  /// `error="message"` — switches the border to [AppColors.danger] **and**
  /// renders the message below as a live region (`Button.tsx`:100, :111-120).
  /// Null and empty are both "no error", matching JSX's falsy test.
  final String? error;

  final bool fullWidth;

  /// Suppressed while [loading] — the spinner takes its place
  /// (`Button.tsx`:103-107).
  final Widget? leadingIcon;

  /// Also suppressed while [loading] (`:109`).
  final Widget? trailingIcon;

  /// `Button.tsx`:44-50, verbatim.
  static AppButtonColors colorsFor(AppButtonVariant variant) {
    switch (variant) {
      case AppButtonVariant.primary:
        return (
          bg: AppColors.primary,
          fg: AppColors.white,
          border: AppColors.primary,
        );
      case AppButtonVariant.secondary:
        return (
          bg: AppColors.white,
          fg: AppColors.primary,
          border: AppColors.trackingConnector,
        );
      case AppButtonVariant.amber:
        // Dark text, measured 6.83:1. White on #F59E0B is 2.15:1 and fails
        // WCAG 1.4.3 — `Button.tsx`:24-25 says so in the source, and the note
        // travels with the value so nobody "tidies" it back to white.
        return (
          bg: AppColors.warningStrong,
          fg: AppColors.gray800,
          border: AppColors.warningStrong,
        );
      case AppButtonVariant.danger:
        return (
          bg: AppColors.danger,
          fg: AppColors.white,
          border: AppColors.danger,
        );
      case AppButtonVariant.ghost:
        return (
          bg: AppColors.transparent,
          fg: AppColors.buttonGhostInk,
          border: AppColors.transparent,
        );
    }
  }

  /// `Button.tsx`:52-56's Tailwind classes at the 16 px root:
  /// `px-3 py-2 text-xs rounded-lg gap-1.5` → 12 / 8 / 12 / 8 / 6, and so on.
  static AppButtonMetrics metricsFor(AppButtonSize size) {
    switch (size) {
      case AppButtonSize.sm:
        return (
          px: AppSpacing.gap12,
          py: AppSpacing.gap8,
          fontSize: AppTypography.size12,
          radius: AppSpacing.radiusLg,
          gap: AppSpacing.gap6,
        );
      case AppButtonSize.md:
        return (
          px: AppSpacing.gap20,
          py: AppSpacing.gap10,
          fontSize: AppTypography.size14,
          radius: AppSpacing.radiusXl,
          gap: AppSpacing.gap8,
        );
      case AppButtonSize.lg:
        return (
          px: AppSpacing.gap24,
          py: AppSpacing.gap14,
          fontSize: AppTypography.size14,
          radius: AppSpacing.radiusXl,
          gap: AppSpacing.gap8,
        );
    }
  }

  bool get _hasError => error != null && error!.isNotEmpty;

  /// `disabled` is `Boolean(disabled)` in the source; here an absent handler.
  /// **Loading is not disabled** — see the library doc.
  bool get _isDisabled => onPressed == null && !loading;

  @override
  Widget build(BuildContext context) {
    final AppButtonColors v = colorsFor(variant);
    final AppButtonMetrics m = metricsFor(size);

    final Widget button = _button(v, m);

    final Widget column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          fullWidth ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
      children: <Widget>[
        // `opacity-50` covers fill, border and label together (library doc).
        if (_isDisabled) Opacity(opacity: 0.5, child: button) else button,
        if (_hasError) ...<Widget>[
          const SizedBox(height: AppSpacing.gap6),
          _errorMessage(m),
        ],
      ],
    );

    // `<span className={fullWidth ? "block w-full" : "inline-block"}>` — the
    // source's wrapper is what makes `fullWidth` stretch the button *and* left-
    // align the error beneath it.
    return fullWidth
        ? SizedBox(width: double.infinity, child: column)
        : column;
  }

  Widget _button(AppButtonColors v, AppButtonMetrics m) {
    final List<Widget> row = <Widget>[
      if (loading)
        SizedBox(
          // `w-4 h-4 animate-spin` — Material's indicator is the framework's
          // equivalent of lucide's `Loader2`; there is no `Loader2` glyph in
          // the bundled set and inventing one would be a divergence.
          width: AppSpacing.gap16,
          height: AppSpacing.gap16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(v.fg),
          ),
        )
      else if (leadingIcon != null)
        leadingIcon!,
      child,
      // `{!loading && trailingIcon}` — `Button.tsx`:109.
      if (!loading && trailingIcon != null) trailingIcon!,
    ];

    return Semantics(
      button: true,
      enabled: !_isDisabled,
      // `aria-busy={loading || undefined}`.
      liveRegion: false,
      child: TextButton(
        // A non-null no-op while loading: `Button.tsx`:91 swallows the click
        // *without* disabling, so the control stays in the tab order.
        onPressed: loading ? () {} : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: v.bg,
          foregroundColor: v.fg,
          disabledBackgroundColor: v.bg,
          disabledForegroundColor: v.fg,
          padding: EdgeInsets.symmetric(horizontal: m.px, vertical: m.py),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          animationDuration: AppMotion.buttonState,
          textStyle: TextStyle(
            fontSize: m.fontSize,
            fontWeight: AppTypography.semiBold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(m.radius),
            side: BorderSide(
              // `borderColor: error ? "#DC2626" : v.border` — `:100`.
              color: _hasError ? AppColors.danger : v.border,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (int i = 0; i < row.length; i++) ...<Widget>[
              if (i > 0) SizedBox(width: m.gap),
              row[i],
            ],
          ],
        ),
      ),
    );
  }

  /// `role="alert"` + `AlertCircle` + the message — `Button.tsx`:111-120.
  ///
  /// `liveRegion: true` is Flutter's `role="alert"`: it is what makes a screen
  /// reader announce the message when it appears without the user moving
  /// focus. Rendering the text without it would look identical and be
  /// inaccessible, which is exactly the kind of half-port `B10-AC-44` asserts
  /// against.
  Widget _errorMessage(AppButtonMetrics m) {
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const LucideIcon(
            name: 'AlertCircle',
            size: AppSpacing.gap14,
            color: AppColors.buttonErrorText,
          ),
          const SizedBox(width: AppSpacing.gap4),
          Flexible(
            child: Text(
              error!,
              style: const TextStyle(
                color: AppColors.buttonErrorText,
                fontSize: AppTypography.size12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

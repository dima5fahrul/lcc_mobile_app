/// The type scale and the `NotoSansLao` family wiring.
///
/// ## The family
///
/// One family for both locales. `NotoSansLao` carries Latin glyphs as well as
/// Lao ones, so pinning it app-wide keeps English and Lao rendering from the
/// same metrics — which is what makes the Lao page's greater height a *layout*
/// question rather than a font-substitution artefact. **AC-24** (the font is
/// declared, bundled and actually applied) is asserted against
/// `AppTheme.light().textTheme`, and this file is where the family it reads
/// comes from.
///
/// ## The scale
///
/// Tailwind's `text-*` ramp at the source's 16 px root (`theme.css:4`). The
/// names are the pixel sizes, for the same reason as `AppSpacing`: a reviewer
/// checking `text-xs` against [size12] should not have to remember a mapping.
///
/// ## What this file deliberately does NOT do
///
/// It does not hand `ThemeData` a populated `TextTheme`. Overriding Material's
/// default text sizes app-wide would silently re-lay-out every screen that
/// already shipped — including the frozen auth forms — which is a fidelity
/// change no ticket asked for, made invisibly, in the batch whose whole purpose
/// is to make fidelity measurable. The scale is published here for B2's new
/// surfaces to opt into per `TextStyle`; the global default stays Material's,
/// stamped with the family by `AppTheme`.
library;

import 'dart:ui' show FontWeight;

/// Type-scale tokens. Never instantiated.
abstract final class AppTypography {
  /// The bundled family. Declared in `pubspec.yaml`'s `fonts:` block with a
  /// 400 and a 700 face; the 700 face is what [bold] resolves to.
  static const String fontFamily = 'NotoSansLao';

  // ── Sizes (Tailwind text-* at a 16 px root) ────────────────────────────────

  /// `text-[11px]` — bottom-nav labels.
  static const double size11 = 11;

  /// `text-xs` — 12 px. Chips, helper text, the language toggle's label.
  static const double size12 = 12;

  /// `text-[13px]` — dense body copy in the auth forms.
  static const double size13 = 13;

  /// `text-sm` — 14 px.
  static const double size14 = 14;

  /// `text-[15px]` — 15 px. `ServiceCard.tsx:70`'s service description.
  static const double size15 = 15;

  /// `text-base` — 16 px. Body default.
  static const double size16 = 16;

  /// `text-lg` — 18 px.
  static const double size18 = 18;

  /// `text-xl` — 20 px.
  static const double size20 = 20;

  /// `text-2xl` — 24 px. Page titles.
  static const double size24 = 24;

  /// `text-3xl` — 30 px. Hero headline.
  static const double size30 = 30;

  // ── Weights ────────────────────────────────────────────────────────────────

  /// `font-normal` — `--font-weight-normal: 400` (`theme.css:23`).
  static const FontWeight regular = FontWeight.w400;

  /// `font-medium` — `--font-weight-medium: 500` (`theme.css:22`).
  static const FontWeight medium = FontWeight.w500;

  /// `font-semibold` — 600. The weight the brand wordmark and active nav use.
  static const FontWeight semiBold = FontWeight.w600;

  /// `font-bold` — 700. The one weight with its own bundled face.
  static const FontWeight bold = FontWeight.w700;

  // ── Line heights ───────────────────────────────────────────────────────────

  /// `leading-tight` — 1.2. Used by the two-line brand block, where the
  /// default 1.4+ would push the sub-brand out of a 64 px bar.
  static const double lineTight = 1.2;

  /// `leading-snug` — 1.375. Card titles and blurbs, which the source packs
  /// tighter than body copy (`ServicePage.tsx:457,460`, `ServiceCard.tsx:64`).
  static const double lineSnug = 1.375;

  /// `leading-normal` — 1.4.
  static const double lineNormal = 1.4;

  /// The `@layer base` line-height `theme.css:155` gives every `h1`–`h4`,
  /// `label`, `button` and `input`. Utility classes override the *size*, not
  /// this, so a heading that keeps its default size keeps 1.5 too.
  static const double lineBaseElement = 1.5;

  /// `leading-relaxed` — 1.6. Long-form article body.
  static const double lineRelaxed = 1.6;
}

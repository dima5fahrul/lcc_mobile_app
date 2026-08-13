/// Every colour the app draws with, as a named `const`.
///
/// **This file is the only place in `lib/**` allowed to hold a raw colour
/// literal** (SSD § 10.1, specs.md § 6.2). The single named exemption is the
/// grandfathered set under `features/auth/presentation/**`, which converts the
/// next time an auth page is unfrozen for another reason. New code has no
/// exemption.
///
/// ## Why this file exists at all
///
/// Fidelity **Tier 2 (design-token parity) is automated, blocking and
/// 100 %-required**, and it compares the web's tokens against the Flutter
/// theme **as values, not pixels**. Before this file there was nothing on the
/// Flutter side to compare *to*: `#344EAD` appeared as a hardcoded
/// `Color(0xFF344EAD)` in 20+ widget bodies, so Tier 2 could not return an
/// answer at all. A machine-readable token surface is the artefact that makes
/// the gate evaluable.
///
/// ## Provenance
///
/// The React app has no brand token layer either — the shadcn scaffolding in
/// `src/styles/theme.css` is generic and unrelated to LCC's palette, which is
/// written as inline hex at the point of use. So each token below cites the
/// source line it was read from, and the citation is the provenance record.
///
/// ## What is NOT in here, deliberately
///
/// **The colours the API supplies at runtime are data, not tokens.**
/// `ServiceCategory.color`, `Service.color` and `NewsCategory.color` arrive
/// over the wire as `#RRGGBB` strings and change without an app release. The
/// eight category colours visible in today's catalogue are **not** transcribed
/// here: hardcoding them would silently pin a value the server owns, and the
/// first time an administrator recolours a category the app would disagree with
/// the web for a whole release cycle. Parse them at the edge; pass them down as
/// values. [shade] exists precisely so a runtime-supplied colour can be
/// rendered the way the web renders it.
library;

import 'dart:ui' show Color;

/// Named colour tokens. Never instantiated.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  //
  // `Layout.tsx` writes these as inline hex at ~14 sites; they are the app's
  // actual brand palette.

  /// `#344EAD` — the LCC brand blue. Header bar, active nav, primary CTAs.
  /// `Layout.tsx:315` (`backgroundColor`), `:407` (active nav item).
  static const Color primary = Color(0xFF344EAD);

  /// `#EEF2FF` — the pale brand tint behind brand-coloured icons and tiles.
  /// `Layout.tsx:200`, `:210`, `:245`.
  static const Color primarySoft = Color(0xFFEEF2FF);

  /// `#F0F2F8` — the page wash behind every screen. `Layout.tsx:310`
  /// (`bg-[#F0F2F8]`).
  static const Color surface = Color(0xFFF0F2F8);

  /// `#6B7280` — inactive bottom-nav icon and label. `Layout.tsx:407`'s
  /// inactive branch.
  static const Color muted = Color(0xFF6B7280);

  /// `#101C48` — the sign-in backdrop base. `AuthPage.tsx:192`,
  /// `bg-[#101C48]`. Verified present in the web source.
  static const Color authGradientStart = Color(0xFF101C48);

  /// `#1A2A5E` — **the one token in this file with no web counterpart.**
  ///
  /// The doc these two constants shipped with (`3c0f974`) attributed them to
  /// *"`AuthPage.tsx` — `linear-gradient(#101C48 → #1A2A5E)`"*. Deriving the
  /// Tier 2 oracle caught it: `grep -rn 1A2A5E sources/lcc-app` returns
  /// **nothing** at `62f8a529`. That gradient does not exist. The web's
  /// backdrop is a flat `bg-[#101C48]` (`:192`) beneath an
  /// `rgba(14,28,75,…)` / `rgba(16,28,72,…)` photo overlay (`:215`).
  ///
  /// The value came from the *Flutter* page — `auth_page.dart:200` draws
  /// `[Color(0xFF101C48), Color(0xFF1A2A5E)]` — so this is a Flutter-only
  /// disparity that a token layer then documented as if it were a port.
  ///
  /// **Not fixed here, and that is a scope decision, not an oversight.** The
  /// AuthPage backdrop is exactly R-12's subject; R-12 is on specs.md § 6.5.5's
  /// closed pre-existing-disparity register, owned by
  /// `GOR-245-b1b2-r12-emblem-restoration`, and the auth pages are frozen
  /// (§ 4.2). The constant stays so the frozen page keeps rendering what it
  /// renders today; the Tier 2 oracle **excludes** it by name with this reason
  /// (`oracle/tier2/tokens.json` → `excluded.authGradientEnd`), because
  /// comparing it against the web would be comparing Flutter against itself.
  static const Color authGradientEnd = Color(0xFF1A2A5E);

  /// The 60 % and 100 % stops of the catalogue header's brand gradient,
  /// `linear-gradient(135deg, #344EAD 0%, #2A3F99 60%, #1E3070 100%)`
  /// (`ServicePage.tsx:362-365`). The 0 % stop is [primary].
  static const Color headerGradientMid = Color(0xFF2A3F99);
  static const Color headerGradientEnd = Color(0xFF1E3070);

  // ── Neutrals ───────────────────────────────────────────────────────────────
  //
  // Tailwind's stock grey ramp, EXCEPT the two the source deliberately
  // overrides for contrast — see [gray400] / [gray500].

  static const Color white = Color(0xFFFFFFFF);

  /// `rgb(0 0 0 / 0.05)` — Tailwind `shadow-sm`, the hairline lift under every
  /// catalogue card, panel and skeleton tile.
  static const Color cardShadow = Color(0x0D000000);

  /// `rgb(0 0 0 / 0.1)` — Tailwind `shadow-md`, under the search field.
  static const Color cardShadowMedium = Color(0x1A000000);

  /// `rgba(0,0,0,0.18)` — `GlassIcon.tsx`'s glyph drop-shadow
  /// (`drop-shadow(0 1px 1px rgba(0,0,0,0.18))`). Named here rather than
  /// written inline in `presentation/common/`, which has no exemption.
  static const Color glyphShadow = Color(0x2E000000);

  /// `#111827` — Tailwind `gray-900`. Headings and primary body text.
  static const Color gray900 = Color(0xFF111827);

  /// `#374151` — Tailwind `gray-700`. Field labels.
  static const Color gray700 = Color(0xFF374151);

  /// `#5A6472` — **not** Tailwind's stock `gray-500` (`#6A7282`).
  /// `theme.css:93` overrides it: the stock value reaches only 4.32:1 on the
  /// `#F0F2F8` app background, below the 4.5:1 AA minimum, across ~160 muted
  /// labels. This is the lightest value that still clears AA (6.00:1 on white,
  /// 5.36:1 on `#F0F2F8`). Porting the stock value instead would import an
  /// accessibility defect the web already fixed.
  static const Color gray500 = Color(0xFF5A6472);

  /// `#616B7A` — likewise an override of Tailwind's `gray-400` (`#99A1AF`,
  /// 2.6:1 on white). `theme.css:92`. 5.40:1 white / 4.82:1 on `#F0F2F8`.
  static const Color gray400 = Color(0xFF616B7A);

  /// `#1F2937` — Tailwind `gray-800`, **not** overridden by `theme.css`.
  /// `ServiceCard.tsx:65`'s resting service name.
  static const Color gray800 = Color(0xFF1F2937);

  /// `#D1D5DB` — Tailwind `gray-300`. The category card's trailing chevron
  /// (`ServicePage.tsx:455`, `text-gray-300`).
  static const Color gray300 = Color(0xFFD1D5DB);

  /// `#E5E7EB` — Tailwind `gray-200`. Input borders, hairline dividers, and
  /// the skeleton tile/bar fill (`ServicePage.tsx:245-246`).
  static const Color gray200 = Color(0xFFE5E7EB);

  /// `#F3F4F6` — Tailwind `gray-100`. Card hairline borders, the neutral
  /// empty-state icon tile, `ServiceCard`'s divider
  /// (`ServicePage.tsx:243,435,510`, `ServiceCard.tsx:57,78`).
  static const Color gray100 = Color(0xFFF3F4F6);

  /// `#F9FAFB` — Tailwind `gray-50`. Resting input fill.
  static const Color gray50 = Color(0xFFF9FAFB);

  /// `#9CA3AF` — Tailwind's **stock** `gray-400`, written as an *inline hex*
  /// at `ServicePage.tsx:465` for a category whose service count is zero.
  ///
  /// This is deliberately NOT [gray400]. `theme.css:92` overrides the
  /// `--color-gray-400` custom property to `#616B7A`, so every `text-gray-400`
  /// *class* resolves to the accessible value — but an inline
  /// `style={{ color: "#9CA3AF" }}` never reads that property and renders the
  /// stock grey. Porting this one label as [gray400] would be a Tier 2 value
  /// mismatch dressed up as an accessibility improvement; the source's own
  /// override mechanism did not reach it, and B2 ports the web rather than
  /// improving it (ADR-0001, § V.8 item 20).
  static const Color gray400Inline = Color(0xFF9CA3AF);

  // ── Semantic ───────────────────────────────────────────────────────────────
  //
  // Read off `api_notice.tsx` / the auth forms, which are the only surfaces
  // that render state colour today.

  /// `#DC2626` — Tailwind `red-600`. Error text and error field borders.
  static const Color danger = Color(0xFFDC2626);

  /// `#EF4444` — Tailwind `red-500`. Inline field-level error text.
  static const Color dangerStrong = Color(0xFFEF4444);

  /// `#FCA5A5` — Tailwind `red-300`. Error field outline.
  static const Color dangerBorder = Color(0xFFFCA5A5);

  /// `#FECACA` — Tailwind `red-200`. Error notice outline.
  static const Color dangerOutline = Color(0xFFFECACA);

  /// `#FEF2F2` — Tailwind `red-50`. Error notice / error field fill.
  static const Color dangerSoft = Color(0xFFFEF2F2);

  /// `#15803D` — Tailwind `green-700`. Success text.
  static const Color success = Color(0xFF15803D);

  /// `#BBF7D0` — Tailwind `green-200`. Success notice outline.
  static const Color successBorder = Color(0xFFBBF7D0);

  /// `#F0FDF4` — Tailwind `green-50`. Success notice fill.
  static const Color successSoft = Color(0xFFF0FDF4);

  /// `#B45309` — Tailwind `amber-700`. Warning text.
  static const Color warning = Color(0xFFB45309);

  /// `#F59E0B` — Tailwind `amber-500`. Mid-strength meter segment.
  static const Color warningStrong = Color(0xFFF59E0B);

  /// `#C7D2FE` — Tailwind `indigo-200`. Informational notice outline.
  static const Color infoBorder = Color(0xFFC7D2FE);

  // ── Help-centre swatch palette ─────────────────────────────────────────────

  /// `HelpCenterPage.tsx:56`'s `PALETTE`, cycled over the help categories.
  ///
  /// This lives in the theme, not in `features/help/`, because the source says
  /// so in as many words at `:55`: *"the categories are data, their colours are
  /// design."* The category list comes from `/help/categories`; the four
  /// swatches it is painted with do not.
  static const List<({Color color, Color background})> helpPalette =
      <({Color color, Color background})>[
    (color: Color(0xFF344EAD), background: Color(0xFFEEF2FF)),
    (color: Color(0xFFB45309), background: Color(0xFFFEF3C7)),
    (color: Color(0xFF15803D), background: Color(0xFFDCFCE7)),
    (color: Color(0xFF6366F1), background: Color(0xFFE0E7FF)),
  ];

  /// `HelpCenterPage.tsx:61` — `PALETTE[i % PALETTE.length]`.
  static ({Color color, Color background}) helpSwatch(int index) =>
      helpPalette[index % helpPalette.length];

  // ── Category tints and accents ─────────────────────────────────────────────
  //
  // `ServicePage.tsx:144-153`'s `CATEGORIES` table carries, per category, a
  // `bg` (a pale tile wash) and a `color`.
  //
  // These sit uneasily beside this file's own rule that a runtime-supplied
  // colour is data and must never be transcribed, so the distinction is worth
  // being precise about: `/service-categories` publishes `color` and **not**
  // `bg`. The eight `bg` values are therefore compile-time copy the API cannot
  // send, and belong here. The eight `color` values are *also* transcribed —
  // but only as the fallback for `c.color || seed?.color || "#344EAD"`
  // (`:325`), a branch that cannot fire while the API sends a colour for all
  // eight, which it does. They are ported because the source's fallback chain
  // is ported, not because anything reads them today; the rendered accent is
  // always the wire's.
  //
  // They live in the theme rather than in `features/service/presentation/`
  // because B2-AC-11 admits no colour literal outside this directory, and the
  // rule does not bend for a table of eight.

  /// `#EEF2FF` / `#344EAD` — Civil & Population.
  static const Color categoryTintCivil = Color(0xFFEEF2FF);
  static const Color categoryAccentCivil = Color(0xFF344EAD);

  /// `#E0F2FE` / `#0EA5E9` — Immigration.
  static const Color categoryTintImmigration = Color(0xFFE0F2FE);
  static const Color categoryAccentImmigration = Color(0xFF0EA5E9);

  /// `#DCFCE7` / `#16A34A` — Tax & Payment.
  static const Color categoryTintFinance = Color(0xFFDCFCE7);
  static const Color categoryAccentFinance = Color(0xFF16A34A);

  /// `#FFEDD5` / `#EA580C` — Land & Property.
  static const Color categoryTintHousing = Color(0xFFFFEDD5);
  static const Color categoryAccentHousing = Color(0xFFEA580C);

  /// `#FEF3C7` / `#F59E0B` — Transport.
  static const Color categoryTintTransport = Color(0xFFFEF3C7);
  static const Color categoryAccentTransport = Color(0xFFF59E0B);

  /// `#FCE7F3` / `#DB2777` — Social Protection.
  static const Color categoryTintWelfare = Color(0xFFFCE7F3);
  static const Color categoryAccentWelfare = Color(0xFFDB2777);

  /// `#DBEAFE` / `#2563EB` — Education.
  static const Color categoryTintEducation = Color(0xFFDBEAFE);
  static const Color categoryAccentEducation = Color(0xFF2563EB);

  /// `#FEE2E2` / `#DC2626` — Health.
  static const Color categoryTintHealth = Color(0xFFFEE2E2);
  static const Color categoryAccentHealth = Color(0xFFDC2626);

  /// `seed?.bg ?? "#F3F4F6"` (`ServicePage.tsx:326`) — the wash for a category
  /// this build has no seed row for. Same value as [gray100]; named separately
  /// because it is a *fallback decision*, not a border colour, and the two
  /// would be changed for different reasons.
  static const Color categoryTintFallback = Color(0xFFF3F4F6);

  /// `c.color || seed?.color || "#344EAD"` — the last link of the accent
  /// fallback chain. Same value as [primary]; named for the same reason.
  static const Color categoryAccentFallback = Color(0xFF344EAD);

  // ── glass.ts ───────────────────────────────────────────────────────────────

  /// `glass.ts`'s `shade()` — lighten toward white (`percent > 0`) or darken
  /// toward black (`percent < 0`), per channel.
  ///
  /// Ported here rather than into `features/help/` for the same reason as
  /// [helpPalette]: `glass.ts` is design. It is a *function* and not a token
  /// because its input is usually a colour the API supplied at runtime, which
  /// by the rule at the top of this file must never be transcribed as a
  /// constant.
  ///
  /// The arithmetic is the source's, including its `Math.round`:
  /// `round((t - c) * p + c)` where `t` is 255 lightening / 0 darkening and
  /// `p` is `|percent| / 100`. Reimplementing it as a `Color.lerp` toward
  /// white would be off by up to one 8-bit step per channel — invisible to a
  /// reviewer and a Tier 2 value mismatch.
  static Color shade(Color color, double percent) {
    final int target = percent < 0 ? 0 : 255;
    final double p = (percent.abs()) / 100;

    int channel(double v) {
      final int c = (v * 255).round();
      return ((target - c) * p + c).round().clamp(0, 255);
    }

    return Color.fromARGB(
      (color.a * 255).round(),
      channel(color.r),
      channel(color.g),
      channel(color.b),
    );
  }

  /// Parses a wire-supplied `#RRGGBB` (or `#AARRGGBB`, or the same without the
  /// `#`) into a [Color], falling back to [fallback] on anything unparseable.
  ///
  /// This is the "parse them at the edge; pass them down as values" half of
  /// this file's rule about runtime colour families. `ServiceCategory.color`
  /// and `Service.color` arrive as strings and must become a `Color`
  /// *somewhere*; doing it here keeps the conversion — and the only place a
  /// channel-arithmetic literal could hide — inside the one directory
  /// B2-AC-11 exempts.
  ///
  /// **Never throws.** CSS is forgiving about a malformed colour (the
  /// declaration is dropped and the inherited value shows), and a catalogue row
  /// with a typo'd hex must degrade to a plain tile, not take down a page of
  /// 43. [fallback] defaults to [primary], which is the last link of the
  /// source's own `c.color || seed?.color || "#344EAD"` chain.
  static Color parseHex(String value, {Color fallback = primary}) {
    String hex = value.trim();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return fallback;

    final int? parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return fallback;
    return Color(parsed);
  }

  /// `glass.ts`'s `hexToRgba()` has **no port**, deliberately.
  ///
  /// Its whole job is turning a `#RRGGBB` string plus an alpha into a CSS
  /// `rgba()` string — a stringly-typed workaround for CSS having no colour
  /// type. Flutter has one: `color.withValues(alpha: a)` is the same operation,
  /// already in the framework. A wrapper would be a second name for an existing
  /// function and one more thing to keep in step. Call sites use
  /// `withValues` directly; this doc comment is the record that the omission is
  /// a decision, not an oversight.
  static const String hexToRgbaNote =
      'glass.ts hexToRgba(c, a) == Flutter c.withValues(alpha: a)';
}

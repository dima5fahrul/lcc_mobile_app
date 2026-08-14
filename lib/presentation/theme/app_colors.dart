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

  /// `#1A2D6B` — the **0 %** stop of the news header's gradient,
  /// `linear-gradient(135deg, #1A2D6B 0%, #344EAD 100%)` (`NewsPage.tsx:66`).
  /// The 100 % stop is [primary]. Note the direction is the reverse of the
  /// catalogue header's: news runs dark → brand, service runs brand → dark.
  static const Color newsHeaderStart = Color(0xFF1A2D6B);

  /// `#1a2d7a` — the **100 %** stop of the help header's gradient,
  /// `linear-gradient(135deg, #344EAD 0%, #1a2d7a 100%)`
  /// (`HelpCenterPage.tsx:153`). The 0 % stop is [primary].
  ///
  /// Distinct from both [headerGradientEnd] (`#1E3070`, the catalogue header)
  /// and [newsHeaderStart] (`#1A2D6B`) — three different dark-navy stops on
  /// three different headers, and the source really does write three values.
  /// Collapsing them onto one token would be a substitution, not a
  /// simplification.
  static const Color helpHeaderEnd = Color(0xFF1A2D7A);

  /// `rgba(245,158,11,0.28)` — the amber radial bloom behind the help header
  /// (`HelpCenterPage.tsx:157`). The RGB is [warningStrong] (`#F59E0B`); only
  /// the alpha is new, so this is that token at 28 %.
  static const Color helpHeaderBloom = Color(0x47F59E0B);

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

  // ── B2b additions — Home ───────────────────────────────────────────────────
  //
  // ## Why this block exists in a file B2b's § 3.1 column does not list
  //
  // B2-AC-11 admits **no** colour literal outside this directory and its
  // grandfather list is closed. `HomePage`, `Hero` and `ServiceCard` draw
  // fifteen values B2a had no reason to transcribe — an amber action banner,
  // an emerald verified badge, a navy photo scrim, two gradient stops. There is
  // no compliant place for them other than here, so the alternative to this
  // block is not "a tidier diff", it is B2-AC-11 red. Recorded in the hand-back
  // as a required deviation from § 3.1's B2b file list.
  //
  // ## Why the Tailwind-class values below differ in convention from those above
  //
  // **`lcc-app` is on `tailwindcss@4.1.12`** (`package.json:77`), whose default
  // palette is defined in **OKLCH** (`node_modules/tailwindcss/theme.css`), not
  // in the v3 sRGB hexes. The two are close for neutrals and far apart for
  // saturated ramps — `red-600` is `oklch(57.7% 0.245 27.325)` = `#E7000B`,
  // where v3's hex was `#DC2626`.
  //
  // The tokens above this block transcribe **v3** values for classes
  // (`gray900` `#111827` where v4 renders `#101828`, `gray800` `#1F2937` where
  // v4 renders `#1E2939`). Those are B2a's and this batch does not touch them —
  // they are rendered by the frozen auth pages and by `ServicePage`, so
  // changing them is a fidelity edit outside B2b's scope. **It is nonetheless a
  // real disparity and it is reported**, because Tier 2 cannot catch it by
  // construction: `derive_tier2.py` greps each hex out of the web file it is
  // attributed to, and a Tailwind *class* never appears as a hex in the source,
  // so no class-derived token is in the oracle at all.
  //
  // Everything below therefore carries the **v4 value the browser actually
  // paints**, converted from the OKLCH triple, with that triple quoted so the
  // conversion is checkable. Values that are *inline hex* in the source are
  // marked as such and are exact by definition.

  /// `#FFE2E2` — Tailwind v4 `red-100`, `oklch(93.6% 0.032 17.717)`.
  /// The outline of every error notice on Home (`HomePage.tsx:326,466,630`,
  /// `border-red-100`).
  static const Color dangerOutlineSoft = Color(0xFFFFE2E2);

  /// `#FB2C36` — Tailwind v4 `red-500`, `oklch(63.7% 0.237 25.331)`.
  /// The `AlertCircle` glyph in those notices (`text-red-500`).
  static const Color dangerGlyph = Color(0xFFFB2C36);

  /// `#E7000B` — Tailwind v4 `red-600`, `oklch(57.7% 0.245 27.325)`.
  /// Their message text (`text-red-600`).
  static const Color dangerText = Color(0xFFE7000B);

  /// `#FFFBEB` — Tailwind v4 `amber-50`, `oklch(98.7% 0.022 95.277)`.
  /// The action banner's fill (`HomePage.tsx:394`, `bg-amber-50`).
  static const Color warningSurface = Color(0xFFFFFBEB);

  /// `#FEE685` — Tailwind v4 `amber-200`, `oklch(92.4% 0.12 95.746)`.
  /// The action banner's outline (`border-amber-200`).
  static const Color warningOutline = Color(0xFFFEE685);

  /// `#FEF3C6` — Tailwind v4 `amber-100`, `oklch(96.2% 0.059 95.617)`.
  /// The tile behind the banner's `AlertTriangle` (`HomePage.tsx:395`).
  ///
  /// Deliberately **not** [categoryTintTransport], which is the same family and
  /// a different number (`#FEF3C7`, an inline hex in `ServicePage.tsx`'s seed
  /// table). Two values one step apart, from two sources, for two unrelated
  /// things — collapsing them would tie a banner's styling to a category's.
  static const Color warningTint = Color(0xFFFEF3C6);

  /// `#973C00` — Tailwind v4 `amber-800`, `oklch(47.3% 0.137 46.201)`.
  /// The banner's title (`HomePage.tsx:399`, `text-amber-800`).
  static const Color warningTitle = Color(0xFF973C00);

  /// `#BB4D00` — Tailwind v4 `amber-700`, `oklch(55.5% 0.163 48.998)`.
  /// The banner's reference-number line (`HomePage.tsx:404`).
  ///
  /// Not [warning] (`#B45309`), which is the *inline* hex of
  /// `HelpCenterPage.tsx`'s `PALETTE[1]` and only coincidentally the v3 name
  /// for this class.
  static const Color warningReference = Color(0xFFBB4D00);

  /// `#FFB900` — Tailwind v4 `amber-400`, `oklch(82.8% 0.189 84.429)`.
  /// The banner's dismiss `X` at rest (`HomePage.tsx:418`).
  static const Color warningDismiss = Color(0xFFFFB900);

  /// `#D97706` — **inline hex**, `HomePage.tsx:412`
  /// (`style={{ color: "#D97706" }}` on "Update document"). Written inline, so
  /// it never reads the `--color-amber-600` custom property and is exactly this
  /// value — the same mechanism that makes [gray400Inline] differ from
  /// [gray400].
  static const Color warningLink = Color(0xFFD97706);

  /// `#ECFDF5` — Tailwind v4 `emerald-50`, `oklch(97.9% 0.021 166.113)`.
  /// The ID card's "Verified" badge fill (`Hero.tsx:218`).
  static const Color verifiedSurface = Color(0xFFECFDF5);

  /// `#A4F4CF` — Tailwind v4 `emerald-200`, `oklch(90.5% 0.093 164.15)`.
  /// That badge's outline.
  static const Color verifiedOutline = Color(0xFFA4F4CF);

  /// `#007A55` — Tailwind v4 `emerald-700`, `oklch(50.8% 0.118 165.612)`.
  /// That badge's text and check glyph.
  static const Color verifiedText = Color(0xFF007A55);

  /// `#4A5565` — Tailwind v4 `gray-600`, `oklch(44.6% 0.03 256.802)`.
  /// The dismiss dialog's "Keep it" label (`HomePage.tsx:815`).
  static const Color gray600 = Color(0xFF4A5565);

  /// `#F8FAFF` — **inline hex**, `HomePage.tsx:503`. The resting fill of the
  /// "More" tile, which is a dashed-border tile rather than a card and so has
  /// its own near-white rather than [white].
  static const Color moreTileSurface = Color(0xFFF8FAFF);

  /// `#17235C` — **inline hex**, `HomePage.tsx:561` and `:663`. The 100 % stop
  /// of both photo-card gradients: the category slide
  /// (`linear-gradient(155deg, ${cat.color} 0%, #17235c 100%)`) and the news
  /// thumbnail (`135deg`). The 0 % stop is runtime data in both cases, which is
  /// why only this end of the ramp is a token.
  static const Color photoGradientEnd = Color(0xFF17235C);

  /// `rgb(18,31,80)` — the navy the hero backdrop and the category slides are
  /// washed with. Written in the source as three `rgba(18,31,80,α)` stops per
  /// gradient (`Hero.tsx:79`, `HomePage.tsx:574`) with α the only thing that
  /// varies, so the colour is the token and the alpha stays at the call site
  /// via `withValues` — see [hexToRgbaNote].
  static const Color scrimNavy = Color(0xFF121F50);

  /// Opaque black, the base of every modal overlay on Home.
  ///
  /// The source writes `bg-black/40` (`HomePage.tsx:797`) and `bg-black/50`
  /// (`:837`, `:923`, `Hero.tsx:319`) — one colour, three alphas — so the
  /// colour is the token and the alpha stays at the call site via
  /// `withValues`, exactly as [scrimNavy] does. It exists because
  /// `Colors.black54` is a `Colors.<name>` literal and B2-AC-11 does not carve
  /// out Material's palette for being convenient; it is also the wrong number
  /// (0.54, not 0.40 or 0.50).
  static const Color black = Color(0xFF000000);

  /// `#6366F1` — **inline hex**, `Hero.tsx:242`. The 0 % stop of the initial
  /// tile's gradient, shown when a card has no photo
  /// (`linear-gradient(135deg, #6366F1 0%, #344EAD 100%)`); the 100 % stop is
  /// [primary]. Numerically equal to `helpPalette[3].color` and kept separate
  /// for the reason [categoryTintFallback] is: the two would be changed for
  /// different reasons.
  static const Color idInitialGradientStart = Color(0xFF6366F1);

  // ── B9a additions — the notification bell ──────────────────────────────────
  //
  // ## Why this block exists in a file B9a's § 3.1 column does not list
  //
  // The same required deviation the B2b block above records, for the same
  // reason and with the same disposition. B9's § 3.1 table names
  // `lib/features/notifications/**` and the two shell files; it does not name
  // this one. But SSD § 10.1 — a binding architecture document, not a batch
  // spec — makes this directory **the only place in `lib/**` allowed to hold a
  // raw colour literal**, with one closed grandfather list
  // (`features/auth/presentation/**`). Measured: `grep -rn 'Color(0x' lib`
  // outside `presentation/theme/` returns 84 lines and **every one of them is
  // in that grandfather list**. There is no compliant home for the five values
  // below other than here, so the alternative to this block is not a tidier
  // diff — it is `lib/features/notifications/presentation/` becoming the first
  // non-grandfathered colour literal in the tree.
  //
  // B9-AC-48's automatic-FAIL list enumerates `sources/lcc-app/**`,
  // `flutter-boilerplate/**`, `lib/core/network/**`, `lib/i18n/i18n.dart`,
  // `assets/{images,fonts,icons}/**`, `android/**`, the baseline PNGs and
  // F0a's parked paths. This file is in none of them, so this is a recorded
  // scope deviation to be reviewed, not an automatic failure — and it is
  // reported as one in the hand-back rather than left for a diff to find.
  //
  // Four of the five are `NOTIF_STYLE`'s announcement pair and the error
  // glyph. The other three `NOTIF_STYLE` pairs are NOT re-declared: their
  // values already exist above as exact tokens and `notif_style.dart` cites
  // them, because a fifth name for `#344EAD` is what `categoryAccentFallback`'s
  // own doc apologises for.

  /// `#6366F1` — `Layout.tsx:67`, the `announcement` row's glyph tint and the
  /// **fallback for every unrecognised category** (`NOTIF_FALLBACK`, `:70`).
  ///
  /// **Inline hex in the source**, so Tier 2 can see it and it is exact.
  ///
  /// Numerically equal to [idInitialGradientStart] and to `helpPalette[3]`'s
  /// accent, and kept separate for the reason [categoryTintFallback] is: three
  /// unrelated surfaces that would be changed for three different reasons.
  static const Color notifAccentAnnouncement = Color(0xFF6366F1);

  /// `#E0E7FF` — `Layout.tsx:67`, the tile behind that glyph. Inline hex.
  /// Numerically equal to `helpPalette[3]`'s background; see
  /// [notifAccentAnnouncement].
  static const Color notifTintAnnouncement = Color(0xFFE0E7FF);

  /// Fully transparent — the **absence** of a colour, not a colour.
  ///
  /// `MenuAnchor` draws a Material surface of its own around whatever it hosts:
  /// a background, an elevation shadow and an M3 surface tint. The bell's panel
  /// draws all three itself (`Layout.tsx:184`'s `bg-white rounded-2xl
  /// shadow-2xl border`), so the anchor's have to be suppressed or the port
  /// renders a card inside a card. Suppressing them means handing `MenuStyle`
  /// three transparent `WidgetStatePropertyAll`s.
  ///
  /// It lives here rather than as `Colors.transparent` at the call site for the
  /// reason [black]'s doc gives: `color_literal_test.dart` enforces B2-AC-11
  /// over `Colors.<name>` as well as over `Color(0x…)`, and *"B2-AC-11 does not
  /// carve out Material's palette for being convenient"*. Measured — the guard
  /// caught exactly this, three times, before the value moved here.
  static const Color transparent = Color(0x00000000);

  /// `#FF6467` — Tailwind v4 `red-400`, `oklch(70.4% 0.191 22.216)`
  /// (`lcc-app/node_modules/tailwindcss/theme.css:14`, the version this app
  /// actually ships). The `AlertCircle` in the bell menu's error branch
  /// (`Layout.tsx:231`, `text-red-400`).
  ///
  /// **Class-derived, so Tier 2 cannot see it** — `derive_tier2.py` greps hex
  /// out of the web source and a Tailwind class never appears as one
  /// (`roadmap.md:480-491`). Named here with its provenance and recorded as
  /// not covered by Tier 2 (B9-AC-29) rather than quietly counted as covered.
  ///
  /// Deliberately **not** [dangerGlyph] (`#FB2C36`, v4 `red-500`), which is
  /// `HomePage`'s notice glyph. One step apart on the same ramp, two different
  /// classes in two different files; substituting one for the other would be a
  /// divergence no tier could catch. The OKLCH → sRGB conversion was validated
  /// by re-deriving `red-500` and getting [dangerGlyph] exactly.
  static const Color dangerGlyphSoft = Color(0xFFFF6467);

  // ── B9b additions — the customer-service chat ──────────────────────────────
  //
  // ## The same required deviation B9a's block above records
  //
  // B9's § 3.1 table names `lib/features/chat/**` and the two shell files; it
  // does not name this one. SSD § 10.1 — a binding architecture document, not a
  // batch spec — makes this directory **the only place in `lib/**` allowed to
  // hold a raw colour literal**, and `color_literal_test.dart` enforces it with
  // a closed grandfather list of ten `features/auth/presentation/**` files that
  // `lib/features/chat/` is not on and cannot join. So the alternative to this
  // block is not a tidier diff: it is a **failing green test**, because the
  // three values below have no compliant home anywhere else.
  //
  // B9-AC-48's automatic-FAIL list enumerates `sources/lcc-app/**`,
  // `flutter-boilerplate/**`, `lib/core/network/**`, `lib/i18n/i18n.dart`,
  // `assets/{images,fonts,icons}/**`, `android/**`, the baseline PNGs and F0a's
  // parked paths. This file is in none of them, so this is a recorded scope
  // deviation to be reviewed, not an automatic failure — and it is reported as
  // one in the hand-back rather than left for a diff to find.
  //
  // **Three, and only three.** Everything else the chat draws is an existing
  // token, and each was checked by value rather than by name: `#344EAD` is
  // [primary] (`:207`, `:344`, `:390`, `:550`), `#EEF2FF` is [primarySoft]
  // (`:286`), `#1F2937` is [gray800] (`:353`, `:397`), `#E5E7EB` is [gray200]
  // (`:374`, `:415`), and the launcher's `bg-red-500` unread circle (`:555`) is
  // **[dangerGlyph]** — B9a's own doc records that `#FB2C36` is v4 `red-500`,
  // and re-deriving it from `oklch(63.7% 0.237 25.331)` reproduces it exactly.
  // A fourth `red-500` token would be the mistake [categoryAccentFallback]
  // apologises for.

  /// `#F5F7FF` — the chat panel's body wash. **Inline hex** in the source, at
  /// `CustomerServiceChat.tsx:283` (`bg-[#F5F7FF]`, the signed-out prompt) and
  /// `:316` (the transcript scroller), so Tier 2 can see it and it is exact.
  ///
  /// Deliberately **not** [surface] (`#F0F2F8`, the app page wash) or
  /// [moreTileSurface] (`#F8FAFF`). Three near-identical off-whites on three
  /// different surfaces, and the source really does write three values;
  /// collapsing them would be a substitution, not a simplification.
  static const Color chatSurface = Color(0xFFF5F7FF);

  /// `#05DF72` — Tailwind v4 `green-400`, `oklch(79.2% 0.209 151.711)`
  /// (`lcc-app/node_modules/tailwindcss/theme.css:74`, `tailwindcss@4.1.12`,
  /// the version this app actually ships). The agent's presence dot on the chat
  /// header avatar (`:214`, `bg-green-400`).
  ///
  /// **Class-derived, so Tier 2 cannot see it** — `derive_tier2.py` greps hex
  /// out of the web source and a Tailwind class never appears as one
  /// (`roadmap.md:480-491`). Named here with its provenance and recorded as not
  /// covered by Tier 2 (B9-AC-29) rather than quietly counted as covered.
  ///
  /// Deliberately not [success] (`#15803D`, `green-700`) or
  /// [categoryAccentFinance] (`#16A34A`, `green-600`): three steps apart on one
  /// ramp, three different surfaces. The OKLCH → sRGB conversion used here was
  /// validated by re-deriving `red-500` → [dangerGlyph] and `red-400` →
  /// [dangerGlyphSoft] and getting both exactly.
  static const Color presenceOnline = Color(0xFF05DF72);

  /// `rgba(0, 0, 0, 0.07)` — the inbound chat bubble's drop shadow,
  /// `boxShadow: "0 1px 4px rgba(0,0,0,0.07)"` (`:355`, `:398`).
  ///
  /// `0.07 × 255 = 17.85 → 0x12`. Deliberately not [cardShadow] (`0x0D`, i.e.
  /// 0.05) or [cardShadowMedium] (`0x1A`, 0.10), both of which are already in
  /// this file and neither of which is this value. Substituting the nearest one
  /// would be a Tier-2-invisible divergence chosen for tidiness.
  ///
  /// An `rgba()` literal is **not** hex, so `derive_tier2.py` cannot see this
  /// one either; recorded with the two class-derived colours above.
  static const Color chatBubbleShadow = Color(0x12000000);

  // ── B8a additions — the account & profile surface ──────────────────────────
  //
  // ## The same required deviation B9a and B9b's blocks above record
  //
  // specs.md § 3.1's B8a table names `lib/features/account/**`, four shared
  // files and two shell/session files; it does not name this one. `ssd.md`
  // § 10.1 — a binding architecture document, not a batch spec — makes this
  // directory **the only place in `lib/**` allowed to hold a raw colour
  // literal**, and `color_literal_test.dart` enforces it with a closed
  // grandfather list of ten `features/auth/presentation/**` files that
  // `lib/features/account/` is not on and cannot join. So the alternative to
  // this block is not a tidier diff: it is a **failing green test**, because
  // the two values below have no compliant home anywhere else. B8-AC-38's own
  // wording — *"no new hardcoded hex in `features/account/**`"* — assumes a
  // token exists to use; for these two, none did.
  //
  // Recorded as a scope deviation to be reviewed, and reported as one in the
  // hand-back rather than left for a diff to find.
  //
  // **Two, and only two.** Everything else `AccountPage` draws resolves to a
  // token already in this file, and each was checked **by value**, not by name:
  // `#344EAD` → [primary] (`:312`, `:438`, `:475`, `:627`), `#EEF2FF` →
  // [primarySoft] (`:436`, `:626`), `#1A2D6B` → [newsHeaderStart] (`:312`, the
  // header gradient's dark stop), `#E5E7EB` → [gray200] (`:119`, `:627`),
  // `#6B7280` → [muted] (`:628`), `bg-green-400` → [presenceOnline] (`:348`,
  // the same Tailwind class B9b's chat avatar uses), `border-red-100` →
  // [dangerOutlineSoft] (`:381`, `:722`), `text-red-500` → [dangerGlyph]
  // (`:382`, `:517`, `:531`, `:545`, `:600`, `:701`, `:726`), `text-red-600` →
  // [dangerText] (`:384`), and the four-part doc badge palette →
  // [successSoft] / [successBorder] / [success] / [dangerSoft] /
  // [dangerOutline] / [danger] / [gray50] / [gray200] / [gray500] (`:299-302`).
  //
  // ## A measured discrepancy in the reused tokens, recorded not forked
  //
  // Four of those reuses are **one step off the Tailwind v4 value the browser
  // actually paints**, because the token was derived from a v3 name or from an
  // inline hex in a different file: [gray300] is `#D1D5DB` where v4
  // `gray-300` is `#D1D5DC`; [gray800] is `#1F2937` (an inline hex in
  // `ServiceCard.tsx:65`) where the v4 *class* is `#1E2939`; [successBorder]
  // is `#BBF7D0` where v4 `green-200` is `#B9F8CF`; [success] is `#15803D`
  // where v4 `green-700` is `#008236`.
  //
  // B8 **reuses them anyway** and does not add four near-duplicates. Each of
  // those four tokens is already this project's designated token for that
  // Tailwind class — [gray300]'s own doc cites a `text-gray-300` class at
  // `ServicePage.tsx:455` — so forking here would give the app two colours for
  // one class and make the account page disagree with every other ported
  // surface. The discrepancy is a token-layer defect predating B8 and is
  // reported to the theme's owner rather than half-fixed inside one feature.
  //
  // Conversions below use the same OKLCH → sRGB path B9a validated by
  // re-deriving `red-500` → [dangerGlyph], `red-400` → [dangerGlyphSoft] and
  // `green-400` → [presenceOnline]; all three reproduce exactly.

  /// `#7BF1A8` — Tailwind v4 `green-300`, `oklch(87.1% 0.15 154.449)`
  /// (`lcc-app/node_modules/tailwindcss/theme.css:73`, `tailwindcss@4.1.12`).
  /// The **"Verified Citizen" chip's label** on the account header
  /// (`AccountPage.tsx:371`, `text-green-300`), sitting on the `bg-white/10`
  /// pill.
  ///
  /// **Class-derived, so Tier 2 cannot see it** — `derive_tier2.py` greps hex
  /// out of the web source and a Tailwind class never appears as one. Named
  /// here with its provenance and recorded as not covered (B8-AC-38) rather
  /// than quietly counted as covered.
  ///
  /// Deliberately not [presenceOnline] (`#05DF72`, `green-400`), which is the
  /// **check glyph beside this very label** (`:370`, `text-green-400`) — one
  /// step apart on one ramp, two nodes in the same three-element row, and the
  /// source really does write two values.
  static const Color green300 = Color(0xFF7BF1A8);

  /// `#00A63E` — Tailwind v4 `green-600`, `oklch(62.7% 0.194 149.214)`
  /// (`theme.css:76`). The two green confirmation notes: the profile editor's
  /// `profileNote` (`AccountPage.tsx:547`, `text-green-600`) and the password
  /// form's `pwNote` (`:702`).
  ///
  /// Class-derived, so likewise invisible to Tier 2. Deliberately not
  /// [categoryAccentFinance] (`#16A34A`), which happens to be v3's `green-600`
  /// and is an **inline hex** in `ServicePage.tsx:147`'s category seed table —
  /// a different source for a different thing, and the mistake
  /// [categoryAccentFallback] apologises for.
  static const Color green600 = Color(0xFF00A63E);

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

  // ── B10 — boot, onboarding, tutorial and the shared button ─────────────────
  //
  // § 6.14. Tier 2 compares *values*, and `color_literal_test.dart`'s own doc
  // says why every one of these has to be here rather than inline: *"a value
  // that is written inline in a widget body is not in the theme, so Tier 2
  // cannot see it."*
  //
  // **The WCAG reasoning is carried across with the values, deliberately.**
  // `SplashScreens.tsx:57-62` and `Button.tsx:24-25` each explain that a dark
  // shade was chosen *because* the vibrant one fails 1.4.3 as text. A token
  // named without that reasoning is one refactor away from being "simplified"
  // back to the bright value by someone who reads it as an arbitrary choice.

  // ── LoadingScreen.tsx ──
  /// `linear-gradient(160deg, #4460C9 0%, …)` — `LoadingScreen.tsx:52`, stop 1.
  static const Color bootGradientStart = Color(0xFF4460C9);

  /// `… #344EAD 45% …` — same value as [primary]; named separately because it
  /// is a gradient stop and would be changed for a different reason.
  static const Color bootGradientMid = Color(0xFF344EAD);

  /// `… #1B2C68 100%` — `LoadingScreen.tsx:52`, stop 3. Also the third stop of
  /// all three splash washes (`SplashScreens.tsx:170`, `:181`, `:192`).
  static const Color bootGradientEnd = Color(0xFF1B2C68);

  /// `rgba(255,255,255,0.10)` — the top-right decorative glow
  /// (`LoadingScreen.tsx:61`).
  static const Color bootGlowWhite = Color(0x1AFFFFFF);

  /// `rgba(245,197,66,0.12)` — the bottom-left glow (`:66`).
  static const Color bootGlowAmber = Color(0x1FF5C542);

  /// `#F5C542` — the progress bar fill (`:108`) and the issuing-authority star
  /// (`:123`). Not [warningStrong] (`#F59E0B`): a different amber.
  static const Color bootAccent = Color(0xFFF5C542);

  /// `rgba(255,255,255,0.22)` — the progress track (`:102`).
  static const Color bootProgressTrack = Color(0x38FFFFFF);

  /// `border: 1px solid rgba(255,255,255,0.45)` — the pulsing halo (`:78`).
  static const Color bootRing = Color(0x73FFFFFF);

  /// `boxShadow: 0 20px 45px rgba(0,0,0,0.28)` — the logo tile's drop shadow
  /// (`LoadingScreen.tsx:82`). Deeper than [cardShadowMedium] (0.10) because
  /// the tile floats over a photograph-free gradient with nothing else to
  /// separate it.
  static const Color bootLogoShadow = Color(0x47000000);

  // ── SplashScreens.tsx — badge inks ──
  /// `#344EAD`, **7.36:1 on white** (`SplashScreens.tsx:168`). Slide 1's badge.
  /// Same value as [primary]; a badge ink, not the brand fill.
  static const Color splashBadgeInk1 = Color(0xFF344EAD);

  /// `#075985`, **7.2:1 on white** (`:179`). Slide 2. The vibrant sky it
  /// darkens (`#0EA5E9`) is only **2.32:1** and fails WCAG 1.4.3 as text —
  /// that is the whole reason this is a separate, darker token.
  static const Color splashBadgeInk2 = Color(0xFF075985);

  /// `#166534`, **7.14:1 on white** (`:190`). Slide 3, same rationale.
  static const Color splashBadgeInk3 = Color(0xFF166534);

  // ── SplashScreens.tsx — the three colour washes over the shared photo ──
  // `linear-gradient(160deg, …)`, three stops each, all translucent so the
  // backdrop still reads through them.

  /// `rgba(68,96,201,0.86)` — slide 1, stop 1 (`:170`).
  static const Color splashWash1Start = Color(0xDB4460C9);

  /// `rgba(52,78,173,0.90)` — slide 1, stop 2.
  static const Color splashWash1Mid = Color(0xE6344EAD);

  /// `rgba(27,44,104,0.95)` — the shared stop 3 of all three washes.
  static const Color splashWashEnd = Color(0xF21B2C68);

  /// `rgba(47,127,212,0.86)` — slide 2, stop 1 (`:181`).
  static const Color splashWash2Start = Color(0xDB2F7FD4);

  /// `rgba(42,91,184,0.90)` — slide 2 and slide 3, stop 2 (`:181`, `:192`).
  static const Color splashWash2Mid = Color(0xE62A5BB8);

  /// `rgba(46,143,122,0.86)` — slide 3, stop 1 (`:192`).
  static const Color splashWash3Start = Color(0xDB2E8F7A);

  // ── SplashScreens.tsx — slide 2's tracking card ──
  /// `#C7D0EA` — the connector between two completed tracking steps (`:125`).
  /// Also `Button.tsx:46`'s secondary border.
  static const Color trackingConnector = Color(0xFFC7D0EA);

  /// `#16A34A` — the final "approved" step's dot (`:120`). Not [success]
  /// (`#15803D`): the source uses the brighter green *as a fill behind a white
  /// check*, where contrast is a glyph problem and not a text one.
  static const Color trackingDone = Color(0xFF16A34A);

  /// `rgba(255,255,255,0.18)` — the card peeking out behind slide 3's ID card
  /// (`:152`), suggesting a stack of stored documents.
  static const Color splashCardStack = Color(0x2EFFFFFF);

  // ── TutorialOverlay.tsx — badge pairs (background / ink) ──
  /// `#EEF2FF` / `#344EAD` — steps 1 and 4. Same values as [primarySoft] /
  /// [primary]; named as a *pair* so the six badges read as one table.
  static const Color tutorialBadgeBgIndigo = Color(0xFFEEF2FF);
  static const Color tutorialBadgeInkIndigo = Color(0xFF344EAD);

  /// `#FEF3C7` / `#D97706` — step 2 (search).
  static const Color tutorialBadgeBgAmber = Color(0xFFFEF3C7);
  static const Color tutorialBadgeInkAmber = Color(0xFFD97706);

  /// `#DCFCE7` / `#16A34A` — step 3 (browse & filter).
  static const Color tutorialBadgeBgGreen = Color(0xFFDCFCE7);
  static const Color tutorialBadgeInkGreen = Color(0xFF16A34A);

  /// `#F3E8FF` / `#9333EA` — step 5 (history).
  static const Color tutorialBadgeBgPurple = Color(0xFFF3E8FF);
  static const Color tutorialBadgeInkPurple = Color(0xFF9333EA);

  /// `#FEE2E2` / `#DC2626` — step 6 (news & chat).
  static const Color tutorialBadgeBgRed = Color(0xFFFEE2E2);
  static const Color tutorialBadgeInkRed = Color(0xFFDC2626);

  /// `#F8FAFF` — the wash behind every step's visual (`TutorialOverlay.tsx:393`).
  /// Same value as [moreTileSurface], named separately for the same reason the
  /// category fallbacks are.
  static const Color tutorialVisualSurface = Color(0xFFF8FAFF);

  /// `rgba(0,0,0,0.6)` — the tutorial scrim (`:364`).
  static const Color tutorialScrim = Color(0x99000000);

  /// `#F59E0B` — step 2's search button and step 6's unread badge. Same value
  /// as [warningStrong].
  static const Color tutorialAmberFill = Color(0xFFF59E0B);

  /// `border-amber-300` — Tailwind `#FCD34D`, the highlighted search field in
  /// step 2's visual (`:85`).
  static const Color tutorialSearchOutline = Color(0xFFFCD34D);

  /// `text-amber-500` — Tailwind `#F59E0B`, the search glyph in the same
  /// visual. Named separately because it is a glyph tint, not a fill.
  static const Color tutorialSearchGlyph = Color(0xFFF59E0B);

  // ── Button.tsx — the five variant triples (`:44-50`) ──
  /// `primary: { bg #344EAD, fg #FFFFFF, border #344EAD }`. Reuses [primary]
  /// and [white]; no new token needed.
  ///
  /// `secondary: { bg #FFFFFF, fg #344EAD, border #C7D0EA }` —
  /// [trackingConnector] is that border.
  ///
  /// `amber: { bg #F59E0B, fg #1F2937, border #F59E0B }`. **The dark
  /// foreground is not a style preference**: `Button.tsx:24-25` records that
  /// white on `#F59E0B` measures **2.15:1**, and `#1F2937` measures 6.83:1.
  /// [gray800] is that ink; [warningStrong] is that fill.
  ///
  /// `danger: { bg #DC2626, … }` — [danger].
  ///
  /// `ghost: { bg transparent, fg #4B5563, border transparent }` — the one
  /// value with no existing token.
  static const Color buttonGhostInk = Color(0xFF4B5563);

  /// `text-red-600` — Tailwind `#DC2626`, the inline error message under a
  /// button in its error state (`Button.tsx:115`). Same value as [danger].
  static const Color buttonErrorText = Color(0xFFDC2626);

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

  // ── Wallet quick actions + the QR bitmap (B6a) ─────────────────────────────
  //
  // **Five tokens, appended under an explicit § 8.3 escalation that was raised
  // and granted rather than assumed.** specs.md § 4.1 puts
  // `lib/presentation/theme/**` out of B6's scope and § 8.3 makes a
  // needed-but-missing Tier 2 token an escalation; `B6-AC-40` requires the
  // escalation to be recorded *even when granted*. It was granted on the
  // precedent B10 already carries — its § 3.1 holds the identical row for the
  // identical reason (*"the `color_literal_test.dart` guard forbids literals
  // outside `presentation/theme/`"*). The record is
  // `docs/greenfield/GOR-245-b6-wallet-payment/blocked.md`.
  //
  // Measured first, not assumed: `grep -in "0xFF<hex>"` over this directory
  // returns nothing for any of the five, while the other twelve
  // `QUICK_ACTIONS` values and every other colour B6a renders already resolve
  // to a member above.
  //
  // Append-only: nothing above this comment changed.
  //
  // `WalletPage.tsx:51-60`'s `QUICK_ACTIONS` is a table of eight
  // `{color, bg}` pairs. Six of the eight resolve to existing members —
  // topup `#16A34A`/`#DCFCE7`, transfer `#344EAD`/`#EEF2FF`, mobile
  // `#0EA5E9`/`#E0F2FE`, electricity `#F59E0B`/`#FEF3C7`, internet
  // `#DB2777`/`#FCE7F3`, fines `#DC2626`/`#FEE2E2`. Two do not, and they are
  // the four below. They are compile-time copy the API cannot send — the same
  // standing the eight `categoryTint*` washes have — so this is where they
  // belong.

  /// `#7C3AED` — the **Scan & Pay** quick-action glyph
  /// (`WalletPage.tsx:54`, `QUICK_ACTIONS[2].color`).
  static const Color quickActionAccentScan = Color(0xFF7C3AED);

  /// `#EDE9FE` — the **Scan & Pay** tile wash (`WalletPage.tsx:54`,
  /// `QUICK_ACTIONS[2].bg`).
  static const Color quickActionTintScan = Color(0xFFEDE9FE);

  /// `#0891B2` — the **Water** quick-action glyph colour
  /// (`WalletPage.tsx:57`, `QUICK_ACTIONS[5].color`).
  ///
  /// Rendered only as a fallback in practice: the Water tile carries a raster
  /// logo (`nampapa-logo.png`), and `:249-255` draws the logo *instead of* the
  /// glyph whenever `a.logo` is set. Ported because the source's table sets
  /// it, on the same footing as the eight `categoryAccent*` values that exist
  /// for a fallback branch the live API never reaches.
  static const Color quickActionAccentWater = Color(0xFF0891B2);

  /// `#CFFAFE` — the **Water** tile wash (`WalletPage.tsx:57`,
  /// `QUICK_ACTIONS[5].bg`).
  ///
  /// Likewise fallback-only: `:249` uses `a.logo ? "white" : a.bg`, so a tile
  /// with a logo renders on [white] with a [gray100] hairline border.
  static const Color quickActionTintWater = Color(0xFFCFFAFE);

  /// `#1a1a1a` — the ink of one filled cell in the decorative QR bitmap
  /// (`PaymentSection.tsx:158`, `fill="#1a1a1a"` over a white 20×20 `rect`).
  ///
  /// **The source writes this hex in lower case**, which is why a
  /// case-sensitive `grep "1A1A1A"` over `PaymentSection.tsx` returns 0 and a
  /// case-insensitive one returns line 158. Recorded because
  /// `derive_tier2.py` verifies a token's provenance by grepping its hex out
  /// of the attributed web file, and a case-sensitive check cannot see this
  /// one.
  ///
  /// Deliberately not [black] (`#000000`): the source is one step off pure
  /// black and a Tier 2 comparison is an equality, not a tolerance.
  ///
  /// What this paints is `B6-DIV-3` — a **constant** bitmap that does not
  /// encode `instruction.qr_payload`. See `presentation/payment/
  /// qr_placeholder.dart` and specs.md § 6.10 / FU-6.
  static const Color qrCellInk = Color(0xFF1A1A1A);

  // ── The approved status ring (B7a) ─────────────────────────────────────────
  //
  // **One token, appended under the § 3.1 operation-A scope row B7 was granted
  // for this file.** The precedent is B10's § 3.1 line 284, which carries the
  // identical row for the identical reason, and B6a's five tokens directly
  // above, granted on that same precedent.
  //
  // ## Why exactly one, when `history_palette.dart` held fifteen literals
  //
  // Measured before assuming, the way B9b and B8a's blocks describe — **by
  // value, not by name**: of the fifteen distinct `0xFF……` values in
  // `features/history/presentation/widgets/history_palette.dart`, fourteen
  // already resolve to a member of this class and are now references to it.
  // They were duplication, not a missing token, and the file's doc comment
  // claiming they *"have no `AppColors` entry"* was false for all fourteen.
  //
  // The mapping, so the next reader does not have to re-measure it: `#15803D`
  // → [success], `#DC2626` → [danger], `#FCA5A5` → [dangerBorder], `#B45309`
  // → [warning], `#344EAD` → [primary], `#EEF2FF` → [primarySoft], `#F3F4F6` →
  // [gray100], `#6B7280` → [muted], `#DCFCE7` → [categoryTintFinance],
  // `#FEE2E2` → [categoryTintHealth], `#FEF3C7` → [categoryTintTransport],
  // `#16A34A` → [categoryAccentFinance], `#D97706` → [warningLink], `#FCD34D`
  // → [tutorialSearchOutline].
  //
  // The last six of those are surface-specific names being read from another
  // feature, which is a real coupling and is **not** a new liberty: B6a's
  // `wallet_quick_actions.dart:100-152` and B9a's `notif_style.dart:107-116`
  // already reuse those same three `categoryTint*` washes for these same three
  // values. Adding history-local synonyms instead would be the fifth name for
  // one colour that [categoryAccentFallback]'s own doc apologises for.
  //
  // Append-only: nothing above this comment changed.

  /// `#86EFAC` — Tailwind v3 `green-300`, the **`ring` of the `approved` status
  /// badge** (`HistoryPage.tsx:43`, `STATUS_CONFIG.approved.ring`).
  ///
  /// **Inline hex in the source**, so Tier 2 can see it and it is exact;
  /// `test/features/history/fidelity/tier2_history_test.dart` reads it back out
  /// of the pinned TSX.
  ///
  /// Three near neighbours it is deliberately none of, each a different value:
  /// [successBorder] (`#BBF7D0`, v3 `green-200`) — the name the B7a escalation
  /// first proposed, already taken and one step lighter; [green300]
  /// (`#7BF1A8`) — Tailwind **v4**'s `green-300`, which is what a class-derived
  /// token for this ramp position would hold, while this is an inline hex of
  /// v3's; and [success] (`#15803D`, `green-700`) — the *text* of the very same
  /// chip. Named `successRing` after the source's own field name rather than
  /// after the ramp position, so the collision with [green300] cannot recur.
  ///
  /// **Carried, not rendered — and that is faithful.** `config.ring` is read
  /// nowhere in `HistoryPage.tsx`: the badge at `:304-306` is
  /// `border-2 border-white` over `backgroundColor: config.bg`, and the only
  /// reads of the table are `config.icon` (`:284`), `config.bg` (`:305`,
  /// `:323`) and `config.text` (`:307`, `:323`). The field is dead in the web
  /// app too. It is ported because the port carries the source's data, and
  /// `history_i18n_test.dart:219-232` asserts it stays distinct from `bg`.
  static const Color successRing = Color(0xFF86EFAC);
}

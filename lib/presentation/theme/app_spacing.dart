/// The spacing, radius and fixed-chrome scale.
///
/// The React source spaces everything with Tailwind utility classes, so the
/// scale is Tailwind's: one step = `0.25rem` = **4 logical pixels** at the
/// app's 16 px root (`theme.css:4`, `--font-size: 16px`). The names below are
/// the step values, not invented t-shirt sizes, so a reviewer holding
/// `gap-1.5` next to [gap6] can check the port by arithmetic instead of taste.
///
/// Tier 2 compares spacing as values. That only works if the values are named
/// somewhere a test can read them.
library;

/// Spacing steps and radii. Never instantiated.
abstract final class AppSpacing {
  // ── Tailwind spacing steps actually used by B2's surfaces ──────────────────

  /// `p-0.5` — 2 px.
  static const double gap2 = 2;

  /// `p-1` / `gap-1` — 4 px.
  static const double gap4 = 4;

  /// `gap-1.5` — 6 px. The language toggle's flag-to-label gap.
  static const double gap6 = 6;

  /// `p-2` / `gap-2` — 8 px.
  static const double gap8 = 8;

  /// `px-2.5` — 10 px. The language toggle's horizontal padding.
  static const double gap10 = 10;

  /// `p-3` / `gap-3` — 12 px.
  static const double gap12 = 12;

  /// `p-4` / `gap-4` — 16 px. The default page gutter.
  static const double gap16 = 16;

  /// `p-5` — 20 px.
  static const double gap20 = 20;

  /// `p-6` — 24 px.
  static const double gap24 = 24;

  /// `p-8` — 32 px.
  static const double gap32 = 32;

  /// `p-10` — 40 px. The padding of the catalogue's error and empty panels
  /// (`ServicePage.tsx:267,434,510`).
  static const double gap40 = 40;

  /// `w-14 h-14` — 56 px. Two different things at the same size: the
  /// `GlassIcon` on a catalogue card (`ServicePage.tsx:454`, passed as
  /// `size={56}`) and the neutral round-rect tile the error/empty panels put
  /// their glyph in.
  static const double tile56 = 56;

  // ── Radii ──────────────────────────────────────────────────────────────────

  /// `rounded-lg` — 8 px.
  static const double radiusLg = 8;

  /// `rounded-xl` — 12 px. The chip/button radius the shell already uses.
  static const double radiusXl = 12;

  /// `rounded-2xl` — 16 px. Cards.
  static const double radius2xl = 16;

  /// `rounded-full`, expressed as a radius large enough to fully round any
  /// chrome element this app draws.
  static const double radiusFull = 9999;

  // ── Fixed chrome ───────────────────────────────────────────────────────────

  /// `h-16` in `Layout.tsx` — 64 logical pixels, taller than Material's 56
  /// default so the brand + sub-brand stack fits.
  static const double topBarHeight = 64;

  /// The brand mark tile in the top bar, and the flag disc in the language
  /// toggle's larger sibling. `Layout.tsx`'s `w-9 h-9`.
  static const double brandMarkSize = 36;

  /// `w-5 h-5` — the language toggle's flag disc (`LanguageToggle.tsx:79`).
  static const double flagSize = 20;

  // ── B2b additions — Home ───────────────────────────────────────────────────
  //
  // Same § 3.1 deviation as `app_colors.dart`'s B2b block, for a weaker reason:
  // no gate forbids a raw number in a widget the way B2-AC-11 forbids a raw
  // colour. They are named anyway because every B2a widget spaces itself from
  // this class and a page that mixed `AppSpacing.gap16` with a bare `14` would
  // read as if one of the two were significant. Each is a Tailwind step at the
  // 16 px root, named for its pixel value like the rest of the file.

  /// `py-3.5` / `px-3.5` — 14 px. The hero search field's vertical padding and
  /// the "See service" chip's horizontal one.
  static const double gap14 = 14;

  /// `rounded-3xl` — 24 px. The ID card, the category slides and the dialogs.
  static const double radius3xl = 24;

  /// `w-9 h-9` — 36 px. The summary tile's icon tile and the banner's glyph
  /// tile. Numerically [brandMarkSize]; named separately because the brand mark
  /// and a content tile would be resized for different reasons.
  static const double tile36 = 36;

  /// `w-10 h-10` — 40 px. The two slider arrows.
  static const double control40 = 40;

  /// `w-11 h-11` — 44 px. The ID card's QR button.
  static const double tile44 = 44;

  /// `w-12 h-12` — 48 px. The service sheet's category tile.
  static const double tile48 = 48;

  /// `h-24` — 96 px. One summary-tile skeleton.
  static const double skeletonSummary = 96;

  /// `h-40` — 160 px. A news card's thumbnail, and its skeleton's.
  static const double newsThumbHeight = 160;

  /// `h-52` — 208 px. One service-card skeleton.
  static const double skeletonServiceCard = 208;

  /// `h-80` — 320 px. One news-card skeleton.
  static const double skeletonNewsCard = 320;

  /// `h-[360px]` — the category slide's fixed height (`HomePage.tsx:556`).
  /// **Half of B2-AC-31's decode budget**: paired with [categorySlideWidth] it
  /// is the box those eight 864×1152 photographs are painted into.
  static const double categorySlideHeight = 360;

  /// `w-[72%]` of a 390 px viewport — **281 px**, the width B1b § 6.3 measured
  /// the category slide at and sized `civil-population` and its seven siblings
  /// against ("Max render (CSS) 281×360"). It is a constant rather than a
  /// fraction because it is the number the asset tier was derived from; the
  /// widget still lays out at 72 % and uses this only as the decode target.
  static const double categorySlideWidth = 281;

  /// `w-48 h-48` — 192 px. The QR preview inside the verification dialog.
  static const double qrPreview = 192;

  // ── B10 additions — boot, onboarding, tutorial, button ─────────────────────

  /// `rounded-t-[2rem]` / `sm:rounded-[2rem]` — 32 px. The splash's bottom
  /// sheet (`SplashScreens.tsx:294`).
  static const double radius4xl = 32;

  /// `w-6 h-6` — 24 px. The dot hit area (WCAG 2.5.8, `SplashScreens.tsx:335`)
  /// and slide 2's step markers. Numerically [gap24]; named because a hit area
  /// and a gap are resized for different reasons.
  static const double hit24 = 24;

  /// The **visual** dot: `height: 6px`, `width: 6px` inactive and `20px`
  /// active (`SplashScreens.tsx:340-341`, `TutorialOverlay.tsx:436-437`).
  static const double dotSize = 6;
  static const double dotActiveWidth = 20;

  /// `size={58}` — the six `GlassIcon` tiles on splash slide 1
  /// (`SplashScreens.tsx:80`). Not [tile56]: the source says 58.
  static const double splashTile58 = 58;

  /// `w-24 h-24` — 96 px. The boot logo tile (`LoadingScreen.tsx:81`).
  static const double bootLogoTile = 96;

  /// `w-16 h-16` — 64 px. The logo image inside that tile (`:88`).
  static const double bootLogoGlyph = 64;

  /// `w-48` / `h-1` — the boot progress bar (`LoadingScreen.tsx:101`).
  static const double bootProgressWidth = 192;
  static const double bootProgressHeight = 4;

  /// `w-20 h-20` — 80 px. The tutorial step-1 home tile
  /// (`TutorialOverlay.tsx:41`).
  static const double tutorialHeroTile = 80;

  /// `min-h-[160px]` — the tutorial's visual well (`:392`).
  static const double tutorialVisualMinHeight = 160;

  /// `max-w-[19rem]` — 304 px. Slide 2's tracking card (`SplashScreens.tsx:98`).
  static const double trackingCardMaxWidth = 304;

  /// `SWIPE_THRESHOLD = 50` — `SplashScreens.tsx:33`. Pixels of horizontal drag
  /// before a gesture counts as a slide change. A **token**, not a magic
  /// number, because § 6.14 and `B10-AC-26` make it Tier 2 material.
  static const double swipeThreshold = 50;
}

/// Motion constants — durations the source states as data.
///
/// § 6.14: *"Durations are tokens too."* They live beside the spacing rather
/// than inside the widgets for the same reason the colours do: Tier 2 compares
/// **values**, and a `Duration(milliseconds: 1800)` written inline in a widget
/// body is invisible to it.
///
/// Every value below is a literal from the source, cited. None is a feel
/// judgement — `B10-AC-26` asserts the five against the `.tsx`.
abstract final class AppMotion {
  AppMotion._();

  /// `DEFAULT_DURATION = 1800` — `LoadingScreen.tsx:17`. The boot hold, and the
  /// progress bar's own animation length (`--lcc-boot-ms`, `:109`).
  static const Duration bootHold = Duration(milliseconds: 1800);

  /// `FADE_MS = 320` — `LoadingScreen.tsx:18`, and `EXIT_MS = 320` —
  /// `SplashScreens.tsx:32`. One value, two names in the source; one token
  /// here because they are the same 320 ms opacity transition.
  ///
  /// `onDone` fires at `duration + FADE_MS` = **2120 ms**, not at 1800
  /// (`LoadingScreen.tsx:36-37`). [bootTotal] is that sum, named so the
  /// arithmetic is stated once.
  static const Duration exitFade = Duration(milliseconds: 320);

  /// `duration + FADE_MS` — `LoadingScreen.tsx:37`. `B10-AC-32`.
  static const Duration bootTotal = Duration(milliseconds: 2120);

  /// `transition-opacity duration-500` — the splash backdrop cross-fade
  /// (`SplashScreens.tsx:260`). A background-image cannot be transitioned, so
  /// the source stacks all three and fades between them; the port does the
  /// same.
  static const Duration backdropCrossFade = Duration(milliseconds: 500);

  /// `transition-opacity duration-300` / `transition-transform duration-300`
  /// and `setTimeout(onDone, 300)` — the tutorial's exit
  /// (`TutorialOverlay.tsx:344`, `:361`, `:367`).
  static const Duration tutorialExit = Duration(milliseconds: 300);

  /// `transition-all duration-200` — the progress dot's width change
  /// (`SplashScreens.tsx:338`, `TutorialOverlay.tsx:434`).
  static const Duration dotMorph = Duration(milliseconds: 200);

  /// `transition-all duration-200` — `Button.tsx:92`.
  static const Duration buttonState = Duration(milliseconds: 200);
}

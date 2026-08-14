/// Port of `lcc-app/src/app/components/SplashScreens.tsx` (365 lines) — the
/// three first-run onboarding slides.
///
/// Shown only when `lcc.onboarding_seen` is absent, so a returning citizen goes
/// straight from the boot splash to Home. **Skip** and **Start** both mark it
/// seen (`SplashScreens.tsx`:216, :277). `main.dart` owns the gate and the
/// phase transition; this widget owns the slides.
///
/// ## What is composed in rather than imported (§ 6.9)
///
/// [slide3Visual] and [backdropBuilder] are slots. See
/// `splash_slide_visual.dart` for the two G-L7 / Tier-A walls that make them
/// slots rather than imports, and `app_routes.dart` for where they are filled.
/// Slide 1 needs **no** slot: the source's `CATEGORIES` is a hardcoded const,
/// so `onboarding_categories.dart` transcribes it and this file imports that.
///
/// ## Navigation — four affordances, three of them ported
///
/// | source | here |
/// |---|---|
/// | `next` / `prev` buttons (`:222-223`) | yes |
/// | dots jump to any slide (`:332`) | yes |
/// | horizontal swipe past 50 px (`:235-241`) | yes |
/// | **arrow keys** (`:226-233`) | **not ported** — see below |
///
/// `useEffect` binds `ArrowLeft`/`ArrowRight` on `window`. That is a desktop
/// affordance on a surface this app only ever renders on a handset, and
/// Flutter's equivalent (a focused `Shortcuts`/`Actions` scope) would be
/// **new** interaction the source does not have on the platform being ported —
/// there is no hardware keyboard in the target envelope. Recorded here as a
/// deliberate omission rather than silently dropped; it is the mirror image of
/// § 6.2's `Footer` ruling.
///
/// `goTo` **clamps** to `[0, slides − 1]` (`:221`), so swiping back on slide 1
/// or forward on slide 3 neither throws nor wraps (`B10-AC-37`).
///
/// ## Every `.tr()` here passes `context:` (G-L8, `B10-AC-12`)
///
/// A bare `.tr()` reads `Localization.instance`, a global, and creates no
/// `InheritedWidget` dependency — which is D-3's whole mechanism (§ 6.6.2).
/// The splash carries a `LanguageToggle`, so a bare call here would be the
/// defect at its most visible: the citizen switches language on slide 1 and
/// nothing but the toggle's own label changes.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/storage/storage_service.dart';
import '../../i18n/i18n.dart';
import '../common/glass_icon.dart';
import '../icons/lucide_icon.dart';
import '../shell/language_toggle.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'onboarding_categories.dart';
import 'splash_slide_visual.dart';

/// One slide's fixed data — `SplashScreens.tsx`:56-72's `Slide`.
@immutable
class _SlideSpec {
  const _SlideSpec({
    required this.badgeInk,
    required this.washStart,
    required this.washMid,
    required this.badgeKey,
    this.badgeLucide,
    this.badgeMaterial,
    required this.titleKey,
    required this.descKey,
  }) : assert(
          (badgeLucide == null) != (badgeMaterial == null),
          'exactly one glyph source — see the divergence note below',
        );

  /// *"Tint for this slide's badge only. Each value is a dark shade: the
  /// vibrant versions fail WCAG 1.4.3 as text (#0EA5E9 → 2.32:1), so the badge
  /// never uses a bright accent directly."* — `SplashScreens.tsx`:57-62,
  /// carried across with the value it explains.
  final Color badgeInk;

  /// The first two stops of `linear-gradient(160deg, …)`. The third is shared
  /// ([AppColors.splashWashEnd]).
  final Color washStart;
  final Color washMid;

  final String badgeKey;

  /// A **bundled** lucide name. Preferred: it is the source's own glyph.
  final String? badgeLucide;

  /// A Material stand-in, used only where the source's lucide glyph is not in
  /// the bundled 86. See the divergence note on [_kSlides].
  final IconData? badgeMaterial;

  final String titleKey;
  final String descKey;
}

/// `buildSlides()` — `SplashScreens.tsx`:165-201, minus the visuals, which are
/// built per-slide below because two of them need runtime context.
///
/// **One badge glyph is a named divergence.** The source uses `Sparkles`,
/// `Clock` and `ShieldCheck` (`:173`, `:184`, `:195`). `Clock` and
/// `ShieldCheck` **are** in the bundled 86 and are used as-is. **`Sparkles` is
/// not**, and bundling an SVG is outside B10's § 3.1 scope.
///
/// The wrong move here would be to pass `'Sparkles'` to `LucideIcon` anyway:
/// the registry falls back to `FileText` (`app_icons.dart`:43), so slide 1's
/// badge would silently show a *document* glyph and no test or tier would call
/// it out. An explicit Material stand-in is worse fidelity than the real glyph
/// and better fidelity than a silent wrong one — and, unlike the fallback, it
/// is visible in this source file. The real fix is to bundle `Sparkles.svg`;
/// the batch report files it.
const List<_SlideSpec> _kSlides = <_SlideSpec>[
  _SlideSpec(
    badgeInk: AppColors.splashBadgeInk1,
    washStart: AppColors.splashWash1Start,
    washMid: AppColors.splashWash1Mid,
    badgeKey: 'onboarding.slide1Badge',
    // `Sparkles` — NOT BUNDLED. See the note above.
    badgeMaterial: Icons.auto_awesome,
    titleKey: 'onboarding.slide1Title',
    descKey: 'onboarding.slide1Desc',
  ),
  _SlideSpec(
    badgeInk: AppColors.splashBadgeInk2,
    washStart: AppColors.splashWash2Start,
    washMid: AppColors.splashWash2Mid,
    badgeKey: 'onboarding.slide2Badge',
    badgeLucide: 'Clock',
    titleKey: 'onboarding.slide2Title',
    descKey: 'onboarding.slide2Desc',
  ),
  _SlideSpec(
    badgeInk: AppColors.splashBadgeInk3,
    washStart: AppColors.splashWash3Start,
    washMid: AppColors.splashWash2Mid,
    badgeKey: 'onboarding.slide3Badge',
    badgeLucide: 'ShieldCheck',
    titleKey: 'onboarding.slide3Title',
    descKey: 'onboarding.slide3Desc',
  ),
];

/// The three onboarding slides.
class SplashScreens extends StatefulWidget {
  const SplashScreens({
    super.key,
    required this.onDone,
    required this.storage,
    required this.slide3Visual,
    required this.backdropBuilder,
  });

  /// Called [AppMotion.exitFade] after Skip or Start — `:218`.
  final VoidCallback onDone;

  /// The single writer of `lcc.onboarding_seen`. Threaded as a parameter, not
  /// resolved from a container: **G-L5** forbids any widget naming a locator,
  /// and this is the same seam `AppTopBar` and `LanguageToggle` already use.
  final StorageService storage;

  /// The real `LaoIdCard`, composed at the route layer — § 6.9.
  final Widget slide3Visual;

  /// The shared backdrop photograph, per slide — § 6.9.
  final SplashBackdropBuilder backdropBuilder;

  @override
  State<SplashScreens> createState() => _SplashScreensState();
}

class _SplashScreensState extends State<SplashScreens> {
  int _index = 0;
  bool _exiting = false;
  double? _touchStartX;

  bool get _isLast => _index == _kSlides.length - 1;

  /// `finish()` — `:215-219`. Marks seen, fades, then calls `onDone`.
  ///
  /// The write is **not awaited before the fade starts**: the source's
  /// `markOnboardingSeen()` is synchronous `localStorage` and the fade begins
  /// in the same tick. Awaiting a keychain write here would stall the exit on
  /// a slow device for no behavioural gain, and `StorageService` already
  /// swallows a write failure (§ 6.11).
  void _finish() {
    widget.storage.markOnboardingSeen();
    setState(() => _exiting = true);
    Future<void>.delayed(AppMotion.exitFade, () {
      if (mounted) widget.onDone();
    });
  }

  /// `goTo` — `:221`. Clamped, never wrapping (`B10-AC-37`).
  void _goTo(int i) {
    final int clamped = i.clamp(0, _kSlides.length - 1);
    if (clamped != _index) setState(() => _index = clamped);
  }

  void _next() => _isLast ? _finish() : _goTo(_index + 1);

  /// `handleTouchEnd` — `:235-241`. Below the threshold, nothing happens.
  void _onHorizontalDragEnd(DragEndDetails details, double endX) {
    final double? start = _touchStartX;
    _touchStartX = null;
    if (start == null) return;
    final double dx = endX - start;
    if (dx.abs() < AppSpacing.swipeThreshold) return;
    _goTo(dx < 0 ? _index + 1 : _index - 1);
  }

  @override
  Widget build(BuildContext context) {
    final _SlideSpec slide = _kSlides[_index];

    return AnimatedOpacity(
      opacity: _exiting ? 0 : 1,
      duration: AppMotion.exitFade,
      curve: Curves.easeOut,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (DragStartDetails d) =>
            _touchStartX = d.globalPosition.dx,
        onHorizontalDragEnd: (DragEndDetails d) => _onHorizontalDragEnd(
          d,
          // `changedTouches[0].clientX` has no direct Flutter analogue on
          // `DragEndDetails`; the primary velocity's sign carries the same
          // information, but the source thresholds on **distance**, so the
          // last known position is tracked instead.
          _lastDragX ?? _touchStartX ?? 0,
        ),
        onHorizontalDragUpdate: (DragUpdateDetails d) =>
            _lastDragX = d.globalPosition.dx,
        child: ColoredBox(
          color: AppColors.bootGradientEnd,
          child: Stack(
            children: <Widget>[
              _backdrops(),
              SafeArea(
                child: Column(
                  children: <Widget>[
                    _topBar(),
                    Expanded(child: _illustration()),
                    _sheet(slide),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double? _lastDragX;

  /// `:256-271` — all three backdrops stacked and cross-faded.
  ///
  /// *"Cross-fading backdrops: one shared photo under each slide's colour wash.
  /// Reusing the hero photo costs no extra bytes … and a different framing per
  /// slide keeps them from looking like the same screen three times."* The
  /// source stacks them because a CSS `background-image` cannot be
  /// transitioned; the port stacks them for the same visual result.
  Widget _backdrops() {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          return Stack(
            children: <Widget>[
              for (int i = 0; i < _kSlides.length; i++)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: i == _index ? 1 : 0,
                      duration: AppMotion.backdropCrossFade,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          widget.backdropBuilder(
                            kSplashBackdropAlignments[i],
                            width,
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                // 160°, the same conversion as the boot
                                // gradient — see `loading_screen.dart`.
                                begin: const Alignment(-0.342, -0.940),
                                end: const Alignment(0.342, 0.940),
                                colors: <Color>[
                                  _kSlides[i].washStart,
                                  _kSlides[i].washMid,
                                  AppColors.splashWashEnd,
                                ],
                                stops: const <double>[0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// `:274-282` — the language toggle and Skip.
  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gap20,
        AppSpacing.gap20,
        AppSpacing.gap20,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          LanguageToggle(storage: widget.storage),
          TextButton(
            onPressed: _finish,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.white.withValues(alpha: 0.8),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gap12,
                vertical: AppSpacing.gap6,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: AppTypography.size12,
                fontWeight: AppTypography.medium,
              ),
            ),
            child: Text('onboarding.skip'.tr(context: context)),
          ),
        ],
      ),
    );
  }

  /// `:285-289` — the illustration well.
  Widget _illustration() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gap20,
        vertical: AppSpacing.gap24,
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Center(
            // `key={index}` on the source's wrapper is what restarts the
            // `.lcc-slide-in` entrance on every change. A `ValueKey` here does
            // the same job for Flutter's element reuse: without it, slide 2's
            // card would be built into slide 1's element and any implicit
            // animation would interpolate between two unrelated layouts.
            key: ValueKey<int>(_index),
            child: _visualFor(_index),
          ),
        ),
      ),
    );
  }

  Widget _visualFor(int index) {
    switch (index) {
      case 0:
        return const _ServicesVisual();
      case 1:
        return const _TrackingVisual();
      default:
        return _DocumentVisual(card: widget.slide3Visual);
    }
  }

  /// `:294-361` — the white bottom sheet: badge, title, description, controls.
  Widget _sheet(_SlideSpec slide) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radius4xl),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(color: AppColors.cardShadowMedium, blurRadius: 24),
        ],
      ),
      child: Padding(
        // `px-6 pt-7 pb-8`
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gap24,
          28,
          AppSpacing.gap24,
          AppSpacing.gap32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _badge(slide),
            const SizedBox(height: AppSpacing.gap16),
            Text(
              slide.titleKey.tr(context: context),
              style: const TextStyle(
                color: AppColors.gray900,
                fontSize: AppTypography.size20,
                fontWeight: AppTypography.semiBold,
                height: AppTypography.lineSnug,
              ),
            ),
            const SizedBox(height: AppSpacing.gap10),
            Text(
              slide.descKey.tr(context: context),
              style: const TextStyle(
                color: AppColors.gray500,
                fontSize: AppTypography.size14,
                height: AppTypography.lineRelaxed,
              ),
            ),
            const SizedBox(height: 28),
            _controls(),
          ],
        ),
      ),
    );
  }

  /// `:297-303` — `backgroundColor: ${badgeInk}1A`, i.e. the ink at 10 %.
  Widget _badge(_SlideSpec slide) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gap12,
        vertical: AppSpacing.gap6,
      ),
      decoration: BoxDecoration(
        color: slide.badgeInk.withValues(alpha: 0x1A / 0xFF),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (slide.badgeLucide != null)
            LucideIcon(
              name: slide.badgeLucide!,
              size: AppSpacing.gap12,
              color: slide.badgeInk,
            )
          else
            Icon(
              slide.badgeMaterial,
              size: AppSpacing.gap12,
              color: slide.badgeInk,
            ),
          const SizedBox(width: AppSpacing.gap6),
          Text(
            slide.badgeKey.tr(context: context),
            style: TextStyle(
              color: slide.badgeInk,
              fontSize: AppTypography.size12,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ],
      ),
    );
  }

  /// `:311-359` — Back | dots | Next, as a three-column grid so the dots stay
  /// centred regardless of the two buttons' widths.
  Widget _controls() {
    return Row(
      children: <Widget>[
        // `1fr`, left-aligned. `index > 0 ? <button> : <div />` — Back is
        // **absent**, not disabled, on slide 1 (`B10-AC-21`).
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: _index > 0 ? _backButton() : const SizedBox.shrink(),
          ),
        ),
        _dots(),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: _nextButton(),
          ),
        ),
      ],
    );
  }

  Widget _backButton() {
    return OutlinedButton(
      onPressed: () => _goTo(_index - 1),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gray500,
        side: const BorderSide(color: AppColors.gray200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gap16,
          vertical: AppSpacing.gap10,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        textStyle: const TextStyle(
          fontSize: AppTypography.size14,
          fontWeight: AppTypography.medium,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const LucideIcon(
            name: 'ChevronLeft',
            size: AppSpacing.gap16,
            color: AppColors.gray500,
          ),
          const SizedBox(width: AppSpacing.gap6),
          Text('onboarding.back'.tr(context: context)),
        ],
      ),
    );
  }

  /// `:350-357`. The label and the glyph both switch on `isLast`:
  /// `getStarted` + a rocket, or `next` + a chevron (`B10-AC-21`).
  Widget _nextButton() {
    return FilledButton(
      onPressed: _next,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gap16,
          vertical: AppSpacing.gap10,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        elevation: 3,
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
          Text(
            (_isLast ? 'onboarding.getStarted' : 'onboarding.next')
                .tr(context: context),
          ),
          const SizedBox(width: AppSpacing.gap6),
          LucideIcon(
            name: _isLast ? 'Rocket' : 'ChevronRight',
            size: AppSpacing.gap16,
            color: AppColors.white,
          ),
        ],
      ),
    );
  }

  /// `:328-347`. Each dot is a 24×24 hit area (WCAG 2.5.8) with a 6 px pill
  /// drawn inside, widening to 20 px when active.
  ///
  /// `aria-label={t("slideOf", { current, total })}` becomes a `Semantics`
  /// label; `aria-current` becomes `selected` (`B10-AC-53`).
  Widget _dots() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gap8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < _kSlides.length; i++)
            Semantics(
              button: true,
              selected: i == _index,
              label: 'onboarding.slideOf'.tr(
                context: context,
                namedArgs: <String, String>{
                  'current': '${i + 1}',
                  'total': '${_kSlides.length}',
                },
              ),
              child: GestureDetector(
                onTap: () => _goTo(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: AppSpacing.hit24,
                  height: AppSpacing.hit24,
                  child: Center(
                    child: AnimatedContainer(
                      duration: AppMotion.dotMorph,
                      width: i == _index
                          ? AppSpacing.dotActiveWidth
                          : AppSpacing.dotSize,
                      height: AppSpacing.dotSize,
                      decoration: BoxDecoration(
                        color:
                            i == _index ? AppColors.primary : AppColors.gray300,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Slide 1 — `ServicesVisual`, `SplashScreens.tsx`:75-88.
///
/// Six `GlassIcon` tiles in a 3-column grid, labelled from the local const.
class _ServicesVisual extends StatelessWidget {
  const _ServicesVisual();

  @override
  Widget build(BuildContext context) {
    // `lang === "lo" ? cat.labelLo : cat.label` — read from the ambient
    // Localizations rather than from a global, which is also what keeps these
    // six labels refreshing on the toggle (§ 6.6.2).
    final Lang lang = Lang.fromCode(Localizations.localeOf(context).languageCode);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      // `gap-x-4 gap-y-5`
      crossAxisSpacing: AppSpacing.gap16,
      mainAxisSpacing: AppSpacing.gap20,
      childAspectRatio: 0.78,
      children: <Widget>[
        for (final OnboardingCategory cat in kOnboardingCategories)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              GlassIcon(
                iconName: cat.iconName,
                color: cat.color,
                size: AppSpacing.splashTile58,
              ),
              const SizedBox(height: AppSpacing.gap8),
              Flexible(
                child: Text(
                  cat.labelFor(lang),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.8),
                    fontSize: AppTypography.size11,
                    height: AppTypography.lineTight,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Slide 2 — `TrackingVisual`, `SplashScreens.tsx`:91-140.
///
/// Entirely hardcoded, including the reference `RC-2026-004821` (`:110`) and
/// the three timestamps (`:93-95`). That is the source's own copy, not sample
/// data standing in for an API — which is why B10 is the one batch in this
/// epic unaffected by the empty test citizen (§ 8.3).
class _TrackingVisual extends StatelessWidget {
  const _TrackingVisual();

  @override
  Widget build(BuildContext context) {
    final List<({String labelKey, String time, bool last})> steps =
        <({String labelKey, String time, bool last})>[
      (
        labelKey: 'onboarding.trackStepSubmitted',
        time: '15 Apr, 09:24',
        last: false
      ),
      (
        labelKey: 'onboarding.trackStepUnderReview',
        time: '16 Apr, 11:05',
        last: false
      ),
      (
        labelKey: 'onboarding.trackStepApproved',
        time: '18 Apr, 10:12',
        last: true
      ),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AppSpacing.trackingCardMaxWidth,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.gap20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radius3xl),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: AppColors.cardShadowMedium, blurRadius: 24),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header: glyph tile, title, reference.
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.gap16),
              child: Row(
                children: <Widget>[
                  Container(
                    width: AppSpacing.control40,
                    height: AppSpacing.control40,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                    child: const Center(
                      child: LucideIcon(
                        name: 'FileText',
                        size: AppSpacing.gap20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gap12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'onboarding.trackDocTitle'.tr(context: context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.gray800,
                            fontSize: AppTypography.size14,
                            fontWeight: AppTypography.semiBold,
                          ),
                        ),
                        const Text(
                          'RC-2026-004821',
                          style: TextStyle(
                            color: AppColors.gray400Inline,
                            fontSize: AppTypography.size11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.gray100),
            const SizedBox(height: AppSpacing.gap16),
            for (int i = 0; i < steps.length; i++)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Container(
                          width: AppSpacing.hit24,
                          height: AppSpacing.hit24,
                          decoration: BoxDecoration(
                            // `s.last ? "#16A34A" : "#344EAD"` — `:120`.
                            color: steps[i].last
                                ? AppColors.trackingDone
                                : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: LucideIcon(
                              name: 'Check',
                              size: AppSpacing.gap14,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        if (i < steps.length - 1)
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.gap4,
                              ),
                              child: SizedBox(
                                width: 2,
                                child: ColoredBox(
                                  color: AppColors.trackingConnector,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.gap12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              i < steps.length - 1 ? AppSpacing.gap16 : 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              steps[i].labelKey.tr(context: context),
                              style: const TextStyle(
                                color: AppColors.gray800,
                                fontSize: AppTypography.size14,
                                fontWeight: AppTypography.medium,
                                height: AppTypography.lineTight,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.gap2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const LucideIcon(
                                  name: 'Clock',
                                  size: AppSpacing.gap12,
                                  color: AppColors.gray400Inline,
                                ),
                                const SizedBox(width: AppSpacing.gap4),
                                Text(
                                  steps[i].time,
                                  style: const TextStyle(
                                    color: AppColors.gray400Inline,
                                    fontSize: AppTypography.size11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Slide 3 — `DocumentVisual`, `SplashScreens.tsx`:143-163.
///
/// The card behind, the real card in front, and the scan caption. [card] is
/// the composed `LaoIdCard` — see `splash_slide_visual.dart` for why it
/// arrives as a parameter.
class _DocumentVisual extends StatelessWidget {
  const _DocumentVisual({required this.card});

  final Widget card;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            // `absolute inset-x-4 -top-4 h-24` — the card peeking out behind,
            // `aria-hidden`, suggesting a stack of stored documents.
            Positioned(
              left: AppSpacing.gap16,
              right: AppSpacing.gap16,
              top: -AppSpacing.gap16,
              height: AppSpacing.bootLogoTile,
              child: const ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.splashCardStack,
                    borderRadius:
                        BorderRadius.all(Radius.circular(AppSpacing.radius3xl)),
                  ),
                ),
              ),
            ),
            card,
          ],
        ),
        const SizedBox(height: AppSpacing.gap16),
        Text(
          'onboarding.idScan'.tr(context: context),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.8),
            fontSize: AppTypography.size11,
          ),
        ),
      ],
    );
  }
}

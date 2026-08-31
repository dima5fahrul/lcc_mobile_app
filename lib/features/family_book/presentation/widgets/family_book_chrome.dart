/// The page frame and the three chrome pieces inside it — `frame` (`:244-274`),
/// `StepIndicator` (`:125-160`), `StepHeader` (`:162-174`) and the bottom CTA
/// (`:569-594`).
///
/// ## The frame is shared by five of the eight states and NOT by the sixth
///
/// Loading, signed out, error, empty and steps 1-3 all render through `frame`.
/// **The success screen does not** (`:340-388`): it is
/// `min-h-full flex flex-col items-center justify-center p-6`, with no header,
/// no back chevron and no step indicator. Reusing the frame there is a Tier 1
/// structural failure, which is why [FamilyBookFrame] is a widget the page
/// chooses rather than a wrapper the page always applies.
///
/// ## Two things inside the frame are conditional, and on different conditions
///
/// * The **step indicator** renders on `{book && …}` (`:262`) — on the *book*,
///   not on the step. In the four bookless states it is absent, and a port that
///   gated it on `step >= 1` would render it in all of them.
/// * The **CTA** renders on `{cta && …}` (`:268`), and `frame` is called with
///   one argument in every state but the wizard (`:278`, `:296`, `:306`,
///   `:327`). `F4-AC-37` asserts both absences, not just the presences.
///
/// ## The chevron is wired in every state
///
/// `goBack` (`:225-228`) is passed to the header button unconditionally, and in
/// the four states where `step` is pinned at 1 it always calls the caller's
/// `onBack`. There is **no hardware-back handler**: the web's chevron has no
/// analogue on a hash router, `resident_certificate_page.dart` adds none, and
/// adding one here would be an L-10 degrade-better (`F4-AC-40`).
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/family_book_derivations.dart';
import '../bloc/family_book_state.dart';

/// `space-y-5` — the 20 px gap between the body container's direct children
/// (`:265`).
const double kFamilyBookBodyGap = AppSpacing.gap20;

/// `frame(body, cta?)` — `FamilyBookPage.tsx:244-274`.
class FamilyBookFrame extends StatelessWidget {
  const FamilyBookFrame({
    super.key,
    required this.onBack,
    required this.showStepIndicator,
    required this.step,
    required this.children,
    this.cta,
  });

  /// `goBack` — wired in every state, including the four with no step to
  /// decrement.
  final VoidCallback onBack;

  /// `{book && <StepIndicator …>}` — `:262`.
  final bool showStepIndicator;

  final int step;

  /// The body's direct children, laid out with `space-y-5` between them.
  final List<Widget> children;

  /// `{cta && …}` — `:268`. Null in every state but the wizard.
  final Widget? cta;

  @override
  Widget build(BuildContext context) {
    final List<Widget> spaced = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) spaced.add(const SizedBox(height: kFamilyBookBodyGap));
      spaced.add(children[i]);
    }

    // ── GOR-267 — this was a bare `ColoredBox`, and it is a render root ──────
    //
    // `/service/family-book` is mounted OUTSIDE the `ShellRoute`, correctly:
    // `Layout.tsx:300`'s `isSubPage = !MAIN_TABS.has(activeTab)` is true for
    // every certificate tab (`MAIN_TABS` at `:46-52` is
    // `{home, service, history, wallet, account}`), so `:388` slides the bottom
    // nav off with `translate-y-full` and `:385` suppresses the chat FAB. **The
    // source renders all six full-frame** and B12 reproduced that deliberately.
    //
    // But nothing then supplied a `Material` ancestor. Every `Text` below
    // inherited `WidgetsApp`'s `_errorTextStyle` — 48px red monospace with a
    // **yellow double underline**, whose own `debugLabel` reads *"fallback
    // style; consider putting your text in a Material"* — in release builds as
    // well as debug, and the content drew under the status bar for want of a
    // `SafeArea`. One omission, two symptoms. This page and F1's Resident were
    // the only two of the six affected; birth, death, marriage and divorce
    // already carry a top-level `Scaffold` (e.g.
    // `marriage_certificate_page.dart:114`), as do `/signin`, `/help`, `/news`
    // and `/news/:id`.
    //
    // **The chrome belongs HERE and not in `family_book_page.dart`.**
    // `app_routes.dart:1050-1084` renders a `FamilyBookFrame` *directly* in the
    // `SessionStatus.initial | loading` branch (`:1059`), before
    // `FamilyBookPage` is constructed at all, so siting it on the page would
    // leave that render root broken for as long as the session is resolving.
    // `test/features/certificates/material_ancestor_test.dart`'s T-2 pins that
    // branch.
    //
    // **And it is not a `ShellRoute` re-parent.** Moving the route inside the
    // shell would add a brand bar, a bottom nav and a chat FAB to a form the
    // source shows without them — an `ssd.md` § 11.2 L-10 regression.
    //
    // `backgroundColor` carries the `bg-[#F0F2F8]` (`:245`) the `ColoredBox`
    // used to; `SafeArea` matches what the six correct siblings do. `body:` and
    // `backgroundColor:` only — an `appBar` or a `bottomNavigationBar` here
    // would add chrome the source hides.
    //
    // Every widget test over this page passed before this change, because the
    // harness supplies the `MaterialApp`/`Scaffold` the running app does not —
    // the suite was asserting against its own harness.
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _Header(onBack: onBack),
            if (showStepIndicator) FamilyBookStepIndicator(step: step),
            Expanded(
              child: SingleChildScrollView(
                // `px-4 py-6 … pb-28` — `:265`.
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gap16,
                  AppSpacing.gap24,
                  AppSpacing.gap16,
                  112,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: spaced,
                ),
              ),
            ),
            if (cta != null) cta!,
          ],
        ),
      ),
    );
  }
}

/// `:246-260` — the header: chevron, centred title and subtitle, and a spacer
/// the same width as the chevron so the title is centred against the *frame*
/// rather than against the remaining space (`:258`).
class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.white,
        // `px-4 py-3`
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gap16,
          vertical: AppSpacing.gap12,
        ),
        child: Row(
          children: <Widget>[
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBack,
                // `w-9 h-9`
                child: const SizedBox(
                  width: AppSpacing.tile36,
                  height: AppSpacing.tile36,
                  child: Center(
                    child: LucideIcon(
                      name: 'ChevronLeft',
                      size: 20,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: <Widget>[
                  Text(
                    // `t("title")` — `:255`.
                    '$kFamilyBookNamespace.title'.tr(context: context),
                    style: const TextStyle(
                      fontSize: AppTypography.size14,
                      fontWeight: AppTypography.semiBold,
                      color: AppColors.gray800,
                    ),
                  ),
                  Text(
                    // `t("subtitle")` — `:256`.
                    '$kFamilyBookNamespace.subtitle'.tr(context: context),
                    style: const TextStyle(
                      fontSize: AppTypography.size12,
                      color: AppColors.gray400Inline,
                    ),
                  ),
                ],
              ),
            ),
            // `<div className="w-9 flex-shrink-0" />` — `:258`.
            const SizedBox(width: AppSpacing.tile36),
          ],
        ),
      );
}

/// `StepIndicator` — `FamilyBookPage.tsx:125-160`.
///
/// Three dots and two connectors. `done` dots carry the check glyph at 55 %
/// opacity; `active` dots carry their number at full opacity; neither-yet dots
/// are `bg-gray-100` with `#9CA3AF` numerals. A connector is primary at 40 %
/// once passed and `#E5E7EB` before.
class FamilyBookStepIndicator extends StatelessWidget {
  const FamilyBookStepIndicator({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.white,
        // `px-4 py-4`
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gap16,
          vertical: AppSpacing.gap16,
        ),
        child: Row(
          children: <Widget>[
            for (int id = 1; id <= kFamilyBookStepCount; id++) ...<Widget>[
              _dot(id),
              if (id != kFamilyBookStepCount) Expanded(child: _bar(id)),
            ],
          ],
        ),
      );

  Widget _dot(int id) {
    final bool done = step > id;
    final bool active = step == id;
    return Opacity(
      // `opacity: done ? 0.55 : 1` — `:140`.
      opacity: done ? 0.55 : 1,
      child: Container(
        // `w-8 h-8 rounded-full`
        width: AppSpacing.gap32,
        height: AppSpacing.gap32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done || active ? AppColors.primary : AppColors.gray100,
        ),
        child: done
            // `<Check className="w-3.5 h-3.5" strokeWidth={3}/>` — `:143`.
            ? const LucideIcon(name: 'Check', size: 14, color: AppColors.white)
            : Text(
                '$id',
                style: TextStyle(
                  // `font-bold text-xs`
                  fontSize: AppTypography.size12,
                  fontWeight: AppTypography.bold,
                  color: active ? AppColors.white : AppColors.gray400Inline,
                ),
              ),
      ),
    );
  }

  Widget _bar(int id) => Opacity(
        // `opacity: step > s.id ? 0.4 : 1` — `:150`.
        opacity: step > id ? 0.4 : 1,
        child: Container(
          // `h-0.5 mx-1.5 rounded-full`
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.gap6),
          decoration: BoxDecoration(
            color: step > id ? AppColors.primary : AppColors.gray200,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
        ),
      );
}

/// `StepHeader` — `FamilyBookPage.tsx:162-174`.
///
/// `tracking-wider` is `0.05em`, **not** the resident wizard's `tracking-widest`
/// — same-looking eyebrow line, different letter-spacing, and the two pages sit
/// one route apart.
class FamilyBookStepHeader extends StatelessWidget {
  const FamilyBookStepHeader({super.key, required this.step});

  final int step;

  /// `tracking-wider` at `text-[11px]`.
  static const double tracking = AppTypography.size11 * 0.05;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            // `t("stepOf", { n: step, m: STEPS.length })` — `:168`.
            '$kFamilyBookNamespace.stepOf'.tr(
              context: context,
              namedArgs: <String, String>{
                'n': '$step',
                'm': '$kFamilyBookStepCount',
              },
            ).toUpperCase(),
            style: const TextStyle(
              fontSize: AppTypography.size11,
              fontWeight: AppTypography.semiBold,
              letterSpacing: tracking,
              color: AppColors.primary,
            ),
          ),
          // `mt-0.5`
          const SizedBox(height: AppSpacing.gap2),
          Text(
            // `t(meta.labelKey)` — `:170`.
            '$kFamilyBookNamespace.step${step}Label'.tr(context: context),
            style: const TextStyle(
              fontSize: AppTypography.size18,
              fontWeight: AppTypography.semiBold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: AppSpacing.gap2),
          Text(
            // `t(meta.subKey)` — `:171`.
            '$kFamilyBookNamespace.step${step}Subtitle'.tr(context: context),
            style: const TextStyle(
              fontSize: AppTypography.size12,
              color: AppColors.gray400Inline,
            ),
          ),
        ],
      );
}

/// The bottom CTA — `FamilyBookPage.tsx:569-594`.
///
/// **Disabled only while pending** (`:571`). There is no `canProceed`, no
/// validation and no empty-book guard: `fsd.md`:817 measures *"validation:
/// none"* and Next always advances. A port that disabled this on an empty
/// household would be a degrade-better with no analogue in the source, and
/// `F4-AC-41` asserts it is **enabled** on a fully-empty book.
///
/// The label is `submitting` while pending, `submitRecord` on the last step and
/// `continue` otherwise. The spinner is Flutter's: `Loader2` is not one of the
/// 89 bundled lucide glyphs, and `app_button.dart:243` records the same
/// substitution.
class FamilyBookCta extends StatelessWidget {
  const FamilyBookCta({
    super.key,
    required this.pending,
    required this.isLastStep,
    required this.onTap,
  });

  final bool pending;
  final bool isLastStep;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String label = pending
        ? '$kFamilyBookNamespace.submitting'.tr(context: context)
        : isLastStep
            ? '$kFamilyBookNamespace.submitRecord'.tr(context: context)
            : '$kFamilyBookNamespace.continue'.tr(context: context);

    return Container(
      color: AppColors.white,
      // `px-4 pt-3 pb-6`
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gap16,
        AppSpacing.gap12,
        AppSpacing.gap16,
        AppSpacing.gap24,
      ),
      child: Semantics(
        button: true,
        enabled: !pending,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: pending ? null : onTap,
          child: Container(
            // `w-full h-14 rounded-2xl`
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // `backgroundColor: pending ? "#C7D2FE" : "#344EAD"` — `:574`.
              color: pending ? AppColors.ctaPendingFill : AppColors.primary,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppSpacing.radius2xl),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (pending) ...<Widget>[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: _Spinner(),
                  ),
                  // `gap-2`
                  const SizedBox(width: AppSpacing.gap8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: AppTypography.size14,
                    fontWeight: AppTypography.semiBold,
                    color: AppColors.white,
                  ),
                ),
                if (!pending) ...<Widget>[
                  const SizedBox(width: AppSpacing.gap8),
                  const LucideIcon(
                    name: 'ArrowRight',
                    size: 16,
                    color: AppColors.white,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `<Loader2 className="w-4 h-4 animate-spin"/>` — `:580`.
///
/// Material's indicator is the framework's equivalent of lucide's `Loader2`;
/// there is no `Loader2` glyph in the bundled set of 89 and inventing one would
/// be a divergence. `app_button.dart:240-250` records the same substitution, as
/// do `reference_select_view.dart:134` and `searchable_select.dart:389` — this
/// is the fourth site and the convention, not a new decision.
class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
      );
}

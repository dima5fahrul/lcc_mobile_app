/// `FamilyBookPage.tsx:181-596` — the page itself: eight states, evaluated in
/// the source's order, with early returns.
///
/// ## The cascade below IS the specification
///
/// `specs.md` § 6.3: the source evaluates `loading` (`:277`), `!isAuthenticated`
/// (`:295`), `error && !error.isNotFound` (`:305`), `!book` (`:326`),
/// `submitted` (`:339`), then the wizard — **top to bottom, with early
/// returns** — and re-ordering them changes what renders. The predicates are
/// [FamilyBookViewState]'s, written there as a cascade for the same reason, and
/// this build method reads them in the same order so the two files cannot
/// disagree about which state wins.
///
/// Three consequences worth stating where they are implemented:
///
/// * **A 404 renders the empty card, not the error card.** `showsError`
///   excludes `NotFoundFailure`; `showsEmpty` catches what falls through. This
///   is the only branch of this page any reference in the repository exercises
///   (slot 47).
/// * **The success screen does not use the frame.** `:340-388` is its own
///   centred layout; see `family_book_success.dart`.
/// * **The CTA is passed only in the wizard branch**, because `frame` is called
///   with one argument everywhere else.
///
/// ## What this page does NOT have
///
/// No hardware-back handler, no confirmation dialog, no toast, no snackbar, no
/// empty-book CTA guard, and no validation of any kind. Each of those is a
/// thing the source does not do, and adding any of them is the L-10 corollary
/// (b) degrade-better that `F4-AC-70` reviews for line by line.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../i18n/i18n.dart';
import '../../domain/entities/family_book.dart';
import '../bloc/family_book_cubit.dart';
import '../bloc/family_book_state.dart';
import '../widgets/family_book_chrome.dart';
import '../widgets/family_book_states.dart';
import '../widgets/family_book_steps.dart';
import '../widgets/family_book_success.dart';

/// `FamilyBookPageProps` — `:177-179`.
class FamilyBookPage extends StatefulWidget {
  const FamilyBookPage({
    super.key,
    required this.cubit,
    required this.onBack,
  });

  /// Resolved by a route builder, never by a widget (`ssd.md`:511, G-L5).
  /// Passed rather than created here so a test can pump the page with a cubit
  /// built from doubles and no container at all.
  final FamilyBookCubit cubit;

  /// `onBack()` — `:178`. Called when the chevron is tapped on step 1, in every
  /// bookless state, and from the success screen's own button (`:379`).
  final VoidCallback onBack;

  @override
  State<FamilyBookPage> createState() => _FamilyBookPageState();
}

class _FamilyBookPageState extends State<FamilyBookPage> {
  @override
  void initState() {
    super.initState();
    // The two reads that fire on mount — `:190` and `:200`.
    widget.cubit.load();
  }

  /// `goBack` — `:225-228`. The cubit owns the step, this owns navigation.
  void _goBack() {
    if (widget.cubit.goBack()) widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FamilyBookCubit, FamilyBookViewState>(
      bloc: widget.cubit,
      builder: (BuildContext context, FamilyBookViewState state) {
        // ── 1. Loading — `:277-292` ──────────────────────────────────────────
        if (state.showsLoading) {
          return FamilyBookFrame(
            onBack: _goBack,
            showStepIndicator: state.showsStepIndicator,
            step: state.step,
            children: const <Widget>[
              FamilyBookLoadingLine(),
              FamilyBookSkeletonCard(),
              FamilyBookSkeletonCard(),
              FamilyBookSkeletonCard(),
            ],
          );
        }

        // ── 2. Signed out — `:295-302` ───────────────────────────────────────
        if (state.showsSignedOut) {
          return FamilyBookFrame(
            onBack: _goBack,
            showStepIndicator: state.showsStepIndicator,
            step: state.step,
            children: const <Widget>[FamilyBookSignedOutCard()],
          );
        }

        // ── 3. Error — `:305-323`. A 404 never reaches here. ─────────────────
        if (state.showsError) {
          return FamilyBookFrame(
            onBack: _goBack,
            showStepIndicator: state.showsStepIndicator,
            step: state.step,
            children: <Widget>[
              FamilyBookErrorCard(
                // `{error.message}` — `:311`, the backend's own sentence.
                message: state.failure?.message ?? '',
                onRetry: widget.cubit.refetch,
              ),
            ],
          );
        }

        // ── 4. Empty — `:326-336`. Slot 47's render. ─────────────────────────
        if (state.showsEmpty) {
          return FamilyBookFrame(
            onBack: _goBack,
            showStepIndicator: state.showsStepIndicator,
            step: state.step,
            children: const <Widget>[FamilyBookEmptyCard()],
          );
        }

        // `book` is non-null from here: `:326` already returned on null, which
        // is what lets `:358` fall back to `household_no`.
        final FamilyBook book = state.book!;

        // ── 5. Success — `:339-389`. NOT the frame. ──────────────────────────
        if (state.showsSuccess) {
          return FamilyBookSuccess(
            book: book,
            submitted: state.submitted!,
            onBack: widget.onBack,
          );
        }

        // ── 6-8. The household — `:392-595` ──────────────────────────────────
        return FamilyBookFrame(
          onBack: _goBack,
          showStepIndicator: state.showsStepIndicator,
          step: state.step,
          cta: FamilyBookCta(
            pending: state.submitPending,
            isLastStep: state.isLastStep,
            // `say()` reads `lang` at submit time (§ 6.5 T0-2), so the locale
            // is read here, at the tap, and not captured when the page opened.
            onTap: () => widget.cubit.requestCopy(_langOf(context)),
          ),
          children: <Widget>[
            FamilyBookStepHeader(step: state.step),
            ...switch (state.step) {
              1 => familyBookStep1(context, book),
              2 => familyBookStep2(context, book),
              _ => familyBookStep3(
                  context,
                  book,
                  copyFee: state.copyFee,
                  submitFailure: state.submitFailure?.message,
                ),
            },
          ],
        );
      },
    );
  }
}

/// `useLang().lang` — `:184`.
Lang _langOf(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'lo' ? Lang.lo : Lang.en;

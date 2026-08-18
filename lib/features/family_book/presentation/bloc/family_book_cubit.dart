/// `FamilyBookPage.tsx`'s state — its two `useState`s, its `useQuery`, its
/// `useMutation` and its service-catalogue read, in one place.
///
/// ## A Cubit, and its state holds no captured-values map
///
/// `ssd.md` § 7.4 rules *"one BLoC per certificate page, holding the payload
/// map, the wizard step index, and server-side field errors."* Its three stated
/// grounds, measured against this page:
///
/// | § 7.4's ground | FamilyBook | Source |
/// |---|---|---|
/// | B4 requires draft I/O — create, patch, attachment upload | **false** — none of the three | `fsd.md`:820 |
/// | The Tier 0 gate needs the payload tree to be an inspectable object | **false** — the whole body is one key | `specs.md` § 6.5 |
/// | Consistency with the only two BLoCs that exist | **holds** | — |
///
/// Only the third survives, and it carries the *shape* — one Cubit per page,
/// built by DI, handed to the widget — not the *content*. This page captures no
/// values, so a `Map<String, dynamic>` in its state would be a field with no
/// writer, and `F4-AC-15` greps for exactly that. There is likewise no
/// `ValidationScope`, no field-error map and no 422 routing: `fsd.md`:817
/// measures *"`canProceed` / validation: none"* — Next always advances.
///
/// A [Cubit] rather than a `Bloc` for `resident_form_cubit.dart`'s reason: the
/// source is two `useState` calls and two async operations, and each transition
/// below has exactly one caller. An event class per transition would be five
/// types carrying no information the method name does not.
///
/// ## The reason string is read at SUBMIT time, from the caller's locale
///
/// [requestCopy] takes a [Lang] instead of capturing one at construction, and
/// that is § 6.5's **T0-2** rather than a style preference: `say()` closes over
/// `lang` from `useLang()` (`:193`) and `handleNext` calls it at `:236`, so
/// flipping the language on the review step and *then* submitting sends the new
/// locale's bytes. A cubit built with a fixed `lang` would send the language
/// the page was opened in, and would pass every locale test that never flips.
///
/// The bytes come from `kFbCopyReason` — the transcription of record of the
/// component's own `COPY` table — and not from the JSON dictionary, because
/// `say("copyReason")` reads the module literal. `family_book_copy_test.dart`
/// asserts the two agree, so the choice costs no drift.
///
/// ## The fee is supplied as a function, and its absence is the seeded value
///
/// `useServiceConfig("family-book")` (`:190`) reads the live `/services`
/// catalogue once per tab and folds it over a seeded table; `config` is never
/// undefined, so a fee never renders blank. [readFee] is that read, handed in
/// as a function so this file names no other feature's use case — the same
/// seam the resident wizard's catalogue read uses. A null [readFee], or a
/// failed read, leaves [kFamilyBookSeedFeeLak] standing, which is what
/// `getServiceConfig` answers before the catalogue lands.
library;

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../i18n/i18n.dart';
import '../../../application/domain/entities/application_row.dart';
import '../../domain/entities/family_book.dart';
import '../../domain/family_book_copy.dart';
import '../../domain/usecases/family_book_usecases.dart';
import 'family_book_state.dart';

/// The `family-book` row's `fee_lak`, as a function this page can be handed.
///
/// Answers `null` when the catalogue could not be read at all — which leaves
/// the seed standing rather than rendering `—`, because
/// `getServiceConfig` falls back to the seeded table and never to "no fee
/// configured" for a code it knows (`serviceConfig.ts:108-120`).
typedef FamilyBookFeeReader = Future<int?> Function();

class FamilyBookCubit extends Cubit<FamilyBookViewState> {
  FamilyBookCubit({
    required this.getFamilyBook,
    required this.requestFamilyBookCopy,
    required bool authenticated,
    this.readFee,
  }) : super(FamilyBookViewState.initial(authenticated: authenticated));

  final GetFamilyBook getFamilyBook;
  final RequestFamilyBookCopy requestFamilyBookCopy;

  /// Null in tests that do not care about the review step's fee line, and null
  /// in any build where the catalogue is unavailable. Both leave the seed.
  final FamilyBookFeeReader? readFee;

  /// The two `useQuery`/`useServiceConfig` reads that fire on mount
  /// (`:190`, `:200`).
  ///
  /// **The household read is issued only when authenticated.** `:201`'s
  /// `enabled: isAuthenticated` is not a UI condition — `hooks.ts:42`,`:59-62`
  /// skip the fetch entirely — so a signed-out mount makes **zero** requests
  /// (`F4-AC-20`). The fee read is not gated: `/services` is anonymous and the
  /// web issues it either way.
  Future<void> load() async {
    unawaited(_loadFee());
    if (!state.authenticated) return;
    await _read();
  }

  /// `refetch()` — `:314`, `hooks.ts:92`.
  ///
  /// A nonce bump. Because an error implies `data === undefined`, `hasData` is
  /// false and the re-entry is **`loading`, not `refreshing`**
  /// (`hooks.ts:67-68`): the citizen sees the skeleton again, not a spinner
  /// over stale content. Clearing [FamilyBookViewState.book] here is what
  /// reproduces that; keeping it would be the `refreshing` branch, which this
  /// page can never be in (`F4-AC-38`).
  Future<void> refetch() async {
    if (!state.authenticated) return;
    _emit(state.copyWith(loading: true, clearBook: true, clearFailure: true));
    await _read();
  }

  Future<void> _read() async {
    _emit(state.copyWith(loading: true, clearFailure: true));
    final Either<Failure, FamilyBook> result = await getFamilyBook(NoParams());
    result.fold(
      (Failure f) => _emit(
        state.copyWith(loading: false, failure: f, clearBook: true),
      ),
      (FamilyBook book) => _emit(
        state.copyWith(loading: false, book: book, clearFailure: true),
      ),
    );
  }

  Future<void> _loadFee() async {
    final FamilyBookFeeReader? reader = readFee;
    if (reader == null) return;
    final int? fee = await reader();
    if (fee == null) return;
    _emit(state.copyWith(copyFee: fee));
  }

  /// `goBack` — `:225-228`.
  ///
  /// ```tsx
  /// const goBack = () => {
  ///   if (step > 1) setStep((s) => s - 1);
  ///   else onBack();
  /// };
  /// ```
  ///
  /// Returns **true when the caller's own back should fire**, so the widget
  /// owns navigation and this file owns the step. It is wired to the header
  /// chevron in *every* frame state, including the four where [step] is pinned
  /// at 1 — in those, it always answers true.
  bool goBack() {
    if (state.step > 1) {
      _emit(state.copyWith(step: state.step - 1));
      return false;
    }
    return true;
  }

  /// `handleNext` — `:230-241`.
  ///
  /// ```tsx
  /// if (step < lastStep) { setStep((s) => s + 1); return; }
  /// try { setSubmitted(await requestCopy.run(say("copyReason"))); }
  /// catch { /* rendered from requestCopy.error on the review step */ }
  /// ```
  ///
  /// **The catch block is empty by design.** A failed request does not
  /// navigate, does not raise a toast or a dialog, and does not reset the step:
  /// the citizen stays on step 3 and the failure renders inline above the
  /// review card (`:514-519`, `F4-AC-39`). Adding any of the three would be an
  /// L-10 degrade-better.
  Future<void> requestCopy(Lang lang) async {
    if (!state.isLastStep) {
      _emit(state.copyWith(step: state.step + 1));
      return;
    }
    if (state.submitPending) return;

    _emit(state.copyWith(submitPending: true, clearSubmitFailure: true));

    final Either<Failure, ApplicationRow> result =
        await requestFamilyBookCopy(RequestCopyParams(reason: reasonFor(lang)));

    result.fold(
      (Failure f) =>
          _emit(state.copyWith(submitPending: false, submitFailure: f)),
      (ApplicationRow row) => _emit(
        state.copyWith(submitPending: false, submitted: row),
      ),
    );
  }

  /// `say("copyReason")` — `:193`, `:236`. The whole request body's one value.
  ///
  /// `COPY[key][lang] ?? COPY[key].en`, and the `en` fallback is unreachable
  /// here because both sides are non-nullable literals — reproduced anyway so
  /// the expression reads against the source.
  static String reasonFor(Lang lang) =>
      lang == Lang.lo ? kFbCopyReason.lo : kFbCopyReason.en;

  /// Every `emit` goes through here.
  ///
  /// A read that lands **after the page is gone** is discarded without a state
  /// write (`F4-AC-26`) — the Dart analogue of `hooks.ts:64-88`, where the
  /// `AbortController` fires on unmount and the late resolution is ignored.
  /// `Cubit.emit` throws on a closed cubit, so without this guard a citizen
  /// leaving the page mid-request would surface a framework error rather than
  /// nothing at all: an added failure mode, which is L-10's first clause.
  void _emit(FamilyBookViewState next) {
    if (isClosed) return;
    emit(next);
  }
}

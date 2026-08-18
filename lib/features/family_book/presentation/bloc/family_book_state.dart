/// `FamilyBookPage.tsx`'s render state — the eight branches of `specs.md` § 6.3
/// as one value, plus the four predicates that select between them.
///
/// ## Eight states, not four, and the ORDER is load-bearing
///
/// `ssd.md` § 7.3 mandates four (loading · data · empty · error-with-retry).
/// This page has eight and evaluates them **top to bottom with early returns**
/// (`:277`, `:295`, `:305`, `:326`, `:339`, then the wizard). Re-ordering them
/// changes what renders, so the predicates below are written as a cascade in
/// the source's own order rather than as an enum the page switches on: an enum
/// invites a `switch` whose cases can be reordered without anything failing.
///
/// | # | State | Guard | Chrome | CTA | Step indicator |
/// |---|---|---|---|---|---|
/// | 1 | Loading | `:277` | frame | no | no |
/// | 2 | Signed out | `:295` | frame | no | no |
/// | 3 | Error | `:305` | frame | no (the retry is *inside* the card) | no |
/// | 4 | Empty | `:326` | frame | no | no |
/// | 5 | Success | `:339` | **its own centred layout, NOT frame** | its own | no |
/// | 6 | Step 1 | `:397` | frame | yes | yes |
/// | 7 | Step 2 | `:438` | frame | yes | yes |
/// | 8 | Step 3 | `:505` | frame | yes | yes |
///
/// Three of those rows are the ones a port gets wrong by default:
///
/// * **A 404 is not an error.** `:305`'s `&& !error.isNotFound` sends it to the
///   empty state. [showsError] therefore excludes `NotFoundFailure`.
/// * **Success is checked AFTER `!book`**, so a success render always has a
///   book behind it — which is why `:358` can fall back to `household_no`.
/// * **[loading] initialises to `enabled`, not to `true`.** `hooks.ts:46` is
///   `useState(enabled)` and `enabled` is `isAuthenticated` (`:201`). A port
///   that started at `true` would show a skeleton to a signed-out citizen for
///   one frame, which the web never does (`F4-AC-35`).
library;

import '../../../../core/error/failure.dart';
import '../../../application/domain/application_failures.dart';
import '../../../application/domain/entities/application_row.dart';
import '../../domain/entities/family_book.dart';

/// `STEPS.length` — `FamilyBookPage.tsx:69-73`. Three steps, ids `1..3`.
const int kFamilyBookStepCount = 3;

/// `serviceConfig.ts:115` — the seeded `family-book` fee, `0`.
///
/// **Not a hardcoded "Free".** `useServiceConfig` folds the live `/services`
/// catalogue over a seeded table and `getServiceConfig` answers the seed until
/// the catalogue lands, so the seed is a real part of the source's mechanism
/// rather than a placeholder for one (`serviceConfig.ts:258-290`). The source
/// comment at `:531-533` records that a literal `"Free"` here was a defect,
/// and this is the thing that is not that: the value is replaced the moment the
/// catalogue answers, and the catalogue is what decides.
const int kFamilyBookSeedFeeLak = 0;

class FamilyBookViewState {
  const FamilyBookViewState({
    required this.authenticated,
    required this.loading,
    this.book,
    this.failure,
    this.step = 1,
    this.submitted,
    this.submitPending = false,
    this.submitFailure,
    this.copyFee = kFamilyBookSeedFeeLak,
  });

  /// The state a fresh mount is in — `useQuery`'s own initialisation.
  ///
  /// `loading: enabled`, and `enabled` is `isAuthenticated`. Written as a
  /// factory rather than as defaults on the constructor so the coupling between
  /// the two fields is expressed once and cannot be half-copied.
  factory FamilyBookViewState.initial({required bool authenticated}) =>
      FamilyBookViewState(
        authenticated: authenticated,
        loading: authenticated,
      );

  /// `useSession().isAuthenticated` — `:185`, `:201`, `:295`.
  final bool authenticated;

  /// `useQuery`'s `loading` — `hooks.ts:46`, `:198`.
  final bool loading;

  /// `useQuery`'s `data` — `:196`. Null until the read succeeds, and null
  /// again after a retry begins (`hooks.ts:67-68`).
  final FamilyBook? book;

  /// `useQuery`'s `error` — `:198`. A [NotFoundFailure] here is the *empty*
  /// state, not the error state.
  final Failure? failure;

  /// `useState(1)` — `:186`. Pinned at 1 in states 1-5.
  final int step;

  /// `useState<ApplicationRow | null>(null)` — `:187`.
  final ApplicationRow? submitted;

  /// `requestCopy.pending` — `:571`, the CTA's only disabled condition.
  final bool submitPending;

  /// `requestCopy.error` — `:514-519`, rendered **inline on step 3**. Not a
  /// toast, not a dialog, not a navigation.
  final Failure? submitFailure;

  /// `familyBookService.fee ?? 0` — `:191`.
  final int copyFee;

  // ── The cascade, in the source's evaluation order ──────────────────────────

  /// `:277` — `if (loading)`.
  bool get showsLoading => loading;

  /// `:295` — `if (!isAuthenticated)`, reached only when [showsLoading] is
  /// false.
  bool get showsSignedOut => !showsLoading && !authenticated;

  /// `:305` — `if (error && !error.isNotFound)`.
  ///
  /// The `!isNotFound` half is the whole reason slot 47 has a reference: on
  /// every account this programme has, `GET /me/family-book` answers 404 and
  /// this predicate is **false**, so the render falls through to
  /// [showsEmpty].
  bool get showsError =>
      !showsLoading &&
      !showsSignedOut &&
      failure != null &&
      failure is! NotFoundFailure;

  /// `:326` — `if (!book)`.
  bool get showsEmpty =>
      !showsLoading && !showsSignedOut && !showsError && book == null;

  /// `:339` — `if (submitted)`, checked **after** `!book`.
  bool get showsSuccess =>
      !showsLoading &&
      !showsSignedOut &&
      !showsError &&
      !showsEmpty &&
      submitted != null;

  /// `:392` — the household, i.e. one of steps 1-3.
  bool get showsHousehold =>
      !showsLoading &&
      !showsSignedOut &&
      !showsError &&
      !showsEmpty &&
      !showsSuccess;

  /// `{book && <StepIndicator …>}` — `:262`. Not "steps 1-3": the guard is on
  /// `book`, and `book` is also non-null behind the success render, where the
  /// frame is not used at all.
  bool get showsStepIndicator => book != null;

  /// `step === lastStep` — `:583`.
  bool get isLastStep => step >= kFamilyBookStepCount;

  FamilyBookViewState copyWith({
    bool? authenticated,
    bool? loading,
    FamilyBook? book,
    bool clearBook = false,
    Failure? failure,
    bool clearFailure = false,
    int? step,
    ApplicationRow? submitted,
    bool? submitPending,
    Failure? submitFailure,
    bool clearSubmitFailure = false,
    int? copyFee,
  }) =>
      FamilyBookViewState(
        authenticated: authenticated ?? this.authenticated,
        loading: loading ?? this.loading,
        book: clearBook ? null : (book ?? this.book),
        failure: clearFailure ? null : (failure ?? this.failure),
        step: step ?? this.step,
        submitted: submitted ?? this.submitted,
        submitPending: submitPending ?? this.submitPending,
        submitFailure:
            clearSubmitFailure ? null : (submitFailure ?? this.submitFailure),
        copyFee: copyFee ?? this.copyFee,
      );
}

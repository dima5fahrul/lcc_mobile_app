/// The family-book feature's repository contract — **two operations, and there
/// is no third** (`F4-AC-21`).
///
/// | Source | Method | Endpoint | Auth |
/// |---|---|---|---|
/// | `FamilyBookPage.tsx:200` | [getFamilyBook] | `GET /me/family-book` | Bearer |
/// | `FamilyBookPage.tsx:204` | [requestFamilyBookCopy] | `POST /me/family-book/request-copy` | Bearer |
///
/// ## Why the count is a criterion and not a tidiness note
///
/// Five sibling batches port a wizard that captures values, builds a payload
/// tree and drives a four-call write sequence. FamilyBook does none of it:
/// `fsd.md`:820 measures zero `/applications` calls, zero uploads, zero
/// validation and no draft. The reflex from those five is to give this
/// repository the same surface — and every one of those extra methods would be
/// a wire call the shipped web app never makes.
///
/// So the interface is closed at two, and the criterion greps for the absent
/// verbs rather than trusting the reading.
///
/// ## The 404 is not an error, and that lands here
///
/// `FamilyBookPage.tsx:305` is `if (error && !error.isNotFound)`. A 404 falls
/// **past** the error branch into the empty state at `:326` — it is the answer
/// *"you are not on a household"*, which is the only branch the fidelity
/// baseline exercises at all (`specs.md` § 2.2 Finding B) and the reason slot
/// 47 exists.
///
/// [getFamilyBook] therefore answers `NotFoundFailure` for a 404 and a plain
/// `Failure` for everything else, reusing the application feature's type rather
/// than declaring a second one: `application_failures.dart` exists precisely
/// because `HistoryDetailPage` needed the same one-bit distinction, and two
/// not-found types in one tree is two things a `case` can miss.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../application/domain/entities/application_row.dart';
import '../entities/family_book.dart';

abstract class FamilyBookRepository {
  /// `GET /me/family-book` — Bearer (`endpoints.ts:128`).
  ///
  /// A **404 folds to `NotFoundFailure`**; every other failure keeps the API's
  /// own sentence, because `:311` renders `error.message` verbatim under the
  /// fixed error title and a Dart type dump on a citizen's screen is not what
  /// the source does.
  ///
  /// **Only called when authenticated.** `:201`'s `enabled: isAuthenticated`
  /// means a signed-out mount issues no request at all (`F4-AC-20`); that gate
  /// lives in the caller, not here, because it is a render-state question.
  Future<Either<Failure, FamilyBook>> getFamilyBook();

  /// `POST /me/family-book/request-copy` — Bearer (`endpoints.ts:128-129`).
  ///
  /// The body is `{"reason": "<reason>"}` and **that is the entire body**: one
  /// key, no envelope, no nulls (`F4-AC-22`). [reason] is the locale's
  /// `familyBookPage.copyReason` bytes, resolved by the caller at submit time.
  ///
  /// Answers the created case as the shared `ApplicationRow`. F4 declares no
  /// competing application entity (`F4-AC-23`) — the success card reads
  /// `reference_no` and `status_label` off it (`:358`, `:362`), which are two
  /// of that entity's own fields.
  Future<Either<Failure, ApplicationRow>> requestFamilyBookCopy(String reason);
}

/// The FR-11 record-picker's interface — `ssd.md` § 11.4's sub-flow, F3's.
///
/// ## Why this is a SECOND repository and not two more methods on
/// [ReferenceRepository]
///
/// `ReferenceRepository`'s single `options()` exists to make L-1 true: a widget
/// asks for a `LookupKey` and never learns which host answered, because the two
/// endpoint families behind it are interchangeable *lists of options*. A
/// prerequisite record is not an option — it is a record with eleven fields, a
/// party pair, a free-form payload and a `record_no` that becomes
/// `linked_reference_no` on the wire. Folding it into `LookupKey` would mean
/// either widening `LookupOption` to carry fields no select reads, or adding a
/// second return type to a method whose whole purpose is that it has one.
///
/// `ssd.md` § 11.4 already separates it — *"a different endpoint, a different
/// interaction and a different owner"* — and `api_endpoint.dart` records the
/// same split.
///
/// ## No in-flight de-duplication here, deliberately
///
/// `ReferenceRepositoryImpl` shares futures because Birth fires 19 identical
/// reference reads (R-22) and eliminating them is invisible to the citizen.
/// This endpoint has **one caller per page**, debounced 300 ms
/// (`MarriageCertificatePage.tsx:752`), and its query changes with every
/// keystroke — there are no duplicates to eliminate, and a cache keyed on the
/// search string would make the retry affordance replay a stale answer.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/prerequisite_record.dart';

abstract class PrerequisiteRecordRepository {
  /// `catalog.prerequisiteRecords({kind, search, per_page: 20})`.
  ///
  /// [kind] is `"betrothal"` (Marriage) or `"mediation"` (Divorce). [query] is
  /// passed verbatim including empty.
  ///
  /// **Answers `data: []` on every account this programme has**
  /// (`manifest-authenticated.md`:230-232), so `Right(empty)` is the only
  /// outcome any real call has produced. That is a data-availability limit, not
  /// an implementation one, and it is why the picker's loaded state has no
  /// execution evidence.
  Future<Either<Failure, PrerequisiteRecordPage>> search({
    required String kind,
    required String query,
  });

  /// `catalog.prerequisiteRecord(recordNo)` — the single-record read the picker
  /// fires when a row is tapped.
  ///
  /// A `Left` here is rendered **beneath the picker** rather than replacing it
  /// (`MarriageCertificatePage.tsx:828-830`), so the citizen can try another
  /// row. The page's `selectExisting` swallows the throw for exactly that.
  Future<Either<Failure, PrerequisiteRecord>> byRecordNo(String recordNo);
}

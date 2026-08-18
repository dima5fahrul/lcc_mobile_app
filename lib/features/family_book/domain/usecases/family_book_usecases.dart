/// The family-book feature's two use cases — its whole data surface.
///
/// One file, for the reason `application_usecases.dart` and `news_usecases.dart`
/// give: the *set* is the feature's entire wire vocabulary, and two files of
/// four lines each would hide that there are only two.
///
/// They stay separate types so DI registers two lazy singletons (DI-2) and the
/// cubit's constructor names exactly what it depends on — which is what makes
/// `F4-AC-20`'s "issued **only** when authenticated" assertable against a cubit
/// built from doubles, with no container in the test at all.
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../application/domain/entities/application_row.dart';
import '../entities/family_book.dart';
import '../repositories/family_book_repository.dart';

/// `me.familyBook(signal)` — `FamilyBookPage.tsx:200`, `endpoints.ts:128`.
class GetFamilyBook implements UseCase<FamilyBook, NoParams> {
  const GetFamilyBook({required this.repository});

  final FamilyBookRepository repository;

  @override
  Future<Either<Failure, FamilyBook>> call(NoParams params) =>
      repository.getFamilyBook();
}

/// The single argument of the single write: the reason string, already resolved
/// to the citizen's current locale.
///
/// A parameter object rather than a bare `String` so the call site reads
/// `RequestCopyParams(reason: …)` and cannot be handed the wrong string by
/// position — this is the value that becomes the entire request body, and it is
/// the one leaf Tier 0 compares byte-for-byte.
class RequestCopyParams extends Equatable {
  const RequestCopyParams({required this.reason});

  /// `say("copyReason")` — `FamilyBookPage.tsx:236`. Resolved at **submit**
  /// time from the locale in force then, not captured at mount (§ 6.5 T0-2).
  final String reason;

  @override
  List<Object?> get props => <Object?>[reason];
}

/// `me.requestFamilyBookCopy({ reason })` — `FamilyBookPage.tsx:204`,
/// `endpoints.ts:128-129`.
///
/// Answers the created case as `ApplicationRow`; the success card reads two of
/// its fields and nothing else.
class RequestFamilyBookCopy
    implements UseCase<ApplicationRow, RequestCopyParams> {
  const RequestFamilyBookCopy({required this.repository});

  final FamilyBookRepository repository;

  @override
  Future<Either<Failure, ApplicationRow>> call(RequestCopyParams params) =>
      repository.requestFamilyBookCopy(params.reason);
}

/// `FamilyBookRepositoryImpl` — try the datasource, fold every throw into a
/// [Failure], and keep **one** distinction: 404.
///
/// ## Why the 404 branch is here and not a general rule
///
/// `application_repository_impl.dart` has two folds — one that flattens every
/// status (`_guard`) and one that distinguishes not-found (`_guardDetail`) —
/// and its header explains the split: the list has one error panel whatever the
/// status, the detail renders different copy for a missing case.
///
/// FamilyBook is the detail's shape and more so. `FamilyBookPage.tsx:305`:
///
/// ```tsx
/// if (error && !error.isNotFound) { …the error card… }
/// if (!book)                      { …"No household on file"… }
/// ```
///
/// A 404 is not a fault on this page — it is the **answer**, and it is the only
/// branch the fidelity baseline has a reference for (slot 47). Flattening it
/// would put *"We could not load your family book"* in front of every citizen
/// who is simply not on a household yet, which is the whole population of the
/// staging environment today.
///
/// ## The message is `e.message`, not `e.toString()`
///
/// `:311` renders `error.message` — the backend's own sentence — under the
/// fixed title. `ApiException.toString()` is `ApiException(500, INTERNAL_ERROR,
/// …)`, a Dart type dump; putting that on a citizen's screen is not what the
/// source does. Same reading `_guardDetail` took, and `F4-AC-25` asserts the
/// rendered message is the failure's own rather than a hardcoded sentence.
///
/// This is a **deliberate divergence from the standing Flutter-side
/// disposition** that `application_repository_impl.dart:11-17` records — that
/// every page in this tree renders fixed bilingual copy rather than the API's
/// sentence. It is taken here because this page's error card has *two* text
/// slots, a fixed title and a variable line, and the Tier 1 oracle declares the
/// second `role: "server-text"` precisely so the port can carry it without
/// pretending to know its value.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_exception.dart';
import '../../../application/domain/application_failures.dart';
import '../../../application/domain/entities/application_row.dart';
import '../../domain/entities/family_book.dart';
import '../../domain/repositories/family_book_repository.dart';
import '../datasources/family_book_remote_datasource.dart';

class FamilyBookRepositoryImpl implements FamilyBookRepository {
  const FamilyBookRepositoryImpl({required this.remote});

  final FamilyBookRemoteDatasource remote;

  /// One fold, both call sites — written once so a later reader cannot find
  /// one that distinguishes 404 and one that does not.
  ///
  /// The write inherits the 404 branch and that is harmless rather than
  /// sloppy: `POST …/request-copy` has no documented 404, and if it ever
  /// answered one the page would render it through the same inline failure line
  /// as any other (`:514-519`), which reads `.message` either way.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() read) async {
    try {
      return Right<Failure, T>(await read());
    } on ApiException catch (e) {
      return Left<Failure, T>(
        e.isNotFound ? NotFoundFailure(e.message) : Failure(e.message),
      );
    } catch (e) {
      // Not an `ApiException` — a parse or a programming error, which has no
      // citizen-facing sentence of its own. It lands in the generic branch,
      // never the not-found one, so it can never be mistaken for "you are not
      // on a household".
      return Left<Failure, T>(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FamilyBook>> getFamilyBook() =>
      _guard(remote.getFamilyBook);

  @override
  Future<Either<Failure, ApplicationRow>> requestFamilyBookCopy(
    String reason,
  ) =>
      _guard(() => remote.requestFamilyBookCopy(reason));
}

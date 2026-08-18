/// `AccountRepositoryImpl` — try the datasource, fold every throw into a
/// [Failure].
///
/// Follows `NotificationRepositoryImpl` and `HelpRepositoryImpl` exactly,
/// including their deviation from the session feature: **no `ApiException`
/// rethrow.** Every mode these three calls have — offline, 500, 401 after the
/// token expired, a malformed row — collapses to the same user-visible outcome,
/// which for documents is the error-with-retry branch
/// (`AccountPage.tsx:406-417`) and for preferences is the panel's inline error
/// (`:573-580`). Neither branches on a status code.
///
/// [Failure.message] carries the exception text, and unlike the notifications
/// menu **it is what the UI renders**: `docsQuery.error.message ||
/// c("docsError")` (`:409`) and `prefsQuery.error.message` (`:575`) — the API's
/// own message wins over the local string. See `documents_card.dart`.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/citizen_document.dart';
import '../../domain/entities/citizen_preferences.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_datasource.dart';

class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl({required this.remote});

  final AccountRemoteDatasource remote;

  /// ## The `ApiException` arm (added 2026-08-18, B8 MAJOR-1)
  ///
  /// Three of this repository's reads reach a citizen-visible error surface:
  /// the My Documents panel (`documents_card.dart:164-166`, `:173`) and the
  /// notifications panel on both its read and its write path
  /// (`preferences_panel.dart:70`, `:116`). All three render `Failure.message`
  /// directly.
  ///
  /// With one bare `catch`, an `ApiException` reached them as
  /// `ApiException.toString()` — status, code, the internal `requestId` and a
  /// field count. `ApiError extends Error` with `super(message)`
  /// (`client.ts:61-68`), so the source's equivalent is the backend's sentence
  /// alone. Folding `e.message` makes the Dart value equal the JS value those
  /// render sites were written against.
  ///
  /// The generic arm keeps `e.toString()`: a `DioException` or a parse error
  /// has no server-authored sentence to prefer, and its text is what a log
  /// needs. Same two-arm shape as
  /// `prerequisite_record_repository_impl.dart:38-42` and
  /// `service_repository_impl.dart:75-79`.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() read) async {
    try {
      return Right<Failure, T>(await read());
    } on ApiException catch (e) {
      return Left<Failure, T>(Failure(e.message));
    } catch (e) {
      return Left<Failure, T>(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CitizenPreferences>> getPreferences() =>
      _guard(remote.getPreferences);

  @override
  Future<Either<Failure, CitizenPreferences>> savePreferences(
    CitizenPreferences preferences,
  ) =>
      _guard(() => remote.savePreferences(preferences));

  @override
  Future<Either<Failure, List<CitizenDocument>>> getDocuments() =>
      _guard(remote.getDocuments);
}

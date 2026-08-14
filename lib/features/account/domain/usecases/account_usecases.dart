/// The account surface's three use cases.
///
/// One file, matching `notification_usecases.dart`'s shape rather than one file
/// per class — the split the session and auth features use predates that
/// convention and B9a is the more recent precedent.
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/citizen_document.dart';
import '../entities/citizen_preferences.dart';
import '../repositories/account_repository.dart';

/// `GET /me/preferences` — `AccountPage.tsx:191`.
class GetPreferences implements UseCase<CitizenPreferences, NoParams> {
  const GetPreferences({required this.repository});

  final AccountRepository repository;

  @override
  Future<Either<Failure, CitizenPreferences>> call(NoParams params) =>
      repository.getPreferences();
}

/// The **already-merged** preferences object.
///
/// Named `Params` rather than taking the entity bare so the use-case surface
/// keeps the project's convention, and so the doc has somewhere to say that the
/// merge has already happened.
class SavePreferencesParams extends Equatable {
  const SavePreferencesParams(this.preferences);

  final CitizenPreferences preferences;

  @override
  List<Object?> get props => <Object?>[preferences];
}

/// `PUT /me/preferences` — `AccountPage.tsx:258`.
class SavePreferences
    implements UseCase<CitizenPreferences, SavePreferencesParams> {
  const SavePreferences({required this.repository});

  final AccountRepository repository;

  @override
  Future<Either<Failure, CitizenPreferences>> call(
          SavePreferencesParams params) =>
      repository.savePreferences(params.preferences);
}

/// `GET /me/documents` — `AccountPage.tsx:190`.
class GetDocuments implements UseCase<List<CitizenDocument>, NoParams> {
  const GetDocuments({required this.repository});

  final AccountRepository repository;

  @override
  Future<Either<Failure, List<CitizenDocument>>> call(NoParams params) =>
      repository.getDocuments();
}

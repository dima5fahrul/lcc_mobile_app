/// The account surface's four use cases — three from B8a, [UploadAvatar] from
/// B8b.
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
import '../entities/picked_avatar.dart';
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

/// The photograph the citizen picked, on its way to `POST /me/avatar`.
///
/// A `Params` wrapper for the same reason [SavePreferencesParams] is one: it
/// keeps the use-case surface uniform, and it gives the file a place to be
/// documented on its way through. **Nothing between the picker and
/// `MultipartFile.fromBytes` inspects, resizes or re-encodes it.**
class UploadAvatarParams extends Equatable {
  const UploadAvatarParams(this.file);

  final PickedAvatar file;

  /// Identity on the *file object*, not on its bytes.
  ///
  /// Deliberate: two picks of the same photograph must be two distinct
  /// uploads, not one deduplicated by an `Equatable` that compared byte
  /// content. That is `B8-AC-54` — the analogue of `e.target.value = ""` at
  /// `AccountPage.tsx:236`, which runs **before** the early return precisely so
  /// that re-picking the same file fires again. A value-equality `props` here
  /// would be a silent memoisation the web does not have.
  @override
  List<Object?> get props => <Object?>[identityHashCode(file)];
}

/// `POST /me/avatar` — `AccountPage.tsx:232`, `endpoints.ts:107-111`. B8b.
///
/// A pass-through. The whole of the upload's behaviour is in
/// `AccountRemoteDatasourceImpl.uploadAvatar`, whose doc carries the
/// send-raw ruling and its authority.
class UploadAvatar implements UseCase<String, UploadAvatarParams> {
  const UploadAvatar({required this.repository});

  final AccountRepository repository;

  @override
  Future<Either<Failure, String>> call(UploadAvatarParams params) =>
      repository.uploadAvatar(params.file);
}

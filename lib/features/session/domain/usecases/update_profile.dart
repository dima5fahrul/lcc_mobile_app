/// `UpdateProfile` usecase — `PATCH /me/profile`.
///
/// Thin wrapper over [SessionRepository.updateProfile], matching [GetProfile]'s
/// shape. Two consumers, both landed by B8a:
///
/// | Caller | Source | Body |
/// |---|---|---|
/// | `AccountProfileBloc` | `AccountPage.tsx:222` | the dirty-field diff |
/// | `SessionBloc` (R-25) | `LanguageToggle.tsx:71` | `{preferred_lang}` alone |
///
/// The second is why this is a use case and not a repository call from the
/// BLoC: `core/session/bloc/**` → `features/session/domain/**` is the single
/// whitelisted `core → features` edge (`ssd.md` § 4.5, G-L4), and it points at
/// `domain/`, not at `data/`.
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/citizen_profile.dart';
import '../entities/profile_update.dart';
import '../repositories/session_repository.dart';

/// Wraps the diff so the use case keeps the project's `Params` convention
/// (`ResetPasswordParams`, `MarkNotificationReadParams`).
class UpdateProfileParams extends Equatable {
  const UpdateProfileParams(this.update);

  final ProfileUpdate update;

  @override
  List<Object?> get props => <Object?>[update];
}

class UpdateProfile implements UseCase<CitizenProfile, UpdateProfileParams> {
  const UpdateProfile({required this.repository});

  final SessionRepository repository;

  @override
  Future<Either<Failure, CitizenProfile>> call(UpdateProfileParams params) =>
      repository.updateProfile(params.update);
}

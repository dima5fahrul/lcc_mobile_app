/// `ChangePassword` usecase — `POST /auth/change-password` (B8a).
///
/// Thin wrapper over [AuthRepository.changePassword], matching
/// [ResetPassword]'s shape.
///
/// ## The two client-side rules live in the BLoC, not here
///
/// `handleChangePassword` (`AccountPage.tsx:273-286`) checks
/// `pw.next.length < 8` **then** `pw.next !== pw.confirm`, in that order, and
/// returns before calling the endpoint if either fails. Those are form
/// validations with i18n-keyed messages, so they belong to the surface that
/// renders them (`AccountProfileBloc`), not to a use case that has no way to
/// name a message. Keeping them out of here also keeps `confirm` from ever
/// reaching a layer that could serialise it (B8-AC-34).
///
/// **The whole client-side policy is those two rules** — whether the server
/// enforces anything stronger is NOT EVALUATED and unmeasurable without an
/// authenticated write (specs.md § 6.8 item 1, GG-4).
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// The two fields that go on the wire. **`confirm` is deliberately not here** —
/// it is never transmitted (`AccountPage.tsx:280`), so it has no place in a
/// type that exists to describe the request.
class ChangePasswordParams extends Equatable {
  const ChangePasswordParams({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  /// **Both fields are omitted from [props]' string form by never overriding
  /// `toString`** — `Equatable`'s default `toString` is the runtime type only
  /// unless `stringify` is set, and it is not set here. That keeps a logged or
  /// asserted `ChangePasswordParams` from printing either password (B8-AC-45).
  @override
  List<Object?> get props => <Object?>[currentPassword, newPassword];
}

class ChangePassword implements UseCase<Unit, ChangePasswordParams> {
  const ChangePassword({required this.repository});

  final AuthRepository repository;

  @override
  Future<Either<Failure, Unit>> call(ChangePasswordParams params) =>
      repository.changePassword(
        currentPassword: params.currentPassword,
        newPassword: params.newPassword,
      );
}

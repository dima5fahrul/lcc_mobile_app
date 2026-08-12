/// `GetProfile` usecase — thin wrapper over [SessionRepository.getProfile].
///
/// Follows the flutter-boilerplate `GetPopularMovies` pattern: a const
/// constructor that takes the repository, a single `call(NoParams)` method
/// that delegates straight to the repo. Keeps the BLoC depending on a usecase
/// rather than the repository directly, so a future cross-cutting concern
/// (logging, metrics) has a single place to hook in.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/citizen_profile.dart';
import '../repositories/session_repository.dart';

class GetProfile implements UseCase<CitizenProfile, NoParams> {
  final SessionRepository repository;

  const GetProfile({required this.repository});

  @override
  Future<Either<Failure, CitizenProfile>> call(NoParams params) =>
      repository.getProfile();
}

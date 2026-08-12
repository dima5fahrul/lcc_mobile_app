/// Session usecase DI.
///
/// Registers [GetProfile] against the repository. Future session usecases
/// (e.g. `Logout`, `RefreshTokens`) will hang off this same container.
library;

import '../domain/repositories/session_repository.dart';
import '../domain/usecases/get_profile.dart';
import 'session_injection.dart';

class SessionUsecaseInjection {
  static void inject() {
    sessionInjection.registerLazySingleton<GetProfile>(
      () => GetProfile(repository: sessionInjection<SessionRepository>()),
    );
  }
}

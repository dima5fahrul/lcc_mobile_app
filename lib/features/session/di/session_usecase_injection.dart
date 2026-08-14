/// Session usecase DI.
///
/// Registers [GetProfile] against the repository. Future session usecases
/// (e.g. `Logout`, `RefreshTokens`) will hang off this same container.
library;

import '../domain/repositories/session_repository.dart';
import '../domain/usecases/get_profile.dart';
import '../domain/usecases/update_profile.dart';
import 'session_injection.dart';

class SessionUsecaseInjection {
  static void inject() {
    sessionInjection
      ..registerLazySingleton<GetProfile>(
        () => GetProfile(repository: sessionInjection<SessionRepository>()),
      )
      // B8a. Resolved out of this container by two places: `SessionBloc`'s
      // R-25 handler (via `dependency_injection.dart`, step 4) and
      // `AccountFeatureInjection`, which re-exports it into `accountInjection`
      // rather than reaching across containers at every call site.
      ..registerLazySingleton<UpdateProfile>(
        () => UpdateProfile(repository: sessionInjection<SessionRepository>()),
      );
  }
}

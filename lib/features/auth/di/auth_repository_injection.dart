/// Auth repository DI.
///
/// Registers the abstract [AuthRepository] against its impl, pulling the
/// datasource from [authInjection]. Mirrors the session feature's
/// `session_repository_injection.dart`.
library;

import '../data/datasources/auth_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import 'auth_injection.dart';

class AuthRepositoryInjection {
  static void inject() {
    authInjection.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remote: authInjection<AuthRemoteDatasource>(),
      ),
    );
  }
}

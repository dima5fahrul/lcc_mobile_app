/// Session repository DI.
///
/// Registers the abstract [SessionRepository] against its impl, pulling the
/// datasource from [sessionInjection].
library;

import '../data/datasources/session_remote_datasource.dart';
import '../data/repositories/session_repository_impl.dart';
import '../domain/repositories/session_repository.dart';
import 'session_injection.dart';

class SessionRepositoryInjection {
  static void inject() {
    sessionInjection.registerLazySingleton<SessionRepository>(
      () => SessionRepositoryImpl(
        remote: sessionInjection<SessionRemoteDatasource>(),
      ),
    );
  }
}

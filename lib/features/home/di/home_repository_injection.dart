/// Home repository DI.
///
/// Registers the abstract [HomeRepository] against its impl, pulling the
/// datasource from [homeInjection].
library;

import '../data/datasources/home_remote_datasource.dart';
import '../data/repositories/home_repository_impl.dart';
import '../domain/repositories/home_repository.dart';
import 'home_injection.dart';

class HomeRepositoryInjection {
  static void inject() {
    homeInjection.registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(remote: homeInjection<HomeRemoteDatasource>()),
    );
  }
}

/// Service catalogue repository DI.
///
/// Registers the abstract [ServiceRepository] against its impl, pulling the
/// datasource from [serviceInjection].
library;

import '../data/datasources/service_remote_datasource.dart';
import '../data/repositories/service_repository_impl.dart';
import '../domain/repositories/service_repository.dart';
import 'service_injection.dart';

class ServiceRepositoryInjection {
  static void inject() {
    serviceInjection.registerLazySingleton<ServiceRepository>(
      () => ServiceRepositoryImpl(
        remote: serviceInjection<ServiceRemoteDatasource>(),
      ),
    );
  }
}

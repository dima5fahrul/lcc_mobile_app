/// Service catalogue usecase DI.
///
/// Two reads, two usecases, both lazy (DI-2).
library;

import '../domain/repositories/service_repository.dart';
import '../domain/usecases/get_service_categories.dart';
import '../domain/usecases/get_services.dart';
import 'service_injection.dart';

class ServiceUsecaseInjection {
  static void inject() {
    serviceInjection
      ..registerLazySingleton<GetServiceCategories>(
        () => GetServiceCategories(
          repository: serviceInjection<ServiceRepository>(),
        ),
      )
      ..registerLazySingleton<GetServices>(
        () => GetServices(repository: serviceInjection<ServiceRepository>()),
      );
  }
}

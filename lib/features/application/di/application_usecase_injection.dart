/// Application use-case DI — two lazy singletons (DI-2), one per use case.
///
/// Both are part of this feature's published surface (see
/// `application_injection.dart`). [ListApplications] in particular is what
/// B6b's Bills Due card will resolve; its parameter object
/// (`ListApplicationsParams`) is therefore a cross-batch contract, not an
/// internal shape B7 may change freely.
library;

import '../domain/repositories/application_repository.dart';
import '../domain/usecases/application_usecases.dart';
import 'application_injection.dart';

class ApplicationUsecaseInjection {
  static void inject() {
    applicationInjection
      ..registerLazySingleton<ListApplications>(
        () => ListApplications(
          repository: applicationInjection<ApplicationRepository>(),
        ),
      )
      ..registerLazySingleton<GetStatusPipeline>(
        () => GetStatusPipeline(
          repository: applicationInjection<ApplicationRepository>(),
        ),
      );
  }
}

/// Home usecase DI — six reads, six usecases, all lazy (DI-2).
///
/// Every `HomeRepository` resolution happens **inside** the closure, not once
/// above them. Hoisting it would look like a harmless de-duplication and would
/// silently break DI-2: resolving the repository at registration time
/// constructs the datasource, which resolves the root `ApiClient`, which builds
/// the `Dio` — turning `HomeFeatureInjection.init()` from six map writes into
/// real work at app boot, before anything has asked for it.
library;

import '../domain/repositories/home_repository.dart';
import '../domain/usecases/home_usecases.dart';
import 'home_injection.dart';

class HomeUsecaseInjection {
  static void inject() {
    homeInjection
      ..registerLazySingleton<GetHomeSummary>(
        () => GetHomeSummary(repository: homeInjection<HomeRepository>()),
      )
      ..registerLazySingleton<GetDigitalId>(
        () => GetDigitalId(repository: homeInjection<HomeRepository>()),
      )
      ..registerLazySingleton<GetPhase1Services>(
        () => GetPhase1Services(repository: homeInjection<HomeRepository>()),
      )
      ..registerLazySingleton<SearchServices>(
        () => SearchServices(repository: homeInjection<HomeRepository>()),
      )
      ..registerLazySingleton<GetFeaturedNews>(
        () => GetFeaturedNews(repository: homeInjection<HomeRepository>()),
      )
      ..registerLazySingleton<GetHomeFaqs>(
        () => GetHomeFaqs(repository: homeInjection<HomeRepository>()),
      );
  }
}

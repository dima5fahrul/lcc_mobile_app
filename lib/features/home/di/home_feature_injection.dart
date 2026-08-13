/// Home feature injection entry point.
///
/// Called from `DependencyInjection.init` after `ApiClient` is on the root
/// container — the datasource resolves it. Ordering inside: datasource →
/// repository → usecase → bloc, mirroring `ServiceFeatureInjection.init()`.
///
/// ## Where it sits in the root's order, and why that is not "anywhere"
///
/// Unlike the service catalogue — which is wholly anonymous and therefore
/// genuinely order-free after step 2 — Home makes **two authenticated reads**
/// (`/me/home-summary`, `/me/digital-id`). It still has no *registration*
/// dependency on the session feature: the token is attached by `AuthInterceptor`
/// inside the shared `Dio`, not by anything Home resolves. What it does have is
/// a *runtime* one — `HomeBloc` is told whether the citizen is signed in by the
/// route builder reading `SessionBloc`, so the session must be registered
/// before the first navigation, which step 4 guarantees. Registering Home last
/// keeps that true by construction.
///
/// ## Why `registerFactory` for the BLoC
///
/// Same reasoning as `ServiceBloc`, with a different subject. A `HomeBloc`
/// holds one visit's UI state — the search text, a live debounce `Timer`, the
/// open FAQ index, whether the action banner was dismissed — and it holds the
/// citizen's **summary and digital-ID data**. A lazy singleton would hand the
/// next visit the previous visit's search results and a `Timer` scheduled
/// against a closed emitter; worse, on this page it would keep one citizen's
/// UIN and wallet balance in memory across a sign-out, since the container
/// outlives the session. The route builder pairs this with
/// `BlocProvider(create:)`, so one creator, one closer, one lifetime per visit
/// to `/`.
library;

import '../domain/usecases/home_usecases.dart';
import '../presentation/bloc/home_bloc.dart';
import 'home_datasource_injection.dart';
import 'home_injection.dart';
import 'home_repository_injection.dart';
import 'home_usecase_injection.dart';

class HomeFeatureInjection {
  /// Register the home feature. Call once at boot, after the core singletons
  /// are ready.
  static Future<void> init() async {
    HomeDatasourceInjection.inject();
    HomeRepositoryInjection.inject();
    HomeUsecaseInjection.inject();

    homeInjection.registerFactory<HomeBloc>(
      () => HomeBloc(
        getHomeSummary: homeInjection<GetHomeSummary>(),
        getDigitalId: homeInjection<GetDigitalId>(),
        getPhase1Services: homeInjection<GetPhase1Services>(),
        searchServices: homeInjection<SearchServices>(),
        getFeaturedNews: homeInjection<GetFeaturedNews>(),
        getHomeFaqs: homeInjection<GetHomeFaqs>(),
      ),
    );
  }
}

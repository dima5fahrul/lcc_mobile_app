/// Service feature injection entry point.
///
/// Called from `DependencyInjection.init` after `ApiClient` is on the root
/// container — the datasource resolves it. Nothing else constrains the
/// ordering: the catalogue is anonymous, so unlike the auth feature it has no
/// dependency on the session being registered first.
///
/// Ordering inside: datasource → repository → usecase → bloc, mirroring
/// `AuthFeatureInjection.init()`.
///
/// ## Why `registerFactory` for the BLoC
///
/// The same reasoning as `AuthBloc`, with a different subject. A
/// `ServiceBloc` holds one visit's UI state — the active category, the search
/// text, a live debounce `Timer` — none of which should survive leaving the
/// tab. A lazy singleton would hand the next visit the previous visit's search
/// results and, worse, a `Timer` scheduled against a closed emitter. The route
/// builder pairs this with `BlocProvider(create:)`, so one creator, one
/// closer, one lifetime per visit to `/service`.
library;

import '../domain/usecases/get_service_categories.dart';
import '../domain/usecases/get_services.dart';
import '../presentation/bloc/service_bloc.dart';
import 'service_datasource_injection.dart';
import 'service_injection.dart';
import 'service_repository_injection.dart';
import 'service_usecase_injection.dart';

class ServiceFeatureInjection {
  /// Register the service catalogue. Call once at boot, after the core
  /// singletons are ready.
  static Future<void> init() async {
    ServiceDatasourceInjection.inject();
    ServiceRepositoryInjection.inject();
    ServiceUsecaseInjection.inject();

    serviceInjection.registerFactory<ServiceBloc>(
      () => ServiceBloc(
        getServiceCategories: serviceInjection<GetServiceCategories>(),
        getServices: serviceInjection<GetServices>(),
      ),
    );
  }
}

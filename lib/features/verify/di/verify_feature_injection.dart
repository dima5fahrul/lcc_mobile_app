/// Verify feature injection entry point.
///
/// Ordering inside: datasource → repository → usecase → bloc, mirroring
/// `NotificationsFeatureInjection.init()`.
///
/// ## `registerFactory` and not a singleton
///
/// `VerifyBloc` holds one verification's answer — a certificate's checks, its
/// holder's masked name, its status. A surviving instance would hand both to
/// the next code anybody scans or types, which on this surface is very
/// possibly a *different citizen's* certificate (the endpoints are anonymous,
/// so there is no sign-out boundary that would clear it). Per-visit lifetime
/// it is: the `/verify` route builders own the provider
/// (`BlocProvider(create:)`), so the instance is created and closed with the
/// visit.
///
/// ## Wired into the root (Task 4)
///
/// Task 3 landed this container but did NOT wire it — the feature was
/// page-less. Task 4 adds [VerifyFeatureInjection.init] to
/// `DependencyInjection.init()` and builds the bloc/pages/routes on top.
library;

import '../domain/usecases/verify_usecases.dart';
import '../presentation/bloc/verify_bloc.dart';
import 'verify_datasource_injection.dart';
import 'verify_injection.dart';
import 'verify_repository_injection.dart';
import 'verify_usecase_injection.dart';

class VerifyFeatureInjection {
  static Future<void> init() async {
    VerifyDatasourceInjection.inject();
    VerifyRepositoryInjection.inject();
    VerifyUsecaseInjection.inject();

    verifyInjection.registerFactory<VerifyBloc>(
      () => VerifyBloc(
        verifyByCode: verifyInjection<VerifyByCode>(),
      ),
    );
  }
}

/// Application use-case DI — one lazy singleton (DI-2) per use case.
///
/// All of them are part of this feature's published surface (see
/// `application_injection.dart`). [ListApplications] in particular is what
/// B6b's Bills Due card will resolve; its parameter object
/// (`ListApplicationsParams`) is therefore a cross-batch contract, not an
/// internal shape B7 may change freely.
///
/// **B7b appended [GetApplication] and [GetApplicationTimeline]**, and this file
/// is a *stated deviation from specs.md § 3.1*. B7b's scope row grants
/// `features/application/domain/**` and `data/**` but omits `di/**`, which B7a's
/// row holds. The omission cannot be honoured as written: the two use cases
/// exist (B7a created the repository methods behind them), the detail BLoC
/// resolves them, and § 3.1's own B7b row says `lib/core/di/dependency_injection.dart`
/// is "not modified by B7b — B7a's two lines already cover it", which is only
/// coherent if the *feature* containers are where B7b registers. Recorded here
/// rather than absorbed silently, because a scope table is a licence as much as
/// a constraint (§ 10).
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
      )
      // ── The detail's two reads (B7b) ───────────────────────────────────────
      //
      // `HistoryDetailPage.tsx:142` and `:145` — two independent queries, which
      // is why they are two use cases and not one. Same container, same
      // repository instance as the list's, so the detail and the list cannot
      // disagree about what a `sla_days` is called.
      ..registerLazySingleton<GetApplication>(
        () => GetApplication(
          repository: applicationInjection<ApplicationRepository>(),
        ),
      )
      ..registerLazySingleton<GetApplicationTimeline>(
        () => GetApplicationTimeline(
          repository: applicationInjection<ApplicationRepository>(),
        ),
      )
      // ── The write half (F1) ────────────────────────────────────────────────
      //
      // Four more lazy singletons (DI-2), same container, same repository
      // instance. They are resolved out of `certificatesInjection` through a
      // closure — the `ChatUsecaseInjection` → `helpInjection` shape — which is
      // why they are registered here and not there: the wire work is
      // `features/application/`'s and `features/certificates/data/` does not
      // exist (`F1-AC-17`).
      //
      // Registering them lazily is what makes `F1-AC-14`'s second half
      // checkable: two resolutions of `ApplicationRepository` return the same
      // instance, so the four writes and the two reads share one datasource and
      // one `ApiClient`.
      ..registerLazySingleton<CreateApplication>(
        () => CreateApplication(
          repository: applicationInjection<ApplicationRepository>(),
        ),
      )
      ..registerLazySingleton<UpdateApplication>(
        () => UpdateApplication(
          repository: applicationInjection<ApplicationRepository>(),
        ),
      )
      ..registerLazySingleton<AddAttachment>(
        () => AddAttachment(
          repository: applicationInjection<ApplicationRepository>(),
        ),
      )
      ..registerLazySingleton<SubmitApplication>(
        () => SubmitApplication(
          repository: applicationInjection<ApplicationRepository>(),
        ),
      );
  }
}

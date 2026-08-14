/// History use-case DI — **two re-exports, and nothing of its own**.
///
/// `features/history/` owns a page, not a data surface. Both use cases it
/// drives belong to `features/application/` (specs.md § 6.2: *an application is
/// not a history concept*), so this file resolves them out of
/// `applicationInjection` through closures rather than registering a second
/// `ApplicationRepository` behind a second parse of `/applications`.
///
/// This is `ChatUsecaseInjection`'s precedent verbatim
/// (`chat_usecase_injection.dart:57-62`), which itself follows
/// `AuthDatasourceInjection`'s. Cross-Feature Isolation permits
/// `features/A → features/B/domain/**` and **G-L3 measures precisely that
/// boundary and allows it**; what it forbids is reaching into
/// `features/application/data/**`, which nothing here does — the closures are
/// typed on the domain use cases.
///
/// **The ordering constraint** is the same one chat's file documents:
/// `ApplicationFeatureInjection.init()` must have run first. It does — the
/// alphabetical order DI-6 asks for happens to be the required order here, so
/// unlike chat/help there is no deviation to state at the call site.
library;

import '../../application/di/application_injection.dart';
import '../../application/domain/usecases/application_usecases.dart';
import 'history_injection.dart';

class HistoryUsecaseInjection {
  static void inject() {
    historyInjection
      // Resolved lazily out of `applicationInjection` on first use, so
      // registration order between the two containers is the only constraint.
      ..registerLazySingleton<ListApplications>(
        () => applicationInjection<ListApplications>(),
      )
      ..registerLazySingleton<GetStatusPipeline>(
        () => applicationInjection<GetStatusPipeline>(),
      );
  }
}

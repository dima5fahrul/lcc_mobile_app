/// Application feature injection entry point.
///
/// Called from `DependencyInjection.init` after `ApiClient` is on the root
/// container — the datasource resolves it. Ordering inside: datasource →
/// repository → usecase, mirroring `ReferenceFeatureInjection.init()`.
///
/// ## It registers NO BLoC, and that is the design
///
/// `features/application/` is **page-less** (specs.md § 6.2, `B7-AC-10`) — the
/// second such feature in the tree after `features/reference/`, whose
/// `dependency_injection.dart` step records the same thing. Four features
/// consume this one's `domain/**` and none of them may reach into its `data/`
/// or `presentation/` (G-L3), so there is nothing for a BLoC here to drive.
/// `HistoryBloc` lives in `historyInjection` and resolves these two use cases
/// through a closure, which is the only sanctioned cross-container shape
/// (`chat_usecase_injection.dart`).
///
/// ## Ordering
///
/// Anywhere after step 2 (`ApiClient`). `/applications` is a Bearer call, but
/// that is a dependency on step 2's *instance* — the interceptors are attached
/// to the client, not to the session container — so no ordering against step 3
/// is required, the same reasoning `AccountFeatureInjection`'s note gives.
/// **It must precede `HistoryFeatureInjection`**, whose usecase closures reach
/// into this container; `application` precedes `history` alphabetically, so
/// DI-6's alphabetical rule and the real constraint agree and no deviation
/// arises (§ 6.2).
library;

import 'application_datasource_injection.dart';
import 'application_repository_injection.dart';
import 'application_usecase_injection.dart';

class ApplicationFeatureInjection {
  static Future<void> init() async {
    ApplicationDatasourceInjection.inject();
    ApplicationRepositoryInjection.inject();
    ApplicationUsecaseInjection.inject();
  }
}

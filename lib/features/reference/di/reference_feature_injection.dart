/// Reference feature injection entry point.
///
/// Called from `DependencyInjection.init` after `ApiClient` is on the root
/// container — the datasources resolve it. Ordering inside: datasources →
/// repository → usecase, mirroring `NewsFeatureInjection.init()`.
///
/// **No BLoC is registered here, and that is the shape, not an omission.**
/// `features/reference/` is a **page-less feature** (`ssd.md` § 11.1, § 4.2
/// row 4, `F0-AC-52`): it has no route, no widget and no `presentation/`. The
/// state a reference-backed control needs is held by the *certificate page's*
/// BLoC, which F1 builds and which resolves `GetLookupOptions` out of this
/// container through its route builder — the seam RULING 8 draws and G-L5
/// enforces.
library;

import 'reference_datasource_injection.dart';
import 'reference_repository_injection.dart';
import 'reference_usecase_injection.dart';

class ReferenceFeatureInjection {
  static Future<void> init() async {
    ReferenceDatasourceInjection.inject();
    ReferenceRepositoryInjection.inject();
    ReferenceUsecaseInjection.inject();
  }
}

/// Family-book feature injection entry point.
///
/// Called from `DependencyInjection.init` after `ApiClient` is on the root
/// container — the datasource resolves it. Ordering inside: datasource →
/// repository → usecase → bloc, mirroring `ApplicationFeatureInjection.init()`
/// with the fourth step the application feature has no need of.
///
/// ## Six files, not the application feature's five
///
/// `specs.md` § 3.1 row 4 asks for *"`features/application/di/`'s five-file
/// shape"*. This is that shape plus `family_book_bloc_injection.dart`, because
/// `features/application/` is **page-less** and this feature is not. The
/// certificate feature is the inverse — BLoC-only, no datasource — and between
/// the two, six is the union rather than an invention.
///
/// ## Ordering: after step 6 (Service), and that is a hard requirement
///
/// `FamilyBookBlocInjection` resolves `GetServices` out of `serviceInjection`
/// through a closure for the review step's fee, so this must follow it. The
/// registration is lazy, so a wrong order would not fail here — it would fail
/// at the first resolution, i.e. the first time a citizen opens the page, which
/// is why `family_book_injection_test.dart` asserts the order rather than
/// trusting this comment.
///
/// Both of its endpoints are authenticated `/me/*` calls, so it needs step 2's
/// *instance* of `ApiClient` for the Auth/Refresh interceptor chain — satisfied
/// by re-exporting the same client, not by ordering against step 3.
///
/// Alphabetically `family_book` sorts between `chat` and `help`. DI-6's
/// alphabetical rule yields to the `serviceInjection` dependency exactly as it
/// yielded for chat, account and certificates, and the deviation is stated at
/// the call site in `dependency_injection.dart` as those three do.
library;

import 'family_book_bloc_injection.dart';
import 'family_book_datasource_injection.dart';
import 'family_book_repository_injection.dart';
import 'family_book_usecase_injection.dart';

class FamilyBookFeatureInjection {
  static Future<void> init() async {
    FamilyBookDatasourceInjection.inject();
    FamilyBookRepositoryInjection.inject();
    FamilyBookUsecaseInjection.inject();
    FamilyBookBlocInjection.inject();
  }
}

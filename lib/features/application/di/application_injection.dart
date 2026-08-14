/// The application feature's own `GetIt` container.
///
/// `GetIt.asNewInstance()`, matching `helpInjection` / `referenceInjection`: a
/// feature container, not a second copy of the root. DI-1 keeps the root
/// holding exactly `StorageService`, `ApiClient` and `SessionBloc`.
///
/// **This container is a PUBLISHED surface, not an internal detail**
/// (specs.md § 6.2). `historyInjection` resolves `ListApplications` and
/// `GetStatusPipeline` out of it today, and B6b's wallet will resolve
/// `ListApplications` out of it for the Bills Due card (`WalletPage.tsx:105`),
/// through a closure against the **domain interface** — the
/// `ChatUsecaseInjection` → `helpInjection` shape. That is why the
/// registrations below are typed on the abstractions rather than the impls.
///
/// Adding a feature container without adding `await applicationInjection.reset()`
/// to the three DI tests' `tearDown` is the defect that has now shipped five
/// times; `test/architecture/di_teardown_completeness_test.dart` fails on this
/// declaration if any of them forgets.
library;

import 'package:get_it/get_it.dart';

final applicationInjection = GetIt.asNewInstance();

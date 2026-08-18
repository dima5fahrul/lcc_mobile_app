/// The family-book feature's own `GetIt` container.
///
/// `GetIt.asNewInstance()`, matching `applicationInjection` /
/// `certificatesInjection`: a feature container, not a second copy of the root.
/// DI-1 keeps the root holding exactly `StorageService`, `ApiClient` and
/// `SessionBloc`.
///
/// **Nothing outside this feature resolves out of it today**, unlike
/// `applicationInjection`, which is a published surface four features read.
/// That is not an invitation to make it private: `specs.md` § 6.2's third
/// ground for the placement is that B5 and B4 reach FamilyBook through
/// `domain/**` under CFI if they ever need it, and a container is how a
/// closure over `GetFamilyBook` would be taken. It is a published surface with
/// no consumer yet.
///
/// Adding a feature container without adding `await familyBookInjection.reset()`
/// to the three DI tests' `tearDown` is the defect that has now shipped five
/// times; `test/architecture/di_teardown_completeness_test.dart` discovers this
/// declaration by scanning and fails on it if any of them forgets. Those three
/// one-line additions are a **recorded scope deviation** — `specs.md` § 3.1
/// grants `test/features/family_book/**` and does not name
/// `test/core/di/dependency_injection_test.dart` or the news/home DI tests —
/// and the deviation is reported rather than absorbed, exactly as
/// `application_usecase_injection.dart` reported its own.
library;

import 'package:get_it/get_it.dart';

final familyBookInjection = GetIt.asNewInstance();

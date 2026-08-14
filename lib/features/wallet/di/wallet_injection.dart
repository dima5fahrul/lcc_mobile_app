/// The wallet feature's own `GetIt` container. `GetIt.asNewInstance()`, matching
/// `newsInjection` / `homeInjection` / `notificationsInjection` / `chatInjection`;
/// DI-1 keeps the root holding exactly `StorageService`, `ApiClient` and
/// `SessionBloc`.
///
/// **Adding a container obliges three tearDowns.** `walletInjection.reset()` is
/// in `test/core/di/dependency_injection_test.dart`,
/// `test/features/news/di/news_injection_test.dart` and
/// `test/features/home/di/home_injection_test.dart`, and
/// `test/architecture/di_teardown_completeness_test.dart` discovers this
/// declaration by scanning for `GetIt.asNewInstance()` and fails if any of the
/// three is missing it. That guard exists because the omission shipped **five**
/// times, every occurrence surfacing as
/// `Type ApiClient is already registered inside GetIt` — which names the wrong
/// object. It is not optional and it is not a formality.
library;

import 'package:get_it/get_it.dart';

final walletInjection = GetIt.asNewInstance();

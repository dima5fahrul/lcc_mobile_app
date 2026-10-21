/// The verify feature's own `GetIt` container. `GetIt.asNewInstance()`,
/// matching every other feature container; DI-1 keeps the root holding exactly
/// `StorageService`, `ApiClient` and `SessionBloc`.
///
/// `di_teardown_completeness_test.dart` discovers this declaration by pattern
/// and requires the three DI test files to reset it — see that guard's own
/// reason string.
library;

import 'package:get_it/get_it.dart';

final verifyInjection = GetIt.asNewInstance();

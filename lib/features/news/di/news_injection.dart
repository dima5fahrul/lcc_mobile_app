/// The news feature's own `GetIt` container.
///
/// `GetIt.asNewInstance()`, matching `serviceInjection` / `homeInjection`: a
/// feature container, not a second copy of the root. DI-1 keeps the root
/// holding exactly `StorageService`, `ApiClient` and `SessionBloc`.
library;

import 'package:get_it/get_it.dart';

final newsInjection = GetIt.asNewInstance();

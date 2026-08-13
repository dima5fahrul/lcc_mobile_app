/// Service feature-scoped GetIt instance.
///
/// Mirrors `session_injection.dart` / `auth_injection.dart`: each feature owns
/// its own `GetIt.asNewInstance()` so feature registrations do not collide with
/// the root container or with each other. The core singletons
/// (`StorageService`, `ApiClient`) are pulled from the root `injection`, not
/// rebuilt here — DI-3: no feature builds its own `Dio`.
library;

import 'package:get_it/get_it.dart';

final serviceInjection = GetIt.asNewInstance();

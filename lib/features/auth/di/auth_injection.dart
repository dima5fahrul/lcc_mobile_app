/// Auth feature-scoped GetIt instance.
///
/// Mirrors the session feature's `session_injection.dart`: each feature owns
/// its own `GetIt.asNewInstance()` so feature registrations do not collide
/// with the root container or other features. The core singletons
/// (StorageService, ApiClient) are pulled from the root `injection`, not
/// re-registered here.
library;

import 'package:get_it/get_it.dart';

final authInjection = GetIt.asNewInstance();

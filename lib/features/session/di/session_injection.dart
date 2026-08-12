/// Session feature-scoped GetIt instance.
///
/// Mirrors the flutter-boilerplate `movie_injection.dart` pattern: each
/// feature owns its own `GetIt.asNewInstance()` so feature registrations do
/// not collide with the root container or other features. The core
/// singletons (StorageService, ApiClient) are pulled from the root
/// `injection`, not re-registered here.
library;

import 'package:get_it/get_it.dart';

final sessionInjection = GetIt.asNewInstance();

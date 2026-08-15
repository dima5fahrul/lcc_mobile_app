/// The certificates feature's own `GetIt` container.
///
/// `GetIt.asNewInstance()`, matching `referenceInjection` / `applicationInjection`:
/// a feature container, not a second copy of the root. DI-1 keeps the root
/// holding exactly `StorageService`, `ApiClient` and `SessionBloc`.
library;

import 'package:get_it/get_it.dart';

final certificatesInjection = GetIt.asNewInstance();

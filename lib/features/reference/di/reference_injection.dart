/// The reference feature's own `GetIt` container.
///
/// `GetIt.asNewInstance()`, matching `newsInjection` / `serviceInjection`: a
/// feature container, not a second copy of the root. DI-1 keeps the root
/// holding exactly `StorageService`, `ApiClient` and `SessionBloc`.
library;

import 'package:get_it/get_it.dart';

final referenceInjection = GetIt.asNewInstance();

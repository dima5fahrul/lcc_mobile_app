/// The help feature's own `GetIt` container. `GetIt.asNewInstance()`, matching
/// `serviceInjection` / `homeInjection` / `newsInjection`; DI-1 keeps the root
/// holding exactly `StorageService`, `ApiClient` and `SessionBloc`.
library;

import 'package:get_it/get_it.dart';

final helpInjection = GetIt.asNewInstance();

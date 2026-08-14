/// The notification feature's own `GetIt` container. `GetIt.asNewInstance()`,
/// matching `helpInjection` / `newsInjection` / `homeInjection`; DI-1 keeps the
/// root holding exactly `StorageService`, `ApiClient` and `SessionBloc`.
library;

import 'package:get_it/get_it.dart';

final notificationsInjection = GetIt.asNewInstance();

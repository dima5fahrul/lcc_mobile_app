/// The chat feature's own `GetIt` container. `GetIt.asNewInstance()`, matching
/// `helpInjection` / `notificationsInjection` / `newsInjection`; DI-1 keeps the
/// root holding exactly `StorageService`, `ApiClient` and `SessionBloc`.
library;

import 'package:get_it/get_it.dart';

final chatInjection = GetIt.asNewInstance();

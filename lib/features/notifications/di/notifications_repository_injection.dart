/// Notification repository DI. Lazy (DI-2), over the datasource registered
/// before it.
library;

import '../data/datasources/notification_remote_datasource.dart';
import '../data/repositories/notification_repository_impl.dart';
import '../domain/repositories/notification_repository.dart';
import 'notifications_injection.dart';

class NotificationsRepositoryInjection {
  static void inject() {
    notificationsInjection.registerLazySingleton<NotificationRepository>(
      () => NotificationRepositoryImpl(
        remote: notificationsInjection<NotificationRemoteDatasource>(),
      ),
    );
  }
}

/// Notification use-case DI — four lazy singletons (DI-2), one per use case.
library;

import '../domain/repositories/notification_repository.dart';
import '../domain/usecases/notification_usecases.dart';
import 'notifications_injection.dart';

class NotificationsUsecaseInjection {
  static void inject() {
    notificationsInjection
      ..registerLazySingleton<GetNotifications>(
        () => GetNotifications(
          repository: notificationsInjection<NotificationRepository>(),
        ),
      )
      ..registerLazySingleton<GetUnreadCount>(
        () => GetUnreadCount(
          repository: notificationsInjection<NotificationRepository>(),
        ),
      )
      ..registerLazySingleton<MarkNotificationRead>(
        () => MarkNotificationRead(
          repository: notificationsInjection<NotificationRepository>(),
        ),
      )
      ..registerLazySingleton<MarkAllNotificationsRead>(
        () => MarkAllNotificationsRead(
          repository: notificationsInjection<NotificationRepository>(),
        ),
      );
  }
}
